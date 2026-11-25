#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(WNOHANG);
use Test::More;

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

# Hermetic runtime rooted at a throwaway home. The runtime root resolves from the
# deepest .developer-dashboard layer discovered from the current working
# directory, so the test must chdir into the temp home before building objects.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ],
);
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $runner = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );

# Devel::Cover slows the detached supervisor child down substantially, so the
# reap loop needs a much longer ceiling when the coverage gate is running.
my $supervisor_wait_loops = $INC{'Devel/Cover.pm'} ? 1200 : 400;

# Pin the shell the command actions run through so the recipes below have the
# same POSIX semantics on every host, instead of inheriting whatever interactive
# shell happens to be exported into the harness environment.
local $ENV{SHELL} = 'sh';

# reap_supervisor($pid)
# Purpose: block until the detached background-action supervisor child exits so
# its raw wait status can be inspected and its coverage data is flushed before
# the test process ends.
# Input: supervisor process id integer.
# Output: raw waitpid status word, or undef when the child never exited.
sub reap_supervisor {
    my ($pid) = @_;
    for ( 1 .. $supervisor_wait_loops ) {
        my $reaped = waitpid( $pid, WNOHANG );
        return $? if $reaped == $pid;
        select undef, undef, undef, 0.05;
    }
    return;
}

# ---------------------------------------------------------------------------
# run_command_action(): the deadline escalation must force SIGKILL when the
# command child is still alive after the SIGTERM grace window
# (line 208, `waitpid(...) == 0` true side).
#
# Determinism matters here, because the naive "trap TERM and sleep" recipe races
# the interpreter/shell startup: core time() only has one-second granularity, so
# a deadline of `time() + timeout_ms/1000` can elapse in the very next loop turn
# when the supervisor happens to start just before a second boundary. If SIGTERM
# lands before the command child has installed its handler, the child dies, the
# escalation waitpid reaps it, and the forced-KILL side is never taken.
#
# This case removes that race in two ways. First, timeout_ms is 5000, so with
# integer time() the deadline cannot fire before time() has advanced five times
# -- at least four seconds of wall clock after the fork. This leaves ample room
# for the command child to initialize even when Devel::Cover is inherited by the
# nested interpreter. Second, the command child is a real script whose
# TERM handler writes a marker file and then keeps running, so the assertions can
# prove from the outside that SIGTERM was delivered *and* survived: the marker
# only exists if the child was still alive when the escalation waitpid ran, which
# is exactly the branch under test.
#
# The command string leads with the shell's `exec` builtin on purpose. /bin/sh is
# dash on Debian-family hosts and it does not always collapse a single `-c`
# command into an exec, so without it the shell would stay between the supervisor
# and the script: SIGTERM would kill the shell instead of the script, and the
# script would be orphaned rather than signalled.
# ---------------------------------------------------------------------------
{
    my $marker = File::Spec->catfile( $home, 'term-was-absorbed.marker' );
    my $pidfile = File::Spec->catfile( $home, 'term-child.pid' );
    my $script = File::Spec->catfile( $home, 'ignore-term.pl' );
    open my $script_fh, '>', $script or die "Unable to write $script: $!";
    print {$script_fh} <<'CHILD';
#!/usr/bin/env perl
use strict;
use warnings;

# Record our own pid first: the test asserts after the supervisor is reaped
# that no command descendant survives the escalation (round 58: on Windows
# the supervisor used to terminate only the PowerShell direct child, so this
# script survived as an orphan, held the harness stdio pipe, and stalled
# prove after 1..13).
my $pidfile = $ENV{DD_TEST_PID_FILE};
if ( defined $pidfile && $pidfile ne '' ) {
    open my $pfh, '>', $pidfile or die "Unable to write $pidfile: $!";
    print {$pfh} "$$\n";
    close $pfh or die "Unable to close $pidfile: $!";
}

# The supervisor's terminate window must find this process alive, so record the
# delivered SIGTERM and deliberately keep running until SIGKILL arrives.
my $marker = $ENV{DD_TEST_TERM_MARKER};
$SIG{TERM} = sub {
    open my $fh, '>', $marker or return;
    print {$fh} "termed\n";
    close $fh;
    return;
};
sleep 5 while 1;
CHILD
    close $script_fh or die "Unable to close $script: $!";

    my $result = $runner->run_command_action(
        # The command string leads with the shell's `exec` builtin on
        # purpose on Unix (see the comment above), but there is no exec on
        # Windows: the supervisor runs the command through PowerShell
        # there, so invoke the script with the PowerShell call operator.
        command => $^O eq 'MSWin32' ? qq{& "$^X" "$script"} : qq{exec "$^X" "$script"},
        cwd        => $home,
        env        => { DD_TEST_TERM_MARKER => $marker, DD_TEST_PID_FILE => $pidfile },
        background => 1,
        timeout_ms => 5000,
    );

    ok( $result->{background}, 'background command action reports itself as backgrounded' );
    ok( $result->{pid} > 0, 'background command action returns a supervisor pid' );
    like( $result->{started_at}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, 'background command action stamps an ISO-8601 start time' );

    my $raw_status = reap_supervisor( $result->{pid} );
    ok( defined $raw_status, 'the detached background supervisor exits on its own' );
    is( ( defined $raw_status ? $raw_status >> 8 : -1 ), 124, 'the supervisor reports the timeout exit code after the deadline elapses' );

    SKIP: {
        # The marker only exists if the command child was still alive when
        # the escalation waitpid ran, which proves SIGTERM was delivered
        # and survived. On Windows a signal is never delivered to a
        # CreateProcess child - the supervisor terminates it outright -
        # so the handler never runs and the marker can never be written.
        skip 'SIGTERM is never delivered to a CreateProcess child on Windows, so the TERM handler never runs and the marker can never be written', 1
          if $^O eq 'MSWin32';
        ok( -e $marker, 'the command child received SIGTERM and stayed alive through the terminate window' );
    }
    ok( !$runner->_pid_is_running( $result->{pid} ), 'the supervisor is gone once the forced SIGKILL escalation completes' );

    # Round 58: the tree terminate must leave no command descendant alive.
    # The script above records its own pid; the supervisor only ever knew
    # the PowerShell pid, so without this check an orphaned script would
    # pass every other assertion in this file and still stall the harness.
    my $grandchild_pid;
    if ( open my $pfh, '<', $pidfile ) {
        local $/;
        my $text = <$pfh>;
        close $pfh;
        ($grandchild_pid) = $text =~ /(\d+)/ if defined $text;
    }
    ok( defined $grandchild_pid && $grandchild_pid > 0, 'the TERM-absorbing command child recorded its own pid' );
    my $grandchild_gone = 0;
    if ( defined $grandchild_pid ) {
        for ( 1 .. 100 ) {
            if ( !$runner->_pid_is_running($grandchild_pid) ) { $grandchild_gone = 1; last; }
            select undef, undef, undef, 0.05;
        }
    }
    ok( $grandchild_gone, 'no command descendant survives the forced SIGKILL escalation' );
}

