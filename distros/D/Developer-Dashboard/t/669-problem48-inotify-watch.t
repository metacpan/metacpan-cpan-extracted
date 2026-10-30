use strict;
use warnings;

use FindBin;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Time::HiRes qw(sleep);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Errno ();
use IO::Handle;
use Test::More;

my $repo_root = File::Spec->catdir( $FindBin::Bin, '..' );
require lib;
lib->import( File::Spec->catdir( $repo_root, 'lib' ) );

my $module = 'Developer::Dashboard::IndicatorStore::Watch';
my $loaded = eval "require $module; 1";
ok( $loaded, 'the indicator watcher module loads' ) or BAIL_OUT($@);

my ( @writers, @added, $initializations, $closed_handles );
my $backend = {
    initialize => sub {
        pipe( my $reader, my $writer ) or die "Unable to create test pipe: $!";
        $writer->autoflush(1);
        push @writers, $writer;
        $initializations++;
        return $reader;
    },
    add_watch => sub {
        my ( $handle, $path, $mask ) = @_;
        push @added, [ $path, $mask ];
        return -1 if $path eq '/fail';
        return scalar @added;
    },
    close => sub {
        my ($handle) = @_;
        $closed_handles++;
        return close $handle;
    },
};

my $watcher = $module->new( backend => $backend );
isa_ok( $watcher, $module, 'an injected descriptor backend constructs a watcher' );
ok( $watcher->configure( 'inventory-a', [ '/root', '/root/one' ] ),
    'the watcher accepts an ordered directory inventory' );
is( $initializations, 1, 'initial configuration opens one descriptor' );
is( scalar @added, 2, 'initial configuration watches each unique directory' );
ok( $added[0][1] & $module->event_mask, 'watch registration requests filesystem change events' );
ok( !( $module->event_mask & 0x00000001 ), 'read-access events do not invalidate the stable cache' );
ok( $module->event_mask & 0x00000002, 'write-modify events invalidate the stable cache' );
ok( $watcher->unchanged('inventory-a'), 'a readable check with no events is unchanged' );

ok( $watcher->configure( 'inventory-a', [ '/root', '/root/one' ] ),
    'reconfiguring the same inventory is a no-op' );
is( $initializations, 1, 'an identical inventory does not replace the descriptor' );
is( scalar @added, 2, 'an identical inventory does not add duplicate watches' );

print { $writers[0] } "change\n" or die "Unable to signal fake event: $!";
ok( !$watcher->unchanged('inventory-a'), 'any queued event invalidates the fast path' );
is( $watcher->last_error, undef, 'a normal filesystem event is not reported as an API error' );

ok( !$watcher->unchanged('inventory-old'), 'a different inventory signature cannot reuse this watch set' );
ok( $watcher->configure( 'inventory-b', [ '/root', '/root/two' ] ),
    'a changed inventory replaces the descriptor and watch set' );
is( $initializations, 2, 'changed inventory opens a fresh descriptor' );
is( $closed_handles, 1, 'changed inventory closes the old descriptor' );
is_deeply( [ map { $_->[0] } @added[ -2 .. -1 ] ], [ '/root', '/root/two' ],
    'changed inventory installs the new directories' );
ok( $watcher->unchanged('inventory-b'), 'the replacement watch set starts clean' );

ok( !$watcher->configure( 'inventory-fail', [ '/root', '/fail' ] ),
    'a watch-registration failure disables the optimization' );
like( $watcher->last_error, qr{Unable to watch directory},
    'watch-registration failure is retained as an explicit diagnostic' );
ok( !$watcher->unchanged('inventory-fail'),
    'a failed watch set never reports an unchanged inventory' );

my $init_failure = $module->new(
    backend => {
        initialize => sub { return },
        add_watch  => sub { die 'add_watch must not run after initialization failure' },
        close      => sub { return 1 },
    },
);
ok( !$init_failure->configure( 'inventory-init-fail', ['/root'] ),
    'descriptor initialization failure disables the optimization' );
like( $init_failure->last_error, qr{Unable to initialize filesystem watch},
    'descriptor initialization failure is explicit' );

my $undefined_watch = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { return undef },
        close      => sub { close $_[0] },
    },
);
ok( !$undefined_watch->configure( 'undefined-watch', ['/root'] ),
    'undefined watch descriptor rejects the inventory' );
like( $undefined_watch->last_error, qr/Unable to watch directory/,
    'undefined watch descriptor retains a diagnostic without stale errno' );

my $invalid_watch = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { return 0 },
        close      => sub { close $_[0] },
    },
);
ok( !$invalid_watch->configure( 'inventory-invalid-watch', ['/root'] ),
    'a non-positive watch descriptor disables the optimization' );
like( $invalid_watch->last_error, qr{invalid watch descriptor},
    'invalid watch descriptors are diagnosed' );

ok( $watcher->close, 'close releases the active watcher descriptor' );
ok( $watcher->close, 'close is safe when called more than once' );
is( $watcher->last_error, undef, 'closing a healthy watcher leaves no failure diagnostic' );

my $invalid_backend_error;
eval { $module->new( backend => [] ); 1 } or $invalid_backend_error = $@;
like( $invalid_backend_error, qr/Watcher backend must be a hash reference/,
    'constructor rejects a backend with the wrong shape' );
my $missing_callback_error;
eval { $module->new( backend => { initialize => sub { 1 } } ); 1 }
  or $missing_callback_error = $@;
like( $missing_callback_error, qr/missing 'add_watch'/,
    'constructor rejects an incomplete callback backend' );
for my $missing_method (qw(initialize add_watch close)) {
    my %callbacks = map { $_ => sub { 1 } } qw(initialize add_watch close);
    delete $callbacks{$missing_method};
    my $callback_error;
    eval { $module->new( backend => \%callbacks ); 1 } or $callback_error = $@;
    like( $callback_error, qr/missing '\Q$missing_method\E'/,
        "constructor rejects a backend missing $missing_method" );
}

