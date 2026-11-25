#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(EBADF);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;

# Keep the Windows background-start readiness loop instant and hermetic.
$ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS} = 1;

{
    package Local::Runner;
    sub new           { return bless {}, shift }
    sub running_loops { return () }

    package Local::Server;
    sub new { my ( $class, %args ) = @_; return bless { %args }, $class }
    sub run { return 'foreground-ran' }
    sub start_daemon { return bless {}, 'Local::Daemon' }
    sub serve_daemon { return 1 }
    sub _run_ssl_backend_process {
        my ( $self, $daemon ) = @_;
        return $self->{run_ssl_backend}->($daemon);
    }

    package Local::Daemon;
    sub sockhost { return '127.0.0.1' }
    sub sockport { return 7894 }
}

my $original_cwd = getcwd();
my $home         = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

my $manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub { return Local::Server->new(@_) },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => Local::Runner->new,
);

# ---------------------------------------------------------------------------
# _write_startup_pipe_message: the startup pipe writer closes cleanly.
#
# The shipped _close_startup_pipe_writer wrapper exists precisely so this seam
# can be driven from both sides. Every real invocation on this host reports a
# close failure that the caller then classifies via $!, so the "close reported
# success" arm of the guard is only reachable through the documented wrapper
# override. Drive it here so the success arm stays exercised and cannot rot
# into a silent die.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my @closed;
    local *Developer::Dashboard::RuntimeManager::_close_startup_pipe_writer = sub {
        my ( $self, $writer ) = @_;
        push @closed, $writer;
        return 1;
    };

    my $path = File::Spec->catfile( $home, 'startup-clean-close.txt' );
    open my $writer, '>', $path or die "Unable to open $path: $!";
    my $payload = "ok|4242|0.0.0.0|7890\n";
    ok(
        $manager->_write_startup_pipe_message( $writer, $payload ),
        '_write_startup_pipe_message succeeds when the startup pipe writer closes cleanly'
    );
    is( scalar @closed, 1, '_write_startup_pipe_message closes the startup pipe writer exactly once' );
    close $writer or die "Unable to close $path: $!";

    open my $reader, '<', $path or die "Unable to read $path: $!";
    my $written = do { local $/; <$reader> };
    close $reader or die "Unable to close $path: $!";
    is( $written, $payload, '_write_startup_pipe_message wrote the whole payload before the clean close' );
}

# The counterpart arm of the same guard: the writer reports a close failure and
# the caller tolerates it once it recognizes the expected errno value.
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_close_startup_pipe_writer = sub {
        $! = EBADF;
        return 0;
    };

    my $path = File::Spec->catfile( $home, 'startup-tolerated-close.txt' );
    open my $writer, '>', $path or die "Unable to open $path: $!";
    ok(
        $manager->_write_startup_pipe_message( $writer, "ok|4243|0.0.0.0|7891\n" ),
        '_write_startup_pipe_message tolerates the expected startup pipe close failure'
    );
    close $writer or die "Unable to close $path: $!";
}

# ---------------------------------------------------------------------------
# _start_web_windows_background: both live sides of the persisted-pid choice.
#
# The confirmed listener pid wins when it is a usable process id, and the
# spawned background pid is the fallback when listener discovery yields a
# falsy pid for the port.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_windows_background_web_command = sub {
        return ( 'perl.exe', 'd2', 'serve' );
    };
    local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 7100 };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections       = sub { return 1 };

    {
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (7301) };
        is(
            $manager->_start_web_windows_background( host => '127.0.0.1', port => 7890, workers => 2, ssl => 1 ),
            7301,
            '_start_web_windows_background persists the confirmed listener pid'
        );
        my $state = $manager->web_state;
        is( $state->{pid},     7301,        'the persisted Windows web state keeps the confirmed listener pid' );
        is( $state->{workers}, 2,           'the persisted Windows web state keeps the requested worker count' );
        is( $state->{ssl},     1,           'the persisted Windows web state keeps the requested ssl flag' );
        is( $state->{host},    '127.0.0.1', 'the persisted Windows web state keeps the requested host' );
        my $pidfile = $files->read('web_pid');
        chomp $pidfile if defined $pidfile;
        is( $pidfile, '7301', 'the Windows web pid file records the confirmed listener pid' );
    }

    {
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (0) };
        is(
            $manager->_start_web_windows_background( host => '127.0.0.1', port => 7890 ),
            7100,
            '_start_web_windows_background falls back to the spawned pid when the listener pid is falsy'
        );
        my $state = $manager->web_state;
        is( $state->{pid},     7100, 'the persisted Windows web state falls back to the spawned pid' );
        is( $state->{workers}, 1,    'the persisted Windows web state defaults the worker count' );
        is( $state->{ssl},     0,    'the persisted Windows web state defaults the ssl flag' );
        my $pidfile = $files->read('web_pid');
        chomp $pidfile if defined $pidfile;
        is( $pidfile, '7100', 'the Windows web pid file records the spawned fallback pid' );
    }
}

