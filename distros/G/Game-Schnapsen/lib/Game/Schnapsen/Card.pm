package Game::Schnapsen::Card;

use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(rank_of suit_of power_of points_of name_of long_name_of id_of
                    ids_of_ranks ranks suits CARDS);

use constant CARDS => 24;

my @RANKS = qw(A T K Q J 9);
my @SUITS = qw(S H D C);

my %POINTS = (A => 11, T => 10, K => 4, Q => 3, J => 2, 9 => 0);

my %RANK_NAME = (A => 'ace', T => 'ten', K => 'king',
                 Q => 'queen', J => 'jack', 9 => 'nine');
my %SUIT_NAME = (S => 'spades', H => 'hearts', D => 'diamonds', C => 'clubs');

my %RANK_AT;
@RANK_AT{@RANKS} = 0 .. $#RANKS;

sub ranks { return @RANKS }
sub suits { return @SUITS }

sub _check {
    my ($id) = @_;
    die 'Game::Schnapsen::Card: no card has id ' . (defined $id ? "'$id'" : 'undef') . "\n"
        unless defined $id && $id =~ /\A[1-9][0-9]*\z/ && $id >= 1 && $id <= CARDS;
    return $id;
}

sub rank_of { my $id = _check($_[0]); return $RANKS[ ($id - 1) % @RANKS ] }
sub suit_of { my $id = _check($_[0]); return $SUITS[ int(($id - 1) / @RANKS) ] }

sub power_of  { return $#RANKS - $RANK_AT{ rank_of($_[0]) } }
sub points_of { return $POINTS{ rank_of($_[0]) } }

sub name_of { my ($id) = @_; return rank_of($id) . suit_of($id) }

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

sub ids_of_ranks {
    my ($want) = @_;
    my %keep = map { $_ => 1 } @$want;
    return [ grep { $keep{ rank_of($_) } } 1 .. CARDS ];
}

1;

__END__

=head1 NAME

Game::Schnapsen::Card - a card is an integer, and everything else is derived

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Schnapsen::Card qw(rank_of suit_of power_of points_of name_of id_of);

    rank_of(1);          # 'A'
    suit_of(1);          # 'S'
    points_of(1);        # 11
    name_of(1);          # 'AS'
    id_of('AS');         # 1

    points_of(6);        # 0, a nine
    name_of(24);         # '9C'

=head1 DESCRIPTION

Cards are integers 1 to 24, suit-major, six ranks to a suit: 1 to 6 are spades
ace to nine, 7 to 12 hearts, 13 to 18 diamonds, 19 to 24 clubs. A hand is
therefore a list of small integers and a deal is a permutation.

=head2 One id space for both games

Schnapsen is played with twenty cards and Sixty-Six with twenty-four, but
Schnapsen's pack is this pack with the four nines removed rather than a separate
numbering. So this module never needs to know which game is being played:
L<Game::Schnapsen::Deck> filters. One id space means one notation, one set of
test vectors, and no arithmetic that means different things in different games.

=head2 The ten beats the king

This is the trap in the marriage family, and it is stated here as a rank order
rather than left to fall out of the arithmetic. A ranking built from the card
point values happens to get it right, because ten is worth 10 and a king 4. A
ranking built from the ordinary sequence of a pack gets it wrong, and nothing
would notice until somebody lost a trick they had won. C<power_of> is the
authority, and it is derived from the order of the rank list and from nothing
else.

=head2 Card points

An ace 11, a ten 10, a king 4, a queen 3, a jack 2, a nine nothing. Both
published rulesets give the same table, so it is implemented once.

The nine being worth nothing is why both packs hold the same 120 card points.
The extra four cards in Sixty-Six change how long a deal runs, not what it is
worth, and Sixty-Six's 130 comes from the ten it pays for the last trick rather
than from the larger pack.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 rank_of

One of C<A>, C<T>, C<K>, C<Q>, C<J>, C<9>. Dies for an id that is not a card.

=head2 suit_of

One of C<S>, C<H>, C<D>, C<C>.

=head2 power_of

How the card ranks within its suit, 5 for an ace down to 0 for a nine. Higher
wins. Two cards in a trick are never equal, because the pack holds no
duplicates, so a comparison of two powers never has to break a tie.

=head2 points_of

What the card is worth to whoever takes the trick.

=head2 name_of

Two characters, rank then suit: C<AS>, C<TD>, C<QH>, C<9C>. The suit is a
letter and never a glyph: a consumer that encodes a view to JSON and embeds it
in a page gets mojibake out of a glyph, so glyphs belong in the consumer.

=head2 long_name_of

C<ace of spades>, for a sentence.

=head2 id_of

The id for a name, or undef. Case insensitive. This one parses input, so it
returns undef rather than dying.

=head2 ids_of_ranks

    ids_of_ranks([qw(A T K Q J)]);   # the twenty-card pack

The ids whose rank is in the list, in id order. How L<Game::Schnapsen::Deck>
builds a variant's pack.

=head2 ranks, suits

The rank and suit lists, ranks in descending order of trick power.

=head2 CARDS

24, as a constant: the full pack, before any variant removes anything.

=head1 SEE ALSO

L<Game::Schnapsen::Deck>, L<Game::Schnapsen::Variant>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