my ( @filtered_writers, @filtered_paths );
my $filtered = $module->new(
    backend => {
        initialize => sub {
            pipe( my $reader, my $writer ) or die "Unable to create filtered test pipe: $!";
            push @filtered_writers, $writer;
            return $reader;
        },
        add_watch => sub { push @filtered_paths, $_[1]; return scalar @filtered_paths },
        close     => sub { close $_[0] },
    },
);
ok( $filtered->configure( 'filtered', [ undef, [], '', '/kept', '/kept' ] ),
    'configuration ignores undefined, referenced, blank, and duplicate paths' );
is_deeply( \@filtered_paths, ['/kept'], 'only the unique valid watch path is installed' );
my $bad_signature_error;
eval { $filtered->configure( undef, [] ); 1 } or $bad_signature_error = $@;
like( $bad_signature_error, qr/inventory signature/, 'configuration rejects an undefined signature' );
my $reference_signature_error;
eval { $filtered->configure( [], [] ); 1 } or $reference_signature_error = $@;
like( $reference_signature_error, qr/inventory signature/,
    'configuration rejects a reference signature' );
my $bad_paths_error;
eval { $filtered->configure( 'bad-paths', {} ); 1 } or $bad_paths_error = $@;
like( $bad_paths_error, qr/paths must be an array reference/, 'configuration rejects non-array paths' );
ok( $filtered->close, 'filtered-path watcher closes after configuration validation' );

my ( @portable_backend_paths, $portable_backend_closed );
my @portable_backend_states = ( 1, 0, undef );
my $portable_backend = $module->new(
    backend => {
        configure_paths => sub {
            my ($paths) = @_;
            @portable_backend_paths = @{$paths};
            return ( { token => 'native-event-source' }, undef );
        },
        unchanged => sub {
            my ($handle) = @_;
            die 'portable event backend received the wrong handle'
              if $handle->{token} ne 'native-event-source';
            my $state = shift @portable_backend_states;
            return ( $state, defined $state ? undef : 'synthetic event backend failure' );
        },
        close => sub {
            my ($handle) = @_;
            $portable_backend_closed++ if $handle->{token} eq 'native-event-source';
            return 1;
        },
    },
);
isa_ok( $portable_backend, $module, 'a callback event backend constructs without a descriptor API' );
ok( $portable_backend->configure( 'callback-set', [ '/one', '/two', '/one' ] ),
    'callback event backend configures a normalized path set' );
is_deeply( \@portable_backend_paths, [ '/one', '/two' ],
    'callback event backend receives unique paths in stable order' );
ok( $portable_backend->unchanged('callback-set'),
    'callback event backend can report an unchanged inventory' );
ok( !$portable_backend->unchanged('callback-set'),
    'callback event backend can report an observed filesystem event' );
is( $portable_backend->last_error, undef,
    'an observed callback event is not treated as a backend failure' );
ok( !$portable_backend->unchanged('callback-set'),
    'callback event backend failure invalidates the fast path' );
like( $portable_backend->last_error, qr/synthetic event backend failure/,
    'callback event backend failure is retained as an explicit diagnostic' );
ok( $portable_backend->close, 'callback event backend releases its platform resource' );
is( $portable_backend_closed, 1, 'callback event backend close callback runs once' );

my $callback_close_error = $module->new(
    backend => {
        configure_paths => sub { return ( { token => 'close-failure' }, undef ) },
        unchanged       => sub { return ( 1, undef ) },
        close           => sub { return ( 0, 'synthetic native close failure' ) },
    },
);
ok( $callback_close_error->configure( 'close-error', ['/close-error'] ),
    'callback close-error fixture configures' );
ok( !$callback_close_error->close, 'callback backend close failure is returned' );
like( $callback_close_error->last_error, qr/synthetic native close failure/,
    'callback close failure preserves the backend diagnostic' );

my $callback_setup_error = $module->new(
    backend => {
        configure_paths => sub { return ( { token => 'partial' }, 'synthetic configure failure' ) },
        unchanged       => sub { return ( 1, undef ) },
        close           => sub { return 1 },
    },
);
ok( !$callback_setup_error->configure( 'callback-setup-error', ['/one'] ),
    'callback backend setup error rejects its partial handle' );
like( $callback_setup_error->last_error, qr/synthetic configure failure/,
    'callback backend setup error remains visible' );

my $callback_missing_handle = $module->new(
    backend => {
        configure_paths => sub { return ( undef, undef ) },
        unchanged       => sub { return ( 1, undef ) },
        close           => sub { return 1 },
    },
);
ok( !$callback_missing_handle->configure( 'callback-missing-handle', ['/one'] ),
    'callback backend with no handle rejects its watch set' );
like( $callback_missing_handle->last_error, qr/Unable to configure platform filesystem notifications/,
    'callback backend without an error uses the explicit generic setup diagnostic' );

my $callback_missing_state = $module->new(
    backend => {
        configure_paths => sub { return ( { token => 'missing-state' }, undef ) },
        unchanged       => sub { return ( undef, undef ) },
        close           => sub { return 1 },
    },
);
ok( $callback_missing_state->configure( 'callback-missing-state', ['/one'] ),
    'callback backend missing-state fixture configures' );
ok( !$callback_missing_state->unchanged('callback-missing-state'),
    'callback backend without a state rejects cache reuse' );
like( $callback_missing_state->last_error, qr/returned no state/,
    'callback backend without state reports a clear error' );

