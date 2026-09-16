#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;
use Game::Checkers::Terminal;

sub terminal {
	my (%option) = @_;
	my $buffer = '';
	open my $out, '>', \$buffer or die "in memory handle: $!";
	my $terminal = Game::Checkers::Terminal->new(
		out => $out,
		interactive => 0,
		colour => 0,
		ascii => 1,
		%option
	);
	return ($terminal, \$buffer);
}

subtest 'the opening board, to the character' => sub {
	plan tests => 2;
	# written out by hand: the file letters sit over the middle of their cells
	# and an empty playing square is a dot, so the played half of the board can
	# be seen. There are no square numbers on it: a move is read off the edge
	my @expect = split m/\n/, <<'BOARD';
     a   b   c   d   e   f   g   h
   +---+---+---+---+---+---+---+---+
 8 |   | b |   | b |   | b |   | b |  Black 12  (0 kings)
   +---+---+---+---+---+---+---+---+
 7 | b |   | b |   | b |   | b |   |  White 12  (0 kings)
   +---+---+---+---+---+---+---+---+
 6 |   | b |   | b |   | b |   | b |
   +---+---+---+---+---+---+---+---+
 5 | . |   | . |   | . |   | . |   |
   +---+---+---+---+---+---+---+---+
 4 |   | . |   | . |   | . |   | . |
   +---+---+---+---+---+---+---+---+
 3 | w |   | w |   | w |   | w |   |
   +---+---+---+---+---+---+---+---+
 2 |   | w |   | w |   | w |   | w |
   +---+---+---+---+---+---+---+---+
 1 | w |   | w |   | w |   | w |   |
   +---+---+---+---+---+---+---+---+
BOARD

	my ($terminal) = terminal();
	is_deeply $terminal->board_lines, \@expect, 'the board is drawn as designed';
	# the cells only, so the rank down the side and the piece counts beside it
	# are not mistaken for numbering on the board
	my @cell = map { m/^\s*[1-8] \|(.*\|)/ ? $1 : () } @{$terminal->board_lines};
	ok !grep({ m/[0-9]/ } @cell), 'and no square number is written inside it';
};

subtest 'kings and flipping' => sub {
	plan tests => 3;
	my ($terminal) = terminal(game => Game::Checkers->new(fen => 'B:WK32:BK1'));
	my $lines = $terminal->board_lines;
	like $lines->[2], qr/\| B \|/, 'a black king is B';
	like $lines->[-2], qr/\| W \|/, 'and a white king is W';

	$terminal->flip(1);
	$lines = $terminal->board_lines;
	like $lines->[0], qr/h   g   f   e   d   c   b   a/,
		'flipped, the files run the other way';
};

subtest 'ascii is ascii and colour is optional' => sub {
	plan tests => 4;
	my ($plain, $buffer) = terminal();
	$plain->render;
	unlike ${$buffer}, qr/[^\x00-\x7f]/, 'with ascii there is no wide character';
	unlike ${$buffer}, qr/\e/, 'and with colour off there is no escape';

	my ($wide, $wide_buffer) = terminal(ascii => 0);
	$wide->render;
	like ${$wide_buffer}, qr/[^\x00-\x7f]/, 'without ascii the symbols are drawn';

	my ($painted, $painted_buffer) = terminal(colour => 1);
	$painted->render;
	like ${$painted_buffer}, qr/\e\[/, 'and colour puts escapes in';
};

subtest 'the status block' => sub {
	plan tests => 5;
	my ($terminal) = terminal();
	is_deeply $terminal->status_lines, ['Black to move, 7 moves'],
		'whose turn it is, and how much choice they have';

	$terminal->game->move('11-15');
	$terminal->game->move('22-18');
	is_deeply $terminal->status_lines,
		['Last: c3-d4 by white', 'Black must capture, 1 jump available'],
		'the last move named by its squares, and the compulsion';

	$terminal->game->move('15x22');
	like $terminal->status_lines->[0], qr/^Last: e5xc3 by black, taking d4$/,
		'a jump is its path, and says what it took';

	$terminal->game->offer_draw('black');
	like $terminal->status_lines->[-1], qr/Black has offered a draw/, 'an offer shows';

	$terminal->game->resign('black');
	is $terminal->status_lines->[-1], 'White wins: Black resigned',
		'and the result replaces the rest';
};

subtest 'the screen is only cleared for a person' => sub {
	plan tests => 2;
	my ($quiet, $buffer) = terminal();
	$quiet->clear;
	is ${$buffer}, '', 'a captured transcript is not full of escape codes';

	my ($live, $live_buffer) = terminal(interactive => 1, colour => 0);
	$live->clear;
	is ${$live_buffer}, "\e[2J\e[H", 'but a terminal gets its screen cleared';
};

done_testing;
