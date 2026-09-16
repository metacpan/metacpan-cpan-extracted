#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi::Board;

# NOTE: every Test::More call whose first argument is a Class->method(...) call
# needs its own parentheses. Without them `is Game::Reversi::Board->count($b),`
# parses as indirect object syntax and becomes Game::Reversi::Board->is(...),
# which fails with "Can't locate object method is". It reads like a typo in the
# module rather than in the test, which is what makes it worth a comment.

# The board, the eight rays, and what outflanks what.
#
# Every vector here is hand-derived and the derivation is written above it. A
# Reversi engine that generates its own vectors can only ever confirm the bug it
# was born with, and the bug this file exists for is exactly the kind that looks
# like a working game.

# The square index, computed here independently of Game::Reversi::Notation so
# that a fault in the notation cannot make a board test pass or fail for the
# wrong reason. Row 0 is rank 8, column 0 is file a, index is row * 8 + col.
sub sq {
	my ($name) = @_;
	my ($f, $r) = $name =~ /\A([a-h])([1-8])\z/
		or die "bad square name $name";
	return (8 - $r) * 8 + (ord($f) - ord('a'));
}

# A board from a picture: square name => colour.
sub board_of {
	my (%at) = @_;
	my $b = Game::Reversi::Board->empty;
	$b->[ sq($_) ] = $at{$_} for keys %at;
	return $b;
}

sub names { return join ',', sort map { Game::Reversi::Board->name_of($_) } @_ }

subtest 'the numbering, which everything else depends on' => sub {
	is sq('a8'), 0,  'a8 is the first cell, because row 0 is rank 8';
	is sq('h8'), 7,  'h8 ends the first row';
	is sq('a1'), 56, 'a1 begins the last row';
	is sq('h1'), 63, 'h1 is the last cell';

	# The centre four, which phase 02 places into.
	is sq('d5'), 27, 'd5';
	is sq('e5'), 28, 'e5';
	is sq('d4'), 35, 'd4';
	is sq('e4'), 36, 'e4';

	# The module must agree with the test's own arithmetic, in both directions.
	for my $name (qw(a8 h8 a1 h1 d5 e5 d4 e4 c3 f6)) {
		is(Game::Reversi::Board->square_of(substr($name, 0, 1), substr($name, 1, 1)),
			sq($name), "square_of agrees on $name");
		is(Game::Reversi::Board->name_of(sq($name)), $name,
			"name_of round trips $name");
	}
	done_testing();
};

subtest 'an empty cell is not a colour' => sub {
	# The reason the cells hold undef / 'b' / 'w' and not 0 / 1 / 2: index 0 is
	# a real square and 0 is a plausible colour, so a truth test on a cell must
	# not be able to mean "not black".
	my $b = Game::Reversi::Board->empty;
	is scalar @$b, 64, 'sixty four cells';
	is scalar(grep { defined } @$b), 0, 'all empty to begin with';
	ok !defined $b->[0], 'and an empty cell is undef rather than a false colour';
	done_testing();
};

# ---- the edge wrap, which is the only bug that matters in this file ----------
#
# A ray walked by adding a stride to a flat index runs off the right hand edge
# of one rank and reappears on the left hand edge of the next. It stays inside
# 0 .. 63, so a bounds check on the index alone does not catch it. It produces
# legal moves that look entirely plausible and flips discs along a line no
# player can see.
#
# Each vector below is built so that the CORRECT answer is zero flips and the
# WRAPPING answer is a specific non-zero number. A vector where both answers are
# zero proves nothing, which is the trap: most positions never touch an edge.

subtest 'a ray does not wrap off the east edge' => sub {
	# White fills a4 to g4 and Black sits on h4. Black plays h5.
	#
	# Correct: h5 is on column 7, so the east ray leaves the board at once. The
	# south ray meets Black's own h4 immediately. The south west ray meets g4,
	# white, then f3, empty. Nothing flips anywhere, and Black has no legal move
	# on this board at all.
	#
	# Wrapping: h5 is index 31, and 31 + 1 is 32, which is a4. The walk then
	# runs a4, b4 .. g4, all white, and stops on h4, black. It reports seven
	# flips and offers h5 as a legal move.
	my $b = board_of(
		a4 => 'w', b4 => 'w', c4 => 'w', d4 => 'w',
		e4 => 'w', f4 => 'w', g4 => 'w', h4 => 'b',
	);

	is names(Game::Reversi::Board->flips_for($b, sq('h5'), 'b')), '',
		'h5 flips nothing, so the east ray did not wrap onto rank 4';
	is names(Game::Reversi::Board->legal_moves($b, 'b')), '',
		'and Black has no legal move on this board at all';
	done_testing();
};