{
    my ( $read_fh, $write_fh );
    pipe( $read_fh, $write_fh ) or die "Unable to create FSEvents adapter fixture: $!";
    $write_fh->autoflush(1);
    my @mac_paths;
    my $mac_stopped = 0;
    {
        no warnings qw(redefine once);
        local $INC{'Mac/FSEvents.pm'} = __FILE__;
        local *Mac::FSEvents::new = sub {
            my ( $class, $options ) = @_;
            @mac_paths = @{ $options->{path} };
            return bless { fh => $read_fh, stopped => \$mac_stopped }, 'Local::Problem48FSEvents';
        };
        my $mac_backend = $module->_macos_backend;
        ok( ref($mac_backend) eq 'HASH', 'macOS FSEvents backend loads when the optional module is available' );
        {
            local $^O = 'darwin';
            ok( ref( $module->_native_backend ) eq 'HASH',
                'native backend dispatches to FSEvents on macOS' );
        }
        my ( $empty_handle, $empty_error ) = $mac_backend->{configure_paths}->([]);
        ok( !defined $empty_handle, 'FSEvents rejects an empty directory inventory' );
        like( $empty_error, qr/No existing directories/, 'empty FSEvents inventory has a clear diagnostic' );
        my ( $bad_watch_state, $bad_watch_error ) = $mac_backend->{unchanged}->(undef);
        ok( !defined $bad_watch_state, 'FSEvents rejects a malformed watch object' );
        like( $bad_watch_error, qr/handle is malformed/, 'malformed FSEvents watch has a clear diagnostic' );
        my ( $missing_stream_state, $missing_stream_error ) = $mac_backend->{unchanged}->( { select => bless( {}, 'Local::Problem48AlwaysReadable' ) } );
        ok( !defined $missing_stream_state, 'FSEvents rejects a watch without its stream' );
        like( $missing_stream_error, qr/handle is malformed/, 'missing FSEvents stream is diagnosed' );
        my ( $missing_select_state, $missing_select_error ) = $mac_backend->{unchanged}->( { stream => bless( {}, 'Local::Problem48FSEvents' ) } );
        ok( !defined $missing_select_state, 'FSEvents rejects a watch without its selector' );
        like( $missing_select_error, qr/handle is malformed/, 'missing FSEvents selector is diagnosed' );
        my ( $bad_close_state, $bad_close_error ) = $mac_backend->{close}->({});
        ok( !$bad_close_state, 'FSEvents rejects a malformed close handle' );
        like( $bad_close_error, qr/malformed during close/, 'malformed FSEvents close has a diagnostic' );
        my ( $bad_close_type, $bad_close_type_error ) = $mac_backend->{close}->([]);
        ok( !$bad_close_type, 'FSEvents close rejects a non-hash handle' );
        like( $bad_close_type_error, qr/malformed during close/, 'non-hash FSEvents close has a diagnostic' );
        my ( $missing_close_stream, $missing_close_error ) = $mac_backend->{close}->( {} );
        ok( !$missing_close_stream, 'FSEvents close rejects a missing stream' );
        like( $missing_close_error, qr/malformed during close/, 'missing close stream is diagnosed' );
        my $mac_watcher = $module->new( backend => $mac_backend );
        ok( $mac_watcher->configure( 'mac-set', [ '/one', '/two' ] ),
            'macOS backend configures the complete directory inventory' );
        is_deeply( \@mac_paths, [ '/one', '/two' ], 'FSEvents receives the selected directory roots' );
        ok( $mac_watcher->unchanged('mac-set'), 'FSEvents backend reports a quiet event stream as unchanged' );
        print {$write_fh} "event\n" or die "Unable to signal FSEvents fixture: $!";
        ok( !$mac_watcher->unchanged('mac-set'), 'FSEvents readiness invalidates the cached snapshot' );
        is( $mac_watcher->last_error, undef, 'a normal FSEvents notification is not reported as an error' );
        ok( $mac_watcher->close, 'FSEvents backend stops its native event stream' );
    }
    close $write_fh or die "Unable to close FSEvents fixture writer: $!";
    is( $mac_stopped, 1, 'FSEvents stop callback runs when the watcher closes' );
}

{
    my ( $read_fh, $write_fh );
    pipe( $read_fh, $write_fh ) or die "Unable to create FSEvents read-error fixture: $!";
    $write_fh->autoflush(1);
    local $INC{'Mac/FSEvents.pm'} = __FILE__;
    no warnings qw(redefine once);
    local *Mac::FSEvents::new = sub {
        return bless { fh => $read_fh }, 'Local::Problem48UnreadableFSEvents';
    };
    my $mac_backend = $module->_macos_backend;
    my ( $handle, $setup_error ) = $mac_backend->{configure_paths}->(['/one']);
    ok( defined $handle, 'FSEvents read-error fixture configures' );
    print {$write_fh} "event\n" or die "Unable to signal FSEvents read-error fixture: $!";
    my ( $read_state, $read_error ) = $mac_backend->{unchanged}->($handle);
    ok( !defined $read_state, 'FSEvents read failure invalidates the snapshot' );
    like( $read_error, qr/synthetic FSEvents read failure/, 'FSEvents read exception is visible' );
    my ( $closed, $close_error ) = $mac_backend->{close}->($handle);
    ok( $closed, 'FSEvents read-error fixture still closes' );
    close $write_fh or die "Unable to close FSEvents read-error writer: $!";
}

{
    local $INC{'FFI/Platypus.pm'};
    delete $INC{'FFI/Platypus.pm'};
    local @INC = ( sub { die "Can't locate FFI/Platypus.pm in \@INC\n" } );
    is( $module->_windows_backend, undef, 'missing optional Windows FFI module selects portable validation' );
}
my $unexpected_windows_ffi_error;
{
    local $INC{'FFI/Platypus.pm'};
    delete $INC{'FFI/Platypus.pm'};
    local @INC = ( sub { die "synthetic Windows FFI loader failure\n" } );
    eval { $module->_windows_backend; 1 } or $unexpected_windows_ffi_error = $@;
}
like( $unexpected_windows_ffi_error, qr/synthetic Windows FFI loader failure/,
    'unexpected Windows FFI loader errors remain visible' );

