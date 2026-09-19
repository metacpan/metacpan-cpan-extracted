#!perl

# Chains and liberties, on positions drawn by hand.
#
# EVERY EXPECTED NUMBER IN THIS FILE IS DERIVED BY HAND IN A COMMENT BESIDE IT,
# and not one of them came out of the engine. That is the house rule everywhere,
# and here it is the only thing holding the engine to anything: there is no
# pure-Perl board to differ from and no published ladder to check against, so a
# figure taken from the code under test would be the code agreeing with itself.
#
# The load-bearing case is 'an empty point touching one chain twice', which is
# the case the faster liberty bookkeeping gets wrong and the reason this engine
# recounts instead.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Engine;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

# A position from a diagram. Row 0 is the TOP, matching the engine's own
# ordering. This places stones and asserts nothing, so it cannot launder an
# expectation: X is black, O is white, a dot is empty.
sub board {
	my ($size, $diagram) = @_;
	my $b = Game::Go::Engine->new(size => $size);
	my @rows = grep { /\S/ } split /\n/, $diagram;
	for my $row (0 .. $#rows) {
		my @cells = grep { length } split /\s+/, $rows[$row];
		for my $col (0 .. $#cells) {
			my $c = $cells[$col];
			next if $c eq '.';
			$b->put($b->point_of($col, $row), $c eq 'X' ? $B : $W);
		}
	}
	return $b;
}

# Sorting lives in here and not in a sort block at the call site, and that is
# not tidiness. Every board in this file is a lexical `my $b`, which SHADOWS
# sort's own $b, so `sort { $a <=> $b }` beside a board silently compares each
# element against the board object. Perl warns, the comparator is nonsense, and
# an is_deeply over two identically-mangled lists passes anyway. There is no
# lexical $b in this sub's scope, so the sort block here gets the real one.
sub numerically { return [ sort { $a <=> $b } @{ $_[0] } ] }

subtest 'one stone, and the three places it can sit' => sub {
	my $b = Game::Go::Engine->new(size => 9);

	# The centre has four neighbours, all empty.
	$b->put($b->point_of(4, 4), $B);
	is($b->libs($b->point_of(4, 4)), 4, 'a stone in the middle has 4 liberties');

	# An edge point has three neighbours on the board; the fourth is the
	# sentinel ring, which is never empty.
	$b->put($b->point_of(0, 4), $B);
	is($b->libs($b->point_of(0, 4)), 3, 'a stone on the edge has 3');

	# A corner has two.
	$b->put($b->point_of(0, 0), $B);
	is($b->libs($b->point_of(0, 0)), 2, 'a stone in the corner has 2');

	is($b->chain_size($b->point_of(4, 4)), 1, 'and each is a chain of one');
	is($b->stones($B), 3, 'three black stones on the board');
	is($b->stones($W), 0, 'and no white ones');
	done_testing();
};

subtest 'an empty point touching one chain twice is ONE liberty' => sub {
	# THE case. An L of three stones in the top left:
	#
	#     . X .          stones (1,0) (1,1) (0,1)
	#     X X .
	#     . . .
	#
	# Derived by hand, neighbour by neighbour:
	#   (1,0) -> (0,0) empty, (2,0) empty, (1,-1) ring, (1,1) own
	#   (1,1) -> (0,1) own,   (2,1) empty, (1,0) own,   (1,2) empty
	#   (0,1) -> (-1,1) ring, (1,1) own,   (0,0) empty, (0,2) empty
	#
	# Empty points named:      (0,0) (2,0) (2,1) (1,2) (0,0) (0,2)
	# DISTINCT empty points:   (0,0) (2,0) (2,1) (1,2) (0,2)  = 5
	#
	# (0,0) is named twice, by (1,0) and by (0,1), and it is one liberty.
	# A count of occurrences rather than of points says 6, and that is
	# precisely the bug in the incremental scheme this engine refused.
	my $b = board(9, <<'POS');
		. X .
		X X .
		. . .
POS

	is($b->chain_size($b->point_of(1, 1)), 3, 'the L is one chain of three stones');
	is($b->libs($b->point_of(1, 1)), 5, 'and it has 5 liberties, not the 6 an occurrence count gives');

	is($b->libs($b->point_of(1, 0)), 5, 'every stone reports its chain, so (1,0) says 5 too');
	is($b->libs($b->point_of(0, 1)), 5, 'and so does (0,1)');

	my $chain = numerically($b->chain_at($b->point_of(1, 0)));
	my $same  = numerically($b->chain_at($b->point_of(0, 1)));
	is_deeply($chain, $same, 'and all three stones are in the same chain');
	is(scalar @$chain, 3, 'and the comparison was over three points, not an empty list');
	done_testing();
};

