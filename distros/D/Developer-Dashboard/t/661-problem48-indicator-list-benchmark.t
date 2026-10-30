use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-indicator-list-benchmark' );

my ( $help_out, $help_err, $help_exit ) = _run( $script, '--help' );
is( $help_exit, 0, '--help succeeds' );
like( $help_out, qr/--indicators N/, 'help documents indicator count' );
like( $help_out, qr/--layers 1|2/, 'help documents one- and two-layer fixtures' );
is( $help_err, '', '--help emits no stderr' );

my ( $invalid_out, $invalid_err, $invalid_exit ) = _run( $script, '--runs', '2' );
isnt( $invalid_exit, 0, 'even run count is rejected' );
like( $invalid_err, qr/Usage:/, 'invalid benchmark options show usage' );

for my $layers ( 1, 2 ) {
    my ( $out, $err, $exit ) = _run(
        $script,
        '--indicators', '3',
        '--runs',       '1',
        '--layers',     $layers,
    );
    is( $exit, 0, "small $layers-layer benchmark succeeds" );
    like( $out, qr/exact_parity=yes/, "small $layers-layer benchmark preserves exact output" );
    is( $err, '', "small $layers-layer benchmark emits no warnings" );
}

done_testing();

# _run(@argv)
# Executes the benchmark and captures output and wait status.
# Input: benchmark path followed by command-line arguments.
# Output: stdout, stderr, and exit status from Capture::Tiny.
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

661-problem48-indicator-list-benchmark.t - check the indicator-list benchmark contract

=head1 PURPOSE

Tests the indicator-list benchmark's CLI validation and runs exact-parity
smoke measurements with both one and two runtime layers.

=head1 WHY IT EXISTS

The benchmark reproduces the measured optimization in an isolated temporary
home. This test makes sure future edits keep the benchmark runnable and checks
that its fixture variants do not emit warnings or report mismatched results.

=head1 WHEN TO USE

Run this test when editing the benchmark's fixture construction, options, or
old-versus-new result comparison.

=head1 HOW TO USE

  prove -lv t/661-problem48-indicator-list-benchmark.t

=head1 WHAT USES IT

The repository test suite exercises the benchmark contract. Problem 48
research uses its CLI to measure the live dashboard indicator-list path.

=head1 EXAMPLES

Run in the isolated Docker benchmark service:

  d2 docker compose -p dd-problem48-bench -f /tmp/d2-problem48-bench.yml -f /tmp/d2-problem48-init.yml run --rm bench sh -lc 'cd /checkout && prove -lv t/661-problem48-indicator-list-benchmark.t'

=cut
