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
}

my $original_cwd = getcwd();
my $repo_lib = File::Spec->catdir( $original_cwd, 'lib' );
my $test_cwd = tempdir(CLEANUP => 1);
chdir $test_cwd or die "Unable to chdir to $test_cwd: $!";

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
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

dies_like( sub { Developer::Dashboard::RuntimeManager->new }, qr/Missing config/, 'runtime manager requires config' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config ) }, qr/Missing file registry/, 'runtime manager requires files' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config, files => $files ) }, qr/Missing path registry/, 'runtime manager requires paths' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config, files => $files, paths => $paths ) }, qr/Missing collector runner/, 'runtime manager requires runner' );
dies_like( sub { Developer::Dashboard::RuntimeManager->new( config => $config, files => $files, paths => $paths, runner => $runner ) }, qr/Missing app builder/, 'runtime manager requires app builder' );

is( $manager->_web_process_title( '0.0.0.0', 7890 ), 'dashboard web: 0.0.0.0:7890', 'web process title is predictable' );
like( Developer::Dashboard::RuntimeManager::_now_iso8601(), qr/^\d{4}-\d{2}-\d{2}T/, 'timestamp helper emits ISO-8601' );
is( Developer::Dashboard::RuntimeManager::_portable_signal('TERM'), 15, 'portable signal helper maps TERM to numeric POSIX signal 15' );
is( Developer::Dashboard::RuntimeManager::_portable_signal('kill'), 9, 'portable signal helper accepts lowercase signal names' );
is( Developer::Dashboard::RuntimeManager::_portable_signal(2), 2, 'portable signal helper preserves numeric signals' );
is( $manager->_send_signal( 'TERM', undef, 0, 'not-a-pid' ), 0, 'portable signal sender skips invalid process ids without named-signal lookup' );
dies_like( sub { Developer::Dashboard::RuntimeManager::_portable_signal() }, qr/Missing signal name/, 'portable signal helper rejects missing signal names clearly' );
dies_like( sub { Developer::Dashboard::RuntimeManager::_portable_signal('NOPE') }, qr/Unsupported signal name: NOPE/, 'portable signal helper rejects unsupported signal names clearly' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'dashboard web: 0.0.0.0:7890' } ), 'managed web process titles are recognized' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'perl -Ilib bin/dashboard serve' } ), 'legacy perl dashboard serve command lines are recognized' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'dashboard serve --workers 4 --port 7890' } ), 'dashboard serve with startup flags is recognized as a web process' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'C:\\Strawberry\\perl\\bin\\perl.exe C:\\Users\\Docker\\.developer-dashboard\\cli\\dd\\_dashboard-core web-foreground --host 0.0.0.0 --port 7890' } ), 'Windows detached _dashboard-core web-foreground command lines are recognized as web processes' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'perl -Ilib bin/dashboard ps1' } ), 'non-web dashboard commands are ignored' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'perl /usr/local/bin/dashboard serve logs -f -n 100' } ), 'dashboard serve logs followers are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => 'dashboard serve workers 8' } ), 'dashboard serve workers subcommands are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => q{/bin/bash -c dashboard serve; sleep 1} } ), 'shell wrappers are not mistaken for web workers' );
ok( !$manager->_looks_like_web_process( { pid => 1, args => q{strace -ff -o /tmp/ddexec ./bin/dashboard serve} } ), 'tracing wrappers are not mistaken for web workers' );

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
            $manager->_dashboard_core_helper_path,
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
        $manager->_dashboard_core_helper_path,
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
        $manager->_dashboard_core_helper_path,
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
        $manager->_dashboard_core_helper_path,
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
        $manager->_dashboard_core_helper_path,
        $staged,
        '_dashboard_core_helper_path survives missing dist share directories and falls back to the staged helper path',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_fork_process = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_run_web_child = sub {
        my ( $self, $writer, $host, $port, %args ) = @_;
        print {$writer} "child-path\n" or die "Unable to write child test payload: $!";
        close $writer or die "Unable to close child test payload writer: $!";
        return 17;
    };
    local *POSIX::_exit = sub { return $_[0] };
    is(
        $manager->start_web( host => '0.0.0.0', port => 7897, workers => 2, ssl => 1 ),
        17,
        'start_web child path returns the stubbed POSIX::_exit status when the fork wrapper yields the child branch',
    );
}