subtest 'a 2x2 block in the corner has four liberties' => sub {
	# The other shape where the naive count goes wrong, and it goes wrong
	# twice over:
	#
	#     X X .        stones (0,0) (1,0) (0,1) (1,1)
	#     X X .
	#     . . .
	#
	#   (0,0) -> ring, own, ring, own              : nothing
	#   (1,0) -> own, (2,0) empty, ring, own       : (2,0)
	#   (0,1) -> ring, own, own, (0,2) empty       : (0,2)
	#   (1,1) -> own, (2,1) empty, own, (1,2) empty: (2,1) (1,2)
	#
	# DISTINCT: (2,0) (0,2) (2,1) (1,2) = 4
	my $b = board(9, <<'POS');
		X X .
		X X .
		. . .
POS

	is($b->chain_size($b->point_of(0, 0)), 4, 'four stones in one chain');
	is($b->libs($b->point_of(0, 0)), 4, 'and four liberties');
	done_testing();
};

subtest 'one move merging three chains' => sub {
	# Three lone stones around an empty point, then a stone on it:
	#
	#     . . X . .        (3,2)
	#     . X . X .        (2,3) and (4,3), with (3,3) empty
	#     . . . . .
	#
	# After (3,3) all four are one chain, a plus shape. A plus of five...
	# no: four stones. Derived:
	#   (3,2) -> (2,2) (4,2) (3,1) empty, (3,3) own          : 3
	#   (2,3) -> (1,3) (2,2) (2,4) empty, (3,3) own          : 3
	#   (4,3) -> (5,3) (4,2) (4,4) empty, (3,3) own          : 3
	#   (3,3) -> (3,2) (2,3) (4,3) own,   (3,4) empty        : 1
	# Named: (2,2) (4,2) (3,1) (1,3) (2,2) (2,4) (5,3) (4,2) (4,4) (3,4)
	# DISTINCT: (2,2) (4,2) (3,1) (1,3) (2,4) (5,3) (4,4) (3,4) = 8
	#
	# (2,2) is named by both (3,2) and (2,3); (4,2) by both (3,2) and (4,3).
	# So this position double-counts TWO points, not one.
	my $b = Game::Go::Engine->new(size => 9);
	$b->put($b->point_of(3, 2), $B);
	$b->put($b->point_of(2, 3), $B);
	$b->put($b->point_of(4, 3), $B);

	is($b->chain_size($b->point_of(3, 2)), 1, 'three separate stones to begin with');
	is($b->chain_size($b->point_of(2, 3)), 1, '...');
	is($b->chain_size($b->point_of(4, 3)), 1, '...');

	$b->put($b->point_of(3, 3), $B);

	is($b->chain_size($b->point_of(3, 3)), 4, 'one move joins all three into a chain of four');
	is($b->libs($b->point_of(3, 3)), 8, 'with 8 liberties, where an occurrence count says 10');
	is(scalar @{ $b->chain_at($b->point_of(2, 3)) }, 4,
		'and the chain is reachable from any of its stones');
	done_testing();
};

subtest 'an enemy stone takes a liberty away' => sub {
	my $b = Game::Go::Engine->new(size => 9);
	my $c = $b->point_of(4, 4);
	$b->put($c, $B);
	is($b->libs($c), 4, 'four to start with');

	$b->put($b->point_of(4, 3), $W);
	is($b->libs($c), 3, 'a white stone above leaves three');
	is($b->libs($b->point_of(4, 3)), 3, 'and the white stone has three of its own');

	$b->put($b->point_of(3, 4), $W);
	is($b->libs($c), 2, 'two');
	$b->put($b->point_of(5, 4), $W);
	is($b->libs($c), 1, 'one, which is atari');
	$b->put($b->point_of(4, 5), $W);
	is($b->libs($c), 0, 'and none');

	# THE ENGINE DID NOT CAPTURE IT, and that is the phase boundary: `put`
	# is a structure primitive and the rules layer is what notices a chain
	# with no liberties and lifts it. Asserting it here pins the boundary,
	# so that phase 02 adding capture is a visible change rather than a
	# silent one.
	is($b->at($c), $B, 'the surrounded stone is still on the board');
	is($b->stones($B), 1, 'and still counted');
	done_testing();
};

