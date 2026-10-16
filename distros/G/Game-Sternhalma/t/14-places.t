use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Sternhalma::Engine ':all';
use SthT qw(near_home move_not_to);
my $E = 'Game::Sternhalma::Engine';

# ---- four seats finish in the order 2, 0, 3, and the race ends there ---------------------

{
    my ($bd, @gap) = near_home(4);
    my @turns;
    my $step = sub {
        my ($finish) = @_;
        my $s = $bd->to_move;
        push @turns, $s;
        my @m = $finish ? ($gap[$s][1], $gap[$s][0]) : move_not_to($bd, $gap[$s][0], $gap[$s][1]);
        my ($why) = $bd->play(@m);
        is($why, PLAY_OK, "seat $s " . ($finish ? 'goes home' : 'moves'));
    };
    $bd->set_to_move(2);
    $step->(1);
    ok($bd->finished(2), 'seat 2 is home first');
    is($bd->place_of(2), 1, '  in first place');
    ok(!$bd->over, '  and the others play on');
    $step->(0);
    $step->(1);
    is($bd->place_of(0), 2, 'seat 0 home second');
    $step->(0);
    ok(!$bd->over, 'three seats racing, two home: not over');
    $step->(1);
    is_deeply(\@turns, [ 2, 3, 0, 1, 3 ], 'turns ran clockwise and skipped seat 2 once it was home');
    ok($bd->over, 'seat 3 home third leaves seat 1 alone, and the game is over');
    is($bd->how, BY_HOME, '  by home');
    is_deeply([ $bd->places ], [ 2, 4, 1, 3 ], 'places by seat: 0 second, 1 last, 2 first, 3 third');
    my ($why) = $bd->play($gap[1][1], $gap[1][0]);
    is($why, WHY_OVER, 'no move after the end');
}

# ---- two seats: the first home wins at once ------------------------------------------------

{
    my ($bd, @gap) = near_home(2);
    $bd->set_to_move(1);
    $bd->play($gap[1][1], $gap[1][0]);
    ok($bd->over, 'two seats: seat 1 home ends it');
    is_deeply([ $bd->places ], [ 2, 1 ], '  seat 1 first, seat 0 second');
}

# ---- every play, pass and resign undone, last first ----------------------------------------

srand 20261019;
my ($games, $plies, $undo_ok) = (0, 0, 1);
for my $seats (2, 3, 4, 6) {
    for (1 .. 15) {
        my $bd = $E->new(seats => $seats);
        my @history;
        $games++;
        while (!$bd->over && @history < 300) {
            my $before = join '|', $bd->to_string, $bd->key, $bd->ply, $bd->to_move, $bd->over, $bd->how,
                join(',', $bd->places), join(',', map { $bd->finished($_) } 0 .. $seats - 1);
            my ($why, $undo);
            if (rand() < 0.01 && $seats > 2) {
                ($why, $undo) = $bd->resign(int rand $seats);
            }
            elsif ($bd->can_pass) {
                ($why, $undo) = $bd->pass;
            }
            else {
                my @l = $bd->legal;
                ($why, $undo) = $bd->play(@{ $l[ rand @l ] });
            }
            push @history, [ $undo, $before ] if $why == PLAY_OK;
        }
        while (my $h = pop @history) {
            $bd->unplay($h->[0]) or $undo_ok = 0;
            $plies++;
            my $now = join '|', $bd->to_string, $bd->key, $bd->ply, $bd->to_move, $bd->over, $bd->how,
                join(',', $bd->places), join(',', map { $bd->finished($_) } 0 .. $seats - 1);
            $undo_ok = 0 unless $now eq $h->[1];
        }
    }
}
is($games, 60, '60 random games at 2, 3, 4 and 6 seats');
cmp_ok($plies, '>', 10_000, "$plies plays, passes and resigns");
ok($undo_ok, '  each undone, last first, to exactly the game before it: board, key, ply, turn, places');

done_testing();
