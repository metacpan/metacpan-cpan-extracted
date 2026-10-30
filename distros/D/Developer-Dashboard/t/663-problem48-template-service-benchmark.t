#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-template-service-benchmark' );

my ( $help_out, $help_err, $help_exit ) = _run('--help');
is( $help_exit, 0, '--help exits successfully' );
like( $help_out, qr/fresh Template Toolkit setup with request-local service and worker-local compiled-template reuse/, '--help explains the benchmark comparison' );
is( $help_err, '', '--help emits no diagnostics' );

my ( $bad_out, $bad_err, $bad_exit ) = _run( '--runs', '2' );
isnt( $bad_exit, 0, 'even run counts are rejected' );
like( $bad_err, qr/odd positive integer/, 'invalid run count explains its constraint' );

my ( $workload_out, $workload_err, $workload_exit ) = _run( '--workload', 'unknown' );
isnt( $workload_exit, 0, 'unknown workload is rejected' );
like( $workload_err, qr/repeated.*distinct/, 'invalid workload explains supported modes' );

my ( $bench_out, $bench_err, $bench_exit ) = _run( '--iterations', '3', '--runs', '3', '--workload', 'distinct' );
is( $bench_exit, 0, 'small benchmark run completes' );
like( $bench_out, qr/parity=exact/, 'fresh and cached renders have exact output parity' );
like( $bench_out, qr/requests=3 renders_per_request=5 runs=3 parity=exact roots=one workload=distinct/, 'benchmark reports request scope and selected workload' );
like( $bench_out, qr/fresh_ms_per_render=[0-9.]+ cached_ms_per_render=[0-9.]+ speedup=[0-9.]+x/, 'benchmark reports per-render medians and ratio' );
is( $bench_err, '', 'successful benchmark emits no diagnostics' );

done_testing;

# _run(@arguments)
# Executes the benchmark with the current Perl and captures process output.
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

663-problem48-template-service-benchmark.t - verify the Template Toolkit comparison utility

=head1 PURPOSE

Checks argument validation, exact-render parity, and measurement output from
the Problem 48 Template Toolkit service benchmark.

=head1 WHY IT EXISTS

The benchmark is the repeatable evidence for request-scoped Template Toolkit
service reuse and worker-local compiled scalar-template reuse under
repeated-source and distinct-source request workloads. This test prevents
its interface, output parity, or workload options from silently disappearing.

=head1 WHEN TO USE

Run this test after changing the benchmark or PageRuntime's Template Toolkit
service and compiled scalar-template caches.

=head1 HOW TO USE

  prove -lv t/663-problem48-template-service-benchmark.t

=head1 WHAT USES IT

The repository test suite runs this check; operators can run the benchmark
directly to compare five renders with request-scoped service and worker-local
compiled-template reuse. The repeated
workload uses the same scalar body five times in one request; the distinct
workload uses five different bodies.

=head1 EXAMPLES

  perl script/problem48-template-service-benchmark --iterations 500 --runs 21 --workload repeated
  perl script/problem48-template-service-benchmark --iterations 500 --runs 21 --workload distinct
  d2 docker compose -p dd-problem48-coverage -f /tmp/d2-problem48-bench.yml -f /tmp/d2-problem48-init.yml run --rm --no-deps bench sh -lc 'cd /checkout && prove -lv t/663-problem48-template-service-benchmark.t'

=cut