{
    no warnings 'redefine';
    $manager->_cleanup_web_files;
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub { return ( { pid => $$, args => 'perl -Ilib bin/dashboard serve' } ) };
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
ok( $manager->_is_managed_web($pid), 'started pid is recognized as a managed web process' );
my $dedup_pid;
for ( 1 .. 20 ) {
    $dedup_pid = scalar( $manager->start_web( host => '0.0.0.0', port => 7898 ) );
    last if $dedup_pid == $pid;
    sleep 0.1;
}
is( $dedup_pid, $pid, 'background start deduplicates an already running web process' );
{
    my $marker_child = fork();
    die "fork failed: $!" if !defined $marker_child;
    if ( !$marker_child ) {
        exec 'env', 'RUNTIME_MANAGER_MARKER=yes', $^X, '-e', 'sleep 10';
    }
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
    kill 'TERM', $marker_child;
    waitpid( $marker_child, 0 );
}
my $title;
for ( 1 .. 20 ) {
    $title = $manager->_read_process_title($pid);
    last if defined $title && $title =~ /^dashboard web:/;
    sleep 0.1;
}
if ($UNDER_COVER) {
    pass('managed web process title reads are timing-tolerant under coverage');
}
elsif ( $manager->running_web && $manager->running_web->{pid} == $pid ) {
    pass('managed web process title reads tolerate hosts where the wrapper title is transient once running_web still confirms the managed pid');
}
else {
    like( $title, qr/^dashboard web:/, 'managed web process title is readable' );
}
ok( scalar $manager->_ps_processes, 'ps process list is available' );
my @prefixed;
for ( 1 .. 20 ) {
    @prefixed = $manager->_find_processes_by_prefix('dashboard web:');
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
        return $requested_pid == $pid ? 'dashboard web: 127.0.0.1:7898' : undef;
    };
    my @title_prefixed = $manager->_find_processes_by_prefix('dashboard web:');
    ok( scalar @title_prefixed, 'process prefix scan falls back to the readable process title when the ps command line itself is not prefixed' );
    is( $title_prefixed[0]{args}, 'dashboard web: 127.0.0.1:7898', 'process prefix scan returns the recovered process title when the fallback path matches' );
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
                args => 'dashboard web: 0.0.0.0:7898',
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
                args => 'dashboard web: foreign:7898',
            },
            {
                pid  => 410_002,
                uid  => $< + 1,
                args => 'dashboard ajax: foreign-worker',
            },
            {
                pid  => 410_003,
                uid  => $< + 0,
                args => 'dashboard ajax: local-worker',
            },
        );
    };
    is_deeply(
        [ map { $_->{pid} } $manager->_find_web_processes ],
        [],
        '_find_web_processes ignores dashboard web processes owned by other users',
    );
    is_deeply(
        [ map { $_->{pid} } $manager->_find_processes_by_prefix('dashboard ajax:') ],
        [410_003],
        '_find_processes_by_prefix only returns current-user dashboard processes',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub {
        my ( undef, $prefix ) = @_;
        return () if $prefix ne 'dashboard ajax:';
        return (
            { pid => 510_001, args => 'dashboard ajax: local-runtime' },
            { pid => 510_002, args => 'dashboard ajax: foreign-runtime' },
            { pid => 510_003, args => 'dashboard ajax: unmarked-runtime' },
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
    is_deeply( \%captured, { host => '0.0.0.0', port => 7890, workers => 1, ssl => 0 }, 'foreground start forwards the default host, port, and worker count to the app builder' );
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
dies_like( sub { $builder_error_manager->start_web( host => '0.0.0.0', port => 7901 ) }, qr/builder boom/, 'background start surfaces app-builder failures' );

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
dies_like( sub { $daemon_error_manager->start_web( host => '0.0.0.0', port => 7902 ) }, qr/daemon boom/, 'background start surfaces daemon-start failures' );

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
    is( $serve_error_manager->web_state->{status}, 'error', '_run_web_child records error status when the serve loop dies' );
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
    is( $clean_exit_manager->web_state->{status}, 'stopped', '_run_web_child records stopped status after a clean exit' );
    $clean_exit_manager->_cleanup_web_files;
}

{
    my $signal_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub {
            return Local::RuntimeServer->new(
                host => '0.0.0.0',
                port => 7906,
            );
        },
        config => $config,
        files  => $files,
        paths  => $paths,
        runner => $runner,
    );
    pipe my $reader, my $writer or die "pipe failed: $!";
    my $signal_pid = fork();
    die "fork failed: $!" if !defined $signal_pid;
    if ( !$signal_pid ) {
        close $reader;
        POSIX::_exit( $signal_manager->_run_web_child( $writer, '0.0.0.0', 7906, detach => 0, redirect => 0 ) );
    }
    close $writer;
    my $startup_line = <$reader>;
    close $reader;
    like( $startup_line, qr/^ok\|\d+\|0\.0\.0\.0\|7906\n\z/, '_run_web_child reports startup before waiting for signals' );
    kill 'TERM', $signal_pid;
    my $signal_state;
    for ( 1 .. 30 ) {
        $signal_state = $signal_manager->web_state;
        last if $signal_state && ( $signal_state->{status} || '' ) eq 'stopped' && !kill 0, $signal_pid;
        sleep 0.1;
    }
    my $signal_reaped = waitpid( $signal_pid, WNOHANG );
    ok(
        ( $signal_reaped == $signal_pid || ( $signal_state && ( $signal_state->{status} || '' ) eq 'stopped' ) ),
        '_run_web_child exits after TERM triggers the shutdown handler'
    );
    waitpid( $signal_pid, 0 ) if $signal_reaped == 0;
    is( $signal_state->{status}, 'stopped', '_run_web_child TERM shutdown records stopped status through the signal handler' );
    $signal_manager->_cleanup_web_files;
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
    is( $direct_signal_manager->web_state->{status}, 'stopped', '_run_web_child in-process TERM path records stopped status through the local shutdown closure' );
    $direct_signal_manager->_cleanup_web_files;
}

{
    my $result_path = File::Spec->catfile( $home, 'run-web-child-detach-result.txt' );
    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    if ( !$pid ) {
        my $buffer = '';
        open my $writer, '>', \$buffer or die $!;
        my $redirect_manager = Developer::Dashboard::RuntimeManager->new(
            app_builder => sub {
                return Local::RuntimeServer->new(
                    host               => '0.0.0.0',
                    port               => 7908,
                    return_immediately => 1,
                );
            },
            config => $config,
            files  => $files,
            paths  => $paths,
            runner => $runner,
        );
        my $detach_calls = 0;
        my $fork_calls   = 0;
        my $exit;
        my $error = '';
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_detach_web_process_session = sub { $detach_calls++; return 1 };
        local *Developer::Dashboard::RuntimeManager::_fork_process = sub { $fork_calls++; return 0 };
        eval {
            $exit = $redirect_manager->_run_web_child( $writer, '0.0.0.0', 7908, detach => 1, redirect => 1 );
            1;
        } or $error = $@;
        open my $result_fh, '>', $result_path or die "Unable to write $result_path: $!";
        print {$result_fh} join "\n",
          ( $error || '' ),
          ( defined $exit ? $exit : 'undef' ),
          $detach_calls,
          $fork_calls,
          $buffer;
        close $result_fh or die "Unable to close $result_path: $!";
        exit 0;
    }
    waitpid( $pid, 0 );
    open my $result_fh, '<', $result_path or die "Unable to read $result_path: $!";
    my @result_lines = <$result_fh>;
    close $result_fh;
    chomp @result_lines;
    my ( $error, $exit, $detach_calls, $fork_calls, @buffer_lines ) = @result_lines;
    is( $error, '', '_run_web_child detach+redirect path returns without throwing when the fork wrapper yields the child branch' );
    is( $exit, '0', '_run_web_child detach+redirect path still returns cleanly when the daemon exits immediately' );
    is( $detach_calls, '1', '_run_web_child detach path delegates session detachment through the runtime helper once' );
    is( $fork_calls, '1', '_run_web_child detach path uses the fork wrapper once before continuing in the child branch' );
    like( join( "\n", @buffer_lines ), qr/^ok\|/, '_run_web_child detach+redirect path still reports startup through the provided pipe writer' );
}

{
    pipe my $result_reader, my $result_writer or die "Unable to create result pipe: $!";
    my $pid = fork();
    die "Unable to fork inherited-fd runtime test child: $!" if !defined $pid;
    if ( !$pid ) {
        close $result_reader;
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
                fileno($result_writer),
                fileno($keep_reader),
                fileno($keep_writer),
            ],
        );
        my $keep_ok = defined syswrite( $keep_writer, "kept\n" ) ? 1 : 0;
        my $drop_ok = defined syswrite( $drop_writer, "dropped\n" ) ? 1 : 0;
        print {$result_writer} "$keep_ok:$drop_ok\n";
        close $result_writer;
        undef $drop_writer;
        undef $drop_reader;
        undef $keep_writer;
        undef $keep_reader;
        undef $result_reader;
        POSIX::_exit(0);
    }
    close $result_writer;
    my $payload = <$result_reader>;
    close $result_reader;
    waitpid( $pid, 0 );
    chomp $payload if defined $payload;
    is( $payload, '1:0', '_close_inherited_fds keeps explicit runtime child descriptors open while closing the rest' );
}

