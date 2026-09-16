#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi::Board;
use Game::Reversi::Move;
use Game::Reversi::Notation;

# Squares, boards and transcripts as text.
#
# Parentheses on every Test::More call whose first argument is a Class->method
# call: without them it parses as indirect object syntax and becomes
# Class->is(...), which fails in a way that reads like a fault in the module.

my $N = 'Game::Reversi::Notation';
my $B = 'Game::Reversi::Board';

sub sq { return $N->text_to_square($_[0]) }

subtest 'a square, both ways' => sub {
	is($N->text_to_square('f5'), 29, 'f5');
	is($N->text_to_square('a8'), 0,  'a8 is the first cell');
	is($N->text_to_square('h1'), 63, 'h1 is the last');
	is($N->square_to_text(29), 'f5', 'and back again');

	is($N->text_to_square('F5'), 29, 'case does not matter');
	is($N->text_to_square(' f5 '), 29, 'nor does surrounding space');

	# undef rather than a false value, because square 0 is a real square and a
	# caller has to be able to tell "a8" from "not a square".
	is($N->text_to_square('i5'), undef, 'there is no file i');
	is($N->text_to_square('f9'), undef, 'there is no rank 9');
	is($N->text_to_square('f'),  undef, 'half a square is not a square');
	is($N->text_to_square(undef), undef, 'nor is nothing');

	for my $square (0 .. 63) {
		is($N->text_to_square($N->square_to_text($square)), $square,
			"square $square round trips") if $square % 7 == 0;
	}
	done_testing();
};

subtest 'a transcript is squares run together, which is the published form' => sub {
	my $squares = $N->parse('f5d6c3d3c4');
	is(scalar @$squares, 5, 'five moves');
	is_deeply($squares, [ map { sq($_) } qw(f5 d6 c3 d3 c4) ],
		'read in order, with no separators to help');
	is($N->render($squares), 'f5d6c3d3c4', 'and written back the same way');

	# A transcript pasted out of a mail or a forum post has usually picked up
	# spaces or commas, and refusing it would be pedantry rather than rigour.
	is_deeply($N->parse('f5 d6 c3 d3 c4'), $squares, 'spaces are tolerated');
	is_deeply($N->parse('f5,d6,c3,d3,c4'), $squares, 'and commas');
	is_deeply($N->parse('F5D6C3D3C4'),     $squares, 'and upper case');
	is_deeply($N->parse(''), [], 'an empty transcript is no moves, not an error');

	ok(!eval { $N->parse('f5 xx c3'); 1 }, 'something that is not a square dies');
	done_testing();
};

subtest 'a written pass is discarded, because the position decides' => sub {
	# A pass is forced, so where the passes fall is a fact about the position
	# and not about the transcript. Believing a written one would let a
	# transcript disagree with the rules and win.
	is_deeply($N->parse('f5--d6'), $N->parse('f5d6'),
		'a written pass does not become a move');
	is_deeply($N->parse('f5 pass d6'), $N->parse('f5d6'), 'nor does the word');
	done_testing();
};

# ---- replaying, which is where the passes come back -------------------------

# The Othello opening position, which is one of the six the historic opening can
# reach and the only one anybody has written about: dark on e4 and d5, light on
# d4 and e5, dark to move.
sub othello_start {
	my $board = $B->empty;
	$board->[ sq('e4') ] = 'b';
	$board->[ sq('d5') ] = 'b';
	$board->[ sq('d4') ] = 'w';
	$board->[ sq('e5') ] = 'w';
	return $board;
}