subtest 'lifting a chain gives its neighbours their liberties back' => sub {
	# A white stone in the corner with black on both its neighbours:
	#
	#     O X .        white (0,0), black (1,0) and (0,1)
	#     X . .
	#     . . .
	my $b = board(9, <<'POS');
		O X .
		X . .
		. . .
POS

	is($b->libs($b->point_of(0, 0)), 0, 'the white corner stone has no liberties');

	# black (1,0): (0,0) white, (2,0) empty, ring, (1,1) empty  = 2
	is($b->libs($b->point_of(1, 0)), 2, 'black (1,0) has two');

	is($b->lift($b->point_of(0, 0)), 1, 'lifting the white stone removes one stone');
	is($b->at($b->point_of(0, 0)), Game::Go::EMPTY, 'the point is empty');
	is($b->stones($W), 0, 'and white has nothing on the board');

	# (0,0) is now empty, so black (1,0) has three.
	is($b->libs($b->point_of(1, 0)), 3, 'and black (1,0) now has three');
	is($b->libs($b->point_of(0, 1)), 3, 'as does black (0,1)');
	done_testing();
};

subtest 'lifting a chain of five' => sub {
	#     X X X X X        a row of five along the top
	#     . . . . .
	#
	# Derived: the two ends have the ring above and beside them.
	#   (0,0) -> ring, (1,0) own, ring, (0,1) empty     : (0,1)
	#   (1,0) -> own, own, ring, (1,1) empty            : (1,1)
	#   (2,0) -> own, own, ring, (2,1) empty            : (2,1)
	#   (3,0) -> own, own, ring, (3,1) empty            : (3,1)
	#   (4,0) -> own, (5,0) empty, ring, (4,1) empty    : (5,0) (4,1)
	# DISTINCT: (0,1) (1,1) (2,1) (3,1) (4,1) (5,0) = 6
	my $b = board(9, <<'POS');
		X X X X X . . . .
		. . . . . . . . .
POS

	is($b->chain_size($b->point_of(2, 0)), 5, 'five stones in one chain');
	is($b->libs($b->point_of(2, 0)), 6, 'and six liberties');
	is($b->lift($b->point_of(0, 0)), 5, 'lifting from any of its stones removes all five');
	is($b->stones($B), 0, 'the board is empty again');
	done_testing();
};

subtest 'the zobrist hash follows the stones' => sub {
	my $b = Game::Go::Engine->new(size => 9);
	my $empty = $b->hash_hex;
	is($empty, '0' x 16, 'an empty board hashes to zero');

	my $pt = $b->point_of(4, 4);
	$b->put($pt, $B);
	my $one = $b->hash_hex;
	isnt($one, $empty, 'a stone changes it');
	is($one, Game::Go::Engine->zobrist_hex($B, $pt), 'to exactly that point-and-colour entry');

	$b->lift($pt);
	is($b->hash_hex, $empty, 'and lifting it puts the hash back');

	# Order independence is what makes the hash usable for superko at all: two
	# different move orders reaching the same colouring must hash the same.
	my $x = Game::Go::Engine->new(size => 9);
	$x->put($x->point_of(0, 0), $B);
	$x->put($x->point_of(8, 8), $W);
	my $y = Game::Go::Engine->new(size => 9);
	$y->put($y->point_of(8, 8), $W);
	$y->put($y->point_of(0, 0), $B);
	is($x->hash_hex, $y->hash_hex, 'two move orders to one colouring hash alike');
	is($x->pack_position, $y->pack_position, 'and pack agrees, which is what settles a collision');

	# The colours are not interchangeable.
	my $z = Game::Go::Engine->new(size => 9);
	$z->put($z->point_of(0, 0), $W);
	$z->put($z->point_of(8, 8), $B);
	isnt($z->hash_hex, $x->hash_hex, 'swapping the two colours does not');
	done_testing();
};

