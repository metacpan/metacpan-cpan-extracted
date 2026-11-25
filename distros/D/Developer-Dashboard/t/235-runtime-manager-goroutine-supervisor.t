#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

BEGIN {
    no warnings qw(redefine once);
    *CORE::GLOBAL::fork = sub () { die "Perl fork was called by the test target\n" };
}

use lib 'lib';
require Developer::Dashboard::GoRoutine;
require Developer::Dashboard::RuntimeManager;

my $source_path = 'lib/Developer/Dashboard/RuntimeManager.pm';
open my $source_fh, '<', $source_path
  or die "Unable to read $source_path: $!";
my $source = do { local $/; <$source_fh> };
close $source_fh or die "Unable to close $source_path: $!";

my ($start_supervisor) = $source =~ /^sub _start_collector_supervisor\s*\{(.*?)^\}/ms;
ok( defined $start_supervisor, 'collector supervisor start routine is present' );
if ( defined $start_supervisor ) {
    unlike(
        $start_supervisor,
        qr/\bfork\s*\(/,
        'collector supervisor start does not call Perl fork directly',
    );
    like(
        $start_supervisor,
        qr/Developer::Dashboard::GoRoutine::spawn\s*\(/,
        'collector supervisor start delegates process creation to GoRoutine',
    );
}

my ($start_web) = $source =~ /^sub start_web\s*\{(.*?)^\}/ms;
ok( defined $start_web, 'web service start routine is present' );
if ( defined $start_web ) {
    unlike(
        $start_web,
        qr/\b_fork_process\s*\(/,
        'background web service startup does not invoke the Perl fork wrapper',
    );
    like(
        $start_web,
        qr/\->_start_web_background\s*\(/,
        'background web service startup delegates its lifecycle to the GoRoutine launcher',
    );
}
my ($start_web_background) = $source =~ /^sub _start_web_background\s*\{(.*?)^\}/ms;
ok( defined $start_web_background, 'GoRoutine web background launcher is present' );
if ( defined $start_web_background ) {
    unlike( $start_web_background, qr/\bfork\s*\(/, 'GoRoutine web launcher does not fork Perl' );
    like(
        $start_web_background,
        qr/Developer::Dashboard::GoRoutine::spawn\s*\(/,
        'GoRoutine web launcher creates the listener process with the native API',
    );
}

{
    package Local::SupervisorPaths;
    sub secure_file_permissions { return 1 }

    package Local::SupervisorFiles;
    sub collector_log { return '/tmp/dkt016-supervisor.log' }
    sub dashboard_log { return '/tmp/dkt016-web.log' }
    sub write { return 1 }
}

{
    my $temp_dir = tempdir( 'dd-goroutine-supervisor-XXXXXX', TMPDIR => 1, CLEANUP => 1 );
    my ( $spawned_argv, $spawned_options, $written_state );
    my $manager = bless {
        paths => bless( {}, 'Local::SupervisorPaths' ),
        files => bless( {}, 'Local::SupervisorFiles' ),
    }, 'Developer::Dashboard::RuntimeManager';

    no warnings qw(redefine once);
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { 0 };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub {
        return { watched_names => ['alpha'] };
    };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_pidfile = sub {
        return File::Spec->catfile( $temp_dir, 'supervisor.pid' );
    };
    local *Developer::Dashboard::RuntimeManager::_dashboard_core_helper_path = sub {
        my ( undef, $command ) = @_;
        return "/tmp/$command";
    };
    local *Developer::Dashboard::RuntimeManager::_current_perl_command = sub { return 'perl' };
    local *Developer::Dashboard::RuntimeManager::_write_collector_supervisor_state = sub {
        my ( undef, $state ) = @_;
        $written_state = { %{$state} };
        return $written_state;
    };
    local *Developer::Dashboard::GoRoutine::spawn = sub {
        ( $spawned_argv, $spawned_options ) = @_;
        return 9876;
    };

    my $pid = eval { $manager->_start_collector_supervisor };
    my $error = $@;
    is(
        $error,
        '',
        'collector supervisor starts without invoking Perl fork',
    );
    is(
        $pid,
        9876,
        'collector supervisor returns the pid from GoRoutine spawn',
    );
    is_deeply(
        $spawned_argv,
        [ 'perl', $manager->_perl_library_args, '/tmp/collector-supervisor-foreground', 'collector-supervisor-foreground' ],
        'collector supervisor launches the shared foreground helper without a shell',
    );
    is_deeply(
        $spawned_options,
        {
            stdin  => File::Spec->devnull(),
            stdout => '/tmp/dkt016-supervisor.log',
            stderr => '/tmp/dkt016-supervisor.log.stderr',
            env    => { DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR => 1 },
        },
        'collector supervisor redirects the helper standard streams to its log',
    );
    is( $written_state->{pid}, 9876, 'collector supervisor persists the spawned pid' );
    is( $written_state->{status}, 'running', 'collector supervisor persists its running state' );
}

{
    my ( $spawned_argv, $spawned_options, $written_state );
    my $manager = bless {
        files => bless( {}, 'Local::SupervisorFiles' ),
    }, 'Developer::Dashboard::RuntimeManager';

    no warnings qw(redefine once);
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_background_web_command = sub {
        my ( undef, %args ) = @_;
        my @command = ( 'perl', '/tmp/_dashboard-core', 'web-foreground', '--host', $args{host}, '--port', $args{port} );
        push @command, '--ssl' if $args{ssl};
        return @command;
    };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (4321) };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_web_process_title = sub { return 'd2 web: 127.0.0.1:7890' };
    local *Developer::Dashboard::RuntimeManager::_write_web_state = sub {
        my ( undef, $state ) = @_;
        $written_state = { %{$state} };
        return 1;
    };
    local *Developer::Dashboard::GoRoutine::spawn = sub {
        ( $spawned_argv, $spawned_options ) = @_;
        return 9876;
    };

    is(
        $manager->_start_web_background( host => '127.0.0.1', port => 7890, workers => 2, ssl => 1 ),
        4321,
        'GoRoutine web launcher returns the confirmed listener pid',
    );
    is_deeply(
        $spawned_argv,
        [ 'perl', '/tmp/_dashboard-core', 'web-foreground', '--host', '127.0.0.1', '--port', 7890, '--ssl' ],
        'GoRoutine web launcher passes literal helper arguments without a shell',
    );
    is_deeply(
        $spawned_options,
        {
            stdin  => File::Spec->devnull(),
            stdout => '/tmp/dkt016-web.log',
            stderr => '/tmp/dkt016-web.log.stderr',
            env    => {
                DEVELOPER_DASHBOARD_WEB_SERVICE => 1,
                DEVELOPER_DASHBOARD_WEB_HOST    => '127.0.0.1',
                DEVELOPER_DASHBOARD_WEB_PORT    => 7890,
                DEVELOPER_DASHBOARD_WEB_WORKERS => 2,
                DEVELOPER_DASHBOARD_WEB_SSL     => 1,
            },
        },
        'GoRoutine web launcher supplies inherited management identity and explicit log files',
    );
    is( $written_state->{pid}, 4321, 'GoRoutine web launcher persists the listener pid' );
    is( $written_state->{status}, 'running', 'GoRoutine web launcher persists a running state' );
}

{
    my ( $terminated_pid, $waited_pid );
    my $manager = bless {
        files => bless( {}, 'Local::SupervisorFiles' ),
    }, 'Developer::Dashboard::RuntimeManager';

    no warnings qw(redefine once);
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_background_web_command = sub { return ('perl', 'helper') };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::GoRoutine::spawn = sub { return 9876 };
    local *Developer::Dashboard::GoRoutine::terminate_process = sub {
        ( $terminated_pid, my $signal ) = @_;
        is( $signal, 'KILL', 'web startup timeout terminates the child explicitly' );
        return 1;
    };
    local *Developer::Dashboard::GoRoutine::wait_process = sub {
        ($waited_pid) = @_;
        return 137;
    };

    my $error = eval { $manager->_start_web_background( host => '127.0.0.1', port => 7890 ); 1 } ? '' : $@;
    like( $error, qr/exited with status 137/, 'web startup timeout reports the child exit status' );
    is( $terminated_pid, 9876, 'web startup timeout terminates the spawned child' );
    is( $waited_pid, 9876, 'web startup timeout reaps the spawned child' );
}

done_testing();

__END__

=head1 NAME

t/235-runtime-manager-goroutine-supervisor.t - guard runtime process creation during GoRoutine migration

=head1 PURPOSE

This test protects the collector supervisor and POSIX background web-service
start paths after they were migrated to the GoRoutine native process API. It
reads production routines as source contracts and stubs the spawn/readiness
boundary, so the regression can run without starting persistent services.

=head1 WHY IT EXISTS

Starting a detached collector supervisor or web service is a sensitive process
boundary. This contract detects a return to direct Perl C<fork>, verifies that
the active runtime delegates process creation to the shared native
implementation, and confirms that web startup failures terminate and reap the
child instead of returning an unverified process id.

=head1 WHEN TO USE

Run this test in the dev Docker container when changing
C<RuntimeManager::_start_collector_supervisor>,
C<RuntimeManager::_start_web_background>, or the GoRoutine process-launch API.
It verifies the delegated launch paths without starting real long-lived
processes.

=head1 HOW TO USE

Run the contract from the project root in the dev Docker container:

  d2 docker compose exec dev prove -lv t/235-runtime-manager-goroutine-supervisor.t

If testing a freshly built XS library, put its build paths first:

  d2 docker compose exec dev bash -c 'PERL5LIB=/work/blib/lib:/work/blib/arch prove -lv t/235-runtime-manager-goroutine-supervisor.t'

=head1 WHAT USES IT

The distribution test suite runs this test with the RuntimeManager and
collector lifecycle tests. Maintainers use it when changing either detached
service startup path or the native process-launch API.

=head1 EXAMPLES

From the project root, run:

  d2 docker compose exec dev prove -lv t/235-runtime-manager-goroutine-supervisor.t

After the native extension is rebuilt, provide its build paths to C<prove>:

  d2 docker compose exec dev bash -c 'PERL5LIB=/work/blib/lib:/work/blib/arch prove -lv t/235-runtime-manager-goroutine-supervisor.t'

=head1 ASSERTIONS

The test confirms that the collector-supervisor startup routine exists, no
longer invokes Perl C<fork> directly, and calls
C<Developer::Dashboard::GoRoutine::spawn>. It covers only this supervisor
startup path; other runtime process call sites require their own tests.

=cut
