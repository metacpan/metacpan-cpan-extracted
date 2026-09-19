#!perl

# TWO ALPHABETS FOR ONE BOARD, AND THEY ARE NOT THE SAME ALPHABET.
#
# HUMAN notation, which a board edge, a book and a tournament sheet all print:
# columns A to T with I OMITTED, and rows numbered from the BOTTOM.
#
#     A B C D E F G H J K L M N O P Q R S T
#
# SGF notation, from the FF[4] Go specification:
#
#   The first letter designates the column (left to right), the second the row
#   (top to bottom). The upper left part of the board is used for smaller
#   boards, e.g. letters "a"-"m" for 13*13.
#
# Nothing is skipped and the rows run the other way. So on a 19x19 board:
#
#                    human    SGF     column index
#      top left       A19      aa          0
#      bottom left    A1       as          0
#      the trap       J10      ij          8      J is the NINTH human column
#      the trap       K10      jj          9      j is the TENTH sgf letter
#
# J10 AND jj ARE ONE COLUMN APART. Both read as "the tenth column, row ten" to
# anybody not paying attention, and they are different points. Every pair below
# is derived by hand from the two rules above, not read off the code.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Notation;

my $N = 'Game::Go::Notation';

sub human { Game::Go::Notation::to_human(@_) }
sub sgf   { Game::Go::Notation::to_sgf(@_) }
sub unhuman { Game::Go::Notation::from_human(@_) }
sub unsgf   { Game::Go::Notation::from_sgf(@_) }

subtest 'the human column letters skip I' => sub {
	my @cols = map { Game::Go::Notation::col_letter($_) } 0 .. 18;
	is_deeply(\@cols, [qw(A B C D E F G H J K L M N O P Q R S T)],
		'nineteen columns, A to T, with no I');
	is(scalar(grep { $_ eq 'I' } @cols), 0, 'I is not among them');

	is(Game::Go::Notation::letter_col('A'), 0, 'A is the first column');
	is(Game::Go::Notation::letter_col('H'), 7, 'H is the eighth');
	is(Game::Go::Notation::letter_col('J'), 8, 'J is the NINTH, because I is missing');
	is(Game::Go::Notation::letter_col('K'), 9, 'K is the tenth');
	is(Game::Go::Notation::letter_col('T'), 18, 'T is the nineteenth');
	is(Game::Go::Notation::letter_col('I'), undef, 'and I is not a column at all');
	is(Game::Go::Notation::letter_col('j'), 8, 'lowercase is accepted');
	done_testing();
};

subtest 'the hand-derived table, 19x19' => sub {
	# col, row, human, sgf. Derived from the two rules and nothing else:
	#   human column = the index into A..T less I
	#   human row    = size - engine row        (numbered from the BOTTOM)
	#   sgf column   = 'a' + index              (nothing skipped)
	#   sgf row      = 'a' + engine row         (numbered from the TOP)
	my @table = (
		[ 0,  0,  'A19', 'aa' ],   # top left
		[ 0,  18, 'A1',  'as' ],   # bottom left
		[ 18, 0,  'T19', 'sa' ],   # top right
		[ 18, 18, 'T1',  'ss' ],   # bottom right
		[ 3,  15, 'D4',  'dp' ],   # the 4-4 star point, bottom left
		[ 7,  9,  'H10', 'hj' ],   # the column BEFORE the missing I
		[ 8,  9,  'J10', 'ij' ],   # the column after it
		[ 9,  9,  'K10', 'jj' ],   # tengen
	);

	for my $r (@table) {
		my ($col, $row, $h, $s) = @$r;
		is(human(19, $col, $row), $h, "($col,$row) is $h");
		is(sgf(19, $col, $row), $s, "($col,$row) is $s");
		is_deeply([ unhuman(19, $h) ], [ $col, $row ], "$h is ($col,$row)");
		is_deeply([ unsgf(19, $s) ], [ $col, $row ], "$s is ($col,$row)");
	}

	# AND THE TRAP, ASSERTED DIRECTLY. Neither of these is an accident of the
	# table above; they are why the table exists.
	isnt(join(',', unhuman(19, 'J10')), join(',', unsgf(19, 'jj')),
		'J10 and jj are DIFFERENT POINTS');
	is_deeply([ unhuman(19, 'J10') ], [ 8, 9 ], 'J10 is column eight');
	is_deeply([ unsgf(19, 'jj') ], [ 9, 9 ], 'and jj is column nine');
	is(sgf(19, unhuman(19, 'J10')), 'ij', 'human J10 written as SGF is ij, not jj');
	is(human(19, unsgf(19, 'jj')), 'K10', 'and SGF jj written for a human is K10, not J10');
	done_testing();
};

