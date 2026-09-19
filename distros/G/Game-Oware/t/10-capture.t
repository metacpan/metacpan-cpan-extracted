#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware::Board;
use Game::Oware::Scoring;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# The capture chain.
#
# EVERY VECTOR IN THIS FILE IS OURS, hand-derived on paper, and none of it is
# cited. The one external position this distribution has is in t/16-cited.t and
# it is labelled as such there. These are the cases that position does not
# reach.
#
# capture_chain takes the board AFTER sowing, because every count in the rule is
# a post-sowing count. It finds the chain and never applies it, so every subtest
# here also asserts that the board came back untouched.

sub board {
	my (@houses) = @_;
	die 'twelve houses' unless @houses == 12;
	my $seeds = 0;
	$seeds += $_ for @houses;
	return [ @houses, 48 - $seeds, 0 ];
}

sub chain_on {
	my ($board, $last, $sown, $seat) = @_;
	my $before = [ @$board ];
	my @chain = Game::Oware::Board->capture_chain($board, $last, $sown, $seat);
	is_deeply($board, $before, 'capture_chain did not touch the board');
	is(Game::Oware::Board->total($board), 48, 'and there are still forty-eight seeds');
	return @chain;
}

# The final seed decides whether there is a capture at all, and it has to have
# landed in the OPPONENT's row. A seat's own house at two is still two.
subtest 'a seed landing in your own house captures nothing' => sub {
	my $board = board(0, 0, 0, 2, 0, 0, 2, 2, 2, 0, 0, 0);

	my @chain = chain_on($board, 3, 4, 'p1');

	is_deeply(\@chain, [], 'p1 captures nothing by landing on its own D');
	is(Game::Oware::Scoring->taken($board, \@chain), 0, 'and takes no seeds');
};

# The chain does not start unless the LAST seed made two or three. Four is not
# "two or more", and the twos sitting behind it are unreachable because the walk
# never begins.
subtest 'a last seed making four captures nothing, whatever is behind it' => sub {
	my $board = board(0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 4, 0);

	my @chain = chain_on($board, 10, 5, 'p1');

	is_deeply(\@chain, [], 'four is not two or three');
	is($board->[9], 2, 'and the two behind it is still sitting there');
};

# THE CAP. A hand of one seed touched one house, so a chain of two would be
# describing a capture the sowing never reached. House 7 is set to two purely as
# a trap: a walk without the cap takes it.
subtest 'the chain never outruns the hand' => sub {
	my $board = board(0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0);

	my @chain = chain_on($board, 8, 1, 'p1');

	is_deeply(\@chain, [ 8 ], 'one seed sown, one house captured');
	is(Game::Oware::Scoring->taken($board, \@chain), 2, 'two seeds');
	is($board->[7], 2, 'and the house behind it was never reached');

	my @longer = Game::Oware::Board->capture_chain($board, 8, 2, 'p1');
	is_deeply(\@longer, [ 8, 7 ], 'the same position with a hand of two takes both');
};

# The walk has no idea a row boundary exists. It stops because the house below
# the opponent's first one belongs to the seat doing the capturing, which is the
# ownership test doing the work. House 5 holds two so that the count cannot be
# what stopped it.
subtest 'the walk stops at the row boundary, by ownership and not by arithmetic' => sub {
	my $board = board(0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0);

	my @chain = chain_on($board, 6, 6, 'p1');

	is_deeply(\@chain, [ 6 ], 'it takes a and stops');
	is($board->[5], 2, "and p1's own F, also at two, is not captured");
};

subtest 'and it stops there for p2 as well, wrapping round zero' => sub {
	my $board = board(2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);

	my @chain = chain_on($board, 0, 6, 'p2');

	is_deeply(\@chain, [ 0 ], 'p2 takes A and stops');
	is($board->[11], 2, "and p2's own f, also at two, is not captured");
};

# Six houses, which is every seed the opponent has. Phase 03 decides what
# happens to it; all this phase says is that the chain is found.
subtest 'a chain can run the whole opponent row' => sub {
	my $board = board(4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2);

	my @chain = chain_on($board, 11, 7, 'p1');

	is_deeply(\@chain, [ 11, 10, 9, 8, 7, 6 ], 'all six, in walk-back order');
	is(Game::Oware::Scoring->taken($board, \@chain), 12, 'twelve seeds');
	is(Game::Oware::Board->seeds_on_side($board, 'p2'), 12,
		'which is everything p2 has, so phase 03 will call this a grand slam');
};

subtest 'a chain broken in the middle stops at the break' => sub {
	my $board = board(0, 0, 0, 0, 0, 0, 3, 5, 3, 2, 3, 0);

	my @chain = chain_on($board, 10, 8, 'p1');

	is_deeply(\@chain, [ 10, 9, 8 ], 'it stops at the five');
	is(Game::Oware::Scoring->taken($board, \@chain), 8, 'eight seeds');
	is($board->[6], 3, 'and the three beyond the break is not contiguous, so it stays');
};

subtest 'what is not a house' => sub {
	my $board = Game::Oware::Board->opening;

	eval { Game::Oware::Board->capture_chain($board, 13, 4, 'p1') };
	like($@, qr/a house is 0 to 11/, 'a store cannot be landed in');
};

subtest 'captured and score are not the same question' => sub {
	my $board = Game::Oware::Board->opening;
	$board->[12] = 9;
	$board->[13] = 4;

	is_deeply(Game::Oware::Scoring->captured($board), { p1 => 9, p2 => 4 },
		'captured is always available');
	is(Game::Oware::Scoring->score($board, 'active'), undef,
		'score refuses to answer while the game is running');
	is_deeply(Game::Oware::Scoring->score($board, 'finished'), { p1 => 9, p2 => 4 },
		'and answers once it is over');

	is(Game::Oware::Scoring->leader($board), 'p1', 'p1 leads');
	is(Game::Oware::Scoring->target_reached($board), undef, 'nobody has 25 yet');

	$board->[12] = 26;
	is(Game::Oware::Scoring->target_reached($board), 'p1',
		'twenty-five OR MORE, because one capture can carry a store past it');

	$board->[12] = 24;
	$board->[13] = 24;
	ok(Game::Oware::Scoring->is_draw($board), 'twenty-four each is a draw');
	is(Game::Oware::Scoring->leader($board), undef, 'and nobody leads it');
};

done_testing;