subtest 'a ray does not wrap off the west edge' => sub {
	# The mirror. White fills b5 to h5, Black sits on a5, and Black plays a4.
	#
	# Correct: a4 is on column 0, so the west ray leaves the board at once, and
	# the north ray meets Black's own a5. Nothing flips.
	#
	# Wrapping: a4 is index 32, and 32 - 1 is 31, which is h5. The walk runs
	# h5, g5 .. b5, all white, and stops on a5, black. Seven flips again.
	my $b = board_of(
		a5 => 'b', b5 => 'w', c5 => 'w', d5 => 'w',
		e5 => 'w', f5 => 'w', g5 => 'w', h5 => 'w',
	);

	is names(Game::Reversi::Board->flips_for($b, sq('a4'), 'b')), '',
		'a4 flips nothing, so the west ray did not wrap onto rank 5';
	done_testing();
};

subtest 'a diagonal ray does not wrap either' => sub {
	# The diagonals wrap too, and by a larger stride, so they are worth their
	# own vector rather than being assumed to follow from the orthogonals.
	#
	# Black plays a4, which is on column 0, so its south west ray leaves the
	# board at once and nothing can flip.
	#
	# Wrapping: a4 is index 32 and the south west stride is +7, giving 39, 46,
	# 53, which are h4, g3 and f2. With white on h4 and g3 and black on f2 that
	# walk reports two flips along an anti diagonal at the other end of the
	# board.
	my $b = board_of(h4 => 'w', g3 => 'w', f2 => 'b');

	is names(Game::Reversi::Board->flips_for($b, sq('a4'), 'b')), '',
		'a4 flips nothing, so the south west ray did not wrap';
	done_testing();
};

# ---- the capture rules ------------------------------------------------------

subtest 'one move outflanks in more than one direction at once' => sub {
	# The rule the World Othello Federation's own numbered list omits: its rules
	# run 1, 2, 4, 5, 6, 7, 8, and the missing rule 3 is the one that says a
	# disc may outflank in several directions at the same time. Wikipedia:
	# "Multiple chains of disks may be captured in a single move."
	#
	# So this is cited from Wikipedia, not from WOF, and it is tested because a
	# plausible implementation returns the first ray that hits and stops.
	#
	# White on e4 and d3, Black on f4 and d2. Black plays d4:
	#   east  d4 -> e4 white -> f4 black, so e4 turns
	#   south d4 -> d3 white -> d2 black, so d3 turns
	my $b = board_of(e4 => 'w', d3 => 'w', f4 => 'b', d2 => 'b');

	is names(Game::Reversi::Board->flips_for($b, sq('d4'), 'b')), 'd3,e4',
		'both rays flip, not just the first one found';

	my @in_order = Game::Reversi::Board->flips_for($b, sq('d4'), 'b');
	is scalar @in_order, 2, 'exactly two discs turn';
	is $in_order[0], sq('e4'), 'and they come back in ray order, east before south';
	done_testing();
};

subtest 'a line of your own colour does not outflank' => sub {
	# WOF rule 4: "Players may not skip over their own colour disc(s) to
	# outflank an opposing disc."
	#
	# Black on d4, White on e4, Black on f4. Black plays c4. Walking east the
	# very first disc is Black's own d4, so there is nothing to outflank even
	# though a white disc is sitting two squares further along bounded by black.
	my $b = board_of(d4 => 'b', e4 => 'w', f4 => 'b');

	is names(Game::Reversi::Board->flips_for($b, sq('c4'), 'b')), '',
		'c4 outflanks nothing, because the ray opens with a black disc';
	ok !(grep { $_ == sq('c4') } Game::Reversi::Board->legal_moves($b, 'b')),
		'so c4 is not a legal move';
	done_testing();
};

subtest 'an empty square stops a ray' => sub {
	# WOF rule 5: outflanked discs "must fall in the direct line of the disc
	# placed down", so a gap ends the line and the discs beyond it are not in it.
	#
	# White on d4 and e4, f4 EMPTY, Black on g4. Black plays c4 and the walk
	# reaches the gap before it reaches the black disc.
	my $b = board_of(d4 => 'w', e4 => 'w', g4 => 'b');

	is names(Game::Reversi::Board->flips_for($b, sq('c4'), 'b')), '',
		'the gap at f4 ends the line, so d4 and e4 do not turn';
	done_testing();
};