subtest 'the row origin, which runs the other way' => sub {
	# Human rows count from the BOTTOM and SGF rows from the TOP, so the two
	# disagree about every row except the middle one.
	for my $row (0 .. 18) {
		my $h = human(19, 0, $row);
		my ($n) = $h =~ /([0-9]+)/;
		is($n, 19 - $row, "engine row $row is human row " . (19 - $row));
		is(sgf(19, 0, $row), 'a' . chr(ord('a') + $row), "and SGF row " . ($row + 1));
	}

	# The one row they agree about, on an odd-sized board.
	is(human(19, 0, 9), 'A10', 'the middle row is human 10');
	is(sgf(19, 0, 9), 'aj', 'and SGF j, which is the tenth letter');
	done_testing();
};

subtest 'every size, and nothing off the board' => sub {
	for my $size (Game::Go->sizes) {
		my $last = $size - 1;

		is(human($size, 0, 0), 'A' . $size, "size $size: top left is A$size");
		is(human($size, 0, $last), 'A1', "size $size: bottom left is A1");
		is(sgf($size, 0, 0), 'aa', "size $size: top left is aa");
		is(sgf($size, $last, $last), chr(ord('a') + $last) x 2, "size $size: bottom right");

		# The last human column letter, which is where the missing I shows.
		my $last_letter = Game::Go::Notation::col_letter($last);
		is($last_letter, ($size == 9 ? 'J' : $size == 13 ? 'N' : 'T'),
			"size $size: the last column is $last_letter");

		# Off the board, both ways, both alphabets.
		is(human($size, $size, 0), undef, "size $size: a column past the edge");
		is(human($size, 0, $size), undef, "size $size: a row past the edge");
		is(human($size, -1, 0), undef, "size $size: a negative column");
		is_deeply([ unhuman($size, 'A' . ($size + 1)) ], [], "size $size: a row number too big");
		is_deeply([ unhuman($size, 'Z1') ], [], "size $size: a column letter too far");
		is_deeply([ unsgf($size, chr(ord('a') + $size) . 'a') ], [], "size $size: an SGF column too far");
	}
	done_testing();
};

subtest 'a pass is not a point' => sub {
	# from_sgf refuses both pass spellings rather than quietly returning
	# something. Game::Go::SGF is the thing that knows a pass is a move.
	is_deeply([ unsgf(19, '') ], [], 'the empty string is not a point');
	is_deeply([ unsgf(19, 'tt') ], [], 'and neither is tt');

	# tt works as a sentinel precisely BECAUSE it is column 20, off any board
	# this distribution offers. On a 26x26 board it would be a real point,
	# which is why the spec limits it to boards of 19 and under.
	is(Game::Go::Notation::letter_col('T'), 18, 'T is the last human column on 19x19');
	is_deeply([ unsgf(19, 'ss') ], [ 18, 18 ], 'and ss is the last SGF point');
	done_testing();
};

subtest 'round trips, over the whole board' => sub {
	for my $size (Game::Go->sizes) {
		my ($human_ok, $sgf_ok) = (0, 0);
		for my $row (0 .. $size - 1) {
			for my $col (0 .. $size - 1) {
				my $h = human($size, $col, $row);
				my $s = sgf($size, $col, $row);
				$human_ok++ if join(',', unhuman($size, $h)) eq "$col,$row";
				$sgf_ok++   if join(',', unsgf($size, $s)) eq "$col,$row";
			}
		}
		is($human_ok, $size * $size, "size $size: every point round-trips through human notation");
		is($sgf_ok, $size * $size, "size $size: and through SGF");
	}
	done_testing();
};

subtest 'a transcript reads as moves' => sub {
	my $B = Game::Go::BLACK;
	my $W = Game::Go::WHITE;
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(3, 5));
	$g->play($W, $g->point(0, 8));
	$g->pass($B);

	my $t = Game::Go::Notation::transcript($g);
	is_deeply($t, [ 'black D4', 'white A1', 'black pass' ],
		'moves in human coordinates, passes included');

	# (3,5) on a 9x9 is D4: column D is the fourth, and row 5 from the top is
	# row 4 from the bottom.
	is(human(9, 3, 5), 'D4', 'which is the hand-derived name for that point');
	done_testing();
};

done_testing();
