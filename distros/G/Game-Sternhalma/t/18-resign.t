use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Sternhalma::Engine ':all';
use SthT qw(near_home move_not_to);
my $E = 'Game::Sternhalma::Engine';

# ---- four seats: one home, then two resign -------------------------------------------------

{
    my ($bd, @gap) = near_home(4);
    $bd->set_to_move(2);
    $bd->play($gap[2][1], $gap[2][0]);
    ok($bd->finished(2), 'seat 2 home first');
    is($bd->to_move, 3, '  seat 3 to move');

    my ($why) = $bd->resign(2);
    is($why, WHY_SEAT_DONE, 'a seat already home may not resign');
    ($why) = $bd->resign(4);
    is($why, WHY_NOT_A_SEAT, 'nor may a seat the game does not have');

    ($why, my $undo) = $bd->resign(1);
    is($why, PLAY_OK, 'seat 1 resigns, not on its turn');
    ok(!$bd->over, '  two seats still racing: the game goes on');
    is($bd->to_move, 3, '  and it is still seat 3\'s turn');
    $bd->play(move_not_to($bd, $gap[3][0], $gap[3][1]));
    is($bd->to_move, 0, 'seat 3 moves; seat 0 next, seat 1 skipped as seat 2 is');
    ($why) = $bd->resign(0);
    is($why, PLAY_OK, 'seat 0 resigns on its turn');
    ok($bd->over, '  which leaves seat 3 alone: over');
    is($bd->how, BY_RESIGN, '  by resignation');
    is_deeply([ $bd->places ], [ 3, 4, 1, 2 ],
        'seat 2 home first; seat 3 racing, second; seat 0 resigned last, third; seat 1 resigned first, fourth');
    ok(defined $bd->at($gap[1][1]), 'a resigned seat\'s pieces stay on the board');
}

# ---- two seats --------------------------------------------------------------------------

{
    my $bd = $E->new(seats => 2);
    my ($why, $undo) = $bd->resign(1);
    ok($bd->over, 'two seats: one resigns, the game is over');
    is_deeply([ $bd->places ], [ 1, 2 ], '  the other wins');
    $bd->unplay($undo);
    ok(!$bd->over, 'the resignation undone: the game runs again');
    is_deeply([ $bd->places ], [ 0, 0 ], '  and nobody has a place');
    is($bd->to_move, 0, '  seat 0 to move');
}

{
    my $bd = $E->new(seats => 3);
    $bd->resign(0);
    is($bd->to_move, 1, 'three seats: the seat to move resigns, and the turn passes on');
}

done_testing();
