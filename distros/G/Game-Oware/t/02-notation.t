#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware::Board;
use Game::Oware::Notation;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# The house indices here are written out rather than computed from the module
# under test, so that a fault in `index_of` cannot make a board test pass for
# the wrong reason.

subtest 'the letters and the indices' => sub {
	my @expect = ('A' .. 'F', 'a' .. 'f');

	is_deeply([ Game::Oware::Notation->letters ], \@expect, 'twelve letters in index order');

	for my $i (0 .. 11) {
		is(Game::Oware::Notation->letter_of($i), $expect[$i], "house $i is $expect[$i]");
		is(Game::Oware::Notation->index_of($expect[$i]), $i, "and $expect[$i] is house $i");
	}

	is(Game::Oware::Notation->seat_of('A'), 'p1', 'A belongs to p1');
	is(Game::Oware::Notation->seat_of('F'), 'p1', 'and so does F');
	is(Game::Oware::Notation->seat_of('a'), 'p2', 'a belongs to p2');
	is(Game::Oware::Notation->seat_of('f'), 'p2', 'and so does f');
};

subtest 'what is not a house' => sub {
	eval { Game::Oware::Notation->index_of('G') };
	like($@, qr/one of ABCDEFabcdef/, 'G is past the end of the row');

	eval { Game::Oware::Notation->index_of('g') };
	like($@, qr/one of ABCDEFabcdef/, 'and so is g');

	eval { Game::Oware::Notation->index_of('1') };
	like($@, qr/one of ABCDEFabcdef/, 'a house is never a number');

	eval { Game::Oware::Notation->index_of(undef) };
	like($@, qr/one of ABCDEFabcdef/, 'nor undef');

	eval { Game::Oware::Notation->letter_of(12) };
	like($@, qr/a house is 0 to 11/, 'and a store has no letter');
};

subtest 'a transcript round trips' => sub {
	my $text = 'EcAbFa';

	my $houses = Game::Oware::Notation->parse($text);
	is_deeply($houses, [ 4, 8, 0, 7, 5, 6 ], 'it parses to the right houses');

	is(Game::Oware::Notation->render($houses), $text, 'and renders back unchanged');

	# The twice-round form, which is where a notation with two spellings shows
	# itself: one pass can normalise, two cannot hide it.
	is(Game::Oware::Notation->render(Game::Oware::Notation->parse(
		Game::Oware::Notation->render($houses))), $text, 'twice round changes nothing');

	is_deeply(Game::Oware::Notation->parse(''), [], 'an empty transcript is no moves');
	is_deeply(Game::Oware::Notation->parse(" E c \n A "), [ 4, 8, 0 ],
		'and whitespace is not part of it');
};

# THE RULE THIS SUBTEST EXISTS FOR.
#
# Oware has no pass. The feeding obligation means a seat on turn always has
# seeds: if the opponent could feed them they were obliged to, and if they could
# not, the game is already over. So two moves in a row by one seat is something
# no game can produce, and a parser that quietly reattributed it would accept a
# transcript describing a game that cannot exist.
subtest 'the seats alternate, and p1 moves first' => sub {
	eval { Game::Oware::Notation->parse('EC') };
	like($@, qr/p2 to play/, 'p1 cannot move twice');

	eval { Game::Oware::Notation->parse('Ecb') };
	like($@, qr/p1 to play/, 'and neither can p2');

	eval { Game::Oware::Notation->parse('cE') };
	like($@, qr/p2's move, but it is p1 to play/, 'p2 does not open');

	is_deeply(Game::Oware::Notation->parse('Ec'), [ 4, 8 ], 'but alternating is fine');
};

subtest 'a board round trips through text' => sub {
	my $board = Game::Oware::Board->opening;
	$board->[12] = 3;
	$board->[13] = 5;
	$board->[0]  = 0;
	$board->[11] = 9;

	my $text = Game::Oware::Notation->board_to_text($board);

	is_deeply(Game::Oware::Notation->text_to_board($text), $board,
		'the board survives the trip');
	is(Game::Oware::Notation->board_to_text(
		Game::Oware::Notation->text_to_board($text)), $text,
		'and so does the text');

	my @lines = split /\n/, $text;
	is(scalar @lines, 4, 'four lines');
	like($lines[0], qr/f\s+e\s+d\s+c\s+b\s+a/, 'p2 reads f to a, right to left');
	like($lines[3], qr/A\s+B\s+C\s+D\s+E\s+F/, 'p1 reads A to F, left to right');
	like($lines[1], qr/\[5\]/, "p2's store sits on p2's row");
	like($lines[2], qr/\[3\]/, "and p1's on p1's");
};

subtest 'the headers are optional on the way back in' => sub {
	my $bare = " 2  2  1  2  3  1  [0]\n 3  1  4  0  6  2  [0]\n";
	my $board = Game::Oware::Notation->text_to_board($bare);

	is_deeply([ @{$board}[0 .. 5] ], [ 3, 1, 4, 0, 6, 2 ], "p1's row read from the lower line");
	is_deeply([ @{$board}[6 .. 11] ], [ 1, 3, 2, 1, 2, 2 ],
		"p2's row read right to left from the upper line");

	my $no_stores = " 2  2  1  2  3  1\n 3  1  4  0  6  2\n";
	is_deeply(Game::Oware::Notation->text_to_board($no_stores),
		[ 3, 1, 4, 0, 6, 2, 1, 3, 2, 1, 2, 2, 0, 0 ],
		'and a diagram with no stores drawn reads as two empty ones');
};

subtest 'what a board is not' => sub {
	eval { Game::Oware::Notation->text_to_board(" 1 2 3\n 4 5 6\n") };
	like($@, qr/a row is six houses/, 'a short row is refused');

	eval { Game::Oware::Notation->text_to_board(" 1 2 3 4 5 6\n") };
	like($@, qr/two rows/, 'and so is a single row');

	eval { Game::Oware::Notation->board_to_text([ (4) x 12 ]) };
	like($@, qr/fourteen cells/, 'a board without its stores is not a board');
};

done_testing;