# ---------------------------------------------------------------------------
# serve_ssl_backend_foreground: validate the isolated backend inputs and default
# its worker count before building the backend server.
# ---------------------------------------------------------------------------
{
    my $err = eval { $manager->serve_ssl_backend_foreground( port => 7890 ); 1 } ? '' : $@;
    like( $err, qr/Missing SSL backend host/, 'serve_ssl_backend_foreground requires an internal host' );

    $err = eval { $manager->serve_ssl_backend_foreground( host => '127.0.0.1' ); 1 } ? '' : $@;
    like( $err, qr/Missing SSL backend port/, 'serve_ssl_backend_foreground requires an internal port' );

    $err = eval { $manager->serve_ssl_backend_foreground( host => '127.0.0.1', port => 0 ); 1 } ? '' : $@;
    like( $err, qr/SSL backend port must be a positive integer/, 'serve_ssl_backend_foreground rejects a zero internal port' );

    $err = eval { $manager->serve_ssl_backend_foreground( host => '127.0.0.1', port => 'not-a-port' ); 1 } ? '' : $@;
    like( $err, qr/SSL backend port must be a positive integer/, 'serve_ssl_backend_foreground rejects a nonnumeric internal port' );

    $err = eval { $manager->serve_ssl_backend_foreground( host => '127.0.0.1', port => 7890, workers => 0 ); 1 } ? '' : $@;
    like( $err, qr/Worker count must be a positive integer/, 'serve_ssl_backend_foreground rejects a zero worker count' );

    $err = eval { $manager->serve_ssl_backend_foreground( host => '127.0.0.1', port => 7890, workers => 'not-a-count' ); 1 } ? '' : $@;
    like( $err, qr/Worker count must be a positive integer/, 'serve_ssl_backend_foreground rejects a nonnumeric worker count' );

    no warnings 'redefine';
    no strict 'refs';
    require Developer::Dashboard::Web::Server::Daemon;
    my %built;
    my $server = bless {
        run_ssl_backend => sub { return 23 },
    }, 'Local::Server';
    local *{'Developer::Dashboard::Web::Server::Daemon::new'} = sub {
        my ( $class, %args ) = @_;
        $built{daemon} = \%args;
        return bless \%args, 'Local::SSLServer::Daemon';
    };
    local $manager->{app_builder} = sub {
        my %args = @_;
        $built{server} = \%args;
        return $server;
    };

    is(
        $manager->serve_ssl_backend_foreground( host => '127.0.0.1', port => 7890 ),
        23,
        'serve_ssl_backend_foreground returns the backend runner status',
    );
    is( $built{server}{workers}, 1, 'serve_ssl_backend_foreground defaults the worker count' );
    is( $built{server}{ssl}, 1, 'serve_ssl_backend_foreground always builds the isolated server with SSL enabled' );
    is( $built{daemon}{internal_port}, 7890, 'serve_ssl_backend_foreground passes the internal listener port to its daemon' );
}

