#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes::Layout;
use Game::Dominoes::Scoring qw(count score_for MAX_COUNT);
use Game::Dominoes::Tile;

plan tests => 8;

sub tile { Game::Dominoes::Tile->of(@_) }

subtest 'a single tile is one end, counted once' => sub {
	plan tests => 6;

	# The opening tile shows both its faces and is ONE end, not two. Counting
	# it as two would double every one of the cited opening vectors.
	for my $t ([ 6, 4, 10 ], [ 5, 5, 10 ], [ 5, 0, 5 ], [ 4, 1, 5 ], [ 3, 2, 5 ]) {
		my $l = Game::Dominoes::Layout->new;
		$l->place(tile($t->[0], $t->[1]), 'L');
		is count($l), $t->[2],
			"$t->[0]-$t->[1] alone counts $t->[2]";
	}

	my $l = Game::Dominoes::Layout->new;
	$l->place(tile(0, 0), 'L');
	is count($l), 0, 'and the double blank counts nothing';
};

subtest 'a double at an end counts both its halves' => sub {
	plan tests => 3;

	# Pagat: "A double on the end of an arm of the tableau scores the total of
	# its pips; that is [5-5] is worth ten points in the total, [6-6] is worth
	# twelve points and so forth."
	my $l = Game::Dominoes::Layout->new;
	$l->place(tile(6, 4), 'L');
	$l->place(tile(4, 4), 'R');
	is count($l), 8 + 6, 'the double four counts eight, not four';

	# GameColony gives this exact case: "If one end of the chain has a double
	# four and the other end has a two, the score is eight (8) for the double
	# four and two (2)", so ten, which scores.
	my $cited = Game::Dominoes::Layout->new;
	$cited->place(tile(4, 2), 'L');
	$cited->place(tile(4, 4), 'L');
	is count($cited), 8 + 2, 'a double four at one end and a two at the other is ten';

	$cited->place(tile(2, 2), 'R');
	is count($cited), 8 + 4, 'and a double two on the other end makes it twelve';
};

subtest 'the worked example, counted at every step' => sub {
	plan tests => 5;

	# The five step example from plan_game_dominoes/06-scoring.md, derived by
	# hand from the pinned rules and checked against Pagat's prose.
	my $l = Game::Dominoes::Layout->new;

	$l->place(tile(5, 5), 'L');
	is count($l), 10, '1. the spinner alone: 5 + 5';

	$l->place(tile(5, 2), 'L');
	is count($l), 12, '2. one side covered: the spinner still counts, plus the two';

	$l->place(tile(5, 3), 'R');
	is count($l), 5, '3. both sides covered: the spinner is silent, leaving 2 + 3';

	$l->place(tile(5, 6), 'U');
	is count($l), 11, '4. an arm opens and adds its six';

	$l->place(tile(5, 4), 'D');
	is count($l), 15, '5. the last arm adds its four';
};

subtest 'step three takes the count DOWN, and that is the point' => sub {
	plan tests => 3;

	# A count that only ever rises is the natural thing to write and it is
	# wrong. Covering the spinner second side removes ten from the total and
	# adds three, so the count falls from 12 to 5 and SCORES 5 as it goes.
	my $l = Game::Dominoes::Layout->new;
	$l->place(tile(5, 5), 'L');
	$l->place(tile(5, 2), 'L');
	is count($l), 12, 'before: twelve';

	$l->place(tile(5, 3), 'R');
	is count($l), 5, 'after: five, which is lower';
	is score_for(count($l)), 5, 'and it scores, because five is a multiple of five';
};

subtest 'the spinner needs no rule of its own' => sub {
	plan tests => 3;

	# Pagat: "When the second tile is played against the spinner, the spinner
	# no longer contributes to the score: only the tiles at the two ends of
	# the layout count, just as if the spinner was another tile placed in
	# line. This can be confusing because the ends of the spinner are still
	# open for setting other tiles."
	#
	# Nothing in Scoring.pm implements that sentence. A spinner with both
	# sides covered is not at an end, so Layout does not report it, so it
	# cannot be counted.
	my $l = Game::Dominoes::Layout->new;
	$l->place(tile(5, 5), 'L');
	$l->place(tile(5, 2), 'L');
	$l->place(tile(5, 3), 'R');

	is scalar(grep { $_->{tile}->is_double } $l->ends), 0,
		'the spinner is not among the ends';
	is $l->sides_covered, 2, 'because both its sides are covered';
	is_deeply [ sort { $a <=> $b } $l->open_ends ], [ 2, 3, 5, 5 ],
		'even though its two arms are still open to play on';
};

subtest 'only a multiple of five scores, and nought never does' => sub {
	plan tests => 9;

	# "If this total is a multiple of five (5, 10, 15, 20, 25, 30 or 35
	# points), the player immediately scores that number of points." The
	# enumeration starts at five: nought is arithmetically a multiple of five
	# and is not a score.
	is score_for(0), 0, 'nought scores nothing, though it divides by five';
	is score_for(5), 5, 'five scores five';
	is score_for(10), 10, 'ten scores ten';
	is score_for(35), 35, 'and thirty-five scores thirty-five';

	is score_for($_), 0, "$_ is not a multiple of five and scores nothing"
		for 1, 4, 7, 12;

	is score_for(undef), 0, 'and nothing at all scores nothing';
};

subtest 'the divided scale is the cribbage board variation' => sub {
	plan tests => 4;

	# "It is common to divide all the scores by five, so that for example a
	# total of 15 on the ends of the layout scores 3 points. The game can then
	# be scored on a Cribbage board, and the winning target is 61 points."
	is score_for(15, 5), 3, 'fifteen on the divided scale scores three';
	is score_for(10, 5), 2, 'ten scores two';
	is score_for(35, 5), 7, 'and thirty-five scores seven';
	is score_for(15), 15, 'while the raw scale still scores the total itself';
};

subtest 'the highest count in one play is thirty-five' => sub {
	plan tests => 3;

	# Pagat gives the construction as well as the number: "the [6-6], [5-5]
	# and [4-4] tiles on the ends of three arms of the layout and a tile which
	# shows a 5 on the fourth arm". Assert the CONSTRUCTION, because the
	# number alone would still pass against a scorer that simply capped.
	is 12 + 10 + 8 + 5, MAX_COUNT, 'the published construction adds to 35';
	is MAX_COUNT, 35, 'which is the published maximum';
	is score_for(MAX_COUNT), 35, 'and it is a scoring total';
};
