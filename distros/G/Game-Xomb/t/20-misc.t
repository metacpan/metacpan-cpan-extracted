#!perl
#
# misc. tests of misc. routines

use 5.24.0;
use warnings;
use Game::Xomb;
use Test::Most;

plan tests => 28;

my $deeply = \&eq_or_diff;

is Game::Xomb::between(1, 6, -1), 1;
is Game::Xomb::between(1, 6, 1),  1;
is Game::Xomb::between(1, 6, 3),  3;
is Game::Xomb::between(1, 6, 6),  6;
is Game::Xomb::between(1, 6, 9),  6;

# does_hit - requires a weapon structure and ideally that the RNG is setup
# NOTE distance MUST be a positive integer and the To_Hit lists must
# line up with the range (yes does_hit is some fragile code)
{
    Game::Xomb::init_jsf(int rand 2**32);

    my $weap;
    $weap->@[ Game::Xomb::WEAP_DMG, Game::Xomb::W_RANGE, Game::Xomb::W_COST ] =
      (sub () { 1 }, 3, 99);
    #                 1   2  3  range
    push $weap->@*, 100, 50, 0;

    $deeply->([ Game::Xomb::does_hit(1, $weap) ], [ 1, 99 ], 'hits');

    my ($hits, $cost) = Game::Xomb::does_hit(3, $weap);
    ok !$hits, 'miss';
    is $cost, 99;

    # 2 out of range will increase the cost so that the monster sleeps
    # until the player can be range before next check
    $deeply->(
        [ Game::Xomb::does_hit(5, $weap) ],
        [ -1, Game::Xomb::DEFAULT_COST * 2 ],
        'sleep miss'
    );

  SKIP: {
        skip "no expensive tests without AUTHOR_TEST_JMATES=1", 1
          unless $ENV{AUTHOR_TEST_JMATES};
        my $maxerr = 0.1;
        my $total  = 1000;
        $hits = 0;
        for (1 .. $total) {
            $hits += (Game::Xomb::does_hit(2, $weap))[0];
        }
        my $offby = abs($hits - $total / 2) / $total;
        ok $offby < $maxerr or diag "HITS $hits of $total err $offby";
    }
}

# do the amulet checks work? pretty important.
{
    Game::Xomb::make_player;
    ok !Game::Xomb::has_amulet;
    my $ammie = (Game::Xomb::make_amulet)[0];

    is Game::Xomb::veggie_name($ammie), '(1000) Dragonstone';

    my $stash = $Game::Xomb::Animates[Game::Xomb::HERO][Game::Xomb::STASH];
    my $loot  = $stash->[Game::Xomb::LOOT];
    is scalar $loot->@*, 0;

    push $loot->@*, $ammie;
    ok Game::Xomb::has_amulet;

    is Game::Xomb::loot_value, Game::Xomb::AMULET_VALUE;

    ok Game::Xomb::use_item($loot, 0, $stash);
    is scalar $loot->@*, 0;
    ok Game::Xomb::has_amulet;
    is $stash->[Game::Xomb::SHIELDUP][Game::Xomb::SPECIES], Game::Xomb::AMULET;

    # loot value must be the same even when Amulet being used to
    # recharge the shield (unless the shield is regenerating...)
    is Game::Xomb::loot_value, Game::Xomb::AMULET_VALUE;

    my ($gem, $gemv, $bonus) = Game::Xomb::make_gem;
    ok $gemv > 0;
    ok $bonus >= 0;

    push $loot->@*, $gem;
    is Game::Xomb::loot_value, Game::Xomb::AMULET_VALUE + $gemv;

    # swap gem for amulet
    ok Game::Xomb::use_item($loot, 0, $stash);
    is Game::Xomb::loot_value, Game::Xomb::AMULET_VALUE + $gemv;
    is scalar $loot->@*, 1;
    is $stash->[Game::Xomb::SHIELDUP][Game::Xomb::SPECIES], Game::Xomb::GEM;
}

{
    my @points;
    Game::Xomb::with_adjacent(0, 0, sub { push @points, $_[0] });
    # NOTE order may vary if internals change, ideally would sort output
    # numeric by row and column to account for that
    $deeply->(\@points, [ [ 0, 1 ], [ 1, 0 ], [ 1, 1 ] ]);
}
