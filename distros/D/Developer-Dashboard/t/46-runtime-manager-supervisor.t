#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use Errno qw(EACCES);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use Time::HiRes qw(sleep);

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;
use Developer::Dashboard::GoRoutine ();

{
    package Local::SupervisorRunner;

    sub new { return bless {}, shift }
    sub running_loops { return (); }
}

my $original_cwd = getcwd();
my $repo_lib = File::Spec->catdir( $original_cwd, 'lib' );
my $test_cwd = tempdir( CLEANUP => 1 );
chdir $test_cwd or die "Unable to chdir to $test_cwd: $!";

# _runtime_fixture_script($body)
# Builds Perl source for an isolated runtime-manager process fixture.
# Input: statements to run after a filesystem-backed manager is reconstructed.
# Output: complete child Perl source string for GoRoutine::spawn.
sub _runtime_fixture_script {
    my ($body) = @_;
    die "runtime fixture body must be a non-empty scalar\n"
      if !defined $body || ref($body) || $body eq '';
    return sprintf q{
        use lib q{%s};
        use Developer::Dashboard::PathRegistry;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::RuntimeManager;
        use Developer::Dashboard::GoRoutine ();
        my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
        my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
        my $manager = Developer::Dashboard::RuntimeManager->new(
            app_builder => sub { die "unexpected app build in process fixture\n" },
            config => bless({}, 'Local::FixtureConfig'),
            files => $files,
            paths => $paths,
            runner => bless({}, 'Local::FixtureRunner'),
        );
        %s
    }, $repo_lib, $body;
}

# _spawn_perl_fixture($script, $options)
# Starts a Perl child fixture through the native GoRoutine process API.
# Input: child source and optional process options hash reference.
# Output: positive child process identifier.
sub _spawn_perl_fixture {
    my ( $script, $options ) = @_;
    die "process fixture source must be a non-empty scalar\n"
      if !defined $script || ref($script) || $script eq '';
    return Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', $script ],
        $options || {},
    );
}

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $runner = Local::SupervisorRunner->new;

my $manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub { die "app builder should not run in supervisor tests\n" },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => $runner,
);

is(
    $manager->_collector_supervisor_process_title,
    'd2 collector supervisor',
    'collector supervisor uses the expected process title',
);
like(
    $manager->_collector_supervisor_pidfile,
    qr/collector-supervisor\.pid\z/,
    'collector supervisor pidfile path is stable',
);
like(
    $manager->_collector_supervisor_statefile,
    qr/collector-supervisor\.json\z/,
    'collector supervisor statefile path is stable',
);

is_deeply(
    [ $manager->_normalized_collector_watch_names( [ 'beta', '', 'alpha', 'beta', undef ] ) ],
    [ 'alpha', 'beta' ],
    'collector watchdog target names are normalized, filtered, and sorted',
);

{
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_LIMIT} = 7;
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_WINDOW_SECONDS} = 42;
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR_POLL_INTERVAL} = 0.75;
    is( $manager->_collector_restart_limit, 7, 'collector restart limit respects the environment override' );
    is( $manager->_collector_restart_window_seconds, 42, 'collector restart window respects the environment override' );
    is( $manager->_collector_supervisor_poll_interval, 0.75, 'collector supervisor poll interval respects the environment override' );
}

is( $manager->_collector_restart_limit, 3, 'collector restart limit defaults to three restarts' );
is( $manager->_collector_restart_window_seconds, 300, 'collector restart window defaults to five minutes' );
is( $manager->_collector_supervisor_poll_interval, 5, 'collector supervisor poll interval defaults to five seconds' );

ok(
    $manager->_looks_like_collector_supervisor_process(
        { pid => $$, args => 'd2 collector supervisor' }
    ),
    'collector supervisor title records are recognized',
);
ok(
    $manager->_looks_like_collector_supervisor_process(
        { pid => $$, args => '_dashboard-core collector-supervisor-foreground' }
    ),
    'collector supervisor helper command lines are recognized',
);
ok(
    $manager->_looks_like_collector_supervisor_process(
        { pid => $$, args => 'perl /tmp/_dashboard-core collector-supervisor-foreground --poll 1' }
    ),
    'collector supervisor perl helper command lines are recognized',
);
ok(
    !$manager->_looks_like_collector_supervisor_process(
        { pid => $$, args => 'd2 collector start alpha' }
    ),
    'unrelated collector commands are not mistaken for the supervisor',
);

{
    my @signals;
    my @sleeps;
    my $reaped_pid = 0;
    my $cleaned = 0;
    my $running_checks = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::sleep = sub { push @sleeps, $_[0]; return 0 };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return 4242 };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub {
        $running_checks++;
        return $running_checks <= 22 ? 1 : 0;
    };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub {
        my ( $self, $signal, @pids ) = @_;
        push @signals, [ $signal, @pids ];
        return scalar @pids;
    };
    local *Developer::Dashboard::RuntimeManager::_reap_child_process = sub {
        my ( $self, $pid ) = @_;
        $reaped_pid = $pid;
        return 1;
    };
    local *Developer::Dashboard::RuntimeManager::_cleanup_collector_supervisor_files = sub {
        $cleaned = 1;
        return 1;
    };
    $manager->_stop_collector_supervisor;
    is_deeply(
        \@signals,
        [
            [ 'TERM', 4242 ],
            [ 'KILL', 4242 ],
        ],
        '_stop_collector_supervisor escalates from TERM to KILL when the supervisor stays alive',
    );
    is( scalar @sleeps, 21, '_stop_collector_supervisor waits through the TERM loop and the post-KILL confirmation loop' );
    is( $reaped_pid, 4242, '_stop_collector_supervisor reaps the stopped supervisor pid after escalation' );
    ok( $cleaned, '_stop_collector_supervisor still cleans up supervisor state files after escalation' );
}

{
    my $state = $manager->_write_collector_supervisor_state(
        {
            pid           => 3210,
            process_name  => $manager->_collector_supervisor_process_title,
            status        => 'running',
            watched_names => [ 'alpha', 'beta' ],
        }
    );
    is( $state->{pid}, 3210, 'collector supervisor state write returns the persisted payload' );
    is_deeply(
        $manager->_collector_supervisor_state,
        {
            pid           => 3210,
            process_name  => $manager->_collector_supervisor_process_title,
            status        => 'running',
            watched_names => [ 'alpha', 'beta' ],
        },
        'collector supervisor state reads back the persisted payload',
    );
    ok( $manager->_cleanup_collector_supervisor_files, 'collector supervisor cleanup returns a true value' );
    ok( !-f $manager->_collector_supervisor_statefile, 'collector supervisor cleanup removes the state file' );
}

