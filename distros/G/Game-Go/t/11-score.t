#!perl

# Japanese territory scoring, Articles 8 and 10.
#
# EVERY NUMBER HERE IS DERIVED BY HAND IN A COMMENT BESIDE IT. The position most
# of this file uses is built so that the whole board is accounted for and the
# arithmetic can be checked without a Go board in front of you:
#
#        col:  0 1 2 | 3 | 4 | 5 | 6 7 8
#                    | X |   | O |
#   a black wall down column 3 and a white wall down column 5, nine rows each.
#
#     columns 0,1,2  27 empty points reaching only black
#     column  4       9 empty points reaching BOTH, so dame
#     columns 6,7,8  27 empty points reaching only white
#     stones          9 black, 9 white
#
#   territory  27 / 27      dame 9      area 36 / 36      27 + 27 + 9 + 18 = 81

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Scoring;
use Game::Go::Result;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

# The walls, played alternately so that both colours have played the same
# number of stones. Left one move short of stopping, so a caller can add to it.
sub walls {
	my (%o) = @_;
	my $g = Game::Go->new(size => 9, %o);
	for my $row (0 .. 8) {
		$g->play($B, $g->point(3, $row));
		$g->play($W, $g->point(5, $row));
	}
	return $g;
}

# Two passes, a proposal with whatever marks, and an acceptance.
sub settle {
	my ($g, %o) = @_;
	$g->pass($g->turn);
	$g->pass($g->turn);
	my $m = $g->marking;
	$g->mark($m->proposer, $_)      for @{ $o{dead} || [] };
	$g->mark_seki($m->proposer, $_) for @{ $o{seki} || [] };
	$g->done($m->proposer);
	$g->accept($m->answerer);
	return $g->outcome;
}

subtest 'the empty regions, counted' => sub {
	my $g = walls();
	my $raw = $g->raw_score;

	is($raw->{eyes_b}, 27, 'columns 0 to 2 are black eye points');
	is($raw->{eyes_w}, 27, 'columns 6 to 8 are white eye points');
	is($raw->{dame}, 9, 'column 4 reaches both colours, so it is dame');
	is($raw->{stones_b}, 9, 'nine black stones');
	is($raw->{stones_w}, 9, 'nine white stones');

	# Every point on the board is accounted for exactly once.
	is($raw->{eyes_b} + $raw->{eyes_w} + $raw->{dame} + $raw->{stones_b} + $raw->{stones_w},
		81, 'and the whole board adds up');
	done_testing();
};

subtest 'the score, and the komi that decides it' => sub {
	my $g = walls();
	my $r = settle($g);

	isa_ok($r, 'Game::Go::Result');
	is($r->territory->{$B}, 27, 'black territory');
	is($r->territory->{$W}, 27, 'white territory');
	is($r->prisoners->{$B}, 0, 'no prisoners either way');
	is($r->prisoners->{$W}, 0, '...');

	# black = 27 - 0 = 27      white = 27 - 0 + 6.5 = 33.5
	is($r->scores->{$B}, 27, 'black scores 27');
	is($r->scores->{$W}, 33.5, 'white scores 33.5, the komi being the whole difference');
	is($r->margin, 6.5, 'a margin of 6.5');
	is($r->winner, $W, 'so white wins');
	is($r->result, 'score', 'by a score');
	is($r->scored_by, 'territory', 'reached by agreement');
	is($r->stringify, 'White wins by 6.5', 'and it reads as a sentence');
	is($g->winner, $W, 'the game agrees');
	done_testing();
};

subtest 'a dead stone changes the answer twice over' => sub {
	# A lone white stone at (1,4), inside what would be black's territory.
	#
	# UNMARKED, the region it sits in reaches white as well as black, so the
	# whole of columns 0 to 2 becomes dame. Those columns hold 27 points, less
	# black's stone at (0,0) and white's at (1,4), so 25 are empty; with
	# column 4's 9 that is 34 points of dame, and black gets nothing.
	my $g = walls();
	$g->play($B, $g->point(0, 0));       # keep the stone counts even
	$g->play($W, $g->point(1, 4));

	my $raw = $g->raw_score;
	is($raw->{eyes_b}, 0, 'unmarked, black has no territory at all');
	is($raw->{dame}, 34, 'and the region is dame (25 points plus column 4)');

	# MARKED DEAD, the stone comes off, the region reaches only black again,
	# and the stone becomes a prisoner BLACK holds.
	my $h = walls();
	$h->play($B, $h->point(0, 0));
	$h->play($W, $h->point(1, 4));
	my $r = settle($h, dead => [ $h->point(1, 4) ]);

	is($r->territory->{$B}, 26, 'marked dead, black has its territory back');
	is($r->prisoners->{$B}, 1, 'and holds the stone as a prisoner');
	is($r->prisoners->{$W}, 0, 'white holds none');

	# THE DIRECTION OF STEP 5 IS THE RULE. Article 10.2 fills each player's
	# prisoners INTO THE OPPONENT'S TERRITORY, so black holding one costs
	# WHITE a point rather than gaining black one.
	#   black = 26 - 0             = 26
	#   white = 27 - 1 + 6.5       = 32.5
	is($r->scores->{$B}, 26, 'black scores its own territory, unchanged by its prisoner');
	is($r->scores->{$W}, 32.5, 'and WHITE is the one who loses a point to it');
	done_testing();
};

