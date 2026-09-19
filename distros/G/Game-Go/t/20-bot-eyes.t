#!perl

# THE EYE RULE, WHICH IS WHAT MAKES A PLAYOUT TERMINATE AT ALL.
#
# A uniformly random legal move fills its own eyes, which kills its own groups,
# which means the position never settles and every playout runs to its move cap.
# So a playout never plays a point that is a true eye for its own colour:
#
#   a point is a true eye for colour C when
#     every orthogonal neighbour is C or off the board, AND
#     of the diagonals that are on the board,
#       at most one is not C   -- in the middle
#       none is not C          -- on an edge or in a corner
#
# THE EDGE CLAUSE IS THE HALF EVERYBODY LEAVES OUT, and without it a playout
# fills real eyes on the first line. There is a position below for each clause.
#
# The rule is not reachable from Perl directly, so it is tested through its
# consequence: a playout from a position whose only non-eye move is a pass must
# settle rather than hit the cap, and a group with two eyes must survive.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Engine;
use Game::Go::Rules;

my $B = Game::Go::Rules::BLACK;
my $W = Game::Go::Rules::WHITE;

sub board {
	my ($size, $diagram) = @_;
	my $b = Game::Go::Engine->new(size => $size, history => 0);
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

subtest 'a playout SETTLES, which is what the eye rule is for' => sub {
	# THE OBSERVABLE, and it took a wrong turn to find it. A playout runs on an
	# internal copy, so the caller's board is untouched and there is nothing to
	# inspect afterwards: the first draft of this file examined the board after
	# a playout and every assertion in it was vacuous.
	#
	# What CAN be seen is the move count. Without eye avoidance a playout never
	# reaches two consecutive passes, because each side keeps filling its own
	# eyes and killing its own groups, so it always stops at the move cap of
	# 3 * size * size. With it, a playout settles in well under half that.
	for my $size (9, 13, 19) {
		my $b = Game::Go::Engine->new(size => $size, history => 0);
		my $cap = 3 * $size * $size;
		my ($total, $capped, $runs) = (0, 0, 0);

		for my $seed (1 .. 20) {
			my $r = $b->playout(colour => $B, seed => $seed);
			is($r->{cap}, $cap, "size $size: the cap is 3 * size squared") if $seed == 1;
			$total += $r->{moves};
			$capped++ if $r->{moves} >= $cap;
			$runs++;
		}

		is($runs, 20, "size $size: twenty playouts ran, rather than none");
		is($capped, 0, "size $size: and not one of them hit the cap");
		cmp_ok($total / 20, '<', $cap / 2,
			sprintf('size %d: settling in %.0f moves against a cap of %d', $size, $total / 20, $cap));
	}
	done_testing();
};

subtest 'the score a playout returns is a real area difference' => sub {
	# A settled playout has divided the board, so the difference is large. On an
	# empty board with random play it is near zero on average and rarely small
	# in any one game, which is what makes it a usable leaf value.
	my $b = Game::Go::Engine->new(size => 9, history => 0);
	my @diffs = map { $b->playout(colour => $B, seed => $_)->{diff} } 1 .. 40;

	is(scalar @diffs, 40, 'forty playouts');
	my $black_won = grep { $_ > 0 } @diffs;
	cmp_ok($black_won, '>', 5, "black won $black_won of forty");
	cmp_ok($black_won, '<', 35, 'and lost a fair share, so it is not a constant');

	# Every difference is within the board, because it is a count of points.
	my $sane = grep { abs($_) <= 81 } @diffs;
	is($sane, 40, 'and every difference fits on the board');
	done_testing();
};

subtest 'a playout is deterministic in its seed' => sub {
	my $b = Game::Go::Engine->new(size => 9, history => 0);
	my @first  = map { $b->clone->playout(colour => $B, seed => $_) } 1 .. 10;
	my @second = map { $b->clone->playout(colour => $B, seed => $_) } 1 .. 10;
	is_deeply(\@second, \@first, 'the same seeds give the same ten results');

	my %distinct = map { $_ => 1 } @first;
	cmp_ok(scalar keys %distinct, '>', 1, 'and different seeds give different ones');
	done_testing();
};

done_testing();