{
    my ( $read_fh, $write_fh );
    pipe( $read_fh, $write_fh ) or die "Unable to create FSEvents cleanup fixture: $!";
    my $failure_mode = 'setup';
    {
        no warnings qw(redefine once);
        local $INC{'Mac/FSEvents.pm'} = __FILE__;
        local *Mac::FSEvents::new = sub {
            my $class = $failure_mode eq 'no-stop'
              ? 'Local::Problem48NoStopFSEvents'
              : 'Local::Problem48FailingFSEvents';
            return bless {
                fh          => $read_fh,
                failure_mode => $failure_mode,
            }, $class;
        };
        my $mac_backend = $module->_macos_backend;
        my $setup_failure = $module->new( backend => $mac_backend );
        ok( !$setup_failure->configure( 'mac-setup-failure', ['/one'] ),
            'FSEvents setup failure rejects the incomplete watcher' );
        like( $setup_failure->last_error, qr/synthetic FSEvents watch failure/,
            'FSEvents setup error is retained' );
        like( $setup_failure->last_error, qr/synthetic FSEvents cleanup failure/,
            'FSEvents cleanup failure is appended rather than swallowed' );

        $failure_mode = 'no-handle';
        my $no_stream = $module->new( backend => $mac_backend );
        ok( !$no_stream->configure( 'mac-no-stream', ['/one'] ),
            'FSEvents setup rejects a stream without a readable handle' );
        like( $no_stream->last_error, qr/did not return a readable event stream/,
            'missing FSEvents descriptor has an explicit setup error' );

        $failure_mode = 'setup-false-stop';
        my $false_cleanup = $module->new( backend => $mac_backend );
        ok( !$false_cleanup->configure( 'mac-false-cleanup', ['/one'] ),
            'FSEvents setup failure remains rejected when cleanup returns false' );
        like( $false_cleanup->last_error, qr/FSEvents cleanup failed: stop returned false/,
            'false FSEvents cleanup return receives a diagnostic' );

        $failure_mode = 'no-stop';
        my $no_stop = $module->new( backend => $mac_backend );
        ok( !$no_stop->configure( 'mac-no-stop', ['/one'] ),
            'FSEvents setup failure without a stop method remains rejected' );
        like( $no_stop->last_error, qr/did not return a readable event stream/,
            'FSEvents setup failure is preserved without a cleanup method' );

        $failure_mode = 'close';
        my $close_failure = $module->new( backend => $mac_backend );
        ok( $close_failure->configure( 'mac-close-failure', ['/one'] ),
            'FSEvents close-error fixture configures' );
        ok( !$close_failure->close, 'FSEvents stop failure is returned from close' );
        like( $close_failure->last_error, qr/Unable to stop macOS FSEvents: synthetic FSEvents stop failure/,
            'FSEvents close failure preserves its actionable diagnostic' );

        $failure_mode = 'false-stop';
        my $false_stop = $module->new( backend => $mac_backend );
        ok( $false_stop->configure( 'mac-false-stop', ['/one'] ), 'FSEvents false-stop fixture configures' );
        ok( !$false_stop->close, 'FSEvents false stop result is treated as a close failure' );
        like( $false_stop->last_error, qr/Unable to stop macOS FSEvents: stop returned false/,
            'FSEvents false stop result has a diagnostic' );
    }
    close $write_fh or die "Unable to close FSEvents cleanup fixture writer: $!";
    close $read_fh or die "Unable to close FSEvents cleanup fixture reader: $!";
}

{
    local $INC{'Mac/FSEvents.pm'} = __FILE__;
    no warnings qw(redefine once);
    local *Mac::FSEvents::new = sub { die "synthetic FSEvents constructor failure\n" };
    my $mac_backend = $module->_macos_backend;
    my $constructor_failure = $module->new( backend => $mac_backend );
    ok( !$constructor_failure->configure( 'mac-constructor-failure', ['/one'] ),
        'FSEvents constructor exception rejects setup' );
    like( $constructor_failure->last_error, qr/synthetic FSEvents constructor failure/,
        'FSEvents constructor exception is preserved when no stream exists to clean up' );
}

{
    local $INC{'Mac/FSEvents.pm'};
    delete $INC{'Mac/FSEvents.pm'};
    local @INC = ( sub { die "Can't locate Mac/FSEvents.pm in \@INC\n" } );
    is( $module->_macos_backend, undef, 'missing optional FSEvents module selects portable validation' );
}

my $unexpected_fsevents_error;
{
    local $INC{'Mac/FSEvents.pm'};
    delete $INC{'Mac/FSEvents.pm'};
    local @INC = ( sub { die "synthetic FSEvents loader failure\n" } );
    eval { $module->_macos_backend; 1 } or $unexpected_fsevents_error = $@;
}
like( $unexpected_fsevents_error, qr/synthetic FSEvents loader failure/,
    'unexpected FSEvents loader errors remain visible' );