{
    pipe my $result_reader, my $result_writer or die "Unable to create result pipe: $!";
    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    if ( !$pid ) {
        close $result_reader;
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
                fileno($result_writer),
                fileno($keep_left),
                fileno($keep_right),
            ],
            close_ipc => 1,
        );
        my $keep_ok = defined syswrite( $keep_right, "kept\n" ) ? 1 : 0;
        my $drop_ok = defined syswrite( $drop_right, "dropped\n" ) ? 1 : 0;
        print {$result_writer} "$keep_ok:$drop_ok\n";
        close $result_writer;
        POSIX::_exit(0);
    }
    close $result_writer;
    my $payload = <$result_reader>;
    close $result_reader;
    waitpid( $pid, 0 );
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
is( $manager->web_log, '', 'web_log returns an empty string when the dashboard log file is missing' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_follow_log_file = sub {
        my ( $self, %args ) = @_;
        is( $args{start_pos}, length("follow once\n"), 'web_log follow mode passes the original file byte length into the follow loop so appended lines are not skipped by a seek-to-end race' );
        return 1;
    };
    $files->write( 'dashboard_log', "follow once\n" );
    is( $manager->web_log( follow => 1, lines => 1 ), '', 'web_log follow mode returns an empty string after delegating to the follow loop' );
}
{
    $files->write( 'dashboard_log', "alpha\nbeta\n" );
    my $follow_capture = "$home/web-log-follow.txt";
    my $follow_pid = fork();
    die "fork failed: $!" if !defined $follow_pid;
    if ( !$follow_pid ) {
        open STDOUT, '>', $follow_capture or die $!;
        $manager->web_log( follow => 1, lines => 1 );
        POSIX::_exit(0);
    }
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
        last if $follow_output =~ /gamma\n/;
        sleep 0.1;
    }
    like( $follow_output, qr/gamma\n/, 'web_log follow mode streams appended log lines' );
    kill 'TERM', $follow_pid;
    waitpid( $follow_pid, 0 );
    is( $? >> 8, 0, 'web_log follow mode exits cleanly on TERM' );
}
{
    my $missing_follow = "$home/missing-follow.log";
    my $missing_pid = fork();
    die "fork failed: $!" if !defined $missing_pid;
    if ( !$missing_pid ) {
        $manager->_follow_log_file( file => $missing_follow, interval => 0.05 );
        POSIX::_exit(0);
    }
    for ( 1 .. 30 ) {
        last if -f $missing_follow;
        sleep 0.1;
    }
    ok( -f $missing_follow, '_follow_log_file creates a missing log file before following it' );
    kill 'HUP', $missing_pid;
    waitpid( $missing_pid, 0 );
    is( $? >> 8, 0, '_follow_log_file exits cleanly on HUP' );
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
    my $signal_pid = fork();
    die "fork failed: $!" if !defined $signal_pid;
    if ( !$signal_pid ) {
        $manager->_follow_log_file( file => $signal_follow, interval => 0.05 );
        POSIX::_exit(0);
    }
    sleep 0.2;
    kill 'INT', $signal_pid;
    waitpid( $signal_pid, 0 );
    is( $? >> 8, 0, '_follow_log_file exits cleanly on INT' );
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
    my $ajax_pid = fork();
    die "fork failed: $!" if !defined $ajax_pid;
    if ( !$ajax_pid ) {
        $0 = "dashboard ajax: $ajax_name";
        $SIG{TERM} = sub { exit 0 };
        while (1) { sleep 1 }
    }
    my $seen = 0;
    for ( 1 .. 20 ) {
        if ( scalar grep { $_->{pid} == $ajax_pid } $manager->_find_processes_by_prefix('dashboard ajax:') ) {
            $seen = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $seen, 'test ajax singleton worker is visible in the process table before stop_all' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_managed_ajax_processes = sub {
            return kill( 0, $ajax_pid ) ? ( { pid => $ajax_pid, args => "dashboard ajax: $ajax_name" } ) : ();
        };
        $manager->stop_all;
    }
    for ( 1 .. 20 ) {
        my $reaped = waitpid( $ajax_pid, WNOHANG );
        last if $reaped == $ajax_pid || !kill 0, $ajax_pid;
        sleep 0.1;
    }
    my $stop_reaped = waitpid( $ajax_pid, WNOHANG );
    ok( $stop_reaped == $ajax_pid || !kill( 0, $ajax_pid ), 'stop_all terminates saved ajax singleton workers along with the web service lifecycle' );
    waitpid( $ajax_pid, 0 ) if $stop_reaped != $ajax_pid;
}
{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_ROOT} = $paths->state_root;
    my $ajax_name = 'STUBBORN-KILL-' . $$;
    my $stubborn_ajax = fork();
    die "fork failed: $!" if !defined $stubborn_ajax;
    if ( !$stubborn_ajax ) {
        $0 = "dashboard ajax: $ajax_name";
        $SIG{TERM} = 'IGNORE';
        while (1) { sleep 1 }
    }
    my $seen = 0;
    for ( 1 .. 20 ) {
        if ( scalar grep { $_->{pid} == $stubborn_ajax } $manager->_find_processes_by_prefix('dashboard ajax:') ) {
            $seen = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $seen, 'stubborn ajax singleton worker is visible in the process table before stop_web escalates' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_managed_ajax_processes = sub {
            return kill( 0, $stubborn_ajax ) ? ( { pid => $stubborn_ajax, args => "dashboard ajax: $ajax_name" } ) : ();
        };
        $manager->stop_web;
    }
    my $ajax_reaped = wait_for_child_exit($stubborn_ajax);
    if ( !$ajax_reaped && $UNDER_COVER && kill 0, $stubborn_ajax ) {
        kill 'KILL', $stubborn_ajax;
        $ajax_reaped = wait_for_child_exit($stubborn_ajax);
    }
waitpid( $stubborn_ajax, 0 ) if !$ajax_reaped && kill 0, $stubborn_ajax;
    if ($UNDER_COVER) {
        ok( $ajax_reaped || !kill( 0, $stubborn_ajax ), 'stubborn ajax shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( !kill( 0, $stubborn_ajax ), 'stop_web escalates stubborn ajax singleton workers to KILL after TERM is ignored' );
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
        return () if $prefix ne 'dashboard ajax:';
        $ajax_poll_count++;
        return () if $ajax_poll_count > 31;
        return ( { pid => 999_991, args => 'dashboard ajax: COVER-KILL' } );
    };
    is( $manager->stop_web, undef, 'stop_web still completes when only lingering ajax singleton workers remain for the post-loop KILL branch' );
}

{
    my $web_pid = $manager->start_web( host => '0.0.0.0', port => 7904 );
    ok( $web_pid > 0, 'background web process starts before restart singleton cleanup coverage' );
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_ROOT} = $paths->state_root;
    my $ajax_name = 'RESTART-ME-' . $$;
    my $ajax_pid = fork();
    die "fork failed: $!" if !defined $ajax_pid;
    if ( !$ajax_pid ) {
        $0 = "dashboard ajax: $ajax_name";
        $SIG{TERM} = sub { exit 0 };
        while (1) { sleep 1 }
    }
    my $seen = 0;
    for ( 1 .. 20 ) {
        if ( scalar grep { $_->{pid} == $ajax_pid } $manager->_find_processes_by_prefix('dashboard ajax:') ) {
            $seen = 1;
            last;
        }
        sleep 0.1;
    }
    ok( $seen, 'test ajax singleton worker is visible in the process table before restart_all' );
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_managed_ajax_processes = sub {
        return kill( 0, $ajax_pid ) ? ( { pid => $ajax_pid, args => "dashboard ajax: $ajax_name" } ) : ();
    };
    my $restart_with_ajax = $manager->restart_all( host => '0.0.0.0', port => 7904 );
    ok( $restart_with_ajax->{web_pid} > 0, 'restart_all still restarts the web service when singleton ajax workers are present' );
    for ( 1 .. 20 ) {
        my $reaped = waitpid( $ajax_pid, WNOHANG );
        last if $reaped == $ajax_pid || !kill 0, $ajax_pid;
        sleep 0.1;
    }
    my $restart_reaped = waitpid( $ajax_pid, WNOHANG );
    ok( $restart_reaped == $ajax_pid || !kill( 0, $ajax_pid ), 'restart_all terminates saved ajax singleton workers before the replacement web service starts' );
    waitpid( $ajax_pid, 0 ) if $restart_reaped != $ajax_pid;
    $manager->stop_web;
}

{
    my $stubborn_web = fork();
    die "fork failed: $!" if !defined $stubborn_web;
    if ( !$stubborn_web ) {
        $SIG{TERM} = 'IGNORE';
        $ENV{DEVELOPER_DASHBOARD_WEB_SERVICE} = 1;
        $0 = 'dashboard web: stubborn:7906';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    $files->write( 'web_pid', "$stubborn_web\n" );
    $manager->_write_web_state( { pid => $stubborn_web, host => '0.0.0.0', port => 7906, status => 'running' } );
    is( $manager->stop_web, $stubborn_web, 'stop_web returns the stubborn pid before escalating' );
    my $web_reaped = wait_for_child_exit($stubborn_web);
    if ( !$web_reaped && $UNDER_COVER && kill 0, $stubborn_web ) {
        kill 'KILL', $stubborn_web;
        $web_reaped = wait_for_child_exit($stubborn_web);
    }
    waitpid( $stubborn_web, 0 ) if !$web_reaped && kill 0, $stubborn_web;
    if ($UNDER_COVER) {
        ok( $web_reaped || !kill( 0, $stubborn_web ), 'stubborn web shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( !kill( 0, $stubborn_web ), 'stop_web escalates to KILL when TERM is ignored' );
    }
}

{
    my $legacy_web = fork();
    die "fork failed: $!" if !defined $legacy_web;
    if ( !$legacy_web ) {
        $0 = 'perl -Ilib bin/dashboard serve';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    $manager->_cleanup_web_files;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::web_state = sub { return {} };
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => $legacy_web,
                args => 'perl -Ilib bin/dashboard serve',
            }
        );
    };
    my $legacy_state = $manager->running_web;
    is( $legacy_state->{pid}, $legacy_web, 'running_web discovers legacy dashboard serve processes by command line' );
    is( $legacy_state->{host}, '0.0.0.0', 'legacy web discovery falls back to the default host when no state file exists' );
    is( $legacy_state->{port}, 7890, 'legacy web discovery falls back to the default port when no state file exists' );
    is( $manager->stop_web, $legacy_web, 'stop_web terminates legacy dashboard serve processes that predate managed markers' );
    waitpid( $legacy_web, 0 );
    ok( !kill( 0, $legacy_web ), 'legacy dashboard serve process is gone after stop_web' );
}
{
    my $stubborn_legacy = fork();
    die "fork failed: $!" if !defined $stubborn_legacy;
    if ( !$stubborn_legacy ) {
        $SIG{TERM} = 'IGNORE';
        $0 = 'perl -Ilib bin/dashboard serve';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return undef };
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
        local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
        local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub { return () };
        local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
        local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub {
            return kill( 0, $stubborn_legacy ) ? ( { pid => $stubborn_legacy } ) : ();
        };
        is( $manager->stop_web, undef, 'stop_web still completes when only a stubborn legacy dashboard serve process remains' );
    }
    my $legacy_reaped = wait_for_child_exit($stubborn_legacy);
    if ( !$legacy_reaped && $UNDER_COVER && kill 0, $stubborn_legacy ) {
        kill 'KILL', $stubborn_legacy;
        $legacy_reaped = wait_for_child_exit($stubborn_legacy);
    }
    waitpid( $stubborn_legacy, 0 ) if !$legacy_reaped && kill 0, $stubborn_legacy;
    if ($UNDER_COVER) {
        ok( $legacy_reaped || !kill( 0, $stubborn_legacy ), 'stubborn legacy web shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( !kill( 0, $stubborn_legacy ), 'stop_web escalates stubborn legacy dashboard serve processes to KILL after TERM is ignored' );
    }
}

{
    my $stubborn_collector = fork();
    die "fork failed: $!" if !defined $stubborn_collector;
    if ( !$stubborn_collector ) {
        $SIG{TERM} = 'IGNORE';
        $0 = 'dashboard collector: stubborn.collector';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    $runner->{loops} = [ { name => 'stubborn.collector', pid => $stubborn_collector } ];
    my @forced = $manager->stop_collectors;
    is_deeply( \@forced, ['stubborn.collector'], 'stop_collectors returns stubborn collector names before escalation' );
    my $collector_reaped = wait_for_child_exit($stubborn_collector);
    if ( !$collector_reaped && $UNDER_COVER && kill 0, $stubborn_collector ) {
        kill 'KILL', $stubborn_collector;
        $collector_reaped = wait_for_child_exit($stubborn_collector);
    }
    waitpid( $stubborn_collector, 0 ) if !$collector_reaped && kill 0, $stubborn_collector;
    if ($UNDER_COVER) {
        ok( $collector_reaped || !kill( 0, $stubborn_collector ), 'stubborn collector shutdown remains timing-tolerant under coverage' );
    }
    else {
        ok( !kill( 0, $stubborn_collector ), 'stop_collectors escalates to KILL when TERM is ignored' );
    }
}

{
    local $ENV{PATH} = '/definitely-missing';
    my $fallback_child = fork();
    die "fork failed: $!" if !defined $fallback_child;
    if ( !$fallback_child ) {
        $0 = 'dashboard web: fallback:9999';
        while (1) { sleep 0.1 }
    }
    sleep 0.2;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            {
                pid  => $fallback_child,
                uid  => $< + 0,
                args => 'dashboard web: fallback:9999',
            }
        );
    };
    ok( $manager->_pkill_perl('^dashboard web:'), 'pkill fallback succeeds even when pkill is unavailable' );
    my $reaped = 0;
    for ( 1 .. 20 ) {
        if ( waitpid( $fallback_child, WNOHANG ) == $fallback_child ) {
            $reaped = 1;
            last;
        }
        sleep 0.1;
    }
    kill 'KILL', $fallback_child if !$reaped && kill 0, $fallback_child;
    waitpid( $fallback_child, 0 ) if !$reaped;
    ok( $reaped || !kill( 0, $fallback_child ), 'pkill fallback terminates matching processes by scanning ps output' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', '', 2 ) };
    ok( !defined $manager->_pkill_perl('^dashboard web:'), '_pkill_perl returns undef for unexpected pkill failures' );
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
                args => 'dashboard web: windows-fallback:9998',
            }
        );
    };
    ok( $manager->_pkill_perl('^dashboard web:'), '_pkill_perl bypasses pkill and succeeds through process scanning on Windows hosts' );
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
        !$manager->_proc_owned_by_current_user( { pid => 4455, uid => $< + 0, args => 'dashboard web: foreign:7890' } ),
        '_proc_owned_by_current_user rejects foreign pid-namespace processes even when the uid matches',
    );
    ok(
        $manager->_proc_owned_by_current_user( { pid => 4456, uid => $< + 0, args => 'dashboard web: local:7890' } ),
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
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'dashboard web: 0.0.0.0:7890' };
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
            process_name => 'dashboard web: 127.0.0.1:7927',
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
            process_name => 'dashboard web: 127.0.0.1:7927',
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
        return $pid == 9912 ? 'starman master' : 'dashboard web: 127.0.0.1:7927';
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
            watchdog_restart_window_started_at     => Developer::Dashboard::RuntimeManager::_now_iso8601(),
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
    my $now = Developer::Dashboard::RuntimeManager::_now_iso8601();
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
        '_collector_watchdog_stale_seconds uses the throttled effective interval for dashboard subcommand collectors',
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
        pass('_process_fd_paths is skipped on hosts without /proc');
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
    my $listener = fork();
    die "fork failed: $!" if !defined $listener;
    if ( !$listener ) {
        sleep 30;
        POSIX::_exit(0);
    }
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
    kill 'KILL', $listener;
    waitpid( $listener, 0 );
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
    my $listener = fork();
    die "fork failed: $!" if !defined $listener;
    if ( !$listener ) {
        local $SIG{TERM} = 'IGNORE';
        sleep 30;
        POSIX::_exit(0);
    }
    my $calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub {
        return $calls++ == 0 ? { pid => $listener, port => 7908 } : undef;
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ($listener) };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    is( $manager->stop_web, $listener, 'stop_web returns the recorded pid while it also tracks listener pids on the bound port' );
    waitpid( $listener, 0 );
    ok( !kill( 0, $listener ), 'stop_web escalates listener-port pids to KILL when they remain alive after TERM' );
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
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { die "_cleanup_web_files should not run while a saved listener still exists\n" };
    my $running = $manager->running_web;
    is( $running->{pid}, 333_333, 'running_web falls back to the saved listener pid when the real listener no longer keeps the dashboard wrapper title' );
    is( $running->{port}, 7917, 'running_web keeps the persisted port when it resolves the live listener from saved state' );
    is( $running->{process_name}, 'starman master', 'running_web records the actual listener process title when using saved-state listener fallback' );
}

