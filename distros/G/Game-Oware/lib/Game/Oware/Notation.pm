package Game::Oware::Notation;

use strict;
use warnings;

use Game::Oware::Board;

our $VERSION = '0.01';

my @LETTER = ('A' .. 'F', 'a' .. 'f');

my %INDEX = map { $LETTER[$_] => $_ } 0 .. $#LETTER;

sub letters { return @LETTER }

sub letter_of {
	my ($class, $house) = @_;
	Game::Oware::Board->assert_house($house);
	return $LETTER[$house];
}

sub index_of {
	my ($class, $letter) = @_;
	die 'Game::Oware::Notation: a house is one of ABCDEFabcdef'
		unless defined $letter && exists $INDEX{$letter};
	return $INDEX{$letter};
}

sub seat_of {
	my ($class, $letter) = @_;
	return Game::Oware::Board->owner_of($class->index_of($letter));
}

sub render {
	my ($class, $houses) = @_;
	return join '', map { $class->letter_of($_) } @$houses;
}

sub parse {
	my ($class, $text) = @_;
	die 'Game::Oware::Notation: a transcript is a string'
		unless defined $text;

	$text =~ s/\s+//g;
	return [] unless length $text;

	my @houses;
	my $expect = 'p1';
	for my $letter (split //, $text) {
		my $house = $class->index_of($letter);
		my $seat  = Game::Oware::Board->owner_of($house);
		die "Game::Oware::Notation: $letter is ${seat}'s move, but it is "
			. "$expect to play, and the seats alternate"
			unless $seat eq $expect;
		push @houses, $house;
		$expect = Game::Oware::Board->other($expect);
	}

	return \@houses;
}

sub board_to_text {
	my ($class, $board) = @_;
	die 'Game::Oware::Notation: a board is fourteen cells'
		unless ref $board eq 'ARRAY' && @$board == Game::Oware::Board->CELLS;

	my @top    = map { $board->[$_] } reverse 6 .. 11;
	my @bottom = map { $board->[$_] } 0 .. 5;

	return join "\n",
		' ' . join(' ', map { sprintf '%2s', $_ } reverse 'a' .. 'f'),
		' ' . join(' ', map { sprintf '%2d', $_ } @top)
			. '  [' . $board->[Game::Oware::Board->P2_STORE] . ']',
		' ' . join(' ', map { sprintf '%2d', $_ } @bottom)
			. '  [' . $board->[Game::Oware::Board->P1_STORE] . ']',
		' ' . join(' ', map { sprintf '%2s', $_ } 'A' .. 'F');
}

sub text_to_board {
	my ($class, $text) = @_;
	die 'Game::Oware::Notation: a board is a string'
		unless defined $text;

	my @rows;
	for my $line (split /\n/, $text) {
		next unless $line =~ /\d/;
		my ($counts, $store) = $line =~ /\A([^\[]*)(?:\[\s*(\d+)\s*\])?\s*\z/
			or die "Game::Oware::Notation: cannot read '$line'";
		my @counts = $counts =~ /(\d+)/g;
		die "Game::Oware::Notation: a row is six houses, not "
			. scalar(@counts) . " in '$line'"
			unless @counts == 6;
		push @rows, [ \@counts, $store || 0 ];
	}

	die 'Game::Oware::Notation: a board is two rows of houses'
		unless @rows == 2;

	my ($top, $bottom) = @rows;
	my @board;
	@board[0 .. 5]  = @{ $bottom->[0] };
	@board[6 .. 11] = reverse @{ $top->[0] };
	$board[ Game::Oware::Board->P1_STORE ] = $bottom->[1];
	$board[ Game::Oware::Board->P2_STORE ] = $top->[1];

	return \@board;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Oware::Notation - house letters, transcripts, and boards as text

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Oware::Notation;

    Game::Oware::Notation->letter_of(4);        # E
    Game::Oware::Notation->index_of('c');       # 8
    Game::Oware::Notation->parse('EcAb');       # [ 4, 8, 0, 7 ]

=head1 DESCRIPTION

=head2 The letters are standard, the transcript container is ours

Upper case C<A> to C<F> for one side and lower case C<a> to C<f> for the other
is the convention every published diagram uses, and the one the Wikipedia
article's own worked example is written in: "the lower player prepares to sow
from B<E>", "B<e>, B<d>, and B<c> are captured".

Joining the letters into a transcript with no separator is B<not> standard.
Joan Sala's I<Aualé> saves games in a format that "resembles PGN", but no
specification of it could be found to cite, so it is not adopted and nothing
here claims to read it.

=head2 A transcript is self-describing, and that is a fact about the rules

The case carries the seat, so a parser never has to track whose turn it is in
order to attribute a move. That is the opposite of L<Game::Reversi::Notation>,
where a transcript is a list of squares, a forced pass is usually not written
down, and a parser that assumes strict alternation misattributes every move
after the first one.

=head2 Oware has no pass, so alternation is strict and is enforced

The feeding obligation means a seat on turn always has seeds: if the opponent
could feed them they were obliged to, and if they could not the game is already
over. So there is no forced pass, nothing to reconstruct on read, and no token
for one.

Which makes two consecutive moves by the same seat something no game can
produce, so C<parse> refuses it rather than quietly reattributing it. p1 moves
first.

=head2 The board layout puts each row where the article draws it

Top row is p2's, read C<f> to C<a> right to left; bottom row is p1's, read C<A>
to C<F> left to right; each row carries its own store in brackets. Sowing then
runs left to right along the bottom and right to left along the top, which is
one continuous counter-clockwise ring on the page.

C<text_to_board> ignores any line with no digits in it, so the letter headers
C<board_to_text> writes are optional on the way back in and a diagram
transcribed from a source can keep whatever labels it came with.

=head1 FUNCTIONS

=head2 letters

Every house letter, in index order.

=head2 letter_of

The letter for a house index.

=head2 index_of

The house index for a letter. Dies on anything else.

=head2 seat_of

The seat that owns the house a letter names.

=head2 render

A list of house indices as a transcript string.

=head2 parse

A transcript string as an arrayref of house indices. Dies if the seats do not
alternate, or if p1 does not move first.

=head2 board_to_text

A board as four lines: the two letter headers, and the two rows with their
stores.

=head2 text_to_board

Four lines, or just the two numeric rows, back into a board.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Board>, L<Game::Oware::Move>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
