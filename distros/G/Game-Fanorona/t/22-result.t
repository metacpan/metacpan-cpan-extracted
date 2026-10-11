use strict;
use warnings;
use Test::More;

use Game::Fanorona::Result;
my $R = 'Game::Fanorona::Result';

is_deeply([ $R->ways ], [ qw(no_moves resign stones agreement ply_cap quiet repetition) ],
    'seven ways a game ends: three with a winner, then four without');

for my $how (qw(stones no_moves resign)) {
    for my $winner (qw(white black)) {
        my $r = $R->new(how => $how, winner => $winner, position => '9/9/4w4/9/9 b', moves => 31);
        is($r->how, $how, "$how: how");
        is($r->winner, $winner, "$how: won by $winner");
        is($r->loser, $winner eq 'white' ? 'black' : 'white', "$how: lost by the other");
        ok(!$r->is_draw, "$how: not a draw");
        is($r->position, '9/9/4w4/9/9 b', "$how: the position");
        is($r->moves, 31, "$how: the moves");
    }
    ok(!eval { $R->new(how => $how); 1 }, "$how with no winner croaks");
    like($@, qr/has a winner, white or black/, 'saying it has one');
    ok(!eval { $R->new(how => $how, winner => 'red'); 1 }, "$how won by a side that is not one croaks");
}

for my $how (qw(repetition quiet ply_cap agreement)) {
    my $r = $R->new(how => $how, position => '9/9/4w4/9/8b w');
    is($r->how, $how, "$how: how");
    is($r->winner, undef, "$how: nobody won");
    is($r->loser, undef, "$how: nobody lost");
    ok($r->is_draw, "$how: a draw");
    is($r->moves, 0, "$how: moves is 0 when not given");
    ok(!eval { $R->new(how => $how, winner => 'white'); 1 }, "$how with a winner croaks");
    like($@, qr/has no winner/, 'saying it has none');
}

ok(!eval { $R->new(how => 'boredom', winner => 'white'); 1 }, 'a way that is not one croaks');
like($@, qr/'boredom' is not a way a game ends/, 'naming it');
ok(!eval { $R->new(winner => 'white'); 1 }, 'and so does no way at all');

done_testing();