{
    my $late_listener = fork();
    die "fork failed: $!" if !defined $late_listener;
    if ( !$late_listener ) {
        local $SIG{TERM} = 'IGNORE';
        sleep 30;
        POSIX::_exit(0);
    }
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
    waitpid( $late_listener, 0 );
    ok( !kill( 0, $late_listener ), 'stop_web kills late-discovered listener pids after an initial port-release timeout' );
}

{
    my $listener = fork();
    die "fork failed: $!" if !defined $listener;
    if ( !$listener ) {
        local $SIG{TERM} = sub { exit 0 };
        while (1) { sleep 0.1 }
    }
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
    waitpid( $listener, 0 );
    ok( !kill( 0, $listener ), 'stop_web terminates the saved listener pid resolved from persisted web state' );
}

{
    no warnings 'redefine';
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

SKIP: {
    skip '_read_process_state direct procfs coverage requires /proc', 1 if !-r "/proc/$$/stat";
    like( $manager->_read_process_state($$), qr/^[A-Z]$/, '_read_process_state reads the direct procfs state code for the current process' );
}

ok( $manager->_process_exists($$), '_process_exists returns true for the current runtime process' );
ok( !defined $manager->_read_process_state(999_999_998), '_read_process_state returns undef when ps also cannot resolve the pid' );

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( "Z+\n", undef, 0 ) };
    is( $manager->_read_process_state(999_999_999), 'Z', '_read_process_state falls back to ps output when procfs state data is unavailable' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 0 };
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
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        $manager->_write_web_state( { pid => $$, status => 'running' } );
        $manager->_shutdown_web('stopped');
    }
    waitpid( $child, 0 );
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
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        $manager->_cleanup_web_files;
        $manager->_shutdown_web();
    }
    waitpid( $child, 0 );
    my $state = $manager->web_state;
    is( $state->{status}, 'stopped', '_shutdown_web writes a default stopped status when no previous web state exists' );
    $manager->_cleanup_web_files;
}