{
    local $INC{'FFI/Platypus.pm'} = __FILE__;
    local $INC{'FFI/Platypus/Type/WideString.pm'} = __FILE__;
    no warnings qw(redefine once);
    local *FFI::Platypus::new = sub { return bless {}, 'Local::Problem48WindowsFFI' };
    our @P48_WINDOWS_WAIT_STATES = ( 258, 258, 0, 258 );
    our @P48_WINDOWS_CHANGE_HANDLES = ( 101, 102 );
    our $P48_WINDOWS_NEXT_COUNT = 0;
    our $P48_WINDOWS_CLOSE_COUNT = 0;
    our $P48_WINDOWS_NEXT_RESULT = 1;
    our $P48_WINDOWS_CLOSE_RESULT = 1;
    our $P48_WINDOWS_LAST_ERROR = 5;
    our $P48_WINDOWS_FIRST_PATHS;
    my $windows_backend = $module->_windows_backend;
    ok( ref($windows_backend) eq 'HASH', 'Windows FFI backend loads when FFI is available' );
    {
        local $^O = 'MSWin32';
        ok( ref( $module->_native_backend ) eq 'HASH',
            'native backend dispatches to Windows directory notifications on Windows' );
    }
    my ( $empty_handle, $empty_error ) = $windows_backend->{configure_paths}->([]);
    ok( !defined $empty_handle, 'Windows watcher rejects an empty directory inventory' );
    like( $empty_error, qr/No existing directories/, 'empty Windows inventory has a clear diagnostic' );
    my ( $bad_wait_state, $bad_wait_error ) = $windows_backend->{unchanged}->(undef);
    ok( !defined $bad_wait_state, 'Windows watcher rejects malformed notification state' );
    like( $bad_wait_error, qr/handle set is malformed/, 'malformed Windows wait state has a clear diagnostic' );
        my ( $bad_array_state, $bad_array_error ) = $windows_backend->{unchanged}->([]);
        ok( !defined $bad_array_state, 'Windows watcher rejects a non-hash notification state' );
        like( $bad_array_error, qr/handle set is malformed/, 'non-hash Windows wait state is diagnosed' );
        my ( $missing_handles_state, $missing_handles_error ) = $windows_backend->{unchanged}->({});
        ok( !defined $missing_handles_state, 'Windows watcher rejects a missing handle array' );
        like( $missing_handles_error, qr/handle set is malformed/, 'missing Windows handle array is diagnosed' );
    my ( $bad_close_state, $bad_close_error ) = $windows_backend->{close}->({});
    ok( !$bad_close_state, 'Windows watcher rejects malformed close state' );
    like( $bad_close_error, qr/handle set is malformed during close/,
        'malformed Windows close state has an explicit diagnostic' );
        my ( $bad_close_array, $bad_close_array_error ) = $windows_backend->{close}->([]);
        ok( !$bad_close_array, 'Windows close rejects a non-hash handle state' );
        like( $bad_close_array_error, qr/handle set is malformed during close/,
            'non-hash Windows close state has an explicit diagnostic' );
        my ( $missing_close_handles, $missing_close_handles_error ) = $windows_backend->{close}->({});
        ok( !$missing_close_handles, 'Windows close rejects a missing handle array' );
        like( $missing_close_handles_error, qr/handle set is malformed during close/,
            'missing Windows close handle array has an explicit diagnostic' );
    if ( ref($windows_backend) eq 'HASH' ) {
        my $windows_watcher = $module->new( backend => $windows_backend );
        ok( $windows_watcher->configure( 'windows-set', [ 'C:\\one', 'C:\\two' ] ),
            'Windows backend configures one notification handle per directory' );
        is_deeply( $P48_WINDOWS_FIRST_PATHS, [ 'C:\\one', 'C:\\two' ],
            'Windows notifications receive the full Unicode-aware directory paths' );
        ok( $windows_watcher->unchanged('windows-set'),
            'Windows timeout from all notification handles leaves the snapshot unchanged' );
        ok( !$windows_watcher->unchanged('windows-set'),
            'a signaled Windows directory notification invalidates the snapshot' );
        is( $P48_WINDOWS_NEXT_COUNT, 1, 'signaled Windows notification is re-armed' );
        ok( $windows_watcher->close, 'Windows backend closes all notification handles' );
        is( $P48_WINDOWS_CLOSE_COUNT, 2, 'every Windows notification handle is closed' );

        @P48_WINDOWS_CHANGE_HANDLES = ( 201 );
        $P48_WINDOWS_CLOSE_RESULT = 0;
        my $close_failure = $module->new( backend => $module->_windows_backend );
        ok( $close_failure->configure( 'windows-close-failure', ['C:\\one'] ),
            'Windows close-error fixture configures' );
        ok( !$close_failure->close, 'Windows notification close failure is returned' );
        like( $close_failure->last_error, qr/FindCloseChangeNotification failed \(GetLastError=5\)/,
            'Windows close failure preserves the native error code' );
        $P48_WINDOWS_CLOSE_RESULT = 1;

        @P48_WINDOWS_CHANGE_HANDLES = (undef);
        my ( $invalid_handle, $invalid_handle_error ) = $windows_backend->{configure_paths}->(['C:\\bad']);
        ok( !defined $invalid_handle, 'Windows setup rejects an invalid native notification handle' );
        like( $invalid_handle_error, qr/FindFirstChangeNotificationW failed.*GetLastError=5/,
            'invalid Windows notification handle exposes GetLastError' );

        @P48_WINDOWS_CHANGE_HANDLES = ( 301, -1 );
        $P48_WINDOWS_CLOSE_RESULT = 0;
        my ( $partial_handle, $partial_error ) = $windows_backend->{configure_paths}->( [ 'C:\\one', 'C:\\two' ] );
        ok( !defined $partial_handle, 'Windows setup closes a partial watch set after a later handle fails' );
        like( $partial_error, qr/cleanup failed \(GetLastError=5\)/,
            'Windows partial-watch cleanup failure is explicit' );
        $P48_WINDOWS_CLOSE_RESULT = 1;

        @P48_WINDOWS_CHANGE_HANDLES = ( 311, -1 );
        $P48_WINDOWS_CLOSE_RESULT = 1;
        my ( $partial_success, $partial_success_error ) = $windows_backend->{configure_paths}->( [ 'C:\\one', 'C:\\two' ] );
        ok( !defined $partial_success, 'Windows setup still rejects a later invalid handle when cleanup succeeds' );
        unlike( $partial_success_error, qr/cleanup failed/, 'successful Windows partial cleanup adds no cleanup error' );

        for my $invalid ( 0, -1, '4294967295', '18446744073709551615', '0xffffffff', '0xffffffffffffffff' ) {
            ok( Developer::Dashboard::IndicatorStore::Watch::_windows_invalid_handle($invalid),
                "Windows rejects invalid handle sentinel $invalid" );
        }
        ok( Developer::Dashboard::IndicatorStore::Watch::_windows_invalid_handle(undef),
            'Windows rejects an undefined native handle' );
        ok( !Developer::Dashboard::IndicatorStore::Watch::_windows_invalid_handle(101),
            'Windows accepts a normal native handle' );

        my $wait_failure = $module->new( backend => $windows_backend );
        @P48_WINDOWS_CHANGE_HANDLES = ( 401 );
        ok( $wait_failure->configure( 'windows-wait-failure', ['C:\\one'] ),
            'Windows wait-error fixture configures' );
        @P48_WINDOWS_WAIT_STATES = (undef);
        my ( $wait_error_state, $wait_error ) = $windows_backend->{unchanged}->( $wait_failure->{handle} );
        ok( !defined $wait_error_state, 'Windows wait API failure invalidates the snapshot' );
        like( $wait_error, qr/WaitForSingleObject failed \(GetLastError=5\)/,
            'Windows wait API error is retained' );
        @P48_WINDOWS_WAIT_STATES = (0xffffffff);
        ( $wait_error_state, $wait_error ) = $windows_backend->{unchanged}->( $wait_failure->{handle} );
        ok( !defined $wait_error_state, 'Windows failed wait sentinel invalidates the snapshot' );

        @P48_WINDOWS_WAIT_STATES = (77);
        my ( $unexpected_state, $unexpected_error ) = $windows_backend->{unchanged}->( $wait_failure->{handle} );
        ok( !defined $unexpected_state, 'Windows rejects an unknown wait status' );
        like( $unexpected_error, qr/unexpected status 77/, 'unknown Windows wait status is explicit' );

        @P48_WINDOWS_WAIT_STATES = (0);
        $P48_WINDOWS_NEXT_RESULT = 0;
        my ( $rearm_state, $rearm_error ) = $windows_backend->{unchanged}->( $wait_failure->{handle} );
        ok( !defined $rearm_state, 'Windows rearm failure invalidates the snapshot' );
        like( $rearm_error, qr/FindNextChangeNotification failed \(GetLastError=5\)/,
            'Windows rearm failure includes GetLastError' );
        $P48_WINDOWS_NEXT_RESULT = 1;
        $wait_failure->close;
    }
}

