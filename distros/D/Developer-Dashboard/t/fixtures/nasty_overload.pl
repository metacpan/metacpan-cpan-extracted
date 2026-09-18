use strict;
use warnings;

package PAX::Fixture::Box;

use overload
    '0+' => sub { ${ $_[0] } },
    '+' => sub { ${ $_[0] } + $_[1] },
    fallback => 1;

sub new {
    my ($class, $value) = @_;
    return bless \$value, $class;
}

package main;

my $box = PAX::Fixture::Box->new(7);
die "bad overload" unless $box + 5 == 12;
1;

__END__

=head1 NAME

t/fixtures/nasty_overload.pl - fixture: operator overloading (C<use overload>) surviving compilation intact

=head1 PURPOSE

Defines a class using C<overload> for numeric context ('0+') and addition ('+'), then exercises operator overloading through ordinary Perl arithmetic syntax.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - operator overloading (C<use overload>) surviving compilation intact -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: dies with "bad overload" unless C<$box + 5> (where C<$box> overloads C<+>) evaluates to 12 once compiled and run.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/nasty_overload.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/nasty_overload.pl -o /tmp/out && /tmp/out

=cut