# ---------------------------------------------------------------------------
# The opposite side of the same escalation check: a command child that honours
# SIGTERM is already reaped when the escalation waitpid runs, so no SIGKILL is
# sent (line 208, `waitpid(...) == 0` false side).
#
# `exec sleep 60` makes the shell replace itself with the sleep, so the process
# the supervisor signals is the process that dies -- there is no shell left
# waiting on a foreground child and therefore no orphaned sleep afterwards. The
# 5000ms timeout allows the instrumented child to finish startup before SIGTERM.
# ---------------------------------------------------------------------------
{
    # On Windows there is no `exec` and no `sleep` command, so run the
    # same 60-second sleep as a Perl script through PowerShell instead;
    # the observable behaviour is the same (a long-lived child that dies
    # when the supervisor terminates it).
    my $sleep_script = File::Spec->catfile( $home, 'dd-test-supervisor-sleep.pl' );
    open my $sleep_fh, '>', $sleep_script or die "Unable to write $sleep_script: $!";
    print {$sleep_fh} q{select undef, undef, undef, 60;};
    close $sleep_fh or die "Unable to close $sleep_script: $!";
    my $result = $runner->run_command_action(
        command => $^O eq 'MSWin32' ? qq{& "$^X" "$sleep_script"} : 'exec sleep 60',
        cwd        => $home,
        background => 1,
        timeout_ms => 5000,
    );

    ok( $result->{pid} > 0, 'a SIGTERM-honouring background action returns a supervisor pid' );

    my $raw_status = reap_supervisor( $result->{pid} );
    ok( defined $raw_status, 'the supervisor of a SIGTERM-honouring command exits on its own' );
    is( ( defined $raw_status ? $raw_status >> 8 : -1 ), 124, 'a terminated command still reports the timeout exit code' );
    ok( !$runner->_pid_is_running( $result->{pid} ), 'no supervisor survives the terminated command action' );
}

