use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-inline-html-escape-benchmark' );
my ( $help_out, $help_err, $help_exit ) = _run('--help');
is( $help_exit, 0, 'help exits before optional native benchmark modules load' );
like( $help_out, qr/--runs ODD_N/, 'help documents the sample count option' );
is( $help_err, '', 'help emits no diagnostics' );

my ( $invalid_out, $invalid_err, $invalid_exit ) = _run('--runs', '2');
isnt( $invalid_exit, 0, 'even sample counts are rejected' );
like( $invalid_err, qr/odd positive integer/, 'invalid run count explains the constraint' );

my $native_available = eval { require Inline; 1 };
SKIP: {
    skip 'Inline::C and a compiler are optional benchmark dependencies', 9 if !$native_available;
    my ( $bench_out, $bench_err, $bench_exit ) = _run('--runs', '1');
    is( $bench_exit, 0, 'small native escaping benchmark completes' );
    like( $bench_out, qr/chunked_parity=yes/, 'chunk-scanning XS candidate matches Perl output and UTF-8 flags' );
    like( $bench_out, qr/lookup_table_parity=yes/, 'lookup-table XS candidate matches Perl output and UTF-8 flags' );
    like( $bench_out, qr/adaptive_dispatch_parity=yes/, 'production dispatch policy matches Perl output and UTF-8 flags' );
    like( $bench_out, qr/workload=dense/, 'benchmark includes dense escapable input' );
    like( $bench_out, qr/workload=sparse/, 'benchmark includes sparse escapable input' );
    like( $bench_out, qr/workload=prefix_sparse/, 'benchmark includes input with an early but rare escape' );
    like( $bench_out, qr/workload=plain/, 'benchmark includes text with no escapable bytes' );
    is( $bench_err, '', 'successful benchmark emits no diagnostics' );
}

done_testing;

# _run(@arguments)
# Runs the native HTML-escape benchmark while capturing its two output streams.
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

664-problem48-inline-html-benchmark.t - test the native HTML escape benchmark

=head1 PURPOSE

Checks benchmark help, argument validation, and exact output parity for the
Inline::C chunk-scanning and lookup-table candidates plus reporting for dense,
late-sparse, early-sparse, and plain-text distributions when optional compiler
dependencies are available. It also verifies the adaptive production dispatch
candidate's exact parity marker.

=head1 WHY IT EXISTS

Problem 48 is evaluating whether native scanning can improve the measured
HTML body escaper without changing bytes or Perl UTF-8 flags.

=head1 WHEN TO USE

Run when changing the Inline::C HTML escaping benchmark or its options.

=head1 HOW TO USE

  prove -lv t/664-problem48-inline-html-benchmark.t

=head1 WHAT USES IT

The repository test suite runs this benchmark contract test; production code
does not load the research script.

=head1 EXAMPLES

  d2 docker compose -p dd-problem48-profile-next -f /tmp/d2-problem48-bench.yml run --rm bench prove -lv t/664-problem48-inline-html-benchmark.t

=cut