subtest 'the sentinel ring, and the edge wrap it exists to stop' => sub {
	# THE bug the padded board is built to make impossible. A flat index and
	# a stride added to it walks off the right-hand end of one row and comes
	# back on the left-hand end of the next, and the house has paid for this
	# one before in a sibling dist's ray walker.
	#
	# So: for every row, the right-edge point and the NEXT row's left-edge
	# point must be two chains and not one.
	for my $size (9, 13, 19) {
		my $b = Game::Go::Engine->new(size => $size);
		my $pairs = 0;
		for my $row (0 .. $size - 2) {
			my $right = $b->point_of($size - 1, $row);
			my $left  = $b->point_of(0, $row + 1);
			$b->put($right, $B);
			$b->put($left,  $B);
			is($b->chain_size($right), 1, "size $size row $row: the right edge is its own chain");
			is($b->chain_size($left),  1, "size $size row $row: and so is the next row's left edge");
			$b->lift($right);
			$b->lift($left);
			$pairs++;
		}
		is($pairs, $size - 1, "size $size: every adjacent row pair was checked");
	}
	done_testing();
};

subtest 'the ring is not reachable and not playable' => sub {
	my $b = Game::Go::Engine->new(size => 9);

	is($b->point_of(-1, 0), -1, 'a negative column is not a point');
	is($b->point_of(0, -1), -1, 'nor a negative row');
	is($b->point_of(9, 0), -1, 'nor a column off the far side');
	is($b->point_of(0, 9), -1, 'nor a row off the bottom');

	is($b->at(0), Game::Go::BORDER, 'index 0 is the ring');
	is($b->at(-1), Game::Go::BORDER, 'and so is anything off the array');
	is($b->at(100000), Game::Go::BORDER, '...');

	# put() is a no-op on the ring rather than a corruption, because the ring
	# is never empty and put() refuses a point that is not.
	$b->put(0, $B);
	is($b->at(0), Game::Go::BORDER, 'a stone cannot be put on the ring');
	is($b->stones($B), 0, 'and nothing was counted');

	# Nor on an occupied point.
	my $pt = $b->point_of(4, 4);
	$b->put($pt, $B);
	$b->put($pt, $W);
	is($b->at($pt), $B, 'nor on top of a stone');
	is($b->stones($W), 0, 'and again nothing was counted');
	done_testing();
};

subtest 'every size works, and the corner is where a stride bug shows' => sub {
	# A stride that is off by one puts the corner in the wrong place and
	# nothing else obviously moves, so the corner is the point to assert at
	# each size.
	for my $size (2, 9, 13, 19) {
		my $b = Game::Go::Engine->new(size => $size);
		is($b->size, $size, "size $size");
		is($b->stride, $size + 2, "size $size: stride is size + 2");
		is(length($b->pack_position), $size * $size, "size $size: pack is size squared bytes");

		my $tl = $b->point_of(0, 0);
		my $br = $b->point_of($size - 1, $size - 1);
		$b->put($tl, $B);
		$b->put($br, $W);
		is($b->libs($tl), 2, "size $size: the top left corner has 2 liberties")
			if $size > 2;
		is($b->libs($br), 2, "size $size: and so does the bottom right")
			if $size > 2;
		is($b->col_of($br), $size - 1, "size $size: col_of round-trips at the far corner");
		is($b->row_of($br), $size - 1, "size $size: and row_of");
	}

	my $bad = eval { Game::Go::Engine->new(size => 20); 1 };
	ok(!$bad, 'a size above 19 dies');
	$bad = eval { Game::Go::Engine->new(size => 1); 1 };
	ok(!$bad, 'and so does one below 2');
	done_testing();
};

subtest 'a clone shares nothing' => sub {
	my $b = board(9, <<'POS');
		. X .
		X X .
		. . .
POS

	my $c = $b->clone;
	is($c->hash_hex, $b->hash_hex, 'the copy starts identical');
	is($c->pack_position, $b->pack_position, 'byte for byte');

	$c->lift($c->point_of(1, 1));
	is($c->stones($B), 0, 'lifting from the copy empties the copy');
	is($b->stones($B), 3, 'and leaves the original alone');
	is($b->libs($b->point_of(1, 1)), 5, 'including its liberty counts');
	isnt($c->hash_hex, $b->hash_hex, 'the two hashes have parted');
	done_testing();
};

done_testing();
