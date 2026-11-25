#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(cwd);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX ();
use Test::More;

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::GoRoutine ();

my $repo_root = cwd();

# _run_perl_child($source, @arguments)
# Starts an isolated Perl process through the GoRoutine process API, propagates
# the harness's coverage options and shared database, and returns its exit code.
# Input: Perl source string followed by its @ARGV values.
# Output: child exit code integer.
sub _run_perl_child {
    my ( $source, @arguments ) = @_;
    my @include = map { '-I' . File::Spec->catdir( $repo_root, $_ ) } qw(lib blib/lib blib/arch);
    my %child_env;
    my $coverage_switches = $ENV{HARNESS_PERL_SWITCHES};
    my $coverage_child = defined $coverage_switches && length $coverage_switches
      && $coverage_switches =~ /Devel::Cover/;
    if ( defined $coverage_switches && length $coverage_switches ) {
        $child_env{PERL5OPT} = $coverage_switches;
    }
    my $spawn_options = { env => \%child_env };
    # Devel::Cover only instruments repository modules under its selected source
    # tree. These child fixtures chdir into their throwaway HOME for hermetic
    # behavior, so coverage mode returns them to the checkout before startup.
    $spawn_options->{cwd} = $repo_root if $coverage_child;
    my $pid = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, @include, '-e', $source, @arguments ],
        $spawn_options,
    );
    die "GoRoutine spawn failed: $!" if !defined $pid;
    return Developer::Dashboard::GoRoutine::wait_process($pid);
}

# ---------------------------------------------------------------------------
# Hermetic runtime rooted in a throwaway HOME. The config root resolves from
# the deepest .developer-dashboard layer discovered from the CWD, so chdir into
# the temporary home before constructing anything.
# ---------------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
);
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => Developer::Dashboard::Collector->new( paths => $paths ),
    files      => Developer::Dashboard::FileRegistry->new( paths => $paths ),
    indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
    paths      => $paths,
);

# ===========================================================================
# _command_pid_from_file: the present-but-unopenable pidfile and the
# present-but-empty pidfile.
# ===========================================================================

# An existing pidfile whose permissions deny reading passes the -f guard and
# then fails the open, which must be reported as "no recorded pid" rather than
# dying inside a signal handler.
{
    my $unreadable = File::Spec->catfile( $home, 'unreadable-command.pid' );
    open my $fh, '>', $unreadable or die "Unable to write $unreadable: $!";
    print {$fh} "4242\n";
    close $fh or die "Unable to close $unreadable: $!";
  SKIP: {
        chmod 0000, $unreadable or skip 'chmod not honored on this filesystem', 1;
        # Was `if -r $unreadable`. Perl's filetest operators are mode-bit
        # arithmetic and special-case uid 0, so -r answers true for root even
        # where the open is genuinely denied - which skipped an assertion that a
        # capability-dropped root would have run and passed. Probe by attempting.
        if ( open my $probe, '<', $unreadable ) {
            close $probe or die "Unable to close probe on $unreadable: $!";
            skip 'this process can read a mode-0000 file, so the open failure cannot occur', 1;
        }
        ok(
            !defined $runner->_command_pid_from_file($unreadable),
            '_command_pid_from_file returns no pid when a present pidfile cannot be opened',
        );
    }
    chmod 0600, $unreadable;
}

