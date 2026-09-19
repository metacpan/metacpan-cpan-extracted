#!perl

# THE DIFFERENTIAL TEST THIS DISTRIBUTION WOULD OTHERWISE NOT HAVE.
#
# The board, the rules and the scorers exist once each, in C. There is no
# pure-Perl implementation to compare against, no published perft ladder for Go,
# and no reference engine whose licence lets us vendor it. What there is, is TWO
# SCORERS OVER ONE POSITION, and a published statement of when they must agree.
#
# Wikipedia's "Rules of Go":
#
#   If the game ends with both players having played the same number of stones,
#   then the result will be identical in territory and area scoring: indeed, the
#   difference of stones on the board will equal the difference of prisoners and
#   hence the difference of score will be the same.
#
# The condition implemented is EQUAL STONES PLAYED AND NO AGREED SEKI, which is
# derived in a comment in Game::Go::Scoring rather than copied. Two things that
# look as though they should matter do not, and this file asserts both:
# removing dead stones preserves the identity, and unfilled dame preserves it.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Scoring;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

sub walls {
	my $g = Game::Go->new(size => 9);
	for my $row (0 .. 8) {
		$g->play($B, $g->point(3, $row));
		$g->play($W, $g->point(5, $row));
	}
	return $g;
}

subtest 'the condition holds, and the two scorers agree' => sub {
	my $g = walls();
	my $played = Game::Go::Scoring::stones_played($g);
	is($played->{$B}, 9, 'black played nine stones');
	is($played->{$W}, 9, 'white played nine');

	is(Game::Go::Scoring::agree_under_equivalence($g), 1,
		'so the condition holds and the two margins are the same');

	# Shown rather than asserted only through the method, so a reader can see
	# what is being compared. Territory: 27 - 0 against 27 - 0, a margin of 0.
	# Area: 36 against 36, a margin of 0.
	my $raw = $g->raw_score;
	my $territory = ($raw->{territory_b} - $raw->{prisoners_w})
	              - ($raw->{territory_w} - $raw->{prisoners_b});
	my $area = $raw->{area_b} - $raw->{area_w};
	is($territory, 0, 'the territory margin');
	is($area, 0, 'and the area margin');
	is($territory, $area, 'are the same number');
	done_testing();
};

subtest 'unequal stones played, and the question does not apply' => sub {
	my $g = walls();
	$g->pass($W);            # white gives up a move, so black plays one more
	$g->play($B, $g->point(0, 0));

	my $played = Game::Go::Scoring::stones_played($g);
	is($played->{$B}, 10, 'black has played ten');
	is($played->{$W}, 9, 'white nine');

	# UNDEF RATHER THAN 0. The identity says nothing about this position, and
	# reporting a failure would be reporting one where none was claimed. The
	# gate counts how often the condition HELD for exactly this reason.
	is(Game::Go::Scoring::agree_under_equivalence($g), undef,
		'so the method declines to answer');
	done_testing();
};

subtest 'an agreed seki DOES break it, and is excluded' => sub {
	my $g = walls();
	$g->pass($g->turn);
	$g->pass($g->turn);
	$g->mark_seki($g->marking->proposer, $g->point(0, 0));

	# Territory excludes a seki; area does not. So the two genuinely disagree
	# here, and the condition excludes the case rather than reporting a bug.
	is(Game::Go::Scoring::agree_under_equivalence($g), undef,
		'a marked seki takes the position out of the comparison');
	done_testing();
};

subtest 'removing dead stones does NOT break it' => sub {
	# The plan this was written from asked for the dead set to be empty. The
	# algebra says otherwise: lifting k black stones moves k out of the board
	# count and into the prisoners WHITE holds, which changes both sides of
	# the identity by the same k.
	#
	# Black plays a stone into white's area and it is agreed dead.
	my $g = walls();
	$g->play($B, $g->point(7, 4));     # a black stone in white's territory
	$g->play($W, $g->point(0, 0));     # and one for white, to keep the counts even

	my $played = Game::Go::Scoring::stones_played($g);
	is($played->{$B}, $played->{$W}, 'the stone counts are still equal');

	$g->pass($g->turn);
	$g->pass($g->turn);
	$g->mark($g->marking->proposer, $g->point(7, 4));
	is(scalar @{ $g->marking->dead_points }, 1, 'one chain is agreed dead');

	is(Game::Go::Scoring::agree_under_equivalence($g), 1,
		'and the two scorers still agree');
	done_testing();
};