subtest 'a transcript replays, and each move is attributed to the right side' => sub {
	# Hand-derived from the Othello start, move by move. This is NOT presented
	# as a real game: it is a legal sequence worked out on paper, and every step
	# is named here so the vector can be checked rather than trusted.
	#
	#   f5  Black. West of f5 is e5 white, then d5 black, so e5 turns.
	#   d6  White. North of d6 is d5 black, then d4 white, so d5 turns.
	#   c3  Black. North east of c3 is d4 white, then e5 black, so d4 turns.
	#   d3  White. North of d3 is d4 black, then d5 white, so d4 turns.
	#   c4  Black. East of c4 is d4 white, then e4 black, so d4 turns.
	#
	# It happens to be an opening line real players use, which is a cross check
	# and not the provenance.
	my $steps = $N->walk(othello_start(), 'b', $N->parse('f5d6c3d3c4'));

	is(scalar @$steps, 5, 'five moves replayed');
	is_deeply([ map { $_->{colour} } @$steps ], [ qw(b w b w b) ],
		'and the colours alternate, because nobody had to pass');
	is_deeply([ map { $_->{passes} } @$steps ], [ 0, 0, 0, 0, 0 ],
		'so no passes were inserted');

	is_deeply($steps->[0]{flips}, [ sq('e5') ], 'f5 turned e5');
	is_deeply($steps->[1]{flips}, [ sq('d5') ], 'd6 turned d5');
	is_deeply($steps->[2]{flips}, [ sq('d4') ], 'c3 turned d4');
	is_deeply($steps->[3]{flips}, [ sq('d4') ], 'd3 turned d4 back');
	is_deeply($steps->[4]{flips}, [ sq('d4') ], 'and c4 turned it again');

	# Every disc on the board is accounted for: four to begin with plus one per
	# move, since each of these turned exactly one and a turn moves a disc from
	# one column of the count to the other.
	my $count = $B->count($steps->[-1]{board});
	is($count->{b} + $count->{w}, 9, 'nine discs after five moves');
	done_testing();
};

subtest 'the four moves open to Black from the Othello position' => sub {
	# Every published opening book starts here, so this is the one position in
	# the game whose legal moves can be checked against the outside world.
	my @moves = sort map { $B->name_of($_) } $B->legal_moves(othello_start(), 'b');
	is_deeply(\@moves, [ qw(c4 d3 e6 f5) ],
		'c4, d3, e6 and f5, and nothing else');
	done_testing();
};

subtest 'a forced pass is put back, and the move after it changes hands' => sub {
	# THE TEST THIS FILE EXISTS FOR. A transcript carries squares and no
	# colours, so a reader that assumes strict alternation misattributes every
	# move after a pass, silently.
	#
	# The position, hand-derived so that the pass is forced and provable:
	#
	#   Black on h4, White on g4, everything else empty. White to move.
	#
	# White cannot move. White's only disc is g4, so any legal white move needs
	# a ray running over black discs and ending on g4. The only black disc is
	# h4, and the only square from which a ray reaches h4 and then g4 is east of
	# h4, which is off the board. So White forfeits.
	#
	# Black can move: f4 runs east over g4, white, and ends on h4, black.
	#
	# A reader that alternated would call f4 a White move and turn the board
	# inside out.
	my $board = $B->empty;
	$board->[ sq('h4') ] = 'b';
	$board->[ sq('g4') ] = 'w';

	ok(!$B->has_move($board, 'w'), 'White has no legal move, as derived');
	ok($B->has_move($board, 'b'),  'Black has one');

	# Evaluated rather than called straight, because a reader that alternated
	# would not merely attribute f4 wrongly, it would find f4 illegal for White
	# and die inside walk, taking the rest of this file with it. The point of
	# the subtest is the attribution, so the death is reported as a failure here
	# and the remaining subtests still get to run.
	my $steps = eval { $N->walk($board, 'w', $N->parse('f4')) };
	ok($steps, 'the transcript replays at all') or do {
		diag("walk died: $@");
		done_testing();
		return;
	};

	is(scalar @$steps, 1, 'one move in the transcript');
	is($steps->[0]{colour}, 'b', 'and it belongs to Black, not to White whose turn it was');
	is($steps->[0]{passes}, 1, 'because one turn was forfeited before it');
	is_deeply($steps->[0]{flips}, [ sq('g4') ], 'and it turned g4');

	is($N->render_with_passes($steps), '--f4',
		'written out, the pass is shown even though it was not in the input');
	done_testing();
};

