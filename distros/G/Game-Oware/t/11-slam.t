#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware::Board;
use Game::Oware::Rules;
use Game::Oware::Scoring;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# The grand slam.
#
# Every vector here is ours, hand-derived. The rule being tested is D1: under
# abapa the move is legal and captures nothing, which is what the article's own
# rules body says ("the capture is forfeited ... the seeds are instead left on
# the board") and what its Variations section calls the international rule.
#
# THE QUESTION IS ASKED OF THE RESULTING BOARD, NEVER OF THE CHAIN'S LENGTH.
# Both halves of that get their own subtest, because the plausible wrong
# implementation - `is the chain six houses long` - passes the first and fails
# the second.

sub board {
	my (@houses) = @_;
	die 'twelve houses' unless @houses == 12;
	my $seeds = 0;
	$seeds += $_ for @houses;
	return [ @houses, 48 - $seeds, 0 ];
}

# p2 holds one seed, in c. p1 sows A, which holds three, so the seeds land in
# B, C and D... which are p1's own. Nothing is captured and nothing is a slam.
# This is the control for the two below it.
subtest 'an ordinary move that takes nothing is not a slam' => sub {
	my $board = board(3, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0);

	my ($next, $move) = Game::Oware::Rules->resolve($board, 0, 'p1', 'abapa');

	ok(!$move->slammed, 'not a slam');
	is_deeply($move->forfeited, [], 'nothing forfeited');
	is_deeply($move->captured, [], 'and nothing captured');
	is(Game::Oware::Board->total($next), 48, 'forty-eight seeds');
};

# THE ONE-HOUSE SLAM. p2 holds a single seed, in a. p1 sows F, which holds one,
# so the seed lands in a and brings it to two - a capture, and it is every seed
# p2 has. A chain of ONE house, and a grand slam.
subtest 'a chain of one house can be a grand slam' => sub {
	my $board = board(0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0);

	is(Game::Oware::Board->seeds_on_side($board, 'p2'), 1, 'p2 has one seed');

	my ($next, $move) = Game::Oware::Rules->resolve($board, 5, 'p1', 'abapa');

	ok($move->slammed, 'it is a slam, on a chain of one');
	is_deeply($move->forfeited, [ 6 ], 'so the chain is given back');
	is_deeply($move->captured, [], 'nothing is captured');
	is($move->taken, 0, 'and no seeds are taken');

	is($next->[6], 2, 'the seeds are left on the board, as the article says');
	is($next->[12], $board->[12], "p1's store did not move");
	is(Game::Oware::Board->seeds_on_side($next, 'p2'), 2,
		'and p2 can still play, which is the point of the rule');
	is(Game::Oware::Board->total($next), 48, 'forty-eight seeds');

	is($move->stringify, 'F (slam forfeited)', 'and the move says so');
};

# THE SIX-HOUSE CHAIN THAT IS NOT A SLAM. Every one of p2's houses is taken,
# but b held four and stopped the walk, so p2 keeps it. A length test calls this
# a slam; the board says it is not.
subtest 'a chain of five houses is not a slam when the opponent keeps one' => sub {
	my $board = board(0, 0, 0, 0, 0, 6, 1, 3, 1, 2, 1, 2);

	my ($next, $move) = Game::Oware::Rules->resolve($board, 5, 'p1', 'abapa');

	is_deeply($move->captured, [ 11, 10, 9, 8 ], 'four houses taken');
	ok(!$move->slammed, 'and it is not a slam');
	is(Game::Oware::Board->seeds_on_side($next, 'p2'), 6,
		'because b and a still hold seeds');
	is($move->taken, 10, 'ten seeds captured');
	is($next->[12], $board->[12] + 10, 'and they are in the store');
	is(Game::Oware::Board->total($next), 48, 'forty-eight seeds');
};

# The other half of the same rule: six houses emptied IS a slam, because the
# opponent had nothing anywhere else.
#   Six seeds, not seven: a seventh would carry the last seed round into p1's
#   own house A, where the chain cannot start at all and nothing is captured.
#   The first draft of this vector used seven and proved nothing.
subtest 'a chain of six houses is a slam when that is everything' => sub {
	my $board = board(0, 0, 0, 0, 0, 6, 1, 1, 1, 1, 1, 1);

	my ($next, $move) = Game::Oware::Rules->resolve($board, 5, 'p1', 'abapa');

	is_deeply($move->forfeited, [ 11, 10, 9, 8, 7, 6 ], 'all six would have gone');
	ok($move->slammed, 'so it is a slam');
	is(Game::Oware::Board->seeds_on_side($next, 'p2'), 12, 'and p2 keeps all twelve');
	is(Game::Oware::Board->total($next), 48, 'forty-eight seeds');
};

# THE SOLVED RULE SET. Pinned from the Awari Game Score Database's own
# Awari-Python/README.md, fetched 18 Sep 2026, which says the scores are
# computed under rules where "it is not allowed to remove all stones of the
# opponent (leaving it no move), unless it is the only move available".
#
# So under awari a grand slam is filtered out of the legal list, and played
# normally when nothing else is legal. Both halves are asserted, because the
# exception clause is the half a reader will assume is not there.
subtest 'under awari a slam is illegal, unless it is the only move' => sub {
	my $only = board(0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0);

	is_deeply([ Game::Oware::Rules->legal_moves($only, 'p1', 'awari') ], [ 5 ],
		'when F is the only house with seeds, the slam is legal');

	my ($after, $move) = Game::Oware::Rules->resolve($only, 5, 'p1', 'awari');

	ok($move->slammed, 'it is still a slam');
	is_deeply($move->captured, [ 6 ], 'but the capture is made');
	is_deeply($move->forfeited, [], 'and nothing is given back');
	is($move->taken, 2, 'two seeds');
	is(Game::Oware::Board->total($after), 48, 'forty-eight seeds');

	my ($abapa) = Game::Oware::Rules->resolve($only, 5, 'p1', 'abapa');
	isnt($abapa->[12], $after->[12], 'the two variants disagree about the store');

	my $choice = board(1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0);

	is_deeply([ Game::Oware::Rules->sowable($choice, 'p1') ], [ 0, 5 ],
		'with a second house holding seeds there are two candidates');
	is_deeply([ Game::Oware::Rules->legal_moves($choice, 'p1', 'awari') ], [ 0 ],
		'and the slam is no longer legal');
	is_deeply([ Game::Oware::Rules->legal_moves($choice, 'p1', 'abapa') ], [ 0, 5 ],
		'while abapa still offers it, because there it simply captures nothing');
};

subtest 'an unknown variant is programmer error' => sub {
	my $board = Game::Oware::Board->opening;

	eval { Game::Oware::Rules->resolve($board, 0, 'p1', 'congkak') };
	like($@, qr/there is no variant 'congkak'/,
		'a sow-into-a-store game is not a variant of this one');

	eval { Game::Oware::Rules->legal_moves($board, 'p1', undef) };
	like($@, qr/there is no variant/, 'and so does none at all');
};

subtest 'resolve never modifies the board it was given' => sub {
	my $board = board(0, 0, 0, 0, 0, 6, 1, 3, 1, 2, 1, 2);
	my $before = [ @$board ];

	Game::Oware::Rules->resolve($board, 5, 'p1', 'abapa');

	is_deeply($board, $before, 'untouched');
};

done_testing;
