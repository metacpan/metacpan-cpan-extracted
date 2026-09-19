#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware::Board;
use Game::Oware::Rules;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# The feeding obligation, and the filter it puts on the legal move list.
#
# "If an opponent's houses are all empty, the current player must make a move
# that gives the opponent seeds. If no such move is possible, the current player
# captures all seeds in their own territory, ending the game."
#
# Every vector here is ours. The rule bites only when the opponent's row is
# ALREADY empty at the start of the turn, which is what makes it easy to write a
# filter that fires in the wrong positions.

sub board {
	my (@houses) = @_;
	die 'twelve houses' unless @houses == 12;
	my $seeds = 0;
	$seeds += $_ for @houses;
	return [ @houses, 48 - $seeds, 0 ];
}

subtest 'the rule does not bite while the opponent has seeds' => sub {
	my $board = Game::Oware::Board->opening;

	ok(!Game::Oware::Rules->starved($board, 'p2'), 'p2 is not starved');
	is_deeply([ Game::Oware::Rules->legal_moves($board, 'p1', 'abapa') ], [ 0 .. 5 ],
		'so every house p1 can sow from is legal');

	# One seed anywhere on their side is enough to switch the rule off.
	my $barely = board(4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 1);
	ok(!Game::Oware::Rules->starved($barely, 'p2'), 'one seed is not starved');
	is_deeply([ Game::Oware::Rules->legal_moves($barely, 'p1', 'abapa') ], [ 0 .. 5 ],
		'and the filter stays off');
};

subtest 'when it does bite, only the moves that reach are legal' => sub {
	# p2 is empty. p1 holds seeds in A (1), D (2) and F (1). Only F reaches,
	# because A needs six seeds and D needs three.
	my $board = board(1, 0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0);

	ok(Game::Oware::Rules->starved($board, 'p2'), 'p2 is starved');

	is_deeply([ Game::Oware::Rules->sowable($board, 'p1') ], [ 0, 3, 5 ],
		'three houses have seeds in them');
	is_deeply([ Game::Oware::Rules->legal_moves($board, 'p1', 'abapa') ], [ 5 ],
		'but only F is legal, which is why the legal list is not the sowable one');
};