{
    my $rename_attempt = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_rename_path = sub {
        my ( undef, $source, $target ) = @_;
        $rename_attempt++;
        if ( $rename_attempt == 1 ) {
            $! = EACCES;
            return 0;
        }
        return CORE::rename( $source, $target );
    };
    local *Developer::Dashboard::RuntimeManager::_replace_path_via_powershell = sub {
        my ( undef, $source, $target ) = @_;
        return ( CORE::rename( $source, $target ) ? 1 : 0, $! );
    };
    my $state = $manager->_write_collector_supervisor_state(
        {
            pid           => 6543,
            process_name  => $manager->_collector_supervisor_process_title,
            status        => 'running',
            watched_names => ['gamma'],
        }
    );
    is( $state->{pid}, 6543, '_write_collector_supervisor_state returns the payload after the Windows PowerShell replacement fallback' );
    is_deeply(
        $manager->_collector_supervisor_state,
        {
            pid           => 6543,
            process_name  => $manager->_collector_supervisor_process_title,
            status        => 'running',
            watched_names => ['gamma'],
        },
        '_write_collector_supervisor_state persists the payload after the Windows PowerShell replacement fallback',
    );
    ok( $manager->_cleanup_collector_supervisor_files, 'collector supervisor cleanup still works after the Windows replacement fallback path' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return '1' };
    ok( $manager->_is_collector_supervisor($$), 'collector supervisor marker environment wins process detection' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub {
        return 'd2 collector supervisor';
    };
    ok( $manager->_is_collector_supervisor($$), 'collector supervisor title fallback detects the process' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub {
        return 'perl /tmp/_dashboard-core collector-supervisor-foreground';
    };
    ok( $manager->_is_collector_supervisor($$), 'collector supervisor helper-shape fallback detects the process' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub {
        return 'd2 collector start alpha';
    };
    ok( !$manager->_is_collector_supervisor($$), 'collector supervisor detection rejects unrelated processes' );
}

{
    open my $fh, '>', $manager->_collector_supervisor_pidfile or die $!;
    print {$fh} "$$\n";
    close $fh;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_is_collector_supervisor = sub { return 1 };
    is(
        $manager->_collector_supervisor_running,
        $$,
        'collector supervisor running returns the live managed pid from the pidfile',
    );
}

{
    open my $fh, '>', $manager->_collector_supervisor_pidfile or die $!;
    print {$fh} "999999\n";
    close $fh;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_is_collector_supervisor = sub { return 0 };
    ok( !defined $manager->_collector_supervisor_running, 'collector supervisor running clears stale pidfiles' );
    ok( !-f $manager->_collector_supervisor_pidfile, 'collector supervisor running removes stale pidfiles after cleanup' );
}

{
    my $stopped = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_stop_collector_supervisor = sub {
        $stopped++;
        return;
    };
    ok( !defined $manager->_set_collector_supervisor_targets( [] ), 'empty collector supervisor targets stop the watchdog' );
    is( $stopped, 1, 'empty collector supervisor targets delegate to the watchdog stop path' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return 7654 };
    my $pid = $manager->_set_collector_supervisor_targets( [ 'beta', 'alpha' ] );
    is( $pid, 7654, 'collector supervisor target updates keep an already-running supervisor' );
    is_deeply(
        $manager->_collector_supervisor_state->{watched_names},
        [ 'alpha', 'beta' ],
        'collector supervisor target updates persist the normalized watch list',
    );
    is(
        $manager->_collector_supervisor_state->{status},
        'running',
        'collector supervisor target updates mark existing watchdogs as running',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_start_collector_supervisor = sub { return 8844 };
    is(
        $manager->_set_collector_supervisor_targets( [ 'gamma', 'alpha' ] ),
        8844,
        'collector supervisor target updates start a watchdog when one is not already running',
    );
    is(
        $manager->_collector_supervisor_state->{status},
        'starting',
        'collector supervisor target updates mark new watchdogs as starting before launch',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub {
        return { watched_names => [ 'alpha', 'beta' ] };
    };
    local *Developer::Dashboard::RuntimeManager::_set_collector_supervisor_targets = sub {
        my ( undef, $names ) = @_;
        return join ',', @{$names};
    };
    is(
        $manager->_merge_collector_supervisor_targets( [ 'beta', 'alpha' ] ),
        'alpha,beta',
        'collector supervisor merges new watched names into the existing set',
    );
    is(
        $manager->_remove_collector_supervisor_targets( ['alpha'] ),
        'beta',
        'collector supervisor removes requested names from the watched set',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { 1 };
    local *Developer::Dashboard::RuntimeManager::_current_perl_command = sub { return 'perl.exe' };
    local *Developer::Dashboard::RuntimeManager::_dashboard_core_helper_path = sub {
        my ( undef, $command ) = @_;
        return "C:/dd/$command";
    };
    is_deeply(
        [ $manager->_background_collector_supervisor_command ],
        [ 'perl.exe', $manager->_perl_library_args, 'C:/dd/collector-supervisor-foreground', 'collector-supervisor-foreground' ],
        'collector supervisor Windows helper command uses the private foreground entrypoint',
    );
}

{
    my ( $spawned_argv, $spawned_options );
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { 1 };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_current_perl_command = sub { return 'perl.exe' };
    local *Developer::Dashboard::RuntimeManager::_dashboard_core_helper_path = sub {
        my ( undef, $command ) = @_;
        return "C:/dd/$command";
    };
    local *Developer::Dashboard::GoRoutine::spawn = sub {
        ( $spawned_argv, $spawned_options ) = @_;
        return 5566;
    };
    $manager->_write_collector_supervisor_state(
        {
            watched_names => ['alpha'],
        }
    );
    is( $manager->_start_collector_supervisor, 5566, 'collector supervisor starts through the Windows detached helper path' );
    is_deeply(
        $spawned_argv,
        [ 'perl.exe', $manager->_perl_library_args, 'C:/dd/collector-supervisor-foreground', 'collector-supervisor-foreground' ],
        'collector supervisor start launches the expected helper command without a shell',
    );
    is_deeply(
        $spawned_options,
        {
            stdin  => File::Spec->devnull(),
            stdout => $files->collector_log,
            stderr => $files->collector_log . '.stderr',
            env    => { DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR => 1 },
        },
        'collector supervisor start redirects helper standard streams',
    );
    is( $manager->_collector_supervisor_state->{pid}, 5566, 'collector supervisor Windows start persists the supervisor pid' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return 6677 };
    $manager->_write_collector_supervisor_state(
        {
            watched_names => ['alpha'],
        }
    );
    is( $manager->_start_collector_supervisor, 6677, 'collector supervisor start returns an already-running watchdog pid without relaunching it' );
}

{
    my $child_pid;
    no warnings 'redefine';
    my ( $spawned_argv, $spawned_options );
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { 0 };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_current_perl_command = sub { return 'perl' };
    local *Developer::Dashboard::RuntimeManager::_dashboard_core_helper_path = sub {
        my ( undef, $command ) = @_;
        return "/tmp/$command";
    };
    local *Developer::Dashboard::GoRoutine::spawn = sub {
        ( $spawned_argv, $spawned_options ) = @_;
        return 6677;
    };
    $manager->_write_collector_supervisor_state(
        {
            watched_names => ['alpha'],
        }
    );
    $child_pid = $manager->_start_collector_supervisor;
    is( $child_pid, 6677, 'collector supervisor starts through the GoRoutine process path on Unix' );
    is_deeply(
        $spawned_argv,
        [ 'perl', $manager->_perl_library_args, '/tmp/collector-supervisor-foreground', 'collector-supervisor-foreground' ],
        'collector supervisor launches the private foreground helper on Unix',
    );
    is( $spawned_options->{stdout}, $files->collector_log, 'Unix supervisor output is redirected to the collector log' );
}

{
    my @events;
    my $reap_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub {
        return { watched_names => ['alpha'] };
    };
    local *Developer::Dashboard::RuntimeManager::_supervise_collectors_once = sub {
        $SIG{CHLD}->() if ref( $SIG{CHLD} ) eq 'CODE';
        die "watchdog boom\n";
    };
    local *Developer::Dashboard::RuntimeManager::_reap_any_child_processes = sub {
        $reap_calls++;
        return 0;
    };
    local *Developer::Dashboard::RuntimeManager::_write_collector_supervisor_state = sub {
        my ( undef, $state ) = @_;
        push @events, { %{$state} };
        return $state;
    };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { die "loop-finished\n" };
    my $error = eval {
        $manager->_run_collector_supervisor_child( daemonize => 0, redirect => 0 );
        return '';
    } || $@;
    like( $error, qr/loop-finished/, 'collector supervisor child loop can be broken cleanly in tests after one pass' );
    ok(
        ( scalar grep { ( $_->{status} || '' ) eq 'error' && ( $_->{error} || '' ) =~ /watchdog boom/ } @events ),
        'collector supervisor child records watchdog errors in supervisor state',
    );
    ok( $reap_calls >= 2, 'collector supervisor child reaps exited children during the loop and from the CHLD handler' );
}

{
    my $marker = File::Spec->catfile( $home, 'collector-supervisor-defaults.marker' );
    my $child_script = _runtime_fixture_script(q{
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub {
            return { watched_names => ['alpha'] };
        };
        local *Developer::Dashboard::RuntimeManager::_detach_web_process_session = sub {
            open my $fh, '>>', $ENV{DASHBOARD_SUPERVISOR_MARKER} or die $!;
            print {$fh} "detached\n";
            close $fh;
            return 1;
        };
        local *Developer::Dashboard::RuntimeManager::_supervise_collectors_once = sub { return {} };
        local *Developer::Dashboard::RuntimeManager::_shutdown_collector_supervisor = sub {
            my ( undef, $status ) = @_;
            open my $fh, '>>', $ENV{DASHBOARD_SUPERVISOR_MARKER} or die $!;
            print {$fh} "shutdown:$status\n";
            close $fh;
            exit 0;
        };
        local *Developer::Dashboard::RuntimeManager::sleep = sub {
            Developer::Dashboard::GoRoutine::terminate_process( $$, 'TERM' );
            return 0;
        };
        $manager->_run_collector_supervisor_child;
        exit 1;
    });
    my $child = _spawn_perl_fixture(
        $child_script,
        {
            env => { HOME => $home, DASHBOARD_SUPERVISOR_MARKER => $marker },
            stdout => "$home/collector-supervisor-defaults.out",
            stderr => "$home/collector-supervisor-defaults.err",
        },
    );
    # Windows has no POSIX signal handlers: GoRoutine::terminate_process maps
    # TERM to native process termination there (documented in GoRoutine.pm),
    # so the child is ended at once with the TERM exit code 143 and its
    # $SIG{TERM} shutdown closure cannot run. Assert that real contract on
    # Windows and the handler-driven clean exit everywhere else.
    my $windows = $^O eq 'MSWin32';
    if ($windows) {
        is( Developer::Dashboard::GoRoutine::wait_process($child), 143,
            'collector supervisor child default daemonize and redirect path is ended natively by TERM on Windows' );
    }
    else {
        is( Developer::Dashboard::GoRoutine::wait_process($child), 0,
            'collector supervisor child default daemonize and redirect path exits cleanly after TERM' );
    }
    open my $fh, '<', $marker or die "Unable to read $marker: $!";
    my @marker_lines = <$fh>;
    close $fh;
    ok(
        ( scalar grep { $_ eq "detached\n" } @marker_lines ),
        'collector supervisor child default path detaches the process session before entering the loop',
    );
    if ($windows) {
        ok(
            !( scalar grep { /^shutdown:/ } @marker_lines ),
            'collector supervisor child is terminated natively on Windows before any signal handler can run',
        );
    }
    else {
        ok(
            ( scalar grep { $_ eq "shutdown:stopped\n" } @marker_lines ),
            'collector supervisor child TERM handler invokes the shutdown closure through the local signal binding',
        );
    }
}

{
    my $shutdown_status = '';
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub {
        return { watched_names => [] };
    };
    local *Developer::Dashboard::RuntimeManager::_shutdown_collector_supervisor = sub {
        my ( undef, $status ) = @_;
        $shutdown_status = $status;
        die "shutdown-$status\n";
    };
    my $error = eval {
        $manager->_run_collector_supervisor_child( daemonize => 0, redirect => 0 );
        return '';
    } || $@;
    like( $error, qr/shutdown-stopped/, 'collector supervisor child exits through shutdown when no targets remain' );
    is( $shutdown_status, 'stopped', 'collector supervisor child requests a stopped shutdown when the watch list is empty' );
}

{
    # Lifetime owner: a starter that can be killed without ever running a
    # stop ties the runtime to its own pid through
    # DEVELOPER_DASHBOARD_LIFETIME_PID. Unset, malformed and self values
    # give no owner, so an ordinary runtime is never tied to anything.
    {
        local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID};
        delete $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID};
        is( scalar( $manager->_lifetime_owner_pid ), undef, 'no lifetime owner when the starter did not opt in' );
        my @in_list_context = $manager->_lifetime_owner_pid;
        is_deeply( \@in_list_context, [undef],
            'with no opt-in the owner reader returns one undef in list context, never an empty list' );
        my $owner_state = { pid => $manager->_lifetime_owner_pid, dead_polls => 0 };
        is_deeply( $owner_state, { pid => undef, dead_polls => 0 },
            'with no opt-in the owner state built the way the supervisor, loop and web watcher build it has an undef pid' );
        is( $manager->_lifetime_owner_is_gone($owner_state), 0,
            'an ordinary user with no opt-in is never judged to have a dead owner' );
        is( $manager->_lifetime_owner_is_gone($owner_state), 0,
            'and still not on a second poll in a row' );
        $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = 'abc';
        is( scalar( $manager->_lifetime_owner_pid ), undef, 'a malformed lifetime owner value is ignored' );
        $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = 0;
        is( scalar( $manager->_lifetime_owner_pid ), undef, 'a zero lifetime owner value is ignored' );
        $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = $$;
        is( scalar( $manager->_lifetime_owner_pid ), undef, 'a process is never tied to its own pid' );
        $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = 4242;
        is( scalar( $manager->_lifetime_owner_pid ), 4242, 'a numeric lifetime owner value is returned as the owner pid' );
    }

    my @stopped_loops;
    my $web_stops       = 0;
    my $shutdown_status = '';
    my $owner_running   = 1;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return $owner_running };
    my $pattern_stops = 0;
    local *Developer::Dashboard::RuntimeManager::stop_web = sub { $pattern_stops++; return };
    local *Developer::Dashboard::RuntimeManager::_stop_recorded_web_for_lifetime_owner = sub { $web_stops++; die "web stop failed\n" };
    local *Developer::Dashboard::RuntimeManager::_shutdown_collector_supervisor = sub {
        my ( undef, $status ) = @_;
        $shutdown_status = $status;
        die "shutdown-$status\n";
    };
    no warnings 'once';
    local *Local::SupervisorRunner::stop_loop = sub {
        my ( undef, $name ) = @_;
        push @stopped_loops, $name;
        die "loop stop failed\n" if $name eq 'beta';
        return 1;
    };

    my $no_owner = { pid => undef, dead_polls => 0 };
    $owner_running = 0;
    is( scalar( $manager->_check_collector_supervisor_lifetime_owner( [ 'alpha', 'beta' ], $no_owner ) ),
        undef, 'the lifetime check does nothing when no owner is set' );
    is( $no_owner->{dead_polls}, 0, 'the lifetime check counts nothing when no owner is set' );

    my $owner = { pid => 4242, dead_polls => 1 };
    $owner_running = 1;
    is( scalar( $manager->_check_collector_supervisor_lifetime_owner( [ 'alpha', 'beta' ], $owner ) ),
        undef, 'the lifetime check leaves the runtime alone while the owner is alive' );
    is( $owner->{dead_polls}, 0, 'a live owner resets the dead-poll count' );

    $owner_running = 0;
    is( scalar( $manager->_check_collector_supervisor_lifetime_owner( [ 'alpha', 'beta' ], $owner ) ),
        undef, 'one dead poll alone does not end the runtime' );
    is( $owner->{dead_polls}, 1, 'the first dead poll is counted' );
    is_deeply( \@stopped_loops, [], 'nothing is stopped on the first dead poll' );

    my $error = eval {
        $manager->_check_collector_supervisor_lifetime_owner( [ 'alpha', 'beta' ], $owner );
        return '';
    } || $@;
    like( $error, qr/shutdown-lifetime-owner-gone/, 'a second dead poll in a row shuts the supervisor down' );
    is( $shutdown_status, 'lifetime-owner-gone', 'the shutdown records that the lifetime owner is gone' );
    is_deeply( \@stopped_loops, [ 'alpha', 'beta' ], 'every watched loop is stopped, even when one stop fails' );
    is( $web_stops, 1, 'the recorded web process of this runtime is stopped once, and a failed web stop does not keep the supervisor alive' );
    is( $pattern_stops, 0, 'the machine-wide stop_web is never used when the lifetime owner dies' );
}

{
    # The path every ordinary user runs: a supervisor whose starter never
    # set DEVELOPER_DASHBOARD_LIFETIME_PID. The reader, the shared
    # dead-poll rule, the liveness probe and the supervisor's own check
    # are all real here; only the three things the check would do to the
    # runtime are recorded. When the reader ended with a bare return, the
    # owner state built this way read its pid as the text 'dead_polls',
    # the liveness probe refused it, and the second poll shut the
    # supervisor down.
    local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID};
    delete $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID};
    my @stopped_loops;
    my $web_stops = 0;
    my @shutdowns;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_stop_recorded_web_for_lifetime_owner = sub { $web_stops++; return };
    local *Developer::Dashboard::RuntimeManager::_shutdown_collector_supervisor = sub {
        my ( undef, $status ) = @_;
        push @shutdowns, $status;
        die "shutdown-$status\n";
    };
    no warnings 'once';
    local *Local::SupervisorRunner::stop_loop = sub {
        my ( undef, $name ) = @_;
        push @stopped_loops, $name;
        return 1;
    };

    # The owner state exactly as the supervisor builds it before its loop.
    my $owner = { pid => $manager->_lifetime_owner_pid, dead_polls => 0 };
    is_deeply( $owner, { pid => undef, dead_polls => 0 },
        'unset owner: the owner state the supervisor builds has no pid and no extra key' );
    my @outcomes;
    for ( 1 .. 4 ) {
        my $returned = eval { $manager->_check_collector_supervisor_lifetime_owner( [ 'alpha', 'beta' ], $owner ); 1 };
        push @outcomes, $returned ? 'returned' : "died: $@";
    }
    is_deeply( \@outcomes, [ ('returned') x 4 ],
        'unset owner: the real supervisor check returns on four polls in a row' );
    is( $owner->{dead_polls}, 0, 'unset owner: the real supervisor check never counts a dead poll' );
    is_deeply( \@stopped_loops, [], 'unset owner: the real supervisor check never stops a watched loop' );
    is( $web_stops, 0, 'unset owner: the real supervisor check never stops the web process' );
    is_deeply( \@shutdowns, [], 'unset owner: the real supervisor check never shuts the supervisor down' );

    # The supervisor's own loop, four passes, so the line that builds the
    # owner state inside _run_collector_supervisor_child is the one that
    # runs. The quiesce period is left at its default, far beyond four
    # instant passes.
    my $sleeps = 0;
    my @states;
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub {
        return { watched_names => [ 'alpha', 'beta' ] };
    };
    local *Developer::Dashboard::RuntimeManager::_supervise_collectors_once = sub { return {} };
    local *Developer::Dashboard::RuntimeManager::_reap_any_child_processes = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_write_collector_supervisor_state = sub {
        my ( undef, $state ) = @_;
        push @states, { %{$state} };
        return $state;
    };
    local *Developer::Dashboard::RuntimeManager::web_state = sub { return };
    local *Developer::Dashboard::RuntimeManager::sleep = sub {
        $sleeps++;
        die "loop-finished\n" if $sleeps >= 4;
        return 0;
    };
    my $error = eval {
        $manager->_run_collector_supervisor_child( daemonize => 0, redirect => 0 );
        return '';
    } || $@;
    like( $error, qr/\Aloop-finished/,
        'unset owner: the supervisor loop is still running after four passes and is only ended by the test' );
    is( $sleeps, 4, 'unset owner: the supervisor loop reached its sleep on all four passes' );
    is_deeply( \@shutdowns, [], 'unset owner: the supervisor loop never shuts itself down' );
    is_deeply( \@stopped_loops, [], 'unset owner: the supervisor loop never stops a watched loop' );
    is( $web_stops, 0, 'unset owner: the supervisor loop never stops the web process' );
    is( scalar( grep { ( $_->{status} || '' ) eq 'running' } @states ), 4,
        'unset owner: the supervisor loop records itself running on each of the four passes' );
}

{
    # The targeted web stop used when the lifetime owner dies: only the pid
    # this runtime recorded, only while it still proves to be a managed
    # dashboard web process, TERM first and KILL only if it stays.
    my $recorded;
    my $running = 1;
    my $managed = 1;
    my @signals;
    my $files_class = ref $manager->{files};
    no strict 'refs';
    no warnings 'redefine';
    local *{ $files_class . '::read' } = sub { return $recorded };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return $running };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return $managed };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub {
        my ( undef, $signal, @pids ) = @_;
        push @signals, join ' ', $signal, @pids;
        $running = 0 if $signal eq 'TERM' && $recorded eq "5151\n";
        return scalar @pids;
    };
    use strict 'refs';

    is( scalar( $manager->_stop_recorded_web_for_lifetime_owner ), undef, 'no recorded web pid means nothing is stopped' );
    $recorded = "junk\n";
    is( scalar( $manager->_stop_recorded_web_for_lifetime_owner ), undef, 'a malformed recorded web pid is ignored' );
    $recorded = "4343\n";
    $running  = 0;
    is( scalar( $manager->_stop_recorded_web_for_lifetime_owner ), undef, 'a recorded web pid that is no longer running is left alone' );
    $running = 1;
    $managed = 0;
    is( scalar( $manager->_stop_recorded_web_for_lifetime_owner ), undef, 'a recorded pid that is not a managed web process is left alone' );
    is_deeply( \@signals, [], 'nothing has been signalled so far' );

    $managed  = 1;
    $recorded = "5151\n";
    is( scalar( $manager->_stop_recorded_web_for_lifetime_owner ), 5151, 'a managed web process that ends on TERM is reported stopped' );
    is_deeply( \@signals, ['TERM 5151'], 'a web process that ends on TERM is not sent KILL' );

    @signals  = ();
    $running  = 1;
    $recorded = "6262\n";
    is( scalar( $manager->_stop_recorded_web_for_lifetime_owner ), 6262, 'a managed web process that ignores TERM is still reported stopped' );
    is_deeply( \@signals, [ 'TERM 6262', 'KILL 6262' ], 'a web process that ignores TERM is sent KILL after the wait' );
}