my $same_signature = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { return 1 },
        close      => sub { close $_[0] },
    },
);
ok( $same_signature->configure( 'same', ['/first'] ), 'same-signature watcher configures' );
ok( $same_signature->configure( 'same', ['/second'] ),
    'matching signature with a different path replaces the watch set' );

my $state_checks = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { return 1 },
        close      => sub { close $_[0] },
    },
);
ok( $state_checks->configure( 'state', ['/state'] ), 'state-check watcher configures' );
local $state_checks->{signature} = undef;
ok( !$state_checks->unchanged('state'),
    'watcher with an active descriptor but missing signature is not unchanged' );
ok( $state_checks->configure( 'state', ['/state'] ),
    'configure replaces an active descriptor when its previous signature is absent' );
$state_checks->{signature} = 'state';
ok( !$state_checks->unchanged(undef), 'unchanged check rejects an undefined signature' );
ok( !$state_checks->unchanged([]), 'unchanged check rejects a reference signature' );
ok( !$state_checks->unchanged('other'), 'unchanged check rejects a mismatched signature' );
delete $state_checks->{select};
ok( !$state_checks->unchanged('state'), 'watcher without a selector cannot claim unchanged state' );
ok( $state_checks->close, 'state-check watcher closes' );

my $close_failure = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { return 1 },
        close      => sub { $! = Errno::EIO(); return 0 },
    },
);
ok( $close_failure->configure( 'close-a', ['/root'] ), 'close-failure watcher configures initially' );
ok( !$close_failure->configure( 'close-b', ['/other'] ),
    'configuration stops when the previous descriptor cannot close' );
like( $close_failure->last_error, qr/Unable to close filesystem watch descriptor/,
    'failed descriptor replacement has a visible close diagnostic' );

my $explicit_close_failure = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { return 1 },
        close      => sub { return ( 0, 'synthetic explicit close failure' ) },
    },
);
ok( $explicit_close_failure->configure( 'explicit-close', ['/root'] ), 'explicit close-error fixture configures' );
ok( !$explicit_close_failure->close, 'explicit backend close failure is returned' );
like( $explicit_close_failure->last_error, qr/synthetic explicit close failure/,
    'explicit backend close diagnostic is preserved' );

my $empty_close_error = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { return 1 },
        close      => sub { $! = 0; return ( 0, undef ) },
    },
);
ok( $empty_close_error->configure( 'empty-close-error', ['/root'] ), 'empty close-error fixture configures' );
ok( !$empty_close_error->close, 'close failure without native diagnostic is still returned' );
is( $empty_close_error->last_error, 'Unable to close filesystem watch descriptor',
    'close failure without native diagnostic gets a generic actionable message' );

my $blank_close_error = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { return 1 },
        close      => sub { $! = 0; return ( 0, '' ) },
    },
);
ok( $blank_close_error->configure( 'blank-close-error', ['/root'] ), 'blank close-error fixture configures' );
ok( !$blank_close_error->close, 'blank backend close diagnostic is treated as missing' );
is( $blank_close_error->last_error, 'Unable to close filesystem watch descriptor',
    'blank backend close diagnostic gets the generic actionable message' );

my $disable_close_failure = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { $! = Errno::EIO(); return -1 },
        close      => sub { $! = Errno::EIO(); return 0 },
    },
);
ok( !$disable_close_failure->configure( 'partial-close', ['/root'] ),
    'watch registration failure rejects a partial watch set' );
like( $disable_close_failure->last_error, qr/descriptor close failed/,
    'partial descriptor close failure is appended to the original diagnostic' );

my $explicit_disable_close_failure = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { return -1 },
        close      => sub { return ( 0, 'synthetic partial close failure' ) },
    },
);
ok( !$explicit_disable_close_failure->configure( 'partial-explicit-close', ['/root'] ),
    'partial watch setup failure remains rejected after explicit close failure' );
like( $explicit_disable_close_failure->last_error, qr/descriptor close failed: synthetic partial close failure/,
    'partial watch cleanup preserves its explicit backend diagnostic' );

my $empty_disable_close_failure = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { $! = Errno::EIO(); return -1 },
        close      => sub { $! = 0; return ( 0, undef ) },
    },
);
ok( !$empty_disable_close_failure->configure( 'partial-empty-close', ['/root'] ),
    'partial watch setup remains rejected when cleanup returns no diagnostic' );
like( $empty_disable_close_failure->last_error, qr/descriptor close failed: unknown close failure/,
    'partial cleanup without a native diagnostic remains explicitly visible' );

my $blank_disable_close_failure = $module->new(
    backend => {
        initialize => sub { pipe( my $reader, my $writer ) or die $!; push @writers, $writer; return $reader },
        add_watch  => sub { $! = Errno::EIO(); return -1 },
        close      => sub { $! = 0; return ( 0, '' ) },
    },
);
ok( !$blank_disable_close_failure->configure( 'partial-blank-close', ['/root'] ),
    'partial watch setup remains rejected when cleanup returns a blank diagnostic' );