# ---------------------------------------------------------------------------
# _start_web_background: use the spawned child pid when listener discovery
# returns a false pid even though the port has become ready.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    require Developer::Dashboard::GoRoutine;
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_background_web_command = sub { return ('perl', 'web-foreground') };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (0) };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 1 };
    local *Developer::Dashboard::GoRoutine::spawn = sub { return 7400 };

    is(
        $manager->_start_web_background( host => '127.0.0.1', port => 7891 ),
        7400,
        '_start_web_background falls back to the spawned pid when the ready listener pid is false',
    );
    is( $manager->web_state->{pid}, 7400, '_start_web_background persists the spawned fallback pid' );

    my %spawn_options;
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::GoRoutine::spawn = sub {
        my ( $command, $options ) = @_;
        %spawn_options = %{$options};
        return 7401;
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (7402) };
    is( $manager->_start_web_background(), 7402, '_start_web_background adopts the discovered listener pid' );
    is( $spawn_options{env}{DEVELOPER_DASHBOARD_WEB_HOST}, '0.0.0.0', '_start_web_background defaults the listener host' );
    is( $spawn_options{env}{DEVELOPER_DASHBOARD_WEB_PORT}, 7890, '_start_web_background defaults the listener port' );
    is( $spawn_options{env}{DEVELOPER_DASHBOARD_WEB_WORKERS}, 1, '_start_web_background defaults the worker count' );
}

# A discovered socket is not sufficient readiness evidence until it accepts a
# connection; exercise the second operand's false path and child cleanup.
{
    no warnings 'redefine';
    require Developer::Dashboard::GoRoutine;
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_background_web_command = sub { return ('perl', 'web-readiness') };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (7405) };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    local *Developer::Dashboard::GoRoutine::spawn = sub { return 7406 };
    local *Developer::Dashboard::GoRoutine::terminate_process = sub { return 1 };
    local *Developer::Dashboard::GoRoutine::wait_process = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    my $err = eval { $manager->_start_web_background( host => '127.0.0.1', port => 7895 ); 1 } ? '' : $@;
    like( $err, qr/Unable to start dashboard web service/, 'a discovered listener that rejects connections is not accepted as ready' );
}

# ---------------------------------------------------------------------------
# _start_web_background: a failed native process launch is surfaced and a
# listener that is not ready is not persisted as a running service.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    require Developer::Dashboard::GoRoutine;
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_background_web_command = sub { return ('perl', 'web-foreground') };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::GoRoutine::spawn = sub { return 0 };
    my $err = eval { $manager->_start_web_background( host => '127.0.0.1', port => 7892 ); 1 } ? '' : $@;
    like( $err, qr/Unable to launch dashboard web service process/, '_start_web_background reports a failed native process launch' );

    local *Developer::Dashboard::GoRoutine::spawn = sub { return 7403 };
    local *Developer::Dashboard::GoRoutine::terminate_process = sub { return 1 };
    local *Developer::Dashboard::GoRoutine::wait_process = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    $err = eval { $manager->_start_web_background( host => '127.0.0.1', port => 7892 ); 1 } ? '' : $@;
    like( $err, qr/Unable to start dashboard web service/, '_start_web_background reports a child that never opens its listener' );
}

# ---------------------------------------------------------------------------
# _run_collector_supervisor_child: default daemonize/redirect options take the
# detach and stdio-redirection path before running a single controlled loop pass.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR};
    local *Developer::Dashboard::RuntimeManager::_detach_web_process_session = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub { return { watched_names => ['a'] } };
    local *Developer::Dashboard::RuntimeManager::_supervise_collectors_once = sub { return {} };
    local *Developer::Dashboard::RuntimeManager::_reap_any_child_processes = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_write_collector_supervisor_state = sub { return $_[1] };
    local *Developer::Dashboard::RuntimeManager::_close_inherited_fds = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { die "__STOP_DEFAULT_SUPERVISOR__\n" };
    my $child_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub { return Local::Server->new(@_) },
        config      => $config,
        files       => $files,
        paths       => $paths,
        runner      => Local::Runner->new,
    );
    open my $save_in,  '<&', \*STDIN  or die "Unable to save STDIN: $!";
    open my $save_out, '>&', \*STDOUT or die "Unable to save STDOUT: $!";
    open my $save_err, '>&', \*STDERR or die "Unable to save STDERR: $!";
    my $err = eval { $child_manager->_run_collector_supervisor_child(); 1 } ? '' : $@;
    open STDIN,  '<&', $save_in  or die "Unable to restore STDIN: $!";
    open STDOUT, '>&', $save_out or die "Unable to restore STDOUT: $!";
    open STDERR, '>&', $save_err or die "Unable to restore STDERR: $!";
    like( $err, qr/__STOP_DEFAULT_SUPERVISOR__/, '_run_collector_supervisor_child uses default daemonize/redirect settings and enters its loop' );
}

