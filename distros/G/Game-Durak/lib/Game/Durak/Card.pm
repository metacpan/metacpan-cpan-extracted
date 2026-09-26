package Game::Durak::Card;

use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(rank_of suit_of power_of name_of long_name_of face_of
                    id_of ids_of_suit six_of beats ranks suits CARDS);

use constant CARDS => 36;

my @RANKS = qw(A K Q J T 9 8 7 6);
my @SUITS = qw(S H D C);

my %RANK_NAME = (A => 'ace',  K => 'king',  Q => 'queen', J => 'jack',
                 T => 'ten',  9 => 'nine',  8 => 'eight', 7 => 'seven',
                 6 => 'six');
my %SUIT_NAME = (S => 'spades', H => 'hearts', D => 'diamonds', C => 'clubs');

my %RANK_AT;
@RANK_AT{@RANKS} = 0 .. $#RANKS;

my %SUIT_AT;
@SUIT_AT{@SUITS} = 0 .. $#SUITS;

sub ranks { return @RANKS }
sub suits { return @SUITS }

sub _card {
    my ($id) = @_;
    die 'Game::Durak::Card: no card has id ' . (defined $id ? "'$id'" : 'undef') . "\n"
        unless defined $id && $id =~ /\A[1-9][0-9]*\z/ && $id >= 1 && $id <= CARDS;
    return $id;
}

sub _suit {
    my ($suit) = @_;
    die 'Game::Durak::Card: no suit is ' . (defined $suit ? "'$suit'" : 'undef') . "\n"
        unless defined $suit && exists $SUIT_AT{$suit};
    return $suit;
}

sub rank_of { my $id = _card($_[0]); return $RANKS[ ($id - 1) % @RANKS ] }
sub suit_of { my $id = _card($_[0]); return $SUITS[ int(($id - 1) / @RANKS) ] }

