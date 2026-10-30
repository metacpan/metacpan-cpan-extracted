use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Test::More;

my $script = "$Bin/../script/problem48-stash-decode-benchmark";
my $repo_lib = abs_path("$Bin/../lib");

my ( $help_stdout, $help_stderr, $help_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--help' );
    return $? >> 8;
};
is( $help_exit, 0, 'STASH decoder benchmark help succeeds' );
is( $help_stderr, q{}, 'STASH decoder benchmark help emits no stderr' );
like( $help_stdout, qr/--iterations N.*--runs ODD_N/s,
    'STASH decoder benchmark documents workload controls' );

my ( $run_stdout, $run_stderr, $run_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 3, '--runs', 3 );
    return $? >> 8;
};
is( $run_exit, 0, 'small STASH decoder benchmark completes' );
is( $run_stderr, q{}, 'STASH decoder benchmark emits no stderr' );
like( $run_stdout, qr/iterations=3 runs=3 .*median_us_per_call=[0-9.]+/,
    'benchmark reports sample size and median' );
like( $run_stdout, qr/result_sha256=[0-9a-f]{64} exact_repeat_parity=yes/,
    'benchmark verifies repeated decoded data is identical' );

my ( $invalid_stdout, $invalid_stderr, $invalid_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--runs', 2 );
    return $? >> 8;
};
isnt( $invalid_exit, 0, 'benchmark rejects an even run count' );
like( $invalid_stderr, qr/--runs must be a positive odd integer/,
    'invalid run count reports the correction' );

done_testing;

__END__

=pod

=head1 NAME

674-problem48-stash-decode-benchmark.t - tests the STASH decode benchmark

=head1 PURPOSE

Checks that the focused legacy STASH benchmark validates options, produces
repeatable decoded values, reports a timing median, and fails clearly for an
invalid sample count.

=head1 WHY IT EXISTS

Problem 48 evaluates optimizations one workload at a time. This test protects
the reproducibility of the Safe-evaluation versus bounded-memoization
comparison from malformed measurements or silently changed output.

=head1 WHEN TO USE

Run this test when changing the benchmark interface, its legacy STASH fixture,
source selection, output digest, or sample aggregation.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/674-problem48-stash-decode-benchmark.t

=head1 WHAT USES IT

The Problem 48 performance research cycle runs this test before using the
benchmark to compare v5.88 with the current source tree.

=head1 EXAMPLES

Run the regression test in the development container as shown above. The
benchmark it protects accepts C<--iterations N> and C<--runs ODD_N>, and
selects its Perl source library with C<P48_LIB>.

=cut