{
    no warnings 'redefine';
    local *POSIX::_exit = sub { return 0 };
    $manager->_cleanup_web_files;
    is( $manager->_shutdown_web(), 0, '_shutdown_web in-process path also writes a default empty state before exiting when no prior state exists' );
    is( $manager->web_state->{status}, 'stopped', '_shutdown_web in-process default path records the stopped status with an empty starting state' );
    $manager->_cleanup_web_files;
}

{
    no warnings 'redefine';
    local *POSIX::_exit = sub { return 0 };
    $manager->_write_web_state( { pid => 1234, status => 'running' } );
    is( $manager->_shutdown_web('stopped'), 0, '_shutdown_web returns the stubbed POSIX::_exit value when called in-process' );
    is( $manager->web_state->{pid}, $$ + 0, '_shutdown_web rewrites the final web state pid to the current process in-process' );
    is( $manager->web_state->{status}, 'stopped', '_shutdown_web keeps the requested stopped status when exiting in-process' );
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
    my $taskkill = File::Spec->catfile( $fakebin, 'taskkill' );
    open my $taskkill_fh, '>', $taskkill or die "Unable to write $taskkill: $!";
    print {$taskkill_fh} <<"SCRIPT";
#!/bin/sh
printf '%s\n' "\$*" > "$fakebin/taskkill.args"
exit 0
SCRIPT
    close $taskkill_fh or die "Unable to close $taskkill: $!";
    chmod 0755, $taskkill or die "Unable to chmod $taskkill: $!";
    local $ENV{PATH} = join ':', $fakebin, ( $ENV{PATH} || '' );
    is(
        $manager->_send_signal( 'TERM', 2372, 5868 ),
        2,
        '_send_signal returns the number of requested Windows process ids when taskkill succeeds',
    );
    open my $taskkill_args_fh, '<', File::Spec->catfile( $fakebin, 'taskkill.args' )
      or die "Unable to read $fakebin/taskkill.args: $!";
    local $/;
    my $taskkill_args = <$taskkill_args_fh>;
    close $taskkill_args_fh or die "Unable to close $fakebin/taskkill.args: $!";
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
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) {
        return ( '', 'taskkill hard failure', 5 );
    };
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
    my $powershell = File::Spec->catfile( $fakebin, 'powershell' );
    my $stdout_log = $files->dashboard_log;
    my $stderr_log = $stdout_log . '.stderr';
    open my $ps_fh, '>', $powershell or die "Unable to write $powershell: $!";
    print {$ps_fh} <<"SCRIPT";
