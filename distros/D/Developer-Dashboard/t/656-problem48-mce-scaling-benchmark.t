use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-mce-scaling-benchmark' );

my ( $help_out, $help_err, $help_exit ) = _run( $script, '--help' );
is( $help_exit, 0, '--help exits successfully without requiring optional MCE' );
like( $help_out, qr/--skills N,N,.../, '--help lists configurable workload sizes' );
like( $help_out, qr/--workers N/, '--help lists worker count' );
is( $help_err, '', '--help does not write diagnostics to stderr' );

my ( $runs_out, $runs_err, $runs_exit ) = _run( $script, '--runs', '2' );
isnt( $runs_exit, 0, 'an even run count is rejected' );
like( $runs_err, qr/Usage:/, 'invalid run count reports usage' );

my ( $skills_out, $skills_err, $skills_exit ) = _run( $script, '--skills', '50,nope' );
isnt( $skills_exit, 0, 'a malformed skill-count list is rejected' );
like( $skills_err, qr/positive integers/, 'malformed skill counts explain the required format' );

my $mce_available = eval { require MCE::Map; 1 };
SKIP: {
    skip 'MCE is an optional benchmark dependency', 3 if !$mce_available;
    my ( $benchmark_out, $benchmark_err, $benchmark_exit ) = _run(
        $script, '--skills', '3', '--runs', '1', '--workers', '2',
    );
    is( $benchmark_exit, 0, 'a small benchmark runs with MCE available' );
    like( $benchmark_out, qr/exact_ordered_parity=yes/, 'benchmark reports verified ordered-output parity' );
    is( $benchmark_err, '', 'successful benchmark reports no stderr warnings' );
}

done_testing;

# _run(@argv)
# Executes the benchmark helper with captured standard streams.
# Input: command-line argument list for the helper.
# Output: stdout, stderr, and wait status from Capture::Tiny.
sub _run {
    my ( $program, @argv ) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system $^X, $program, @argv;
    };
    return ( $stdout, $stderr, $exit );
}

__END__

=pod

=head1 NAME

656-problem48-mce-scaling-benchmark.t - verify MCE scaling benchmark CLI guards

=head1 PURPOSE

This test checks the benchmark's help and argument validation without running
its comparatively expensive filesystem and parallel-read workload.

=head1 WHY IT EXISTS

The benchmark is used to make performance decisions in Problem 48. Invalid
workload sizes or sample counts could otherwise produce misleading timings or
hide test setup errors.

=head1 WHEN TO USE

Run this test whenever the MCE benchmark's command-line options, startup
behavior, or usage text change.

=head1 HOW TO USE

  prove -lv t/656-problem48-mce-scaling-benchmark.t

The test launches only C<--help> and invalid-argument paths; it does not need
MCE installed.

=head1 WHAT USES IT

The repository test suite executes this file. The MCE benchmark itself is
manual research tooling and does not call this test at runtime.

=head1 EXAMPLES

Run the focused test in Docker:

  d2 docker compose -p dd-problem48-bench -f /tmp/d2-problem48-bench.yml -f /tmp/d2-problem48-init.yml run --rm bench sh -lc 'cd /checkout && prove -lv t/656-problem48-mce-scaling-benchmark.t'

Run it as part of the complete test suite:

  prove -lr t

=cut
