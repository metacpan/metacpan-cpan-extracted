use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

my $C = $E->hole_at(0, 0);

# ---- a seat walled in passes ----------------------------------------------------------
#
# Seat 0's only piece is in the middle, its six neighbours seat 1's and the six
# holes beyond them seat 1's too: no step, no hop.

{
    my $bd = $E->new(seats => 2, empty => 1);
    $bd->put($C, 0);
    for my $d (E .. SE) {
        my $n = $E->next_to($C, $d);
        $bd->put($n, 1);
        $bd->put($E->next_to($n, $d), 1);
    }
    is(scalar(my @l = $bd->legal), 0, 'seat 0 walled in has no move');
    ok($bd->can_pass, '  and may pass');
    my ($why) = $bd->play($C, $E->next_to($C, E));
    is($why, WHY_UNREACHABLE, '  and may not move');
    ($why, my $undo) = $bd->pass;
    is($why, PLAY_OK, 'seat 0 passes');
    is($bd->to_move, 1, '  and it is seat 1\'s turn');
    is($bd->ply, 1, '  a pass is a ply');
    ok(!$bd->can_pass, 'seat 1 has moves');
    ($why) = $bd->pass;
    is($why, WHY_HAS_MOVE, '  and may not pass');
    ok(!$bd->over, 'one seat passing is not a deadlock');
    $bd->unplay($undo);
    is($bd->to_move, 0, 'the pass undone: seat 0 to move again');
}

# ---- nobody can move: a deadlock --------------------------------------------------------
#
# Every hole full: no empty hole, so no step and no hop for anyone.

for my $seats (2, 3) {
    my $bd = $E->new(seats => $seats, empty => 1);
    for my $h (0 .. HOLES - 1) {
        $bd->put($h, $h % $seats);
    }
    for my $s (0 .. $seats - 1) {
        my ($why) = $bd->pass;
        is($why, PLAY_OK, "$seats seats: seat $s passes");
        last if $bd->over;
    }
    ok($bd->over, "$seats seats: every seat passed in a row, and the game is over");
    is($bd->how, BY_DEADLOCK, '  by deadlock');
    my @d = map { $bd->distance_left($_) } 0 .. $seats - 1;
    my @want = map { my $s = $_; 1 + grep { $d[$_] < $d[$s] } 0 .. $seats - 1 } 0 .. $seats - 1;
    is_deeply([ $bd->places ], \@want, "  placed by distance left (@d): @want");
}

# ---- a move breaks a run of passes ---------------------------------------------------------

{
    my $bd = $E->new(seats => 3, empty => 1);
    $bd->put($C, 0);
    for my $d (E .. SE) {
        my $n = $E->next_to($C, $d);
        $bd->put($n, 1);
        $bd->put($E->next_to($n, $d), 1);
    }
    $bd->put(0, 2);
    $bd->pass;
    my @l = $bd->legal;
    $bd->play(@{ $l[0] });
    is($bd->to_move, 2, 'seat 0 passed, seat 1 moved; seat 2 to move');
    @l = $bd->legal;
    $bd->play(@{ $l[0] });
    is($bd->to_move, 0, 'seat 2 moved; seat 0 again');
    $bd->pass;
    ok(!$bd->over, 'a pass after moves is no deadlock: the run of passes started again');
}

done_testing();