{
    my $child_script = _runtime_fixture_script(q{
        $manager->_write_collector_supervisor_state(
            {
                watched_names => ['alpha'],
            }
        );
        open my $fh, '>', $manager->_collector_supervisor_pidfile or die $!;
        print {$fh} "$$\n";
        close $fh;
        $manager->_shutdown_collector_supervisor('stopped');
    });
    my $child = _spawn_perl_fixture(
        $child_script,
        {
            env => { HOME => $home },
            stdout => "$home/collector-supervisor-shutdown.out",
            stderr => "$home/collector-supervisor-shutdown.err",
        },
    );
    is( Developer::Dashboard::GoRoutine::wait_process($child), 0,
        'collector supervisor shutdown exits cleanly through GoRoutine' );
    ok( !-f $manager->_collector_supervisor_pidfile, 'collector supervisor shutdown removes the pidfile' );
    ok( !-f $manager->_collector_supervisor_statefile, 'collector supervisor shutdown removes the statefile' );
}

{
    my $child = _spawn_perl_fixture(q{$SIG{TERM} = sub { exit 0 }; while (1) { select undef, undef, undef, 0.1 }},
        { env => { HOME => $home }, stdout => "$home/collector-supervisor-stop.out", stderr => "$home/collector-supervisor-stop.err" });
    sleep 0.2;
    open my $fh, '>', $manager->_collector_supervisor_pidfile or die $!;
    print {$fh} "$child\n";
    close $fh;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_is_collector_supervisor = sub {
        my ( undef, $pid ) = @_;
        return $pid == $child ? 1 : 0;
    };
    is( $manager->_stop_collector_supervisor, $child, 'collector supervisor stop returns the managed child pid' );
    ok( !Developer::Dashboard::GoRoutine::process_running($child),
        'collector supervisor stop reaps the GoRoutine-spawned child instead of leaving it running' );
    ok( !-f $manager->_collector_supervisor_pidfile, 'collector supervisor stop removes the pidfile after shutdown' );
}