# Read the Linux procfs process-state format from a portable local fixture.
# This reaches the real state parser under macOS and Windows, where /proc is absent.
{
    require File::Path;
    my $proc_root = File::Spec->catdir( $home, 'fake-proc' );
    my $pid_dir = File::Spec->catdir( $proc_root, '424242' );
    File::Path::make_path($pid_dir);
    my $stat = File::Spec->catfile( $pid_dir, 'stat' );
    open my $fh, '>', $stat or die "Unable to write $stat: $!";
    print {$fh} "424242 (example worker) S 1 2 3\n";
    close $fh or die "Unable to close $stat: $!";
    local $Developer::Dashboard::ActionRunner::PROCFS_ROOT = $proc_root;
    is( $runner->_read_process_state(424242), 'S',
        '_read_process_state parses a readable procfs stat fixture portably' );
    open my $broken, '>', $stat or die "Unable to rewrite $stat: $!";
    print {$broken} "not a procfs stat record\n";
    close $broken or die "Unable to close $stat: $!";
    is( $runner->_read_process_state(424242), undef,
        '_read_process_state ignores a readable but malformed procfs stat' );
}

done_testing;

__END__

=pod

=head1 NAME

t/121-actionrunner-coverage-2.t - forced-SIGKILL escalation coverage for background command actions

=head1 PURPOSE

This test closes the last uncovered decision in
C<Developer::Dashboard::ActionRunner>: the detached background-action
supervisor's escalation from C<SIGTERM> to C<SIGKILL>. It drives a real
background command action whose child absorbs C<SIGTERM> and keeps running, so
the supervisor's post-grace-window C<waitpid> observes an unreaped child and must
send C<SIGKILL> before reporting the timeout exit code.

=head1 WHY IT EXISTS

It exists because the repository coverage gate demands 100 percent on every
Devel::Cover metric, including branch and condition, and the forced-kill side of
the escalation check was the one decision the rest of the suite never took. The
existing background-action tests only reached the case where the command child
had already died from C<SIGTERM>, which silently skips the escalation entirely.
That gap matters beyond the metric: a background action whose command ignores
C<SIGTERM> would otherwise be able to outlive its own timeout, leaving a runaway
process behind with no test proving the dashboard escalates.

=head1 WHEN TO USE

Use this test when changing the background command-action timeout logic, the
supervisor's terminate/kill sequence, the grace window between the two signals,
or the exit status the supervisor reports after a timeout. Run it as a targeted
regression before touching anything in the detached-supervisor loop, and expect
it to fail if the escalation is weakened to a plain terminate.

=head1 HOW TO USE

Run it directly from a source checkout:

  perl -Ilib t/121-actionrunner-coverage-2.t

It builds its own throwaway home, chdirs into it so the runtime layer resolves
hermetically, writes a tiny helper script that traps C<SIGTERM>, and then reaps
the supervisor itself so the detached child flushes before the test exits. No
environment beyond a writable temp directory and a POSIX-signal-capable host is
required.

=head1 WHAT USES IT

The repository test harness runs it as part of C<prove -lr t>, and the coverage
gate consumes it when measuring C<Developer::Dashboard::ActionRunner>. It is the
companion of the broader action-runner coverage and bug-hunt regressions, which
cover the trust checks, the encoded action transport, and the synchronous command
path rather than the escalation.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/121-actionrunner-coverage-2.t

Run the escalation regression on its own and watch the supervisor report exit
code 124.

Example 2:

  prove -lv t/81-actionrunner-coverage.t t/121-actionrunner-coverage-2.t

Run the full action-runner coverage pair together after editing the background
fork, detach, or timeout code.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -l t/121-actionrunner-coverage-2.t

Confirm the forced-kill branch is genuinely recorded rather than merely
exercised, since the decision executes inside a forked supervisor child.

Example 4:

  prove -lr t

Put any change to the action runner back through the whole suite before release.

=cut