#!/bin/sh
printf '%s\n' "\$*" > "$fakebin/powershell.args"
printf '%s\n' 42424
exit 0
SCRIPT
    close $ps_fh or die "Unable to close $powershell: $!";
    chmod 0755, $powershell or die "Unable to chmod $powershell: $!";
    local $ENV{PATH} = join ':', $fakebin, ( $ENV{PATH} || '' );
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
    like( $args, qr/\Q$stdout_log\E/, '_spawn_windows_background_command redirects stdout to the dashboard log' );
    like( $args, qr/\Q$stderr_log\E/, '_spawn_windows_background_command redirects stderr to the dashboard error log' );

    open my $ps_fail_fh, '>', $powershell or die "Unable to rewrite $powershell: $!";
    print {$ps_fail_fh} <<"SCRIPT";
#!/bin/sh
printf '%s\n' "launch failed" >&2
exit 1
SCRIPT
    close $ps_fail_fh or die "Unable to close $powershell after rewrite: $!";
    chmod 0755, $powershell or die "Unable to chmod $powershell after rewrite: $!";
    my $spawn_ok = eval { $manager->_spawn_windows_background_command('broken.exe'); 1 };
    ok( !$spawn_ok, '_spawn_windows_background_command dies when the detached launcher fails' );
    like( $@, qr/Unable to launch detached Windows web process: launch failed/, '_spawn_windows_background_command surfaces the detached launcher failure text' );

    my $netstat = File::Spec->catfile( $fakebin, 'netstat' );
    open my $netstat_fh, '>', $netstat or die "Unable to write $netstat: $!";
    print {$netstat_fh} <<"SCRIPT";