# A launcher that was killed between creating and writing its pidfile leaves a
# zero-length file, so the first read yields undef instead of pid text. The
# remaining recorded-pid shapes are exercised alongside it so this file pins
# every arm of the validation guard on its own.
{
    my $recorded = File::Spec->catfile( $home, 'recorded-command.pid' );

    # write_recorded_pid: replace the recorded pid text with one payload.
    # Input: raw pid file content string. Output: pid file path string.
    my $write_recorded_pid = sub {
        my ($content) = @_;
        open my $fh, '>', $recorded or die "Unable to write $recorded: $!";
        print {$fh} $content;
        close $fh or die "Unable to close $recorded: $!";
        return $recorded;
    };

    $write_recorded_pid->('');
    ok(
        !defined $runner->_command_pid_from_file($recorded),
        '_command_pid_from_file returns no pid when the pidfile is present but empty',
    );

    $write_recorded_pid->("not-a-pid\n");
    ok(
        !defined $runner->_command_pid_from_file($recorded),
        '_command_pid_from_file returns no pid for non-numeric recorded text',
    );

    $write_recorded_pid->("0\n");
    ok(
        !defined $runner->_command_pid_from_file($recorded),
        '_command_pid_from_file returns no pid for a recorded pid below one',
    );

    $write_recorded_pid->("4242\n");
    is(
        $runner->_command_pid_from_file($recorded),
        4242,
        '_command_pid_from_file returns the numeric pid recorded by the launcher',
    );
}

# ===========================================================================
# _run_command: the pid-file close failure and a non-timeout exception raised
# from inside the alarm-guarded system() eval.
# ===========================================================================

# The recorded pid file must be closed before the launcher writes to it. Hand
# _run_command a handle whose flush cannot succeed (the read end of a pipe is
# already gone) so the close-failure guard fires.
{
    no warnings 'redefine';
    local $SIG{PIPE} = 'IGNORE';
    local *Developer::Dashboard::CommandRunner::tempfile = sub {
        pipe my $read, my $write or die "Unable to create a pipe: $!";
        close $read or die "Unable to close the pipe read end: $!";
        print {$write} 'pending';    # buffered: the flush inside close hits EPIPE
        return ( $write, File::Spec->catfile( $home, 'unclosable-command.pid' ) );
    };
    my $error = eval { $runner->_run_command( source => 'true', cwd => $home, timeout_ms => 5000 ); 1 } ? '' : $@;
    like(
        $error,
        qr/Unable to close collector command pid file/,
        '_run_command dies when the launcher pid file cannot be closed',
    );
}

# A failure that is not the alarm-driven timeout marker must be rethrown
# verbatim instead of being reported as a timed-out collector run.
{
    my $pidfile = File::Spec->catfile( $home, 'rethrown-command.pid' );
    no warnings 'redefine';
    local *Developer::Dashboard::CommandRunner::tempfile = sub {
        open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
        return ( $fh, $pidfile );
    };
    local *Developer::Dashboard::CommandRunner::exit_code_from_status = sub {
        die "collector wait-status decode failed\n";
    };
    my $error = eval { $runner->_run_command( source => 'true', cwd => $home, timeout_ms => 60_000 ); 1 } ? '' : $@;
    alarm 0;    # the rethrow skips the normal alarm reset at the end of _run_command
    like(
        $error,
        qr/collector wait-status decode failed/,
        '_run_command rethrows a non-timeout exception raised while running the command',
    );
    unlink $pidfile;
}

# The sibling arm of the same guard: the alarm-driven timeout marker is
# recognized and converted into the timeout exit code instead of being rethrown.
{
    my ( undef, undef, $exit_code, $timed_out ) = $runner->_run_command(
        source     => qq{$^X -e 'sleep 5'},
        cwd        => $home,
        timeout_ms => 100,
    );
    is( $exit_code, 124, '_run_command converts its own timeout marker into the timeout exit code' );
    ok( $timed_out, '_run_command flags the run as timed out rather than rethrowing the timeout marker' );
}

# ===========================================================================
# _run_command signal handlers: the TERM/INT/HUP handlers installed around a
# running collector command must forward that exact signal to the command
# subtree cleanup.
# ===========================================================================

