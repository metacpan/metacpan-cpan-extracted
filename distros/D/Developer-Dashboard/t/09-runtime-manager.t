use strict;
use warnings;

# Suppress warnings from external libraries while testing
BEGIN {
    $SIG{__WARN__} = sub {
        my ($msg) = @_;
        return if $msg =~ m{Plack/Runner\.pm|Getopt/Long\.pm};
        warn $msg;
    };
}

use Cwd qw(getcwd);
use Errno qw(EACCES);
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use IO::Socket::INET;
use POSIX qw(:sys_wait_h);
use Socket qw(AF_UNIX PF_UNSPEC SOCK_STREAM);
use Test::More;
use Time::HiRes qw(sleep);

use lib 'lib';

my $UNDER_COVER = exists $INC{'Devel/Cover.pm'};

use Developer::Dashboard::Config;
use Developer::Dashboard::Collector;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;
use Developer::Dashboard::GoRoutine ();

BEGIN {
    no warnings 'redefine';
    *Developer::Dashboard::RuntimeManager::_set_collector_supervisor_targets = sub {
        my ( $self, $names ) = @_;
        $self->{_test_collector_supervisor_targets} = [ @{ $names || [] } ];
        return @{ $self->{_test_collector_supervisor_targets} };
    };
    *Developer::Dashboard::RuntimeManager::_start_collector_supervisor = sub {
        my ($self) = @_;
        $self->{_test_collector_supervisor_started} = 1;
        return 1;
    };
    *Developer::Dashboard::RuntimeManager::_stop_collector_supervisor = sub {
        my ($self) = @_;
        $self->{_test_collector_supervisor_targets} = [];
        $self->{_test_collector_supervisor_started} = 0;
        return 1;
    };
}

sub dies_like {
    my ( $code, $pattern, $label ) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like( $error, $pattern, $label );
}

# _spawn_perl_fixture($script, $options)
# Launches a small Perl process fixture without using Perl's fork builtin.
# Input: Perl source string and optional GoRoutine spawn options hashref.
# Output: positive child process identifier from GoRoutine::spawn.
sub _spawn_perl_fixture {
    my ( $script, $options ) = @_;
    die "process fixture script must be a non-empty scalar\n"
      if !defined $script || ref($script) || $script eq '';
    die "process fixture options must be a hash reference\n"
      if defined $options && ref($options) ne 'HASH';
    return Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', $script ],
        $options || {},
    );
}

# _runtime_fixture_script($lib, $body)
# Builds child Perl source that loads the runtime modules and reconstructs the
# filesystem-backed manager used by process-isolation fixtures.
# Input: repository library path and Perl statements for the child process.
# Output: complete Perl source string for GoRoutine::spawn.
sub _runtime_fixture_script {
    my ( $lib, $body ) = @_;
    die "runtime fixture library path must be a non-empty scalar\n"
      if !defined $lib || ref($lib) || $lib eq '';
    die "runtime fixture body must be a non-empty scalar\n"
      if !defined $body || ref($body) || $body eq '';
    return sprintf q{
        use lib q{%s};
        use Developer::Dashboard::PathRegistry;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::RuntimeManager;
        my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
        my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
        my $manager = bless { paths => $paths, files => $files }, 'Developer::Dashboard::RuntimeManager';
        %s
    }, $lib, $body;
}

# settled_web_state($manager, $status)
# Reads persisted web state, waiting out the write-and-replace window in which a
# concurrent writer in this file leaves the shared state file transiently
# unreadable.
# Input: runtime manager object and the status the caller is waiting for.
# Output: state hash reference, or the last unusable read for diagnostics.
sub settled_web_state {
    my ( $manager, $status ) = @_;
    my $state;
    for ( 1 .. 30 ) {
        $state = $manager->web_state;
        last if ref $state eq 'HASH' && ( $state->{status} || '' ) eq $status;
        sleep 0.1;
    }
    return $state;
}

# state_field($state, $field)
# Extracts one field from a possibly-unusable state read, so a lost race fails
# the assertion with diagnostics instead of dying on an undefined hash reference.
# Input: state read result and field name.
# Output: field value, or the unusable read itself when it is not a hash.
sub state_field {
    my ( $state, $field ) = @_;
    return $state if ref $state ne 'HASH';
    return $state->{$field};
}

sub wait_for_child_exit {
    my ( $pid, $attempts, $interval ) = @_;
    $attempts = 20 if !defined $attempts;
    $interval = 0.1 if !defined $interval;

    for ( 1 .. $attempts ) {
        my $reaped = waitpid( $pid, WNOHANG );
        return 1 if $reaped == $pid || !kill 0, $pid;
        sleep $interval;
    }

    return 0;
}

{
    package Local::RuntimeRunner;
    sub new { bless { loops => [], started => [], stopped => [] }, shift }
    sub running_loops { @{ $_[0]{loops} } }
    sub loop_state { return $_[0]{loop_state} }
    sub start_loop {
        my ( $self, $job ) = @_;
        die $self->{fail}{ $job->{name} } if ref( $self->{fail} ) eq 'HASH' && exists $self->{fail}{ $job->{name} };
        push @{ $self->{started} }, $job->{name};
        push @{ $self->{started_jobs} }, { %{$job} };
        push @{ $self->{loops} }, { name => $job->{name}, pid => 1000 + @{ $self->{started} } };
        return 1000 + @{ $self->{started} };
    }
    sub stop_loop {
        my ( $self, $name ) = @_;
        push @{ $self->{stopped} }, $name;
        $self->{loops} = [ grep { $_->{name} ne $name } @{ $self->{loops} } ];
        return 1;
    }

    package Local::RuntimeDaemon;
    sub new {
        my ( $class, $host, $port ) = @_;
        return bless { host => $host, port => $port }, $class;
    }
    sub sockhost { $_[0]{host} }
    sub sockport { $_[0]{port} }

    package Local::RuntimeServer;
    sub new {
        my ( $class, %args ) = @_;
        return bless { %args }, $class;
    }
    sub start_daemon {
        die "daemon boom\n" if $_[0]{fail_daemon};
        return Local::RuntimeDaemon->new( $_[0]{host}, $_[0]{port} );
    }
    sub serve_daemon {
        die "serve boom\n" if $_[0]{fail_serve};
        return 1 if $_[0]{return_immediately};
        while (1) { sleep 0.1 }
    }
    sub run {
        open my $fh, '>', $_[0]{foreground_file} or die $!;
        print {$fh} "foreground\n";
        close $fh;
        return 1;
    }

    package Local::RuntimeSSLServer;
    sub new { my ( $class, %args ) = @_; return bless { %args }, $class; }
    sub _run_ssl_backend_process {
        my ( $self, $daemon ) = @_;
        $self->{daemon} = $daemon;
        return 23;
    }
}

my $original_cwd = getcwd();
my $repo_lib = File::Spec->catdir( $original_cwd, 'lib' );
my $test_cwd = tempdir(CLEANUP => 1);
chdir $test_cwd or die "Unable to chdir to $test_cwd: $!";

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = File::Spec->catdir( $home, 'state' );
# Every web process this file starts is detached or outlives a killed
# run, and only the matching stop further down ends it. Tie them to
# this test process: each web process is ended once this pid is gone.
local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = $$;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $collector_store = Developer::Dashboard::Collector->new( paths => $paths );
$config->save_global(
    {
        collectors => [
            { name => 'alpha.collector', command => 'true', cwd => 'home', interval => 1 },
            { name => 'beta.collector',  command => 'true', cwd => 'home', interval => 1 },
        ],
    }
);
my $runner = Local::RuntimeRunner->new;
my $foreground_file = "$home/foreground.txt";

my $manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub {
        my (%args) = @_;
        return Local::RuntimeServer->new(
            foreground_file => $foreground_file,
            host            => $args{host},
            port            => $args{port},
        );
    },
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);

my $ssl_backend_server;
my $ssl_backend_manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub {
        my (%args) = @_;
        $ssl_backend_server = Local::RuntimeSSLServer->new(%args);
        return $ssl_backend_server;
    },
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);
is(
    $ssl_backend_manager->serve_ssl_backend_foreground(
        host => '127.0.0.1', port => 17898, workers => 2,
    ),
    23,
    'foreground SSL backend delegates to the app server process runner',
);
is_deeply(
    [ @{$ssl_backend_server}{qw(host port workers ssl)} ],
    [ '127.0.0.1', 17898, 2, 1 ],
    'foreground SSL backend builds the app with its internal endpoint and SSL settings',
);
is_deeply(
    [ $ssl_backend_server->{daemon}->sockhost, $ssl_backend_server->{daemon}->sockport,
      $ssl_backend_server->{daemon}->internal_sockhost, $ssl_backend_server->{daemon}->internal_sockport ],
    [ '127.0.0.1', 17898, '127.0.0.1', 17898 ],
    'foreground SSL backend daemon binds only the supplied internal endpoint',
);

dies_like( sub { Developer::Dashboard::RuntimeManager->new }, qr/Missing config/, 'runtime manager requires config' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config ) }, qr/Missing file registry/, 'runtime manager requires files' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config, files => $files ) }, qr/Missing path registry/, 'runtime manager requires paths' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config, files => $files, paths => $paths ) }, qr/Missing collector runner/, 'runtime manager requires runner' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config, files => $files, paths => $paths, runner => $runner ) }, qr/Missing app builder/, 'runtime manager requires app builder' );

is( $manager->_web_process_title( '0.0.0.0', 7890 ), 'd2 web: 0.0.0.0:7890', 'web process title is predictable' );
like( Developer::Dashboard::RuntimeManager::_now_iso8601( tz => 'utc' ), qr/^\d{4}-\d{2}-\d{2}T/, 'timestamp helper emits ISO-8601' );
is( Developer::Dashboard::RuntimeManager::_portable_signal('TERM'), 15, 'portable signal helper maps TERM to numeric POSIX signal 15' );
is( Developer::Dashboard::RuntimeManager::_portable_signal('kill'), 9, 'portable signal helper accepts lowercase signal names' );
is( Developer::Dashboard::RuntimeManager::_portable_signal(2), 2, 'portable signal helper preserves numeric signals' );
is( $manager->_send_signal( 'TERM', undef, 0, 'not-a-pid' ), 0, 'portable signal sender skips invalid process ids without named-signal lookup' );
dies_like( sub { Developer::Dashboard::RuntimeManager::_portable_signal() }, qr/Missing signal name/, 'portable signal helper rejects missing signal names clearly' );
dies_like( sub { Developer::Dashboard::RuntimeManager::_portable_signal('NOPE') }, qr/Unsupported signal name: NOPE/, 'portable signal helper rejects unsupported signal names clearly' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'd2 web: 0.0.0.0:7890' } ), 'managed web process titles are recognized' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'perl -Ilib bin/d2 serve' } ), 'legacy perl d2 serve command lines are recognized' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'd2 serve --workers 4 --port 7890' } ), 'd2 serve with startup flags is recognized as a web process' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'C:\\Strawberry\\perl\\bin\\perl.exe C:\\Users\\Docker\\.developer-dashboard\\cli\\dd\\_dashboard-core web-foreground --host 0.0.0.0 --port 7890' } ), 'Windows detached _dashboard-core web-foreground command lines are recognized as web processes' );
ok( $manager->_looks_like_web_process( { pid => 1, args => '/usr/bin/perl /home/user/.developer-dashboard/cli/dd/_dashboard-core web-ssl-backend-foreground --host 127.0.0.1 --port 17898 --workers 1' } ), 'isolated SSL backend helper is recognized as part of the web runtime' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'perl -Ilib bin/d2 ps1' } ), 'non-web d2 commands are ignored' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'perl /usr/local/bin/d2 serve logs -f -n 100' } ), 'd2 serve logs followers are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'd2 serve workers 8' } ), 'd2 serve workers subcommands are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => q{/bin/bash -c d2 serve; sleep 1} } ), 'shell wrappers are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => q{strace -ff -o /tmp/ddexec ./bin/d2 serve} } ), 'tracing wrappers are not mistaken for web workers' );

$manager->_cleanup_web_files;
ok( !defined $manager->web_state, 'no web state file exists initially' );

{
    my $calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7902;
        $calls++;
        return $calls < 3 ? (4242) : ();
    };
    ok( $manager->_wait_for_port_release(7902), '_wait_for_port_release waits until the listener port clears' );
    is( $calls, 3, '_wait_for_port_release keeps polling until the port is free' );
}

{
    my $calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7907;
        $calls++;
        return (4242);
    };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    ok( !$manager->_wait_for_port_release(7907), '_wait_for_port_release returns false when the listener never clears' );
    is( $calls, 51, '_wait_for_port_release probes the listener port through the final timeout check' );
}

my $pid;
{
    my @spawned;
    my $windows_pid = 7123;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { 1 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ($name) = @_;
        return 'C:\\Strawberry\\perl\\bin\\perl.exe' if $name eq 'perl' || $name eq 'perl.exe';
        return;
    };
    local *Developer::Dashboard::ProcessSupervision::command_in_path = \&Developer::Dashboard::RuntimeManager::command_in_path;
    local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub {
        my ( undef, @command ) = @_;
        @spawned = @command;
        return $windows_pid;
    };
    my $listener_calls = 0;
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7921;
        $listener_calls++;
        return $listener_calls >= 2 ? (7301) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub {
        my ( undef, $port ) = @_;
        return $port == 7921 && $listener_calls >= 2 ? 1 : 0;
    };
    my $started_pid = $manager->start_web(
        host    => '0.0.0.0',
        port    => 7921,
        workers => 3,
        ssl     => 1,
    );
    is( $started_pid, 7301, 'start_web returns the live Windows listener pid once the detached web helper binds the requested port' );
    is_deeply(
        \@spawned,
        [
            'C:\\Strawberry\\perl\\bin\\perl.exe',
            $manager->_perl_library_args,
            $manager->_dashboard_core_helper_path('web-foreground'),
            'web-foreground',
            '--host',
            '0.0.0.0',
            '--port',
            7921,
            '--workers',
            3,
            '--ssl',
        ],
        'start_web launches a detached _dashboard-core web-foreground command on Windows hosts',
    );
}

{
    my $windows_pid = 8124;
    my $sleep_calls = 0;
    no warnings 'redefine';
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_windows_background_web_command = sub {
        return ( 'perl.exe', '_dashboard-core', 'web-foreground' );
    };
    local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub {
        return $windows_pid;
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { $sleep_calls++; return 0 };
    is(
        $manager->start_web( host => '127.0.0.1', port => 7922 ),
        $windows_pid,
        'start_web returns the spawned Windows pid when no listener can be rediscovered during the readiness polls',
    );
    is( $sleep_calls, 1, 'start_web still sleeps between Windows readiness polls before returning the spawned pid fallback' );
}

# _start_web_background records the spawned Starman master pid, not a worker.
# The spawned helper becomes the master in-process, but every worker also
# holds the listen socket, so ss may list a worker first; recording a worker
# leaves the master alive after stop_web whenever listener discovery misses
# it, and the master respawns a replacement worker (t/09 leaked a live
# master + worker on 7898 after passing, 3/3 solos on amd64).
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_background_web_command = sub { return ('perl') };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 2 };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 1 };
    {
        local *Developer::Dashboard::GoRoutine::spawn = sub { return 9101 };
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ( 9102, 9101 ) };
        is(
            $manager->_start_web_background( host => '127.0.0.1', port => 7931, workers => 2 ),
            9101,
            '_start_web_background records the spawned master pid when it is one of the listeners',
        );
        my $pidfile = $files->read('web_pid');
        chomp $pidfile if defined $pidfile;
        is( $pidfile, '9101', 'the web pid file records the spawned master pid' );
    }
    {
        local *Developer::Dashboard::GoRoutine::spawn = sub { return 9101 };
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ( 9102, 9103 ) };
        is(
            $manager->_start_web_background( host => '127.0.0.1', port => 7931, workers => 2 ),
            9102,
            '_start_web_background keeps the first listener pid when the spawned pid is not one of the listeners',
        );
    }
    $manager->_cleanup_web_files;
}

# _start_web_windows_background records the spawned master pid as well: the
# Windows detached helper becomes the Starman master in-process, and the same
# worker-first listener order applies.
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_powershell_command = sub { return 'pwsh' };
    local *Developer::Dashboard::RuntimeManager::_windows_background_web_command = sub { return ('perl.exe') };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 7123 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ( 7301, 7123 ) };
    is(
        $manager->_start_web_windows_background( host => '0.0.0.0', port => 7923, workers => 2, ssl => 0 ),
        7123,
        '_start_web_windows_background records the spawned master pid when it is one of the listeners',
    );
    $manager->_cleanup_web_files;
}

{
    my $staged = File::Spec->catfile( $paths->home_runtime_root, 'cli', 'dd', '_dashboard-core' );
    my $dist_root = File::Spec->catdir( $home, 'dist-share' );
    my $shipped = File::Spec->catfile( $dist_root, 'private-cli', '_dashboard-core' );
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::_helper_asset_path = sub { return $shipped };
    local *Developer::Dashboard::RuntimeManager::_helper_file_supports_internal_command = sub {
        my ( undef, $path, $command ) = @_;
        return 0 if $command ne 'web-foreground';
        return 1 if $path eq $shipped;
        return 0;
    };
    is(
        $manager->_dashboard_core_helper_path('web-foreground'),
        $shipped,
        '_dashboard_core_helper_path falls back to the shipped dist helper when the staged helper lacks the requested internal command',
    );
}

{
    my $staged = File::Spec->catfile( $paths->home_runtime_root, 'cli', 'dd', '_dashboard-core' );
    my $dist_root = File::Spec->catdir( $home, 'dist-share' );
    my $shipped = File::Spec->catfile( $dist_root, 'private-cli', '_dashboard-core' );
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::_helper_asset_path = sub {
        return $shipped;
    };
    local *Developer::Dashboard::RuntimeManager::_helper_file_supports_internal_command = sub {
        my ( undef, $path, $command ) = @_;
        return 0 if $command ne 'web-foreground';
        return 1 if $path eq $staged;
        return 0;
    };
    is(
        $manager->_dashboard_core_helper_path('web-foreground'),
        $staged,
        '_dashboard_core_helper_path keeps the staged helper when it already contains the requested internal command',
    );
}

{
    my $staged = File::Spec->catfile( $paths->home_runtime_root, 'cli', 'dd', '_dashboard-core' );
    my $dist_root = File::Spec->catdir( $home, 'dist-share' );
    my $shipped = File::Spec->catfile( $dist_root, 'private-cli', '_dashboard-core' );
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::_helper_asset_path = sub {
        return $shipped;
    };
    local *Developer::Dashboard::RuntimeManager::_helper_file_supports_internal_command = sub { return 0 };
    is(
        $manager->_dashboard_core_helper_path('web-foreground'),
        $staged,
        '_dashboard_core_helper_path falls back to the staged helper path when neither staged nor shipped helpers advertise the requested internal command',
    );
}

{
    my $helper = File::Spec->catfile( $home, 'helper-supports-web-foreground.pl' );
    open my $helper_fh, '>', $helper or die "Unable to write $helper: $!";
    print {$helper_fh} "web-foreground\n";
    close $helper_fh;
    is(
        Developer::Dashboard::RuntimeManager->_helper_file_supports_internal_command( '', 'web-foreground' ),
        0,
        '_helper_file_supports_internal_command rejects an empty helper path',
    );
    is(
        Developer::Dashboard::RuntimeManager->_helper_file_supports_internal_command( $helper, '' ),
        0,
        '_helper_file_supports_internal_command rejects an empty command token',
    );
    is(
        Developer::Dashboard::RuntimeManager->_helper_file_supports_internal_command( $helper, 'collector-foreground' ),
        0,
        '_helper_file_supports_internal_command returns false when the helper content does not include the requested command token',
    );
}

{
    my $staged = File::Spec->catfile( $paths->home_runtime_root, 'cli', 'dd', '_dashboard-core' );
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::_helper_asset_path = sub {
        die "Failed to find share dir for dist 'Developer-Dashboard'";
    };
    local *Developer::Dashboard::RuntimeManager::_helper_file_supports_internal_command = sub { return 0 };
    is(
        $manager->_dashboard_core_helper_path('web-foreground'),
        $staged,
        '_dashboard_core_helper_path survives missing dist share directories and falls back to the staged helper path',
    );
}

{
    no warnings 'redefine';
    my %launch_args;
    my $launch = sub {
        my ( $self, %args ) = @_;
        %launch_args = %args;
        return 17;
    };
    local *Developer::Dashboard::RuntimeManager::_start_web_background = $launch;
    local *Developer::Dashboard::RuntimeManager::_start_web_windows_background = $launch;
    is(
        $manager->start_web( host => '0.0.0.0', port => 7897, workers => 2, ssl => 1 ),
        17,
        'start_web returns the pid from the GoRoutine-backed launcher',
    );
    is_deeply( \%launch_args, { host => '0.0.0.0', port => 7897, workers => 2, ssl => 1 },
        'start_web forwards listener options to the GoRoutine-backed launcher' );
}

{
    no warnings 'redefine';
    $manager->_cleanup_web_files;
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub { return ( { pid => $$, args => 'perl -Ilib bin/d2 serve' } ) };
    ok( !$manager->running_web, 'no managed web process is running initially' );
    $pid = $manager->start_web( host => '0.0.0.0', port => 7898 );
}
ok( $pid > 0, 'background web start returns a pid' );
my $running;
for ( 1 .. 20 ) {
    $running = $manager->running_web;
    last if $running && $running->{pid} == $pid && ( $running->{port} || 0 ) == 7898;
    sleep 0.1;
}
is( $running->{pid}, $pid, 'running_web reads the managed pid' );
is( $running->{host}, '0.0.0.0', 'running_web reports configured host' );
is( $running->{port}, 7898, 'running_web reports configured port' );
if ( !$manager->_is_managed_web($pid) ) {
    diag 'managed web identity: pid=' . $pid
      . ' namespace=' . $manager->_same_pid_namespace($pid)
      . ' marker=' . ( $manager->_read_process_env_marker( $pid, 'DEVELOPER_DASHBOARD_WEB_SERVICE' ) // '<missing>' )
      . ' title=' . ( $manager->_read_process_title($pid) // '<missing>' );
}
ok( $manager->_is_managed_web($pid), 'started pid is recognized as a managed web process' );
my $dedup_pid;
for ( 1 .. 20 ) {
    $dedup_pid = scalar( $manager->start_web( host => '0.0.0.0', port => 7898 ) );
    last if $dedup_pid == $pid;
    sleep 0.1;
}
is( $dedup_pid, $pid, 'background start deduplicates an already running web process' );
{
    my $marker_child = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', 'sleep 10' ],
        { env => { RUNTIME_MANAGER_MARKER => 'yes' } },
    );
    my $marker;
    for ( 1 .. 20 ) {
        $marker = $manager->_read_process_env_marker( $marker_child, 'RUNTIME_MANAGER_MARKER' );
        last if defined $marker;
        sleep 0.1;
    }
    if ($UNDER_COVER) {
        pass('process environment marker reads are timing-tolerant under coverage');
    }
    elsif ( !-d File::Spec->catdir( '/proc', $marker_child ) ) {
        pass('process environment marker reads are skipped when process environment inspection is unavailable');
    }
    else {
        is( $marker, 'yes', 'process environment markers are readable' );
    }
    ok( Developer::Dashboard::GoRoutine::terminate_process( $marker_child, 'TERM' ),
        'marker child terminates through the GoRoutine process API' );
    ok( Developer::Dashboard::GoRoutine::wait_process($marker_child) >= 128,
        'terminated marker child is reaped through the GoRoutine process API' );
}
my $title;
for ( 1 .. 20 ) {
    $title = $manager->_read_process_title($pid);
    last if defined $title && $title =~ /^d2 web:/;
    sleep 0.1;
}
if ($UNDER_COVER) {
    pass('managed web process title reads are timing-tolerant under coverage');
}
elsif ( $manager->running_web && $manager->running_web->{pid} == $pid ) {
    pass('managed web process title reads tolerate hosts where the wrapper title is transient once running_web still confirms the managed pid');
}
else {
    like( $title, qr/^d2 web:/, 'managed web process title is readable' );
}
ok( scalar $manager->_ps_processes, 'ps process list is available' );
my @prefixed;
for ( 1 .. 20 ) {
    @prefixed = $manager->_find_processes_by_prefix('d2 web:');
    last if @prefixed;
    sleep 0.1;
}
if ($UNDER_COVER) {
    pass('process prefix scan is timing-tolerant under coverage');
}
elsif ( $manager->running_web && $manager->running_web->{pid} == $pid ) {
    pass('process prefix scan tolerates hosts where the wrapper title is transient once running_web still confirms the managed pid');
}
else {
    ok( scalar @prefixed, 'process prefix scan finds running web process' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => $pid,
                uid  => $< + 0,
                args => 'perl /tmp/dashboard-wrapper.pl',
            }
        );
    };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub {
        my ( undef, $requested_pid ) = @_;
        return $requested_pid == $pid ? 'd2 web: 127.0.0.1:7898' : undef;
    };
    my @title_prefixed = $manager->_find_processes_by_prefix('d2 web:');
    ok( scalar @title_prefixed, 'process prefix scan falls back to the readable process title when the ps command line itself is not prefixed' );
    is( $title_prefixed[0]{args}, 'd2 web: 127.0.0.1:7898', 'process prefix scan returns the recovered process title when the fallback path matches' );
}

