########################################################
# Copyright © 2009 Six Apart, Ltd.

package HTML::Laundry::Rules::Minimal;
use strict;
use warnings;
use base qw( HTML::Laundry::Rules );

=head1 NAME

HTML::Laundry::Rules::Minimal - a minimal set of HTML attributes

=cut

=head2 acceptable_e

Return a hashref representing a minimal list of acceptable elements:
a, b, blockquote, code, em, i, li, ol, p, pre, strong, u, and ul

=cut

sub acceptable_e {
    my $self       = shift;
    my @acceptable = qw(
        a b br blockquote code em i li ol p pre strong u ul
    );
    my %acceptable = map { ( $_, 1 ) } @acceptable;
    return \%acceptable;
}

=head2 acceptable_a

Return a hashref representing a list of acceptable attributes to support
the minimal acceptable list ("href" only)

=cut

sub acceptable_a {
    my $self = shift;
    my @acceptable
        = qw(href);
    my %acceptable = map { ( $_, 1 ) } @acceptable;
    return \%acceptable;
}

=head2 allowed_schemes

Return an arrayref representing "http" and "https" only

=cut

sub allowed_schemes {
    my $self = shift;
    return {
        http  => 1,
        https => 1,
    };
}


1;