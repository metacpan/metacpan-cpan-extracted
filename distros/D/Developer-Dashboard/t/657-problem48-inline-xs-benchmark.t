use strict;
use warnings;

use Capture::Tiny qw(capture);
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
    require Inline;
    require FFI::Platypus;
    require FFI::CheckLib;
    1;
};
SKIP: {
    skip 'Inline::C and FFI::Platypus are optional benchmark dependencies', 3 if !$native_available;
    my ( $bench_out, $bench_err, $bench_exit ) = _run( '--iterations', '32', '--runs', '1' );
    is( $bench_exit, 0, 'small parity benchmark runs when optional native dependencies are installed' );
    like( $bench_out, qr/all_digests_match=yes/, 'Perl, FFI, and Inline::C/XS digests match' );
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
    my ( $stdout, $stderr, $exit ) = capture {
        system $^X, $script, @arguments;
    };
    return ( $stdout, $stderr, $exit );
}

__END__

=pod

=head1 NAME

657-problem48-inline-xs-benchmark.t - verify the Inline::C and XS benchmark

=head1 PURPOSE

Checks the benchmark's dependency-free help and argument-validation paths,
then verifies digest parity when Inline::C/XS and FFI::Platypus are installed.

=head1 WHY IT EXISTS

Problem 48 requires evidence for native acceleration choices. This test keeps
the reproducible Inline::C/XS comparison runnable and guards against accepting
timings whose implementations produce different PBKDF2 digests.

=head1 WHEN TO USE

Run this test when changing the Inline::C benchmark's options, native binding,
or output-parity checks.

=head1 HOW TO USE

  prove -lv t/657-problem48-inline-xs-benchmark.t

The functional comparison is skipped only when its optional native modules are
absent. Compilation errors and digest mismatches remain failures.

=head1 WHAT USES IT

The repository test suite runs this file. The manual Problem 48 benchmark is
not loaded by Developer Dashboard at runtime.

=head1 EXAMPLES

Run the comparison in the isolated Docker benchmark with its optional modules:

  PERL5LIB=/bench-perl/lib/perl5:/bench-perl/lib/perl5/x86_64-linux-gnu-thread-multi prove -lv t/657-problem48-inline-xs-benchmark.t

=cut
