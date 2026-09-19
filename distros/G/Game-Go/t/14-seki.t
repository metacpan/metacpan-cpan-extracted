#!perl

# SEKI, AND WHERE THIS SCORER IS KNOWINGLY WRONG.
#
# Article 8, and the clause that matters is the one in capitals:
#
#   Empty points surrounded by the live stones of just one player are called
#   "eye points." Other empty points are called "dame." Stones which are alive
#   but possess dame are said to be in "seki." Eye points surrounded by stones
#   that are alive but NOT IN SEKI are called "territory," each eye point
#   counting as one point of territory.
#
# The British Go Association's comparison table makes it the row that separates
# Japanese from every other ruleset on their page: "Can you count points in a
# seki? Japanese, Korean: No. AGA, Chinese, SST (Ing), New Zealand: Yes."
#
# A flood fill gets dame right by definition: a region reaching both colours
# belongs to nobody. What it CANNOT see is an eye inside a seki, which reaches
# one colour, is not dame, and is still not territory. Seeing that needs to know
# which groups are alive-with-dame, which is life and death, and this
# distribution has no solver.
#
# SO SEKI IS AGREED, NOT DETECTED. This file asserts both halves: that an agreed
# seki scores nothing, and that an UNAGREED one is counted as territory, which is
# the wrong answer. THE SECOND IS ASSERTED AS DOCUMENTED BEHAVIOUR. A test that
# pretended the case did not exist would be worse than one that records it, and
# if a life-and-death solver is ever written this file is what changes.

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

sub settle {
	my ($g, %o) = @_;
	$g->pass($g->turn);
	$g->pass($g->turn);
	my $m = $g->marking;
	$g->mark_seki($m->proposer, $_) for @{ $o{seki} || [] };
	$g->done($m->proposer);
	$g->accept($m->answerer);
	return $g->outcome;
}

subtest 'a region reaching both colours is dame, and that much is free' => sub {
	# The common shape of a seki is two groups sharing liberties, and the
	# points they share reach both colours. A flood fill gets that right
	# without being told anything, which is why the ordinary seki costs
	# nothing to score.
	my $g = walls();
	my $raw = $g->raw_score;
	is($raw->{dame}, 9, 'the shared column belongs to nobody');
	is($raw->{eyes_b}, 27, 'and each side keeps what only it reaches');
	is($raw->{eyes_w}, 27, '...');
	done_testing();
};

subtest 'an agreed seki scores nothing for anybody' => sub {
	my $g = walls();
	my $r = settle($g, seki => [ $g->point(0, 0) ]);

	# (0,0) is in the twenty-seven-point region that would have been black's.
	# Agreeing it seki takes the whole region out.
	is($r->territory->{$B}, 0, 'the agreed region scores nothing');
	is($r->territory->{$W}, 27, 'the other side is untouched');
	is($r->scores->{$B}, 0, 'black scores nothing');
	is($r->scores->{$W}, 33.5, 'white keeps its territory and the komi');
	done_testing();
};

subtest 'THE DOCUMENTED WRONG ANSWER: an unagreed seki is counted' => sub {
	# The same position, and the players do not mark it.
	#
	# The scorer has no way to tell a seki from a living group with
	# territory, so it counts the region for black. If those black stones are
	# really in seki, Article 8 says the region is worth NOTHING and this
	# answer is twenty-seven points wrong.
	#
	# THIS ASSERTION IS THE DEVIATION, NOT A PASSING GRADE. It is here so the
	# behaviour is recorded rather than discovered, and it is what changes if
	# a life-and-death solver is ever written.
	my $g = walls();
	my $r = settle($g);

	is($r->territory->{$B}, 27, 'unmarked, the region is counted as territory');
	is($r->scores->{$B}, 27, 'and black is given the points');

	# The two answers differ by the whole region, which is the size of the
	# deviation in this position.
	my $agreed = settle(walls(), seki => [ walls()->point(0, 0) ]);
	is($agreed->territory->{$B}, 0, 'where agreeing it would have scored nothing');
	is($r->territory->{$B} - $agreed->territory->{$B}, 27,
		'so the mark is worth the whole region, and nothing else decides it');
	done_testing();
};

subtest 'the escape hatch is Article 9.3, and it is reachable' => sub {
	# A player losing points to the deviation above is not stuck with it. The
	# confirmation phase has a dispute, the dispute sends the game back to the
	# board, and playing the seki out is what a human referee would tell them
	# to do.
	my $g = walls();
	$g->pass($g->turn);
	$g->pass($g->turn);
	is($g->phase, 'marking', 'play has stopped');

	my $m = $g->marking;
	$g->done($m->proposer);

	my @kinds = sort map { $_->kind } @{ $g->legal($m->answerer) };
	is_deeply(\@kinds, [ 'accept', 'dispute' ], 'the answerer may refuse the proposal');

	$g->dispute($m->answerer);
	is($g->phase, 'play', 'and the game goes back to the board');
	ok(scalar @{ $g->legal($g->turn) } > 1, 'with stones to play');
	done_testing();
};

subtest 'a seki mark is a point, and the region around it is what it means' => sub {
	# The players mark a POINT; the scorer resolves the region it belongs to,
	# because flood fills are the scorer's business and not the marker's. So
	# marking any point of a region takes the whole region out, and marking a
	# second point of the same region changes nothing.
	my $one = settle(walls(), seki => [ walls()->point(0, 0) ]);
	my $two = settle(walls(), seki => [ walls()->point(0, 0), walls()->point(2, 8) ]);

	is($one->territory->{$B}, 0, 'one point takes the region out');
	is($two->territory->{$B}, 0, 'and two points of the same region take out no more');
	is($one->territory->{$W}, $two->territory->{$W}, 'with the other side untouched either way');
	done_testing();
};

subtest 'a marked seki takes the position out of the equivalence check' => sub {
	# Territory excludes a seki and area does not, so the two scorers really do
	# disagree here. The check declines the position rather than reporting a
	# bug, which is the difference between a condition and an assertion.
	my $g = walls();
	is(Game::Go::Scoring::agree_under_equivalence($g), 1, 'without a mark they agree');

	$g->pass($g->turn);
	$g->pass($g->turn);
	$g->mark_seki($g->marking->proposer, $g->point(0, 0));
	is(Game::Go::Scoring::agree_under_equivalence($g), undef,
		'and with one the question lapses rather than failing');
	done_testing();
};

done_testing();