{
    my $child = _spawn_perl_fixture('exit 0;',
        { env => { HOME => $home }, stdout => "$home/collector-supervisor-reap.out", stderr => "$home/collector-supervisor-reap.err" });
    my $reaped = 0;
    for ( 1 .. 20 ) {
        $reaped = $manager->_reap_any_child_processes;
        last if $reaped;
        select undef, undef, undef, 0.05;
    }
    is( $reaped, 1, 'collector supervisor reap helper reaps one exited direct child' );
    ok( !Developer::Dashboard::GoRoutine::process_running($child),
        'collector supervisor reap helper leaves no GoRoutine child running after reaping it' );
}

{
    # The pid stop the watcher uses: only a pid that still proves to be
    # a managed dashboard web process is signalled, so a reused pid
    # belonging to an unrelated program is left alone. Mocked: no real
    # process is probed or signalled.
    my $running = 1;
    my $managed = 1;
    my @signals;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return $running };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return $managed };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub {
        my ( undef, $signal, @pids ) = @_;
        push @signals, join ' ', $signal, @pids;
        $running = 0 if $signal eq 'TERM' && $pids[0] == 5151;
        return scalar @pids;
    };

    $running = 0;
    is( scalar( $manager->_stop_web_pid_for_lifetime_owner(4343) ), undef, 'a web pid that is no longer running is left alone' );
    $running = 1;
    $managed = 0;
    is( scalar( $manager->_stop_web_pid_for_lifetime_owner(4343) ), undef, 'a pid that is not a managed web process is left alone' );
    is_deeply( \@signals, [], 'nothing has been signalled so far' );

    $managed = 1;
    is( scalar( $manager->_stop_web_pid_for_lifetime_owner(5151) ), 5151, 'a managed web process that ends on TERM is reported stopped' );
    is_deeply( \@signals, ['TERM 5151'], 'a web process that ends on TERM is not sent KILL' );

    @signals = ();
    $running = 1;
    is( scalar( $manager->_stop_web_pid_for_lifetime_owner(6262) ), 6262, 'a managed web process that ignores TERM is still reported stopped' );
    is_deeply( \@signals, [ 'TERM 6262', 'KILL 6262' ], 'a web process that ignores TERM is sent KILL after the wait' );
}