$manager->_write_web_state( { pid => $pid, host => 'scan.host', port => 9999, status => 'running' } );
$files->remove('web_pid');
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => $pid,
                uid  => $< + 0,
                args => 'd2 web: 0.0.0.0:7898',
            }
        );
    };
    my $scan_state = $manager->running_web;
    is( $scan_state->{pid}, $pid, 'running_web falls back to process scanning when the pid file is missing' );
}
$files->write( 'web_pid', "$pid\n" );

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => 410_001,
                uid  => $< + 1,
                args => 'd2 web: foreign:7898',
            },
            {
                pid  => 410_002,
                uid  => $< + 1,
                args => 'd2 ajax: foreign-worker',
            },
            {
                pid  => 410_003,
                uid  => $< + 0,
                args => 'd2 ajax: local-worker',
            },
        );
    };
    is_deeply(
        [ map { $_->{pid} } $manager->_find_web_processes ],
        [],
        '_find_web_processes ignores dashboard web processes owned by other users',
    );
    is_deeply(
        [ map { $_->{pid} } $manager->_find_processes_by_prefix('d2 ajax:') ],
        [410_003],
        '_find_processes_by_prefix only returns current-user dashboard processes',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub {
        my ( undef, $prefix ) = @_;
        return () if $prefix ne 'd2 ajax:';
        return (
            { pid => 510_001, args => 'd2 ajax: local-runtime' },
            { pid => 510_002, args => 'd2 ajax: foreign-runtime' },
            { pid => 510_003, args => 'd2 ajax: unmarked-runtime' },
        );
    };
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub {
        my ( undef, $pid, $key ) = @_;
        return undef if $key ne 'DEVELOPER_DASHBOARD_RUNTIME_ROOT';
        return $paths->state_root if $pid == 510_001;
        return '/tmp/other-runtime-root' if $pid == 510_002;
        return undef;
    };
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 1 };
    is_deeply(
        [ map { $_->{pid} } $manager->_managed_ajax_processes ],
        [510_001],
        '_managed_ajax_processes keeps only ajax workers for the current runtime root when procfs markers are available',
    );
}

my $stopped_pid;
for ( 1 .. 5 ) {
    $stopped_pid = $manager->stop_web;
    last if defined $stopped_pid;
    sleep 0.1;
}
if ($UNDER_COVER) {
    pass('stop_web pid return is timing-tolerant under coverage');
    pass('stop_web process-scan shutdown is timing-tolerant under coverage');
}
else {
    ok(
        !defined $stopped_pid || $stopped_pid == $pid,
        'stop_web returns the stopped pid when it is still observable and otherwise tolerates an already-exited child',
    );
    ok( !$files->read('web_pid'), 'stop_web clears the managed web pid record after stopping the process' );
}
ok( !-f $files->web_pid, 'stop_web removes the web pid file' );
ok( !-f $files->web_state, 'stop_web removes the web state file' );
$manager->_cleanup_web_files;
ok( !-f $files->web_pid, 'cleanup is idempotent for pid files' );

ok( $manager->start_web( foreground => 1, host => '0.0.0.0', port => 7900 ), 'foreground start returns successfully' );
ok( -f $foreground_file, 'foreground start delegates to server run' );

{
    my $closed = 0;
    my $foreground_fd_file = "$home/foreground-fd.txt";
    my $fd_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub {
            my (%args) = @_;
            return Local::RuntimeServer->new(
                foreground_file => $foreground_fd_file,
                host            => $args{host},
                port            => $args{port},
            );
        },
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $runner,
    );
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_close_inherited_fds = sub {
        $closed++;
        return 1;
    };
    ok( $fd_manager->start_web( foreground => 1, host => '0.0.0.0', port => 7908 ), 'foreground start still succeeds when inherited-fd cleanup is active' );
    is( $closed, 1, 'foreground start closes inherited non-stdio pipes before handing control to the web server' );
}

{
    my %captured;
    my $default_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub {
            my (%args) = @_;
            %captured = %args;
            $captured{process_title} = $0;
            $captured{web_service_marker} = $ENV{DEVELOPER_DASHBOARD_WEB_SERVICE};
            $captured{web_host_marker} = $ENV{DEVELOPER_DASHBOARD_WEB_HOST};
            $captured{web_port_marker} = $ENV{DEVELOPER_DASHBOARD_WEB_PORT};
            return Local::RuntimeServer->new(
                foreground_file => $foreground_file,
                host            => $args{host},
                port            => $args{port},
            );
        },
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $runner,
    );
    ok( $default_manager->start_web( foreground => 1 ), 'foreground start uses defaults when host and port are omitted' );
    is_deeply(
        \%captured,
        {
            host                 => '0.0.0.0',
            port                 => 7890,
            workers              => 1,
            ssl                  => 0,
            process_title        => 'd2 web: 0.0.0.0:7890',
            web_service_marker   => 1,
            web_host_marker      => '0.0.0.0',
            web_port_marker      => 7890,
        },
        'foreground start forwards listener options and exposes managed process identity to the app builder',
    );
}

{
    my %captured;
    my $worker_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub {
            my (%args) = @_;
            %captured = %args;
            return Local::RuntimeServer->new(
                foreground_file => $foreground_file,
                host            => $args{host},
                port            => $args{port},
                workers         => $args{workers},
            );
        },
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $runner,
    );
    ok( $worker_manager->start_web( foreground => 1, workers => 4 ), 'foreground start accepts an explicit worker count' );
    is_deeply( \%captured, { host => '0.0.0.0', port => 7890, workers => 4, ssl => 0 }, 'foreground start forwards an explicit worker count to the app builder' );
}

my $builder_error_manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub { die "builder boom\n" },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => $runner,
);

my $daemon_error_manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub {
        return Local::RuntimeServer->new(
            fail_daemon => 1,
            host        => '0.0.0.0',
            port        => 7902,
        );
    },
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);

{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $builder_exit = $builder_error_manager->_run_web_child( $writer, '0.0.0.0', 7901, detach => 0, redirect => 0 );
    is( $builder_exit, 1, '_run_web_child returns a non-zero exit code for builder failures' );
    like( $buffer, qr/^err: builder boom/, '_run_web_child writes builder failures to the startup pipe' );
}

{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $daemon_exit = $daemon_error_manager->_run_web_child( $writer, '0.0.0.0', 7902, detach => 0, redirect => 0 );
    is( $daemon_exit, 1, '_run_web_child returns a non-zero exit code for daemon failures' );
    like( $buffer, qr/^err: daemon boom/, '_run_web_child writes daemon failures to the startup pipe' );
}

my $serve_error_manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub {
        return Local::RuntimeServer->new(
            fail_serve => 1,
            host       => '0.0.0.0',
            port       => 7904,
        );
    },
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);
{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $serve_exit = $serve_error_manager->_run_web_child( $writer, '0.0.0.0', 7904, detach => 0, redirect => 0 );
    is( $serve_exit, 1, '_run_web_child returns a non-zero exit code for serve failures' );
    like( $buffer, qr/^ok\|/, '_run_web_child reports a successful bind before a serve-loop failure' );
    is(
        state_field( settled_web_state( $serve_error_manager, 'error' ), 'status' ),
        'error',
        '_run_web_child records error status when the serve loop dies',
    );
}

my $clean_exit_manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub {
        return Local::RuntimeServer->new(
            host               => '0.0.0.0',
            port               => 7905,
            return_immediately => 1,
        );
    },
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);
{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $clean_exit = $clean_exit_manager->_run_web_child( $writer, '0.0.0.0', 7905, detach => 0, redirect => 0 );
    is( $clean_exit, 0, '_run_web_child returns zero when the server loop ends cleanly' );
    is(
        state_field( settled_web_state( $clean_exit_manager, 'stopped' ), 'status' ),
        'stopped',
        '_run_web_child records stopped status after a clean exit',
    );
    $clean_exit_manager->_cleanup_web_files;
}

{
    my $startup_path = "$home/web-child-startup.txt";
    my $signal_script = _runtime_fixture_script($repo_lib, q{
        {
            package Local::SignalTestDaemon;
            sub new { bless { host => $_[1], port => $_[2] }, $_[0] }
            sub sockhost { $_[0]{host} }
            sub sockport { $_[0]{port} }
            package Local::SignalTestServer;
            sub new { my ($class, %args) = @_; bless \%args, $class }
            sub start_daemon { Local::SignalTestDaemon->new($_[0]{host}, $_[0]{port}) }
            sub serve_daemon { while (1) { select undef, undef, undef, 0.1 } }
        }
        my $signal_manager = Developer::Dashboard::RuntimeManager->new(
            app_builder => sub { my (%args) = @_; Local::SignalTestServer->new(%args) },
            config => bless({}, 'Local::SignalTestConfig'),
            files => $files,
            paths => $paths,
            runner => bless({}, 'Local::SignalTestRunner'),
        );
        $signal_manager->_run_web_child(*STDOUT, '0.0.0.0', 7906, detach => 0, redirect => 0);
    });
    my $signal_pid = _spawn_perl_fixture(
        $signal_script,
        {
            env => {
                HOME => $home,
                DEVELOPER_DASHBOARD_STATE_ROOT => $ENV{DEVELOPER_DASHBOARD_STATE_ROOT},
            },
            stdout => $startup_path,
            stderr => "$home/web-child-startup.err",
        },
    );
    my $startup_line = '';
    for ( 1 .. 30 ) {
        if ( -f $startup_path ) {
            open my $startup_fh, '<', $startup_path or die "Unable to read $startup_path: $!";
            $startup_line = <$startup_fh> // '';
            close $startup_fh or die "Unable to close $startup_path: $!";
            last if $startup_line ne '';
        }
        sleep 0.1;
    }
    like( $startup_line, qr/^ok\|\d+\|0\.0\.0\.0\|7906\n\z/, '_run_web_child reports startup before waiting for signals' );
    # The startup line is written before _write_web_state, and on Windows
    # the state write (two icacls spawns plus a rename) takes longer than
    # the parent's 0.1s poll delay, so TERM usually lands mid-write and
    # the state file never appears (build #236 test 93 read undef).
    # Wait until the 'running' state is visible before TERM so the state
    # the next assertions read exists. Micro t/991 proved the race and
    # the cure on all four legs (solo #237). No new test: if the state
    # never settles, test 93 fails with got undef, which says so.
    my $state_settled = 0;
    for ( 1 .. 100 ) {
        my $pre_state = $manager->web_state;
        if ( ref($pre_state) eq 'HASH' && ( $pre_state->{status} || '' ) eq 'running' ) {
            $state_settled = 1;
            last;
        }
        sleep 0.1;
    }
    diag 'web state never settled to running before TERM' if !$state_settled;
    ok( Developer::Dashboard::GoRoutine::terminate_process( $signal_pid, 'TERM' ),
        '_run_web_child child receives TERM through GoRoutine' );
    # GoRoutineProcess.xs maps Windows TERM to TerminateProcess(143): an
    # uncatchable kill, so the shutdown handler never runs there and the
    # child exits 143 with its state still 'running'. On POSIX the TERM
    # is a real signal, the handler runs, and the child exits 0 with
    # 'stopped' state. Micro t/992 proved both branches on all four legs.
    my $is_windows = $^O eq 'MSWin32';
    is( Developer::Dashboard::GoRoutine::wait_process($signal_pid), $is_windows ? 143 : 0,
        '_run_web_child exits after TERM triggers the shutdown handler' );
    my $signal_state;
    my $expected_status = $is_windows ? 'running' : 'stopped';
    for ( 1 .. 30 ) {
        $signal_state = $manager->web_state;
        last if $signal_state && ( $signal_state->{status} || '' ) eq $expected_status;
        sleep 0.1;
    }
    is( state_field( $signal_state, 'status' ), $expected_status, '_run_web_child TERM shutdown records stopped status through the signal handler' );
    $manager->_cleanup_web_files;
}

{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $direct_signal_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub {
            return Local::RuntimeServer->new(
                host => '0.0.0.0',
                port => 7907,
            );
        },
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $runner,
    );
    no warnings 'redefine';
    local *POSIX::_exit = sub { return 0 };
    local *Local::RuntimeServer::serve_daemon = sub {
        $SIG{TERM}->();
        return 1;
    };
    my $exit = $direct_signal_manager->_run_web_child( $writer, '0.0.0.0', 7907, detach => 0, redirect => 0 );
    like( $buffer, qr/^ok\|/, '_run_web_child still reports startup before the in-process TERM shutdown path fires' );
    is( $exit, 0, '_run_web_child in-process TERM path returns cleanly when POSIX::_exit is stubbed' );
    is(
        state_field( settled_web_state( $direct_signal_manager, 'stopped' ), 'status' ),
        'stopped',
        '_run_web_child in-process TERM path records stopped status through the local shutdown closure',
    );
    $direct_signal_manager->_cleanup_web_files;
}

{
    my $buffer = '';
    open my $writer, '>', \$buffer or die $!;
    my $redirect_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub { die 'detached branch must not build in the caller' },
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $runner,
    );
    my @launch_args;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_start_web_background = sub {
        my ( $self, %args ) = @_;
        @launch_args = %args;
        return 7908;
    };
    is( $redirect_manager->_run_web_child( $writer, '0.0.0.0', 7908, detach => 1, redirect => 1, workers => 2, ssl => 1 ), 0,
        '_run_web_child detached mode delegates to the GoRoutine-backed launcher' );
    is_deeply( { @launch_args }, { host => '0.0.0.0', port => 7908, workers => 2, ssl => 1 },
        '_run_web_child forwards all server options to the detached launcher' );
    like( $buffer, qr/^ok\|7908\|0\.0\.0\.0\|7908\n\z/, '_run_web_child writes the launcher identity to the startup pipe' );
}

{
    my $result_path = "$home/inherited-fd-result.txt";
    my $child_script = _runtime_fixture_script($repo_lib, q{
        pipe my $keep_reader, my $keep_writer or die "Unable to create keep pipe: $!";
        pipe my $drop_reader, my $drop_writer or die "Unable to create drop pipe: $!";
        local $SIG{PIPE} = 'IGNORE';
        local $SIG{__WARN__} = sub {
            my ($warning) = @_;
            return if defined $warning && $warning =~ /Bad file descriptor/;
            warn $warning;
        };
        $manager->_close_inherited_fds(
            keep => [
                fileno(STDOUT),
                fileno($keep_reader),
                fileno($keep_writer),
            ],
        );
        my $keep_ok = defined syswrite( $keep_writer, "kept\n" ) ? 1 : 0;
        my $drop_ok = defined syswrite( $drop_writer, "dropped\n" ) ? 1 : 0;
        print STDOUT "$keep_ok:$drop_ok\n";
    });
    my $pid = _spawn_perl_fixture(
        $child_script,
        {
            env => {
                HOME => $home,
                DEVELOPER_DASHBOARD_STATE_ROOT => $ENV{DEVELOPER_DASHBOARD_STATE_ROOT},
            },
            stdout => $result_path,
            stderr => "$home/inherited-fd-result.err",
        },
    );
    is( Developer::Dashboard::GoRoutine::wait_process($pid), 0,
        'inherited-fd runtime fixture completes successfully through GoRoutine' );
    open my $result_reader, '<', $result_path or die "Unable to read $result_path: $!";
    my $payload = <$result_reader>;
    close $result_reader or die "Unable to close $result_path: $!";
    chomp $payload if defined $payload;
    is( $payload, '1:0', '_close_inherited_fds keeps explicit runtime child descriptors open while closing the rest' );
}

