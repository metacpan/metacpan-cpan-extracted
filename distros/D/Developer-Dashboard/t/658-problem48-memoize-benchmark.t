use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-memoize-benchmark' );
my ( $help_out, $help_err, $help_exit ) = _run('--help');
is( $help_exit, 0, '--help exits successfully' );
like( $help_out, qr/uncached, request-scoped hash, and Memoize/, '--help names the three cache strategies' );
is( $help_err, '', '--help emits no diagnostics' );

my ( $bad_out, $bad_err, $bad_exit ) = _run( '--runs', '2' );
isnt( $bad_exit, 0, 'even benchmark run counts are rejected' );
like( $bad_err, qr/odd positive integer/, 'invalid run count reports the constraint' );

my ( $bench_out, $bench_err, $bench_exit ) = _run( '--paths', '3', '--runs', '1' );
is( $bench_exit, 0, 'small filesystem benchmark completes' );
like( $bench_out, qr/exact_parity=yes/, 'all cache strategies preserve exact output' );
like( $bench_out, qr/symlink_refresh=yes/, 'each strategy observes symlink changes after an operation boundary' );
is( $bench_err, '', 'successful benchmark emits no warnings or errors' );

done_testing;

# _run(@arguments)
# Executes the benchmark in a fresh Perl process and captures its output.
# Input: command-line argument strings.
# Output: stdout, stderr, and process exit status.
sub _run {
    my (@arguments) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system $^X, $script, @arguments;
    };
    return ( $stdout, $stderr, $exit );
}

__END__

=pod

=head1 NAME

658-problem48-memoize-benchmark.t - verify request-scoped Memoize comparison

=head1 PURPOSE

Tests the Memoize benchmark's command-line handling, output parity, and cache
refresh behavior after a filesystem symlink changes.

=head1 WHY IT EXISTS

Problem 48 must evaluate Memoize without accepting stale filesystem results.
This test ensures the manual timing utility clears its cache at each operation
boundary and compares the result to the uncached and local-hash implementations.

=head1 WHEN TO USE

Run whenever the memoization benchmark or its request-boundary invalidation
changes.

=head1 HOW TO USE

  prove -lv t/658-problem48-memoize-benchmark.t

=head1 WHAT USES IT

The repository test suite runs this regression. The benchmark is research
tooling and is not loaded by the dashboard runtime.

=head1 EXAMPLES

  d2 docker compose -p dd-problem48-bench -f /tmp/d2-problem48-bench.yml -f /tmp/d2-problem48-init.yml run --rm bench sh -lc 'cd /checkout && prove -lv t/658-problem48-memoize-benchmark.t'

=cut