subtest 'unfilled dame does NOT break it' => sub {
	# Column 4 is nine points of dame that nobody ever fills. Dame counts zero
	# to both scorers, so it cannot move either margin.
	#
	# The gate note in the plan said an unfilled dame would be a reason the
	# condition stops holding. It is not; only an unequal stone count is.
	my $g = walls();
	my $raw = $g->raw_score;
	is($raw->{dame}, 9, 'nine points of dame, never filled');
	is(Game::Go::Scoring::agree_under_equivalence($g), 1, 'and the two still agree');

	# Filling one DOES change the answer, and only by making the counts
	# unequal, which the condition catches on its own.
	$g->play($B, $g->point(4, 0));
	is(Game::Go::Scoring::agree_under_equivalence($g), undef,
		'filling a dame point makes the counts unequal, and the question lapses');

	$g->play($W, $g->point(4, 1));
	is(Game::Go::Scoring::agree_under_equivalence($g), 1,
		'and when white fills one back, they agree again');
	done_testing();
};

subtest 'a capture, which is what the identity is really about' => sub {
	# S_b = N_b - P_w: a stone leaves the board only by being captured, and a
	# captured black stone is a prisoner WHITE holds. The identity rests on
	# that, so a position with real prisoners in it is the one that tests it.
	#
	#   B (1,0), W (0,0), B (0,1) takes the corner.
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(1, 0));
	$g->play($W, $g->point(0, 0));
	$g->play($B, $g->point(0, 1));
	$g->play($W, $g->point(8, 8));

	is($g->prisoners->{$B}, 1, 'black holds one prisoner');

	# COUNT THE PLAYS, NOT THE STONES. Black has played two stones and white
	# two, but one of white's is off the board, so white has one on it. The
	# first draft of this subtest asserted black had played three and the
	# engine was right; miscounting here is exactly the mistake the identity
	# exists to catch elsewhere.
	my $played = Game::Go::Scoring::stones_played($g);
	is($played->{$B}, 2, 'black has played two stones');
	is($played->{$W}, 2, 'and white two, of which one was captured');
	is(Game::Go::Scoring::agree_under_equivalence($g), 1,
		'the counts are equal, so the two scorers agree, real prisoner and all');

	# One more black stone and they are unequal again.
	$g->play($B, $g->point(4, 4));
	$played = Game::Go::Scoring::stones_played($g);
	is($played->{$B}, 3, 'black plays a third');
	is($played->{$W}, 2, 'white still has two');
	is(Game::Go::Scoring::agree_under_equivalence($g), undef, 'and the question lapses');
	done_testing();
};

subtest 'the scorers agree across a run of games' => sub {
	# A cheap version of what gate mark 3 will do over a thousand bot games:
	# play a batch, count how often the condition held, and assert there was
	# not one disagreement.
	#
	# THE SECOND HALF MATTERS AS MUCH AS THE FIRST. If the condition almost
	# never held, the identity would not be being tested at all and a green
	# run would mean nothing. So the number of games where it held is
	# asserted, not just the number of disagreements.
	my ($held, $lapsed, $disagreed) = (0, 0, 0);

	for my $n (1 .. 20) {
		my $g = Game::Go->new(size => 9);

		# A deterministic sprinkle, played in PAIRS, with BOTH moves checked
		# before EITHER is played.
		#
		# Two earlier versions of this loop got it wrong the same way: they
		# committed black's move and only then found white's was refused, so
		# the counts drifted apart and the condition held in seven games of
		# twenty. A batch that mostly lapses proves nothing, and a green run
		# over it would have meant nothing either.
		# The pair is tried on a CLONE and committed only if both take, which
		# is the only way to know white's move is legal without having already
		# played black's.
		for my $i (0 .. $n) {
			my $bp = $g->point(($i * 3) % 9, ($i * 5) % 9);
			my $wp = $g->point(($i * 7 + 1) % 9, ($i * 2 + 4) % 9);
			last if $bp < 0 || $wp < 0 || $bp == $wp;

			my $try = $g->clone;
			last if ref $try->play($B, $bp) eq 'Game::Go::Error';
			last if ref $try->play($W, $wp) eq 'Game::Go::Error';

			$g->play($B, $bp);
			$g->play($W, $wp);
		}

		my $verdict = Game::Go::Scoring::agree_under_equivalence($g);
		if    (!defined $verdict) { $lapsed++ }
		elsif ($verdict)          { $held++ }
		else                      { $disagreed++; diag "game $n DISAGREED" }
	}

	is($disagreed, 0, 'not one disagreement');
	cmp_ok($held, '>=', 18, "and the condition held in $held of 20 games, so it was really tested");
	note("held: $held   lapsed: $lapsed   disagreed: $disagreed");
	done_testing();
};

done_testing();