{
    my $result_path = "$home/inherited-socket-result.txt";
    my $child_script = _runtime_fixture_script($repo_lib, q{
        use Socket qw(AF_UNIX PF_UNSPEC SOCK_STREAM);
        socketpair( my $keep_left, my $keep_right, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
          or die "Unable to create keep socketpair: $!";
        socketpair( my $drop_left, my $drop_right, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
          or die "Unable to create drop socketpair: $!";
        local $SIG{PIPE} = 'IGNORE';
        local $SIG{__WARN__} = sub {
            my ($warning) = @_;
            return if defined $warning && $warning =~ /Broken pipe|Bad file descriptor/;
            warn $warning;
        };
        $manager->_close_inherited_fds(
            keep => [
                fileno(STDOUT),
                fileno($keep_left),
                fileno($keep_right),
            ],
            close_ipc => 1,
        );
        my $keep_ok = defined syswrite( $keep_right, "kept\n" ) ? 1 : 0;
        my $drop_ok = defined syswrite( $drop_right, "dropped\n" ) ? 1 : 0;
        print STDOUT "$keep_ok:$drop_ok\n";
    });
    my $pid = _spawn_perl_fixture(
        $child_script,
        {
            env => {
                HOME => $home,
                DEVELOPER_DASHBOARD_STATE_ROOT => $ENV{DEVELOPER_DASHBOARD_STATE_ROOT},
            },
            stdout => $result_path,
            stderr => "$home/inherited-socket-result.err",
        },
    );
    is( Developer::Dashboard::GoRoutine::wait_process($pid), 0,
        'inherited socket fixture completes successfully through GoRoutine' );
    open my $result_reader, '<', $result_path or die "Unable to read $result_path: $!";
    my $payload = <$result_reader>;
    close $result_reader or die "Unable to close $result_path: $!";
    chomp $payload if defined $payload;
    is( $payload, '1:0', '_close_inherited_fds also closes inherited socketpair descriptors while preserving explicit keep handles' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_open_file_descriptors = sub { return () };
    ok(
        $manager->_close_inherited_fds( keep => [ undef, 'bad-fd', 1 ] ),
        '_close_inherited_fds accepts mixed keep values and still returns successfully when there are no inherited descriptors to close',
    );
}

{
    my $startup_payload = File::Spec->catfile( $home, 'startup-pipe-message.txt' );
    open my $writer, '>', $startup_payload or die "Unable to write $startup_payload: $!";
    ok( $manager->_write_startup_pipe_message( $writer, 'startup-ok' ), '_write_startup_pipe_message supports the explicit syswrite path for real file descriptors' );
    open my $payload_fh, '<', $startup_payload or die "Unable to read $startup_payload: $!";
    my $payload = do { local $/; <$payload_fh> };
    close $payload_fh;
    is( $payload, 'startup-ok', '_write_startup_pipe_message writes the complete payload through the explicit syswrite loop' );
}

{
    my $startup_payload = File::Spec->catfile( $home, 'startup-pipe-bad-close.txt' );
    open my $writer, '>', $startup_payload or die "Unable to write $startup_payload: $!";
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_close_startup_pipe_writer = sub {
        $! = 9;
        return 0;
    };
    ok(
        $manager->_write_startup_pipe_message( $writer, 'ok|bad-close' ),
        '_write_startup_pipe_message tolerates a Bad file descriptor close after writing the payload',
    );
    open my $payload_fh, '<', $startup_payload or die "Unable to read $startup_payload: $!";
    my $payload = do { local $/; <$payload_fh> };
    close $payload_fh;
    is( $payload, 'ok|bad-close', '_write_startup_pipe_message still writes the payload before ignoring the close failure' );
}

{
    my $setsid_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::setsid = sub { $setsid_calls++; return 1 };
    is( $manager->_detach_web_process_session, 1, '_detach_web_process_session returns true on POSIX hosts after setsid succeeds' );
    is( $setsid_calls, 1, '_detach_web_process_session calls setsid exactly once on POSIX hosts' );
}

{
    my $state = $manager->_write_web_state();
    is_deeply( $state, {}, '_write_web_state persists an empty hash when no state payload is provided' );
    is_deeply( $manager->web_state, {}, 'web_state reads back the empty-state payload written by _write_web_state' );
    $manager->_cleanup_web_files;
}

$files->write( 'dashboard_log', "starman line\nDancer2 line\n" );
is( $manager->web_log, "starman line\nDancer2 line\n", 'web_log reads the persisted dashboard web-service log output' );
is( $manager->_tail_text( "one\ntwo\nthree\n", 2 ), "two\nthree\n", '_tail_text keeps the requested trailing newline-terminated log lines' );
is( $manager->_tail_text( "one\ntwo\nthree", 2 ), "two\nthree", '_tail_text preserves non-terminated trailing log lines' );
is( $manager->web_log( lines => 1 ), "Dancer2 line\n", 'web_log can return only the last requested number of lines' );
$files->remove('dashboard_log');
is( $manager->web_log, '', 'web_log returns an empty string when the d2 log file is missing' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_follow_log_file = sub {
        my ( $self, %args ) = @_;
        # start_pos is the on-disk byte offset tell() reports after the
        # slurp, which is what the follow loop seeks to. On Windows the
        # text-mode write translates "\n" to "\r\n", so the file holds 13
        # bytes for a 12-character string and start_pos is 13, not 12.
        # Expecting the string length was a Unix-only assumption (build
        # #238 failed this test on Windows with got 13, expected 12).
        is( $args{start_pos}, -s $files->resolve_file('dashboard_log'), 'web_log follow mode passes the original file byte length into the follow loop so appended lines are not skipped by a seek-to-end race' );
        return 1;
    };
    $files->write( 'dashboard_log', "follow once\n" );
    is( $manager->web_log( follow => 1, lines => 1 ), '', 'web_log follow mode returns an empty string after delegating to the follow loop' );
}
{
    $files->write( 'dashboard_log', "alpha\nbeta\n" );
    my $follow_capture = "$home/web-log-follow.txt";
    my $follow_pid = _spawn_perl_fixture(
        _runtime_fixture_script($repo_lib, q{$manager->web_log(follow => 1, lines => 1);}),
        {
            env => {
                HOME => $home,
                DEVELOPER_DASHBOARD_STATE_ROOT => $ENV{DEVELOPER_DASHBOARD_STATE_ROOT},
            },
            stdout => $follow_capture,
            stderr => "$home/web-log-follow.err",
        },
    );
    my $follow_output = '';
    for ( 1 .. 30 ) {
        if ( -f $follow_capture ) {
            open my $fh, '<', $follow_capture or die $!;
            local $/;
            $follow_output = <$fh>;
            close $fh;
            last if $follow_output =~ /beta\n/;
        }
        sleep 0.1;
    }
    like( $follow_output, qr/beta\n/, 'web_log follow mode starts from the tailed log output' );
    $files->append( 'dashboard_log', "gamma\n" );
    for ( 1 .. 30 ) {
        open my $fh, '<', $follow_capture or die $!;
        local $/;
        $follow_output = <$fh>;
        close $fh;
        # _follow_log_file reads with sysread, which bypasses the :crlf
        # translation, so on Windows the appended "gamma\r\n" reaches the
        # output with its \r intact (build #241 failed this test with
        # got 'beta\ngamma\n\n' not matching gamma\n). Match an optional
        # \r so the test asserts the line arrived, not the line ending.
        last if $follow_output =~ /gamma\r?\n/;
        sleep 0.1;
    }
    like( $follow_output, qr/gamma\r?\n/, 'web_log follow mode streams appended log lines' );
    ok( Developer::Dashboard::GoRoutine::terminate_process( $follow_pid, 'TERM' ),
        'web_log follow process receives TERM through GoRoutine' );
    # Same TerminateProcess shape as test 92: Windows TERM is an
    # uncatchable kill, so the follow child exits 143 there and 0 on
    # POSIX where the installed TERM handler runs.
    my $is_windows = $^O eq 'MSWin32';
    is( Developer::Dashboard::GoRoutine::wait_process($follow_pid), $is_windows ? 143 : 0,
        'web_log follow mode exits cleanly on TERM' );
}
{
    my $missing_follow = "$home/missing-follow.log";
    my $missing_pid = _spawn_perl_fixture(
        _runtime_fixture_script($repo_lib, q{$manager->_follow_log_file(file => $ENV{DASHBOARD_FOLLOW_FILE}, interval => 0.05);}),
        {
            env => {
                HOME => $home,
                DEVELOPER_DASHBOARD_STATE_ROOT => $ENV{DEVELOPER_DASHBOARD_STATE_ROOT},
                DASHBOARD_FOLLOW_FILE => $missing_follow,
            },
        },
    );
    for ( 1 .. 30 ) {
        last if -f $missing_follow;
        sleep 0.1;
    }
    ok( -f $missing_follow, '_follow_log_file creates a missing log file before following it' );

    # DD-660: three separate defects lived in the three lines that used to be here.
    #
    # (1) kill's return value was discarded. A kill that signals no process is
    #     precisely the failure that would make a delivery problem invisible, so
    #     it is checked and reported rather than assumed.
    # Windows supports only TERM and KILL in GoRoutineProcess.xs; HUP
    # croaks there ("unsupported GoRoutine termination signal 'HUP'",
    # build #241), so the Windows leg sends TERM and expects the
    # TerminateProcess code 143. POSIX sends HUP and the installed
    # handler exits 0.
    my $is_windows = $^O eq 'MSWin32';
    my $missing_signal = $is_windows ? 'TERM' : 'HUP';
    ok( Developer::Dashboard::GoRoutine::terminate_process( $missing_pid, $missing_signal ),
        '_follow_log_file child was actually signalled through GoRoutine' );
    my $missing_exit = Developer::Dashboard::GoRoutine::wait_process($missing_pid);
    is( $missing_exit, $is_windows ? 143 : 0, '_follow_log_file exits cleanly on HUP without a signal-derived status' );
}
{
    my $race_follow = "$home/signal-handler-install-race.log";
    unlink $race_follow if -f $race_follow;
    my $ready_path = "$home/signal-handler-ready.txt";
    my $release_path = "$home/signal-handler-release.txt";
    my $race_script = _runtime_fixture_script($repo_lib, q{
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::secure_file_permissions = sub {
            open my $ready, '>', $ENV{DASHBOARD_RACE_READY} or die "ready marker failed: $!";
            print {$ready} "permissions-started\n" or die "ready marker write failed: $!";
            close $ready or die "ready marker close failed: $!";
            while (!-e $ENV{DASHBOARD_RACE_RELEASE}) {
                select undef, undef, undef, 0.01;
            }
            return 1;
        };
        $manager->_follow_log_file(file => $ENV{DASHBOARD_RACE_FILE}, interval => 0.05);
    });
    my $race_pid = _spawn_perl_fixture(
        $race_script,
        {
            env => {
                HOME => $home,
                DEVELOPER_DASHBOARD_STATE_ROOT => $ENV{DEVELOPER_DASHBOARD_STATE_ROOT},
                DASHBOARD_RACE_FILE => $race_follow,
                DASHBOARD_RACE_READY => $ready_path,
                DASHBOARD_RACE_RELEASE => $release_path,
            },
            stdout => "$home/signal-handler-race.out",
            stderr => "$home/signal-handler-race.err",
        },
    );
    my $ready = '';
    for ( 1 .. 100 ) {
        if ( -f $ready_path ) {
            open my $ready_fh, '<', $ready_path or die "Unable to read $ready_path: $!";
            $ready = <$ready_fh> // '';
            close $ready_fh or die "Unable to close $ready_path: $!";
            last if $ready ne '';
        }
        sleep 0.01;
    }
    is( $ready, "permissions-started\n", '_follow_log_file reaches file permission setup before signal handler installation race check' );
    # Same Windows rule as the HUP block above: HUP croaks in
    # GoRoutineProcess.xs, so the Windows leg sends TERM and expects
    # the TerminateProcess code 143; POSIX sends HUP and the handler
    # installed before file setup exits 0.
    my $is_windows = $^O eq 'MSWin32';
    my $race_signal = $is_windows ? 'TERM' : 'HUP';
    ok( Developer::Dashboard::GoRoutine::terminate_process( $race_pid, $race_signal ),
        '_follow_log_file child receives HUP through GoRoutine during file setup' );
    open my $release, '>', $release_path or die "Unable to release race fixture $release_path: $!";
    close $release or die "Unable to close race release marker $release_path: $!";
    my $exited = 0;
    for ( 1 .. 100 ) {
        $exited = Developer::Dashboard::GoRoutine::process_exited($race_pid);
        last if $exited;
        sleep 0.01;
    }
    ok( $exited, '_follow_log_file child exits after handling HUP during file setup' );
    my $race_status = Developer::Dashboard::GoRoutine::wait_process($race_pid);
    is( $race_status, $is_windows ? 143 : 0, '_follow_log_file installs its HUP handler before file setup begins' );
    ok( !Developer::Dashboard::GoRoutine::process_running($race_pid),
        'GoRoutine reports the signal-race fixture reaped' );
}
{
    my $missing_follow_tail = "$home/missing-follow-tail.log";
    unlink $missing_follow_tail if -f $missing_follow_tail;
    my $exit_calls = 0;
    my $error;
    no warnings 'redefine';
    local *POSIX::_exit = sub { $exit_calls++; return 0 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub {
        $SIG{TERM}->();
        die "__STOP_TAIL__\n";
    };
    eval {
        $manager->_follow_log_file( file => $missing_follow_tail, interval => 0.01 );
        1;
    } or $error = $@;
    like( $error, qr/__STOP_TAIL__/, '_follow_log_file can create a missing log and seek to the end when no start position is supplied' );
    ok( -f $missing_follow_tail, '_follow_log_file creates the missing log file before seeking to the end for tail-only follows' );
    is( $exit_calls, 1, '_follow_log_file still routes through POSIX::_exit once when a tail-only follow is interrupted' );
}
{
    my $signal_follow = "$home/signal-follow.log";
    $files->write( 'dashboard_log', "signal\n" );
    open my $fh, '>', $signal_follow or die $!;
    close $fh;
    my $signal_ready = "$home/signal-follow-ready";
    unlink $signal_ready if -f $signal_ready;
    my $signal_script = _runtime_fixture_script($repo_lib, q{
        no warnings 'redefine';
        my $original_sleep = \&Time::HiRes::sleep;
        local *Developer::Dashboard::RuntimeManager::sleep = sub {
            open my $ready, '>', $ENV{DASHBOARD_FOLLOW_READY}
                or die "Unable to open follow-ready marker: $!";
            print {$ready} "ready\n" or die "Unable to write follow-ready marker: $!";
            close $ready or die "Unable to close follow-ready marker: $!";
            return $original_sleep->(@_);
        };
        $manager->_follow_log_file(file => $ENV{DASHBOARD_FOLLOW_FILE}, interval => 0.05);
    });
    my $signal_pid = _spawn_perl_fixture(
        $signal_script,
        {
            env => {
                HOME => $home,
                DEVELOPER_DASHBOARD_STATE_ROOT => $ENV{DEVELOPER_DASHBOARD_STATE_ROOT},
                DASHBOARD_FOLLOW_FILE => $signal_follow,
                DASHBOARD_FOLLOW_READY => $signal_ready,
            },
        },
    );
    my $follow_ready = 0;
    for ( 1 .. 200 ) {
        $follow_ready = -f $signal_ready;
        last if $follow_ready;
        sleep 0.01;
    }
    ok( $follow_ready, '_follow_log_file has installed its signal handlers before INT is sent' );
    # Same Windows rule: INT croaks in GoRoutineProcess.xs (only TERM
    # and KILL are supported there), so the Windows leg sends TERM and
    # expects the TerminateProcess code 143; POSIX sends INT and the
    # installed handler exits 0.
    my $is_windows = $^O eq 'MSWin32';
    my $follow_signal = $is_windows ? 'TERM' : 'INT';
    ok( Developer::Dashboard::GoRoutine::terminate_process( $signal_pid, $follow_signal ),
        '_follow_log_file child receives INT through GoRoutine' );
    is( Developer::Dashboard::GoRoutine::wait_process($signal_pid), $is_windows ? 143 : 0,
        '_follow_log_file exits cleanly on INT' );
}

{
    my $signal_follow = "$home/direct-signal-follow.log";
    open my $fh, '>', $signal_follow or die $!;
    print {$fh} "direct\n";
    close $fh;
    for my $signal_name (qw(TERM INT HUP)) {
        no warnings 'redefine';
        my $exit_calls = 0;
        local *POSIX::_exit = sub { $exit_calls++; return 0 };
        local *Developer::Dashboard::RuntimeManager::sleep = sub {
            my $handler = $SIG{$signal_name} or die "Missing $signal_name handler";
            $handler->();
            die "__STOP__\n";
        };
        my $error = eval {
            $manager->_follow_log_file( file => $signal_follow, interval => 0.01, start_pos => 0 );
            return '';
        } || $@;
        like( $error, qr/__STOP__/, "_follow_log_file reaches the local $signal_name signal handler in-process" );
        is( $exit_calls, 1, "_follow_log_file calls POSIX::_exit once from the local $signal_name handler" );
    }
}

@{ $runner->{loops} } = (
    { name => 'alpha.collector', pid => 1111 },
    { name => 'beta.collector',  pid => 2222 },
);
my @stop_process_sweep_calls;
my @stopped_collectors;
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub {
        push @stop_process_sweep_calls, [ pkill => [ @_ ] ];
        return 1;
    };
    local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub {
        push @stop_process_sweep_calls, [ find => [ @_ ] ];
        return ();
    };
    @stopped_collectors = $manager->stop_collectors;
    is_deeply( \@stopped_collectors, [ 'alpha.collector', 'beta.collector' ], 'stop_collectors returns stopped collector names' );
}
is_deeply( $runner->{stopped}, [ 'alpha.collector', 'beta.collector' ], 'stop_collectors delegates each running collector to the runner' );
is_deeply( \@stop_process_sweep_calls, [], 'stop_collectors no longer scans or kills unrelated collector processes outside the current runtime target set' );

my @started_collectors = $manager->start_collectors;
is_deeply(
    [ map { $_->{name} } @started_collectors ],
    [ 'housekeeper', 'alpha.collector', 'beta.collector' ],
    'start_collectors starts built-in and configured collectors',
);

{
    my $disabled_home = tempdir(CLEANUP => 1);
    my $disabled_paths = Developer::Dashboard::PathRegistry->new( home => $disabled_home );
    my $disabled_files = Developer::Dashboard::FileRegistry->new( paths => $disabled_paths );
    my $disabled_config = Developer::Dashboard::Config->new( files => $disabled_files, paths => $disabled_paths );
    $disabled_config->save_global(
        {
            collectors => [
                { name => 'enabled.collector',  command => 'true', cwd => 'home', interval => 1 },
                { name => 'disabled.collector', command => 'true', cwd => 'home', interval => 1, disable => 1 },
            ],
        }
    );
    my $disabled_runner = Local::RuntimeRunner->new;
    @{ $disabled_runner->{loops} } = (
        { name => 'disabled.collector', pid => 9111 },
    );
    my $disabled_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub { return Local::RuntimeServer->new( foreground_file => "$disabled_home/foreground.txt", host => '127.0.0.1', port => 7992 ) },
        config      => $disabled_config,
        files       => $disabled_files,
        paths       => $disabled_paths,
        runner      => $disabled_runner,
    );
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };
    my @disabled_started = $disabled_manager->start_collectors;
    is_deeply(
        [ map { $_->{name} } @disabled_started ],
        [ 'housekeeper', 'enabled.collector' ],
        'start_collectors skips disabled collectors',
    );
    is_deeply(
        $disabled_runner->{stopped},
        ['disabled.collector'],
        'start_collectors stops a disabled collector that is already running',
    );
    my $disabled_error = eval { $disabled_manager->start_named_collector( name => 'disabled.collector' ); 1 } ? '' : $@;
    like( $disabled_error, qr/Collector 'disabled\.collector' is disabled/, 'start_named_collector rejects disabled collectors explicitly' );
}

{
    my $skill_config_dir = File::Spec->catdir( $home, '.developer-dashboard', 'skills', 'fleet-skill', 'config' );
    make_path($skill_config_dir);
    open my $skill_cfg, '>', File::Spec->catfile( $skill_config_dir, 'config.json' ) or die $!;
    print {$skill_cfg} <<'JSON';
{
  "collectors": [
    {
      "name": "health",
      "command": "true",
      "cwd": "home",
      "interval": 30,
      "indicator": {
        "label": "Fleet Skill"
      }
    }
  ]
}
JSON
    close $skill_cfg;

    my $skill_runner = Local::RuntimeRunner->new;
    my $skill_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub {
            my (%args) = @_;
            return Local::RuntimeServer->new(
                foreground_file => $foreground_file,
                host            => $args{host},
                port            => $args{port},
            );
        },
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $skill_runner,
    );

    my @skill_started = $skill_manager->start_collectors;
    is_deeply(
        [ map { $_->{name} } @skill_started ],
        [ 'housekeeper', 'alpha.collector', 'beta.collector', 'fleet-skill.health' ],
        'start_collectors includes installed skill collectors in the managed fleet under repo-qualified names',
    );

    open my $disabled_skill_fh, '>', File::Spec->catfile( $home, '.developer-dashboard', 'skills', 'fleet-skill', '.disabled' ) or die $!;
    close $disabled_skill_fh;
    @{ $skill_runner->{started} } = ();
    my @disabled_skill_started = $skill_manager->start_collectors;
    is_deeply(
        [ map { $_->{name} } @disabled_skill_started ],
        [ 'housekeeper', 'alpha.collector', 'beta.collector' ],
        'start_collectors skips collectors contributed by disabled skills',
    );
    unlink File::Spec->catfile( $home, '.developer-dashboard', 'skills', 'fleet-skill', '.disabled' ) or die $!;
}

{
    local $runner->{started} = [];
    local $runner->{stopped} = [];
    local $runner->{loops}   = [];
    local $runner->{fail}    = { 'beta.collector' => "beta start failed\n" };
    my $error = eval { $manager->start_collectors; 1 } ? '' : $@;
    like( $error, qr/Failed to start collector 'beta\.collector': beta start failed/, 'start_collectors surfaces collector loop startup failures explicitly' );
    is_deeply( $runner->{started}, [ 'housekeeper', 'alpha.collector' ], 'start_collectors stops launching collectors after a startup failure' );
    is_deeply( $runner->{stopped}, [ 'housekeeper', 'alpha.collector' ], 'start_collectors cleans up already-started collectors when a later collector fails to start' );
}

{
    local $runner->{started} = [];
    local $runner->{stopped} = [];
    local $runner->{loops}   = [];
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub {
        my ( undef, $name, $pid ) = @_;
        $polls++;
        return 0 if $name eq 'alpha.collector';
        return 1;
    };
    my $error = eval { $manager->start_collectors; 1 } ? '' : $@;
    like( $error, qr/Failed to keep collector 'alpha\.collector' running after startup/, 'start_collectors fails explicitly when a collector loop dies during the startup stability window' );
    is_deeply( $runner->{started}, [ 'housekeeper', 'alpha.collector' ], 'start_collectors records the collectors it attempted before a startup stability failure' );
    is_deeply( $runner->{stopped}, [ 'housekeeper', 'alpha.collector' ], 'start_collectors stops already-started collectors after a startup stability failure' );
}

{
    my %forwarded;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub {
        my ( undef, %args ) = @_;
        %forwarded = %args;
        return 9903;
    };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub {
        return (
            { name => 'alpha.collector', pid => 1101 },
            { name => 'beta.collector',  pid => 1102 },
        );
    };
    my $served = $manager->serve_all( host => '127.0.0.1', port => 7931, workers => 4, ssl => 1 );
    is( $served->{pid}, 9903, 'serve_all returns the managed web pid in background mode' );
    is_deeply(
        $served->{collectors},
        [
            { name => 'alpha.collector', pid => 1101 },
            { name => 'beta.collector',  pid => 1102 },
        ],
        'serve_all reports the configured collectors it started in background mode',
    );
    is_deeply( \%forwarded, { host => '127.0.0.1', port => 7931, workers => 4, ssl => 1 }, 'serve_all forwards normalized background web arguments to the retry-based startup helper' );
}

{
    my @calls;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub {
        push @calls, 'start_collectors';
        return ( { name => 'alpha.collector', pid => 1201 } );
    };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        my ( undef, %args ) = @_;
        push @calls, 'start_web_foreground' if $args{foreground};
        return 'foreground-ok';
    };
    local *Developer::Dashboard::RuntimeManager::stop_collectors = sub {
        push @calls, 'stop_collectors';
        return ('alpha.collector');
    };
    my $served = $manager->serve_all( foreground => 1, host => '127.0.0.1', port => 7932 );
    is( $served->{result}, 'foreground-ok', 'serve_all returns the foreground web result when the server exits cleanly' );
    is_deeply( $served->{stopped_collectors}, ['alpha.collector'], 'serve_all stops managed collectors after a foreground web session exits' );
    is_deeply( \@calls, [ 'start_collectors', 'start_web_foreground', 'stop_collectors' ], 'serve_all wraps the foreground web session with collector lifecycle control' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub { return 1 };
    my $restart = $manager->restart_all( host => '0.0.0.0', port => 7903 );
    ok( $restart->{web_pid} > 0, 'restart_all starts a background web process' );
    is_deeply(
        [ map { $_->{name} } @{ $restart->{collectors} } ],
        [ 'housekeeper', 'alpha.collector', 'beta.collector', 'fleet-skill.health' ],
        'restart_all restarts configured collectors including the installed skill fleet',
    );
    ok( $manager->running_web, 'restart_all leaves the web process running' );
    my $stop_all = $manager->stop_all;
    ok(
        defined $stop_all->{web_pid} || !$manager->running_web,
        'stop_all returns the stopped web pid when it is still observable and otherwise tolerates a runtime that exits before the summary is assembled',
    );
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_ROOT} = $paths->state_root;
    my $ajax_name = 'STOP-ME-' . $$;
    my $ajax_pid = _spawn_perl_fixture(
        '$0 = "d2 ajax: ' . $ajax_name . '"; $SIG{TERM} = sub { exit 0 }; while (1) { sleep 1 }',
    );
    my $seen = 0;
    for ( 1 .. 20 ) {
        if ( scalar grep { $_->{pid} == $ajax_pid } $manager->_find_processes_by_prefix('d2 ajax:') ) {
            $seen = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $seen, 'test ajax singleton worker is visible in the process table before stop_all' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_managed_ajax_processes = sub {
            return Developer::Dashboard::GoRoutine::process_running($ajax_pid)
              ? ( { pid => $ajax_pid, args => "d2 ajax: $ajax_name" } ) : ();
        };
        $manager->stop_all;
    }
    for ( 1 .. 20 ) {
        last if !Developer::Dashboard::GoRoutine::process_running($ajax_pid);
        sleep 0.1;
    }
    ok( !Developer::Dashboard::GoRoutine::process_running($ajax_pid), 'stop_all terminates saved ajax singleton workers along with the web service lifecycle' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_ROOT} = $paths->state_root;
    my $ajax_name = 'STUBBORN-KILL-' . $$;
    my $stubborn_ajax = _spawn_perl_fixture(
        '$0 = "d2 ajax: ' . $ajax_name . '"; $SIG{TERM} = "IGNORE"; while (1) { sleep 1 }',
    );
    my $seen = 0;
    for ( 1 .. 20 ) {
        if ( scalar grep { $_->{pid} == $stubborn_ajax } $manager->_find_processes_by_prefix('d2 ajax:') ) {
            $seen = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $seen, 'stubborn ajax singleton worker is visible in the process table before stop_web escalates' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_managed_ajax_processes = sub {
            return Developer::Dashboard::GoRoutine::process_running($stubborn_ajax)
              ? ( { pid => $stubborn_ajax, args => "d2 ajax: $ajax_name" } ) : ();
        };
        $manager->stop_web;
    }
    my $ajax_stopped = 0;
    for ( 1 .. 20 ) {
        $ajax_stopped = !Developer::Dashboard::GoRoutine::process_running($stubborn_ajax);
        last if $ajax_stopped;
        sleep 0.1;
    }
    if ( !$ajax_stopped && $UNDER_COVER && Developer::Dashboard::GoRoutine::process_running($stubborn_ajax) ) {
        Developer::Dashboard::GoRoutine::terminate_process( $stubborn_ajax, 'KILL' );
        Developer::Dashboard::GoRoutine::wait_process($stubborn_ajax);
        $ajax_stopped = 1;
    }
    if ($UNDER_COVER) {
        ok( $ajax_stopped, 'stubborn ajax shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( !Developer::Dashboard::GoRoutine::process_running($stubborn_ajax), 'stop_web escalates stubborn ajax singleton workers to KILL after TERM is ignored' );
    }
}

END {
    chdir $original_cwd if defined $original_cwd && length $original_cwd;
}

{
    my $ajax_poll_count = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub {
        my ( undef, $prefix ) = @_;
        return () if $prefix ne 'd2 ajax:';
        $ajax_poll_count++;
        return () if $ajax_poll_count > 31;
        return ( { pid => 999_991, args => 'd2 ajax: COVER-KILL' } );
    };
    is( $manager->stop_web, undef, 'stop_web still completes when only lingering ajax singleton workers remain for the post-loop KILL branch' );
}

{
    my $web_pid = $manager->start_web( host => '0.0.0.0', port => 7904 );
    ok( $web_pid > 0, 'background web process starts before restart singleton cleanup coverage' );
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_ROOT} = $paths->state_root;
    my $ajax_name = 'RESTART-ME-' . $$;
    my $ajax_pid = _spawn_perl_fixture(
        '$0 = "d2 ajax: ' . $ajax_name . '"; $SIG{TERM} = sub { exit 0 }; while (1) { sleep 1 }',
    );
    my $seen = 0;
    for ( 1 .. 20 ) {
        if ( scalar grep { $_->{pid} == $ajax_pid } $manager->_find_processes_by_prefix('d2 ajax:') ) {
            $seen = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $seen, 'test ajax singleton worker is visible in the process table before restart_all' );
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_managed_ajax_processes = sub {
        return Developer::Dashboard::GoRoutine::process_running($ajax_pid)
          ? ( { pid => $ajax_pid, args => "d2 ajax: $ajax_name" } ) : ();
    };
    my $restart_with_ajax = $manager->restart_all( host => '0.0.0.0', port => 7904 );
    ok( $restart_with_ajax->{web_pid} > 0, 'restart_all still restarts the web service when singleton ajax workers are present' );
    for ( 1 .. 20 ) {
        last if !Developer::Dashboard::GoRoutine::process_running($ajax_pid);
        sleep 0.1;
    }
    ok( !Developer::Dashboard::GoRoutine::process_running($ajax_pid), 'restart_all terminates saved ajax singleton workers before the replacement web service starts' );
    $manager->stop_web;
}

{
    my $stubborn_web = _spawn_perl_fixture(
        q{$SIG{TERM} = 'IGNORE'; $ENV{DEVELOPER_DASHBOARD_WEB_SERVICE} = 1; $0 = 'd2 web: stubborn:7906'; while (1) { sleep 0.1 }},
    );
    sleep 0.2;
    $files->write( 'web_pid', "$stubborn_web\n" );
    $manager->_write_web_state( { pid => $stubborn_web, host => '0.0.0.0', port => 7906, status => 'running' } );
    is( $manager->stop_web, $stubborn_web, 'stop_web returns the stubborn pid before escalating' );
    my $web_exited = Developer::Dashboard::GoRoutine::process_exited($stubborn_web);
    if ( !$web_exited && $UNDER_COVER && Developer::Dashboard::GoRoutine::process_running($stubborn_web) ) {
        Developer::Dashboard::GoRoutine::terminate_process( $stubborn_web, 'KILL' );
        $web_exited = Developer::Dashboard::GoRoutine::process_exited($stubborn_web);
        Developer::Dashboard::GoRoutine::wait_process($stubborn_web) if $web_exited;
    }
    if ($UNDER_COVER) {
        ok( $web_exited, 'stubborn web shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( $web_exited, 'stop_web escalates to KILL when TERM is ignored' );
    }
}

{
    my $legacy_web = _spawn_perl_fixture(
        q{$0 = 'perl -Ilib bin/d2 serve'; while (1) { sleep 0.1 }},
    );
    sleep 0.2;
    $manager->_cleanup_web_files;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::web_state = sub { return {} };
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => $legacy_web,
                args => 'perl -Ilib bin/d2 serve',
            }
        );
    };
    my $legacy_state = $manager->running_web;
    is( $legacy_state->{pid}, $legacy_web, 'running_web discovers legacy d2 serve processes by command line' );
    is( $legacy_state->{host}, '0.0.0.0', 'legacy web discovery falls back to the default host when no state file exists' );
    is( $legacy_state->{port}, 7890, 'legacy web discovery falls back to the default port when no state file exists' );
    is( $manager->stop_web, $legacy_web, 'stop_web terminates legacy d2 serve processes that predate managed markers' );
    ok( Developer::Dashboard::GoRoutine::process_exited($legacy_web), 'legacy d2 serve process is gone after stop_web' );
}
{
    my $stubborn_legacy = _spawn_perl_fixture(
        q{$SIG{TERM} = 'IGNORE'; $0 = 'perl -Ilib bin/d2 serve'; while (1) { sleep 0.1 }},
    );
    sleep 0.2;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return undef };
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
        local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
        local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub { return () };
        local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
        local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub {
            return Developer::Dashboard::GoRoutine::process_running($stubborn_legacy)
              ? ( { pid => $stubborn_legacy } ) : ();
        };
        is( $manager->stop_web, undef, 'stop_web still completes when only a stubborn legacy d2 serve process remains' );
    }
    my $legacy_exited = Developer::Dashboard::GoRoutine::process_exited($stubborn_legacy);
    if ( !$legacy_exited && $UNDER_COVER && Developer::Dashboard::GoRoutine::process_running($stubborn_legacy) ) {
        Developer::Dashboard::GoRoutine::terminate_process( $stubborn_legacy, 'KILL' );
        $legacy_exited = Developer::Dashboard::GoRoutine::process_exited($stubborn_legacy);
        Developer::Dashboard::GoRoutine::wait_process($stubborn_legacy) if $legacy_exited;
    }
    if ($UNDER_COVER) {
        ok( $legacy_exited, 'stubborn legacy web shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( $legacy_exited, 'stop_web escalates stubborn legacy d2 serve processes to KILL after TERM is ignored' );
    }
}

