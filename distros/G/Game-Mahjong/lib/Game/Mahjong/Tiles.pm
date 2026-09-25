package Game::Mahjong::Tiles;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use constant KINDS    => 34;
use constant BONUS    => 8;
use constant PATTERNS => 42;
use constant PER_KIND => 4;
use constant TILES    => 144;

my @RANK   = qw(one two three four five six seven eight nine);
my %SUIT   = (m => 'characters', p => 'dots', s => 'bamboo');
my @WIND   = qw(east south west north);
my @DRAGON = qw(red green white);
my @FLOWER = qw(plum orchid bamboo chrysanthemum);
my @SEASON = qw(spring summer autumn winter);

sub set {
	my @set;
	for my $kind (1 .. KINDS) {
		push @set, ($kind) x PER_KIND;
	}
	push @set, (KINDS + 1) .. PATTERNS;
	return @set;
}

sub kinds { return (1 .. KINDS) }

sub patterns { return (1 .. PATTERNS) }

sub name_of {
	my ($kind) = @_;
	my $code = code_of($kind);
	if (my $suit = suit_of($kind)) {
		return $RANK[ rank_of($kind) - 1 ] . ' of ' . $SUIT{$suit};
	}
	return $WIND[ wind_index($kind) ] . ' wind' if is_wind($kind);
	return $DRAGON[ dragon_index($kind) ] . ' dragon' if is_dragon($kind);
	return $FLOWER[ bonus_index($kind) ] if is_flower($kind);
	return $SEASON[ bonus_index($kind) ];
}

sub suit_name {
	my ($letter) = @_;
	die "Game::Mahjong::Tiles: there is no suit '" . (defined $letter ? $letter : 'undef') . "'"
		unless defined $letter && $SUIT{$letter};
	return $SUIT{$letter};
}

sub next_in_suit {
	my ($kind) = @_;
	my $rank = rank_of($kind);
	return undef unless defined $rank && $rank < 9;
	return $kind + 1;
}

1;

__END__

=head1 NAME

Game::Mahjong::Tiles - the forty-two kinds, and the set of 144

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Mahjong;

    my @set = Game::Mahjong::Tiles::set();     # 144 kind ids, four of each suit
                                               # and honour kind, one of each bonus
    Game::Mahjong::Tiles::code_of(19);         # "s1"
    Game::Mahjong::Tiles::id_of('dg');         # 33
    Game::Mahjong::Tiles::suit_of(5);          # "m"
    Game::Mahjong::Tiles::rank_of(5);          # 5
    Game::Mahjong::Tiles::is_terminal(9);      # 1
    Game::Mahjong::Tiles::name_of(33);         # "green dragon"

=head1 DESCRIPTION

A kind is an integer from 1 to 42, and the table behind it is C
(C<include/mahjong_abi.h>, C<mahjong_tiles.c>): the decomposer and the
shanten walk that table for every candidate discard, and a second copy of it
in Perl would be a second place for a flag to be wrong. This module is the
Perl face of the table plus what has no business in C.

=head2 The order is part of the interface

    1 to 9     m1 to m9   characters
    10 to 18   p1 to p9   dots
    19 to 27   s1 to s9   bamboo
    28 to 31   we ws ww wn
    32 to 34   dr dg dw   red, green, white
    35 to 38   f1 to f4   plum, orchid, bamboo, chrysanthemum
    39 to 42   t1 to t4   spring, summer, autumn, winter

Within a suit C<< $kind + 1 >> is the next rank, and C<m9 + 1> is the one of
dots and not a character. The shifted-chow and shifted-pung checks walk ids
inside a suit on that promise, and C<next_in_suit> is the walk written once.

=head2 A kind, not a tile

Four tiles of every kind 1 to 34 exist and they are identical. Nothing here
names the third five of bamboo; a hand counts kinds.

=head2 A number off the table dies

C<code_of(0)>, C<code_of(43)> and C<id_of('x')> die with this module's
sentence. An off-table kind is a programmer error, and the house rule is that
programmer error dies where a refused move is returned.

=head1 FUNCTIONS

All are plain functions, not methods.

=head2 set

The 144 tiles as a list of kind ids: four of each kind 1 to 34, then one of
each bonus kind 35 to 42.

=head2 kinds

The list 1 to 34.

=head2 patterns

The list 1 to 42.

=head2 code_of

The two-letter code of a kind.

=head2 id_of

The kind of a two-letter code. Dies on a code that names no kind.

=head2 suit_of

C<m>, C<p> or C<s> for a suit tile; undef for an honour or a bonus tile.

=head2 rank_of

1 to 9 for a suit tile; undef otherwise.

=head2 wind_index

0 to 3 (east, south, west, north) for a wind; undef otherwise.

=head2 dragon_index

0 to 2 (red, green, white) for a dragon; undef otherwise.

=head2 bonus_index

0 to 3 for a flower or a season; undef otherwise.

=head2 flags_of

The raw flag word from the table, for tests.

=head2 is_suit, is_honour, is_wind, is_dragon, is_terminal, is_simple, is_bonus, is_flower, is_season, is_green, is_reversible

1 or 0. C<is_green> is fan 3's set (the 2, 3, 4, 6 and 8 of bamboo and the
green dragon); C<is_reversible> is fan 40's (the 1, 2, 3, 4, 5, 8 and 9 of
dots, the 2, 4, 5, 6, 8 and 9 of bamboo, and the white dragon: fourteen kinds).

=head2 name_of

The English name: "five of characters", "east wind", "red dragon", "plum".
For the terminal and for the catalogue key's English only.

=head2 suit_name

The English of a suit letter.

=head2 next_in_suit

The kind one rank up in the same suit, or undef at a nine or for anything
that is not a suit tile.

=head2 KINDS, BONUS, PATTERNS, PER_KIND, TILES

34, 8, 42, 4, 144. The tests check them against the table and the set rather
than trusting the literals.

=head2 _abi_ptr, _abi_version, _abi_kinds

The table's address, the ABI version and the pattern count, for a downstream
XS module and for the tests.

=head1 SEE ALSO

L<Game::Mahjong>, L<Game::Mahjong::Notation>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
