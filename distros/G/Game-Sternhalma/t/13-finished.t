use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Sternhalma::Engine ':all';
use SthT qw(home_point near_home);
my $E = 'Game::Sternhalma::Engine';

my @home0 = $E->point_holes(home_point(2, 0));

sub with {
    my ($pieces, %put) = @_;
    my $bd = $E->new(seats => 2, pieces => $pieces, empty => 1);
    $bd->put($_, $put{$_}) for keys %put;
    return $bd;
}

# ---- the parked piece (G2) ----------------------------------------------------------

ok(with(10, map { $_ => 0 } @home0)->home_complete(0), 'all ten home: complete');
ok(with(10, (map { $_ => 0 } @home0[0 .. 8]), $home0[9] => 1)->home_complete(0),
    'nine home and a rival parked in the tenth hole: complete');
ok(!with(10, map { $_ => 0 } @home0[0 .. 8])->home_complete(0), 'nine home and the tenth hole empty: not');
ok(!with(10, map { $_ => 1 } @home0)->home_complete(0), 'the home full of a rival\'s pieces and none of its own: not');
ok(with(10, $home0[0] => 0, map { $_ => 1 } @home0[1 .. 9])->home_complete(0),
    'one of its own and nine rivals: complete, by the rule as written');
ok(!with(10, map { $_ => 0 } @home0)->home_complete(1), 'and that is seat 0\'s home, not seat 1\'s');

{
    my @front = $E->front(home_point(2, 0));
    ok(!with(15, map { $_ => 0 } @home0)->home_complete(0), 'fifteen pieces: the point alone is not home');
    ok(with(15, map { $_ => 0 } @home0, @front)->home_complete(0), '  the point and the five ring holes in front of it are');
}

# ---- complete is a fact about the position; finished is a fact about the game -----------

{
    my $bd = with(10, map { $_ => 0 } @home0);
    ok($bd->home_complete(0) && !$bd->finished(0), 'a board built home is complete and not yet counted');
    is($bd->place_of(0), 0, '  and has no place');
}

# ---- a seat is made home by a rival's move ---------------------------------------------
#
# Seat 0 has nine home and the tenth hole empty. It is seat 1's turn, and seat 1
# has a piece next to that hole. Seat 1 steps into it: seat 0's home is now full,
# one of the pieces its own, and seat 0 is home on seat 1's move.

{
    my ($bd, @gap) = near_home(2);
    my ($hole0, $ring0) = @{ $gap[0] };
    $bd->lift($ring0);
    $bd->put($ring0, 1);
    $bd->set_to_move(1);
    my ($why) = $bd->play($ring0, $hole0);
    is($why, PLAY_OK, 'seat 1 steps into the last hole of seat 0\'s home');
    ok($bd->finished(0), '  and seat 0 is home, on seat 1\'s move');
    ok($bd->over, '  which with two seats ends the game');
    is_deeply([ $bd->places ], [ 1, 2 ], '  seat 0 first');
    is($bd->how, BY_HOME, '  by home');
}

# ---- finishing is for good ------------------------------------------------------------

{
    my ($bd, @gap) = near_home(3);
    my $parked = $gap[0][0];
    $bd->put($parked, 1);
    $bd->lift($gap[1][1]);
    $bd->put($gap[1][1], 2);
    $bd->set_to_move(1);
    my ($m) = grep { $_->[0] != $parked } $bd->legal;
    $bd->play(@$m);
    ok($bd->finished(0), 'three seats: seat 0 home with a rival parked in its tenth hole');
    $bd->set_to_move(1) unless $bd->to_move == 1;
    my ($out) = grep { $_->[0] == $parked } $bd->legal;
    SKIP: {
        skip 'the parked piece has no way out on this board', 2 unless $out;
        $bd->play(@$out);
        ok(!$bd->home_complete(0), 'the parked piece leaves, and the home is not full');
        ok($bd->finished(0), '  but seat 0 stays home: finishing is for good');
    }
}

done_testing();