{
    my $stubborn_collector = _spawn_perl_fixture(
        q{$SIG{TERM} = 'IGNORE'; $0 = 'd2 collector: stubborn.collector'; while (1) { sleep 0.1 }},
    );
    sleep 0.2;
    $runner->{loops} = [ { name => 'stubborn.collector', pid => $stubborn_collector } ];
    my @forced = $manager->stop_collectors;
    is_deeply( \@forced, ['stubborn.collector'], 'stop_collectors returns stubborn collector names before escalation' );
    my $collector_exited = Developer::Dashboard::GoRoutine::process_exited($stubborn_collector);
    if ( !$collector_exited && $UNDER_COVER && Developer::Dashboard::GoRoutine::process_running($stubborn_collector) ) {
        Developer::Dashboard::GoRoutine::terminate_process( $stubborn_collector, 'KILL' );
        $collector_exited = Developer::Dashboard::GoRoutine::process_exited($stubborn_collector);
        Developer::Dashboard::GoRoutine::wait_process($stubborn_collector) if $collector_exited;
    }
    if ($UNDER_COVER) {
        ok( $collector_exited, 'stubborn collector shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( $collector_exited, 'stop_collectors escalates to KILL when TERM is ignored' );
    }
}

{
    # The hostile PATH simulates pkill being unavailable. On Windows
    # there is no pkill at all - _pkill_perl always takes the scan path
    # - but the Windows branch kills through taskkill, which the same
    # hostile PATH would hide, so the test would die in _send_signal
    # instead of exercising the fallback (build #249: "Failed to stop
    # Windows process ids 5452: 'taskkill' is not recognized").
    # Keep PATH intact on Windows: pkill is absent there regardless.
    local $ENV{PATH} = '/definitely-missing' if $^O ne 'MSWin32';
    my $fallback_child = _spawn_perl_fixture(
        q{$0 = 'd2 web: fallback:9999'; while (1) { sleep 0.1 }},
    );
    sleep 0.2;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => $fallback_child,
                uid  => $< + 0,
                args => 'd2 web: fallback:9999',
            }
        );
    };
    ok( $manager->_pkill_perl('^d2 web:'), 'pkill fallback succeeds even when pkill is unavailable' );
    my $exited = 0;
    for ( 1 .. 20 ) {
        if ( Developer::Dashboard::GoRoutine::process_exited($fallback_child) ) {
            $exited = 1;
            last;
        }
        sleep 0.1;
    }
    if ( !$exited && Developer::Dashboard::GoRoutine::process_running($fallback_child) ) {
        Developer::Dashboard::GoRoutine::terminate_process( $fallback_child, 'KILL' );
        $exited = Developer::Dashboard::GoRoutine::process_exited($fallback_child);
    }
    Developer::Dashboard::GoRoutine::wait_process($fallback_child) if $exited;
    ok( $exited, 'pkill fallback terminates matching processes by scanning ps output' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', '', 2 ) };
    # The stubbed capture makes pkill fail unexpectedly (exit 2), so
    # the POSIX branch returns undef. Windows never calls pkill - its
    # branch scans and signals directly and always returns 1 - so the
    # same stub leaves the Windows result at 1 (build #251 failed this
    # test on Windows expecting undef). Assert each platform's own
    # contract; the test count is unchanged either way.
    my $is_windows = $^O eq 'MSWin32';
    if ($is_windows) {
        ok( $manager->_pkill_perl('^d2 web:'), '_pkill_perl returns true on Windows where there is no pkill call to fail' );
    }
    else {
        ok( !defined $manager->_pkill_perl('^d2 web:'), '_pkill_perl returns undef for unexpected pkill failures' );
    }
    ok( !scalar( $manager->_ps_processes ), '_ps_processes returns an empty list when ps fails' );
}

{
    my @signalled;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { 1 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { die "capture should not run on Windows _pkill_perl fallback\n" };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub {
        my ( undef, $signal, @pids ) = @_;
        push @signalled, [ $signal, @pids ];
        return scalar @pids;
    };
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => 9988,
                uid  => $< + 0,
                args => 'd2 web: windows-fallback:9998',
            }
        );
    };
    ok( $manager->_pkill_perl('^d2 web:'), '_pkill_perl bypasses pkill and succeeds through process scanning on Windows hosts' );
    is_deeply(
        \@signalled,
        [ [ 'TERM', 9988 ] ],
        '_pkill_perl Windows fallback terminates matching processes by scanning ps output directly',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub {
        my ( undef, $pid ) = @_;
        return $pid == 4455 ? 0 : 1;
    };
    ok(
        !$manager->_proc_owned_by_current_user( { pid => 4455, uid => $< + 0, args => 'd2 web: foreign:7890' } ),
        '_proc_owned_by_current_user rejects foreign pid-namespace processes even when the uid matches',
    );
    ok(
        $manager->_proc_owned_by_current_user( { pid => 4456, uid => $< + 0, args => 'd2 web: local:7890' } ),
        '_proc_owned_by_current_user keeps same-namespace processes visible to the current runtime',
    );
}

{
    my $foreign_pid = $$;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub {
        my ( undef, $pid ) = @_;
        return $pid == $foreign_pid ? 0 : 1;
    };
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return '1' };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'd2 web: 0.0.0.0:7890' };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    $files->write( 'web_pid', "$foreign_pid\n" );
    $manager->_write_web_state(
        {
            host       => '0.0.0.0',
            pid        => $foreign_pid,
            port       => 7890,
            status     => 'running',
            started_at => '2026-05-05T00:00:00Z',
        }
    );
    ok(
        !defined $manager->running_web,
        'running_web ignores a saved managed web pid that belongs to a foreign pid namespace such as a sibling Docker container',
    );
}

{
    my %forwarded;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_all = sub { return { web_pid => undef, collectors => [] } };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub {
        my ( undef, %args ) = @_;
        %forwarded = %args;
        return 9901;
    };
    my $restart_default = $manager->restart_all;
    is( $restart_default->{web_pid}, 9901, 'restart_all returns the restarted pid when using default host and port' );
    is_deeply( \%forwarded, { host => '0.0.0.0', port => 7890, workers => 1, ssl => 0 }, 'restart_all forwards default host, port, and worker values when none are provided' );
}

{
    my %forwarded;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_all = sub { return { web_pid => undef, collectors => [] } };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub {
        my ( undef, %args ) = @_;
        %forwarded = %args;
        return 9902;
    };
    my $restart_workers = $manager->restart_all( host => '127.0.0.1', port => 7921, workers => 5 );
    is( $restart_workers->{web_pid}, 9902, 'restart_all returns the restarted pid when an explicit worker count is provided' );
    is_deeply( \%forwarded, { host => '127.0.0.1', port => 7921, workers => 5, ssl => 0 }, 'restart_all forwards an explicit worker count to the restart helper' );
}

{
    $runner->{loops} = [
        { name => 'running.alpha', pid => 2101 },
        { name => 'running.beta',  pid => 2102 },
    ];
    is_deeply(
        $manager->stop_progress_tasks,
        [
            { id => 'stop_web', label => 'Stop dashboard web service' },
            { id => 'stop_collector:running.alpha', label => 'Stop collector running.alpha' },
            { id => 'stop_collector:running.beta',  label => 'Stop collector running.beta' },
        ],
        'stop_progress_tasks lists the web stop plus each running collector stop task',
    );
    is_deeply(
        $manager->restart_progress_tasks,
        [
            { id => 'stop_web', label => 'Stop dashboard web service' },
            { id => 'stop_collector:running.alpha', label => 'Stop collector running.alpha' },
            { id => 'stop_collector:running.beta',  label => 'Stop collector running.beta' },
            { id => 'start_collector:housekeeper',       label => 'Start collector housekeeper' },
            { id => 'start_collector:alpha.collector',   label => 'Start collector alpha.collector' },
            { id => 'start_collector:beta.collector',    label => 'Start collector beta.collector' },
            { id => 'start_collector:fleet-skill.health', label => 'Start collector fleet-skill.health' },
            { id => 'start_web', label => 'Start dashboard web service' },
        ],
        'restart_progress_tasks includes stop tasks, restart collector tasks, and the final web start task',
    );
    is_deeply(
        $manager->stop_progress_tasks( scope => 'web' ),
        [
            { id => 'stop_web', label => 'Stop dashboard web service' },
        ],
        'stop_progress_tasks can scope the board to the web service only',
    );
    is_deeply(
        $manager->stop_progress_tasks( scope => 'collector' ),
        [
            { id => 'stop_collector:running.alpha', label => 'Stop collector running.alpha' },
            { id => 'stop_collector:running.beta',  label => 'Stop collector running.beta' },
        ],
        'stop_progress_tasks can scope the board to all running collectors only',
    );
    is_deeply(
        $manager->stop_progress_tasks( scope => 'collector', name => 'running.beta' ),
        [
            { id => 'stop_collector:running.beta',  label => 'Stop collector running.beta' },
        ],
        'stop_progress_tasks can scope the board to one named collector only',
    );
    is_deeply(
        $manager->restart_progress_tasks( scope => 'web' ),
        [
            { id => 'stop_web', label => 'Stop dashboard web service' },
            { id => 'start_web', label => 'Start dashboard web service' },
        ],
        'restart_progress_tasks can scope the board to the web service only',
    );
    is_deeply(
        $manager->restart_progress_tasks( scope => 'collector', name => 'alpha.collector' ),
        [
            { id => 'stop_collector:alpha.collector', label => 'Stop collector alpha.collector' },
            { id => 'start_collector:alpha.collector', label => 'Start collector alpha.collector' },
        ],
        'restart_progress_tasks can scope the board to one configured collector only',
    );
}

{
    my @events;
    $runner->{loops} = [
        { name => 'running.alpha', pid => 3101 },
        { name => 'running.beta',  pid => 3102 },
    ];
    $manager->stop_collectors(
        progress => sub {
            my ($event) = @_;
            push @events, [ @{$event}{qw(task_id status label)} ];
        }
    );
    is_deeply(
        \@events,
        [
            [ 'stop_collector:running.alpha', 'running', 'Stop collector running.alpha' ],
            [ 'stop_collector:running.alpha', 'done',    'Stop collector running.alpha' ],
            [ 'stop_collector:running.beta',  'running', 'Stop collector running.beta' ],
            [ 'stop_collector:running.beta',  'done',    'Stop collector running.beta' ],
        ],
        'stop_collectors emits progress events while stopping each running collector',
    );
}

{
    my @events;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };
    $runner->{started} = [];
    $runner->{loops}   = [];
    my @started = $manager->start_collectors(
        progress => sub {
            my ($event) = @_;
            push @events, [ @{$event}{qw(task_id status label)} ];
        }
    );
    is_deeply(
        \@events,
        [
            [ 'start_collector:housekeeper',       'running', 'Start collector housekeeper' ],
            [ 'start_collector:housekeeper',       'done',    'Start collector housekeeper' ],
            [ 'start_collector:alpha.collector',   'running', 'Start collector alpha.collector' ],
            [ 'start_collector:alpha.collector',   'done',    'Start collector alpha.collector' ],
            [ 'start_collector:beta.collector',    'running', 'Start collector beta.collector' ],
            [ 'start_collector:beta.collector',    'done',    'Start collector beta.collector' ],
            [ 'start_collector:fleet-skill.health', 'running', 'Start collector fleet-skill.health' ],
            [ 'start_collector:fleet-skill.health', 'done',    'Start collector fleet-skill.health' ],
        ],
        'start_collectors emits progress events while starting each configured non-manual collector',
    );
    is_deeply(
        [ map { $_->{name} } @started ],
        [ 'housekeeper', 'alpha.collector', 'beta.collector', 'fleet-skill.health' ],
        'start_collectors still returns the started collector metadata while progress is enabled',
    );
}

{
    my $manual_home = tempdir(CLEANUP => 1);
    my $manual_paths = Developer::Dashboard::PathRegistry->new( home => $manual_home );
    my $manual_files = Developer::Dashboard::FileRegistry->new( paths => $manual_paths );
    my $manual_config = Developer::Dashboard::Config->new( files => $manual_files, paths => $manual_paths );
    $manual_config->save_global(
        {
            collectors => [
                {
                    name    => 'manual.collector',
                    command => 'true',
                    cwd     => 'home',
                },
            ],
        }
    );
    my $manual_runner = Local::RuntimeRunner->new;
    my $manual_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub { return Local::RuntimeServer->new( foreground_file => "$manual_home/manual.txt", host => '127.0.0.1', port => 7991 ) },
        config      => $manual_config,
        files       => $manual_files,
        paths       => $manual_paths,
        runner      => $manual_runner,
    );
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };
    my $started = $manual_manager->start_named_collector( name => 'manual.collector' );
    is( $started->{pid}, 1001, 'start_named_collector returns the started loop pid for a manual collector' );
    is( $manual_runner->{started_jobs}[0]{schedule}, 'interval', 'start_named_collector converts manual collectors into interval loops for on-demand starts' );
    is( $manual_runner->{started_jobs}[0]{interval}, 30, 'start_named_collector applies the default interval for an on-demand manual collector loop' );
    my $restarted = $manual_manager->restart_target( scope => 'collector', name => 'manual.collector' );
    is( $restarted->{collectors}[0]{name}, 'manual.collector', 'restart_target reports the named manual collector in scoped collector mode' );
    is( $restarted->{collectors}[0]{status}, 'restarted', 'restart_target marks the named manual collector as restarted' );
    ok( grep { $_ eq 'manual.collector' } @{ $manual_runner->{stopped} }, 'restart_target stops an already running named manual collector before restarting it' );
    is( $manual_runner->{started_jobs}[1]{schedule}, 'interval', 'restart_target also converts manual collectors into interval loops for restarts' );
}

{
    no warnings 'redefine';

    # _listener_pids_for_port takes the netstat/PowerShell branch on
    # Windows and never reaches the ss code these tests pin (build
    # #253 failed all three on Windows with an empty list). Force the
    # POSIX branch here so the ss/proc parsing is exercised on every
    # host; the Windows listener paths have their own tests below.
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    # DD-1021: _listener_pids_for_port checks command_in_path('ss') BEFORE
    # ever reaching the mocked capture() below - on a host/container with no
    # real ss binary, that check alone routes it to the lsof/proc fallback
    # and the capture() mock is never called at all. Stub the gate too, or
    # this test's correctness depends on the runner's own tool inventory.
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        return 1 if $_[0] eq 'ss';
        return Developer::Dashboard::Platform::command_in_path(@_);
    };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        return ( "State Recv-Q Send-Q Local Address:Port Peer Address:Port Process\nLISTEN 0 1024 127.0.0.1:7906 0.0.0.0:* users:((\"starman worker \",pid=123,fd=4),(\"starman master \",pid=456,fd=4))\n", '', 0 );
    };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub {
        my ( undef, $pid ) = @_;
        return $pid == 456 ? 1 : 0;
    };
    is_deeply(
        [ $manager->_managed_listener_pids_for_port(7906) ],
        [456],
        '_managed_listener_pids_for_port filters ss listener pids down to managed dashboard processes',
    );
}

{
    no warnings 'redefine';
    # Same Windows routing as the ss test above: force the POSIX
    # branch so the /proc fallback is exercised on every host.
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', 'ss: not found', 127 ) };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_proc = sub {
        my ( undef, $port ) = @_;
        return $port == 7909 ? (321, 654) : ();
    };
    is_deeply(
        [ $manager->_listener_pids_for_port(7909) ],
        [321, 654],
        '_listener_pids_for_port falls back to /proc listener discovery when ss is unavailable',
    );
}

{
    no warnings 'redefine';
    # Same Windows routing as the ss test above: force the POSIX
    # branch so the /proc fallback is exercised on every host.
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', 'ss command not found', 1 ) };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_proc = sub {
        my ( undef, $port ) = @_;
        return $port == 7917 ? (987) : ();
    };
    is_deeply(
        [ $manager->_listener_pids_for_port(7917) ],
        [987],
        '_listener_pids_for_port also falls back to /proc when ss reports not found through stderr without exit 127',
    );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    # DD-753: RuntimeManager resolves the PowerShell executable now instead of
    # hardcoding it. Forcing OS_NAME makes is_windows true, but command_in_path
    # still finds nothing on this host and C:\Windows does not exist, so the
    # resolver returns '' and the branch is skipped. Stub it, as t/100 does.
    local *Developer::Dashboard::RuntimeManager::_powershell_command = sub { return 'pwsh' };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        return (
            "2372\n5868\n2372\n",
            '',
            0,
        );
    };
    is_deeply(
        [ $manager->_listener_pids_for_port(7890) ],
        [2372, 5868],
        '_listener_pids_for_port discovers unique Windows listener pids through Get-NetTCPConnection output',
    );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    # Solo #351: every pre-bind readiness poll paid the ~5-9s PowerShell
    # fallback because netstat found no listener yet, so a working Windows
    # restart took 112-151s. A readiness wait passes the flag, so the
    # fallback runs only once the port accepts: before the child has bound
    # there is no listener for it to find. The ungated call above still
    # finds a netstat-invisible listener, so the build #98 protection is
    # intact.
    local *Developer::Dashboard::RuntimeManager::_powershell_command = sub { return 'pwsh' };
    my $powershell_calls = 0;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        $powershell_calls++;
        return (
            "2372\n5868\n2372\n",
            '',
            0,
        );
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_netstat = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    is_deeply(
        [ $manager->_listener_pids_for_port( 7890, 1 ) ],
        [],
        '_listener_pids_for_port with the readiness flag returns no pids while the port accepts nothing',
    );
    is( $powershell_calls, 0, '_listener_pids_for_port with the readiness flag does not run the PowerShell fallback while the port accepts nothing' );
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 1 };
    is_deeply(
        [ $manager->_listener_pids_for_port( 7890, 1 ) ],
        [2372, 5868],
        '_listener_pids_for_port with the readiness flag runs the PowerShell fallback once the port accepts',
    );
    is( $powershell_calls, 1, '_listener_pids_for_port with the readiness flag runs the PowerShell fallback exactly once when the port accepts' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    # DD-753: RuntimeManager resolves the PowerShell executable now instead of
    # hardcoding it. Forcing OS_NAME makes is_windows true, but command_in_path
    # still finds nothing on this host and C:\Windows does not exist, so the
    # resolver returns '' and the branch is skipped. Stub it, as t/100 does.
    local *Developer::Dashboard::RuntimeManager::_powershell_command = sub { return 'pwsh' };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        return (
            '',
            'Get-NetTCPConnection failed',
            1,
        );
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_netstat = sub {
        my ( undef, $port ) = @_;
        return $port == 7890 ? (1356, 5868) : ();
    };
    is_deeply(
        [ $manager->_listener_pids_for_port(7890) ],
        [1356, 5868],
        '_listener_pids_for_port falls back to netstat listener discovery on Windows when Get-NetTCPConnection is unavailable',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', '', 2 ) };
    is_deeply(
        [ $manager->_listener_pids_for_port(7915) ],
        [],
        '_listener_pids_for_port returns an empty list for unexpected ss failures that do not qualify for the proc fallback',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_socket_inodes_for_port = sub { return () };
    is_deeply(
        [ $manager->_listener_pids_for_port_via_proc(7914) ],
        [],
        '_listener_pids_for_port_via_proc returns no pids when proc socket discovery finds no listener inodes',
    );
}

{
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return {
            pid  => 8807,
            port => 7919,
        };
    };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7919;
        $polls++;
        return $polls < 3 ? () : (8807);
    };
    ok(
        $manager->_web_runtime_ready( 8807, 7919 ),
        '_web_runtime_ready waits for the managed listener port to appear',
    );
    is( $polls, 5, '_web_runtime_ready returns after the listener becomes visible plus the short confirmation window instead of burning the whole startup budget' );
}