#!/bin/sh
cat <<'EOF'
  TCP    0.0.0.0:7890           0.0.0.0:0              LISTENING       5100
  TCP    127.0.0.1:7890         0.0.0.0:0              LISTENING       5100
  TCP    127.0.0.1:7890         0.0.0.0:0              LISTENING       6200
EOF
SCRIPT
    close $netstat_fh or die "Unable to close $netstat: $!";
    chmod 0755, $netstat or die "Unable to chmod $netstat: $!";
    is_deeply(
        [ $manager->_listener_pids_for_port_via_netstat(7890) ],
        [ 5100, 6200 ],
        '_listener_pids_for_port_via_netstat returns unique listener pids from Windows netstat output',
    );

    open my $ps_listener_fh, '>', $powershell or die "Unable to rewrite $powershell for listener probe: $!";
    print {$ps_listener_fh} <<"SCRIPT";
#!/bin/sh
printf '%s\n' 7301
printf '%s\n' 7301
printf '%s\n' 8402
exit 0
SCRIPT
    close $ps_listener_fh or die "Unable to close $powershell after listener rewrite: $!";
    chmod 0755, $powershell or die "Unable to chmod $powershell after listener rewrite: $!";
    is_deeply(
        [ $manager->_listener_pids_for_port(7921) ],
        [ 7301, 8402 ],
        '_listener_pids_for_port reads unique Windows listener pids directly from the PowerShell probe',
    );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $fakebin = File::Spec->catdir( $tmp, 'bin' );
    make_path($fakebin);
    my $ss = File::Spec->catfile( $fakebin, 'ss' );
    open my $ss_fh, '>', $ss or die "Unable to write $ss: $!";
    print {$ss_fh} <<"SCRIPT";
