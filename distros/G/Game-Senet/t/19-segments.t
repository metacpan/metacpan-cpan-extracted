use strict;
use warnings;
use Test::More;

use Game::Senet;

# THE TURN, plan_game_senet/06: a turn is a list of segments, each one throw
# and what was done with it. A roll of 1, 4 or 5 keeps the sticks, a 2 or 3
# passes them, and under skyruk a piece reaching 26 binds the next throw to it.
# Each script is worked out by hand; `turn` is checked at every step.

sub turn_is {
    my ($g, $side, $segment, $bound, $extra, $what) = @_;
    is_deeply($g->turn, { side => $side, segment => $segment, bound => $bound, extra => $extra }, $what);
}

subtest 'kendall: a 1 then a 2 gives light two segments, then dark' => sub {
    my $g = Game::Senet->new(script => [ 1, 2, 3 ]);
    turn_is($g, 'light', 1, undef, 1, 'light, first segment, a 1 in hand');
    $g->play_or_die('10-11');
    turn_is($g, 'light', 2, undef, 0, 'light again, second segment, a 2');
    $g->play_or_die('11-13');
    turn_is($g, 'dark', 1, undef, 0, 'then dark');
};

subtest 'a throw of 0 (a 5) and a 4 likewise' => sub {
    my $g = Game::Senet->new(script => [ 5, 4, 2 ]);
    turn_is($g, 'light', 1, undef, 1, 'a 5 in hand');
    $g->play_or_die('10-15');
    turn_is($g, 'light', 2, undef, 1, 'a 4 in hand');
    $g->play_or_die('15-19');
    turn_is($g, 'light', 3, undef, 0, 'a third segment');
    $g->play_or_die('19-21');
    is($g->side, 'dark', 'and the 2 passes');
};

subtest 'a forfeit on a 1 keeps the sticks (G3)' => sub {
    my $g = Game::Senet->new(script => [ 1, 3, 3 ], position => 'd........./........../.......l.. l 5');
    turn_is($g, 'light', 2, undef, 0, 'light on 28 forfeited the 1 and holds the 3, its second segment');
    $g->play_or_die('28-off');
};

subtest 'a backward move on a 4 keeps them' => sub {
    my $g = Game::Senet->new(script => [ 4, 3 ], position => '........../.........d/.l.l.d.... l 5');
    is_deeply([ map { $_->trace } $g->legal ], [ '22<18', '24<20x' ], 'only backward moves');
    $g->play_or_die('24-20');
    turn_is($g, 'light', 2, undef, 0, 'light throws again');
};

subtest 'bearing off with a 1 keeps them (G14)' => sub {
    my $g = Game::Senet->new(script => [ 1, 2 ], position => 'd........./........../.l.......l l 5');
    $g->play_or_die('30-off');
    turn_is($g, 'light', 2, undef, 0, 'light throws again');
};

subtest 'the last piece off on a 1 ends the game, with no throw after' => sub {
    my $g = Game::Senet->new(script => [ 1, 3, 3 ], position => 'd........./........../.........l l 5');
    $g->play_or_die('30-off');
    ok($g->is_over, 'over');
    is($g->result->winner, 'light', 'light wins');
    is($g->throws, 1, 'one throw made, though the 1 would give another');
    is($g->turn, undef, 'and there is no turn');
};

subtest 'skyruk: a piece reaching 26 binds the next segment to it' => sub {
    my $g = Game::Senet->new(script => [ 2, 3, 1 ], rules => 'skyruk', position => 'd........./........../.l.l...... l 5');
    is_deeply([ map { $_->trace } $g->legal ], [ '24>26' ], 'on a 2 only 24 moves: 22>24 is own');
    $g->play_or_die('24-26');
    turn_is($g, 'light', 2, 26, 0, 'light again, though a 2: bound to 26');
    is_deeply([ map { $_->trace } $g->legal ], [ '26>29' ], 'the bound throw offers 26 alone, not 22>25');
    $g->play_or_die('26-29');
    turn_is($g, 'dark', 1, undef, 1, 'the bound throw\'s own 3 passes the turn');
};

subtest 'skyruk: reaching 26 on a 1 earns ONE throw, not two' => sub {
    my $g = Game::Senet->new(script => [ 1, 2, 4 ], rules => 'skyruk', position => 'd........./........../.l..l..... l 5');
    $g->play_or_die('25-26');
    turn_is($g, 'light', 2, 26, 0, 'one throw, bound, a 2');
    $g->play_or_die('26-28');
    is($g->side, 'dark', 'and its 2 passes: had the 1 earned a second throw, light would throw again');
};

subtest 'kendall: a piece reaching 26 binds nothing' => sub {
    my $g = Game::Senet->new(script => [ 2, 3 ], position => 'd........./........../...l...... l 5');
    $g->play_or_die('24-26');
    turn_is($g, 'dark', 1, undef, 0, 'the 2 passes, and nothing is bound');
};

subtest 'undo restores the binding' => sub {
    my $g = Game::Senet->new(script => [ 2, 3, 1 ], rules => 'skyruk', position => 'd........./........../.l.l...... l 5');
    $g->play_or_die('24-26');
    $g->play_or_die('26-29');
    ok($g->undo, 'undo the bound move');
    turn_is($g, 'light', 2, 26, 0, 'bound again, the same throw in hand');
};

subtest 'the ply cap draws, through the facade' => sub {
    my $g = Game::Senet->new(script => [ (1) x 10_001 ], position => '........d./........../.......l.. l 5');
    ok($g->is_over, 'light on 28 throws a 1 for ever, and the game settles every forfeit itself');
    my $r = eval { $g->result };
    ok($r, 'there is a result') or diag($@);
    is($r && $r->how, 'ply_cap', 'at the ply cap');
    ok($r && $r->is_draw, 'a draw');
    is($r && $r->winner, undef, 'with no winner, whoever is ahead');
    is($g->ply, Game::Senet::Engine->new->ply_cap, 'after exactly the cap');
};

done_testing();
