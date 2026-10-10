use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Rules;
my $R = 'Game::RoyalUr::Rules';

=pod

SCRIPTED GAMES. Each is a list of turns: the roll, the place the piece to move
starts from (or nothing, for a turn the roll loses), and THE WHOLE POSITION
EXPECTED AFTERWARDS, typed out by hand from the routes.

The class under test is handed every roll, so a script needs no seed that
happens to throw them.

=cut

sub play {
    my ($name, $game, @script) = @_;
    subtest $name => sub {
        my $ply = $game->ply;
        for my $turn (@script) {
            my ($side, $roll, $from, $want) = @$turn;
            is($game->side, $side, "ply $ply: $side to move");
            my @moves = $game->moves($roll);
            if (defined $from) {
                my ($move) = grep { $_->from eq $from } @moves;
                ok($move, "a roll of $roll moves the piece on $from") or return;
                is($game->apply($move), $move, 'and apply returns the move');
            }
            else {
                is(scalar @moves, 0, "a roll of $roll allows nothing");
                ok($game->forfeit, 'so the turn is lost');
            }
            $ply++;
            is($game->position, $want, 'the position afterwards');
            is($game->ply, $ply, "and it is ply $ply");
        }
    };
    return $game;
}

# ---- finkel ------------------------------------------------------------------

# Three rosettes in a row, and then a roll of nothing straight after the last
# one: an extra roll that allows no move is a turn lost like any other.
my $chain = play('finkel: three extra rolls, then a forfeit directly after one',
    $R->new(rules => 'finkel'),
    [ 'light', 4, 'hand', '4xx2/8/l3xx2 l 6 0 7 0' ],
    [ 'light', 4, 'a1',   '4xx2/3l4/4xx2 l 6 0 7 0' ],
    [ 'light', 4, 'hand', '4xx2/3l4/l3xx2 l 5 0 7 0' ],
    [ 'light', 0, undef,  '4xx2/3l4/l3xx2 d 5 0 7 0' ],
    [ 'dark',  4, 'hand', 'd3xx2/3l4/l3xx2 d 5 0 6 0' ],
    [ 'dark',  4, undef,  'd3xx2/3l4/l3xx2 l 5 0 6 0' ],
);
is($chain->status, 'ongoing', 'and that game is still going');
is($chain->depth, 6, 'with six things to take back');

# The last line above is the other way to lose a turn: dark rolled 4 with a
# piece to move and nowhere to put it. The hand would enter onto its own piece
# on a3, and a3 would land on a light piece on the safe rosette.

my $win = play('finkel: a capture, an entry, and the last piece home',
    $R->new(rules => 'finkel', position => '4xx2/5l1d/4xx2 l 0 6 0 6'),
    [ 'light', 2, 'f2',   '4xx2/7l/4xx2 d 0 6 1 6' ],
    [ 'dark',  3, 'hand', '1d2xx2/7l/4xx2 l 0 6 0 6' ],
    [ 'light', 3, 'h2',   '1d2xx2/8/4xx2 d 0 7 0 6' ],
);
is($win->status, 'won', 'that game is won');
is($win->winner, 'light', 'by light');
is($win->how, 'home', 'by bringing the last piece home');

play('finkel: a rosette, and then a roll with a piece to move and nowhere to put it',
    $R->new(rules => 'finkel', position => '4xx2/3d4/1l2xx2 l 0 6 6 0'),
    [ 'light', 1, 'b1',  '4xx2/3d4/l3xx2 l 0 6 6 0' ],
    [ 'light', 4, undef, '4xx2/3d4/l3xx2 d 0 6 6 0' ],
);

# ---- masters -----------------------------------------------------------------