like( $blank_disable_close_failure->last_error, qr/descriptor close failed: unknown close failure/,
    'partial cleanup with a blank native diagnostic remains explicitly visible' );

for my $read_case ( [ error => 1 ], [ eof => 0 ] ) {
    my ( $kind, $send_writer ) = @{$read_case};
    my ( $reader, $writer );
    pipe( $reader, $writer ) or die "Unable to create $kind test pipe: $!";
    fcntl( $reader, F_SETFL, fcntl( $reader, F_GETFL, 0 ) | O_NONBLOCK )
      or die "Unable to make $kind test pipe nonblocking: $!";
    close $writer if !$send_writer;
    my $read_failure = $module->new(
        backend => {
            initialize => sub { return $reader },
            add_watch  => sub { return 1 },
            close      => sub { close $_[0] },
        },
    );
    ok( $read_failure->configure( "read-$kind", ['/root'] ), "$kind-read watcher configures" );
    $read_failure->{select} = bless {}, 'Local::Problem48AlwaysReadable';
    ok( !$read_failure->unchanged("read-$kind"), "$kind read invalidates the watcher" );
    like( $read_failure->last_error, qr/Unable to read filesystem watch events|closed unexpectedly/,
        "$kind read failure has an explicit diagnostic" );
    close $writer if $send_writer;
}

my $unsupported;
{
    local $^O = 'freebsd';
    $unsupported = $module->new;
}
is( $unsupported, undef, 'unsupported platforms do not construct a native backend' );
my $explicitly_missing_backend = $module->new( backend => undef );
is( $explicitly_missing_backend, undef, 'constructor rejects an explicitly unavailable backend' );
my $missing_ffi;
{
    local $^O = 'linux';
    local @INC = ();
    local $INC{'FFI/Platypus.pm'};
    delete $INC{'FFI/Platypus.pm'};
    $missing_ffi = $module->_native_backend;
}
is( $missing_ffi, undef, 'a missing optional FFI module selects the portable path' );
my $unexpected_ffi_error;
{
    local $^O = 'linux';
    local @INC = ( sub { die "synthetic FFI loader failure\n" } );
    local $INC{'FFI/Platypus.pm'};
    delete $INC{'FFI/Platypus.pm'};
    eval { $module->_native_backend; 1 } or $unexpected_ffi_error = $@;
}
like( $unexpected_ffi_error, qr/synthetic FFI loader failure/,
    'unexpected optional FFI loader errors remain visible' );

our $P48_FAKE_FD_RESULT;
{
    local $^O = 'linux';
    local $INC{'FFI/Platypus.pm'} = __FILE__;
    no warnings qw(redefine once);
    local *FFI::Platypus::new = sub { return bless {}, 'Local::Problem48FFI' };
    my $fake_backend = $module->_native_backend;
    $P48_FAKE_FD_RESULT = undef;
    ok( !defined $fake_backend->{initialize}->(), 'native adapter rejects an undefined descriptor' );
    $P48_FAKE_FD_RESULT = -1;
    ok( !defined $fake_backend->{initialize}->(), 'native adapter rejects a negative descriptor' );
    $P48_FAKE_FD_RESULT = 999_999_999;
    my $descriptor_error;
    eval { $fake_backend->{initialize}->(); 1 } or $descriptor_error = $@;
    like( $descriptor_error, qr/Unable to wrap inotify descriptor/,
        'native adapter reports descriptor wrapping failure' );

    pipe( my $reader, my $writer ) or die "Unable to create Unicode path fixture: $!";
    $P48_FAKE_FD_RESULT = 1;
    my $unicode_path = 'path-' . chr(0x100);
    is( $fake_backend->{add_watch}->( $reader, $unicode_path, $module->event_mask ), -1,
        'Linux inotify refuses a path that cannot be represented as filesystem bytes' );
    is( 0 + $!, Errno::EILSEQ(), 'unrepresentable Linux watcher path sets EILSEQ' );
    close $reader or die "Unable to close Unicode path fixture reader: $!";
    close $writer or die "Unable to close Unicode path fixture writer: $!";
}

my $native = $module->new;
ok( $native || !$ENV{DD_REQUIRE_NATIVE_WATCHER},
    'required platform workflow has an available native filesystem watcher' );
SKIP: {
    skip 'native filesystem event backend is unavailable on this runner', 4 if !$native;
    my $root = tempdir( CLEANUP => 1 );
    my $child = File::Spec->catdir( $root, 'indicator' );
    make_path($child);
    ok( $native->configure( 'native-inventory', [ $root, $child ] ),
        'native platform backend watches the inventory directories' );
    ok( $native->unchanged('native-inventory'),
        'native event descriptor starts with a clean queue' );
    my $changed_file = File::Spec->catfile( $child, 'status.json' );
    open my $changed_fh, '>:raw', $changed_file
      or die "Unable to create watched test file '$changed_file': $!";
    print {$changed_fh} '{"status":"changed"}'
      or die "Unable to write watched test file '$changed_file': $!";
    close $changed_fh or die "Unable to close watched test file '$changed_file': $!";
    my $observed = 0;
    for ( 1 .. 100 ) {
        if ( !$native->unchanged('native-inventory') ) {
            $observed = 1;
            last;
        }
        sleep 0.01;
    }
    ok( $observed, 'native platform backend invalidates after an actual status-file write' );
    ok( $native->close, 'native platform backend closes its event resources cleanly' );
}

done_testing;

package Local::Problem48AlwaysReadable;
# can_read($self, $timeout)
# Provides an always-readable selector stub so tests can force sysread errors.
# Input: selector object and optional timeout.
# Output: true, causing the watcher to attempt one descriptor read.
sub can_read { return 1 }

package Local::Problem48FFI;
# function($self, $symbol, @signature)
# Returns a fake callable for the requested libc symbol.
# Input: fake FFI instance, symbol name, and ignored type metadata.
# Output: fake function object used by native-backend failure tests.
sub function { return bless { symbol => $_[1] }, 'Local::Problem48Function' }

