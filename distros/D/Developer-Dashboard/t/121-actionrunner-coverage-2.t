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
# This case removes that race in two ways. First, timeout_ms is 1500, so with
# integer time() the deadline can only fire once time() has advanced twice --
# i.e. at least a full second of wall clock after the fork, far longer than the
# command child needs to boot. Second, the command child is a real script whose
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
    my $script = File::Spec->catfile( $home, 'ignore-term.pl' );
    open my $script_fh, '>', $script or die "Unable to write $script: $!";
    print {$script_fh} <<'CHILD';
#!/usr/bin/env perl
use strict;
use warnings;

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
        command    => qq{exec "$^X" "$script"},
        cwd        => $home,
        env        => { DD_TEST_TERM_MARKER => $marker },
        background => 1,
        timeout_ms => 1500,
    );

    ok( $result->{background}, 'background command action reports itself as backgrounded' );
    ok( $result->{pid} > 0, 'background command action returns a supervisor pid' );
    like( $result->{started_at}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, 'background command action stamps an ISO-8601 start time' );

    my $raw_status = reap_supervisor( $result->{pid} );
    ok( defined $raw_status, 'the detached background supervisor exits on its own' );
    is( ( defined $raw_status ? $raw_status >> 8 : -1 ), 124, 'the supervisor reports the timeout exit code after the deadline elapses' );

    ok( -e $marker, 'the command child received SIGTERM and stayed alive through the terminate window' );
    ok( !$runner->_pid_is_running( $result->{pid} ), 'the supervisor is gone once the forced SIGKILL escalation completes' );
}

# ---------------------------------------------------------------------------
# The opposite side of the same escalation check: a command child that honours
# SIGTERM is already reaped when the escalation waitpid runs, so no SIGKILL is
# sent (line 208, `waitpid(...) == 0` false side).
#
# `exec sleep 60` makes the shell replace itself with the sleep, so the process
# the supervisor signals is the process that dies -- there is no shell left
# waiting on a foreground child and therefore no orphaned sleep afterwards. The
# same 1500ms timeout keeps the deadline at least a full second away, so the
# child is provably running when SIGTERM lands.
# ---------------------------------------------------------------------------
{
    my $result = $runner->run_command_action(
        command    => 'exec sleep 60',
        cwd        => $home,
        background => 1,
        timeout_ms => 1500,
    );

    ok( $result->{pid} > 0, 'a SIGTERM-honouring background action returns a supervisor pid' );

    my $raw_status = reap_supervisor( $result->{pid} );
    ok( defined $raw_status, 'the supervisor of a SIGTERM-honouring command exits on its own' );
    is( ( defined $raw_status ? $raw_status >> 8 : -1 ), 124, 'a terminated command still reports the timeout exit code' );
    ok( !$runner->_pid_is_running( $result->{pid} ), 'no supervisor survives the terminated command action' );
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
