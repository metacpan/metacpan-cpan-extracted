#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware::Board;
use Game::Oware::Rules;

# THIS IS A REGRESSION BASELINE AND NOT AN ORACLE, AND THE DIFFERENCE MATTERS.
#
# A perft ladder is only an external check if somebody else published the
# numbers. NOBODY HAS. Searched 18 September 2026 across the usual places - the
# Chess Programming Wiki's Awari page, general search for "oware perft" and
# "awari perft" - and there is no published ladder for this game, nor an OEIS
# sequence for it the way A124004 exists for Reversi.
#
# The reason is structural rather than an oversight: the branching factor is at
# most six, so the count is trivially computable and nobody needed to write it
# down.
#
# So the numbers below came out of THIS engine. They catch a change; they cannot
# catch being wrong from the first commit. Whoever reads a failure here needs to
# know that, which is why it says so at the top rather than in a commit message.
#
# THE CONVENTION, because two reasonable ones disagree.
#
# perft(d) counts distinct legal move SEQUENCES OF LENGTH EXACTLY d. A line that
# ends the game before depth d contributes NOTHING, because it cannot be
# extended. The alternative convention counts a terminal position as a leaf at
# whatever depth it stopped, and the two agree until the first short game is
# reachable and then diverge by a small amount - which is the worst possible
# shape for a disagreement, because it looks like an off-by-one.
#
# In xt because depth 7 takes about a second and each further ply is five times
# the last.

unless ($ENV{RELEASE_TESTING} || $ENV{OWARE_PERFT}) {
	plan(skip_all => 'set RELEASE_TESTING or OWARE_PERFT to run perft');
}

sub perft {
	my ($board, $seat, $depth) = @_;
	return 1 if $depth == 0;

	my @legal = Game::Oware::Rules->legal_moves($board, $seat, 'abapa');
	return 0 unless @legal;

	my $count = 0;
	for my $house (@legal) {
		my ($next) = Game::Oware::Rules->resolve($board, $house, $seat, 'abapa');
		$count += perft($next, Game::Oware::Board->other($seat), $depth - 1);
	}

	return $count;
}

# Recorded 18 September 2026 from this engine, under abapa.
my @LADDER = (
	[ 1, 6 ],
	[ 2, 36 ],
	[ 3, 190 ],
	[ 4, 1014 ],
	[ 5, 5219 ],
	[ 6, 27332 ],
	[ 7, 139157 ],
);

subtest 'the ladder has not moved' => sub {
	for my $rung (@LADDER) {
		my ($depth, $expect) = @$rung;
		is(perft(Game::Oware::Board->opening, 'p1', $depth), $expect,
			"perft($depth) is $expect");
	}
};

# The interesting part of the ladder, and the reason it is not simply 6**d:
# a house a seat sowed last turn is empty this turn unless something refilled
# it, so the branching factor drops below six almost immediately.
subtest 'the ladder is not six to the power of the depth' => sub {
	is(perft(Game::Oware::Board->opening, 'p1', 1), 6, 'depth one is the full six');
	is(perft(Game::Oware::Board->opening, 'p1', 2), 36, 'and depth two is six by six');

	cmp_ok(perft(Game::Oware::Board->opening, 'p1', 3), '<', 6 ** 3,
		'but depth three is already short of it, because sowing empties a house');
};

done_testing;