{
    # The watcher a web process starts for itself when its starter opted
    # in to a lifetime owner. Called on the class, as the watcher process
    # calls it. Mocked: no real process is probed or signalled.
    my $class = 'Developer::Dashboard::RuntimeManager';
    my %alive;
    my @probed;
    my @stopped;
    my @stop_proofs;
    my $stop_dies = 1;
    my $stop_mode = 'stop';
    my $confirm_pauses = 0;
    my $real_confirm_looks = \&Developer::Dashboard::RuntimeManager::_web_stop_confirm_looks;
    my $real_confirm_pause = \&Developer::Dashboard::RuntimeManager::_web_stop_confirm_pause_seconds;
    my $watcher_log = File::Spec->catfile( $home, 'web-lifetime-owner-watcher.log' );
    my $read_watcher_log = sub {
        open my $fh, '<', $watcher_log or return '';
        local $/;
        my $text = <$fh>;
        return defined $text ? $text : '';
    };
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_web_watcher_spares_itself   = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_lifetime_owner_poll_seconds = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_web_stop_confirm_pause_seconds = sub {
        $confirm_pauses++;
        return 0;
    };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub {
        my ( undef, $pid ) = @_;
        push @probed, $pid;
        my $answers = $alive{$pid} || [];
        return @{$answers} > 1 ? shift @{$answers} : $answers->[0];
    };
    local *Developer::Dashboard::RuntimeManager::_stop_web_pid_for_lifetime_owner = sub {
        my ( undef, $pid, @proof ) = @_;
        push @stopped, $pid;
        push @stop_proofs, [@proof];
        die "web stop failed\n" if $stop_dies;
        return if $stop_mode eq 'refuse';
        if ( $stop_mode eq 'refuse-web-gone' ) {
            $alive{$pid} = [0];
            return;
        }
        $alive{$pid} = [0] if $stop_mode eq 'stop';
        $alive{$pid} = [ 1, 1, 0 ] if $stop_mode eq 'signal-then-gone';
        return $pid;
    };

    local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = 4242;
    is( $class->_run_web_lifetime_owner_watcher(undef), 0, 'the web owner watcher ends at once with no web pid' );
    is( $class->_run_web_lifetime_owner_watcher('junk'), 0, 'the web owner watcher ends at once with a malformed web pid' );
    is( $class->_run_web_lifetime_owner_watcher($$), 0, 'the web owner watcher never watches its own pid as the web process' );
    is( $class->_run_web_lifetime_owner_watcher(4242), 0, 'a web process is never tied to itself as owner' );
    {
        local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID};
        delete $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID};
        is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0, 'the web owner watcher ends at once when the starter did not opt in' );
        ok( !-e $watcher_log, 'no stop line is written when the starter did not opt in' );
    }
    is_deeply( \@probed, [], 'nothing is probed in any of the cases with nothing to watch' );

    # The web process ends first: the watcher just ends.
    %alive = ( 5151 => [ 1, 1, 0 ], 4242 => [1] );
    is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0, 'the web owner watcher ends once the web process is gone' );
    is_deeply( \@stopped, [], 'nothing is stopped when the web process ends by itself' );
    like( $read_watcher_log->(), qr/\A\S+ watcher pid \Q$$\E is watching web pid 5151 for lifetime owner pid 4242\n\z/,
        'a watcher with something to watch says so first, and writes nothing more when the web process ends by itself' );
    unlink $watcher_log;

    # The owner dies: one dead poll is not enough, the second stops the web.
    @probed = ();
    %alive  = ( 5151 => [1], 4242 => [ 1, 0, 1, 0, 0 ] );
    is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0,
        'the web owner watcher ends after stopping the web process, even when that stop fails' );
    is_deeply( \@stopped, [5151], 'only the one web process the watcher was started for is stopped, once' );
    is_deeply( \@stop_proofs, [ [] ],
        'the watcher asks for the stop with the web pid alone and changes nothing about the managed-web proof' );
    is_deeply(
        \@probed,
        [ 5151, 4242, 5151, 4242, 5151, 4242, 5151, 4242, 5151, 4242 ],
        'a single dead poll of the owner is forgiven; two in a row stop the web process, each time straight after seeing it alive',
    );
    like(
        $read_watcher_log->(),
        qr/ web not stopped: lifetime owner gone; lifetime owner pid 4242 is gone; the stop attempt on web pid 5151 died: web stop failed\n\z/,
        'a stop attempt that dies is not silent: the watcher log says it died, names both pids and carries the error',
    );
    unlike( $read_watcher_log->(), qr/web stopped:/, 'no stop line is written when the stop itself fails' );
    unlink $watcher_log;

    # The owner dies and the stop succeeds: the watcher writes one line
    # naming both pids, so a later reader has positive evidence.
    $stop_dies = 0;
    @probed  = ();
    @stopped = ();
    %alive   = ( 5151 => [1], 4242 => [ 1, 0, 1, 0, 0 ] );
    is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0,
        'the web owner watcher ends after stopping the web process when its owner is gone' );
    is_deeply( \@stopped, [5151], 'the web process is stopped once when its owner is gone' );
    ok( -f $watcher_log, 'the watcher writes its stop line when it stops the web process' );
    my $watcher_log_text;
    {
        open my $fh, '<', $watcher_log or die "cannot read $watcher_log: $!";
        local $/;
        $watcher_log_text = <$fh>;
    }
    like( $watcher_log_text, qr/web stopped: lifetime owner gone/, 'the stop line says why the web process was stopped' );
    like( $watcher_log_text, qr/lifetime owner pid 4242 is gone/, 'the stop line names the dead owner pid' );
    like( $watcher_log_text, qr/web pid 5151 is stopping/, 'the stop line names the stopped web pid' );
    is( scalar( () = $watcher_log_text =~ /\n/g ), 2, 'a stop that is confirmed writes the watching line, the stop line and nothing else' );
    is( $confirm_pauses, 0, 'a web process that is gone at the first look after the stop is not waited for' );

    # The stop signalled the web process, and it is still there after
    # every look of the bounded wait: only then is the stop reported as
    # not confirmed. The pause between looks is stood in for, so nothing
    # here really waits.
    unlink $watcher_log;
    $stop_mode      = 'signal-only';
    $confirm_pauses = 0;
    @probed         = ();
    %alive          = ( 5151 => [1], 4242 => [0] );
    is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0,
        'the web owner watcher ends after a stop that left the web process running' );
    like( $read_watcher_log->(), qr/ web stopped: lifetime owner gone; lifetime owner pid 4242 is gone; web pid 5151 is stopping\n/,
        'a stop that signalled the web process still writes the stop line' );
    like(
        $read_watcher_log->(),
        qr/ web stop not confirmed: lifetime owner gone; lifetime owner pid 4242 is gone; web pid 5151 was signalled and is still running\n\z/,
        'a signalled web process that is still running after the whole wait is reported on a second line',
    );
    is_deeply(
        \@probed,
        [ 5151, 4242, 5151, 4242, (5151) x 10 ],
        'the wait is bounded: the signalled web pid is looked at ten times after the stop and no more',
    );
    is( $confirm_pauses, 9, 'the wait pauses between looks only, nine times for ten looks' );

    # The stop signalled the web process and it was still to be seen for
    # an instant, then gone: that is a confirmed stop, and the line that
    # would have been false is never written.
    unlink $watcher_log;
    $stop_mode      = 'signal-then-gone';
    $confirm_pauses = 0;
    @probed         = ();
    %alive          = ( 5151 => [1], 4242 => [0] );
    is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0,
        'the web owner watcher ends after a stop the web process took a moment to obey' );
    like( $read_watcher_log->(), qr/ web stopped: lifetime owner gone; lifetime owner pid 4242 is gone; web pid 5151 is stopping\n\z/,
        'a web process that goes within the wait leaves the stop line as the last line' );
    unlike( $read_watcher_log->(), qr/web stop not confirmed:/,
        'a web process that goes within the wait is never reported as still running' );
    is_deeply(
        \@probed,
        [ 5151, 4242, 5151, 4242, 5151, 5151, 5151 ],
        'the wait ends at the first look that finds the web process gone',
    );
    is( $confirm_pauses, 2, 'the wait pauses only until the web process is gone' );

    # The real bounds of that wait: ten looks, a fifth of a second apart,
    # so about two seconds in all and never longer.
    is( $real_confirm_looks->($class), 10, 'the real wait looks at the signalled web pid ten times at most' );
    is( $real_confirm_pause->($class), 0.2, 'the real wait pauses a fifth of a second between looks' );

    # The stop refused: the pid is running but is not recognised as a
    # managed dashboard web process, so it was left alone.
    unlink $watcher_log;
    $stop_mode = 'refuse';
    %alive     = ( 5151 => [1], 4242 => [0] );
    is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0,
        'the web owner watcher ends after a stop that refused the web pid' );
    like(
        $read_watcher_log->(),
        qr/ web not stopped: lifetime owner gone; lifetime owner pid 4242 is gone; web pid 5151 is not recognised as a managed dashboard web process and is left alone\n\z/,
        'a web pid that is left alone is not silent: the watcher log says it was not recognised',
    );
    unlike( $read_watcher_log->(), qr/web stopped:/, 'no stop line is written for a web pid that was left alone' );

    # The web process ended by itself between the poll and the stop:
    # nothing was stopped and nothing needs saying.
    unlink $watcher_log;
    $stop_mode = 'refuse-web-gone';
    %alive     = ( 5151 => [1], 4242 => [0] );
    is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0,
        'the web owner watcher ends when the web process went away just before the stop' );
    unlike( $read_watcher_log->(), qr/web stopped:|web not stopped:|web stop not confirmed:/,
        'no stop line of any kind is written when the web process ended by itself before the stop' );
    unlink $watcher_log;

    # The watcher cannot build its object: it says at once, in plain
    # words, that it CANNOT stop the web process in that state, and it
    # carries on with the class name only so the stop attempt that then
    # dies (as the real one does without an object) is logged as well.
    {
        local *Developer::Dashboard::RuntimeManager::_web_lifetime_owner_watcher_object = sub { die "no home directory\n" };
        $stop_mode = 'stop';
        $stop_dies = 1;
        @stopped   = ();
        %alive     = ( 5151 => [1], 4242 => [0] );
        is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0,
            'the web owner watcher still ends normally when it could not build its object' );
        is_deeply( \@stopped, [5151], 'a watcher without its object still makes the stop attempt, so its failure is logged' );
        like(
            $read_watcher_log->(),
            qr/\A\S+ watcher for web pid 5151 could not build its runtime object: it CANNOT stop web pid 5151 when the lifetime owner goes, and carries on only to say so in this log: no home directory\n/,
            'a watcher that could not build its object says plainly that it cannot stop the web process',
        );
        like(
            $read_watcher_log->(),
            qr/ web not stopped: lifetime owner gone; lifetime owner pid 4242 is gone; the stop attempt on web pid 5151 died: web stop failed\n\z/,
            'the stop attempt that dies without the object is logged after it',
        );
        unlike( $read_watcher_log->(), qr/web stopped:/, 'a watcher without its object never claims a stop' );
        unlike( $read_watcher_log->(), qr/is watching/,
            'a watcher that could not build its object does not write the watching line' );
        $stop_dies = 0;
    }

    # A builder that returns no object at all is treated the same way.
    {
        local *Developer::Dashboard::RuntimeManager::_web_lifetime_owner_watcher_object = sub { return };
        unlink $watcher_log;
        $stop_dies = 1;
        %alive     = ( 5151 => [1], 4242 => [0] );
        is( $class->_run_web_lifetime_owner_watcher(5151, $watcher_log), 0,
            'the web owner watcher still ends normally when its builder returned no object' );
        like(
            $read_watcher_log->(),
            qr/\A\S+ watcher for web pid 5151 could not build its runtime object: it CANNOT stop web pid 5151 when the lifetime owner goes, and carries on only to say so in this log: no object was returned\n/,
            'a builder that returned no object is reported with that reason',
        );
        unlike( $read_watcher_log->(), qr/is watching/,
            'a watcher whose builder returned no object does not write the watching line either' );
        $stop_dies = 0;
    }
    unlink $watcher_log;

    # The log helper itself: no path, no text, or an unwritable path is
    # never an error, and white space in the text is folded to one line.
    is( scalar( $manager->_log_web_lifetime_owner_event( undef, 'text' ) ), undef, 'no line is written without a log path' );
    is( scalar( $manager->_log_web_lifetime_owner_event( $watcher_log, '' ) ), undef, 'no line is written without text' );
    is(
        scalar( $manager->_log_web_lifetime_owner_event( File::Spec->catfile( $home, 'no-such-dir', 'watcher.log' ), 'text' ) ),
        undef,
        'a log file that cannot be opened is not an error',
    );
    is( $manager->_log_web_lifetime_owner_event( $watcher_log, "first\n  second\n" ), 1, 'a written line is reported' );
    like( $read_watcher_log->(), qr/\A\S+ first second\n\z/, 'the text is written as one time-stamped line' );
    unlink $watcher_log;
}

