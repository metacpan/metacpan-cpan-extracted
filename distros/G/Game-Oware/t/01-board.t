#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware::Board;

# NOTE: every Test::More call whose first argument is a Class->method(...) call
# needs its own parentheses. Without them `is Game::Oware::Board->total($b),`
# parses as indirect object syntax and becomes Game::Oware::Board->total(...),
# which fails with "Can't locate object method is". It reads like a typo in the
# module rather than in the test, which is what makes it worth a comment.

# The board and the sowing.
#
# Every vector below is hand-derived and the derivation is written above it.
# They were written before `sow` was, because the two rules this file exists to
# guard - the ring is twelve wide and the origin is skipped on every lap - both
# produce a board that looks entirely plausible when they are wrong.

# A board from the twelve houses, with the remainder of the 48 seeds parked in
# p1's store so that the conservation invariant holds in every case.
sub board {
	my (@houses) = @_;
	die 'twelve houses' unless @houses == 12;
	my $seeds = 0;
	$seeds += $_ for @houses;
	return [ @houses, 48 - $seeds, 0 ];
}

subtest 'the opening position' => sub {
	my $board = Game::Oware::Board->opening;

	is(scalar @$board, 14, 'fourteen cells');
	is_deeply([ @{$board}[0 .. 11] ], [ (4) x 12 ], 'four seeds in each house');
	is($board->[12], 0, 'p1 store empty');
	is($board->[13], 0, 'p2 store empty');
	is(Game::Oware::Board->total($board), 48, 'and forty-eight seeds');
};

subtest 'who owns what' => sub {
	is(Game::Oware::Board->owner_of($_), 'p1', "house $_ is p1's") for 0 .. 5;
	is(Game::Oware::Board->owner_of($_), 'p2', "house $_ is p2's") for 6 .. 11;

	is_deeply([ Game::Oware::Board->houses_of('p1') ], [ 0 .. 5 ],  'p1 has 0 to 5');
	is_deeply([ Game::Oware::Board->houses_of('p2') ], [ 6 .. 11 ], 'p2 has 6 to 11');

	is(Game::Oware::Board->store_of('p1'), 12, "p1's store");
	is(Game::Oware::Board->store_of('p2'), 13, "p2's store");

	eval { Game::Oware::Board->owner_of(12) };
	like($@, qr/a house is 0 to 11/, 'a store is not a house');

	eval { Game::Oware::Board->owner_of(-1) };
	like($@, qr/a house is 0 to 11/, 'and neither is a negative index');
};

# THE FIVE SOWING VECTORS.
#
# All five sow from house 0 so that "the house after the origin" is house 1 and
# the arithmetic is readable. The distances that matter are how many complete
# laps the hand makes and how many seeds are left over afterwards, and the ring
# is eleven houses wide once the origin is skipped.
#
#   1 seed   - no lap at all
#  11 seeds  - exactly one lap, nothing doubled: the last board before the skip
#              rule can possibly fire
#  12 seeds  - one lap and one over. THE SKIP FIRES HERE FOR THE FIRST TIME.
#              A ring of twelve that does not skip puts this seed back in the
#              house it came from.
#  13 seeds  - one lap and two over, so two houses are doubled rather than one
#  25 seeds  - TWO laps and three over. An implementation written around the
#              literal twelve gets the first lap right and this one wrong.
subtest 'sowing, five hand-derived vectors' => sub {
	my @cases = (
		{
			name  => 'one seed goes to the next house',
			hand  => 1,
			last  => 1,
			after => [ 0, 1, (0) x 10 ],
		},
		{
			name  => 'eleven seeds fill every other house exactly once',
			hand  => 11,
			last  => 11,
			after => [ 0, (1) x 11 ],
		},
		{
			name  => 'twelve seeds skip the origin and double the house after it',
			hand  => 12,
			last  => 1,
			after => [ 0, 2, (1) x 10 ],
		},
		{
			name  => 'thirteen seeds double the two houses after the origin',
			hand  => 13,
			last  => 2,
			after => [ 0, 2, 2, (1) x 9 ],
		},
		{
			name  => 'twenty-five seeds lap twice and the origin is skipped twice',
			hand  => 25,
			last  => 3,
			after => [ 0, 3, 3, 3, (2) x 8 ],
		},
	);

	for my $case (@cases) {
		subtest $case->{name} => sub {
			my $board = board($case->{hand}, (0) x 11);
			my ($next, $last, $sown) = Game::Oware::Board->sow($board, 0);

			is($sown, $case->{hand}, 'it sowed the whole house');
			is($last, $case->{last}, 'the final seed landed where it should');
			is_deeply([ @{$next}[0 .. 11] ], $case->{after}, 'and the houses are right');

			is($next->[0], 0, 'the origin is empty');
			is($next->[12], $board->[12], "p1's store is untouched");
			is($next->[13], $board->[13], "p2's store is untouched");
			is(Game::Oware::Board->total($next), 48, 'and still forty-eight seeds');

			is_deeply($board, board($case->{hand}, (0) x 11),
				'and the board passed in was not modified');
		};
	}
};