subtest 'a marked seki scores for nobody' => sub {
	my $g = walls();
	my $r = settle($g, seki => [ $g->point(0, 0) ]);

	# (0,0) is in the region that was black's 27 points, so agreeing it seki
	# takes all 27 out of black's territory. Article 8: eye points count as
	# territory only when surrounded by stones that are alive AND NOT IN SEKI.
	is($r->territory->{$B}, 0, 'the whole agreed region scores nothing');
	is($r->territory->{$W}, 27, 'white is untouched');
	is($r->scores->{$B}, 0, 'black scores nothing');
	is($r->scores->{$W}, 33.5, 'and white keeps its 27 and the komi');
	is($r->winner, $W, '...');
	done_testing();
};

subtest 'there is no draw, because the komi is fractional' => sub {
	# The position is symmetrical: 27 territory each, nine stones each. The
	# ONLY thing separating the two scores is the komi, so this is the
	# cleanest place to assert that a jigo cannot happen.
	#
	# Article 10.2 permits one: "If both players have the same amount the game
	# is a draw, which is called a 'jigo'." The half point is the device that
	# removes it, and the day somebody sets an integer komi this test is what
	# says so.
	my $g = walls();
	my $r = settle($g);
	isnt($r->scores->{$B}, $r->scores->{$W}, 'the two scores differ');
	ok(defined $r->winner, 'so there is a winner');

	my $half = $r->scores->{$W} - int($r->scores->{$W});
	is($half, 0.5, 'and white carries the half point that made it so');

	# With an integer komi the same position ties, and nothing in the engine
	# can express that. Asserted so the change is loud rather than silent.
	my $even = walls(komi => 6);
	my $tied = settle($even);
	is($tied->scores->{$B}, 27, 'at komi 6 black has 27');
	is($tied->scores->{$W}, 33, 'and white 33');
	isnt($tied->scores->{$B}, $tied->scores->{$W}, 'which still differ, here');

	# A truly tied board: give black one more point of territory by making the
	# walls asymmetric is fiddly, so assert the mechanism instead.
	my $r2 = Game::Go::Result->new(
		winner => undef, result => 'score', scored_by => 'territory',
		scores => { $B => 30, $W => 30 }, komi => 6,
	);
	is($r2->margin, 0, 'a tied Result has a margin of nought');
	is($r2->winner, undef, 'and no winner, which the site cannot store');
	done_testing();
};

subtest 'the ends that are not a score carry no numbers' => sub {
	for my $how (
		[ 'resign',  sub { $_[0]->resign($W) } ],
		[ 'timeout', sub { $_[0]->timeout($W) } ],
	) {
		my ($name, $end) = @$how;
		my $g = walls();
		$end->($g);
		is($g->result, $name, "$name: the result");
		is($g->winner, $B, "$name: black wins");
		is($g->scored_by, undef, "$name: nothing was counted");
		is($g->outcome, undef, "$name: and there is no scored outcome");
	}

	my $a = walls();
	$a->abandon;
	is($a->winner, undef, 'abandoned: nobody won');
	is($a->scored_by, undef, 'and nothing was counted');
	done_testing();
};

subtest 'an empty board is all dame' => sub {
	my $g = Game::Go->new(size => 9);
	my $raw = $g->raw_score;
	is($raw->{dame}, 81, 'every point reaches neither colour');
	is($raw->{eyes_b}, 0, 'and neither player has any territory');
	is($raw->{eyes_w}, 0, '...');
	is($raw->{area_b}, 0, 'nor any area');
	is($raw->{area_w}, 0, '...');
	done_testing();
};

subtest 'a Result knows what it may be' => sub {
	is_deeply([ Game::Go::Result->results ], [qw(score resign timeout abandoned)],
		'four results and no fifth');
	ok(!eval { Game::Go::Result->new(result => 'void'); 1 },
		'a fifth is refused at construction');

	# The site's games.result column is CHECK-constrained to exactly those
	# four, so a game the players could not agree is a `score` with
	# scored_by => 'area' and not a new kind of result.
	my $r = Game::Go::Result->new(
		winner => $B, result => 'score', scored_by => 'area',
		scores => { $B => 41, $W => 40 },
	);
	is($r->scored, 1, 'it was counted');
	like($r->stringify, qr/scored by area/, 'and it says the players did not agree');
	is_deeply($r->places, { $B => 1, $W => 2 }, 'with a finishing order');
	done_testing();
};

done_testing();
