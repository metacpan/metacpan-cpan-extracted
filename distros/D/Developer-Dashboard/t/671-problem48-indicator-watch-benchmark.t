use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $repo_root = File::Spec->catdir( $FindBin::Bin, '..' );
my $benchmark = File::Spec->catfile( $repo_root, 'script', 'problem48-indicator-watch-benchmark' );

my ( $help_stdout, $help_stderr, $help_exit ) = capture {
    system( $^X, $benchmark, '--help' );
};
is( $help_exit, 0, 'benchmark help exits successfully without optional FFI' );
is( $help_stderr, '', 'benchmark help does not emit warnings' );
like( $help_stdout, qr/--indicators N.*--iterations N.*--runs ODD_N/s,
    'help documents benchmark controls' );

my ( $even_stdout, $even_stderr, $even_exit ) = capture {
    system( $^X, $benchmark, '--runs', '2' );
};
ok( $even_exit != 0, 'an even sample count is rejected' );
like( $even_stderr, qr/--runs must be a positive odd integer/,
    'invalid sample count explains the required shape' );

my ( $zero_stdout, $zero_stderr, $zero_exit ) = capture {
    system( $^X, $benchmark, '--indicators', '0' );
};
ok( $zero_exit != 0, 'zero indicators are rejected' );
like( $zero_stderr, qr/--indicators must be a positive integer/,
    'invalid inventory size is diagnosed' );

done_testing;

__END__

=pod

=head1 NAME

671-problem48-indicator-watch-benchmark.t - verify the watcher benchmark CLI

=head1 PURPOSE

Checks the benchmark help and numeric argument guards without requiring the
optional FFI backend.

=head1 WHY IT EXISTS

The Problem 48 benchmark is the repeatable evidence gate for the optional
indicator sync watcher. Its command-line validation must stay usable even in
the standard test image where the Dashboard XS extension is not built.

=head1 WHEN TO USE

Run this test whenever the benchmark options or startup requirements change.

=head1 HOW TO USE

  d2 docker compose run --rm --no-deps dev prove -lv t/671-problem48-indicator-watch-benchmark.t

=head1 WHAT USES IT

The normal repository test suite runs this test; performance research runs the
benchmark itself in a disposable Docker development container with FFI enabled.

=head1 EXAMPLES

The test invokes the benchmark with C<--help>, an even C<--runs> value, and a
zero C<--indicators> value, then checks exit status and explicit diagnostics.

=cut