# The installed TERM handler delegates to the supervisor shutdown path. Stub
# process exit so the signal closure is observable in-process.
{
    no warnings 'redefine';
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR};
    local *Developer::Dashboard::RuntimeManager::_detach_web_process_session = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub { return { watched_names => ['a'] } };
    local *Developer::Dashboard::RuntimeManager::_supervise_collectors_once = sub { $SIG{TERM}->(); return {} };
    local *Developer::Dashboard::RuntimeManager::_reap_any_child_processes = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_write_collector_supervisor_state = sub { return $_[1] };
    my @shutdown_status;
    local *Developer::Dashboard::RuntimeManager::_shutdown_collector_supervisor = sub {
        push @shutdown_status, $_[1];
        die "__SIGNAL_SUPERVISOR_SHUTDOWN__\n";
    };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { die "__STOP_SIGNAL_SUPERVISOR__\n" };
    my $child_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub { return Local::Server->new(@_) },
        config      => $config,
        files       => $files,
        paths       => $paths,
        runner      => Local::Runner->new,
    );
    my $err = eval { $child_manager->_run_collector_supervisor_child( daemonize => 0, redirect => 0 ); 1 } ? '' : $@;
    like( $err, qr/__STOP_SIGNAL_SUPERVISOR__/, 'the collector supervisor resumes its loop after the shutdown hook is intercepted' );
    is_deeply( \@shutdown_status, ['stopped'], 'the supervisor TERM handler requests the stopped state' );
}

# ---------------------------------------------------------------------------
# _start_collector_supervisor: a false GoRoutine spawn result is a startup
# failure, distinct from an exception thrown by the native launch layer.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_background_collector_supervisor_command = sub { return ('perl', 'collector-supervisor') };
    local *Developer::Dashboard::GoRoutine::spawn = sub { return undef };
    $manager->_write_collector_supervisor_state( { watched_names => ['alpha'] } );
    my $err = eval { $manager->_start_collector_supervisor; 1 } ? '' : $@;
    like( $err, qr/Unable to launch detached collector supervisor process/, '_start_collector_supervisor reports a false GoRoutine spawn result' );
    $manager->_cleanup_collector_supervisor_files;
}

# ---------------------------------------------------------------------------
# _run_web_child: omitted options choose detached mode; with detachment disabled,
# omitted redirect still configures redirected in-process server I/O.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_start_web_background = sub { return 7404 };
    open my $wr, '>', \my $buf or die "Unable to open startup buffer: $!";
    is( $manager->_run_web_child( $wr, '127.0.0.1', 7893 ), 0, '_run_web_child defaults to detached startup' );
    like( $buf, qr/^ok\|7404\|127\.0\.0\.1\|7893\n\z/, '_run_web_child reports the detached child using default options' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_close_inherited_fds = sub { return 1 };
    my $child_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub { return Local::Server->new(@_) },
        config      => $config,
        files       => $files,
        paths       => $paths,
        runner      => Local::Runner->new,
    );
    open my $wr, '>', \my $buf or die "Unable to open startup buffer: $!";
    open my $save_in,  '<&', \*STDIN  or die "Unable to save STDIN: $!";
    open my $save_out, '>&', \*STDOUT or die "Unable to save STDOUT: $!";
    open my $save_err, '>&', \*STDERR or die "Unable to save STDERR: $!";
    my $exit = $child_manager->_run_web_child( $wr, '127.0.0.1', 7894, detach => 0 );
    open STDIN,  '<&', $save_in  or die "Unable to restore STDIN: $!";
    open STDOUT, '>&', $save_out or die "Unable to restore STDOUT: $!";
    open STDERR, '>&', $save_err or die "Unable to restore STDERR: $!";
    is( $exit, 0, '_run_web_child redirects in-process I/O when redirect is omitted and detach is disabled' );
}
{
    no warnings 'redefine';
    local $ENV{DEVELOPER_DASHBOARD_WEB_SERVICE};
    local $ENV{DEVELOPER_DASHBOARD_WEB_HOST};
    local $ENV{DEVELOPER_DASHBOARD_WEB_PORT};
    local $ENV{DEVELOPER_DASHBOARD_WEB_WORKERS};
    local $ENV{DEVELOPER_DASHBOARD_WEB_SSL};
    local *Developer::Dashboard::RuntimeManager::_close_inherited_fds = sub { die 'inherited descriptors must remain open' };
    my $child_manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub { return Local::Server->new(@_) },
        config      => $config,
        files       => $files,
        paths       => $paths,
        runner      => Local::Runner->new,
    );
    open my $wr, '>', \my $buf or die "Unable to open startup buffer: $!";
    is(
        $child_manager->_run_web_child( $wr, '127.0.0.1', 7896, detach => 0, redirect => 0 ),
        0,
        '_run_web_child keeps inherited descriptors open when neither detach nor redirect is requested'
    );
}