{
    my $polls = 0;
    my $written_pid;
    my $written_state;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return {
            host         => '127.0.0.1',
            pid          => 8812,
            port         => 7927,
            process_name => 'd2 web: 127.0.0.1:7927',
            ssl          => 0,
            status       => 'running',
            workers      => 2,
        };
    };
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        return {
            host         => '127.0.0.1',
            pid          => 8812,
            port         => 7927,
            process_name => 'd2 web: 127.0.0.1:7927',
            ssl          => 0,
            status       => 'running',
            workers      => 2,
        };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7927;
        $polls++;
        return $polls < 2 ? () : (9912);
    };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub {
        my ( undef, $pid ) = @_;
        return $pid == 9912 ? 'starman master' : 'd2 web: 127.0.0.1:7927';
    };
    local *Developer::Dashboard::RuntimeManager::_write_web_state = sub {
        my ( undef, $state ) = @_;
        $written_state = { %{$state} };
        return $state;
    };
    local *Developer::Dashboard::FileRegistry::write = sub {
        my ( undef, $name, $content ) = @_;
        $written_pid = $content if $name eq 'web_pid';
        return 1;
    };
    ok(
        $manager->_web_runtime_ready( 8812, 7927 ),
        '_web_runtime_ready adopts the actual listener pid when Starman replaces the startup wrapper process',
    );
    is( $written_pid, "9912\n", '_web_runtime_ready persists the adopted listener pid for later stop and restart flows' );
    is( $written_state->{pid}, 9912, '_web_runtime_ready writes the adopted listener pid into persisted web state' );
    is( $written_state->{process_name}, 'starman master', '_web_runtime_ready refreshes the process title after adopting the listener pid' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return {
            pid  => 8808,
            port => 7920,
        };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    ok(
        !$manager->_web_runtime_ready( 8808, 7920 ),
        '_web_runtime_ready fails when the web pid survives but no listener appears on the configured port',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return {
            pid => 8808,
        };
    };
    ok(
        !$manager->_web_runtime_ready( 8808, undef ),
        '_web_runtime_ready fails cleanly when neither the requested port nor the recorded runtime port exists',
    );
}

{
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return {
            pid  => 8809,
            port => 7921,
        };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub {
        my ( undef, $port ) = @_;
        return 0 if $port != 7921;
        $polls++;
        return $polls >= 2 ? 1 : 0;
    };
    ok(
        $manager->_web_runtime_ready( 8809, 7921 ),
        '_web_runtime_ready falls back to a local TCP probe when listener pid discovery has not populated yet',
    );
    is( $polls, 4, '_web_runtime_ready only keeps the short confirmation window once the local TCP probe succeeds' );
}

{
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        $polls++;
        return $polls <= 3 ? { pid => 8810, port => 7923 } : undef;
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7923;
        return $polls >= 2 && $polls <= 3 ? (8810) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    ok(
        !$manager->_web_runtime_ready( 8810, 7923 ),
        '_web_runtime_ready fails when the replacement web pid only stays up briefly after first appearing ready',
    );
}

{
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        $polls++;
        return { pid => 8811, port => 7924 };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7924;
        return $polls <= 2 ? (8811) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    ok(
        !$manager->_web_runtime_ready( 8811, 7924 ),
        '_web_runtime_ready fails when the replacement listener disappears while the managed web pid still exists',
    );
}

{
    my @adopted;
    my $running = { pid => 77, port => 7991 };
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_runtime_confirmation_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { die "unexpected sleep\n" };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return $running };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_matches_pid = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (9911) };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub {
        my ( undef, $pid ) = @_;
        return 1 if $pid == 9911;
        return 0 if $pid == 77;
        return 0;
    };
    local *Developer::Dashboard::RuntimeManager::_adopt_web_listener_pid = sub {
        push @adopted, { @_ };
        return;
    };
    ok(
        $manager->_web_runtime_ready( 77, 7991 ),
        '_web_runtime_ready still treats the runtime as listening when a fallback listener appears from another pid namespace',
    );
    is( scalar @adopted, 0, '_web_runtime_ready does not adopt a listener pid when the startup wrapper pid is from a different namespace and the runtime still does not match' );
}

{
    my @adopted;
    my $running = { pid => 88, port => 7992 };
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_runtime_confirmation_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { die "unexpected sleep\n" };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return $running };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_matches_pid = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (9912) };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_adopt_web_listener_pid = sub {
        my ( $self, %args ) = @_;
        push @adopted, \%args;
        return $args{listener_pid};
    };
    ok(
        $manager->_web_runtime_ready( 88, 7992 ),
        '_web_runtime_ready can adopt a fallback listener pid when the runtime is listening and the pid namespace still matches',
    );
    is( $running->{pid}, 9912, '_web_runtime_ready updates the running state pid after adopting the fallback listener pid' );
    is( scalar @adopted, 1, '_web_runtime_ready records one listener adoption for the matching-namespace fallback listener path' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { die "_read_process_title should not run when the listener pid is already recorded\n" };
    my $state = { pid => 9912, status => 'running' };
    is(
        $manager->_adopt_web_listener_pid( listener_pid => 9912, state => $state ),
        undef,
        '_adopt_web_listener_pid returns early when the listener pid is already recorded in state',
    );
    is_deeply(
        $state,
        { pid => 9912, status => 'running' },
        '_adopt_web_listener_pid leaves state unchanged when the listener pid is already recorded',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub {
        my ( undef, $pid ) = @_;
        return "listener:$pid";
    };
    $manager->_write_web_state( { pid => 3030, status => 'running' } );
    is(
        $manager->_adopt_web_listener_pid( listener_pid => 3030 ),
        undef,
        '_adopt_web_listener_pid returns early when persisted web state already records the listener pid',
    );
    is_deeply(
        $manager->web_state,
        { pid => 3030, status => 'running' },
        '_adopt_web_listener_pid leaves persisted web state unchanged when the listener pid is already recorded',
    );
    $manager->_cleanup_web_files;
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return {
            pid  => 9909,
            port => 7925,
        };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7925;
        $polls++;
        return $polls >= 2 ? (9909) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub {
        my ( undef, $port ) = @_;
        return $port == 7925 ? 1 : 0;
    };
    ok(
        $manager->_web_runtime_ready( 8809, 7925 ),
        '_web_runtime_ready accepts the Windows listener shape when the runtime port is live even after the active listener pid differs from the startup pid',
    );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return {
            pid  => 5568,
            port => 7926,
        };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return $port == 7926 ? (5568) : ();
    };
    ok(
        $manager->_web_runtime_ready( -1944, 7926 ),
        '_web_runtime_ready normalizes Windows pseudo-fork startup pids before checking the live listener port',
    );
}

{
    my $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        ReuseAddr => 1,
        Listen    => 1,
    ) or die "Unable to open test listener socket: $!";
    my $port = $listener->sockport;
    ok(
        $manager->_port_accepting_connections($port),
        '_port_accepting_connections returns true when a local TCP listener accepts connections',
    );
    close $listener or die "Unable to close test listener socket: $!";
}

{
    my $attempt = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        $attempt++;
        die "Address already in use\n" if $attempt == 1;
        return 8801;
    };
    is( $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7911 ), 8801, '_restart_web_with_retry retries transient bind failures and returns the restarted pid' );
    is( $attempt, 2, '_restart_web_with_retry retries once before succeeding when the bind race clears' );
}

{
    my %captured;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        my ( undef, %args ) = @_;
        %captured = %args;
        return 8802;
    };
    is( $manager->_restart_web_with_retry, 8802, '_restart_web_with_retry uses the default host and port when none are provided' );
    is_deeply( \%captured, { host => '0.0.0.0', port => 7890, workers => 1, ssl => 0 }, '_restart_web_with_retry forwards default host, port, and worker values to start_web' );
}

{
    my %captured;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        my ( undef, %args ) = @_;
        %captured = %args;
        return 8803;
    };
    is( $manager->_restart_web_with_retry( host => '127.0.0.1', port => 7922, workers => 6 ), 8803, '_restart_web_with_retry accepts an explicit worker count' );
    is_deeply( \%captured, { host => '127.0.0.1', port => 7922, workers => 6, ssl => 0 }, '_restart_web_with_retry forwards explicit worker counts to start_web' );
}

{
    my $attempt = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        $attempt++;
        die "Address already in use\n";
    };
    dies_like(
        sub { $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7912 ) },
        qr/Address already in use/,
        '_restart_web_with_retry rethrows the final bind error after exhausting retries',
    );
    is( $attempt, 20, '_restart_web_with_retry uses the full retry budget before surfacing a persistent bind failure' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub { die "unexpected boom\n" };
    dies_like(
        sub { $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7913 ) },
        qr/unexpected boom/,
        '_restart_web_with_retry surfaces non-bind startup failures immediately',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub { return; };
    dies_like(
        sub { $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7916 ) },
        qr/Unable to restart dashboard web service on 0\.0\.0\.0:7916/,
        '_restart_web_with_retry emits the default error text when start_web returns without a pid or exception',
    );
}

{
    my $attempt = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        $attempt++;
        return 8804 if $attempt == 1;
        return 8805;
    };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub {
        my ( undef, $pid, $port ) = @_;
        return 0 if $port != 7917;
        return 0 if $pid == 8804;
        return 1 if $pid == 8805;
        return 0;
    };
    is(
        $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7917 ),
        8805,
        '_restart_web_with_retry retries when start_web returns a pid that is not actually running',
    );
    is( $attempt, 2, '_restart_web_with_retry retries once after a dead-on-arrival pid response' );
}

{
    my $attempt = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        $attempt++;
        die "Unable to start dashboard web service\n" if $attempt == 1;
        return 8807;
    };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub {
        my ( undef, $pid, $port ) = @_;
        return 1 if $pid == 8807 && $port == 7919;
        return 0;
    };
    is(
        $manager->_restart_web_with_retry( host => '127.0.0.1', port => 7919 ),
        8807,
        '_restart_web_with_retry retries when startup aborts before the web child can report readiness',
    );
    is( $attempt, 2, '_restart_web_with_retry retries once after a transient startup-abort error' );
}

{
    my $attempt = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        $attempt++;
        return 8806;
    };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub { return 0 };
    dies_like(
        sub { $manager->_restart_web_with_retry( host => '127.0.0.1', port => 7918 ) },
        qr/Unable to confirm dashboard web service stayed running on 127\.0\.0\.1:7918/,
        '_restart_web_with_retry fails explicitly when start_web only returns dead-on-arrival pids',
    );
    is( $attempt, 20, '_restart_web_with_retry uses the full retry budget for dead-on-arrival pid responses' );
}

{
    my $attempt = 0;
    my @cleanups;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        $attempt++;
        return $attempt == 1 ? 8815 : 8816;
    };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub {
        my ( undef, $pid, $port ) = @_;
        return $pid == 8816 && $port == 7924 ? 1 : 0;
    };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub {
        push @cleanups, 1;
        return 1;
    };
    is(
        $manager->_restart_web_with_retry( host => '127.0.0.1', port => 7924 ),
        8816,
        '_restart_web_with_retry retries when a replacement web pid fails the startup stability window',
    );
    is( $attempt, 2, '_restart_web_with_retry retries after a briefly-live replacement web pid fails stability checks' );
    is( scalar @cleanups, 1, '_restart_web_with_retry clears persisted web state before retrying a briefly-live replacement web pid' );
}

{
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Local::RuntimeRunner::running_loops = sub {
        $polls++;
        return ( { name => 'alpha.collector', pid => 7002 } );
    };
    ok(
        $manager->_collector_runtime_ready( 'alpha.collector', 7002 ),
        '_collector_runtime_ready returns once the managed collector survives the short confirmation window',
    );
    is( $polls, 3, '_collector_runtime_ready only spends three ready polls proving a healthy collector loop' );
}

{
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Local::RuntimeRunner::running_loops = sub {
        $polls++;
        return $polls <= 2
          ? ( { name => 'alpha.collector', pid => 7001 } )
          : ();
    };
    ok(
        !$manager->_collector_runtime_ready( 'alpha.collector', 7001 ),
        '_collector_runtime_ready fails when a managed collector loop disappears during the startup stability window',
    );
}

{
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Local::RuntimeRunner::running_loops = sub {
        $polls++;
        return ();
    };
    local *Local::RuntimeRunner::loop_state = sub {
        return {
            pid    => $$,
            name   => 'alpha.collector',
            status => 'starting',
        };
    };
    ok(
        $manager->_collector_runtime_ready( 'alpha.collector', $$ ),
        '_collector_runtime_ready falls back to the persisted loop state while the managed process title is not observable yet',
    );
    is( $polls, 0, '_collector_runtime_ready trusts the persisted loop-state fallback without consulting running_loops when the pid is already proven alive' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Local::RuntimeRunner::running_loops = sub {
        die "running_loops should not be consulted while the persisted loop-state fallback already proves the pid is alive\n";
    };
    local *Local::RuntimeRunner::loop_state = sub {
        return {
            pid    => $$,
            name   => 'alpha.collector',
            status => 'starting',
        };
    };
    ok(
        $manager->_collector_runtime_ready( 'alpha.collector', $$ ),
        '_collector_runtime_ready trusts the persisted loop-state fallback before the destructive running_loops cleanup path can run',
    );
}

{
    my $polls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Local::RuntimeRunner::loop_state = sub { return undef };
    local *Local::RuntimeRunner::running_loops = sub {
        $polls++;
        return ();
    };
    ok(
        !$manager->_collector_runtime_ready( 'alpha.collector', 7999 ),
        '_collector_runtime_ready returns false after the stability window expires without ever observing a managed collector loop',
    );
    is( $polls, 1, '_collector_runtime_ready consults running_loops across the full timeout path before giving up' );
}

{
    no warnings 'redefine';
    $runner->{started} = [];
    $runner->{loops} = [];
    $collector_store->write_status( 'missing.collector', {} );
    local *Local::RuntimeRunner::running_loops = sub { return () };

    my $result = $manager->_supervise_collectors_once( names => ['missing.collector'] );
    my $status = $collector_store->read_status('missing.collector') || {};

    is_deeply( $result->{restarted}, [], '_supervise_collectors_once does not report restarts for unknown collectors' );
    is( $result->{attention}[0]{name}, 'missing.collector', '_supervise_collectors_once reports unknown watched collectors in the attention list' );
    is( $status->{watchdog_status}, 'attention_required', '_supervise_collectors_once marks unknown watched collectors as attention_required' );
    ok( $status->{watchdog_last_error}, '_supervise_collectors_once records an explicit error for unknown watched collectors' );
}

{
    no warnings 'redefine';
    $runner->{started} = [];
    $runner->{loops} = [ { name => 'alpha.collector', pid => 4401 } ];
    local *Local::RuntimeRunner::running_loops = sub { return @{ $runner->{loops} } };

    my $result = $manager->_supervise_collectors_once( names => ['alpha.collector'] );

    is_deeply( $result->{restarted}, [], '_supervise_collectors_once skips watchdog work for collectors that are already running' );
    is_deeply( $result->{attention}, [], '_supervise_collectors_once does not raise attention for collectors that are already running' );
}

{
    no warnings 'redefine';
    $runner->{started} = [];
    $runner->{stopped} = [];
    $runner->{loops} = [ { name => 'alpha.collector', pid => 4401 } ];
    my $stale_at = '2001-01-01T00:00:00+0000';
    $collector_store->write_status(
        'alpha.collector',
        {
            last_started_at   => $stale_at,
            last_completed_at => $stale_at,
            running           => 1,
        }
    );
    local *Local::RuntimeRunner::running_loops = sub { return @{ $runner->{loops} } };
    local *Developer::Dashboard::RuntimeManager::_collector_watchdog_stale_seconds = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };

    my $result = $manager->_supervise_collectors_once( names => ['alpha.collector'] );
    my $status = $collector_store->read_status('alpha.collector') || {};

    is_deeply( $runner->{stopped}, ['alpha.collector'], '_supervise_collectors_once stops a live collector loop that stopped making progress' );
    is_deeply( $runner->{started}, ['alpha.collector'], '_supervise_collectors_once restarts a live collector loop that stopped making progress' );
    is( $result->{restarted}[0]{name}, 'alpha.collector', '_supervise_collectors_once reports a restarted stalled collector' );
    is( $status->{watchdog_status}, 'running', '_supervise_collectors_once returns a restarted stalled collector to watchdog-running status' );
    like( $status->{watchdog_last_error}, qr/stopped making progress/, '_supervise_collectors_once records why the watchdog recycled a stalled collector' );
}
{
    no warnings 'redefine';
    $runner->{started} = [];
    $runner->{stopped} = [];
    $runner->{loops} = [ { name => 'alpha.collector', pid => 4402 } ];
    my $stale_at = '2001-01-01T00:00:00+0000';
    $collector_store->write_status(
        'alpha.collector',
        {
            last_started_at   => $stale_at,
            last_completed_at => $stale_at,
            running           => 1,
        }
    );
    local *Local::RuntimeRunner::running_loops = sub { return @{ $runner->{loops} } };
    local *Local::RuntimeRunner::stop_loop = sub {
        my ( $self, $name ) = @_;
        push @{ $self->{stopped} }, $name;
        die "stop stale boom\n";
    };
    local *Developer::Dashboard::RuntimeManager::_collector_watchdog_stale_seconds = sub { return 1 };

    my $result = $manager->_supervise_collectors_once( names => ['alpha.collector'] );
    my $status = $collector_store->read_status('alpha.collector') || {};

    is_deeply( $result->{restarted}, [], '_supervise_collectors_once does not restart a stalled collector when stop_loop fails' );
    is( $result->{attention}[0]{name}, 'alpha.collector', '_supervise_collectors_once reports stalled collectors that fail stop_loop in the attention list' );
    like( $result->{attention}[0]{reason}, qr/stop stale boom/, '_supervise_collectors_once records the stop_loop failure text for stalled collectors' );
    is( $status->{watchdog_status}, 'attention_required', '_supervise_collectors_once marks a stalled collector as attention_required when stop_loop fails' );
    like( $status->{watchdog_last_error}, qr/stop stale boom/, '_supervise_collectors_once persists the stale stop_loop failure in collector status' );
}

{
    no warnings 'redefine';
    $runner->{started} = [];
    $runner->{stopped} = [];
    $runner->{loops} = [];
    $collector_store->write_status(
        'alpha.collector',
        {
            watchdog_attention_required            => 0,
            watchdog_last_error                    => undef,
            watchdog_last_restart_at               => undef,
            watchdog_last_restart_at_epoch         => undef,
            watchdog_last_unexpected_stop_at       => undef,
            watchdog_last_unexpected_stop_at_epoch => undef,
            watchdog_restart_count                 => 0,
            watchdog_restart_window_started_at     => undef,
            watchdog_restart_window_started_at_epoch => undef,
            watchdog_status                        => undef,
        }
    );
    local *Local::RuntimeRunner::running_loops = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };

    my $result = $manager->_supervise_collectors_once( names => ['alpha.collector'] );
    my $status = $collector_store->read_status('alpha.collector') || {};

    is_deeply( $runner->{started}, ['alpha.collector'], '_supervise_collectors_once restarts a missing watched collector' );
    is( $result->{restarted}[0]{name}, 'alpha.collector', '_supervise_collectors_once reports the restarted collector name' );
    is( $status->{watchdog_status}, 'running', '_supervise_collectors_once marks a restarted collector as watchdog-running' );
    is( $status->{watchdog_restart_count}, 1, '_supervise_collectors_once records the first watchdog restart attempt' );
    ok( $status->{watchdog_last_unexpected_stop_at}, '_supervise_collectors_once records when the collector was found unexpectedly stopped' );
    ok( $status->{watchdog_last_restart_at}, '_supervise_collectors_once records when the watchdog restarted the collector' );
    ok( !$status->{watchdog_attention_required}, '_supervise_collectors_once keeps attention_required clear after a successful restart' );
}

{
    no warnings 'redefine';
    $runner->{started} = [];
    $runner->{stopped} = [];
    $runner->{loops} = [];
    local $runner->{fail} = { 'alpha.collector' => "watchdog restart boom\n" };
    local *Local::RuntimeRunner::running_loops = sub { return () };
    $collector_store->write_status(
        'alpha.collector',
        {
            watchdog_attention_required            => 0,
            watchdog_last_error                    => undef,
            watchdog_last_restart_at               => undef,
            watchdog_last_restart_at_epoch         => undef,
            watchdog_last_unexpected_stop_at       => undef,
            watchdog_last_unexpected_stop_at_epoch => undef,
            watchdog_restart_count                 => 1,
            watchdog_restart_window_started_at     => Developer::Dashboard::RuntimeManager::_now_iso8601( tz => 'utc' ),
            watchdog_restart_window_started_at_epoch => time,
            watchdog_status                        => undef,
        }
    );

    my $result = $manager->_supervise_collectors_once( names => ['alpha.collector'] );
    my $status = $collector_store->read_status('alpha.collector') || {};

    is_deeply( $result->{restarted}, [], '_supervise_collectors_once does not report a restart when loop startup fails' );
    is_deeply( $result->{attention}, [], '_supervise_collectors_once keeps restart-failed loops out of the attention list until the threshold is exceeded' );
    is( $status->{watchdog_status}, 'restart_failed', '_supervise_collectors_once records restart_failed when the watchdog cannot restart a collector' );
    is( $status->{watchdog_last_error}, 'watchdog restart boom', '_supervise_collectors_once records the watchdog restart failure text' );
    is( $status->{watchdog_restart_count}, 2, '_supervise_collectors_once still increments the watchdog restart count after a failed restart attempt' );
}

{
    no warnings 'redefine';
    $runner->{started} = [];
    $runner->{stopped} = [];
    $runner->{loops} = [];
    $collector_store->write_status(
        'alpha.collector',
        {
            watchdog_attention_required            => 0,
            watchdog_last_error                    => undef,
            watchdog_last_restart_at               => undef,
            watchdog_last_restart_at_epoch         => undef,
            watchdog_last_unexpected_stop_at       => undef,
            watchdog_last_unexpected_stop_at_epoch => undef,
            watchdog_restart_count                 => 0,
            watchdog_restart_window_started_at     => undef,
            watchdog_restart_window_started_at_epoch => undef,
            watchdog_status                        => undef,
        }
    );
    local *Local::RuntimeRunner::running_loops = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 0 };

    my $result = $manager->_supervise_collectors_once( names => ['alpha.collector'] );
    my $status = $collector_store->read_status('alpha.collector') || {};

    is_deeply( $result->{restarted}, [], '_supervise_collectors_once does not report a restart when the collector dies during watchdog readiness confirmation' );
    is_deeply( $runner->{stopped}, ['alpha.collector'], '_supervise_collectors_once stops a collector loop that dies during watchdog readiness confirmation' );
    is( $status->{watchdog_status}, 'restart_failed', '_supervise_collectors_once records restart_failed when the watchdog restart does not survive readiness confirmation' );
    like( $status->{watchdog_last_error}, qr/Failed to keep collector 'alpha\.collector' running after watchdog restart/, '_supervise_collectors_once records an explicit watchdog readiness failure error' );
}