{
    # The watcher's own route, end to end, the way the watcher process
    # runs it: called on the class name, with the real stop and the REAL
    # managed-web proof behind it, on a host where the process
    # environment cannot be read (procfs pointed at a directory that does
    # not exist, which is how macOS and Windows always are). There the
    # proof has to go on to the persisted web state, which needs a real
    # object with a file registry. Called on a bare class name that read
    # dies, the stop never happens and, before the watcher logged its
    # failures, nothing said so. Only the outermost system facts are
    # stood in for: which pids are alive, what the socket table and the
    # process title say, and the signal itself. The web pid is a real
    # live child, because the proof starts with a real signal-0 probe;
    # it holds no harness pipe and ends by itself after two minutes, so
    # a test that dies part way leaves nothing behind.
    my $class = 'Developer::Dashboard::RuntimeManager';
    my $null    = File::Spec->devnull;
    my $web_pid = _spawn_perl_fixture(
        q{for ( 1 .. 1200 ) { select undef, undef, undef, 0.1 }},
        { stdin => $null, stdout => $null, stderr => $null },
    );
    my $owner_pid   = 4242;
    my $port        = 45991;
    my $watcher_log = File::Spec->catfile( $home, 'web-lifetime-owner-watcher-real-route.log' );
    my $read_watcher_log = sub {
        open my $fh, '<', $watcher_log or return '';
        local $/;
        my $text = <$fh>;
        return defined $text ? $text : '';
    };
    my $web_alive = 1;
    my @signals;
    my @listener_ports;
    my @titles_read;
    my $title;
    my @listeners;
    my @objects;
    my $no_procfs = File::Spec->catdir( $home, 'no-procfs-here' );
    no warnings 'redefine';
    local $Developer::Dashboard::ProcessSupervision::PROCFS_ROOT = $no_procfs;
    local $Developer::Dashboard::RuntimeManager::PROCFS_ROOT     = $no_procfs;
    local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = $owner_pid;
    local *Developer::Dashboard::RuntimeManager::_lifetime_owner_poll_seconds = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval       = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_web_watcher_spares_itself   = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub {
        my ( $self, $pid ) = @_;
        push @objects, ref($self) || 'class name';
        return $pid == $web_pid ? $web_alive : 0;
    };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub {
        my ( undef, $asked ) = @_;
        push @listener_ports, $asked;
        return @listeners;
    };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub {
        my ( undef, $pid ) = @_;
        push @titles_read, $pid;
        return $title;
    };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub {
        my ( undef, $signal, @pids ) = @_;
        push @signals, join ' ', $signal, @pids;
        $web_alive = 0;
        return scalar @pids;
    };
    my $stop_line = qr/ web stopped: lifetime owner gone; lifetime owner pid \Q$owner_pid\E is gone; web pid \Q$web_pid\E is stopping\n\z/;
    my $before_stop = qr/\A\S+ watcher pid \Q$$\E is watching web pid \Q$web_pid\E for lifetime owner pid \Q$owner_pid\E\n\S+/;

    ok( $web_pid && $web_pid != $$ && kill( 0, $web_pid ), 'real route: the stand-in web process is a real live pid' );
    is( scalar( $class->_read_process_env_marker( $web_pid, 'DEVELOPER_DASHBOARD_WEB_SERVICE' ) ), undef,
        'real route: the process environment cannot be read, as on a host with no procfs' );

    # A background web: the persisted state names the pid and its port,
    # and the socket table confirms that pid is listening there.
    $manager->_cleanup_web_files;
    $manager->_write_web_state( { host => '127.0.0.1', pid => $web_pid + 0, port => $port, status => 'running', workers => 1 } );
    @listeners = ( $web_pid );
    $title     = undef;
    is( $class->_run_web_lifetime_owner_watcher( $web_pid, $watcher_log ), 0,
        'real route: the watcher called on the class name ends normally for a background web' );
    is_deeply( \@signals, ["TERM $web_pid"],
        'real route: with no procfs the background web is proved through the persisted state and stopped with TERM' );
    is_deeply( \@listener_ports, [$port], 'real route: the socket table was asked about the port the persisted state names' );
    is_deeply( \@titles_read, [], 'real route: the process title is not needed once the persisted state proves the web' );
    like( $read_watcher_log->(), qr/$before_stop$stop_line/,
        'real route: the watching line and the stop line are the only lines, and the stop line names the owner pid and the web pid' );
    is_deeply( [ grep { $_ ne $class } @objects ], [],
        'real route: every liveness probe ran on a real runtime manager object, never on the class name' );

    # A foreground web: no persisted state names it, so the proof falls
    # through to the process title.
    unlink $watcher_log;
    $manager->_cleanup_web_files;
    ( $web_alive, @signals ) = (1);
    @listener_ports = ();
    @listeners      = ();
    $title          = "d2 web: 127.0.0.1:$port";
    is( $class->_run_web_lifetime_owner_watcher( $web_pid, $watcher_log ), 0,
        'real route: the watcher ends normally for a web with no persisted state' );
    is_deeply( \@signals, ["TERM $web_pid"], 'real route: a web with no persisted state is proved by its process title and stopped' );
    is_deeply( \@titles_read, [$web_pid], 'real route: the process title of the web pid was read' );
    like( $read_watcher_log->(), qr/$before_stop$stop_line/, 'real route: the stop line is written for the web proved by its title' );

    # Nothing proves the pid is a dashboard web: it is left alone, and
    # the watcher says so.
    unlink $watcher_log;
    ( $web_alive, @signals ) = (1);
    $title = 'starman master --listen 127.0.0.1:1';
    is( $class->_run_web_lifetime_owner_watcher( $web_pid, $watcher_log ), 0,
        'real route: the watcher ends normally when nothing proves the pid is a dashboard web' );
    is_deeply( \@signals, [], 'real route: a pid nothing proves to be a dashboard web is never signalled' );
    like(
        $read_watcher_log->(),
        qr/$before_stop web not stopped: lifetime owner gone; lifetime owner pid \Q$owner_pid\E is gone; web pid \Q$web_pid\E is not recognised as a managed dashboard web process and is left alone\n\z/,
        'real route: the watcher log says the pid was not recognised and left alone',
    );

    # Linux with procfs present: the environment marker of a live web is
    # not there to be read (Jenkins run-tests #46, amd64 and the Pi: the
    # environment block of the web pid reads blank). The watcher's proof
    # is the ordinary one, unchanged: it reads the marker, gets nothing,
    # and goes on to the persisted state, which only a real object can
    # read. Here procfs is back at its real root and the marker reader
    # is counted.
    {
        my $real_procfs  = '/proc';
        my $marker_reads = 0;
        my $marker_value;
        local $Developer::Dashboard::ProcessSupervision::PROCFS_ROOT = $real_procfs;
        local $Developer::Dashboard::RuntimeManager::PROCFS_ROOT     = $real_procfs;
        local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub {
            $marker_reads++;
            return $marker_value;
        };
        unlink $watcher_log;
        $manager->_cleanup_web_files;
        $manager->_write_web_state( { host => '127.0.0.1', pid => $web_pid + 0, port => $port, status => 'running', workers => 1 } );
        ( $web_alive, @signals ) = (1);
        @listener_ports = ();
        @titles_read    = ();
        @listeners      = ($web_pid);
        $title          = 'starman master';
        is( $class->_run_web_lifetime_owner_watcher( $web_pid, $watcher_log ), 0,
            'real route: the watcher ends normally for a web whose environment marker is not readable although procfs is there' );
        is_deeply( \@signals, ["TERM $web_pid"],
            'real route: a web with no readable marker and a Starman master title is still proved through the persisted state and stopped' );
        like( $read_watcher_log->(), qr/$before_stop$stop_line/,
            'real route: the stop line is written for the web whose marker is not readable' );
        is( $marker_reads, 1, 'real route: the watcher uses the ordinary proof, which reads the marker once before the persisted state' );
        is_deeply( \@titles_read, [], 'real route: the Starman master title is never needed once the persisted state proves the web' );

        # The same proof asked directly, as every other caller asks it.
        $web_alive = 1;
        ok( $manager->_is_managed_web($web_pid), 'the managed-web proof succeeds through the persisted state when the marker is absent' );
        is( $marker_reads, 2, 'the managed-web proof reads the marker once each time it is asked' );
        $manager->_cleanup_web_files;
        $marker_value = '1';
        ok( $manager->_is_managed_web($web_pid), 'the managed-web proof still accepts the marker where it can be read' );
    }

    unlink $watcher_log;
    $manager->_cleanup_web_files;
    Developer::Dashboard::GoRoutine::terminate_process( $web_pid, 'KILL' );
    Developer::Dashboard::GoRoutine::wait_process($web_pid);
}