sub power_of { return $#RANKS - $RANK_AT{ rank_of($_[0]) } }

sub name_of { my ($id) = @_; return rank_of($id) . suit_of($id) }

my %FACE = (T => '10');

sub face_of { my ($id) = @_; my $rank = rank_of($id); return $FACE{$rank} // $rank }

sub long_name_of {
    my ($id) = @_;
    return $RANK_NAME{ rank_of($id) } . ' of ' . $SUIT_NAME{ suit_of($id) };
}

my %ID;
for my $id (1 .. CARDS) { $ID{ name_of($id) } = $id }

sub id_of {
    my ($name) = @_;
    return undef unless defined $name;
    return $ID{ uc $name };
}

sub ids_of_suit {
    my ($suit) = @_;
    my $at = $SUIT_AT{ _suit($suit) };
    return [ map { $at * @RANKS + $_ } 1 .. scalar @RANKS ];
}

sub six_of { my ($suit) = @_; return $ID{ '6' . _suit($suit) } }

sub beats {
    my ($def, $att, $trump) = @_;
    _card($def);
    _card($att);
    _suit($trump);

    return 0 if $def == $att;

    my $ds = suit_of($def);
    my $as = suit_of($att);

    return ($ds eq $trump && power_of($def) > power_of($att)) ? 1 : 0
        if $as eq $trump;

    return 1 if $ds eq $trump;

    return ($ds eq $as && power_of($def) > power_of($att)) ? 1 : 0;
}

1;

__END__

=head1 NAME

Game::Durak::Card - a card is an integer, and the trump decides what beats it

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Durak::Card qw(rank_of suit_of power_of name_of id_of beats);

    rank_of(1);              # 'A'
    suit_of(1);              # 'S'
    name_of(1);              # 'AS'
    id_of('6C');             # 36

    beats(id_of('KS'), id_of('QS'), 'H');    # 1, a higher spade
    beats(id_of('6H'), id_of('AS'), 'H');    # 1, the trump six over the ace
    beats(id_of('6H'), id_of('AH'), 'H');    # 0, a trump takes a HIGHER trump

=head1 DESCRIPTION

Cards are integers 1 to 36, suit-major, nine ranks to a suit: 1 to 9 are
spades ace down to six, 10 to 18 hearts, 19 to 27 diamonds, 28 to 36 clubs. A
hand is therefore a list of small integers and a deal is a permutation.

=head2 The ace is high, the six is low, and this is the third rank order in the tree

L<Game::Gin::Card> and the copies of it made for the other card games on
peer2peergames number a fifty-two card pack ace low over thirteen ranks.
L<Game::Schnapsen::Card> numbers a twenty-four card pack over six ranks with
the ten above the king. This pack is nine ranks, ace high and six low, and
B<no card id, rank index or power in this distribution means what it means in
either of those>.

That is also the reason this module exists rather than a deck being added to
the marriage family's card module. That module derives a rank from
C<($id - 1) % @RANKS> with six ranks in the list, so a nine rank pack moves
every id it has: the ten of spades stops being id 2 and hearts stop starting
at id 7. A thirty-six card pack is not a superset of a twenty-four card one,
it is a different pack.

C<power_of> is the authority on rank order and it is derived from the order of
the rank list and from nothing else.

=head2 beats(), and the order of its three answers

The rules the function is built from, from
L<https://www.pagat.com/beating/podkidnoy_durak.html>:

    A card which is not a trump can be beaten by playing a higher card of the
    same suit, or by any trump. A trump card can only be beaten by playing a
    higher trump. Note that a non-trump attack can always be beaten by a
    trump, even if the defender also holds cards in the suit of the attack
    card - there is no requirement to "follow suit".

Three sentences, and B<the order between them is the rule and not an
optimisation>:

=over 4

=item 1

If the attack card is a trump, only a higher trump beats it. Nothing else,
ever.

=item 2

Otherwise any trump beats it.

=item 3

Otherwise a higher card of the same suit beats it.

=back

Written with the trump clause first, the function is right about every attack
made with one of the twenty-seven plain cards and lets the trump six beat the
trump ace. Written with the suit comparison dropped from the last answer, it
lets a higher card of an unrelated plain suit beat anything. Both mutations
are carried in F<t/01-cards.t>, which asserts B<which> vectors each one
changes rather than that something changed.

There is no fourth answer. Two cards are never equal, because the pack holds
no duplicates, and a card is not offered against itself.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 rank_of

One of C<A>, C<K>, C<Q>, C<J>, C<T>, C<9>, C<8>, C<7>, C<6>. Dies for an id
that is not a card.

=head2 suit_of

One of C<S>, C<H>, C<D>, C<C>.

=head2 power_of

How the card ranks within its suit: 8 for an ace down to 0 for a six. Higher
wins, and it says nothing at all about a card of another suit.

=head2 name_of

Two characters, rank then suit: C<AS>, C<TD>, C<6C>. The suit is a letter and
never a glyph: a consumer that encodes a view to JSON and embeds it in a page
gets mojibake out of a glyph, so glyphs belong in the consumer.

=head2 long_name_of

C<ace of spades>, for a sentence.

=head2 face_of

    face_of(id_of('TS'));    # '10'
    face_of(id_of('AS'));    # 'A'

What a B<player> reads on the card. The only difference from C<rank_of> is
the ten, which this pack spells C<T> because a card here is a two character
id and one character a rank keeps both the arithmetic and the fixtures
simple. Nobody has ever seen a ten with a T on it, so anything drawing a card
for a person asks for this and anything computing with one asks for
C<rank_of>.

=head2 id_of

The id for a name, or undef. Case insensitive. This one parses input, so it
returns undef rather than dying.

=head2 ids_of_suit

    ids_of_suit('H');    # [ 10 .. 18 ], ace down to six

The nine ids of a suit, in id order, as an arrayref.

=head2 six_of

    six_of('D');         # 27

The id of a suit's six. The lowest card of the suit, and the one card that may
be exchanged for the turned up trump.

=head2 beats

    beats($defending_card, $attacking_card, $trump_suit);

True if the first card beats the second with that suit as trumps. Dies for an
id that is not a card or a suit that is not a suit, because both mean a bug
upstream rather than a move a player has made.

=head2 ranks, suits

The rank list, high to low, and the suit list.

=head2 CARDS

36, as a constant.

=head1 SEE ALSO

L<Game::Durak>, L<Game::Durak::Deck>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