# Real delivery: the collector command signals the runner process itself while
# system() is still waiting for it. The forwarding helper is stubbed so the
# handlers record the signal instead of exiting the process, and the whole check
# runs in an isolated GoRoutine-spawned Perl process so a stray signal cannot
# reach the test process. Perl
# ignores SIGINT for the duration of system(), so only TERM and HUP can be
# delivered here.
SKIP: {
    # Real signal delivery is a Unix mechanism: the fixture command shells
    # out to `kill` to signal the runner, and there is no kill on Windows
    # (nor any signal delivery to a process at all). The forwarding of a
    # delivered signal is covered on Windows by the INT-handler block
    # below, which invokes the handler directly.
    skip 'real signal delivery needs a Unix kill binary and Unix signal delivery, neither of which exists on Windows', 2
      if $^O eq 'MSWin32';
    my $report = File::Spec->catfile( $home, 'forwarded-signals.txt' );
    my $source = q{
        use POSIX ();
        use File::Spec;
        use Developer::Dashboard::Collector;
        use Developer::Dashboard::CollectorRunner;
        use Developer::Dashboard::FileRegistry;
        use Developer::Dashboard::IndicatorStore;
        use Developer::Dashboard::PathRegistry;
        my ( $home, $report ) = @ARGV;
        $ENV{HOME} = $home;
        chdir $home or die "Unable to chdir to $home: $!";
        my $paths = Developer::Dashboard::PathRegistry->new(
            home => $home,
            workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
        );
        my $runner = Developer::Dashboard::CollectorRunner->new(
            collectors => Developer::Dashboard::Collector->new( paths => $paths ),
            files => Developer::Dashboard::FileRegistry->new( paths => $paths ),
            indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
            paths => $paths,
        );
        my @forwarded;
        no warnings 'redefine';
        local *Developer::Dashboard::CommandRunner::forward_command_signal = sub {
            my ( $pidfile, $signal, $number ) = @_;
            push @forwarded, "$signal:$number";
            return 1;
        };
        my ( undef, undef, $exit_code ) = $runner->_run_command(
            source => "kill -TERM $$; kill -HUP $$; sleep 1",
            cwd => $home,
            timeout_ms => 60_000,
        );
        open my $fh, '>', $report or POSIX::_exit(9);
        print {$fh} join( ',', sort @forwarded ) . "|exit=$exit_code";
        close $fh or POSIX::_exit(9);
    };
    is(
        _run_perl_child( $source, $home, $report ),
        0,
        '_run_command survives a collector command that signals the runner process',
    );
    my $forwarded = '';
    if ( open my $fh, '<', $report ) {
        local $/;
        $forwarded = <$fh>;
        close $fh or die "Unable to close $report: $!";
    }
    is(
        $forwarded,
        'HUP:1,TERM:15|exit=0',
        '_run_command forwards a delivered TERM and HUP to the command subtree cleanup with their own signal numbers',
    );
}

# Perl sets SIGINT to ignored for as long as system() waits on the command, so
# the INT handler can never be driven by a real signal from that command. Reach
# it at the one point inside the handler's scope a test can hook instead: the
# wait-status decoder, which runs after system() returns and before the capture
# block ends.
{
    my @forwarded;
    no warnings 'redefine';
    local *Developer::Dashboard::CommandRunner::forward_command_signal = sub {
        my ( $pidfile, $signal, $number ) = @_;
        push @forwarded, "$signal:$number";
        return 1;
    };
    local *Developer::Dashboard::CommandRunner::exit_code_from_status = sub {
        my $handler = $SIG{INT};
        $handler->('INT') if ref($handler) eq 'CODE';
        return 0;
    };
    my ( undef, undef, $exit_code ) = $runner->_run_command( source => 'true', cwd => $home, timeout_ms => 5000 );
    is( $exit_code, 0, '_run_command completes after its INT handler has run' );
    is_deeply(
        \@forwarded,
        ['INT:2'],
        '_run_command installs an INT handler that forwards INT with its own signal number',
    );
}

# ===========================================================================
# _terminate_command_process: waitpid reporting -1 because the command child is
# no longer ours to wait for.
# ===========================================================================