{
    # The watcher's object must look in the same state folder as the web
    # process that started it, or it would look for web.json where its
    # own web never wrote it. The web's own process is the private
    # helper share/private-cli/_dashboard-core, which builds its path
    # registry with the existing projects, src and work folders under
    # the home directory as workspace and project roots. Here the same
    # registry is built by hand, the way that helper builds it, and
    # compared with the watcher's, from inside a project that has its
    # own runtime layer, so the state folder is the project's and not
    # the home one. The helper's own source is read as well, so the
    # comparison fails if the helper ever builds its registry another
    # way without the watcher following.
    my $class = 'Developer::Dashboard::RuntimeManager';
    make_path( File::Spec->catdir( $home, 'projects' ), File::Spec->catdir( $home, 'src' ) );
    my $project = File::Spec->catdir( $home, 'projects', 'watcher-paths-demo' );
    make_path( File::Spec->catdir( $project, '.git' ), File::Spec->catdir( $project, '.developer-dashboard' ) );
    my $before_cwd = getcwd();
    chdir $project or die "Unable to chdir to $project: $!";
    local $ENV{PWD} = $project;

    my @helper_roots = grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work);
    my $web_paths    = Developer::Dashboard::PathRegistry->new(
        workspace_roots => [@helper_roots],
        project_roots   => [@helper_roots],
    );
    my $web_files = Developer::Dashboard::FileRegistry->new( paths => $web_paths );
    my $watcher   = $class->_web_lifetime_owner_watcher_object;
    my $home_only = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

    isa_ok( $watcher, $class, 'watcher paths: the watcher builds a real runtime manager object' );
    is( scalar(@helper_roots), 2, 'watcher paths: the fixture has project folders set (projects and src exist, work does not)' );
    is_deeply( [ $watcher->{paths}->workspace_roots ], [ $web_paths->workspace_roots ],
        'watcher paths: the watcher has the same workspace roots as the web process' );
    is_deeply( [ $watcher->{paths}->project_roots ], [ $web_paths->project_roots ],
        'watcher paths: the watcher has the same project roots as the web process' );
    is( $watcher->{paths}->home, $web_paths->home, 'watcher paths: the watcher resolves the same home directory as the web process' );
    is( $watcher->{paths}->runtime_root, $web_paths->runtime_root, 'watcher paths: the watcher resolves the same runtime root as the web process' );
    is( $watcher->{paths}->state_root, $web_paths->state_root, 'watcher paths: the watcher resolves the same state folder as the web process' );
    isnt( $web_paths->state_root, $home_only->state_root,
        'watcher paths: inside the project the state folder is the project one, so the comparison is not the home default' );
    is( $watcher->{files}->web_state, $web_files->web_state, 'watcher paths: the watcher reads the same web.json as the web process' );
    is( $watcher->{files}->web_pid, $web_files->web_pid, 'watcher paths: the watcher reads the same web.pid as the web process' );
    is( $watcher->{files}->resolve_file('web_pid'), $web_files->resolve_file('web_pid'),
        'watcher paths: the recorded web pid file resolves to the same path by name' );
    is( $watcher->{files}->collector_log, $web_files->collector_log, 'watcher paths: the watcher resolves the same collector log as the web process' );
    is( $class->_web_lifetime_owner_watcher_object->{paths}->state_root, $watcher->{paths}->state_root,
        'watcher paths: a second watcher object resolves the same state folder again' );
    is( $watcher->_web_lifetime_owner_watcher_object, $watcher, 'watcher paths: an object invocant is returned as it is' );
    like( ( eval { $watcher->{app_builder}->(); 1 } ? '' : $@ ), qr/never serves/, 'watcher paths: the watcher object refuses to build a web application' );

    # With no home variable of any kind the registry cannot be built,
    # and the roots are simply empty first: no warning, no half-built path.
    {
        local $ENV{HOME};
        local $ENV{USERPROFILE};
        local $ENV{HOMEDRIVE};
        local $ENV{HOMEPATH};
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $built = eval { $class->_web_lifetime_owner_watcher_paths; 1 };
        ok( !$built, 'watcher paths: with no home directory the path registry is refused, as the web process itself is' );
        is_deeply( \@warnings, [], 'watcher paths: a missing home directory raises no warning on the way' );
    }

    # The helper's own source, so a change there cannot pass unnoticed.
    my $helper_file = File::Spec->catfile( $original_cwd, 'share', 'private-cli', '_dashboard-core' );
    my $helper_text = do {
        open my $fh, '<', $helper_file or die "Unable to read $helper_file: $!";
        local $/;
        <$fh>;
    };
    my $roots_line = quotemeta q{[ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],};
    like(
        $helper_text,
        qr/my \$paths = Developer::Dashboard::PathRegistry->new\(\s+workspace_roots => $roots_line\s+project_roots   => $roots_line\s+\);/,
        'watcher paths: the web helper still builds its path registry with exactly the roots the watcher mirrors',
    );

    chdir $before_cwd or die "Unable to chdir back to $before_cwd: $!";
}

{
    # The supervisor's own web stop when its lifetime owner is gone is
    # not silent either: what it did goes to the global collector log,
    # the one log a supervisor always has. Mocked: nothing is read from
    # disk for the recorded pid, nothing is probed or signalled, and the
    # shutdown is replaced by a die so the test process carries on.
    my $recorded;
    my $stop_result;
    my $stop_error;
    my $recorded_running = 0;
    my $shutdowns        = 0;
    my $collector_log    = $manager->{files}->collector_log;
    my $real_recorded_reader = \&Developer::Dashboard::RuntimeManager::_recorded_web_pid_for_lifetime_owner;
    my $read_collector_log = sub {
        open my $fh, '<', $collector_log or return '';
        local $/;
        my $text = <$fh>;
        return defined $text ? $text : '';
    };
    my $run_check = sub {
        unlink $collector_log;
        my $error = eval {
            $manager->_check_collector_supervisor_lifetime_owner( [], { pid => 4242, dead_polls => 1 } );
            return '';
        } || $@;
        return $error;
    };
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_lifetime_owner_is_gone              = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_recorded_web_pid_for_lifetime_owner = sub { return $recorded };
    local *Developer::Dashboard::RuntimeManager::_stop_recorded_web_for_lifetime_owner = sub {
        die $stop_error if defined $stop_error;
        return $stop_result;
    };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return $recorded_running };
    local *Developer::Dashboard::RuntimeManager::_shutdown_collector_supervisor = sub {
        my ( undef, $status ) = @_;
        $shutdowns++;
        die "shutdown-$status\n";
    };
    my $prefix   = qr/\[supervisor\]\[lifetime-owner\]/;
    my $gone     = qr/lifetime owner gone; lifetime owner pid 4242 is gone;/;

    # The recorded web is stopped: a positive line naming owner and web.
    ( $recorded, $stop_result ) = ( 5151, 5151 );
    like( $run_check->(), qr/shutdown-lifetime-owner-gone/, 'the supervisor shuts down after stopping its recorded web' );
    like( $read_collector_log->(), qr/\A\[[^\]]+\]$prefix web stopped: $gone web pid 5151 is stopping\n\z/,
        'a supervisor that stopped its recorded web says so in the collector log on one line, naming the owner pid and the web pid' );

    # The stop died: the line says so and carries the error.
    ( $stop_result, $stop_error ) = ( undef, "web state unreadable\nsecond line\n" );
    like( $run_check->(), qr/shutdown-lifetime-owner-gone/, 'a web stop that dies does not keep the supervisor alive' );
    like(
        $read_collector_log->(),
        qr/\A\[[^\]]+\]$prefix web not stopped: $gone the stop attempt on recorded web pid 5151 died: web state unreadable second line\n\z/,
        'a web stop that dies is not silent: the collector log says it died and carries the error on one line',
    );
    unlike( $read_collector_log->(), qr/web stopped:/, 'no stop line is written when the supervisor web stop died' );

    # The recorded pid could not even be read: the die is still told.
    {
        local *Developer::Dashboard::RuntimeManager::_recorded_web_pid_for_lifetime_owner = sub { die "pid file unreadable\n" };
        like( $run_check->(), qr/shutdown-lifetime-owner-gone/, 'a recorded web pid that cannot be read does not keep the supervisor alive' );
        like(
            $read_collector_log->(),
            qr/\A\[[^\]]+\]$prefix web not stopped: $gone the stop attempt on the recorded web process died: pid file unreadable\n\z/,
            'a recorded web pid that cannot be read is reported with its error',
        );
    }

    # The recorded pid is running but was not recognised: left alone, and said.
    ( $stop_error, $recorded_running ) = ( undef, 1 );
    like( $run_check->(), qr/shutdown-lifetime-owner-gone/, 'a recorded web that is left alone does not keep the supervisor alive' );
    like(
        $read_collector_log->(),
        qr/\A\[[^\]]+\]$prefix web not stopped: $gone recorded web pid 5151 is not recognised as a managed dashboard web process and is left alone\n\z/,
        'a recorded web pid that is running but not recognised is not silent: the collector log says it was left alone',
    );

    # The recorded web is already gone, or none was recorded: no web line.
    $recorded_running = 0;
    like( $run_check->(), qr/shutdown-lifetime-owner-gone/, 'a recorded web that is already gone does not keep the supervisor alive' );
    is( $read_collector_log->(), '', 'nothing is written when the recorded web is already gone' );
    $recorded = undef;
    like( $run_check->(), qr/shutdown-lifetime-owner-gone/, 'a runtime with no recorded web shuts its supervisor down as before' );
    is( $read_collector_log->(), '', 'nothing is written when no web is recorded' );

    # A log that cannot be written never keeps the supervisor alive.
    {
        my $files_class = ref $manager->{files};
        no strict 'refs';
        local *{ $files_class . '::append' } = sub { die "disk full\n" };
        use strict 'refs';
        ( $recorded, $stop_result ) = ( 5151, 5151 );
        $shutdowns = 0;
        like( $run_check->(), qr/shutdown-lifetime-owner-gone/, 'a collector log that cannot be written does not keep the supervisor alive' );
        is( $shutdowns, 1, 'the supervisor shuts down exactly once when its log cannot be written' );
        is( scalar( $manager->_log_collector_supervisor_lifetime_event('text') ), undef, 'a failed supervisor log write is reported as undef, not as an error' );
    }
    is( scalar( $manager->_log_collector_supervisor_lifetime_event('') ), undef, 'no supervisor line is written without text' );
    unlink $collector_log;

    # The recorded pid reader on its own.
    {
        my $files_class = ref $manager->{files};
        my $raw;
        no strict 'refs';
        local *{ $files_class . '::read' } = sub { return $raw };
        use strict 'refs';
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_recorded_web_pid_for_lifetime_owner = $real_recorded_reader;
        is( scalar( $manager->_recorded_web_pid_for_lifetime_owner ), undef, 'no recorded web pid reads as undef' );
        $raw = "junk\n";
        is( scalar( $manager->_recorded_web_pid_for_lifetime_owner ), undef, 'a malformed recorded web pid reads as undef' );
        $raw = "5151\n";
        is( scalar( $manager->_recorded_web_pid_for_lifetime_owner ), 5151, 'a recorded web pid is read as a number' );
    }
}