{
    no warnings 'redefine';
    $runner->{started} = [];
    $runner->{loops} = [];
    my $now = Developer::Dashboard::RuntimeManager::_now_iso8601( tz => 'utc' );
    $collector_store->write_status(
        'alpha.collector',
        {
            watchdog_restart_count            => 1,
            watchdog_restart_window_started_at => $now,
            watchdog_status                   => 'running',
        }
    );
    local *Local::RuntimeRunner::running_loops = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_collector_restart_limit = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };

    my $result = $manager->_supervise_collectors_once( names => ['alpha.collector'] );
    my $status = $collector_store->read_status('alpha.collector') || {};

    is_deeply( $runner->{started}, [], '_supervise_collectors_once stops restarting once the watchdog threshold is exceeded' );
    is( $result->{attention}[0]{name}, 'alpha.collector', '_supervise_collectors_once reports the collector that now needs attention' );
    is( $status->{watchdog_status}, 'attention_required', '_supervise_collectors_once marks repeatedly-crashing collectors as attention_required' );
    ok( $status->{watchdog_attention_required}, '_supervise_collectors_once raises the attention_required flag after too many restarts' );
    is( $status->{watchdog_restart_count}, 2, '_supervise_collectors_once increments the restart count before raising attention_required' );
}

{
    no warnings 'redefine';
    my $cron_name = 'nightly.cron';
    my $heartbeat = Developer::Dashboard::RuntimeManager::_now_iso8601( tz => 'local' );
    my $window_started = Developer::Dashboard::RuntimeManager::_now_iso8601( tz => 'utc' );
    local *Developer::Dashboard::Config::collectors = sub {
        return [ { name => $cron_name, command => 'true', cron => '0 7-8 * * *' } ];
    };
    $collector_store->write_status(
        $cron_name,
        {
            last_completed_at                       => '2020-01-01T00:00:00Z',
            watchdog_restart_count                  => 3,
            watchdog_restart_window_started_at       => $window_started,
            watchdog_restart_window_started_at_epoch => time,
            watchdog_status                         => 'running',
        }
    );
    $runner->{started} = [];
    $runner->{stopped} = [];
    local *Local::RuntimeRunner::running_loops = sub {
        return ( { name => $cron_name, pid => 98765, state => { heartbeat_at => $heartbeat, schedule => 'cron' } } );
    };
    local *Developer::Dashboard::RuntimeManager::_collector_restart_limit = sub { return 3 };
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };

    my $result = $manager->_supervise_collectors_once( names => [$cron_name] );
    my $status = $collector_store->read_status($cron_name) || {};

    is_deeply( $result->{attention}, [], 'a healthy cron loop awaiting its next scheduled window does not raise a watchdog warning' );
    is_deeply( $result->{restarted}, [], 'a healthy cron loop is not restarted just because its last job execution is old' );
    is_deeply( $runner->{started}, [], 'the watchdog does not start a replacement for an idle but healthy cron loop' );
    is_deeply( $runner->{stopped}, [], 'the watchdog does not stop an idle but healthy cron loop' );
    is( $status->{watchdog_restart_count}, 3, 'idle cron waiting does not increment the restart-warning counter' );
    is( $status->{watchdog_status}, 'running', 'idle cron waiting leaves watchdog status running' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_STALL_GRACE_SECONDS} = 17;
    is( $manager->_collector_stall_grace_seconds, 17, '_collector_stall_grace_seconds honours the explicit environment override' );
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_STALL_GRACE_SECONDS} = 'bogus';
    is( $manager->_collector_stall_grace_seconds, 10, '_collector_stall_grace_seconds falls back to the default grace period for invalid values' );
    is(
        $manager->_collector_watchdog_stale_seconds( { interval => 2.5, timeout_ms => 1500 } ),
        14,
        '_collector_watchdog_stale_seconds adds interval, timeout_ms, and grace together before rounding up',
    );
    is(
        $manager->_collector_watchdog_stale_seconds( { interval => 4, timeout => 6 } ),
        20,
        '_collector_watchdog_stale_seconds uses timeout when timeout_ms is absent',
    );
    is(
        $manager->_collector_watchdog_stale_seconds( { command => 'dashboard system-temp cpu', interval => 5 } ),
        70,
        '_collector_watchdog_stale_seconds uses the throttled effective interval for d2 subcommand collectors',
    );
    is(
        $manager->_collector_watchdog_stale_seconds( {} ),
        70,
        '_collector_watchdog_stale_seconds falls back to the default interval, timeout, and grace values',
    );
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS};
    local $ENV{PERL5OPT};
    local $ENV{HARNESS_PERL_SWITCHES};
    local $INC{'Devel/Cover.pm'};
    delete $INC{'Devel/Cover.pm'};
    is( $manager->_runtime_stability_polls, 300, '_runtime_stability_polls keeps the default widened poll count when no override or instrumentation is active' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS};
    is( $manager->_runtime_confirmation_polls, 3, '_runtime_confirmation_polls keeps the default short confirmation window when no override is active' );
}

{
    my @start_attempts;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub {
        my ( $self, %args ) = @_;
        push @start_attempts, { %args };
        die "Address already in use\n" if @start_attempts == 1;
        return 7123;
    };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::stop_collectors = sub { return () };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return () };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => 7123 } };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub { return 1 };
    my $result = $manager->serve_all(
        host    => '127.0.0.1',
        port    => 7999,
        workers => 2,
        ssl     => 0,
    );
    is( $result->{pid}, 7123, 'serve_all retries transient background startup failures and returns the recovered web pid' );
    is( scalar @start_attempts, 2, 'serve_all retries once after a transient bind-style startup failure' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS} = 5;
    is( $manager->_runtime_confirmation_polls, 5, '_runtime_confirmation_polls accepts an explicit environment override' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS} = 0;
    is( $manager->_runtime_confirmation_polls, 3, '_runtime_confirmation_polls ignores invalid environment overrides' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS} = 12;
    local $ENV{PERL5OPT};
    local $ENV{HARNESS_PERL_SWITCHES};
    is( $manager->_runtime_stability_polls, 12, '_runtime_stability_polls accepts an explicit environment override' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS} = 'broken';
    local $ENV{PERL5OPT};
    local $ENV{HARNESS_PERL_SWITCHES};
    is( $manager->_runtime_stability_polls, 300, '_runtime_stability_polls ignores invalid environment overrides and falls back to the widened default' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS};
    local $ENV{PERL5OPT};
    local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
    is( $manager->_runtime_stability_polls, 300, '_runtime_stability_polls widens the startup grace window when coverage instrumentation is active' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS};
    local $ENV{PERL5OPT};
    local $ENV{HARNESS_PERL_SWITCHES};
    local $INC{'Devel/Cover.pm'} = 'Devel/Cover.pm';
    is(
        $manager->_runtime_stability_polls,
        300,
        '_runtime_stability_polls widens the startup grace window when Devel::Cover is already loaded even after coverage env vars are cleared',
    );
}

{
    is_deeply(
        [ $manager->_listener_socket_inodes_for_port(0) ],
        [],
        '_listener_socket_inodes_for_port returns an empty list when no port is requested',
    );
}

{
    my $proc_root = tempdir( CLEANUP => 1 );
    my $tcp = "$proc_root/tcp";
    my $tcp6 = "$proc_root/tcp6";
    open my $tcp_fh, '>', $tcp or die "Unable to write $tcp: $!";
    print {$tcp_fh} <<'TCP';
  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode

bad line without fields
   9: 0100007F:1EE5 00000000:0000 0A
  10: 0100007F:1EE5 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0
  11: 0100007F:1EE5 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 0 1 0000000000000000 100 0 0 10 0
   0: 0100007F:1EE5 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 11111 1 0000000000000000 100 0 0 10 0
   2: 0100007F:1EE5 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 11111 1 0000000000000000 100 0 0 10 0
   1: 0100007F:1EE5 00000000:0000 01 00000000:00000000 00:00000000 00000000     0        0 22222 1 0000000000000000 100 0 0 10 0
TCP
    close $tcp_fh;
    open my $tcp6_fh, '>', $tcp6 or die "Unable to write $tcp6: $!";
    print {$tcp6_fh} <<'TCP6';
  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
   0: 00000000000000000000000000000000:1EE5 00000000000000000000000000000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 33333 1 0000000000000000 100 0 0 10 0
TCP6
    close $tcp6_fh;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_socket_table_paths = sub { return ( $tcp, $tcp6 ) };
    is_deeply(
        [ $manager->_listener_socket_inodes_for_port(7909) ],
        [ 11111, 33333 ],
        '_listener_socket_inodes_for_port parses listening socket inodes from proc tcp tables',
    );
}

{
    my $proc_root = tempdir( CLEANUP => 1 );
    my $fd_dir = "$proc_root/4321/fd";
    my $other_fd_dir = "$proc_root/9876/fd";
    require File::Path;
    File::Path::make_path( $fd_dir, $other_fd_dir );
    open my $plain_fh, '>', "$proc_root/plain-target" or die "Unable to write plain target: $!";
    print {$plain_fh} "plain\n";
    close $plain_fh;
    symlink 'socket:[11111]', "$fd_dir/3" or die "Unable to create socket symlink: $!";
    symlink 'socket:[33333]', "$fd_dir/4" or die "Unable to create socket symlink: $!";
    symlink 'socket:[44444]', "$other_fd_dir/5" or die "Unable to create socket symlink: $!";
    symlink "$proc_root/plain-target", "$other_fd_dir/6" or die "Unable to create plain symlink: $!";
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_process_fd_paths = sub { return ( 'nonsense-path', glob "$proc_root/[0-9]*/fd/*" ) };
    is_deeply(
        [ sort { $a <=> $b } $manager->_process_pids_for_socket_inodes( { 11111 => 1, 33333 => 1 } ) ],
        [4321],
        '_process_pids_for_socket_inodes maps matching socket inodes back to owning process ids',
    );
}

{
    is_deeply(
        [ $manager->_process_pids_for_socket_inodes( {} ) ],
        [],
        '_process_pids_for_socket_inodes returns an empty list for an empty inode lookup table',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_socket_inodes_for_port = sub {
        my ( undef, $port ) = @_;
        return $port == 7910 ? (11111, 22222) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_process_pids_for_socket_inodes = sub {
        my ( undef, $inode_lookup ) = @_;
        return exists $inode_lookup->{11111} && exists $inode_lookup->{22222} ? (7001, 7002) : ();
    };
    is_deeply(
        [ $manager->_listener_pids_for_port_via_proc(7910) ],
        [7001, 7002],
        '_listener_pids_for_port_via_proc joins proc socket inode discovery with pid lookup',
    );
}

{
    is_deeply(
        [ $manager->_listener_socket_table_paths ],
        [ '/proc/net/tcp', '/proc/net/tcp6' ],
        '_listener_socket_table_paths returns the expected proc tcp sources',
    );
    if ( -d '/proc' ) {
        ok( scalar $manager->_process_fd_paths, '_process_fd_paths returns proc fd entries on Linux hosts' );
    }
    else {
        is_deeply(
            [ $manager->_process_fd_paths ],
            [],
            '_process_fd_paths returns no proc fd entries when procfs is absent',
        );
    }
}

{
    no warnings 'redefine';
    my $original_read = Developer::Dashboard::FileRegistry->can('read');
    local *Developer::Dashboard::FileRegistry::read = sub {
        my ( $self, $name ) = @_;
        return "$$\n" if $name eq 'web_pid';
        return $original_read->( $self, $name );
    };
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        return { pid => $$, host => '127.0.0.1', port => 7907, status => 'running' };
    };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ($$) };
    my $state = $manager->running_web;
    is( $state->{pid}, $$, 'running_web trusts the recorded live listener pid for a running state even after the server process renames itself' );
}

{
    my $listener = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', 'sleep 30' ],
        {},
    );
    no warnings 'redefine';
    my $original_read = Developer::Dashboard::FileRegistry->can('read');
    local *Developer::Dashboard::FileRegistry::read = sub {
        my ( $self, $name ) = @_;
        return "$$\n" if $name eq 'web_pid';
        return $original_read->( $self, $name );
    };
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        return { pid => $$, host => '127.0.0.1', port => 7919, status => 'running' };
    };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ($listener) };
    my $state = $manager->running_web;
    is( $state->{pid}, $$, 'running_web trusts the recorded master pid when the managed port is still held by a separate listener worker pid' );
    ok( Developer::Dashboard::GoRoutine::terminate_process( $listener, 'KILL' ),
        'separate listener worker is terminated through the GoRoutine process API' );
    Developer::Dashboard::GoRoutine::wait_process($listener);
}

{
    no warnings 'redefine';
    $files->write( 'web_pid', "$$\n" );
    $manager->_write_web_state( { pid => $$, host => '127.0.0.1', port => 7920, status => 'running' } );
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    my $state = $manager->running_web;
    is( $state->{pid}, $$, 'running_web trusts the recorded running pid even when listener discovery cannot identify the managed process shape' );
    $manager->_cleanup_web_files;
}

{
    my $listener = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', q{$SIG{TERM} = 'IGNORE'; sleep 30;} ],
        {},
    );
    my $calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return $calls++ == 0 ? { pid => $listener, port => 7908 } : undef;
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ($listener) };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    is( $manager->stop_web, $listener, 'stop_web returns the recorded pid while it also tracks listener pids on the bound port' );
    ok( !Developer::Dashboard::GoRoutine::process_running($listener), 'stop_web escalates listener-port pids to KILL when they remain alive after TERM' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        return {
            pid    => 111_111,
            host   => '127.0.0.1',
            port   => 7917,
            status => 'running',
        };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return $port == 7917 ? (333_333) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub {
        my ( undef, $pid ) = @_;
        return $pid == 333_333 ? 'starman master' : undef;
    };
    # Keep this fake-listener fixture independent of any real web service
    # launched by other tests earlier in the same test file.
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { die "_cleanup_web_files should not run while a saved listener still exists\n" };
    my $running = $manager->running_web;
    is( $running->{pid}, 333_333, 'running_web falls back to the saved listener pid when the real listener no longer keeps the dashboard wrapper title' );
    is( $running->{port}, 7917, 'running_web keeps the persisted port when it resolves the live listener from saved state' );
    is( $running->{process_name}, 'starman master', 'running_web records the actual listener process title when using saved-state listener fallback' );
}

{
    my $late_listener = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', q{$SIG{TERM} = 'IGNORE'; sleep 30;} ],
        {},
    );
    my $running_calls  = 0;
    my $listener_calls = 0;
    my $wait_calls     = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return $running_calls++ == 0 ? { pid => $late_listener, port => 7918 } : undef;
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        return $listener_calls++ == 0 ? () : ($late_listener);
    };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub {
        return $wait_calls++ == 0 ? 0 : 1;
    };
    is( $manager->stop_web, $late_listener, 'stop_web returns the recorded pid when it has to re-probe the bound port for late listeners' );
    ok( !Developer::Dashboard::GoRoutine::process_running($late_listener), 'stop_web kills late-discovered listener pids after an initial port-release timeout' );
}

{
    my $listener = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', q{$SIG{TERM} = sub { exit 0 }; while (1) { sleep 0.1; }} ],
        {},
    );
    sleep 0.2;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return };
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        return {
            pid    => 444_444,
            host   => '127.0.0.1',
            port   => 7919,
            status => 'running',
        };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return $port == 7919 ? ($listener) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
    my $stopped = $manager->stop_web;
    is( $stopped, 444_444, 'stop_web preserves the saved managed pid even when it has to terminate a fallback listener pid from persisted state' );
    ok( !Developer::Dashboard::GoRoutine::process_running($listener), 'stop_web terminates the saved listener pid resolved from persisted web state' );
}

{
    no warnings 'redefine';
    # _read_process_title takes the process-table branch on Windows and
    # never reaches the ps fallback these stubs pin (build #266 failed
    # this test on Windows with got undef). Force the POSIX branch so
    # the ps fallback is exercised on every host.
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( "ps fallback title\n", undef, 0 ) };
    is( $manager->_read_process_title(999_999_999), 'ps fallback title', '_read_process_title falls back to ps output when /proc cmdline is unavailable' );
}
ok( !defined $manager->_read_process_title(999_999_998), '_read_process_title returns undef when ps also cannot resolve the pid' );

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 0 };
    my $ps_title = $manager->_read_process_title($$);
    like( $ps_title, qr/\S/, '_read_process_title can execute the ps fallback path directly when procfs is disabled' );
}

# Portable procfs title tests: test the actual parser on hosts without /proc.
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_slurp_proc_file = sub {
        return "dashboard\x00worker\x00";
    };
    is( $manager->_read_process_title(424242), 'dashboard worker',
        '_read_process_title decodes procfs NUL-delimited data on every platform' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_slurp_proc_file = sub { return undef };
    is( $manager->_read_process_title(424242), undef,
        '_read_process_title returns undef for an unreadable procfs entry' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_slurp_proc_file = sub { return '' };
    is( $manager->_read_process_title(424242), undef,
        '_read_process_title returns undef for an empty procfs entry' );
}

# Exercise the actual procfs state parser on all hosts rather than relying
# on the Linux-only /proc/$pid/stat precondition.
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_slurp_proc_file = sub {
        return "424242 (example worker) S 1 2 3\n";
    };
    is( $manager->_read_process_state(424242), 'S',
        '_read_process_state parses a portable procfs stat fixture' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_slurp_proc_file = sub { return undef };
    is( $manager->_read_process_state(424242), undef,
        '_read_process_state handles unreadable procfs stat data' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_slurp_proc_file = sub { return 'invalid stat payload' };
    is( $manager->_read_process_state(424242), undef,
        '_read_process_state handles invalid procfs stat data' );
}
{
    my $proc_fixture = File::Spec->catdir( $home, 'runtime-proc-fixture' );
    mkdir $proc_fixture or die "Unable to create $proc_fixture: $!";
    local $Developer::Dashboard::RuntimeManager::PROCFS_ROOT = $proc_fixture;
    is( $manager->_procfs_available, 1, '_procfs_available detects an existing directory' );
    my $stat = File::Spec->catfile( $proc_fixture, 'stat' );
    open my $fh, '>', $stat or die "Unable to create $stat: $!";
    print {$fh} "fixture text\n";
    close $fh or die "Unable to close $stat: $!";
    is( $manager->_slurp_proc_file($stat), "fixture text\n",
        '_slurp_proc_file reads an existing fixture file' );
    is( $manager->_slurp_proc_file( File::Spec->catfile( $proc_fixture, 'missing' ) ),
        undef, '_slurp_proc_file rejects a missing fixture file' );
}

SKIP: {
    skip '_read_process_state direct procfs coverage requires /proc', 1 if !-r "/proc/$$/stat";
    like( $manager->_read_process_state($$), qr/^[A-Z]$/, '_read_process_state reads the direct procfs state code for the current process' );
}

ok( $manager->_process_exists($$), '_process_exists returns true for the current runtime process' );
ok( !defined $manager->_read_process_state(999_999_998), '_read_process_state returns undef when ps also cannot resolve the pid' );

{
    no warnings 'redefine';
    # Same Windows routing as the ps-fallback title test above:
    # _read_process_state returns early on Windows and never reaches
    # the ps fallback these stubs pin (build #269 failed this test on
    # Windows with got undef). Force the POSIX branch.
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( "Z+\n", undef, 0 ) };
    is( $manager->_read_process_state(999_999_999), 'Z', '_read_process_state falls back to ps output when procfs state data is unavailable' );
}

{
    no warnings 'redefine';
    # Same as above, and ps itself does not exist on Windows, so the
    # fallback's ps invocation is stubbed too: the real function still
    # takes the ps path directly and parses its output, which is what
    # this test pins.
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( "R\n", undef, 0 ) };
    like( $manager->_read_process_state($$), qr/^[A-Z]$/, '_read_process_state can execute the ps fallback path directly when procfs is disabled' );
}

SKIP: {
    skip '_read_process_state invalid procfs parse coverage requires /proc', 1 if !-r "/proc/$$/stat";
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_slurp_proc_file = sub { return "broken stat payload\n" };
    is( $manager->_read_process_state($$), undef, '_read_process_state returns undef when procfs data cannot be parsed' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_reap_child_process = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_read_process_state = sub { return 'Z' };
    local *Developer::Dashboard::RuntimeManager::_process_exists     = sub { return 1 };
    ok( !$manager->_pid_is_running(4242), '_pid_is_running treats zombie runtime pids as stopped even when signal 0 still succeeds' );
}

{
    no warnings 'redefine';
    $manager->_write_web_state( { pid => 4242, host => 'zombie.host', port => 4242, status => 'running' } );
    $files->write( 'web_pid', "4242\n" );
    local *Developer::Dashboard::RuntimeManager::_pid_is_running     = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return () };
    ok( !defined $manager->running_web, 'running_web treats a zombie saved web pid as stopped instead of preserving stale running state' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return };
    local *Developer::Dashboard::RuntimeManager::_read_process_title      = sub { return };
    ok( !$manager->_is_managed_web($$), '_is_managed_web returns false when a live pid has no readable title' );
}

{
    my $child_script = sprintf q{
        use lib q{%s};
        use Developer::Dashboard::PathRegistry;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::RuntimeManager;
        my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
        my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
        my $manager = bless { paths => $paths, files => $files }, 'Developer::Dashboard::RuntimeManager';
        $manager->_write_web_state({ pid => $$, status => 'running' });
        $manager->_shutdown_web('stopped');
    }, $repo_lib;
    my $child = _spawn_perl_fixture(
        $child_script,
        { env => { HOME => $home, DEVELOPER_DASHBOARD_STATE_ROOT => $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} } },
    );
    is( Developer::Dashboard::GoRoutine::wait_process($child), 0,
        '_shutdown_web process fixture completes successfully through GoRoutine' );
    my $state = {};
    for ( 1 .. 20 ) {
        $state = $manager->web_state || {};
        last if ( $state->{status} || '' ) eq 'stopped';
        sleep 0.1;
    }
    is( $state->{status}, 'stopped', '_shutdown_web writes the terminal status before exit' );
    $manager->_cleanup_web_files;
}

{
    my $child_script = sprintf q{
        use lib q{%s};
        use Developer::Dashboard::PathRegistry;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::RuntimeManager;
        my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
        my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
        my $manager = bless { paths => $paths, files => $files }, 'Developer::Dashboard::RuntimeManager';
        $manager->_cleanup_web_files;
        $manager->_shutdown_web();
    }, $repo_lib;
    my $child = _spawn_perl_fixture(
        $child_script,
        { env => { HOME => $home, DEVELOPER_DASHBOARD_STATE_ROOT => $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} } },
    );
    is( Developer::Dashboard::GoRoutine::wait_process($child), 0,
        '_shutdown_web default-state process fixture completes successfully through GoRoutine' );
    is(
        state_field( settled_web_state( $manager, 'stopped' ), 'status' ),
        'stopped',
        '_shutdown_web writes a default stopped status when no previous web state exists',
    );
    $manager->_cleanup_web_files;
}

{
    no warnings 'redefine';
    local *POSIX::_exit = sub { return 0 };
    $manager->_cleanup_web_files;
    is( $manager->_shutdown_web(), 0, '_shutdown_web in-process path also writes a default empty state before exiting when no prior state exists' );
    is(
        state_field( settled_web_state( $manager, 'stopped' ), 'status' ),
        'stopped',
        '_shutdown_web in-process default path records the stopped status with an empty starting state',
    );
    $manager->_cleanup_web_files;
}

{
    no warnings 'redefine';
    local *POSIX::_exit = sub { return 0 };
    $manager->_write_web_state( { pid => 1234, status => 'running' } );
    is( $manager->_shutdown_web('stopped'), 0, '_shutdown_web returns the stubbed POSIX::_exit value when called in-process' );
    my $shutdown_state = settled_web_state( $manager, 'stopped' );
    is( state_field( $shutdown_state, 'pid' ), $$ + 0, '_shutdown_web rewrites the final web state pid to the current process in-process' );
    is( state_field( $shutdown_state, 'status' ), 'stopped', '_shutdown_web keeps the requested stopped status when exiting in-process' );
    $manager->_cleanup_web_files;
}