# Reap the child first, then ask the cleanup helper to terminate it: waitpid
# answers -1 (no such child) and the helper must treat that as "already gone"
# instead of escalating to a direct KILL.
{
    my $gone = Developer::Dashboard::GoRoutine::spawn( [ $^X, '-e', 'exit 0;' ], {} );
    die "GoRoutine spawn failed: $!" if !defined $gone;
    Developer::Dashboard::GoRoutine::wait_process($gone);
    ok(
        $runner->_terminate_command_process($gone),
        '_terminate_command_process treats a waitpid of -1 as an already-reaped command child',
    );
}

# The other two arms of the same wait: a command child that this process still
# owns and that exits on TERM, and a stubborn one that has to spend the whole
# bounded window before the KILL escalation collects it.
{
    my $obedient = Developer::Dashboard::GoRoutine::spawn( [ $^X, '-e', 'sleep 30;' ], {} );
    die "GoRoutine spawn failed: $!" if !defined $obedient;
    ok(
        $runner->_terminate_command_process($obedient),
        '_terminate_command_process reaps a command child it still owns',
    );
    ok( !kill( 0, $obedient ), '_terminate_command_process leaves no owned command child behind' );
}
{
    my $stubborn = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', q{$SIG{TERM} = 'IGNORE'; select undef, undef, undef, 30;} ],
        { process_group => 1 },
    );
    die "GoRoutine spawn failed: $!" if !defined $stubborn;
    select undef, undef, undef, 0.1;
    ok(
        $runner->_terminate_command_process($stubborn),
        '_terminate_command_process escalates to KILL when the command child outlives the bounded TERM window',
    );
}

# ===========================================================================
# _forward_command_signal: the POSIX re-raise arm and the pid-file guard arms.
# ===========================================================================

# POSIX arm: with no pid file recorded there is nothing to unlink, and the
# handler restores the default disposition and re-raises the signal on itself
# before exiting 128+signal. SIGTERM is blocked in the child so the re-raised
# signal stays pending and the exit status is observable.
{
    my $end_marker = File::Spec->catfile( $home, 'forwarded-term-ended.txt' );
    my $source = q{
        use POSIX ();
        use Developer::Dashboard::CommandRunner;
        END {
            open my $fh, '>', $ARGV[0] or die "Unable to write END marker: $!";
            print {$fh} "normal exit\n" or die "Unable to write END marker: $!";
            close $fh or die "Unable to close END marker: $!";
        }
        # POSIX::sigprocmask and its SIG_BLOCK macro do not exist on
        # Strawberry Perl. The Windows arm of forward_command_signal exits
        # 128+signal without re-raising, so blocking the signal is not
        # needed there; the exit code and the END marker are the same.
        if ( $^O ne 'MSWin32' ) {
            POSIX::sigprocmask( POSIX::SIG_BLOCK(), POSIX::SigSet->new( POSIX::SIGTERM() ) );
        }
        no warnings 'redefine';
        local *Developer::Dashboard::CommandRunner::await_command_pid = sub { return undef };
        local *Developer::Dashboard::CommandRunner::terminate_command_process = sub { return 1 };
        Developer::Dashboard::CommandRunner::forward_command_signal( undef, 'TERM', 15 );
    };
    is( _run_perl_child( $source, $end_marker ), 143,
        '_forward_command_signal exits 128+signal while the re-raised signal remains pending' );
    ok( -f $end_marker,
        '_forward_command_signal child exits normally instead of dying from the pending signal' );
}