package Local::Problem48Function;
# call($self, @arguments)
# Returns the configured fake native descriptor result.
# Input: fake function object and native call arguments.
# Output: descriptor value supplied by the surrounding test.
sub call { return $main::P48_FAKE_FD_RESULT }

package Local::Problem48FSEvents;
# watch()
# Returns the injected event stream descriptor used by the adapter test.
# Input: fake FSEvents object.
# Output: readable event stream filehandle.
sub watch { return $_[0]->{fh} }

# read_events()
# Drains a readiness signal in the fake event stream.
# Input: fake FSEvents object.
# Output: empty event list after consuming queued bytes.
sub read_events {
    my ($self) = @_;
    my $buffer = '';
    sysread( $self->{fh}, $buffer, 4096 );
    return ();
}

# stop()
# Records native stream shutdown and closes its injected descriptor.
# Input: fake FSEvents object.
# Output: true when the descriptor closes successfully.
sub stop {
    my ($self) = @_;
    ${ $self->{stopped} }++;
    return CORE::close( $self->{fh} );
}

package Local::Problem48FailingFSEvents;
# watch()
# Returns the configured descriptor or raises the injected stream setup error.
# Input: fake stream object with a mode and optional descriptor.
# Output: descriptor filehandle, or an explicit synthetic setup exception.
sub watch {
    my ($self) = @_;
    die "synthetic FSEvents watch failure\n" if $self->{failure_mode} eq 'setup' || $self->{failure_mode} eq 'setup-false-stop';
    return if $self->{failure_mode} eq 'no-handle';
    return $self->{fh};
}

# stop()
# Raises an injected cleanup error so setup/close diagnostics remain visible.
# Input: fake stream object.
# Output: true when stopped, or an explicit synthetic cleanup exception.
sub stop {
    my ($self) = @_;
    die "synthetic FSEvents cleanup failure\n" if $self->{failure_mode} eq 'setup';
    return 0 if $self->{failure_mode} eq 'setup-false-stop';
    die "synthetic FSEvents stop failure\n" if $self->{failure_mode} eq 'close';
    return 0 if $self->{failure_mode} eq 'false-stop';
    return 1;
}

package Local::Problem48UnreadableFSEvents;
# watch()
# Returns the event descriptor supplied by the test fixture.
# Input: fake stream object with an open descriptor.
# Output: descriptor watched by IO::Select.
sub watch { return $_[0]->{fh} }

# read_events()
# Simulates a native FSEvents read failure after readiness.
# Input: fake stream object.
# Output: never returns; throws an explicit fixture error.
sub read_events { die "synthetic FSEvents read failure\n" }

# stop()
# Closes the test descriptor when the adapter is shut down.
# Input: fake stream object.
# Output: true when the descriptor closes successfully.
sub stop { return CORE::close( $_[0]->{fh} ) }

package Local::Problem48NoStopFSEvents;
# watch()
# Returns no descriptor so setup cleanup can exercise an adapter without stop().
# Input: fake FSEvents object.
# Output: undef, forcing setup to report a missing readable stream.
sub watch { return }

package Local::Problem48WindowsFFI;
# function($self, $name, $arguments, $return)
# Creates a fake native function object for Win32 API backend tests.
# Input: fake FFI object, exported function name, and ignored type signatures.
# Output: callable object retaining the requested Win32 symbol.
sub function { return bless { symbol => $_[1] }, 'Local::Problem48WindowsFunction' }
sub load_custom_type { return 1 }
sub type { return 1 }

package Local::Problem48WindowsFunction;
# call($self, @arguments)
# Simulates Windows filesystem notification API calls and records watched paths.
# Input: fake function object and the native call arguments.
# Output: configured handle, wait status, API success flag, or last-error code.
sub call {
    my ( $self, @arguments ) = @_;
    my $symbol = $self->{symbol};
    if ( $symbol eq 'FindFirstChangeNotificationW' ) {
        push @{ $main::P48_WINDOWS_FIRST_PATHS ||= [] }, $arguments[0];
        return shift @main::P48_WINDOWS_CHANGE_HANDLES;
    }
    if ( $symbol eq 'WaitForSingleObject' ) {
        return shift @main::P48_WINDOWS_WAIT_STATES;
    }
    if ( $symbol eq 'FindNextChangeNotification' ) {
        $main::P48_WINDOWS_NEXT_COUNT++;
        return $main::P48_WINDOWS_NEXT_RESULT;
    }
    if ( $symbol eq 'FindCloseChangeNotification' ) {
        $main::P48_WINDOWS_CLOSE_COUNT++;
        return $main::P48_WINDOWS_CLOSE_RESULT;
    }
    return $main::P48_WINDOWS_LAST_ERROR if $symbol eq 'GetLastError';
    die "Unexpected fake Windows API call '$symbol'";
}

__END__

=pod

=head1 NAME

669-problem48-inotify-watch.t - verify indicator filesystem watcher contracts

=head1 PURPOSE

Exercises the optional filesystem watcher through an injected descriptor
backend. It proves that only a matching, event-free watch set can authorize a
stable-sync fast path and that failures remain explicit.

=head1 WHY IT EXISTS

Problem 48 measured repeated directory and status-file metadata checks in the
stable indicator synchronization path. Native Linux, macOS, and Windows event
backends may avoid those checks between changes, but each must invalidate on
any event and must never turn a
failed or incomplete watch set into a cache hit.

=head1 WHEN TO USE

Run this test when changing the watcher adapter or connecting filesystem
events to indicator cache validation.

=head1 HOW TO USE

  d2 docker compose run --rm --no-deps dev prove -lv t/669-problem48-inotify-watch.t

=head1 WHAT USES IT

The repository regression suite runs this contract test. Indicator sync may
use the same contract across platforms. A native filesystem integration case
runs whenever the runner has its platform adapter and optional dependencies.

=head1 EXAMPLES

The test injects a pipe-backed fake descriptor, configures directory watches,
checks an event-free poll, writes an event, then verifies invalidation and
watch-set replacement. It also exercises descriptor and watch registration
failures without requiring a native library, plus mocked FSEvents and Win32
API contracts. When a platform adapter is available, an integration case
writes a real status file, observes cache invalidation, and closes native
resources.

=cut
