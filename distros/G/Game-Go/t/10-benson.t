#!perl

# Benson's algorithm: the chains that are unconditionally alive.
#
# D. B. Benson, "Life in the Game of Go", Information Sciences 10 (1976). A
# chain is unconditionally alive if it is alive even when its owner NEVER
# ANSWERS ANOTHER MOVE, whatever the opponent does. It is the only part of life
# and death that is decidable without search, and it is the whole of what this
# engine claims to know about the subject.
#
#   X = every chain of the colour
#   R = every region: a maximal connected set of points NOT of the colour
#   repeat until nothing is removed:
#     remove from X every chain with fewer than TWO VITAL regions in R, where a
#       region is vital to a chain when EVERY EMPTY POINT in it is adjacent to
#       that chain
#     remove from R every region that touches a chain no longer in X
#
# EVERY POSITION HERE IS DRAWN AND EVERY ANSWER DERIVED IN A COMMENT. The two
# cases worth the file are 'a single two-point eye', which has two eye points
# and one vital region, and 'a doomed stone inside an eye', where a region with
# no free empty points still counts.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go::Engine;
use Game::Go::Rules;

my $B = Game::Go::Rules::BLACK;
my $W = Game::Go::Rules::WHITE;

sub board {
	my ($diagram) = @_;
	my $b = Game::Go::Engine->new(size => 9);
	my @rows = grep { /\S/ } split /\n/, $diagram;
	for my $row (0 .. $#rows) {
		my @cells = grep { length } split /\s+/, $rows[$row];
		for my $col (0 .. $#cells) {
			next if $cells[$col] eq '.';
			$b->put($b->point_of($col, $row), $cells[$col] eq 'X' ? $B : $W);
		}
	}
	return $b;
}

subtest 'two separate one-point eyes is alive' => sub {
	#        col: 0 1 2 3 4 5
	#     row 0:  . X X X X X
	#     row 1:  . X . X . X
	#     row 2:  . X X X X X
	#
	# One chain: row 0 runs 1..5, row 2 runs 1..5, and (1,1), (3,1), (5,1)
	# join them at three columns.
	#
	# Regions for black:
	#   {(2,1)}  -> neighbours (1,1) (3,1) (2,0) (2,2), all black. One empty
	#               point, adjacent to the chain. VITAL.
	#   {(4,1)}  -> the same. VITAL.
	#   the outside -> has empty points nowhere near the chain. Not vital.
	# Two vital regions, so the chain is unconditionally alive.
	my $b = board(<<'POS');
		. X X X X X
		. X . X . X
		. X X X X X
POS

	is($b->stones($B), 13, 'thirteen black stones');
	is($b->chain_size($b->point_of(1, 0)), 13, 'in one chain');

	my $alive = $b->alive($B);
	is(scalar @$alive, 13, 'and every one of them is unconditionally alive');
	is($b->is_alive($b->point_of(1, 0)), 1, 'is_alive agrees');
	is(scalar @{ $b->alive($W) }, 0, 'white has nothing alive, having nothing');
	done_testing();
};

subtest 'ONE eye is not alive, however big the wall' => sub {
	#        col: 0 1 2 3
	#     row 0:  . X X X
	#     row 1:  . X . X
	#     row 2:  . X X X
	#
	# {(2,1)} is vital. The outside is not. One vital region is not two, so
	# the chain goes, and with it the only region that named it.
	my $b = board(<<'POS');
		. X X X
		. X . X
		. X X X
POS

	is($b->stones($B), 8, 'eight stones');
	is(scalar @{ $b->alive($B) }, 0, 'and not one of them is unconditionally alive');
	done_testing();
};

subtest 'a single TWO-POINT eye is two eye points and ONE vital region' => sub {
	#        col: 0 1 2 3 4
	#     row 0:  . X X X X
	#     row 1:  . X . . X
	#     row 2:  . X X X X
	#
	# THE CASE THAT MAKES THIS ALGORITHM WORTH HAVING. A count of eye points
	# says two and would call this alive. Benson counts REGIONS: (2,1) and
	# (3,1) are connected to each other, so they are ONE region. It is vital
	# (both its empty points touch the chain) and it is the only one.
	#
	# And the Go is right as well as the arithmetic: white plays (2,1), black
	# must answer at (3,1) to capture, and a player who never answers loses
	# the group.
	my $b = board(<<'POS');
		. X X X X
		. X . . X
		. X X X X
POS

	is($b->stones($B), 10, 'ten stones');
	is($b->chain_size($b->point_of(1, 0)), 10, 'in one chain');
	is(scalar @{ $b->alive($B) }, 0, 'not unconditionally alive, despite two eye points');
	done_testing();
};

