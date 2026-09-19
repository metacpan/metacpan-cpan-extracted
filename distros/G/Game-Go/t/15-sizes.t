#!perl

# The three board sizes.
#
# 9x9, 13x13 and 19x19 are one code path with a different constant. Article 3 of
# the Japanese rules says 19x19 and nothing else; the other two are on
# Wikipedia's authority, "Most Go is played on a 19 x 19 board, but 13 x 13 and
# 9 x 9 are also popular sizes".
#
# THE CORNER IS WHERE A STRIDE BUG SHOWS. The board is padded with a sentinel
# ring and the stride is size + 2, so a size the arithmetic was not written for
# puts the corners in the wrong place and moves very little else. Every subtest
# here that could be written once per size is written once per size.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Rules;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

subtest 'three sizes, and nothing else' => sub {
	is_deeply([ Game::Go->sizes ], [ 9, 13, 19 ], 'the three the distribution offers');

	for my $size (Game::Go->sizes) {
		my $g = Game::Go->new(size => $size);
		is($g->size, $size, "size $size builds");
		is($g->board->size, $size, "and its board agrees");
	}

	# The ENGINE takes any size from 2 to 19, because generalising the C costs
	# nothing. The GAME offers three, because a size with no literature has no
	# test oracle.
	for my $bad (2, 5, 8, 10, 12, 14, 18, 20) {
		ok(!eval { Game::Go->new(size => $bad); 1 }, "size $bad is not offered");
	}
	done_testing();
};

subtest 'the geometry, at every size' => sub {
	for my $size (Game::Go->sizes) {
		my $g = Game::Go->new(size => $size);
		my $last = $size - 1;

		# The four corners, which is where a stride that is off by one moves
		# things and nothing else obviously changes.
		is_deeply([ $g->col_row($g->point(0, 0)) ], [ 0, 0 ], "size $size: top left round-trips");
		is_deeply([ $g->col_row($g->point($last, 0)) ], [ $last, 0 ], "size $size: top right");
		is_deeply([ $g->col_row($g->point(0, $last)) ], [ 0, $last ], "size $size: bottom left");
		is_deeply([ $g->col_row($g->point($last, $last)) ], [ $last, $last ], "size $size: bottom right");

		is($g->point(-1, 0), -1, "size $size: off the left is not a point");
		is($g->point($size, 0), -1, "size $size: nor off the right");
		is($g->point(0, $size), -1, "size $size: nor off the bottom");

		# A corner stone has two liberties at any size. An edge stone three.
		$g->play($B, $g->point(0, 0));
		is($g->board->libs(0, 0), 2, "size $size: a corner stone has two liberties");
		$g->play($W, $g->point($last, 0));
		is($g->board->libs($last, 0), 2, "size $size: and so does the far corner");

		is(scalar @{ $g->legal($B) }, $size * $size - 2 + 1,
			"size $size: every empty point, and a pass");
	}
	done_testing();
};

subtest 'a game plays out at every size' => sub {
	for my $size (Game::Go->sizes) {
		my $g = Game::Go->new(size => $size);
		my $last = $size - 1;

		# A capture in the corner, which exercises the ring on two sides at
		# once: white at (0,0), black at (1,0) and (0,1).
		$g->play($B, $g->point(1, 0));
		$g->play($W, $g->point(0, 0));
		my $m = $g->play($B, $g->point(0, 1));
		is($m->captured, 1, "size $size: a corner capture");
		is($g->board->at(0, 0), Game::Go::EMPTY, "size $size: and the point is empty");
		is($g->prisoners->{$B}, 1, "size $size: with a prisoner recorded");

		# And it scores, and the whole board is accounted for.
		$g->pass($g->turn);
		$g->pass($g->turn);
		$g->done($g->marking->proposer);
		$g->accept($g->marking->answerer);
		is($g->status, 'finished', "size $size: the game finishes");

		my $raw = $g->raw_score;
		is($raw->{eyes_b} + $raw->{eyes_w} + $raw->{dame} + $raw->{stones_b} + $raw->{stones_w},
			$size * $size, "size $size: and every point on the board is accounted for");
	}
	done_testing();
};

subtest 'the star points, per size' => sub {
	# Sensei's Library: the 19x19 board has NINE star points, "the 4-4 point
	# (corner star), the 10-4 point (side star) and the 10-10 point (tengen)".
	# "A 13x13 board has only five star points", and "A 9x9 board also has only
	# five star points."
	is(scalar @{ Game::Go::Rules::star_points(19) }, 9, '19x19 has nine star points');
	is(scalar @{ Game::Go::Rules::star_points(13) }, 5, '13x13 has five');
	is(scalar @{ Game::Go::Rules::star_points(9) }, 5, 'and 9x9 has five');

	# 19x19's are cited: lines 4, 10 and 16, which are 0-indexed 3, 9 and 15.
	my %seen = map { join(',', @$_) => 1 } @{ Game::Go::Rules::star_points(19) };
	ok($seen{'3,3'}, '19x19: the 4-4 corner star');
	ok($seen{'15,15'}, '19x19: the far corner');
	ok($seen{'9,9'}, '19x19: tengen at 10-10');
	ok($seen{'9,3'}, '19x19: a 10-4 side star');
	is(scalar keys %seen, 9, 'and all nine are distinct');

	# Every star point is on the board it belongs to.
	for my $size (Game::Go->sizes) {
		my $g = Game::Go->new(size => $size);
		my $off = grep { $_ < 0 } @{ $g->star_points };
		is($off, 0, "size $size: every star point is a real point");
	}
	done_testing();
};

subtest 'komi is the same on every size, and that is a house choice' => sub {
	# There is a citable convention for 19x19 and NONE AT ALL for 9x9. The
	# British Go Association records komi 6 for traditional Japanese rules in
	# Britain; the half point is the anti-jigo device rather than part of the
	# compensation. 6.5 across all three sizes is ours, for uniformity: one
	# komi means one scoring path and one number for a player to learn.
	for my $size (Game::Go->sizes) {
		my $g = Game::Go->new(size => $size);
		is($g->komi, 6.5, "size $size: komi 6.5");
	}
	is(Game::Go::Rules::DEFAULT_KOMI, 6.5, 'and it is one constant, not three');
	done_testing();
};

done_testing();
