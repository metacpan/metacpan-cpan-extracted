#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes::Set qw(tiles tile_of order_for PIPS SIZE);

plan tests => 6;

my $SEED = 'a' x 32;

subtest 'the set' => sub {
	plan tests => 6;

	is SIZE, 28, 'a double six set holds 28 tiles';
	is PIPS, 168, 'and 168 pips';

	my $all = tiles();
	is scalar(@$all), 28, 'tiles() hands back all of them';
	is $all->[0]->stringify, '0-0', 'in canonical order, 0-0 first';
	is $all->[-1]->stringify, '6-6', 'and 6-6 last';

	my $total = 0;
	$total += $_->pips for @$all;
	is $total, PIPS, 'the pips in the set agree with the constant';
};

subtest 'tiles() hands back a fresh list each time' => sub {
	plan tests => 2;

	my $a = tiles();
	my $b = tiles();
	isnt $a, $b, 'a caller may shuffle the arrayref it is given';

	shift @$a;
	is scalar(@{ tiles() }), 28, 'without damaging the next caller';
};

subtest 'tile_of' => sub {
	plan tests => 4;

	is tile_of(1)->stringify, '0-0', 'id 1 is the double blank';
	is tile_of(28)->stringify, '6-6', 'id 28 is the double six';
	ok !eval { tile_of(0); 1 }, 'id 0 dies';
	ok !eval { tile_of(29); 1 }, 'id 29 dies';
};

subtest 'order_for is a permutation of the whole set' => sub {
	plan tests => 3;

	my $order = order_for($SEED, 1);

	is scalar(@$order), 28, 'a shuffle deals all 28';
	is_deeply [ sort { $a <=> $b } @$order ], [ 1 .. 28 ],
		'with no tile missing and none dealt twice';

	# A shuffle that returned the set untouched would pass the two checks
	# above, so say out loud that it shuffled.
	isnt join(',', @$order), join(',', 1 .. 28),
		'and it is not the canonical order';
};

subtest 'order_for is a pure function of the seed and the hand' => sub {
	plan tests => 4;

	is_deeply order_for($SEED, 1), order_for($SEED, 1),
		'the same seed and hand deal the same tiles twice';

	# This is the bug the hand number exists to prevent: a shuffle fixed once
	# at the start of the game would deal identical tiles every hand, and All
	# Fives runs over many hands.
	isnt join(',', @{ order_for($SEED, 1) }), join(',', @{ order_for($SEED, 2) }),
		'a different hand deals differently from the same seed';

	isnt join(',', @{ order_for($SEED, 1) }), join(',', @{ order_for('b' x 32, 1) }),
		'and a different seed deals differently for the same hand';

	# Hand 4 reached directly must match hand 4 reached by playing through,
	# because the deal depends on nothing but the pair.
	my @direct = @{ order_for($SEED, 4) };
	order_for($SEED, $_) for 1 .. 3;
	is_deeply order_for($SEED, 4), \@direct,
		'dealing earlier hands first changes nothing';
};

subtest 'order_for refuses what it cannot be deterministic about' => sub {
	plan tests => 5;

	ok !eval { order_for('short', 1); 1 }, 'a seed that is not 32 bytes dies';
	ok !eval { order_for(undef, 1); 1 }, 'an undefined seed dies';
	ok !eval { order_for($SEED, 0); 1 }, 'hand 0 dies: hands count from 1';
	ok !eval { order_for($SEED, -1); 1 }, 'a negative hand dies';
	ok !eval { order_for($SEED, 'x'); 1 }, 'a hand that is not a number dies';
};
