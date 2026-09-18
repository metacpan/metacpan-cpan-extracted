use strict;
use warnings;

sub add {
    my ($left, $right) = @_;
    return $left + $right;
}

my $value = add(2, 3);
die "bad arithmetic" unless $value == 5;
1;

__END__

=head1 NAME

t/fixtures/simple.pl - fixture: the minimal baseline case, with no edge-case behavior at all

=head1 PURPOSE

The smallest possible fixture: one sub, one call, one self-check - used as a smoke test that the whole build/run pipeline works at all before exercising any specific edge case.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - the minimal baseline case, with no edge-case behavior at all -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: dies with "bad arithmetic" unless C<add(2, 3)> is 5 once compiled and run - if this fixture fails, the problem is in the pipeline itself, not in any specific language feature.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/simple.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/simple.pl -o /tmp/out && /tmp/out

=cut