# Every fourth step of the long route is a rosette, so a piece rolled four
# every time goes the whole way round without the other side moving at all.
my $run = play('masters: the whole route on successive fours',
    $R->new(rules => 'masters'),
    [ 'light', 4, 'hand', '4xx2/8/l3xx2 l 6 0 7 0' ],
    [ 'light', 4, 'a1',   '4xx2/3l4/4xx2 l 6 0 7 0' ],
    [ 'light', 4, 'd2',   '4xxl1/8/4xx2 l 6 0 7 0' ],
    [ 'light', 4, 'g3',   '4xx2/8/4xxl1 l 6 0 7 0' ],
    [ 'light', 1, 'g1',   '4xx2/8/4xx2 d 6 1 7 0' ],
);
is($run->home('light'), 1, 'one light piece home');
is($run->hand('light'), 6, 'six still to enter');
is($run->side, 'dark', 'and only now is it dark to move');

my $far = play('masters: a capture on the far rosette, and the last piece home',
    $R->new(rules => 'masters', position => '4xxd1/6l1/4xx2 l 0 6 0 6'),
    [ 'light', 1, 'g2', '4xxl1/8/4xx2 l 0 6 1 6' ],
    [ 'light', 4, 'g3', '4xx2/8/4xxl1 l 0 6 1 6' ],
    [ 'light', 1, 'g1', '4xx2/8/4xx2 d 0 7 1 6' ],
);
is($far->status, 'won', 'that game is won');
is($far->winner, 'light', 'by light, without dark having moved');

# Masters cannot roll nothing, so the only way to lose a turn is to be blocked.
# Light lands on a1 and rolls four: every piece it has would land on another
# of its own, and the one on g1 would overshoot.
play('masters: a rosette, and then every piece blocked by its own side',
    $R->new(rules => 'masters', position => '4xxl1/3l4/1l2xxl1 l 3 0 7 0'),
    [ 'light', 1, 'b1',  '4xxl1/3l4/l3xxl1 l 3 0 7 0' ],
    [ 'light', 4, undef, '4xxl1/3l4/l3xxl1 d 3 0 7 0' ],
);

# ---- taking it back ------------------------------------------------------------

subtest 'undo walks a whole game back to its start' => sub {
    my $game = $R->new(rules => 'finkel');
    my @positions = ($game->position);
    for my $turn ([ 4, 'hand' ], [ 4, 'a1' ], [ 4, 'hand' ], [ 0 ], [ 4, 'hand' ], [ 4 ]) {
        my ($roll, $from) = @$turn;
        if (defined $from) {
            my ($move) = grep { $_->from eq $from } $game->moves($roll);
            $game->apply($move);
        }
        else { $game->forfeit }
        push @positions, $game->position;
    }
    is($game->position, 'd3xx2/3l4/l3xx2 l 5 0 6 0', 'the game played above, again');
    for my $n (reverse 0 .. $#positions - 1) {
        ok($game->undo, "undo back to ply $n");
        is($game->position, $positions[$n], 'the position it was');
        is($game->ply, $n, "and ply $n");
    }
    ok(!$game->undo, 'and then there is nothing left to take back');
    is($game->position, '4xx2/8/4xx2 l 7 0 7 0', 'which leaves the start');
};

subtest 'what new takes' => sub {
    is($R->new->rules->{route}, 'short', 'no rules is finkel');
    is($R->new(rules => 'masters')->rules->{dice}, 3, 'masters by name');
    is($R->new(rules => { pieces => 3 })->position, '4xx2/8/4xx2 l 3 0 3 0', 'three pieces a side start with three in hand');
    is($R->new(first => 'dark')->side, 'dark', 'first names the side to move');
    is($R->new(position => '4xx2/8/4xx2 d 7 0 7 0', first => 'light')->side, 'light', 'over the position');
    is($R->new(ply => 12)->ply, 12, 'and ply the count to start from');
    ok(!eval { $R->new(rules => 'bell'); 1 }, 'a rule set that is none croaks');
    ok(!eval { $R->new(first => 'white'); 1 }, 'so does a side that is neither');
    ok(!eval { $R->new(position => 'junk'); 1 }, 'a position that is none');
    ok(!eval { $R->new(ply => -1); 1 }, 'and a negative ply');

    my $game = $R->new(rules => 'masters');
    my $rules = $game->rules;
    $rules->{route} = 'short';
    is($game->rules->{route}, 'long', 'the rules handed out are a copy');
    my $board = $game->board;
    $board->set_side(1);
    is($game->side, 'light', 'and so is the board');
};

done_testing();
