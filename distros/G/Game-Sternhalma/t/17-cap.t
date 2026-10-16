use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

is($E->new(seats => 2)->cap, 2 * PLY_CAP_PER_SEAT, 'two seats: the cap is 2,000 plies (PROVISIONAL, 07 sets it)');
is($E->new(seats => 6)->cap, 6 * PLY_CAP_PER_SEAT, 'six seats: 6,000');

# ---- a game stopped at its cap ----------------------------------------------------------

{
    my $bd = $E->new(seats => 2);
    $bd->set_cap(2);
    is($bd->distance_left(0), $bd->distance_left(1), 'at the set-up both seats are as far from home');
    $bd->play(6, 15);
    $bd->play(114, 105);
    ok($bd->over, 'two plies against a cap of two: over');
    is($bd->how, BY_CAP, '  by the cap');
    is($bd->distance_left(0), $bd->distance_left(1), '  each seat stepped once, and they are level');
    is_deeply([ $bd->places ], [ 1, 1 ], '  so they share first place');
    my ($why) = $bd->play(7, 16);
    is($why, WHY_OVER, '  and nothing more is played');
}

{
    my $bd = $E->new(seats => 2);
    $bd->set_cap(2);
    $bd->play(3, 14);
    $bd->play(114, 105);
    cmp_ok($bd->distance_left(0), '<', $bd->distance_left(1), 'seat 0 hopped and seat 1 stepped: seat 0 nearer home');
    is_deeply([ $bd->places ], [ 1, 2 ], '  seat 0 first at the cap');
}

{
    my $bd = $E->new(seats => 3);
    $bd->set_cap(30);
    srand 20261020;
    while (!$bd->over && $bd->ply < 100) {
        my @l = $bd->legal;
        $bd->play(@{ $l[ rand @l ] });
    }
    ok($bd->over, 'three seats, random play to a cap of 30: over');
    is($bd->ply, 30, '  at ply 30');
    my @d = map { $bd->distance_left($_) } 0 .. 2;
    my @want = map { my $s = $_; 1 + grep { $d[$_] < $d[$s] } 0 .. 2 } 0 .. 2;
    is_deeply([ $bd->places ], \@want, "  placed by distance left (@d)");
}

# ---- distance left ----------------------------------------------------------------------

{
    my $bd = $E->new(seats => 2, empty => 1);
    my @home = $E->point_holes(($E->layout_point(2, 0) + 3) % 6);
    $bd->put($_, 0) for @home;
    is($bd->distance_left(0), 0, 'a home full of a seat\'s own pieces is 0 from home');
    $bd->lift($home[0]);
    $bd->put($E->hole_at(0, 0), 0);
    cmp_ok($bd->distance_left(0), '>', 0, 'one piece out in the middle: more than 0');
    is($E->new(seats => 2)->distance_left(0), 120, 'the set-up: 120');
}

done_testing();