subtest 'a position where nothing feeds is the end of the game' => sub {
	# p2 is empty and p1's only seeds are in A and B, which need six and five.
	my $board = board(3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

	ok(Game::Oware::Rules->starved($board, 'p2'), 'p2 is starved');
	ok(scalar(Game::Oware::Rules->sowable($board, 'p1')), 'p1 has seeds to sow');
	is_deeply([ Game::Oware::Rules->legal_moves($board, 'p1', 'abapa') ], [],
		'and no legal move at all, which is the failed-feed ending');
};

# THE TWO DERIVATIONS.
#
# `reaches` is arithmetic: a house needs 6 - its position within its own row.
# `feeds` is a simulation: sow it and look at what the opponent has left.
#
# They are only equal because of D1. Under no_capture a chain that would take
# every seed the sowing just gave the opponent is a grand slam and is forfeited,
# so the seeds stay and the move feeds. Under any policy that allows the capture
# the argument is circular, which is why the engine simulates and only the test
# knows the shortcut.
subtest 'the arithmetic and the simulation agree, on every house of every position' => sub {
	my @positions = (
		[ 'p2 empty, p1 spread out',   board(1, 2, 3, 4, 5, 6, 0, 0, 0, 0, 0, 0), 'p1' ],
		[ 'p2 empty, p1 loaded',       board(9, 8, 7, 0, 0, 1, 0, 0, 0, 0, 0, 0), 'p1' ],
		[ 'p2 empty, p1 nearly empty', board(0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0), 'p1' ],
		[ 'p2 empty, p1 lapping',      board(13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), 'p1' ],
		[ 'p1 empty, p2 spread out',   board(0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6), 'p2' ],
		[ 'p1 empty, p2 nearly empty', board(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1), 'p2' ],
		[ 'p1 empty, p2 lapping',      board(0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0), 'p2' ],
	);

	for my $case (@positions) {
		my ($name, $board, $seat) = @$case;

		for my $house (Game::Oware::Board->houses_of($seat)) {
			next unless $board->[$house];

			my $arithmetic = $board->[$house] >= Game::Oware::Rules->reaches($house, $seat)
				? 1 : 0;
			my $simulated = Game::Oware::Rules->feeds($board, $house, $seat, 'abapa');

			is($simulated, $arithmetic,
				"$name: house $house agrees ("
					. ($arithmetic ? 'feeds' : 'does not reach') . ')');
		}
	}
};

subtest 'what reaches actually says' => sub {
	is(Game::Oware::Rules->reaches(0, 'p1'), 6, 'A needs six seeds');
	is(Game::Oware::Rules->reaches(5, 'p1'), 1, 'and F needs one');
	is(Game::Oware::Rules->reaches(6, 'p2'), 6, 'a needs six seeds');
	is(Game::Oware::Rules->reaches(11, 'p2'), 1, 'and f needs one');
};

# THE CASE THE DERIVATION TURNS ON. p2 holds nothing. p1 sows F, one seed, into
# a, bringing it to one - no capture, so nothing to forfeit, and it feeds. Then
# the harder one: p1 sows a house whose whole chain would take back everything
# it just gave, which IS a grand slam and is forfeited, so it still feeds.
subtest 'a move feeds even when its capture would have taken it all back' => sub {
	my $board = board(0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0);

	is(Game::Oware::Board->seeds_on_side($board, 'p2'), 1, 'p2 has one seed');

	my ($next, $move) = Game::Oware::Rules->resolve($board, 5, 'p1', 'abapa');

	ok($move->slammed, 'the capture would have been a grand slam');
	is_deeply($move->forfeited, [ 6 ], 'so it was forfeited');
	ok(Game::Oware::Rules->feeds($board, 5, 'p1', 'abapa'),
		'and the move therefore feeds, which is the whole derivation');
	is(Game::Oware::Board->seeds_on_side($next, 'p2'), 2, 'p2 can play');
};

# AN EMPTY LEGAL LIST HAS ONE CAUSE, AND THIS IS THE PROOF RATHER THAN THE
# CLAIM.
#
# Two things could in principle empty the list: the failed feed above, or a seat
# arriving at its turn with an empty row of its own. The second cannot happen
# under D1, because the only way to strip a seat of every seed is to capture
# them all, and that is a grand slam and is forfeited.
#
# So rather than construct an unreachable position and assert something about
# it, this plays games out and checks the property at every ply. Moves are
# chosen deterministically - always the first legal one - so a failure is
# reproducible. There is no cycle rule until phase 04, so the ply count is
# capped and running out is not a failure.
subtest 'a seat on turn always has seeds, so the list is only ever emptied by the feed' => sub {
	my $board = Game::Oware::Board->opening;
	my $seat  = 'p1';
	my $plies = 0;
	my $ended_on_feed = 0;

	while ($plies < 400) {
		ok(Game::Oware::Board->seeds_on_side($board, $seat) > 0,
			"ply $plies: the seat to move has seeds")
			or diag explain $board;

		my @legal = Game::Oware::Rules->legal_moves($board, $seat, 'abapa');

		if (!@legal) {
			ok(Game::Oware::Rules->starved($board, Game::Oware::Board->other($seat)),
				"ply $plies: the list emptied, and the opponent was starved");
			$ended_on_feed = 1;
			last;
		}

		($board) = Game::Oware::Rules->resolve($board, $legal[0], $seat, 'abapa');
		is(Game::Oware::Board->total($board), 48, "ply $plies: forty-eight seeds");

		$seat = Game::Oware::Board->other($seat);
		$plies++;
	}

	cmp_ok($plies, '>', 10, 'and it was a real game rather than two moves');
	diag("the game ran $plies plies and "
		. ($ended_on_feed ? 'ended on the feeding rule' : 'hit the ply cap'));
};

subtest 'starvation is about houses, never about the store' => sub {
	my $board = board((4) x 6, (0) x 6);
	$board->[13] = 20;

	ok(Game::Oware::Rules->starved($board, 'p2'),
		'twenty seeds in the store is still starved, because captured seeds never come back');
};

done_testing;