subtest 'the board edge is part of the wall' => sub {
	#        col: 0 1 2 3
	#     row 0:  . X . X
	#     row 1:  X X X X
	#
	# Eyes at (0,0) and (2,0), each closed on two sides by the sentinel ring
	# rather than by stones:
	#   (0,0) -> (1,0) black, (0,1) black, and up and left are off the board
	#   (2,0) -> (1,0) black, (3,0) black, (2,1) black, and up is off the board
	# Two vital regions. The chain is one: row 1 runs 0..3 and (1,0) and (3,0)
	# hang off it.
	my $b = board(<<'POS');
		. X . X
		X X X X
POS

	is($b->chain_size($b->point_of(1, 1)), 6, 'six stones in one chain');
	is(scalar @{ $b->alive($B) }, 6, 'alive, with the edge doing half the work');
	done_testing();
};

subtest 'a doomed stone inside an eye does not make the group killable' => sub {
	#        col: 0 1 2 3 4 5 6
	#     row 0:  . X X X X X X
	#     row 1:  . X . X O . X
	#     row 2:  . X X X X X X
	#
	# Region one: {(2,1)}, an ordinary eye. VITAL.
	# Region two: {(4,1), (5,1)}. They are adjacent and neither is black, so
	#   they are ONE region. Its only EMPTY point is (5,1), whose neighbours
	#   (6,1), (5,0) and (5,2) are black. Every empty point of the region is
	#   adjacent to the chain, so the region is VITAL even though it is two
	#   points and one of them holds a white stone.
	#
	# Two vital regions: black is unconditionally alive.
	#
	# WHICH IS THE POINT. The white stone has one liberty and is not going
	# anywhere; black can take it whenever it likes. A rule that let the
	# presence of an enemy stone in the eye space count against black would
	# let a losing player mark a living wall dead and refuse to agree.
	my $b = board(<<'POS');
		. X X X X X X
		. X . X O . X
		. X X X X X X
POS

	is($b->chain_size($b->point_of(1, 0)), 15, 'fifteen black stones in one chain');
	is($b->libs($b->point_of(4, 1)), 1, 'the white stone has one liberty');

	is(scalar @{ $b->alive($B) }, 15, 'black is unconditionally alive');
	is(scalar @{ $b->alive($W) }, 0, 'and the white stone is not');
	is($b->is_alive($b->point_of(4, 1)), 0, '...');
	done_testing();
};

subtest 'alive is a property of the chain, not of a point' => sub {
	my $b = board(<<'POS');
		. X X X X X
		. X . X . X
		. X X X X X
POS
	my $alive = $b->alive($B);
	my %alive = map { $_ => 1 } @$alive;

	# Every stone of an alive chain is in the set, so a caller can ask about
	# whichever point it happens to be holding.
	my $checked = 0;
	for my $row (0 .. 2) {
		for my $col (0 .. 5) {
			my $pt = $b->point_of($col, $row);
			next unless $b->at($pt) == $B;
			ok($alive{$pt}, "the stone at ($col,$row) is in the alive set");
			$checked++;
		}
	}
	is($checked, 13, 'and all thirteen were checked, rather than none');

	# An empty point is not alive and neither is the ring.
	is($b->is_alive($b->point_of(2, 1)), 0, 'an eye point is not a stone');
	is($b->is_alive(0), 0, 'and nor is the ring');
	done_testing();
};

subtest 'an empty board has nothing alive' => sub {
	my $b = Game::Go::Engine->new(size => 9);
	is(scalar @{ $b->alive($B) }, 0, 'black');
	is(scalar @{ $b->alive($W) }, 0, 'white');
	is(scalar @{ $b->alive(Game::Go::Rules::EMPTY) }, 0, 'and EMPTY is not a colour to ask about');
	done_testing();
};

done_testing();