subtest 'a disc on the far edge with nothing behind it bounds nothing' => sub {
	# White on g4 and h4, Black plays f4. The ray runs g4, h4 and then leaves
	# the board without ever meeting a black disc, so nothing is outflanked.
	# This is the same shape as the gap case and it is the one an implementation
	# that returns what it has collected so far gets wrong.
	my $b = board_of(g4 => 'w', h4 => 'w');

	is names(Game::Reversi::Board->flips_for($b, sq('f4'), 'b')), '',
		'a ray that runs off the board flips nothing';
	done_testing();
};

subtest 'an occupied square is never a move' => sub {
	my $b = board_of(e4 => 'w', f4 => 'b');
	is names(Game::Reversi::Board->flips_for($b, sq('e4'), 'b')), '',
		'a square that already holds a disc outflanks nothing';
	ok !(grep { $_ == sq('e4') } Game::Reversi::Board->legal_moves($b, 'b')),
		'and is not offered';
	done_testing();
};

# ---- applying a move --------------------------------------------------------

subtest 'every outflanked disc turns, and the board is not mutated' => sub {
	# WOF rule 6: "All discs outflanked in any one move must be flipped, even if
	# it is to the player's advantage not to flip them at all." So apply takes
	# no options: there is no partial flip and no choice.
	my $b = board_of(e4 => 'w', d3 => 'w', f4 => 'b', d2 => 'b');
	my $after = Game::Reversi::Board->apply($b, sq('d4'), 'b');

	is $after->[ sq('d4') ], 'b', 'the disc is placed';
	is $after->[ sq('e4') ], 'b', 'the disc east of it turned';
	is $after->[ sq('d3') ], 'b', 'and the disc south of it turned';
	is $after->[ sq('f4') ], 'b', 'the bounding disc is untouched';
	is $after->[ sq('d2') ], 'b', 'as is the other one';

	is $b->[ sq('d4') ], undef, 'the board handed in is unchanged';
	is $b->[ sq('e4') ], 'w',   'including the discs that turned in the copy';
	done_testing();
};

subtest 'a move that outflanks nothing is refused' => sub {
	# WOF, via Wikipedia: "A valid move is one where at least one piece is
	# reversed (flipped over)." So legality is not a separate rule to be kept in
	# step with flips_for; it IS flips_for returning something.
	my $b = board_of(d4 => 'b', e4 => 'w', f4 => 'b');
	ok !eval { Game::Reversi::Board->apply($b, sq('c4'), 'b'); 1 },
		'applying a move that flips nothing dies, because it is programmer error';
	done_testing();
};

# ---- counting ---------------------------------------------------------------

subtest 'counting, and a board with no move left in it' => sub {
	my $b = board_of(d4 => 'b', e4 => 'w', f4 => 'b', d3 => 'w', c3 => 'w');
	is_deeply(Game::Reversi::Board->count($b), { b => 2, w => 3 },
		'discs are counted by colour');
	is(Game::Reversi::Board->empties($b), 59, 'and the empty squares with them');

	my $full = Game::Reversi::Board->empty;
	$_ = 'b' for @$full;
	is_deeply(Game::Reversi::Board->count($full), { b => 64, w => 0 },
		'a full board counts 64');
	is(Game::Reversi::Board->empties($full), 0, 'with nothing empty');
	is names(Game::Reversi::Board->legal_moves($full, 'w')), '',
		'and offers no move to either side';
	is names(Game::Reversi::Board->legal_moves($full, 'b')), '', 'nor to the other';
	done_testing();
};

subtest 'the eight rays are eight, and they are opposites in pairs' => sub {
	# A cheap structural check that catches a duplicated or dropped ray, which
	# otherwise shows up as a subtly weak engine rather than as a failure.
	my @rays = Game::Reversi::Board->rays;
	is scalar @rays, 8, 'eight rays';

	my %seen = map { join(',', @$_) => 1 } @rays;
	is scalar keys %seen, 8, 'all distinct';
	for my $r (@rays) {
		ok $seen{ join ',', -$r->[0], -$r->[1] },
			"the opposite of ($r->[0],$r->[1]) is there too";
		ok !($r->[0] == 0 && $r->[1] == 0), 'and none of them stands still';
	}
	done_testing();
};

done_testing();