# ---------------------------------------------------------------------------
# _is_managed_web: invalid/stale persisted state must not validate an opaque
# server title as a managed Starman listener.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'starman master' };
    local *Developer::Dashboard::RuntimeManager::_read_settled_web_state = sub {
        return ( { pid => $$, port => 7890, status => '' }, 0 );
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return ($$) };
    ok( !$manager->_is_managed_web($$), '_is_managed_web rejects a saved state without running status' );

    for my $state (
        undef,
        { status => 'running' },
        { status => 'running', pid => 'not-a-pid', port => 7890 },
        { status => 'running', pid => $$ + 1, port => 7890 },
        { status => 'running', pid => $$ },
        { status => 'running', pid => $$, port => 'not-a-port' },
        { status => 'running', pid => $$, port => 0 },
    ) {
        local *Developer::Dashboard::RuntimeManager::_read_settled_web_state = sub { return ( $state, 0 ) };
        ok( !$manager->_is_managed_web($$), '_is_managed_web rejects malformed, mismatched, or incomplete persisted listener state' );
    }
}

chdir $original_cwd or die "Unable to chdir to $original_cwd: $!";

done_testing;

__END__

=pod

=head1 NAME

t/119-runtimemanager-coverage-3.t - runtime manager startup-pipe and Windows background-start coverage

=head1 PURPOSE

This test closes runtime lifecycle decision points: the startup-pipe writer
success path; both sides of the Windows background-start pid choice; SSL backend
argument validation and worker defaults; web startup defaults, native launch
failure, socket-present-but-not-accepting readiness and listener-pid selection;
default collector supervisor daemonize/redirect behavior and TERM shutdown;
web-child default options and inherited-descriptor policy; and persisted-state
validation for opaque Starman titles.

=head1 WHY IT EXISTS

These decisions are invisible to the rest of the suite. The startup-pipe close
wrapper always reports a failure that the caller classifies through the errno
value on this host, so the success arm was never executed and a future edit
could have turned it into an unconditional die without any test noticing. The
Windows background start similarly only ever ran with a usable listener pid in
the rest of the suite, leaving its documented fallback to the spawned pid
unproven. A discovered socket that is not accepting connections must also fail
readiness rather than persist false-running state. The collector supervisor's
signal callback and the web child's no-detach/no-redirect descriptor policy are
separate lifecycle decisions; this file exercises them without starting or
terminating real services. SSL helper argument guards, the ready-listener
fallback, and persisted-state validation protect distinct startup and
process-ownership paths. This file keeps these choices executable and measurable
by the coverage gate.

=head1 WHEN TO USE

Use this file when changing how the background web child reports startup back
to its parent, how the startup pipe writer is closed and its errno classified,
how the Windows background start resolves and persists the web service process
id, worker count, and ssl flag; how the isolated TLS backend validates its
arguments; how the supervisor handles TERM; how web children preserve inherited
descriptors when neither detach nor redirect is requested; or how runtime state
is used to identify a managed Starman process.

=head1 HOW TO USE

Run C<prove -lv t/119-runtimemanager-coverage-3.t> while iterating on the
runtime manager. Keep it green under C<prove -lr t> and inside the coverage
gate before release.

=head1 WHAT USES IT

Developers changing the runtime lifecycle manager, the repository test suite,
and the branch/condition coverage gate all rely on this file.

=head1 EXAMPLES

Example 1:

  prove -lv t/119-runtimemanager-coverage-3.t

Run the runtime-manager startup-pipe, SSL-backend, listener-fallback, and
Windows background-start checks alone.

Example 2:

  prove -lr t

Run them as part of the full repository suite before release.

=cut
