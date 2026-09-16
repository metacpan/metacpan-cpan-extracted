#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Gin::Scoring qw(match_result TARGET BOX_BONUS GAME_BONUS);

# What a whole match came to.
#
# THE ASSERTION THIS FILE EXISTS FOR is the one about inverted totals. A
# scorer that simply compared the two final numbers and called the bigger one
# the winner would pass every other test here, and would be wrong: the player
# who reaches the target wins, and the bonuses decide the margin.
#
# That was written into this plan the other way round before the sources were
# read. Both of them are plain about it. Wikipedia: "The game ends when a
# player reaches 100 or more points", and the game bonus goes to that player.
# Pagat: "The game continues with further deals until one player's cumulative
# score reaches 100 points or more", and then "The winner receives an
# additional bonus".

sub hand { my ($w, $p) = @_; return { winner => $w, points => $p, kind => 'knock' } }
sub cancelled { return { winner => undef, points => 0, kind => 'cancelled' } }

subtest 'the pinned match constants' => sub {
    plan tests => 3;
    is(TARGET,     100, 'a game is to 100');
    is(BOX_BONUS,   25, 'a hand won is worth 25 at the end');
    is(GAME_BONUS, 100, 'and winning the game 100');
};

subtest 'an ordinary match' => sub {
    plan tests => 5;
    # p1 wins three hands and gets there; p2 wins one on the way.
    my $r = match_result(hands => [ hand('p1', 40), hand('p2', 15), hand('p1', 35), hand('p1', 30) ]);

    is($r->{winner}, 'p1', 'the player who reached 100 won');
    is($r->{hand_points}{p1}, 105, 'with 105 in hand points');
    is($r->{hands_won}{p1}, 3, 'from three hands');
    is($r->{totals}{p1}, 105 + 3 * BOX_BONUS + GAME_BONUS, 'points, three boxes and the game bonus');
    is($r->{totals}{p2}, 15 + 1 * BOX_BONUS, 'and the loser keeps their points and box');
};

# ---- THE ONE THAT MATTERS ------------------------------------------------------------------

subtest 'the loser can finish with the higher total and still be the loser' => sub {
    plan tests => 5;
    # p2 wins eight small hands: 88 points and eight boxes, which is 288.
    # p1 wins two big ones: 100 points, two boxes and the game bonus, 250.
    my @hands = ((map { hand('p2', 11) } 1 .. 8), hand('p1', 50), hand('p1', 50));
    my $r = match_result(hands => \@hands);

    is($r->{winner}, 'p1', 'p1 reached the target, so p1 won the game');
    is($r->{hand_points}{p2}, 88, 'p2 never got there');
    is($r->{totals}{p1}, 250, 'p1 totals 250');
    is($r->{totals}{p2}, 288, 'p2 totals 288, which is more');
    cmp_ok($r->{totals}{ $r->{winner} }, '<', $r->{totals}{ $r->{loser} },
           'and the winner of the game has the lower total, which is the whole point');
};

# ---- the shutout ------------------------------------------------------------------------------

subtest 'a shutout doubles the hand points, and does it before the boxes' => sub {
    plan tests => 4;
    my $r = match_result(hands => [ hand('p1', 40), hand('p1', 30), hand('p1', 35) ]);

    ok($r->{shutout}, 'the loser won nothing, so it is a shutout');
    # 105 doubled is 210, then three boxes, then the game bonus.
    is($r->{totals}{p1}, 210 + 3 * BOX_BONUS + GAME_BONUS, 'doubled, then the boxes, then the bonus');
    # Doubling AFTER the boxes would pay them twice: 105 + 75 = 180, doubled
    # is 360, plus 100 is 460. The order is stated in the source and this is
    # the assertion that holds it.
    isnt($r->{totals}{p1}, (105 + 3 * BOX_BONUS) * 2 + GAME_BONUS,
         'and not the other way round, which would pay the boxes twice');
    is($r->{totals}{p2}, 0, 'the shut-out player has nothing');
};

subtest 'one hand to the other player is not a shutout' => sub {
    plan tests => 2;
    my $r = match_result(hands => [ hand('p1', 40), hand('p2', 5), hand('p1', 30), hand('p1', 35) ]);
    ok(!$r->{shutout}, 'a single hand lost breaks it');
    is($r->{totals}{p1}, 105 + 3 * BOX_BONUS + GAME_BONUS, 'so nothing is doubled');
};

# ---- a hand nobody won --------------------------------------------------------------------------

subtest 'a cancelled hand is won by nobody' => sub {
    plan tests => 4;
    my $r = match_result(hands => [ hand('p1', 40), cancelled(), hand('p1', 30), hand('p1', 35) ]);

    is($r->{hands_won}{p1}, 3, 'three hands won, not four played');
    is($r->{hands_won}{p2}, 0, 'and none to the other seat');
    is($r->{totals}{p1}, 210 + 3 * BOX_BONUS + GAME_BONUS, 'three boxes, not four');
    # The sources do not say whether a cancelled hand breaks a shutout. It is
    # not a hand anybody won, so it does not, and the reading is recorded here
    # rather than left to be rediscovered.
    ok($r->{shutout}, 'and a cancelled hand does not break a shutout');
};

subtest 'a match nobody has won yet' => sub {
    plan tests => 3;
    my $r = match_result(hands => [ hand('p1', 20), hand('p2', 15) ]);
    is($r->{winner}, undef, 'no winner below the target');
    is($r->{shutout}, 0, 'and no shutout');
    is($r->{totals}{p1}, 20 + BOX_BONUS, 'the totals are still reported');
};

subtest 'the target is settable' => sub {
    plan tests => 2;
    my $r = match_result(hands => [ hand('p1', 30) ], target => 25);
    is($r->{winner}, 'p1', 'thirty beats a target of twenty-five');
    is($r->{target}, 25, 'and the target is reported back');
};

done_testing();
