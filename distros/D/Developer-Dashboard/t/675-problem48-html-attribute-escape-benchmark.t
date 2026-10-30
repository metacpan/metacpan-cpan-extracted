#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-html-attribute-escape-benchmark' );
my ( $help_out, $help_err, $help_exit ) = _run('--help');
is( $help_exit, 0, 'help exits successfully' );
like( $help_out, qr/--iterations POSITIVE_N/, 'help documents iteration count' );
like( $help_out, qr/--runs ODD_N/, 'help documents odd run count' );
is( $help_err, '', 'help emits no diagnostics' );

my ( $invalid_out, $invalid_err, $invalid_exit ) = _run( '--runs', '2' );
isnt( $invalid_exit, 0, 'even run counts are rejected' );
like( $invalid_err, qr/odd positive integer/, 'invalid run count explains the constraint' );

my ( $bench_out, $bench_err, $bench_exit ) = _run( '--iterations', '100', '--runs', '3' );
is( $bench_exit, 0, 'small attribute benchmark completes' );
like( $bench_out, qr/input=nav\/static-1\.tt .*parity=yes/, 'benchmark checks routine navigation-attribute parity' );
like( $bench_out, qr/input=quote-heavy .*parity=yes/, 'benchmark checks escaped-attribute parity' );
like( $bench_out, qr/xs_backend=(?:loaded|unavailable)/, 'benchmark reports native backend availability' );
like( $bench_out, qr/perl_baseline=pure-perl/, 'benchmark reports an independent pure-Perl reference path' );
is( $bench_err, '', 'successful benchmark emits no diagnostics' );

done_testing;

# _run(@arguments)
# Runs the attribute-escape benchmark with captured stdout and stderr.
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

675-problem48-html-attribute-escape-benchmark.t - test the HTML attribute benchmark

=head1 PURPOSE

Checks help, argument validation, output parity reporting, and native-backend
availability reporting for the reproducible Problem 48 attribute-escape
benchmark.

=head1 WHY IT EXISTS

The benchmark compares the established Perl attribute path with the single-pass
XS implementation. This contract keeps its command interface and parity checks
available for repeated Docker measurements.

=head1 WHEN TO USE

Run when changing the attribute benchmark script, its command-line options, or
its output contract.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/675-problem48-html-attribute-escape-benchmark.t

=head1 WHAT USES IT

The repository test suite runs this contract test. The benchmark remains an
explicit research command and is not loaded by the dashboard runtime.

=head1 EXAMPLES

  d2 docker compose exec dev prove -lv t/675-problem48-html-attribute-escape-benchmark.t

=cut
