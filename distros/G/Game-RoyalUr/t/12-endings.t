use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Engine ':all';
use Game::RoyalUr::Rules;
my $E = 'Game::RoyalUr::Engine';
my $R = 'Game::RoyalUr::Rules';

sub move_from {
    my ($game, $roll, $from) = @_;
    my ($move) = grep { $_->from eq $from } $game->moves($roll);
    die "no move from $from on a roll of $roll" unless $move;
    return $move;
}

subtest 'a game that is going' => sub {
    my $game = $R->new;
    is($game->status, 'ongoing', 'the start is ongoing');
    ok(!$game->is_over, 'not over');
    is($game->how, undef, 'no way it ended');
    is($game->winner, undef, 'and no winner');

    my $bd = $E->new;
    is($bd->status, ONGOING, 'the engine says ONGOING');
    is($bd->how, 0, 'and 0');
    is($bd->winner, -1, 'and -1');
};

# THE MOVE THAT BRINGS THE LAST PIECE HOME ENDS THE GAME, on that move, whatever
# the other side has left.
subtest 'the last piece home' => sub {
    my $game = $R->new(position => '4xx2/1d1d4/4xxl1 l 0 6 4 1');
    is($game->status, 'ongoing', 'six home and one on the board is not a win');
    $game->apply(move_from($game, 1, 'g1'));
    is($game->status, 'won', 'the seventh home is');
    is($game->winner, 'light', 'light wins');
    is($game->how, 'home', 'by home');
    ok($game->is_over, 'the game is over');
    is($game->home('dark'), 1, 'with dark one home and pieces all over the board');

    my $dark = $R->new(position => '4xxd1/8/l3xx2 d 5 0 0 6');
    $dark->apply(move_from($dark, 1, 'g3'));
    is($dark->winner, 'dark', 'and dark can win too');
};

subtest 'what is not a win' => sub {
    is($R->new(position => '4xx2/8/4xx2 l 1 6 7 0')->status, 'ongoing', 'six home and one in HAND');
    is($R->new(position => '4xx2/8/4xx2 l 0 6 0 6')->status, 'ongoing',
        'six home each and nothing on the board or in hand: not consistent, and nobody has seven');
    is($R->new(position => '4xx2/8/4xx2 d 7 0 0 0')->status, 'ongoing',
        'A SIDE WITH NOTHING ON THE BOARD has not lost: dark has no piece anywhere and light has not won');
    is($R->new(position => '4xx2/8/4xx2 l 7 0 7 0')->winner, undef, 'nor has anybody at the start');
};

subtest 'the number of pieces is the rule set\'s' => sub {
    my $three = $R->new(rules => { pieces => 3 }, position => '4xx2/8/4xxl1 l 0 2 3 0');
    is($three->status, 'ongoing', 'two of three home');
    $three->apply(move_from($three, 1, 'g1'));
    is($three->status, 'won', 'three of three is a win at three a side');

    my $seven = $R->new(position => '4xx2/8/4xxl1 l 0 2 3 0');
    $seven->apply(move_from($seven, 1, 'g1'));
    is($seven->status, 'ongoing', 'and the same three home is nothing at seven a side');
};

subtest 'once it is over' => sub {
    my $game = $R->new(position => '4xx2/1d1d4/4xxl1 l 0 6 4 1');
    $game->apply(move_from($game, 1, 'g1'));
    my $position = $game->position;
    is(scalar($game->moves($_)), 0, "a roll of $_ allows nothing") for 1 .. 4;
    is_deeply([ $game->moves(2) ], [], 'in list context too');
    ok(!$game->forfeit, 'there is no turn to lose');
    is($game->position, $position, 'and nothing has changed');

    my $late = $R->new(position => '4xx2/1d1d4/4xx2 d 0 7 4 1');
    is($late->status, 'won', 'a position read in already won');
    my ($stale) = $R->new(position => '4xx2/1d1d4/4xx2 d 0 6 4 1')->moves(1);
    ok($stale, 'a dark move made for the same board while it was still going');
    is($late->apply($stale), undef, 'is refused once it is over');
    is($late->position, '4xx2/1d1d4/4xx2 d 0 7 4 1', 'and the board has not moved');

    ok($game->undo, 'but the winning move can be taken back');
    is($game->status, 'ongoing', 'and then the game is going again');
};

subtest 'a move for the side not to move is refused' => sub {
    my $game = $R->new(position => '1d2xx2/3l4/4xx2 l 6 0 6 0');
    my ($dark) = $R->new(position => '1d2xx2/3l4/4xx2 d 6 0 6 0')->moves(1);
    is($dark->side, 'dark', 'a dark move');
    is($game->apply($dark), undef, 'is not made while light is to move');
    is($game->position, '1d2xx2/3l4/4xx2 l 6 0 6 0', 'and nothing changed');
    ok(!eval { $game->apply('d2-e2'); 1 }, 'and apply takes a move, not a string');
};

# NO TEST PLAYS A GAME THIS LONG. The position is built one ply short of the
# cap, from the cap itself, so this file does not say what the number is.
subtest 'the ply cap' => sub {
    my $cap = $E->ply_cap;
    cmp_ok($cap, '>', 100, "there is a cap, and it is $cap");

    my $game = $R->new(ply => $cap - 1);
    is($game->status, 'ongoing', 'one ply short of the cap the game is going');
    ok(scalar($game->moves(1)), 'and there are moves');
    $game->forfeit;
    is($game->ply, $cap, 'A FORFEIT IS A PLY, and this one reaches the cap');
    is($game->status, 'drawn', 'the game is drawn');
    is($game->how, 'ply_cap', 'by the cap');
    is($game->winner, undef, 'NOBODY WINS, whoever has more home');
    ok($game->is_over, 'and it is over');
    is(scalar($game->moves(1)), 0, 'with no more moves');

    my $ahead = $R->new(position => '4xx2/8/4xx2 l 1 6 7 0', ply => $cap - 1);
    $ahead->apply(move_from($ahead, 1, 'hand'));
    is($ahead->status, 'drawn', 'a side six home to none is still only drawn at the cap');
    is($ahead->winner, undef, 'and has not won');

    my $last = $R->new(position => '4xx2/8/4xxl1 l 0 6 7 0', ply => $cap - 1);
    $last->apply(move_from($last, 1, 'g1'));
    is($last->status, 'won', 'but the last piece home ON the capping ply is a win: home is asked first');
    is($last->how, 'home', 'by home');

    my $bd = $E->new->set_ply($cap);
    is($bd->status, DRAWN, 'the engine says DRAWN');
    is($bd->how, BY_PLY_CAP, 'BY_PLY_CAP');
    is($bd->winner, -1, 'and -1');
    is($E->new->set_ply($cap - 1)->status, ONGOING, 'and ONGOING one short');
};

done_testing();
