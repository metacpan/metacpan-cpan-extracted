use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-config-alias-mce-benchmark' );

my ( $help_out, $help_err, $help_exit ) = _run( $script, '--help' );
is( $help_exit, 0, '--help succeeds without requiring MCE' );
like( $help_out, qr/--skills N/, 'help documents synthetic skill count' );
like( $help_out, qr/--workers N/, 'help documents worker count' );
is( $help_err, '', '--help has no stderr diagnostics' );

my ( $invalid_out, $invalid_err, $invalid_exit ) = _run( $script, '--runs', '2' );
isnt( $invalid_exit, 0, 'even run count is rejected' );
like( $invalid_err, qr/Usage:/, 'invalid run count reports usage' );

my $mce_available = eval { require MCE::Map; 1 };
SKIP: {
    skip 'MCE is an optional benchmark dependency', 3 if !$mce_available;
    my ( $bench_out, $bench_err, $bench_exit ) = _run(
        $script, '--skills', '3', '--runs', '1', '--workers', '2',
    );
    is( $bench_exit, 0, 'small dashboard config benchmark succeeds with MCE' );
    like( $bench_out, qr/exact_alias_parity=yes/, 'serial and MCE path_aliases payloads match' );
    is( $bench_err, '', 'successful benchmark produces no warnings' );
}

done_testing();

# _run(@argv)
# Executes the benchmark helper and captures both streams and its wait status.
# Input: command-line argument list for the helper.
# Output: stdout, stderr, and exit status returned by Capture::Tiny.
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

660-problem48-config-alias-mce-benchmark.t - verify the application-level MCE benchmark

=head1 PURPOSE

Checks the benchmark's command-line behavior and, when the optional MCE module
is available, verifies that its parallel config-path-alias payload exactly
matches C<Developer::Dashboard::Config::path_aliases>.

=head1 WHY IT EXISTS

The raw JSON benchmark does not include dashboard-specific config layering,
skill qualification, or alias expansion. This test protects an application-
level comparison before any MCE change is considered for production.

=head1 WHEN TO USE

Run this test when changing the Problem 48 application-level MCE benchmark or
its arguments and output contract.

=head1 HOW TO USE

  prove -lv t/660-problem48-config-alias-mce-benchmark.t

The small parity case runs only when MCE is installed; CLI validation remains
covered without the optional dependency.

=head1 WHAT USES IT

The repository test suite runs the CLI contract; Problem 48 research uses the
benchmark's timings to evaluate whether dashboard config alias reads benefit
from parallel processing.

=head1 EXAMPLES

Run in the isolated Problem 48 Docker project with MCE installed:

  d2 docker compose -p dd-problem48-bench -f /tmp/d2-problem48-bench.yml -f /tmp/d2-problem48-init.yml run --rm bench sh -lc 'export PERL5LIB=/bench-perl/lib/perl5:/bench-perl/lib/perl5/x86_64-linux-gnu-thread-multi:$PERL5LIB; cd /checkout && prove -lv t/660-problem48-config-alias-mce-benchmark.t'

=cut
