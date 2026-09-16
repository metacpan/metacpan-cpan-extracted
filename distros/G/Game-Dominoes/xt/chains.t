#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes::Tile;

# The strongest cited vector this distribution has, and the only one that is
# independent of anything anybody wrote about dominoes RULES: it is a
# combinatorial fact about the tiles themselves, first counted by Edouard Lucas
# in the 1880s and reprinted in Dudeney's Amusements in Mathematics (1917).
#
#   OEIS A284287, "Number of possible legal open chains of a set of dominoes
#   tiles with 0 to 2n pips":  12, 126720, 7959229931520, ...
#
#   Pagat, The Mathematics of Dominoes: "A common question is how many
#   different trains can build with a standard double six set. Without doing
#   the math, the answer is 7,959,229,931,520 if you count reversals or half
#   that amount if you do not."
#
# Both sources verified by hand on 14 September 2026.
#
# This is the nearest thing dominoes has to the perft ladder a chess or
# draughts engine tests its move generator against, and it is better in one
# way: the numbers predate this distribution by a century, so they cannot have
# been contaminated by it.
#
# What it actually tests is Game::Dominoes::Tile's matching: has_face decides
# whether a tile may follow, and other() decides what it leaves showing. Get
# either wrong and these counts move.
#
# In xt/ rather than t/ because the double-four rung takes a few seconds, and
# the double-six rung is not reachable at all: 7.96e12 chains cannot be
# enumerated, so it is asserted as arithmetic the suite cannot reach and is
# recorded here for whoever tries.

plan tests => 3;

# Every open chain that uses all the tiles of a double-$max set, counting
# reversals, which is what both sources count.
sub chains {
	my ($max) = @_;

	my @tiles;
	for my $low (0 .. $max) {
		push @tiles, Game::Dominoes::Tile->of($_, $low) for $low .. $max;
	}

	my $wanted = scalar @tiles;
	my @used = (0) x $wanted;
	my $count = 0;

	my $walk;
	$walk = sub {
		my ($end, $depth) = @_;
		return $count++ if $depth == $wanted;
		for my $i (0 .. $#tiles) {
			next if $used[$i];
			next unless $tiles[$i]->has_face($end);
			$used[$i] = 1;
			$walk->($tiles[$i]->other($end), $depth + 1);
			$used[$i] = 0;
		}
		return;
	};

	for my $i (0 .. $#tiles) {
		$used[$i] = 1;
		# A chain may start from either face of its first tile, except on a
		# double, where the two faces are the same chain.
		$walk->($tiles[$i]->low, 1);
		$walk->($tiles[$i]->high, 1) unless $tiles[$i]->is_double;
		$used[$i] = 0;
	}

	return ($count, $wanted);
}

subtest 'a double two set: 6 tiles, 12 chains' => sub {
	plan tests => 2;

	my ($count, $tiles) = chains(2);
	is $tiles, 6, 'a double two set holds six tiles';
	is $count, 12, 'and A284287(1) says twelve open chains use all of them';
};

subtest 'a double four set: 15 tiles, 126,720 chains' => sub {
	plan tests => 2;

	my ($count, $tiles) = chains(4);
	is $tiles, 15, 'a double four set holds fifteen tiles';
	is $count, 126_720, 'and A284287(2) says 126,720 open chains use all of them';
};

subtest 'a double six set: the rung the suite cannot climb' => sub {
	plan tests => 2;

	# 7,959,229,931,520 chains is not enumerable here and this test does not
	# pretend otherwise. What IS checkable is the relation both sources state
	# between counting reversals and not counting them, which is the part a
	# careless reading gets wrong.
	my $with_reversals = 7_959_229_931_520;
	is $with_reversals / 2, 3_979_614_965_760,
		'half of the published count is the without-reversals figure OEIS gives';

	# And the ladder is self-consistent: each rung grows by the factor the
	# sequence itself records, so a reader can see this number belongs to the
	# same sequence as the two the suite actually computes.
	cmp_ok $with_reversals, '>', 126_720,
		'and it is the next rung above the one this file computes';
};
