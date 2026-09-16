#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi::Board;
use Game::Reversi::Scoring;
use Game::Reversi::Rules;

# Three real tournament games, with their final positions and their published
# scores.
#
# THESE ARE THE ONLY FULLY EXTERNAL VECTORS THIS DISTRIBUTION HAS. Everything
# else in the suite is either a rule derived by hand or an invariant over games
# this engine played. Here the board AND the number come from outside, from
# somebody who was not writing this code, so the scoring rule is checked against
# the world rather than against itself.
#
# Source: https://en.wikipedia.org/wiki/Reversi, the section headed "Examples
# where the game ends before the grid is completely filled", fetched 15 Sep
# 2026. The article draws each final position as a grid and captions it with the
# result. The boards below are transcribed from those grids: X is dark, O is
# light, a space is an empty square.
#
# What makes them worth having is that all three ended with the board NOT full,
# and all three published scores total exactly 64. That is the empty squares
# rule showing up in the wild:
#
#     WOF, World Othello Championships rules, IV.7: "The official score of the
#     game will be determined by counting up the discs of each colour on the
#     board, counting empty squares for the winner."
#
# An engine scoring by raw disc count would report 1-58, 13-45 and 3-17 for
# these three and disagree with every published record of them.

my $B = 'Game::Reversi::Board';
my $S = 'Game::Reversi::Scoring';

# A board from eight rows of eight characters. 'X' dark, 'O' light, anything
# else empty.
sub board_of {
	my (@rows) = @_;
	die 'a board is eight rows' unless @rows == 8;
	my $board = $B->empty;
	for my $row (0 .. 7) {
		my @cells = split //, $rows[$row];
		die 'a row is eight squares' unless @cells == 8;
		for my $col (0 .. 7) {
			$board->[ $row * 8 + $col ] =
				  $cells[$col] eq 'X' ? 'b'
				: $cells[$col] eq 'O' ? 'w'
				: undef;
		}
	}
	return $board;
}

# dark, light, and the published score for each.
my @GAMES = (
	{
		name  => 'Vlasakova 1 - 63 Schotte, European Grand Prix Prague 2011',
		rows  => [
			'OOOOOOOO',
			'OOOOOOOO',
			'OOOOOOOO',
			'OOOOOOO ',
			'OOOOOO  ',
			'OOOOOO X',
			'OOOOOOO ',
			'OOOOOOOO',
		],
		dark  => 1,       # the published score for the dark player
		light => 63,
	},
	{
		name  => 'Vecchi 13 - 51 Nicolas, World Othello Championship 2017, Ghent',
		rows  => [
			' XXXXXXX',
			' OOOOO X',
			'OOOOOOOX',
			'OOOOOOOX',
			'OOOOOOOX',
			'OOOOOOOX',
			'OOOOOOOX',
			' OOOOO  ',
		],
		dark  => 13,
		light => 51,
	},
	{
		name  => 'Hassan 3 - 61 Verstuyft J., European Grand Prix Ghent 2017',
		rows  => [
			'    O   ',
			'    OO  ',
			'OOOOOOOX',
			'  OOOO X',
			'  OOO  X',
			'        ',
			'        ',
			'        ',
		],
		dark  => 3,
		light => 61,
	},
);

for my $game (@GAMES) {
	subtest $game->{name} => sub {
		my $board = board_of(@{ $game->{rows} });

		# The transcription is worth checking before the rule is: a board that
		# does not hold the number of discs the caption implies would make the
		# score come out right for the wrong reason.
		my $count = $S->count($board);
		is($count->{b}, $game->{dark},
			"the loser's discs on the board match the published score, $game->{dark}");
		cmp_ok($B->empties($board), '>', 0,
			'and the game really did end with squares still empty');

		# The rule.
		my $score = $S->score($board);
		is($score->{b}, $game->{dark}, "dark scores $game->{dark}");
		is($score->{w}, $game->{light}, "light scores $game->{light}");
		is($score->{b} + $score->{w}, 64, 'and the score totals 64, as every published one does');

		# What a raw disc count would have said, so the difference is on the
		# record rather than implied.
		isnt($count->{w}, $score->{w},
			'a raw disc count would have disagreed with the published score');

		is($S->winner($board), 'w', 'light won');

		# The position really is finished: neither side can move. Wikipedia
		# presents these under "examples where the game ends before the grid is
		# completely filled", so this checks the transcription against that
		# claim as well as against the caption.
		ok(!$B->has_move($board, 'b'), 'dark cannot move');
		ok(!$B->has_move($board, 'w'), 'nor can light');
		ok(Game::Reversi::Rules->over($board), 'so the game is over');
		done_testing();
	};
}

subtest 'all three total 64, which is the rule showing up in the wild' => sub {
	# Stated once over the set, because it is the observation that makes these
	# three worth citing at all: three independent published results, none of
	# them on a full board, and every one summing to the size of the board.
	for my $game (@GAMES) {
		is($game->{dark} + $game->{light}, 64, $game->{name});
	}
	done_testing();
};

done_testing();
