#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills::Board;
use Game::Merrills::Rules;

unless ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

# PLY 5, WORKED OUT BY HAND.
#
# Ply 5 is white's third man, the first move that can close a mill. Were no
# mill possible it would be 255,024 x 20 = 5,100,480: twenty empty points at
# each of the 255,024 positions four plies in.
#
# A placement that closes a mill is not one move but one for each black man
# it could take. Black has two men down and neither is in a mill, so it is two
# moves where it would have been one: each closing placement adds exactly 1.
#
# White can close at ply 5 when its two men are two points of one mill and the
# third is empty. Two points of a mill, in the order they were placed:
# 16 mills x 3 pairs x 2 orders = 96, and no pair of points shares two mills.
# Black's two men, in order, are on any two of the other 22 points except the
# mill's third: 22 x 21 - 2 x 21 = 420.
#
#   96 x 420 = 40,320 closing placements
#   5,100,480 + 40,320 = 5,140,800

my @SIDE = qw/white black/;

my ($nodes, $closing) = (0, 0);

sub walk {
	my ($position, $ply, $depth) = @_;
	my $moves = Game::Merrills::Rules::generate($position, $SIDE[ $ply % 2 ]);
	if ($depth == 1) {
		$nodes += @{$moves};
		$closing += grep { defined $_->[Game::Merrills::Rules::RM_REMOVE] } @{$moves};
		return;
	}
	for my $move (@{$moves}) {
		Game::Merrills::Rules::apply($position, $SIDE[ $ply % 2 ], $move);
		walk($position, $ply + 1, $depth - 1);
		Game::Merrills::Rules::unapply($position, $SIDE[ $ply % 2 ], $move);
	}
	return;
}

my $position = Game::Merrills::Rules::position(Game::Merrills::Board->new);
walk($position, 0, 5);

is($nodes, 5_140_800, 'ply 5: 5,140,800');
is($closing, 2 * 40_320, 'of which 80,640 take a man: 40,320 closing placements, two men each');
is($nodes - $closing / 2, 255_024 * 20, 'and with each closing placement counted once it is 255,024 x 20');

done_testing;
