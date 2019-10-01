package Games::Cards::Pair::Card;

$Games::Cards::Pair::Card::VERSION   = '0.20';
$Games::Cards::Pair::Card::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Games::Cards::Pair::Card - Object representation of a card.

=head1 VERSION

Version 0.20

=cut

use 5.006;
use Data::Dumper;
use Types::Standard qw(Int);
use Games::Cards::Pair::Params qw(Value Suit);

use Moo;
use namespace::autoclean;

use overload ( '""'  => \&as_string );

has 'index' => (is => 'rw', isa => Int );
has 'suit'  => (is => 'ro', isa => Suit);
has 'value' => (is => 'ro', isa => Value, required => 1);

=head1 DESCRIPTION

Only for internal use of Games::Cards::Pair class. Avoid using it directly.

=cut

sub BUILDARGS {
    my ($class, $args) = @_;

    if (defined($args->{'value'}) && ($args->{'value'} =~ /Joker/i)) {
        die("Attribute (suit) is NOT required for Joker.") if defined $args->{'suit'};
    }
    else {
        die("Attribute (suit) is required.") unless defined $args->{'suit'};
    }

    return $args;
};

=head1 METHODS

=head2 equal()

Returns 1 or 0 depending whether the two cards are same in value or one of them is a Joker.

    use strict; use warnings;
    use Games::Cards::Pair::Card;

    my ($card1, $card2);
    $card1 = Games::Cards::Pair::Card->new({ suit => 'Clubs',    value => '2' });
    $card2 = Games::Cards::Pair::Card->new({ suit => 'Diamonds', value => '2' });
    print "Card are the same.\n" if $card1->equal($card2);

    $card2 = Games::Cards::Pair::Card->new({ value => 'Joker' });
    print "Card are the same.\n" if $card1->equal($card2);

=cut

sub equal {
    my ($self, $other) = @_;

    return 0 unless (defined($other) && (ref($other) eq 'Games::Cards::Pair::Card'));

    return 1
        if ((defined($self->{value}) && ($self->{value} =~ /Joker/i))
            ||
            (defined($other->{value}) && ($other->{value} =~ /Joker/i))
            ||
            (defined($self->{value}) && (defined($other->{value}) && (lc($self->{value}) eq lc($other->{value})))));

    return 0;
}

=head2 as_string()

Returns the card object in readable format. This is overloaded as string context for printing.

    use strict; use warnings;
    use Games::Cards::Pair::Card;

    my $card = Games::Cards::Pair::Card->new({ suit => 'Clubs', value => '2' });
    print "Card: $card\n";
    # or
    print "Card: " . $card->as_string() . "\n";

=cut

sub as_string {
    my ($self) = @_;

    return sprintf("%4s%s", $self->value, $self->suit) if defined $self->suit;

    return sprintf("%5s", $self->value);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Games-Cards-Pair>

=head1 BUGS

Please report any bugs / feature requests to C<bug-games-cards-pair at rt.cpan.org>,or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Cards-Pair>.I will
be notified, & then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Cards::Pair::Card

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Cards-Pair>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Cards-Pair>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Cards-Pair>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Cards-Pair/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Games::Cards::Pair::Card