# The same rule seen from the other end of the row, so that a skip implemented
# as "index 0 is special" fails here while passing everything above.
subtest 'the origin is skipped wherever it is' => sub {
	my $board = board((0) x 5, 12, (0) x 6);
	my ($next, $last) = Game::Oware::Board->sow($board, 5);

	is($next->[5], 0, 'the origin is empty');
	is($next->[6], 2, 'the house after it is doubled');
	is($last, 6, 'and that is where the twelfth seed landed');
	is_deeply([ @{$next}[0 .. 4] ], [ (1) x 5 ], 'p1 house wrap is one each');
	is_deeply([ @{$next}[7 .. 11] ], [ (1) x 5 ], 'and so is the rest of p2');
	is(Game::Oware::Board->total($next), 48, 'forty-eight seeds');
};

subtest 'the ring crosses the row boundary and wraps' => sub {
	my $board = board((0) x 11, 3);
	my ($next, $last) = Game::Oware::Board->sow($board, 11);

	is_deeply([ @{$next}[0 .. 2] ], [ 1, 1, 1 ], "f sows into p1's row");
	is($last, 2, 'and the last seed is in C');
	is($next->[11], 0, 'and f is empty');
};

# THE ONLY EXTERNAL VECTOR IN THIS FILE, and it checks the sowing alone.
#
# Wikipedia, "Oware", revid 1368141850, fetched 17 Sep 2026 as wikitext with
# action=raw, because the two boards are {{Mancala labeled 2x6}} templates and
# a tag-stripped fetch of the rendered page loses every number in them.
#
#   before   top (f e d c b a):  2  2  1  2  3  1
#            bottom (A .. F):    3  1  4  0  6  2      <- the lower player sows from E
#
#   after    top (f e d c b a):  2  3  2  3  4  2
#            bottom (A .. F):    3  1  4  0  0  3
#
# The capture that follows is phase 02's; what this asserts is that six seeds
# leaving E land in exactly the houses the article draws them in.
#
# THE DIAGRAM HOLDS 27 SEEDS, NOT 48. Twenty-one have already been captured and
# the article does not say by whom, so the split below is ours and is chosen
# only to keep the conservation invariant live. Nothing in the assertion depends
# on it.
subtest 'the cited position sows exactly as the article draws it' => sub {
	my $board = [
		3, 1, 4, 0, 6, 2,
		1, 3, 2, 1, 2, 2,
		11, 10,
	];

	is(Game::Oware::Board->total($board), 48, 'the fixture is seeded to 48');

	my ($next, $last, $sown) = Game::Oware::Board->sow($board, 4);

	is($sown, 6, 'E held six seeds');
	is($last, 10, 'and the sixth landed in e');

	is_deeply([ @{$next}[0 .. 5] ], [ 3, 1, 4, 0, 0, 3 ],
		"p1's row matches the article's lower row");
	is_deeply([ @{$next}[6 .. 11] ], [ 2, 4, 3, 2, 3, 2 ],
		"p2's row matches the article's upper row");

	is($next->[11], 2, 'f was never reached, so it did not change');
	is(Game::Oware::Board->total($next), 48, 'forty-eight seeds');
};

subtest 'what dies, because a caller that asks for it has a bug' => sub {
	my $board = Game::Oware::Board->opening;

	eval { Game::Oware::Board->sow($board, 12) };
	like($@, qr/a house is 0 to 11/, 'a store cannot be sown from');

	eval { Game::Oware::Board->sow($board, 'E') };
	like($@, qr/a house is 0 to 11/, 'and neither can a letter');

	my $empty = board(0, (4) x 11);
	eval { Game::Oware::Board->sow($empty, 0) };
	like($@, qr/is empty/, 'an empty house sows nothing and says so');
};

subtest 'seeds on a side are not a score' => sub {
	my $board = Game::Oware::Board->opening;
	is(Game::Oware::Board->seeds_on_side($board, 'p1'), 24, 'p1 has 24 in front');
	is(Game::Oware::Board->seeds_on_side($board, 'p2'), 24, 'and so does p2');

	$board->[12] = 5;
	is(Game::Oware::Board->seeds_on_side($board, 'p1'), 24,
		'and the store is not counted, because captured seeds are not on the side');
};

done_testing;