# Windows arm with an empty recorded pid-file path: the unlink is skipped
# because the path is present but blank, and no self-signal is re-raised.
{
    my $end_marker = File::Spec->catfile( $home, 'forwarded-empty-path-ended.txt' );
    my $source = q{
        use Developer::Dashboard::CommandRunner;
        END {
            open my $fh, '>', $ARGV[0] or die "Unable to write END marker: $!";
            print {$fh} "normal exit\n" or die "Unable to write END marker: $!";
            close $fh or die "Unable to close END marker: $!";
        }
        no warnings 'redefine';
        local *Developer::Dashboard::CommandRunner::is_windows = sub { return 1 };
        local *Developer::Dashboard::CommandRunner::await_command_pid = sub { return undef };
        local *Developer::Dashboard::CommandRunner::terminate_command_process = sub { return 1 };
        Developer::Dashboard::CommandRunner::forward_command_signal( '', 'TERM', 15 );
    };
    is( _run_perl_child( $source, $end_marker ), 143,
        '_forward_command_signal skips unlink for an empty path and exits 128+signal' );
    ok( -f $end_marker,
        '_forward_command_signal empty-path child exits normally on the Windows branch' );
}

# A recorded pid-file path is removed before the handler exits, so a stopped
# command never leaves its launcher pid file behind.
{
    my $pidfile = File::Spec->catfile( $home, 'forwarded-command.pid' );
    open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
    print {$fh} "4242\n";
    close $fh or die "Unable to close $pidfile: $!";
    my $end_marker = File::Spec->catfile( $home, 'forwarded-hup-ended.txt' );
    my $source = q{
        use Developer::Dashboard::CommandRunner;
        END {
            open my $fh, '>', $ARGV[1] or die "Unable to write END marker: $!";
            print {$fh} "normal exit\n" or die "Unable to write END marker: $!";
            close $fh or die "Unable to close END marker: $!";
        }
        no warnings 'redefine';
        local *Developer::Dashboard::CommandRunner::is_windows = sub { return 1 };
        local *Developer::Dashboard::CommandRunner::await_command_pid = sub { return undef };
        local *Developer::Dashboard::CommandRunner::terminate_command_process = sub { return 1 };
        Developer::Dashboard::CommandRunner::forward_command_signal( $ARGV[0], 'HUP', 1 );
    };
    is( _run_perl_child( $source, $pidfile, $end_marker ), 129,
        '_forward_command_signal exits 128+signal for a forwarded HUP' );
    ok( -f $end_marker,
        '_forward_command_signal HUP child exits normally on the Windows branch' );
    ok( !-e $pidfile, '_forward_command_signal removes the recorded launcher pid file' );
}

# A GoRoutine-spawned Perl child must inherit the harness coverage switch when
# a coverage run is active. Without explicitly translating the harness switch
# into PERL5OPT, child-only handlers pass their behavioral assertions but never
# contribute their module lines to the shared coverage database.
{
    my $marker = File::Spec->catfile( $home, 'coverage-child-marker.txt' );
    my $source = q{
        use Developer::Dashboard::CommandRunner;
        use Cwd qw(cwd);
        Developer::Dashboard::CommandRunner::exit_code_from_status(0);
        open my $fh, '>', $ARGV[0] or die "Unable to write coverage marker: $!";
        print {$fh} ( exists $INC{'Devel/Cover.pm'} ? "loaded\n" : "not-loaded\n" );
        print {$fh} ( defined $ENV{PERL5OPT} ? "$ENV{PERL5OPT}\n" : "(unset)\n" );
        print {$fh} cwd(), "\n";
        close $fh or die "Unable to close coverage marker: $!";
    };
    is( _run_perl_child( $source, $marker ), 0, 'coverage-switch probe child exits successfully' );
    open my $fh, '<', $marker or die "Unable to read coverage marker '$marker': $!";
    my $loaded = <$fh>;
    my $child_switches = <$fh>;
    my $child_cwd = <$fh>;
    close $fh or die "Unable to close coverage marker '$marker': $!";
    my $expected = ( $ENV{HARNESS_PERL_SWITCHES} // q{} ) =~ /Devel::Cover/ ? "loaded\n" : "not-loaded\n";
    is( $loaded, $expected, 'GoRoutine subprocess receives the coverage instrumentation selected by the harness' );
    if ( defined $ENV{HARNESS_PERL_SWITCHES} && $ENV{HARNESS_PERL_SWITCHES} =~ /Devel::Cover/ ) {
        is( $child_switches, "$ENV{HARNESS_PERL_SWITCHES}\n", 'GoRoutine subprocess writes to the same Devel::Cover database as the test harness' );
        is(
            $child_cwd,
            "$repo_root\n",
            'coverage-instrumented GoRoutine child starts at the checkout so Devel::Cover includes repository modules',
        );
    }
}

# When procfs supplies a nonempty command line, normalize NUL separators and
# whitespace without depending on /proc (absent on macOS and Windows).
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub {
        return "collector\x00worker\x00\n";
    };
    is(
        $runner->_read_process_title(424242),
        'collector worker',
        '_read_process_title decodes a procfs command line on every platform',
    );
}

