use strict;
use warnings;

use Capture::Tiny qw(capture);
use Config ();
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-inline-xs-benchmark' );

my ( $help_out, $help_err, $help_exit ) = _run( '--help' );
is( $help_exit, 0, '--help exits before loading optional native modules' );
like( $help_out, qr/--iterations N/, '--help documents the workload size' );
like( $help_out, qr/--runs ODD_N/, '--help documents the sample count' );
is( $help_err, '', '--help emits no diagnostics' );

my ( $bad_out, $bad_err, $bad_exit ) = _run( '--runs', '2' );
isnt( $bad_exit, 0, 'an even sample count is rejected' );
like( $bad_err, qr/odd positive integer/, 'invalid sample count explains the requirement' );

my $native_available = eval {
    require Developer::Dashboard::Crypto::PBKDF2;
    Developer::Dashboard::Crypto::PBKDF2->native_available
      or die "OpenSSL XS backend is unavailable\n";
    1;
};
SKIP: {
    skip 'the compiled XS extension or OpenSSL backend is unavailable', 4 if !$native_available;
    my ( $bench_out, $bench_err, $bench_exit ) = _run( '--iterations', '32', '--runs', '1' );
    is( $bench_exit, 0, 'small parity benchmark runs when the XS and OpenSSL backends are available' );
    like( $bench_out, qr/all_digests_match=yes/, 'Perl and XS digests match' );
    like( $bench_out, qr/XS median_ms=/, 'benchmark reports the production XS median' );
    is( $bench_err, '', 'successful parity benchmark emits no warnings or errors' );
}

done_testing;

# _run(@arguments)
# Executes the benchmark script with the active Perl and captures both output
# streams so command validation and optional native execution remain visible.
# Input: command-line argument strings.
# Output: stdout, stderr, and the child process exit status.
sub _run {
    my (@arguments) = @_;
    local $ENV{PERL5LIB} = join $Config::Config{path_sep}, grep { defined && !ref } @INC;
    my ( $stdout, $stderr, $exit ) = capture {
        system $^X, $script, @arguments;
    };
    return ( $stdout, $stderr, $exit );
}

__END__

=pod

=head1 NAME

657-problem48-inline-xs-benchmark.t - verify the Perl and XS benchmark

=head1 PURPOSE

Checks the benchmark's dependency-free help and argument-validation paths,
then verifies digest parity when the compiled Dashboard XS extension and
OpenSSL backend are available.

=head1 WHY IT EXISTS

Problem 48 requires evidence for native acceleration choices. This test keeps
the reproducible Perl-versus-XS comparison runnable and guards against accepting
timings whose implementations produce different PBKDF2 digests.

=head1 WHEN TO USE

Run this test when changing the XS benchmark's options, native binding,
or output-parity checks.

=head1 HOW TO USE

  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/657-problem48-inline-xs-benchmark.t

The functional comparison is skipped only when the compiled XS extension or
OpenSSL backend is unavailable. Compilation errors and digest mismatches remain
failures.

=head1 WHAT USES IT

The repository test suite runs this file. The manual Problem 48 benchmark is
not loaded by Developer Dashboard at runtime.

=head1 EXAMPLES

Run the comparison in the development Docker container after building the XS
extension:

  d2 docker compose exec dev perl script/problem48-inline-xs-benchmark --iterations 1000 --runs 3

=cut