{
    no warnings 'redefine';
    local *POSIX::_exit = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub {
        return { watched_names => [ 'alpha.collector', 'beta.collector', 'gamma.collector' ] };
    };
    my @remaining = $manager->_collector_supervisor_targets_without( ['beta.collector'] );
    is_deeply(
        \@remaining,
        [ 'alpha.collector', 'gamma.collector' ],
        '_collector_supervisor_targets_without removes only the requested watched collector names',
    );
    $manager->_write_collector_supervisor_state( { watched_names => ['alpha.collector'] } );
    open my $pid_fh, '>', $manager->_collector_supervisor_pidfile or die $!;
    print {$pid_fh} "12345\n";
    close $pid_fh;
    is( $manager->_shutdown_collector_supervisor('stopped'), 0, '_shutdown_collector_supervisor returns the stubbed POSIX::_exit value when called in-process' );
    ok( !-f $manager->_collector_supervisor_pidfile, '_shutdown_collector_supervisor removes the supervisor pidfile in-process' );
    ok( !-f $manager->_collector_supervisor_statefile, '_shutdown_collector_supervisor removes the supervisor statefile in-process' );
}

{
    local $runner->{started} = [];
    local $runner->{loops}   = [];
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };
    my @started = $manager->start_collectors( names => ['beta.collector'] );
    is_deeply(
        [ map { $_->{name} } @started ],
        ['beta.collector'],
        'start_collectors can scope startup to one requested collector name',
    );
}

{
    my $manual_home = tempdir(CLEANUP => 1);
    my $manual_paths = Developer::Dashboard::PathRegistry->new( home => $manual_home );
    my $manual_files = Developer::Dashboard::FileRegistry->new( paths => $manual_paths );
    my $manual_config = Developer::Dashboard::Config->new( files => $manual_files, paths => $manual_paths );
    $manual_config->save_global(
        {
            collectors => [
                {
                    name    => 'broken.collector',
                    command => 'true',
                    cwd     => 'home',
                },
            ],
        }
    );
    my $manual_runner = Local::RuntimeRunner->new;
    my $manual_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub { return Local::RuntimeServer->new( foreground_file => "$manual_home/broken.txt", host => '127.0.0.1', port => 7992 ) },
        config      => $manual_config,
        files       => $manual_files,
        paths       => $manual_paths,
        runner      => $manual_runner,
    );
    local $manual_runner->{fail} = { 'broken.collector' => "named start failed\n" };
    my $error = eval { $manual_manager->start_named_collector( name => 'broken.collector' ); 1 } ? '' : $@;
    like( $error, qr/Failed to start collector 'broken\.collector': named start failed/, 'start_named_collector surfaces loop startup failures explicitly' );

    no warnings 'redefine';
    local $manual_runner->{fail} = {};
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 0 };
    $error = eval { $manual_manager->start_named_collector( name => 'broken.collector' ); 1 } ? '' : $@;
    like( $error, qr/Failed to keep collector 'broken\.collector' running after startup/, 'start_named_collector fails explicitly when the named collector never becomes runtime-ready' );
}

{
    local $runner->{loops} = [ { name => 'alpha.collector', pid => 4101 } ];
    no warnings 'redefine';
    local *Local::RuntimeRunner::stop_loop = sub {
        my ( $self, $name ) = @_;
        die "stop failed\n" if $name eq 'alpha.collector';
        return 1;
    };
    my $error = eval { $manager->stop_collectors( structured => 1 ); 1 } ? '' : $@;
    like( $error, qr/Failed to stop collector 'alpha\.collector': stop failed/, 'stop_collectors surfaces loop stop failures explicitly' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    local *POSIX::setsid = sub { die "setsid should not run on Windows\n" };
    ok( $manager->_detach_web_process_session, '_detach_web_process_session skips POSIX::setsid on Windows web lifecycle management' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    my $fakebin = tempdir( CLEANUP => 1 );
    # The fake taskkill must be executable on the host that runs it: a
    # shell script on POSIX, a batch file on Windows. A bare 'taskkill'
    # with no extension is not runnable on Windows and the ':' PATH
    # join is wrong there too, so on a real Windows host the fake
    # never ran, its args file was never written, and the read below
    # died (build #269 exited 2 just after test 395). The Unix legs
    # only passed because the shell script runs there.
    my $is_windows_host = $^O eq 'MSWin32';
    my $taskkill = File::Spec->catfile( $fakebin, $is_windows_host ? 'taskkill.bat' : 'taskkill' );
    my $args_file = File::Spec->catfile( $fakebin, 'taskkill.args' );
    open my $taskkill_fh, '>', $taskkill or die "Unable to write $taskkill: $!";
    if ($is_windows_host) {
        print {$taskkill_fh} "\@echo off\r\n";
        print {$taskkill_fh} 'echo %* > "' . $args_file . "\"\r\n";
        print {$taskkill_fh} "exit /b 0\r\n";
    }
    else {
        print {$taskkill_fh} <<"SCRIPT";
#!/bin/sh
printf '%s\n' "\$*" > "$args_file"
exit 0
SCRIPT
    }
    close $taskkill_fh or die "Unable to close $taskkill: $!";
    chmod 0755, $taskkill or die "Unable to chmod $taskkill: $!";
    local $ENV{PATH} = join( $is_windows_host ? ';' : ':', $fakebin, ( $ENV{PATH} || '' ) );
    is(
        $manager->_send_signal( 'TERM', 2372, 5868 ),
        2,
        '_send_signal returns the number of requested Windows process ids when taskkill succeeds',
    );
    open my $taskkill_args_fh, '<', $args_file
      or die "Unable to read $args_file: $!";
    local $/;
    my $taskkill_args = <$taskkill_args_fh>;
    close $taskkill_args_fh or die "Unable to close $args_file: $!";
    like( $taskkill_args, qr{/PID 2372 /PID 5868 /T /F}, '_send_signal shells out to Windows taskkill with every requested pid plus tree and force flags' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    my @calls;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        my ($code) = @_;
        push @calls, 'capture';
        return ( '', '', 0 );
    };
    is( $manager->_send_signal( 'TERM', 2372, 5868 ), 2, '_send_signal returns the number of requested Windows process ids when taskkill succeeds' );
    is_deeply( \@calls, ['capture'], '_send_signal uses the Windows taskkill path instead of Perl kill on Windows' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    # DD-753: RuntimeManager resolves the PowerShell executable now instead of
    # hardcoding it. Forcing OS_NAME makes is_windows true, but command_in_path
    # still finds nothing on this host and C:\Windows does not exist, so the
    # resolver returns '' and the branch is skipped. Stub it, as t/100 does.
    local *Developer::Dashboard::RuntimeManager::_powershell_command = sub { return 'pwsh' };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        return ( '', 'ERROR: The process "3996" not found.', 128 );
    };
    is(
        $manager->_send_signal( 'TERM', 3996 ),
        1,
        '_send_signal treats already-gone Windows process ids as a successful no-op during shutdown',
    );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    # DD-753: RuntimeManager resolves the PowerShell executable now instead of
    # hardcoding it. Forcing OS_NAME makes is_windows true, but command_in_path
    # still finds nothing on this host and C:\Windows does not exist, so the
    # resolver returns '' and the branch is skipped. Stub it, as t/100 does.
    local *Developer::Dashboard::RuntimeManager::_powershell_command = sub { return 'pwsh' };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        return ( "taskkill: command not found\n", '', 127 );
    };
    is(
        $manager->_send_signal( 'TERM', 4001 ),
        1,
        '_send_signal also treats stdout not-found taskkill failures as a successful no-op on Windows shutdown',
    );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    # DD-753: RuntimeManager resolves the PowerShell executable now instead of
    # hardcoding it. Forcing OS_NAME makes is_windows true, but command_in_path
    # still finds nothing on this host and C:\Windows does not exist, so the
    # resolver returns '' and the branch is skipped. Stub it, as t/100 does.
    local *Developer::Dashboard::RuntimeManager::_powershell_command = sub { return 'pwsh' };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        return ( '', 'taskkill hard failure', 5 );
    };
    # fb4897d5: _send_signal forgives a non-zero taskkill exit when every
    # target is verifiably gone, so the die only fires when a target is
    # still alive. Pin the target alive here, or the assertion depends on
    # whether pid 4002 happens to exist on the test host.
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 1 };
    my $send_ok = eval { $manager->_send_signal( 'TERM', 4002 ); 1 };
    ok( !$send_ok, '_send_signal dies on unexpected Windows taskkill failures for shutdown signals' );
    like( $@, qr/Failed to stop Windows process ids 4002: taskkill hard failure/, '_send_signal surfaces unexpected Windows taskkill failures explicitly' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    is(
        Developer::Dashboard::RuntimeManager::_powershell_single_quote(q{C:\Users\O'Hara\AppData}),
        q{'C:\Users\O''Hara\AppData'},
        '_powershell_single_quote doubles embedded single quotes for PowerShell literals',
    );

    my $fakebin = tempdir( CLEANUP => 1 );
    # The fake powershell must be executable on the host that runs it:
    # a shell script on POSIX, a batch file on Windows. The product
    # resolves powershell through _powershell_command (PATHEXT-aware),
    # so the .bat is found and runs through cmd; a bare 'powershell'
    # with no extension is not runnable on Windows and the ':' PATH
    # join is wrong there too (same shape as the taskkill fake, build
    # #269). The Unix legs only passed because the shell script runs
    # there.
    my $is_windows_host = $^O eq 'MSWin32';
    my $powershell = File::Spec->catfile( $fakebin, $is_windows_host ? 'powershell.bat' : 'powershell' );
    my $powershell_args = File::Spec->catfile( $fakebin, 'powershell.args' );
    my $stdout_log = $files->dashboard_log;
    my $stderr_log = $stdout_log . '.stderr';
    open my $ps_fh, '>', $powershell or die "Unable to write $powershell: $!";
    if ($is_windows_host) {
        print {$ps_fh} "\@echo off\r\n";
        print {$ps_fh} 'echo %* > "' . $powershell_args . "\"\r\n";
        print {$ps_fh} "echo 42424\r\n";
        print {$ps_fh} "exit /b 0\r\n";
    }
    else {
        print {$ps_fh} <<"SCRIPT";
#!/bin/sh
printf '%s\\n' "\$*" > "$powershell_args"
printf '%s\\n' 42424
exit 0
SCRIPT
    }
    close $ps_fh or die "Unable to close $powershell: $!";
    chmod 0755, $powershell or die "Unable to chmod $powershell: $!";
    local $ENV{PATH} = join( $is_windows_host ? ';' : ':', $fakebin, ( $ENV{PATH} || '' ) );
    my $spawned_pid = $manager->_spawn_windows_background_command(
        q{C:\Program Files\Perl\perl.exe},
        'script with space.ps1',
        q{O'Hara},
    );
    is( $spawned_pid, 42424, '_spawn_windows_background_command returns the detached Windows process id written by the helper' );
    open my $args_fh, '<', File::Spec->catfile( $fakebin, 'powershell.args' )
      or die "Unable to read $fakebin/powershell.args: $!";
    local $/;
    my $args = <$args_fh>;
    close $args_fh or die "Unable to close $fakebin/powershell.args: $!";
    like( $args, qr/Start-Process/, '_spawn_windows_background_command shells out through Start-Process' );
    like( $args, qr/'C:\\Program Files\\Perl\\perl\.exe'/, '_spawn_windows_background_command quotes the Windows executable path for PowerShell' );
    like( $args, qr/'script with space\.ps1'/, '_spawn_windows_background_command quotes arguments with spaces for PowerShell' );
    like( $args, qr/'O''Hara'/, '_spawn_windows_background_command escapes embedded single quotes for PowerShell' );
    like( $args, qr/\Q$stdout_log\E/, '_spawn_windows_background_command redirects stdout to the d2 log' );
    like( $args, qr/\Q$stderr_log\E/, '_spawn_windows_background_command redirects stderr to the dashboard error log' );

    open my $ps_fail_fh, '>', $powershell or die "Unable to rewrite $powershell: $!";
    if ($is_windows_host) {
        print {$ps_fail_fh} "\@echo off\r\n";
        print {$ps_fail_fh} "echo launch failed 1>&2\r\n";
        print {$ps_fail_fh} "exit /b 1\r\n";
    }
    else {
        print {$ps_fail_fh} <<"SCRIPT";
#!/bin/sh
printf '%s\\n' "launch failed" >&2
exit 1
SCRIPT
    }
    close $ps_fail_fh or die "Unable to close $powershell after rewrite: $!";
    chmod 0755, $powershell or die "Unable to chmod $powershell after rewrite: $!";
    my $spawn_ok = eval { $manager->_spawn_windows_background_command('broken.exe'); 1 };
    ok( !$spawn_ok, '_spawn_windows_background_command dies when the detached launcher fails' );
    like( $@, qr/Unable to launch detached Windows web process: launch failed/, '_spawn_windows_background_command surfaces the detached launcher failure text' );

    # The netstat output is stubbed through capture, not a fake
    # executable: _listener_pids_for_port_via_netstat shells out to a
    # bare 'netstat', and on a real Windows host CreateProcess resolves
    # that to System32 before PATH, so a fake netstat on PATH can never
    # win there (same family as the taskkill fake, build #269). The
    # parsing is what this test pins, and the stub feeds it the same
    # output the fake used to.
    my $netstat_output = <<'NETSTAT';
  TCP    0.0.0.0:7890           0.0.0.0:0              LISTENING       5100
  TCP    127.0.0.1:7890         0.0.0.0:0              LISTENING       5100
  TCP    127.0.0.1:7890         0.0.0.0:0              LISTENING       6200
NETSTAT
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( $netstat_output, '', 0 ) };
        is_deeply(
            [ $manager->_listener_pids_for_port_via_netstat(7890) ],
            [ 5100, 6200 ],
            '_listener_pids_for_port_via_netstat returns unique listener pids from Windows netstat output',
        );
    }

    open my $ps_listener_fh, '>', $powershell or die "Unable to rewrite $powershell for listener probe: $!";
    if ($is_windows_host) {
        print {$ps_listener_fh} "\@echo off\r\n";
        print {$ps_listener_fh} "echo 7301\r\n";
        print {$ps_listener_fh} "echo 7301\r\n";
        print {$ps_listener_fh} "echo 8402\r\n";
        print {$ps_listener_fh} "exit /b 0\r\n";
    }
    else {
        print {$ps_listener_fh} <<"SCRIPT";
#!/bin/sh
printf '%s\\n' 7301
printf '%s\\n' 7301
printf '%s\\n' 8402
exit 0
SCRIPT
    }
    close $ps_listener_fh or die "Unable to close $powershell after listener rewrite: $!";
    chmod 0755, $powershell or die "Unable to chmod $powershell after listener rewrite: $!";
    is_deeply(
        [ $manager->_listener_pids_for_port(7921) ],
        [ 7301, 8402 ],
        '_listener_pids_for_port reads unique Windows listener pids directly from the PowerShell probe',
    );

    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
        my $source = $files->web_state . '.pending-test';
        open my $source_fh, '>:raw', $source or die "Unable to write $source: $!";
        print {$source_fh} qq({"pid":4242,"status":"running"});
        close $source_fh or die "Unable to close $source: $!";
        open my $target_fh, '>:raw', $files->web_state or die "Unable to seed @{[$files->web_state]}: $!";
        print {$target_fh} qq({"status":"old"});
        close $target_fh or die "Unable to close @{[$files->web_state]}: $!";
        my ( $ok, $error ) = $manager->_overwrite_state_file_in_place( $source, $files->web_state );
        ok( $ok, '_overwrite_state_file_in_place returns success for the Windows in-place overwrite fallback' )
          or diag $error;
        open my $web_state_fh, '<:raw', $files->web_state or die "Unable to read @{[$files->web_state]}: $!";
        my $web_state_json = do { local $/; <$web_state_fh> };
        close $web_state_fh or die "Unable to close @{[$files->web_state]}: $!";
        like( $web_state_json, qr/"status":"running"/, '_overwrite_state_file_in_place persists the payload through the Windows in-place overwrite fallback' );
        ok( !-e $source, '_overwrite_state_file_in_place removes the consumed pending state file after a successful overwrite' );
    }

    {
        my $fakebin = tempdir( CLEANUP => 1 );
        # Batch file on Windows, shell script on POSIX (same shape as
        # the taskkill fake, build #269): the product resolves
        # powershell through _powershell_command, so the .bat is found
        # and runs through cmd.
        my $is_windows_host = $^O eq 'MSWin32';
        my $powershell = File::Spec->catfile( $fakebin, $is_windows_host ? 'powershell.bat' : 'powershell' );
        my $source = $files->web_state . '.pending-ps-move';
        open my $source_fh, '>:raw', $source or die "Unable to write $source: $!";
        print {$source_fh} qq({"pid":5151,"status":"running"});
        close $source_fh or die "Unable to close $source: $!";
        open my $ps_fh, '>', $powershell or die "Unable to write $powershell: $!";
        if ($is_windows_host) {
            print {$ps_fh} "\@echo off\r\n";
            print {$ps_fh} 'move /Y "' . $source . '" "' . $files->web_state . "\"\r\n";
            print {$ps_fh} "exit /b 0\r\n";
        }
        else {
            print {$ps_fh} <<"SCRIPT";
#!/bin/sh
mv "$source" "@{[$files->web_state]}"
exit 0
SCRIPT
        }
        close $ps_fh or die "Unable to close $powershell: $!";
        chmod 0755, $powershell or die "Unable to chmod $powershell: $!";

        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
        local $ENV{PATH} = join( $is_windows_host ? ';' : ':', $fakebin, ( $ENV{PATH} || '' ) );
        my ( $ok, $error ) = $manager->_replace_path_via_powershell( $source, $files->web_state );
        ok( $ok, '_replace_path_via_powershell returns success when the Windows Move-Item web fallback succeeds' )
          or diag $error;
        ok( -f $files->web_state, '_replace_path_via_powershell leaves the web state target in place after a successful Move-Item fallback' );
    }

    {
        my $fakebin = tempdir( CLEANUP => 1 );
        # Batch file on Windows, shell script on POSIX (same shape as
        # the taskkill fake, build #269).
        my $is_windows_host = $^O eq 'MSWin32';
        my $powershell = File::Spec->catfile( $fakebin, $is_windows_host ? 'powershell.bat' : 'powershell' );
        my $source = $files->web_state . '.pending-ps-fail';
        open my $source_fh, '>:raw', $source or die "Unable to write $source: $!";
        print {$source_fh} qq({"pid":5252,"status":"retry"});
        close $source_fh or die "Unable to close $source: $!";
        open my $ps_fh, '>', $powershell or die "Unable to write $powershell: $!";
        if ($is_windows_host) {
            print {$ps_fh} "\@echo off\r\n";
            print {$ps_fh} "echo web move failed 1>&2\r\n";
            print {$ps_fh} "exit /b 7\r\n";
        }
        else {
            print {$ps_fh} <<"SCRIPT";
#!/bin/sh
printf '%s\\n' 'web move failed' >&2
exit 7
SCRIPT
        }
        close $ps_fh or die "Unable to close $powershell: $!";
        chmod 0755, $powershell or die "Unable to chmod $powershell: $!";

        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
        local $ENV{PATH} = join( $is_windows_host ? ';' : ':', $fakebin, ( $ENV{PATH} || '' ) );
        my ( $ok, $error ) = $manager->_replace_path_via_powershell( $source, $files->web_state );
        ok( !$ok, '_replace_path_via_powershell returns failure when the Windows web Move-Item fallback exits non-zero' );
        like( $error, qr/web move failed/, '_replace_path_via_powershell returns the native PowerShell failure text for web state replacement' );
    }

    {
        my $source = $files->web_state . '.pending-final-fail';
        open my $source_fh, '>:raw', $source or die "Unable to write $source: $!";
        print {$source_fh} qq({"pid":6262,"status":"retry"});
        close $source_fh or die "Unable to close $source: $!";
        open my $target_fh, '>:raw', $files->web_state or die "Unable to seed @{[$files->web_state]}: $!";
        print {$target_fh} qq({"status":"stale"});
        close $target_fh or die "Unable to close @{[$files->web_state]}: $!";

        my @rename_calls;
        my @unlink_calls;
        my $error;
        {
            no warnings 'redefine';
            local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
            local *Developer::Dashboard::RuntimeManager::_rename_path = sub {
                my ( undef, $from, $to ) = @_;
                push @rename_calls, [ $from, $to ];
                $! = EACCES;
                return 0;
            };
            local *Developer::Dashboard::RuntimeManager::_unlink_path = sub {
                my ( undef, $path ) = @_;
                push @unlink_calls, $path;
                return unlink $path;
            };
            local *Developer::Dashboard::RuntimeManager::_replace_path_via_powershell = sub {
                return ( 0, "web Move-Item retry failed\n" );
            };
            local *Developer::Dashboard::RuntimeManager::_overwrite_state_file_in_place = sub {
                return ( 0, "web overwrite retry failed\n" );
            };
            eval { $manager->_replace_state_file( $source, $files->web_state ); 1 } or $error = $@;
        }

        like(
            $error,
            qr/PowerShell Move-Item fallback failed: web Move-Item retry failed\s*;\s*in-place overwrite fallback failed: web overwrite retry failed/,
            '_replace_state_file reports both Windows web fallback failures after exhausting retries',
        );
        is( scalar @rename_calls, 11, '_replace_state_file retries the Windows web rename path across all ten attempts plus the initial rename failure' );
        is( scalar @unlink_calls, 2, '_replace_state_file unlinks the stale Windows web target once and then cleans up the pending state file before giving up' );
        is( $unlink_calls[0], $files->web_state, '_replace_state_file removes the stale Windows web target before the retry loop continues' );
        is( $unlink_calls[1], $source, '_replace_state_file removes the pending Windows web state file during final cleanup' );
        ok( !-e $source, '_replace_state_file removes the pending web state file before dying after repeated Windows replacement failures' );
    }
}

{
    # The ss exit-255 and lsof outputs are stubbed through capture,
    # not fake executables: on a real Windows host a bare 'ss' or
    # 'lsof' in system() can never run a fake (CreateProcess only
    # appends .exe, and neither tool exists on Windows at all), so the
    # fake scripts the test used to carry could never be invoked there
    # (same family as the taskkill fake, build #269). The fallback
    # chain and the -Fp parsing are what this test pins, and the stub
    # feeds them the same outputs the fakes used to. is_windows is
    # forced to 0 so the POSIX ss/lsof branch runs even on a Windows
    # host; command_in_path('ss') is forced to 1 so the ss call
    # happens and reports 255 instead of the code skipping straight
    # to lsof.
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ($name) = @_;
        return 1 if $name eq 'ss';
        return;
    };
    local *Developer::Dashboard::ProcessSupervision::command_in_path = \&Developer::Dashboard::RuntimeManager::command_in_path;
    my $capture_calls = 0;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        $capture_calls++;
        return ( '', "Can't exec ss: No such file or directory\n", 255 ) if $capture_calls == 1;
        return ( "p61530\nf5\np61616\nf5\np61617\n", '', 0 );
    };
    is_deeply(
        [ $manager->_listener_pids_for_port(7890) ],
        [ 61530, 61616, 61617 ],
        '_listener_pids_for_port falls back to lsof when ss is unavailable on non-Windows hosts',
    );
}

{
    no warnings 'redefine';
    # is_windows is forced to 0 so the POSIX ss/lsof branch runs even
    # on a Windows host: _listener_pids_for_port takes the netstat /
    # PowerShell branch there and never consults the ss/lsof stubs
    # below (same shape as tests 219-221, build #253).
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ( $name ) = @_;
        return 0 if $name eq 'ss';
        return 1;
    };
    local *Developer::Dashboard::ProcessSupervision::command_in_path = \&Developer::Dashboard::RuntimeManager::command_in_path;
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_lsof = sub { return ( 61530, 61616, 61617 ) };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_proc = sub { die "_listener_pids_for_port_via_proc should not run when lsof already found listener pids\n" };
    is_deeply(
        [ $manager->_listener_pids_for_port(7890) ],
        [ 61530, 61616, 61617 ],
        '_listener_pids_for_port bypasses ss entirely when it is not present on the host PATH',
    );
}