# Enumerate real temporary directory entries instead of Linux /proc. The
# reader and identity lookups are stubbed, but enumeration and filtering run
# through the real method on every platform.
{
    require File::Path;
    my $root = File::Spec->catdir( $home, 'fake-collector-proc' );
    my $self_pid = POSIX::getpid();
    my @pids = map { $self_pid + $_ } ( 10000, 10001, 10002, 10003 );
    File::Path::make_path( $root, map { File::Spec->catdir( $root, $_ ) } ( $self_pid, @pids ) );
    no warnings 'redefine';
    local $Developer::Dashboard::CollectorRunner::PROCFS_ROOT = $root;
    local *Developer::Dashboard::CollectorRunner::_process_title = sub { 'collector-fixture' };
    local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub {
        my ( undef, $path ) = @_;
        return '' if $path =~ m{/\Q$pids[0]\E/cmdline\z};
        return 'command line' if $path =~ m{/\Q$pids[1]\E/cmdline\z};
        return undef;
    };
    local *Developer::Dashboard::CollectorRunner::_read_process_title = sub {
        my ( undef, $pid ) = @_;
        return 'other-title' if $pid == $pids[1];
        return 'collector-fixture';
    };
    local *Developer::Dashboard::CollectorRunner::_same_pid_namespace = sub {
        my ( undef, $pid ) = @_;
        return $pid == $pids[3] ? 1 : 0;
    };
    # Fix C scopes every _find_running_loop branch through
    # _loop_runtime_matches, which fails closed on a candidate with no
    # runtime identity - and its first guard is liveness (kill 0), so a
    # synthetic pid can never match through any channel (micro-proven in
    # t/986). Hold the gate at yes for the positive candidate only: for
    # every other pid this is exactly the real gate's answer here (a fake
    # pid fails it on liveness), so the filtering this block pins is
    # unchanged.
    local *Developer::Dashboard::CollectorRunner::_loop_runtime_matches = sub {
        my ( undef, $pid ) = @_;
        return $pid == $pids[3] ? 1 : 0;
    };
    is( $runner->_find_running_loop('fixture'), $pids[3],
        '_find_running_loop filters empty command lines, titles and namespaces portably' );
    is( $runner->_find_running_loop(''), undef,
        '_find_running_loop rejects an empty collector name' );
    {
        local *Developer::Dashboard::CollectorRunner::_read_process_title = sub { return undef };
        is( $runner->_find_running_loop('fixture'), undef,
            '_find_running_loop rejects candidates whose process title is unavailable' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_same_pid_namespace = sub { return 0 };
        is( $runner->_find_running_loop('fixture'), undef,
            '_find_running_loop returns undef after exhausting foreign-namespace candidates' );
    }

}

# A missing pidfile and no discoverable supervisor must return cleanly.
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_pidfile = sub {
        return File::Spec->catfile( $home, 'absent-supervisor.pid' );
    };
    local *Developer::Dashboard::CollectorRunner::_find_running_loop = sub { return undef };
    is( $runner->stop_loop('absent-loop'), undef,
        'stop_loop returns undef when neither pidfile nor process table finds a loop' );
}

