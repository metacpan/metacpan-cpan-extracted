package Local::CollectorFixture;

use strict;
use warnings;
use utf8;

use Exporter qw(import);
use Time::HiRes ();

our @EXPORT_OK = qw(wait_for_managed_loop);

# wait_for_managed_loop($runner, $pid, $name, %options)
# Waits until a CollectorRunner recognizes one native-process fixture child as the
# managed collector loop it is standing in for. A fixture that writes only a
# pidfile leaves the child's process title as the sole evidence of that
# identity, and the child adopts the title after it starts, so the runner's
# answer changes under it; every caller must therefore wait for the runner's own
# predicate to agree before exercising behaviour that depends on it.
# The budget is wall-clock, not an iteration count, so a starved host really does
# get the whole grace instead of however long a fixed number of sleeps happens to
# take.
# Input: CollectorRunner instance, child-process PID integer, collector name string, and
#        optional timeout => seconds (default 30) and interval => seconds
#        (default 0.05) between probes, plus ready => true to wait not just for
#        recognition but for the child to have finished starting.
# Output: true once the runner recognizes the child process as the managed loop; false if
#         the wall-clock budget expired first, so the caller can fail loudly
#         instead of misreporting the setup failure as a behaviour failure.
#
# The ready option exists because recognition alone is not readiness. A loop
# child is recognizable from the moment it is spawned - its identity marker
# travels in the spawn environ, visible in /proc from birth - but it has not
# finished starting then: it still has to load its modules and install its
# signal handlers. Signalling it in that window kills it with the default
# disposition instead of its orderly handler, so a test that signals the
# child right after the wait (to assert on what the handler records) must
# wait for startup evidence too: the adopted process title, set next to the
# handler installation, or a first-tick loop state of 'running'. Fixtures
# must NOT pass ready: a hand-built fixture child writes no loop state, and
# under qemu its title is never observable, so a ready wait for one can never
# succeed - and fixtures only need identification, since they assert on
# termination, not on what the handler records.
sub wait_for_managed_loop {
    my ( $runner, $pid, $name, %options ) = @_;
    my $timeout  = defined $options{timeout}  ? $options{timeout}  : 30;
    my $interval = defined $options{interval} ? $options{interval} : 0.05;
    my $ready    = $options{ready} ? 1 : 0;
    my $deadline = Time::HiRes::time() + $timeout;

    while (1) {
        if ( $runner->_is_managed_loop( $pid, $name ) ) {
            return 1 if !$ready;
            return 1 if _loop_is_ready( $runner, $pid, $name );
        }
        return 0 if Time::HiRes::time() >= $deadline;
        Time::HiRes::sleep($interval);
    }
}

# _loop_is_ready($runner, $pid, $name)
# Reports whether a recognized loop child has finished starting: it has
# adopted its process title, or its loop state has reached 'running' on its
# first tick. Either is written next to the signal-handler installation, so
# either proves a signal sent now will reach the handler rather than the
# default disposition. The title covers a host where titles are observable;
# the state covers one where they are not (qemu user-mode emulation).
# Input: CollectorRunner instance, child-process PID integer, collector name string.
# Output: boolean true when startup evidence is present.
sub _loop_is_ready {
    my ( $runner, $pid, $name ) = @_;
    my $title = eval { $runner->_read_process_title($pid) };
    return 1 if defined $title && $title ne '' && $title eq $runner->_process_title($name);
    my $state = eval { $runner->loop_state($name) };
    return 1 if $state && ref($state) eq 'HASH' && ( $state->{status} || '' ) eq 'running';
    return 0;
}

1;

__END__

=pod

=head1 NAME

Local::CollectorFixture - wait helper for suite fixtures that stand in for collector loops

=head1 PURPOSE

This helper holds the one wait that every hand-built collector loop fixture
needs: it blocks until a C<Developer::Dashboard::CollectorRunner> recognizes a
native child process as the managed collector loop that fixture is pretending to be, and
reports failure on a wall-clock budget rather than waiting for ever.

=head2 wait_for_managed_loop($runner, $pid, $name, %options)

What it does:
Probes the runner's own managed-loop predicate until it agrees that C<$pid> is
the collector loop C<$name>, sleeping between probes and giving up when the
wall-clock budget expires.

Input arguments:
=over 4
=item * C<$runner> - C<Developer::Dashboard::CollectorRunner> instance
=item * C<$pid> - PID of the fixture's native child process
=item * C<$name> - collector name the child is standing in for
=item * C<%options> - optional C<timeout> in seconds (default 30) and C<interval> in seconds between probes (default 0.05), plus C<ready> to wait not just for recognition but for the child to have finished starting (its adopted title, or a first-tick loop state of C<running>). Pass C<ready> only for a real loop started by C<start_loop>; a hand-built fixture child writes no loop state, and under qemu its title is never observable, so a ready wait for one can never succeed.
=back

Expected output:
A true value once the runner recognizes the child process, or false when the budget
expired first.

=head1 WHY IT EXISTS

A fixture that records a collector by hand writes a pidfile and nothing else, so
no loop state exists to confirm the loop's identity and the child's process title
is the only remaining evidence. The child adopts that title after it starts, which
means a CPU-starved host lets the fixture probe the runner before the child looks
like anything at all. Two suite assertions failed exactly that way on constrained
hosts while passing everywhere else. The obvious repair - poll and try again -
does not work, because the listing path deletes the pidfile of any loop it cannot
recognize, so the first probe destroys the fixture and every later iteration
inspects nothing. Waiting for recognition before the first probe is the only
order that holds, and keeping that wait in one helper stops each fixture
reinventing it slightly differently.

=head1 WHEN TO USE

Use this helper in any repository test that launches a stand-in collector loop
with GoRoutine's native process API, records it with a bare pidfile, and then asks the runner to list, stop, or
otherwise act on that loop.

=head1 HOW TO USE

Load it from C<t/lib>, launch the child through GoRoutine's process API so it
adopts the runner's process title for the collector, write the pidfile, then call C<wait_for_managed_loop> and assert
its result before exercising the behaviour under test.

=head1 WHAT USES IT

The collector lifecycle fixtures in the core unit tests and the coverage-closure
tests use this helper, and the fixture recognition contract test asserts they
keep using it.

=head1 EXAMPLES

Example 1:

  use Local::CollectorFixture qw(wait_for_managed_loop);
  ok(
      wait_for_managed_loop( $runner, $child, 'my.collector' ),
      'the fixture child is identifiable as a managed loop',
  );
  is( $runner->stop_loop('my.collector'), $child, 'stop_loop terminates it' );

Example 2:

  # A short budget when the expected answer is "never recognized".
  is( wait_for_managed_loop( $runner, $child, 'my.collector', timeout => 0.2 ), 0 );

=cut
