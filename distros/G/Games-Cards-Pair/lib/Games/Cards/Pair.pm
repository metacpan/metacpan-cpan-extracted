package Games::Cards::Pair;

$Games::Cards::Pair::VERSION   = '0.18';
$Games::Cards::Pair::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Games::Cards::Pair - Interface to the Pelmanism (Pair) Card Game.

=head1 VERSION

Version 0.18

=cut

use 5.006;
use Data::Dumper;

use Attribute::Memoize;
use List::Util qw(shuffle);
use List::MoreUtils qw(first_index);
use Term::Screen::Lite;
use Types::Standard qw(Int);
use Games::Cards::Pair::Params qw(ZeroOrOne Cards);
use Games::Cards::Pair::Card;

use Moo;
use namespace::clean;

use overload ('""' => \&as_string);

has [ qw(bank seen) ] => (is => 'rw', isa => Cards);
has 'cards'     => (is => 'rw', default => sub { 12 });
has 'board'     => (is => 'rw');
has 'available' => (is => 'ro', isa => Cards);
has 'screen'    => (is => 'ro', default => sub { Term::Screen::Lite->new; });
has 'count'     => (is => 'rw', isa => Int,       default => sub { 0 });
has 'debug'     => (is => 'rw', isa => ZeroOrOne, default => sub { 0 });

=head1 DESCRIPTION

A single-player game of Pelmanism, played with minimum of 12 cards and maximum up
to 54 cards. Depending on number of cards choosen the user, it prepares the game.

Cards picked up from the collection comprises each of the thirteen values (2,3,4,
5,6,7,8,9,10,Queen,King,Ace and Jack) in  each of the four suits (Clubs,Diamonds,
Hearts and Spades) plus two jokers. The Joker will not have any suit.

The game script C<play-pelmanism> is supplied with the distribution and on install
is available to play with.

  USAGE: play-pelmanism [-h] [long options...]

    --cards=Int  Cards count (min:12, max:54).
    --verbose    Play the game in verbose mode.

    --usage      show a short help message
    -h           show a compact help message
    --help       show a long help message
    --man        show the manual

=head1 METHODS

=head2 play($index)

Accepts comma separated card indices and play the game.

=cut

sub play {
    my ($self, $index) = @_;

    my ($card, $new) = $self->_pick($index);

    if ($new->equal($card)) {
        $self->_process($new, $card);
    }
    else {
        $self->{deck}->{$new->index}  = $new;
        $self->{deck}->{$card->index} = $card;
    }
}

=head2 is_over()

Returns 1 or 0 depending if the deck is empty or not.

=cut

sub is_over {
    my ($self) = @_;

    return (scalar(@{$self->{available}}) == 0);
}

=head2 get_board()

Return game board with hidden card, showing only the card index.

=cut

sub get_board {
    return $_[0]->as_string(0);
}

=head2 is_valid_card_count($count)

Valid card count is any number between 12 and 54 (both inclusive). Also it should
be a multiple of 4.

=cut

sub is_valid_card_count {
    my ($self, $count) = @_;

    return (defined $count
            && ($count =~ /^\d+$/)
            && ($count >=12 || $count <= 54)
            && ($count % 4 == 0));
}

=head2 init()

Shuffles the pack and then pick required number of cards.

=cut

sub init {
    my ($self) = @_;

    my $cards = [];
    $self->{available} = [];
    my $i = $self->cards / 4;
    foreach my $suit (qw(C D H S)) {
        my $j = 1;
        foreach my $value (qw(A 2 3 4 5 6 7 8 9 10 J Q K)) {
            next if ($j > $i);
            push @$cards, Games::Cards::Pair::Card->new({ suit => $suit, value => $value });
            $j++;
        }
    }

    # Adding two Jokers to the Suit.
    push @$cards, Games::Cards::Pair::Card->new({ value => 'Joker' });
    push @$cards, Games::Cards::Pair::Card->new({ value => 'Joker' });
    push @{$self->{available}}, $_ for (0..$self->cards-1);

    # Index card after shuffle.
    $self->_index($cards);
}

=head2 get_matched_pairs()

Returns all the matching pair, if any found, from the bank.

=cut

sub get_matched_pairs {
    my ($self) = @_;

    my $string = '';
    foreach (@{$self->{bank}}) {
        $string .= sprintf("%s %s\n", $_->[0], $_->[1]);
    }

    return $string;
}

=head2 as_string()

Returns deck arranged as 4 in a row blocks. This is overloaded as string context.

=cut

sub as_string {
    my ($self, $hide) = @_;

    my $deck = '';
    foreach my $i (1..$self->cards) {
        my $card = $self->{deck}->{$i-1};
        my $c = '     ';
        if (defined $card) {
            if ($hide) {
                $c = $i;
            }
            else {
                $c = $card->as_string;
            }
        }

        $deck .= sprintf("[ %5s ]", $c);
        $deck .= "\n" if ($i % 4 == 0);
    }

    return $deck;
}

#
#
# PRIVATE METHODS

sub _pick {
    my ($self, $index) = @_;

    $self->{count}++;

    my ($i, $j) = split /\,/, $index, 2;
    --$i; --$j;
    my $c1 = $self->{deck}->{$i};
    die "ERROR: Invalid card received [$i].\n" unless defined $c1;

    my $c2 = $self->{deck}->{$j};
    die "ERROR: Invalid card received [$j].\n" unless defined $c2;

    push @{$self->{seen}}, $c1, $c2;

    return ($c1, $c2);
}

sub _save {
    my ($self, @cards) = @_;

    die("ERROR: Expecting atleast a pair of cards.\n") unless (scalar(@cards) == 2);

    push @{$self->{bank}}, [@cards];
}

sub _process {
    my ($self, $card, $new) = @_;

    $self->{deck}->{$new->index}  = undef;
    $self->{deck}->{$card->index} = undef;
    $self->_save($card, $new);

    my $index = first_index { $_ == $new->index } @{$self->{available}};
    splice(@{$self->{available}}, $index, 1) if ($index != -1);

    $index = first_index { $_ == $card->index } @{$self->{available}};
    splice(@{$self->{available}}, $index, 1) if ($index != -1);
}

sub _index {
    my ($self, $cards) = @_;

    $cards = [shuffle @{$cards}];
    my $index  = 0;
    foreach my $card (@{$cards}) {
        $card->index($index);
        $self->{deck}->{$index} = $card;
        $index++;
        last if ($self->cards == $index);
    }
}

sub _draw {
    my ($self) = @_;

    my @random = shuffle(@{$self->{available}});
    my $index  = shift @random;

    return $self->{deck}->{$index} if defined $index;
    return;
}

sub _seen :Memoize {
    my ($self, $card) = @_;

    my $index = 0;
    foreach (@{$self->{seen}}) {
        if ($card->equal($_)) {
            splice(@{$self->{seen}}, $index, 1);
            return $_;
        }
        $index++;
    }

    return;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Games-Cards-Pair>

=head1 BUGS

Please report any bugs / feature requests to C<bug-games-cards-pair at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Cards-Pair>.
I will be notified and then you'll automatically be  notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Cards::Pair

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

1; # End of Games::Cards::Pair