# Missing pidfile, but a process-table lookup found an already reaped pid:
# finish persisted state cleanup without signalling a synthetic process.
{
    no warnings 'redefine';
    my $pid = 424242;
    my $cleaned = 0;
    local *Developer::Dashboard::CollectorRunner::_pidfile = sub {
        return File::Spec->catfile( $home, 'absent-supervisor-found.pid' );
    };
    local *Developer::Dashboard::CollectorRunner::_find_running_loop = sub { return $pid };
    local *Developer::Dashboard::CollectorRunner::_state_active_worker_pids = sub { return () };
    local *Developer::Dashboard::CollectorRunner::_reap_child_process = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_cleanup_loop_files = sub { $cleaned++; return 1 };
    local *Developer::Dashboard::Collector::mark_stopped = sub { return 1 };
    is( $runner->stop_loop('already-reaped-fixture'), $pid,
        'stop_loop accepts a discovered pid and handles a reaped supervisor safely' );
    is( $cleaned, 1, 'discovered, reaped supervisor state is cleaned exactly once' );
}

done_testing;

__END__

=head1 NAME

t/115-collectorrunner-coverage-2.t - second-wave branch and condition closure for the collector runner

=head1 PURPOSE

This file closes the remaining uncovered branches and conditions in the command
execution half of C<Developer::Dashboard::CollectorRunner>: the launcher pid-file
close guard, the non-timeout rethrow inside the alarm-guarded C<system()> eval,
the unopenable and empty launcher pid-file reads, the C<waitpid> of minus one
arm in the command-subtree cleanup, and both pid-file guard arms plus the POSIX
signal re-raise arm of the forwarded stop-signal handler.

=head1 WHY IT EXISTS

Those arms only run when a collector command is torn down under stress: a pid
file that cannot be closed or read, a wait status that cannot be decoded, a
command child that a previous reap already collected, and an external stop
signal arriving while the command subtree is still being cleaned up. Nothing in
the normal collector suites reaches them, yet a regression there orphans command
subtrees or turns a real failure into a bogus timeout report. Pinning each arm
in isolation keeps the all-metric coverage gate honest instead of annotating
paths that are genuinely reachable on the test host.

=head1 WHEN TO USE

Use this file when changing C<_run_command>, the launcher pid-file contract, the
timeout and rethrow handling around the alarm-guarded C<system()> call,
C<_command_pid_from_file>, C<_await_command_pid>, C<_terminate_command_process>,
or C<_forward_command_signal>.

=head1 HOW TO USE

Run it inside the dev Docker container while iterating:

  d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -Ilib -lv t/115-collectorrunner-coverage-2.t

The checks are hermetic: every path lives under a throwaway HOME that the test
chdirs into first. Isolated Perl child programs use the GoRoutine C<spawn> and
C<wait_process> APIs so the stop-signal handler can exit without ending the
harness; an C<END> marker and the child's exit status verify that the blocked
POSIX SIGTERM remains pending and the C<128+signal> exit code is observable.
The close-failure check substitutes a pipe whose read end is gone for the
launcher pid file, and the rethrow check makes the wait-status decoder die, so
neither needs a real broken filesystem or a real stuck command.

=head1 WHAT USES IT

This is a standalone author regression test for
C<Developer::Dashboard::CollectorRunner>; it is run by the Docker test suite
and the repository coverage gate, and nothing in the shipped library depends
on it.

=head1 EXAMPLES

Drive only this file with verbose output while iterating on a fix:

  d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -Ilib -lv t/115-collectorrunner-coverage-2.t

Confirm the collector runner still reads clean on every coverage metric:

  d2 docker compose exec dev perl script/coverage-gate

=cut