subtest 'a transcript that does not fit the position is refused' => sub {
	ok(!eval { $N->walk(othello_start(), 'b', $N->parse('a1')); 1 },
		'a square that outflanks nothing is refused');
	like($@, qr/cannot play/, 'and says so');

	ok(!eval { $N->walk(othello_start(), 'b', $N->parse('d4')); 1 },
		'so is a square that already holds a disc');

	# Neither side can move on an empty board, so any transcript at all runs
	# past the end of the game.
	ok(!eval { $N->walk($B->empty, 'b', $N->parse('d4')); 1 },
		'a transcript that continues past the end of the game is refused');
	like($@, qr/past the end/, 'and says that instead');
	done_testing();
};

# ---- boards as pictures -----------------------------------------------------

subtest 'a board is eight lines of eight, and the two are exact inverses' => sub {
	my $text = $N->board_to_text(othello_start());
	my @lines = split /\n/, $text;
	is(scalar @lines, 8, 'eight lines');
	is(length $lines[0], 8, 'of eight characters');
	is($lines[3], '...bw...', 'rank 5 is dark on d5 and light on e5');
	is($lines[4], '...wb...', 'rank 4 is light on d4 and dark on e4');

	is_deeply($N->text_to_board($text), othello_start(), 'and it reads back');
	is($N->board_to_text($N->text_to_board($text)), $text, 'round trip');

	ok(!eval { $N->text_to_board("...\n...\n"); 1 }, 'a short board is refused');
	ok(!eval { $N->text_to_board(join "\n", ('x' x 8) x 8); 1 },
		'and so is a character that is not a disc');
	done_testing();
};

# ---- the move object --------------------------------------------------------

subtest 'a move knows which of the two kinds it is' => sub {
	my $place = Game::Reversi::Move->place(sq('d4'), 'b');
	is($place->phase, 'place', 'a placement');
	is($place->name, 'd4', 'knows its square');
	is($place->turned, 0, 'and turns nothing');

	my $play = Game::Reversi::Move->play(sq('f5'), 'b', sq('e5'));
	is($play->phase, 'play', 'a play');
	is($play->turned, 1, 'turns what it outflanked');
	is_deeply($play->flips, [ sq('e5') ], 'and says which');

	# The two rules a hand-built move can violate.
	ok(!eval { Game::Reversi::Move->new(phase => 'place', square => 0,
		colour => 'b', flips => [ 1 ]); 1 }, 'a placement that flips is refused');
	ok(!eval { Game::Reversi::Move->play(sq('f5'), 'b'); 1 },
		'and so is a play that flips nothing');
	ok(!eval { Game::Reversi::Move->place(sq('d4'), 'x'); 1 },
		'a colour that is not b or w is refused');
	ok(!eval { Game::Reversi::Move->place(64, 'b'); 1 },
		'and a square off the board');
	done_testing();
};

subtest 'the turned discs are called flips, and nothing is called line' => sub {
	# The site's leak gate refuses any view key matching
	# /\A(score|depth|nodes|pv|line|eval|search|hint)\z/, so a field named line
	# here would fail a test about search leakage several phases from now, in a
	# way that reads as a bug in the gate. Cheaper to assert it at the source.
	my $play = Game::Reversi::Move->play(sq('f5'), 'b', sq('e5'));
	ok($play->can('flips'), 'flips is the accessor');
	ok(!$play->can('line'), 'and there is no line');

	my $source = do {
		open my $fh, '<', $INC{'Game/Reversi/Move.pm'} or die $!;
		local $/; <$fh>;
	};
	unlike($source, qr/^\s*has\s+line\b/m, 'no attribute named line is declared');
	done_testing();
};

done_testing();
