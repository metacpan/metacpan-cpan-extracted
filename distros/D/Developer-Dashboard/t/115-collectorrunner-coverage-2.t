#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

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
        skip 'running as root defeats the unreadable-file open failure', 1 if -r $unreadable;
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
    local *Developer::Dashboard::CollectorRunner::tempfile = sub {
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
    local *Developer::Dashboard::CollectorRunner::tempfile = sub {
        open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
        return ( $fh, $pidfile );
    };
    local *Developer::Dashboard::CollectorRunner::_exit_code_from_status = sub {
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
# runs in a forked child so a stray signal cannot reach the test process. Perl
# ignores SIGINT for the duration of system(), so only TERM and HUP can be
# delivered here.
{
    my $report = File::Spec->catfile( $home, 'forwarded-signals.txt' );
    my $child  = fork();
    die "Unable to fork: $!" if !defined $child;
    if ( !$child ) {
        my @forwarded;
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_forward_command_signal = sub {
            my ( undef, undef, $signal, $number ) = @_;
            push @forwarded, "$signal:$number";
            return 1;
        };
        my ( undef, undef, $exit_code ) = $runner->_run_command(
            source     => "kill -TERM $$; kill -HUP $$; sleep 1",
            cwd        => $home,
            timeout_ms => 60_000,
        );
        open my $fh, '>', $report or POSIX::_exit(9);
        print {$fh} join( ',', sort @forwarded ) . "|exit=$exit_code";
        close $fh or POSIX::_exit(9);
        CORE::exit(0);
    }
    waitpid( $child, 0 );
    my $status = $?;
    is( $status, 0, '_run_command survives a collector command that signals the runner process' );
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
    local *Developer::Dashboard::CollectorRunner::_forward_command_signal = sub {
        my ( undef, undef, $signal, $number ) = @_;
        push @forwarded, "$signal:$number";
        return 1;
    };
    local *Developer::Dashboard::CollectorRunner::_exit_code_from_status = sub {
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
    my $gone = fork();
    die "Unable to fork: $!" if !defined $gone;
    POSIX::_exit(0) if !$gone;
    waitpid( $gone, 0 );
    ok(
        $runner->_terminate_command_process($gone),
        '_terminate_command_process treats a waitpid of -1 as an already-reaped command child',
    );
}

# The other two arms of the same wait: a command child that this process still
# owns and that exits on TERM, and a stubborn one that has to spend the whole
# bounded window before the KILL escalation collects it.
{
    my $obedient = fork();
    die "Unable to fork: $!" if !defined $obedient;
    POSIX::_exit(0) if !$obedient;
    ok(
        $runner->_terminate_command_process($obedient),
        '_terminate_command_process reaps a command child it still owns',
    );
    ok( !kill( 0, $obedient ), '_terminate_command_process leaves no owned command child behind' );
}
{
    my $stubborn = fork();
    die "Unable to fork: $!" if !defined $stubborn;
    if ( !$stubborn ) {
        POSIX::setsid();
        $SIG{TERM} = 'IGNORE';
        select undef, undef, undef, 30;
        POSIX::_exit(0);
    }
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
    my $child = fork();
    die "Unable to fork: $!" if !defined $child;
    if ( !$child ) {
        POSIX::sigprocmask( POSIX::SIG_BLOCK(), POSIX::SigSet->new( POSIX::SIGTERM() ) );
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_await_command_pid          = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::_terminate_command_process = sub { return 1 };
        $runner->_forward_command_signal( undef, 'TERM', 15 );
        POSIX::_exit(1);
    }
    waitpid( $child, 0 );
    my $status = $?;
    is( $status & 127, 0, '_forward_command_signal leaves the re-raised signal pending rather than dying from it' );
    is( $status >> 8, 143, '_forward_command_signal re-raises the default-disposition signal and exits 128+signal' );
}

# Windows arm with an empty recorded pid-file path: the unlink is skipped
# because the path is present but blank, and no self-signal is re-raised.
{
    my $child = fork();
    die "Unable to fork: $!" if !defined $child;
    if ( !$child ) {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::is_windows                 = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_await_command_pid          = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::_terminate_command_process = sub { return 1 };
        $runner->_forward_command_signal( '', 'TERM', 15 );
        POSIX::_exit(1);
    }
    waitpid( $child, 0 );
    is( $? >> 8, 143, '_forward_command_signal skips the unlink for an empty pid-file path and still exits 128+signal' );
}

# A recorded pid-file path is removed before the handler exits, so a stopped
# command never leaves its launcher pid file behind.
{
    my $pidfile = File::Spec->catfile( $home, 'forwarded-command.pid' );
    open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
    print {$fh} "4242\n";
    close $fh or die "Unable to close $pidfile: $!";
    my $child = fork();
    die "Unable to fork: $!" if !defined $child;
    if ( !$child ) {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::is_windows                 = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_await_command_pid          = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::_terminate_command_process = sub { return 1 };
        $runner->_forward_command_signal( $pidfile, 'HUP', 1 );
        POSIX::_exit(1);
    }
    waitpid( $child, 0 );
    is( $? >> 8, 129, '_forward_command_signal exits 128+signal for a forwarded HUP' );
    ok( !-e $pidfile, '_forward_command_signal removes the recorded launcher pid file' );
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

Run it directly while iterating:

  perl -Ilib t/115-collectorrunner-coverage-2.t

The checks are hermetic: every path lives under a throwaway HOME that the test
chdirs into first. Two checks fork a child that calls the stop-signal handler
and then exits through it, so the parent asserts on the child's wait status; the
POSIX arm blocks SIGTERM in the child first so the handler's self-signal stays
pending and the C<128+signal> exit code remains observable. The close-failure
check substitutes a pipe whose read end is gone for the launcher pid file, and
the rethrow check makes the wait-status decoder die, so neither needs a real
broken filesystem or a real stuck command.

=head1 WHAT USES IT

This is a standalone author regression test for
C<Developer::Dashboard::CollectorRunner>; it is run by C<prove -lr t> and by the
repository coverage gate, and nothing in the shipped library depends on it.

=head1 EXAMPLES

Drive only this file with verbose output while iterating on a fix:

  prove -lv t/115-collectorrunner-coverage-2.t

Confirm the collector runner still reads clean on every coverage metric:

  cover -delete
  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
  cover -report text -select_re '^lib/' -coverage branch -coverage condition

=cut
