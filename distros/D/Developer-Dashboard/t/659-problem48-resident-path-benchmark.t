use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile( $FindBin::Bin, '..', 'script', 'problem48-resident-path-benchmark' );
my ( $help_out, $help_err, $help_exit ) = _run('--help');
is( $help_exit, 0, '--help exits successfully' );
like( $help_out, qr/--skills N/, '--help documents the skill inventory size' );
like( $help_out, qr/--runs ODD_N/, '--help documents its sample count' );
is( $help_err, '', '--help writes no diagnostics' );

my ( $invalid_out, $invalid_err, $invalid_exit ) = _run( '--skills', '0' );
isnt( $invalid_exit, 0, 'a zero skill count is rejected' );
like( $invalid_err, qr/positive integer/, 'invalid inventory size reports its constraint' );

my ( $small_out, $small_err, $small_exit ) = _run( '--skills', '3', '--runs', '1' );
is( $small_exit, 0, 'small resident-context probe completes' );
like( $small_out, qr/exact_parity=yes/, 'resident output matches fresh helper output exactly' );
like( $small_out, qr/mutation_refresh=yes/, 'resident context observes changed config and Folder.pm results' );
is( $small_err, '', 'successful probe writes no diagnostics' );

done_testing;

# _run(@arguments)
# Executes the resident-path benchmark in a fresh process and captures streams.
# Input: benchmark command-line argument strings.
# Output: stdout, stderr, and child exit status.
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

659-problem48-resident-path-benchmark.t - verify resident path-context parity

=head1 PURPOSE

Checks a resident Perl path-handler prototype against fresh helper processes,
including mutable skill config and Folder.pm behavior between requests.

=head1 WHY IT EXISTS

Problem 48's only plausible route beyond the Perl process startup floor is a
resident runtime. This regression prevents an apparent warm-process speedup
from relying on stale config or user-provided alias results.

=head1 WHEN TO USE

Run whenever the resident path benchmark's lifecycle, invalidation, or output
comparison changes.

=head1 HOW TO USE

  prove -lv t/659-problem48-resident-path-benchmark.t

=head1 WHAT USES IT

The full repository suite executes this test. The benchmark is not loaded by
the application runtime.

=head1 EXAMPLES

  d2 docker compose -p dd-problem48-bench -f /tmp/d2-problem48-bench.yml -f /tmp/d2-problem48-init.yml run --rm bench sh -lc 'cd /checkout && prove -lv t/659-problem48-resident-path-benchmark.t'

=cut
