use strict;
use warnings;

package PAX::Fixture::TieScalar;

sub TIESCALAR {
    my ($class, $value) = @_;
    return bless \$value, $class;
}

sub FETCH {
    my ($self) = @_;
    return $$self;
}

sub STORE {
    my ($self, $value) = @_;
    $$self = $value;
}

package main;

tie my $value, 'PAX::Fixture::TieScalar', 10;
$value = $value + 5;
die "bad tie" unless $value == 15;
1;

__END__

=head1 NAME

t/fixtures/nasty_tie.pl - fixture: tied variables (C<tie>), whose FETCH/STORE indirection a compiler could bypass incorrectly

=head1 PURPOSE

Defines a tied-scalar class (TIESCALAR/FETCH/STORE) and exercises reading and writing through a tied variable.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - tied variables (C<tie>), whose FETCH/STORE indirection a compiler could bypass incorrectly -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: dies with "bad tie" unless reading and writing the tied C<$value> through FETCH/STORE produces 15 once compiled and run.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/nasty_tie.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/nasty_tie.pl -o /tmp/out && /tmp/out

=cut
