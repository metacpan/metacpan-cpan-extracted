use strict;
use warnings;

sub sum_to_n {
    my ($n) = @_;
    my $sum = 0;
    for (my $i = 1; $i <= $n; $i++) {
        $sum += $i;
    }
    return $sum;
}

die "bad sum_to_n" unless sum_to_n(10) == 55;
1;

__END__

=head1 NAME

t/fixtures/loop_sum.pl - fixture: a simple, hot, numeric loop that PAX's acceleration path should recognize and speed up

=head1 PURPOSE

A simple summation loop (sum 1..n) used as a hot-loop candidate for PAX's acceleration/native-compilation tests.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - a simple, hot, numeric loop that PAX's acceleration path should recognize and speed up -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: dies with "bad sum_to_n" if the compiled/run result of C<sum_to_n(10)> is not 55.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/loop_sum.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/loop_sum.pl -o /tmp/out && /tmp/out

=cut
