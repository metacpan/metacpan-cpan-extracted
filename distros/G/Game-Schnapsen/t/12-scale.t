#!perl
use 5.010; use strict; use warnings;
use Test::More;

use Game::Schnapsen::Variant qw(variants);
use Game::Schnapsen::Scoring qw(scale deal_result
                                TARGET_POINTS SCHNEIDER_AT LAST_TRICK_BONUS
                                PENALTY PENALTY_SCHWARZ);

# The 1/2/3 scale, which both games share word for word:
#
#   "The opponent has 33 or more card points: 1 game point. The opponent has
#    fewer than 33 card points (Schneider): 2 game points. The opponent has no
#    tricks (Schwarz): 3 game points"
#
# Schnapsen states it identically. So it is implemented once and takes no
# variant, and this file asserts that by running every case against both.

is(TARGET_POINTS, 66, 'sixty-six is sixty-six');
is(SCHNEIDER_AT, 33, 'Schneider is under 33');
is(LAST_TRICK_BONUS, 10, 'the last trick bonus is ten');
is(PENALTY, 2, 'a penalty is two');
is(PENALTY_SCHWARZ, 3, 'and three against a player with no trick');

subtest 'the three bands, either side of every threshold' => sub {
    plan tests => 8;
    is(scale(66, 4), 1, 'a losing opponent on 66 still only costs one');
    is(scale(34, 3), 1, 'thirty-four is one');
    is(scale(33, 3), 1, 'thirty-three exactly is one, because the rule says 33 OR MORE');
    is(scale(32, 3), 2, 'thirty-two is Schneider, so two');
    is(scale(1, 1), 2, 'and so is one point');
    is(scale(0, 1), 2, 'and so is none, as long as a trick was taken');
    is(scale(0, 0), 3, 'no trick at all is Schwarz, so three');
    is(scale(120, 1), 1, 'a huge losing total is still one');
};

subtest 'Schwarz counts TRICKS and not points' => sub {
    # THE OFF-BY-ONE THIS FILE EXISTS FOR. A player can take a trick of two
    # nines, hold no card points at all, and NOT be Schwarz. An implementation
    # that tests the point total gives three where the rules give two, and the
    # two cases are otherwise identical.
    plan tests => 3;
    is(scale(0, 1), 2, 'one trick worth nothing is Schneider, not Schwarz');
    is(scale(0, 0), 3, 'no trick is Schwarz');
    isnt(scale(0, 1), scale(0, 0), 'so the two must not be the same answer');
};

subtest 'the scale is shared, so both games give the same answer' => sub {
    # Not a variant predicate. If somebody ever makes it one, this fails.
    plan tests => 6;
    for my $case ([ 40, 3, 1 ], [ 10, 2, 2 ], [ 0, 0, 3 ]) {
        my ($points, $tricks, $want) = @$case;
        my %got;
        for my $v (variants()) {
            my $r = deal_result(
                variant => $v, how => 'claim', by => 'p1',
                points => { p1 => 70, p2 => $points },
                tricks => { p1 => 5, p2 => $tricks },
                closed_by => undef, close_state => undef, last_trick => 'p1');
            $got{$v} = $r->{game_points};
        }
        is($got{schnapsen}, $want, "schnapsen: $points points and $tricks tricks is $want");
        is($got{sixtysix}, $want, "sixtysix: the same");
    }
};

done_testing();
