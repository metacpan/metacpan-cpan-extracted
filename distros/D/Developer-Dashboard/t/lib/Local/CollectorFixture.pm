package Local::CollectorFixture;

use strict;
use warnings;
use utf8;

use Exporter qw(import);
use Time::HiRes ();

our @EXPORT_OK = qw(wait_for_managed_loop);

# wait_for_managed_loop($runner, $pid, $name, %options)
# Waits until a CollectorRunner recognizes one forked fixture child as the
# managed collector loop it is standing in for. A fixture that writes only a
# pidfile leaves the child's process title as the sole evidence of that
# identity, and the child adopts the title after the fork, so the runner's
# answer changes under it; every caller must therefore wait for the runner's own
# predicate to agree before exercising behaviour that depends on it.
# The budget is wall-clock, not an iteration count, so a starved host really does
# get the whole grace instead of however long a fixed number of sleeps happens to
# take.
# Input: CollectorRunner instance, child pid integer, collector name string, and
#        optional timeout => seconds (default 30) and interval => seconds
#        (default 0.05) between probes.
# Output: true once the runner recognizes the child as the managed loop; false if
#         the wall-clock budget expired first, so the caller can fail loudly
#         instead of misreporting the setup failure as a behaviour failure.
sub wait_for_managed_loop {
    my ( $runner, $pid, $name, %options ) = @_;
    my $timeout  = defined $options{timeout}  ? $options{timeout}  : 30;
    my $interval = defined $options{interval} ? $options{interval} : 0.05;
    my $deadline = Time::HiRes::time() + $timeout;

    while (1) {
        return 1 if $runner->_is_managed_loop( $pid, $name );
        return 0 if Time::HiRes::time() >= $deadline;
        Time::HiRes::sleep($interval);
    }
}

1;

__END__

=pod

=head1 NAME

Local::CollectorFixture - wait helper for suite fixtures that stand in for collector loops

=head1 PURPOSE

This helper holds the one wait that every hand-built collector loop fixture
needs: it blocks until a C<Developer::Dashboard::CollectorRunner> recognizes a
forked child as the managed collector loop that fixture is pretending to be, and
reports failure on a wall-clock budget rather than waiting for ever.

=head2 wait_for_managed_loop($runner, $pid, $name, %options)

What it does:
Probes the runner's own managed-loop predicate until it agrees that C<$pid> is
the collector loop C<$name>, sleeping between probes and giving up when the
wall-clock budget expires.

Input arguments:
=over 4
=item * C<$runner> - C<Developer::Dashboard::CollectorRunner> instance
=item * C<$pid> - pid of the forked fixture child
=item * C<$name> - collector name the child is standing in for
=item * C<%options> - optional C<timeout> in seconds (default 30) and C<interval> in seconds between probes (default 0.05)
=back

Expected output:
A true value once the runner recognizes the child, or false when the budget
expired first.

=head1 WHY IT EXISTS

A fixture that records a collector by hand writes a pidfile and nothing else, so
no loop state exists to confirm the loop's identity and the child's process title
is the only remaining evidence. The child adopts that title after the fork, which
means a CPU-starved host lets the fixture probe the runner before the child looks
like anything at all. Two suite assertions failed exactly that way on constrained
hosts while passing everywhere else. The obvious repair - poll and try again -
does not work, because the listing path deletes the pidfile of any loop it cannot
recognize, so the first probe destroys the fixture and every later iteration
inspects nothing. Waiting for recognition before the first probe is the only
order that holds, and keeping that wait in one helper stops each fixture
reinventing it slightly differently.

=head1 WHEN TO USE

Use this helper in any repository test that forks a stand-in collector loop
child, records it with a bare pidfile, and then asks the runner to list, stop, or
otherwise act on that loop.

=head1 HOW TO USE

Load it from C<t/lib>, fork the child so it adopts the runner's process title for
the collector, write the pidfile, then call C<wait_for_managed_loop> and assert
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
