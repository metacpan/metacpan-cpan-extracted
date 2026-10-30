use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-collector-config-benchmark' );

my ( $help_out, $help_err, $help_exit ) = _run('--help');
is( $help_exit, 0, '--help exits successfully' );
like( $help_out, qr/--skills N/, '--help describes the skill-count option' );
is( $help_err, '', '--help emits no diagnostics' );

my ( $bad_out, $bad_err, $bad_exit ) = _run( '--runs', '2' );
isnt( $bad_exit, 0, 'even run counts are rejected' );
like( $bad_err, qr/odd positive integer/, 'invalid run count explains the requirement' );

my ( $bench_out, $bench_err, $bench_exit ) = _run( '--skills', '3', '--runs', '1' );
is( $bench_exit, 0, 'small collector comparison succeeds' );
like( $bench_out, qr/exact_parity=yes/, 'benchmark preserves canonical collector output' );
like( $bench_out, qr/legacy_entry_enumerations=2 shared_entry_enumerations=1/,
    'benchmark confirms collector assembly reuses the merged entry list' );
like( $bench_out, qr/legacy_median_ms=[0-9.]+ shared_median_ms=[0-9.]+/,
    'benchmark reports both measured medians' );
is( $bench_err, '', 'successful benchmark emits no warnings or errors' );

done_testing;

# _run(@arguments)
# Runs the benchmark helper as a child and captures its output and wait status.
# Input: command-line argument strings for the helper.
# Output: stdout, stderr, and child exit status.
sub _run {
    my (@arguments) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system $^X, $script, @arguments;
        return $? >> 8;
    };
    return ( $stdout, $stderr, $exit );
}

__END__

=pod

=head1 NAME

662-problem48-collector-config-benchmark.t - test collector config benchmark

=head1 PURPOSE

Checks the Problem 48 collector-config benchmark's command-line validation,
canonical output parity, measured output fields, and entry-enumeration counts.

=head1 WHY IT EXISTS

The benchmark is the repeatable evidence for sharing installed skill config
entries between merged configuration and collector assembly. Its regression
test ensures the comparison continues to represent both the old double-read
flow and the optimized shared-entry flow without changing collector output.

=head1 WHEN TO USE

Run this test when changing the benchmark, the Config collector assembly path,
or the optional skill-config-entry output contract.

=head1 HOW TO USE

  prove -lv t/662-problem48-collector-config-benchmark.t

The test runs help, invalid input, and a three-skill one-sample workload.

=head1 WHAT USES IT

The repository test suite runs this test. Problem 48 performance research uses
the benchmark itself; the Dashboard runtime does not invoke it.

=head1 EXAMPLES

Run the focused test inside the isolated benchmark container:

  d2 docker compose -f /tmp/d2-problem48-bench.yml run --rm bench prove -lv t/662-problem48-collector-config-benchmark.t

Run all repository tests after changing performance behavior:

  prove -lr t

=cut
