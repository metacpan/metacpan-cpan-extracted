use strict;
use warnings;

use Capture::Tiny qw(capture);
use Test::More;

my ( $stdout, $stderr, $exit ) = capture {
    system(
        $^X,
        'script/problem48-skill-layer-inventory-benchmark',
        '--skills', 3,
        '--runs',   3,
    );
};

is( $exit, 0, 'the skill-layer candidate benchmark completes successfully' );
is( $stderr, '', 'the skill-layer benchmark emits no warnings or errors' );
like( $stdout, qr/skills=3 layers=2 lookups=3 runs=3 exact_layer_parity=yes/, 'the benchmark verifies exact ordered-layer parity' );
like( $stdout, qr/root_scan_baseline_ms=[0-9.]+ inventory_candidate_ms=[0-9.]+ speedup=[0-9.]+x/, 'the benchmark reports both timings and their ratio' );

done_testing();

__END__

=pod

=head1 NAME

666-problem48-skill-layer-inventory-benchmark.t - verify the inventory candidate benchmark

=head1 PURPOSE

This test runs the Problem 48 skill-layer benchmark with a small isolated
fixture and verifies success, clean diagnostics, parity, and timing output.

=head1 WHY IT EXISTS

The benchmark is retained as evidence for a rejected performance candidate.
Its correctness and output contract should remain executable so future
measurements use the same paired, parity-checked method.

=head1 WHEN TO USE

Run this test when editing the skill-layer inventory benchmark or its CLI
output.

=head1 HOW TO USE

Run it through the project's Docker test service:

  prove -lv t/666-problem48-skill-layer-inventory-benchmark.t

=head1 WHAT USES IT

The Problem 48 research log uses this test to guard the benchmark harness. The
application runtime does not invoke this benchmark.

=head1 EXAMPLES

The test requests three synthetic skills and three alternating runs, then
checks that the output states exact parity and includes both timing medians.

=cut