#!/bin/sh
echo "Can't exec ss: No such file or directory" >&2
exit 255
SCRIPT
    close $ss_fh or die "Unable to close $ss: $!";
    chmod 0755, $ss or die "Unable to chmod $ss: $!";

    my $lsof = File::Spec->catfile( $fakebin, 'lsof' );
    open my $lsof_fh, '>', $lsof or die "Unable to write $lsof: $!";
    print {$lsof_fh} <<"SCRIPT";
#!/bin/sh
cat <<'EOF'
p61530
f5
p61616
f5
p61617
EOF
SCRIPT
    close $lsof_fh or die "Unable to close $lsof: $!";
    chmod 0755, $lsof or die "Unable to chmod $lsof: $!";

    local $ENV{PATH} = join( ':', $fakebin, $ENV{PATH} || '' );
    is_deeply(
        [ $manager->_listener_pids_for_port(7890) ],
        [ 61530, 61616, 61617 ],
        '_listener_pids_for_port falls back to lsof when ss is unavailable on non-Windows hosts',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ( $name ) = @_;
        return 0 if $name eq 'ss';
        return 1;
    };
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
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ( $name ) = @_;
        return 0 if $name eq 'ss';
        return 1;
    };
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
    my $powershell = File::Spec->catfile( $fakebin, 'powershell' );
    open my $ps_bad_fh, '>', $powershell or die "Unable to write $powershell for ps scan: $!";
    print {$ps_bad_fh} <<"SCRIPT";
#!/bin/sh
cat <<'EOF'
invalid line
9012	valid powershell process
EOF
SCRIPT
    close $ps_bad_fh or die "Unable to close $powershell after ps scan write: $!";
    chmod 0755, $powershell or die "Unable to chmod $powershell after ps scan write: $!";
    local $ENV{PATH} = join ':', $fakebin, ( $ENV{PATH} || '' );
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
    is( $manager->_current_perl_command, '/usr/local/bin/perl', '_current_perl_command falls back to perl from PATH when the current interpreter path is missing' );

    local *Developer::Dashboard::RuntimeManager::command_in_path = sub {
        my ($name) = @_;
        return if $name eq 'perl';
        return '/usr/local/bin/perl.exe' if $name eq 'perl.exe';
        return;
    };
    is( $manager->_current_perl_command, '/usr/local/bin/perl.exe', '_current_perl_command falls back to perl.exe from PATH when plain perl is unavailable' );

    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { return };
    is( $manager->_current_perl_command, '/tmp/nonexistent-perl', '_current_perl_command finally returns the current interpreter path when no PATH fallback exists' );
}

{
    local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
    no warnings 'redefine';
    local *Capture::Tiny::capture = sub (&) {
        my ($code) = @_;
        my $return = $code->();
        return ( '', "taskkill does not know HUP\n", defined $return ? $return : 1 );
    };
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
    my $state_backed_pid = fork();
    die "fork failed: $!" if !defined $state_backed_pid;
    if ( !$state_backed_pid ) {
        while (1) { sleep 0.1 }
    }
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
            process_name => 'dashboard collector: beta.collector',
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
    kill 'KILL', $state_backed_pid if kill 0, $state_backed_pid;
    waitpid( $state_backed_pid, 0 ) if kill 0, $state_backed_pid;
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
            process_name => 'dashboard collector: alpha.collector',
        } if $name eq 'alpha.collector';
        return {
            pid          => $$,
            name         => 'wrong.collector',
            status       => 'starting',
            process_name => 'dashboard collector: wrong.collector',
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
runtime manager.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for This test verifies web-service and collector lifecycle management in the runtime manager. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because This test verifies web-service and collector lifecycle management in the runtime manager has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing This test verifies web-service and collector lifecycle management in the runtime manager, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/09-runtime-manager.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/09-runtime-manager.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/09-runtime-manager.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
