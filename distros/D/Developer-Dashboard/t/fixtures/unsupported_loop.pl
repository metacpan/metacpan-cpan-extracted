use strict;
use warnings;

sub sum_even_to_n {
    my ($n) = @_;
    my $sum = 0;
    for (my $i = 0; $i <= $n; $i += 2) {
        $sum += $i;
    }
    return $sum;
}

die "bad sum_even_to_n" unless sum_even_to_n(10) == 30;
1;

__END__

=head1 NAME

t/fixtures/unsupported_loop.pl - fixture: a loop shape (non-unit stride) that the native-acceleration path should decline to compile natively, falling back to the interpreter instead

=head1 PURPOSE

A loop that increments its counter by 2 each iteration (rather than the plain +1 shape native_leafs.pl and loop_sum.pl use) - a shape PAX's native-compilation path is expected to decline rather than mis-optimize.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - a loop shape (non-unit stride) that the native-acceleration path should decline to compile natively, falling back to the interpreter instead -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: dies with "bad sum_even_to_n" if the compiled/run result of C<sum_even_to_n(10)> is not 30, regardless of whether PAX ran it natively or via fallback.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/unsupported_loop.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/unsupported_loop.pl -o /tmp/out && /tmp/out

=cut
