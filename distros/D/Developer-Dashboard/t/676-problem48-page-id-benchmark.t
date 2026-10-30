#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-page-id-benchmark' );

my ( $help_out, $help_err, $help_exit ) = _run('--help');
is( $help_exit, 0, 'page-id benchmark help exits successfully' );
like( $help_out, qr/--iterations POSITIVE_N/, 'help documents iteration count' );
like( $help_out, qr/--runs ODD_N/, 'help documents odd sample count' );
is( $help_err, '', 'help emits no diagnostics' );

my ( $invalid_out, $invalid_err, $invalid_exit ) = _run( '--runs', '2' );
isnt( $invalid_exit, 0, 'even run counts are rejected' );
like( $invalid_err, qr/odd positive integer/, 'invalid run count explains the constraint' );

my ( $bench_out, $bench_err, $bench_exit ) = _run( '--iterations', '100', '--runs', '3' );
is( $bench_exit, 0, 'small page-id benchmark completes' );
is( $bench_err, '', 'successful benchmark emits no diagnostics' );
like( $bench_out, qr/input=nav\/item-NNN\.tt .*parity=yes/, 'benchmark checks common nav id parity' );
like( $bench_out, qr/case=nav\/a\.\.b\.tt fast_path=no parity=yes/,
    'benchmark reports unusual valid id fallback' );
like( $bench_out, qr/old_ms_per_call=[0-9.]+ fast_ms_per_call=[0-9.]+ speedup=[0-9.]+x/,
    'benchmark reports timing and speedup' );

done_testing;

# _run(@arguments)
# Runs the page-id benchmark and captures its output for command-contract tests.
# Input: benchmark command-line arguments.
# Output: stdout, stderr, and process exit status.
sub _run {
    my (@arguments) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system $^X, $script, @arguments;
    };
    return ( $stdout, $stderr, $exit );
}

__END__

=head1 NAME

676-problem48-page-id-benchmark.t - test the PageStore id benchmark

=head1 PURPOSE

Checks help, argument validation, parity reporting, fallback-case reporting,
and speed output for the repeatable Problem 48 page-id validation benchmark.

=head1 WHY IT EXISTS

The saved-page benchmark identified PageStore id normalization as a hot helper.
This test ensures the comparison command keeps its documented interface and
checks parity before it times either implementation.

=head1 WHEN TO USE

Run whenever the page-id benchmark or its command-line options change.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/676-problem48-page-id-benchmark.t

=head1 WHAT USES IT

The normal Perl test suite discovers this test; the benchmark itself is an
opt-in research command and is not loaded by the dashboard runtime.

=head1 EXAMPLES

  d2 docker compose exec dev prove -lv t/676-problem48-page-id-benchmark.t

=cut