{
    # The watcher's own stop where the watcher is a child of its web
    # (Windows). There a whole-tree kill of the web ends the watcher
    # inside its own stop, so it must list the tree itself, leave its
    # own pid out, end every other member by exact pid, deepest first,
    # then the web, and only then say the web was stopped. The listing
    # and the kill are stood in for by recorders, so the same checks run
    # on every platform.
    my $class       = 'Developer::Dashboard::RuntimeManager';
    my $web_pid     = 7000;
    my $owner_pid   = 4242;
    my $watcher_log = File::Spec->catfile( $home, 'web-lifetime-owner-watcher-spares-itself.log' );
    my $read_watcher_log = sub {
        open my $fh, '<', $watcher_log or return '';
        local $/;
        my $text = <$fh>;
        return defined $text ? $text : '';
    };
    my $web_alive = 1;
    my ( @tree_signals, @kills, @listings, @log_at_kill );
    my @tree = (
        { pid => 7000, ppid => 6000, started => '500' },
        { pid => 7001, ppid => 7000, started => '510' },
        { pid => 7002, ppid => 7001, started => '520' },
        { pid => $$,   ppid => 7000, started => '530' },
        { pid => 7003, ppid => $$,   started => '540' },
        { pid => 7004, ppid => 7000, started => '100' },
        { pid => 7005, ppid => 7000, started => '' },
        { pid => 7006, ppid => 7005, started => '560' },
        { pid => 8000, ppid => 6000, started => '505' },
    );
    # Born under 7001 after the first listing; 7001 has ended by the
    # second listing and its row is gone, but the child still names it.
    my @late = ( { pid => 7009, ppid => 7001, started => '600' } );
    no warnings 'redefine';
    local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = $owner_pid;
    local *Developer::Dashboard::RuntimeManager::_web_watcher_spares_itself   = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_lifetime_owner_poll_seconds = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval       = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_web_stop_confirm_pause_seconds = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_web_lifetime_owner_watcher_object = sub { return $manager };
    local *Developer::Dashboard::RuntimeManager::_lifetime_owner_is_gone = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web         = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub {
        my ( undef, $pid ) = @_;
        return $pid == $web_pid ? $web_alive : 0;
    };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub {
        my ( undef, $signal, @pids ) = @_;
        push @tree_signals, join ' ', $signal, @pids;
        $web_alive = 0;
        return scalar @pids;
    };
    local *Developer::Dashboard::RuntimeManager::_windows_process_tree_rows = sub {
        push @listings, scalar @listings + 1;
        my @gone = @listings == 1 ? () : ( 7000, 7001, 7002 );
        my @rows = grep { my $row = $_; !grep { $_ == $row->{pid} } @gone } @tree;
        push @rows, @late if @listings == 2;
        return \@rows;
    };
    local *Developer::Dashboard::RuntimeManager::_kill_exact_pids = sub {
        my ( undef, @pids ) = @_;
        push @kills, @pids;
        push @log_at_kill, $read_watcher_log->();
        $web_alive = 0 if grep { $_ == $web_pid } @pids;
        return scalar @pids;
    };

    unlink $watcher_log;
    is( $class->_run_web_lifetime_owner_watcher( $web_pid, $watcher_log ), 0,
        'spare route: the watcher ends normally when it is a child of the web it stops' );
    is_deeply( \@tree_signals, [],
        'spare route: the watcher never makes the whole-tree kill that would end the watcher itself' );
    is_deeply( [ @kills[ 0 .. 2 ] ], [ 7002, 7001, 7000 ],
        'spare route: every listed member is ended by exact pid, deepest first, and the web pid last' );
    is( scalar( grep { $_ == $$ } @kills ), 0, 'spare route: the watcher leaves its own pid out of the kill' );
    is( scalar( grep { $_ == 7003 } @kills ), 0, 'spare route: nothing under the watcher itself is ended' );
    is( scalar( grep { $_ == 8000 } @kills ), 0, 'spare route: a process outside the web tree is never ended' );
    is( scalar( grep { $_ == 7004 } @kills ), 0,
        'spare route: a process older than the web that names its pid as parent is left alone' );
    is( scalar( grep { $_ == 7005 || $_ == 7006 } @kills ), 0,
        'spare route: a process whose start time cannot be read is left alone, with everything under it' );
    is_deeply( [ @kills[ 3 .. $#kills ] ], [7009],
        'spare route: a child born after the first listing is found on the next look and ended' );
    is( scalar @listings, 3, 'spare route: the tree is listed again until a look finds nothing left, at most three times' );
    is( scalar( grep { /web stopped:/ } @log_at_kill ), 0,
        'spare route: no stop line is in the log at the moment of any kill' );
    like( $read_watcher_log->(),
        qr/ web stopped: lifetime owner gone; lifetime owner pid \Q$owner_pid\E is gone; web pid \Q$web_pid\E is stopping\n\z/,
        'spare route: the stop line is written after the kills and is the last line' );
    like( $read_watcher_log->(), qr/ web tree member left alone: [^\n]* under web pid 7000, pid 7004: it is older than the process holding its parent pid/,
        'spare route: the log names the member left alone because its parent pid was reused' );
    like( $read_watcher_log->(), qr/ web tree member left alone: [^\n]* under web pid 7000, pid 7005: a start time could not be read/,
        'spare route: the log names the member left alone because its start time could not be read' );

    # The listing fails: the watcher says so, says what it falls back
    # to, and never claims a stop before the act.
    unlink $watcher_log;
    ( $web_alive, @tree_signals ) = (1);
    @kills = ();
    local *Developer::Dashboard::RuntimeManager::_windows_process_tree_rows = sub { return };
    is( $class->_run_web_lifetime_owner_watcher( $web_pid, $watcher_log ), 0,
        'spare route: the watcher ends normally when the tree cannot be listed' );
    is_deeply( \@kills, [], 'spare route: with no listing nothing is ended by exact pid' );
    is_deeply( \@tree_signals, ["TERM $web_pid"], 'spare route: with no listing the watcher falls back to the whole-tree kill' );
    like( $read_watcher_log->(), qr/ web tree not listed: [^\n]* falling back to a whole-tree kill of web pid 7000, which ends watcher pid \Q$$\E as well[^\n]*\n\S+ web stopped: /,
        'spare route: the fallback line is written before the tree kill and before any stop line' );

    # Where the watcher is not a child of its web the stop is the
    # ordinary one, unchanged.
    unlink $watcher_log;
    ( $web_alive, @tree_signals ) = (1);
    @kills    = ();
    @listings = ();
    local *Developer::Dashboard::RuntimeManager::_web_watcher_spares_itself = sub { return 0 };
    is( $class->_run_web_lifetime_owner_watcher( $web_pid, $watcher_log ), 0,
        'ordinary route: the watcher ends normally where it is not a child of its web' );
    is_deeply( [ \@tree_signals, \@kills, \@listings ], [ ["TERM $web_pid"], [], [] ],
        'ordinary route: the stop is the plain signal, with no listing and no kill by exact pid' );

    is( Developer::Dashboard::RuntimeManager::_process_started_not_before( '1000', '999' ), 1,
        'start times: a longer run of digits is the later time' );
    is( Developer::Dashboard::RuntimeManager::_process_started_not_before( '999', '1000' ), 0,
        'start times: a shorter run of digits is the earlier time' );
    is( Developer::Dashboard::RuntimeManager::_process_started_not_before( '500', '500' ), 1,
        'start times: a child may share its parent start time' );
    is( Developer::Dashboard::RuntimeManager::_process_started_not_before( '', '500' ), 0,
        'start times: an unreadable child start time proves nothing' );
    is( Developer::Dashboard::RuntimeManager::_process_started_not_before( '500', undef ), 0,
        'start times: an unreadable parent start time proves nothing' );
    unlink $watcher_log;
}

END {
    chdir $original_cwd if defined $original_cwd && length $original_cwd;
}

done_testing;

__END__

=pod

=head1 NAME

t/46-runtime-manager-supervisor.t - coverage and regression tests for the collector watchdog supervisor

=head1 WHAT IT IS

This test file exercises the collector watchdog supervisor helpers inside
L<Developer::Dashboard::RuntimeManager>.

=head1 WHAT IT IS FOR

It verifies the state-file, pidfile, process-identification, detached-launch,
shutdown, and watchdog-loop behaviour added for collector self-healing.

=head1 PURPOSE

Test file in the Developer Dashboard codebase. This file verifies collector
watchdog supervisor behaviour, detached lifecycle handling, and coverage for
the RuntimeManager resilience path.
Open this file when you need the implementation, regression coverage, or
runtime entrypoint for that responsibility rather than guessing which part of
the tree owns it.

=head1 WHY IT EXISTS

The collector watchdog is meant to keep managed collectors alive, restart them
after unexpected exits, and escalate to human attention when repeated crashes
continue. These tests keep that resilience path covered so the implementation
does not silently regress.

=head1 WHEN TO USE

This test runs as part of the normal repository test suite and should also be
run when changing collector lifecycle code, watchdog state handling, or
detached helper startup paths.

=head1 HOW TO USE

Run it directly during focused debugging:

  perl -Ilib t/46-runtime-manager-supervisor.t

Run it through the standard harness:

  prove -lv t/46-runtime-manager-supervisor.t

Run it under coverage with the rest of the suite:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

=head1 WHAT USES IT

The repository test harness, coverage gates, release metadata checks, and
maintainers changing the runtime manager use this file to prove the watchdog
behaviour still matches the expected contract.

=head1 EXAMPLES

Example: verify only the watchdog supervisor coverage after editing its state
helpers.

  prove -lv t/46-runtime-manager-supervisor.t

Example: rerun the runtime-manager focused suite after changing collector
restart policy.

  prove -lv t/09-runtime-manager.t t/46-runtime-manager-supervisor.t

Example: confirm the full repository still keeps watchdog code covered.

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

=cut