{
    no warnings 'redefine';
    # is_windows is forced to 0 for the same reason as the block
    # above (build #253 shape): the POSIX ss/lsof/proc branch must
    # run even on a Windows host.
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ( $name ) = @_;
        return 0 if $name eq 'ss';
        return 1;
    };
    local *Developer::Dashboard::ProcessSupervision::command_in_path = \&Developer::Dashboard::RuntimeManager::command_in_path;
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_lsof = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_proc = sub {
        my ( undef, $port ) = @_;
        return $port == 7891 ? ( 71111, 72222 ) : ();
    };
    is_deeply(
        [ $manager->_listener_pids_for_port(7891) ],
        [ 71111, 72222 ],
        '_listener_pids_for_port falls through from missing ss and empty lsof results to procfs lookup',
    );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    my @signals;
    my $shutdown_checks = 0;
    my $release_checks  = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return { pid => $$, port => 7890 };
    };
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        return { pid => $$, port => 7890 };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return ($$) };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ($$) };
    local *Developer::Dashboard::RuntimeManager::_wait_for_windows_web_shutdown = sub {
        $shutdown_checks++;
        return 0;
    };
    local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub {
        $release_checks++;
        return 0;
    };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub {
        my ( undef, $signal, @pids ) = @_;
        push @signals, [ $signal, @pids ];
        return scalar @pids;
    };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    my $stopped_pid = $manager->stop_web;
    is( $stopped_pid, $$, 'stop_web still returns the tracked Windows pid while exercising the late-listener cleanup branch' );
    ok( $shutdown_checks >= 1, 'stop_web consults the Windows shutdown helper before leaving the loop' );
    ok( $release_checks >= 2, 'stop_web retries the Windows port-release helper after the late-listener fallback' );
    is_deeply(
        \@signals,
        [
            [ 'TERM', $$ ],
            [ 'TERM', $$ ],
            [ 'KILL', $$ ],
            [ 'KILL', $$ ],
            [ 'KILL', $$ ],
        ],
        'stop_web exercises the Windows TERM, listener KILL, and late-listener KILL paths when the port never releases',
    );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    my $sleep_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return { pid => $$, port => 7890 };
    };
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        return { pid => $$, port => 7890 };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return ($$) };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_wait_for_windows_web_shutdown = do {
        my $calls = 0;
        sub {
            $calls++;
            return $calls == 1 ? 1 : 0;
        };
    };
    local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { $sleep_calls++; return 0 };
    is( $manager->stop_web, $$, 'stop_web still returns the tracked Windows pid when shutdown requires a second poll' );
    is( $sleep_calls, 1, 'stop_web executes the Windows retry sleep while waiting for the web runtime to shut down' );
}

{
    my @signals;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return };
    local *Developer::Dashboard::RuntimeManager::web_state = sub { return { port => 8123, status => 'running' } };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return (424242) };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub {
        my ( undef, $signal, @pids ) = @_;
        push @signals, [ $signal, @pids ];
        return scalar @pids;
    };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_managed_ajax_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_wait_for_unix_web_shutdown = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_reap_child_processes = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_progress_emit = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 0 };
    is( $manager->stop_web, 424242, 'stop_web falls back to the single listener pid when no saved managed web pid exists' );
    my $saw_listener_term = 0;
    for my $signal (@signals) {
        my ( $name, @pids ) = @{$signal};
        next if $name ne 'TERM';
        if ( grep { $_ == 424242 } @pids ) {
            $saw_listener_term = 1;
            last;
        }
    }
    ok(
        $saw_listener_term,
        'stop_web sends TERM to the listener pid selected from listener-state fallback',
    );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    my $fakebin = tempdir( CLEANUP => 1 );
    # Batch file on Windows, shell script on POSIX (same shape as
    # the taskkill fake, build #269): the product resolves powershell
    # through _powershell_command, so the .bat is found and runs
    # through cmd.
    my $is_windows_host = $^O eq 'MSWin32';
    my $powershell = File::Spec->catfile( $fakebin, $is_windows_host ? 'powershell.bat' : 'powershell' );
    open my $ps_bad_fh, '>', $powershell or die "Unable to write $powershell for ps scan: $!";
    if ($is_windows_host) {
        print {$ps_bad_fh} "\@echo off\r\n";
        print {$ps_bad_fh} "echo invalid line\r\n";
        print {$ps_bad_fh} "echo 9012\tvalid powershell process\r\n";
        print {$ps_bad_fh} "exit /b 0\r\n";
    }
    else {
        print {$ps_bad_fh} <<"SCRIPT";
#!/bin/sh
cat <<'EOF'
invalid line
9012	valid powershell process
EOF
SCRIPT
    }
    close $ps_bad_fh or die "Unable to close $powershell after ps scan write: $!";
    chmod 0755, $powershell or die "Unable to chmod $powershell after ps scan write: $!";
    local $ENV{PATH} = join( $is_windows_host ? ';' : ':', $fakebin, ( $ENV{PATH} || '' ) );
    is_deeply(
        [ $manager->_ps_processes ],
        [
            {
                pid  => 9012,
                args => 'valid powershell process',
            },
        ],
        '_ps_processes skips malformed Windows process-table rows and keeps valid tab-delimited ones',
    );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ($name) = @_;
        return 'C:\\Perl\\perl.exe' if $name eq 'perl.exe';
        return;
    };
    local *Developer::Dashboard::ProcessSupervision::command_in_path = \&Developer::Dashboard::RuntimeManager::command_in_path;
    is( $manager->_current_perl_command, 'C:\\Perl\\perl.exe', '_current_perl_command prefers perl.exe on Windows when plain perl is absent' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'linux';
    local $^X = '/tmp/nonexistent-perl';
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ($name) = @_;
        return '/usr/local/bin/perl' if $name eq 'perl';
        return '/usr/local/bin/perl.exe' if $name eq 'perl.exe';
        return;
    };
    local *Developer::Dashboard::ProcessSupervision::command_in_path = \&Developer::Dashboard::RuntimeManager::command_in_path;
    is( $manager->_current_perl_command, '/usr/local/bin/perl', '_current_perl_command falls back to perl from PATH when the current interpreter path is missing' );

    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ($name) = @_;
        return if $name eq 'perl';
        return '/usr/local/bin/perl.exe' if $name eq 'perl.exe';
        return;
    };
    local *Developer::Dashboard::ProcessSupervision::command_in_path = \&Developer::Dashboard::RuntimeManager::command_in_path;
    is( $manager->_current_perl_command, '/usr/local/bin/perl.exe', '_current_perl_command falls back to perl.exe from PATH when plain perl is unavailable' );

    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { return };
    local *Developer::Dashboard::ProcessSupervision::command_in_path = \&Developer::Dashboard::RuntimeManager::command_in_path;
    is( $manager->_current_perl_command, '/tmp/nonexistent-perl', '_current_perl_command finally returns the current interpreter path when no PATH fallback exists' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    # The stub must target RuntimeManager::capture, the imported copy
    # _send_signal actually calls - stubbing Capture::Tiny::capture
    # never engages (RuntimeManager imports capture at line 8), so the
    # real taskkill ran instead and reported the nonexistent pid 9012
    # as "not found", which _send_signal returns 1 for. The canned
    # values simulate a taskkill failure for an unsupported signal
    # without invoking the real executable, as the other capture
    # stubs in this file do.
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', "taskkill does not know HUP\n", 1 ) };
    is( $manager->_send_signal( 'HUP', 9012 ), 0, '_send_signal returns zero for unsupported Windows signals after surfacing taskkill failures for TERM and KILL only' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    my $polls = 0;
    my $sleep_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        $polls++;
        return $polls == 1 ? (8080) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 2 };
    local *Developer::Dashboard::RuntimeManager::_runtime_confirmation_polls = sub { return 2 };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval = sub { return 0.01 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { $sleep_calls++; return 0 };
    ok( !$manager->_web_runtime_ready( 4321, 7890 ), '_web_runtime_ready returns false on Windows when a listener disappears before the confirmation threshold is reached' );
    is( $sleep_calls, 1, '_web_runtime_ready performs the Windows polling sleep before a later poll observes the vanished listener' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    my $sleep_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 2 };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval = sub { return 0.01 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { $sleep_calls++; return 0 };
    ok( !$manager->_web_runtime_ready( 4321, 7890 ), '_web_runtime_ready returns false on Windows after exhausting the full startup poll budget with no listener' );
    is( $sleep_calls, 2, '_web_runtime_ready performs each Windows startup poll sleep before timing out without a listener' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    ok( !$manager->_web_runtime_matches_pid( { pid => 12 }, 99, undef ), '_web_runtime_matches_pid rejects Windows fallback checks when no listener port is available' );
    ok( $manager->_web_runtime_matches_pid( { pid => 12, port => 7890 }, 99, undef ), '_web_runtime_matches_pid reuses the runtime-reported listener port on Windows when no explicit listener port was supplied' );
    ok( $manager->_web_runtime_matches_pid( { pid => 12, port => 7890 }, 99, 7890 ), '_web_runtime_matches_pid accepts the Windows listener fallback when the running port matches the requested listener port' );
    ok( !$manager->_web_runtime_matches_pid( { pid => 12, port => 7890 }, 99, 7891 ), '_web_runtime_matches_pid rejects Windows fallback checks when the running port does not match the listener port' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'linux';
    ok( !$manager->_web_runtime_matches_pid( { pid => 12, port => 7890 }, 99, 7890 ), '_web_runtime_matches_pid stops before the Windows listener fallback on non-Windows hosts' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'linux';
    my $sleep_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return { pid => 77, port => 7892 };
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return $port == 7892 ? (77) : ();
    };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_runtime_confirmation_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval = sub { return 0.01 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { $sleep_calls++; return 0 };
    ok( $manager->_web_runtime_ready( 77, undef ), '_web_runtime_ready reuses the runtime-reported listener port when no explicit port argument was provided' );
    is( $sleep_calls, 0, '_web_runtime_ready does not need an extra poll sleep when the runtime-reported listener port is immediately ready' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $port ) = @_;
        return () if $port != 7890;
        return (7123);
    };
    ok(
        $manager->_wait_for_windows_web_shutdown( undef, undef, [$$] ),
        '_wait_for_windows_web_shutdown reports the web runtime alive when a tracked listener pid is still running',
    );
    ok(
        $manager->_wait_for_windows_web_shutdown( undef, 7890, [] ),
        '_wait_for_windows_web_shutdown reports the web runtime alive while the listen port still has an owning pid',
    );
    ok(
        !$manager->_wait_for_windows_web_shutdown( undef, 7891, [] ),
        '_wait_for_windows_web_shutdown reports shutdown complete when there is no saved pid, listener pid, or live port owner',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_web = sub {
        my ( undef, %args ) = @_;
        return 5101;
    };
    my $stopped_web = $manager->stop_target( scope => 'web' );
    is( $stopped_web->{web_pid}, 5101, 'stop_target web scope reports the stopped web pid' );
    is( $stopped_web->{web}{status}, 'stopped', 'stop_target web scope reports stopped status' );

    local *Developer::Dashboard::RuntimeManager::stop_collectors = sub {
        my ( undef, %args ) = @_;
        return (
            { name => 'alpha.collector', pid => 6101, status => 'stopped' },
            { name => 'beta.collector',  pid => 6102, status => 'stopped' },
        );
    };
    my $stopped_collectors = $manager->stop_target( scope => 'collector' );
    is( scalar @{ $stopped_collectors->{collectors} }, 2, 'stop_target collector scope reports all stopped collectors' );
    is( $stopped_collectors->{target}, 'all', 'stop_target collector scope defaults its target label to all' );

    my $stopped_named = $manager->stop_target( scope => 'collector', name => 'beta.collector' );
    is( $stopped_named->{target}, 'beta.collector', 'stop_target collector scope preserves the requested collector name in the target field' );
    local *Developer::Dashboard::RuntimeManager::stop_collectors = sub { return (); };
    my $stopped_empty_collectors = $manager->stop_target( scope => 'collector' );
    is_deeply(
        $stopped_empty_collectors->{collectors},
        [
            {
                name    => 'all',
                status  => 'not running',
                details => 'no running collectors',
            },
        ],
        'stop_target collector scope still reports a summary row when no collectors are running',
    );

    {
        local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
        local *Developer::Dashboard::RuntimeManager::stop_collectors = sub {
            return (
                { name => 'alpha.collector', pid => 6201, status => 'stopped' },
                { name => 'beta.collector',  pid => 6202, status => 'stopped' },
            );
        };
        my $windows_stopped_collectors = $manager->stop_target( scope => 'collector' );
        is_deeply(
            $windows_stopped_collectors->{collectors},
            [
                { name => 'alpha.collector', pid => 6201, status => 'stopped' },
                { name => 'beta.collector',  pid => 6202, status => 'stopped'  },
            ],
            'stop_target collector scope reports normal stopped collector rows on Windows',
        );
    }

    local *Developer::Dashboard::RuntimeManager::stop_all = sub {
        return {
            web_pid    => 7101,
            collectors => [ 'alpha.collector', 'beta.collector' ],
        };
    };
    my $stopped_all = $manager->stop_target;
    is( $stopped_all->{web_pid}, 7101, 'stop_target all scope reports the stopped dashboard web pid' );
    is_deeply(
        $stopped_all->{collectors},
        [
            { name => 'alpha.collector', status => 'stopped' },
            { name => 'beta.collector',  status => 'stopped' },
        ],
        'stop_target all scope expands stopped collector names into summary hashes',
    );
}

{
    my $state_backed_pid = _spawn_perl_fixture('while (1) { sleep 0.1 }');
    sleep 0.2;
    no warnings 'redefine';
    local *Local::RuntimeRunner::running_loops = sub { return () };
    local *Local::RuntimeRunner::loop_state = sub {
        my ( undef, $name ) = @_;
        return if $name ne 'beta.collector';
        return {
            pid          => $state_backed_pid,
            name         => 'beta.collector',
            status       => 'starting',
            process_name => 'd2 collector: beta.collector',
        };
    };
    local *Local::RuntimeRunner::stop_loop = sub {
        my ( $self, $name ) = @_;
        push @{ $self->{stopped} }, $name;
        return $state_backed_pid;
    };
    local *Developer::Dashboard::RuntimeManager::_ensure_collector_pid_stopped = sub {
        my ( $self, $name, $pid ) = @_;
        is( $name, 'beta.collector', 'state-backed stop_target still verifies the targeted collector name before final cleanup' );
        is( $pid, $state_backed_pid, 'state-backed stop_target passes the persisted collector pid into final cleanup' );
        return 1;
    };
    my $state_backed_stop = $manager->stop_target( scope => 'collector', name => 'beta.collector' );
    is_deeply(
        $state_backed_stop->{collectors},
        [
            {
                name   => 'beta.collector',
                pid    => $state_backed_pid,
                status => 'stopped',
            },
        ],
        'stop_target collector scope reports one named collector from persisted loop state when the managed title is not observable yet',
    );
    Developer::Dashboard::GoRoutine::terminate_process( $state_backed_pid, 'KILL' );
    Developer::Dashboard::GoRoutine::wait_process($state_backed_pid);
}

{
    is_deeply(
        [ $manager->_collector_stop_fallback_names( { 'zeta.collector' => 1, 'alpha.collector' => 1 } ) ],
        [ 'alpha.collector', 'zeta.collector' ],
        '_collector_stop_fallback_names returns the explicit wanted names in sorted order',
    );

    my $collectors_root = $paths->collectors_root;
    make_path($collectors_root);
    my $gamma_pid = File::Spec->catfile( $collectors_root, 'gamma.collector.pid' );
    my $beta_pid  = File::Spec->catfile( $collectors_root, 'beta.collector.pid' );
    open my $gamma_fh, '>', $gamma_pid or die "Unable to write $gamma_pid: $!";
    print {$gamma_fh} "$$\n";
    close $gamma_fh or die "Unable to close $gamma_pid: $!";
    open my $beta_fh, '>', $beta_pid or die "Unable to write $beta_pid: $!";
    print {$beta_fh} "$$\n";
    close $beta_fh or die "Unable to close $beta_pid: $!";

    my @fallback_names = $manager->_collector_stop_fallback_names({});
    ok( scalar( grep { $_ eq 'alpha.collector' } @fallback_names ), '_collector_stop_fallback_names keeps configured alpha.collector in the fallback set' );
    is( scalar( grep { $_ eq 'beta.collector' } @fallback_names ), 1, '_collector_stop_fallback_names keeps one beta.collector entry when config and pidfiles both mention it' );
    ok( scalar( grep { $_ eq 'gamma.collector' } @fallback_names ), '_collector_stop_fallback_names adds pidfile-only collector names to the fallback set' );

    no warnings 'redefine';
    local *Local::RuntimeRunner::running_loops = sub { return () };
    local *Local::RuntimeRunner::loop_state = sub {
        my ( undef, $name ) = @_;
        return undef if $name eq 'gamma.collector';
        return {
            pid          => $$,
            name         => 'alpha.collector',
            status       => 'starting',
            process_name => 'd2 collector: alpha.collector',
        } if $name eq 'alpha.collector';
        return {
            pid          => $$,
            name         => 'wrong.collector',
            status       => 'starting',
            process_name => 'd2 collector: wrong.collector',
        } if $name eq 'beta.collector';
        return undef;
    };

    is_deeply(
        [ map { { name => $_->{name}, pid => $_->{pid} } } $manager->_collector_stop_targets( { 'gamma.collector' => 1 } ) ],
        [
            {
                name => 'gamma.collector',
                pid  => $$,
            },
        ],
        '_collector_stop_targets accepts a pidfile-backed named collector target even when loop_state is unavailable',
    );

    is_deeply(
        [ map { { name => $_->{name}, pid => $_->{pid} } } $manager->_collector_stop_targets( {} ) ],
        [
            {
                name => 'alpha.collector',
                pid  => $$,
            },
            {
                name => 'beta.collector',
                pid  => $$,
            },
            {
                name => 'gamma.collector',
                pid  => $$,
            },
        ],
        '_collector_stop_targets folds configured live state and pidfile-backed fallback collectors into one sorted stop target list',
    );

    unlink $gamma_pid or die "Unable to remove $gamma_pid: $!";
    unlink $beta_pid or die "Unable to remove $beta_pid: $!";
}

{
    my @supervisor_actions;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_remove_collector_supervisor_targets = sub {
        my ( undef, $names ) = @_;
        push @supervisor_actions, [ remove => [ @{$names || []} ] ];
        return 8802;
    };
    local *Local::RuntimeRunner::running_loops = sub {
        return (
            { name => 'alpha.collector', pid => 9101 },
            { name => 'beta.collector',  pid => 9102 },
        );
    };
    local *Local::RuntimeRunner::stop_loop = sub {
        my ( $self, $name ) = @_;
        push @{ $self->{stopped} }, $name;
        return $name eq 'beta.collector' ? 9102 : 9101;
    };

    my @stopped = $manager->stop_collectors( names => ['beta.collector'] );
    is_deeply( \@stopped, ['beta.collector'], 'stop_collectors still stops the explicitly requested named collector' );
    is_deeply(
        \@supervisor_actions,
        [
            [ remove => ['beta.collector'] ],
        ],
        'stop_collectors removes explicitly requested named collectors from the watchdog set without stopping the whole supervisor',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_web = sub { return 8101 };
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub { return 8102 };
    my $restarted_web = $manager->restart_target( scope => 'web', host => '127.0.0.1', port => 7993, workers => 2, ssl => 1 );
    is( $restarted_web->{stopped_web_pid}, 8101, 'restart_target web scope reports the old web pid' );
    is( $restarted_web->{web_pid}, 8102, 'restart_target web scope reports the restarted web pid' );
    like( $restarted_web->{web}{details}, qr/127\.0\.0\.1:7993 workers=2 ssl=1/, 'restart_target web scope reports the restarted web details' );

    local *Developer::Dashboard::RuntimeManager::stop_collectors = sub {
        return (
            { name => 'alpha.collector', pid => 9101, status => 'stopped' },
        );
    };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub {
        return (
            { name => 'alpha.collector', pid => 9102 },
        );
    };
    my $restarted_collectors = $manager->restart_target( scope => 'collector' );
    is( $restarted_collectors->{collectors}[0]{details}, 'stopped then started', 'restart_target collector scope reports the restart transition details for full-collector restarts' );

    local *Developer::Dashboard::RuntimeManager::restart_all = sub {
        return {
            stopped    => { web_pid => 10101, collectors => [ 'alpha.collector' ] },
            collectors => [ { name => 'alpha.collector', pid => 10102 } ],
            web_pid    => 10103,
        };
    };
    my $restarted_all = $manager->restart_target;
    is( $restarted_all->{stopped}{web_pid}, 10101, 'restart_target all scope reports the stop summary from restart_all' );
    is( $restarted_all->{collectors}[0]{status}, 'restarted', 'restart_target all scope reports restarted collectors' );

    {
        local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
        local *Developer::Dashboard::RuntimeManager::stop_collectors = sub {
            return (
                { name => 'beta.collector', pid => 11101, status => 'stopped' },
            );
        };
        local *Developer::Dashboard::RuntimeManager::start_named_collector = sub {
            return {
                name => 'beta.collector',
                pid  => 11102,
            };
        };
        my $windows_restarted_collectors = $manager->restart_target( scope => 'collector', name => 'beta.collector' );
        is_deeply(
            $windows_restarted_collectors->{collectors},
            [
                {
                    name    => 'beta.collector',
                    pid     => 11102,
                    status  => 'restarted',
                    details => 'stopped then started',
                },
            ],
            'restart_target collector scope performs a normal named collector restart on Windows',
        );
    }
}

{
    my $error = eval { $manager->_collector_job_by_name('missing.collector'); 1 } ? '' : $@;
    like( $error, qr/Unknown collector 'missing\.collector'/, '_collector_job_by_name rejects unknown collector names clearly' );
}

done_testing;

__END__

=head1 NAME

09-runtime-manager.t - runtime lifecycle manager tests

=head1 DESCRIPTION

This test verifies web-service and collector lifecycle management in the
runtime manager, including watchdog behavior when a cron collector's next run
is hours away but its scheduler loop remains alive.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for web-service and collector
lifecycle management. Its watchdog cases distinguish a dead or stalled loop
from an intentionally idle cron schedule, so cron quiet hours do not consume
the unexpected-restart budget.

=head1 WHY IT EXISTS

It exists because runtime lifecycle management has enough moving parts that a
code-only review can miss real regressions. Keeping process, watchdog, and
scheduled-collector expectations in a dedicated test file makes the TDD loop,
coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing runtime process handling, collector watchdog
thresholds, or cron-loop liveness; also use it when a focused CI failure points
here or when you need a faster loop than the entire suite.

=head1 HOW TO USE

Build the shared XS extension in the dev Docker service, then run this test
against the checkout's C<blib> paths:

  d2 docker compose exec dev make
  d2 docker compose exec dev prove -blv t/09-runtime-manager.t

The child-process fixtures use C<Developer::Dashboard::GoRoutine> spawn,
signal, and wait operations so the real process lifecycle remains covered
without calling Perl's C<fork> builtin. Run the full suite and coverage gates
in the same Docker environment before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  d2 docker compose exec dev prove -blv t/09-runtime-manager.t

Run the focused regression against the built checkout extension in Docker.

Example 2:

  d2 docker compose exec dev prove -blv t/09-runtime-manager.t

Run the focused regression under Docker while iterating on the process
supervision behavior.

Example 3:

  d2 docker compose exec dev prove -blr t

Put the focused fix back through the full Docker repository suite before
calling the work finished.

=for comment FULL-POD-DOC END

=cut
