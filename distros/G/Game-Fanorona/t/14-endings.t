use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use Game::Fanorona::Rules ':all';
use FnT qw(sq name text texts mtext mtexts);
my $R = 'Game::Fanorona::Rules';

sub game {
    my ($position, %limit) = @_;
    return $R->new(position => $position, (%limit ? (variant => \%limit) : ()));
}

# play moves given as text, each of which must be one of the game's moves
sub play {
    my ($game, @moves) = @_;
    for my $want (@moves) {
        my ($move) = grep { mtext($_) eq $want } $game->moves;
        die "$want is not a move of " . $game->position . ' (' . mtexts($game->moves) . ')' unless $move;
        $game->play_move($move) or die "$want was refused";
    }
    return $game;
}

subtest 'a new game' => sub {
    my $g = $R->new;
    is($g->position, 'bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w', 'the set-up');
    ok(!$g->over, 'not over');
    is($g->outcome, ONGOING, 'ongoing');
    is($g->how, undef, 'and how is undef');
    is($g->winner, 0, 'nobody has won');
    ok(!$g->is_draw, 'nor drawn');
    is($g->ply, 0, 'no move made');
    is($g->quiet, 0, 'no quiet move');
    is($g->depth, 0, 'nothing to take back');
    is($g->repeats, 1, 'the position has occurred once');
    is($g->side, WHITE, 'White to move');
    is(scalar($g->steps), 5, 'five steps');
    is(scalar($g->moves), 5, 'five moves');
    is_deeply([ $g->quiet_limit, $g->repeat, $g->ply_cap ], [ 60, 3, 3000 ], 'the limits are 60, 3 and 3,000');
    is_deeply([ $g->history ], [ $g->key_hex ], 'the history is the one position');
    is($g->key_at(0), $g->key_hex, 'key_at(0) is it');
    is($g->key_at(1), undef, 'and there is no key for a move not made');
    is($g->undo, 0, 'undo with nothing to undo is false');
    is($g->undo_move, 0, 'and so is undo_move');
    is($R->new(board => 'telo')->position, 'bbb/w1b/www w', 'a game on a named board');
};

# "The game ends when one player captures all stones of the opponent."
subtest 'the last stone' => sub {
    my $g = game('9/9/w1b6/9/9 w');
    play($g, 'a3-b3Axc3');
    ok($g->over, 'the game is over');
    is($g->outcome, BY_STONES, 'by stones');
    is($g->how, 'stones', 'how says stones');
    is($g->winner, WHITE, 'White has won');
    ok(!$g->is_draw, 'it is not a draw');
    is($g->ply, 1, 'in one move');
    is(scalar($g->steps), 0, 'no steps are offered once it is over');
    is(scalar(my @none = $g->moves), 0, 'and no moves');
    ok(!$g->can_stop, 'nor a stop');

    # A CHAIN THAT TAKES THE LAST STONE ENDS THE GAME WHERE IT STANDS
    my $chain = game('9/2b6/9/1w1b5/9 w');
    ok($chain->step(sq('b2'), E, APPROACH), 'b2-c2 takes d2');
    ok(!$chain->over, 'one black stone is left: not over, and the move is not complete');
    is($chain->ply, 0, 'no move has been counted yet');
    ok($chain->step(sq('c2'), N, APPROACH), 'c2-c3 takes c4');
    ok($chain->over, 'the last stone is gone and the game is over');
    is($chain->winner, WHITE, 'White has won');
    is($chain->ply, 1, 'and it was one move');
    ok(!$chain->in_chain, 'with no chain left open');
};

# "a player who is not able to move forfeits the game"
subtest 'a side with stones and no move' => sub {
    #  3  b b .       Black plays b3-b2, a paika. Then a1 has a stone on each
    #  2  b . .       of its three lines and nowhere to go.
    #  1  w b b
    my $g = game('9/9/bb7/b8/wbb6 b');
    is(mtexts(grep { mtext($_) eq 'b3-b2' } $g->moves), 'b3-b2', 'b3-b2 is a move for Black');
    play($g, 'b3-b2');
    ok($g->over, 'the game is over');
    is($g->outcome, BY_NO_MOVES, 'by no moves');
    is($g->how, 'no_moves', 'how says no_moves');
    is($g->winner, BLACK, 'and BLACK HAS WON: the side that cannot move has lost, not drawn');
    is($g->count(WHITE), 1, 'though White still has its stone');
    is($g->side, WHITE, 'and it is White who could not move');

    my $start = game('9/9/9/bb7/wb7 w');
    ok($start->over, 'a game begun in such a position is over before a step');
    is($start->how, 'no_moves', 'by no moves');
    is($start->winner, BLACK, 'won by the side not to move');

    my $other = game('9/9/9/ww7/bw7 b');
    is($other->winner, WHITE, 'and the same for Black stuck');
};

subtest 'a game begun with a side stoneless' => sub {
    my $none = game('9/9/4w4/9/9 b');
    ok($none->over, 'Black to move with no stones: over');
    is($none->how, 'stones', 'by stones');
    is($none->winner, WHITE, 'White has won');
    my $theirs = game('9/9/4w4/9/9 w');
    ok($theirs->over, 'White to move against no stones: over as well');
    is($theirs->winner, WHITE, 'and White has won that too');
    is(scalar($theirs->steps), 0, 'no step is offered');
};

# "In practice this is achieved by repetition of the same position with the
# same player to move."
subtest 'the third time, and not the second' => sub {
    #  two stones far apart, each stepping out and back
    my $g = game('8b/9/9/9/w8 w');
    my @round = ('a1-a2', 'i5-i4', 'a2-a1', 'i4-i5');
    play($g, @round);
    is($g->repeats, 2, 'after one round the first position has occurred twice');
    ok(!$g->over, 'and the game goes on');
    play($g, @round[0 .. 2]);
    ok(!$g->over, 'one move short of the third time, it still goes on');
    play($g, $round[3]);
    is($g->repeats, 3, 'the third time');
    ok($g->over, 'and the game is over');
    is($g->outcome, DRAW_REPETITION, 'drawn by repetition');
    is($g->how, 'repetition', 'how says so');
    is($g->winner, 0, 'nobody has won');
    ok($g->is_draw, 'it is a draw');
    is($g->ply, 8, 'after eight moves');

    # THE SAME STONES WITH THE OTHER SIDE TO MOVE IS ANOTHER POSITION
    my $side = game('8b/9/9/9/w8 w');
    play($side, 'a1-a2', 'i5-i4', 'a2-a1');
    is($side->repeats, 1, 'the stones are back on a1 and i4 for the first time');
    play($side, 'i4-h4', 'a1-b1', 'h4-i4', 'b1-a1');
    is($side->repeats, 2, 'a1 and i4 again with Black to move: twice');

    my $twice = game('8b/9/9/9/w8 w', repeat => 2);
    play($twice, @round);
    is($twice->how, 'repetition', 'with repeat at 2, the second time draws');
    my $never = game('8b/9/9/9/w8 w', repeat => 0, quiet_limit => 0);
    play($never, (@round) x 6);
    ok(!$never->over, 'with repetition and the quiet limit off, six rounds are not a draw');
    is($never->repeats, 7, 'though the position has occurred seven times');
};

subtest 'the quiet limit' => sub {
    my $g = game('8b/9/9/9/w8 w', quiet_limit => 5, repeat => 0);
    play($g, 'a1-a2', 'i5-i4', 'a2-a3', 'i4-i3');
    is($g->quiet, 4, 'four quiet moves');
    ok(!$g->over, 'and the game goes on');
    play($g, 'a3-a4');
    is($g->quiet, 5, 'the fifth');
    ok($g->over, 'and it is over');
    is($g->outcome, DRAW_QUIET, 'drawn by the quiet limit');
    is($g->how, 'quiet', 'how says quiet');
    ok($g->is_draw, 'a draw');

    # A CAPTURE STARTS THE COUNT AGAIN
    #  3  w b . . . . . . .     a3 has its back to the edge and cannot get away
    #  1  . . . . . . . . w     from b3; b3 can withdraw to c3 and take it. So
    #                           White makes a quiet move, and Black must take.
    my $reset = game('8b/9/wb7/9/8w w', quiet_limit => 5, repeat => 0);
    play($reset, 'i1-h1');
    is($reset->quiet, 1, 'one quiet move');
    play($reset, 'b3-c3Wxa3');
    is($reset->quiet, 0, 'a move that takes sets the count to nothing');
    play($reset, 'h1-g1', 'i5-i4', 'g1-f1', 'i4-i5');
    is($reset->quiet, 4, 'four quiet moves since');
    ok(!$reset->over, 'five quiet moves have been made in all, and the game goes on');
    play($reset, 'f1-e1');
    is($reset->how, 'quiet', 'the fifth since the capture ends it');

    # IT COUNTS MOVES, NOT STEPS: a chain of two steps is one move that took
    my $chain = game('9/2b6/9/1w1b5/8b w', quiet_limit => 5, repeat => 0);
    play($chain, 'b2-c2Axd2-c3Axc4');
    is($chain->ply, 1, 'a chain of two steps is one move');
    is($chain->quiet, 0, 'and not a quiet one');
};

subtest 'the cap' => sub {
    my $g = game('8b/9/9/9/w8 w', quiet_limit => 0, repeat => 0, ply_cap => 6);
    play($g, 'a1-a2', 'i5-i4', 'a2-a3', 'i4-i3', 'a3-a4');
    ok(!$g->over, 'five moves of six');
    play($g, 'i3-i2');
    is($g->outcome, DRAW_PLY_CAP, 'the sixth is the cap');
    is($g->how, 'ply_cap', 'how says ply_cap');
    ok($g->is_draw, 'a draw');
    is($g->ply_cap, 6, 'the cap this game was made with');

    # A DRAWN GAME OFFERS NOTHING, though both sides have stones and room: the
    # board underneath would still list steps, and the game does not.
    is(scalar($g->steps), 0, 'no step is offered once the game is drawn');
    is(scalar(my @none = $g->moves), 0, 'and no move');
    ok(!$g->can_stop, 'nor a stop');
    my ($under) = Game::Fanorona::Engine->of_string($g->position);
    cmp_ok(scalar($under->play_steps), '>', 0, 'though the same stones on a bare board have steps to make');
};

# one move can satisfy two: the win it made is asked first
subtest 'the order they are asked in' => sub {
    my $g = game('9/9/w1b6/9/9 w', ply_cap => 1, quiet_limit => 1);
    play($g, 'a3-b3Axc3');
    is($g->how, 'stones', 'a move that wins on the move the cap is reached has won');
    my $q = game('8b/9/9/9/w8 w', quiet_limit => 4, repeat => 2, ply_cap => 4);
    play($q, 'a1-a2', 'i5-i4', 'a2-a1', 'i4-i5');
    is($q->how, 'repetition', 'repetition is asked before the quiet limit, and both before the cap');
};

subtest 'a step the game refuses' => sub {
    my $g = $R->new;
    my $before = $g->position;
    ok(!$g->step(sq('a1'), N, PAIKA), 'a1-a2 is refused: a2 is occupied');
    is($g->refused, PLAY_ILLEGAL, 'refused as illegal');
    is($g->why, WHY_OCCUPIED, 'and why: occupied');
    ok(!$g->step(sq('d3'), E, PAIKA), 'd3-e3 as a paika is refused');
    is($g->why, WHY_NOT_A_PAIKA, 'because it takes');
    ok(!$g->step(sq('f3'), W, APPROACH), 'Black\'s stone is refused');
    is($g->why, WHY_NOT_YOURS, 'as not the mover\'s');
    ok(!$g->stop, 'a stop with no chain open is refused');
    is($g->refused, PLAY_ILLEGAL, 'as illegal');
    is($g->position, $before, 'and none of it changed the position');
    is($g->ply, 0, 'or counted a move');
    is($g->depth, 0, 'or left anything to take back');

    ok($g->step({ from => sq('d3'), dir => E, kind => APPROACH }), 'a legal step, given as a hash, is made');
    is($g->refused, PLAY_OK, 'refused is PLAY_OK after it');
    is($g->why, 0, 'and why is 0');

    my $over = game('9/9/w1b6/9/9 w');
    play($over, 'a3-b3Axc3');
    ok(!$over->step(sq('b3'), E, PAIKA), 'a step after the end is refused');
    is($over->refused, PLAY_OVER, 'because the game is over');
    ok(!$over->stop, 'and so is a stop');
    is($over->refused, PLAY_OVER, 'for the same reason');
    is($over->play_move(($R->new->moves)[0]), 0, 'and a whole move');

    # in a chain, the refusals of a chain
    my $chain = game('9/2b6/9/1w1b5/8b w');
    $chain->step(sq('b2'), E, APPROACH);
    ok(!$chain->step(sq('c2'), E, APPROACH), 'the same direction again is refused');
    is($chain->why, WHY_SAME_DIRECTION, 'and says so');
    ok(!$chain->step(sq('c2'), W, WITHDRAWAL), 'the way back is refused');
    is($chain->why, WHY_REVISIT, 'and says so');
    ok($chain->in_chain, 'the chain is still open after two refusals');
    is(scalar(my @none = $chain->moves), 0, 'moves lists nothing in the middle of one');
    is($chain->play_move(($R->new->moves)[0]), 0, 'and play_move plays nothing');
    ok($chain->stop, 'a stop is accepted');
    is($chain->side, BLACK, 'and the turn passes');
};

subtest 'a move that is refused part way leaves nothing behind' => sub {
    #  a legal first step, then a second that is not: the first is taken back
    my $g = game('9/2b6/9/1w1b5/8b w');
    my $bad = Game::Fanorona::Move->new(from => sq('b2'), steps => [
        { from => sq('b2'), to => sq('c2'), dir => E, kind => APPROACH, taken => [ sq('d2') ] },
        { from => sq('c2'), to => sq('d2'), dir => E, kind => APPROACH, taken => [] },
    ]);
    is($g->play_move($bad), 0, 'refused');
    is($g->refused, PLAY_ILLEGAL, 'as illegal');
    is($g->why, WHY_SAME_DIRECTION, 'for the second step\'s reason');
    is($g->position, '9/2b6/9/1w1b5/8b w', 'and the first step was taken back');
    is($g->depth, 0, 'with nothing left on the stack');
};

subtest 'undo' => sub {
    my $g = game('8b/9/9/9/w8 w', quiet_limit => 3, repeat => 0);
    play($g, 'a1-a2', 'i5-i4');
    my @before = ($g->position, $g->ply, $g->quiet, $g->outcome, $g->depth);
    play($g, 'a2-a3');
    ok($g->over, 'the third quiet move ends it');
    ok($g->undo, 'undo takes it back');
    is_deeply([ $g->position, $g->ply, $g->quiet, $g->outcome, $g->depth ], \@before,
        'position, ply, quiet count, outcome and depth are as they were');
    ok(!$g->over, 'and the game is on again');
    is(scalar($g->history), 3, 'the history is three positions long');

    # a chain: three entries on the stack for one move
    my $c = game('9/2b6/9/1w1b5/8b w');
    my $start = $c->position;
    $c->step(sq('b2'), E, APPROACH);
    $c->stop;
    is($c->depth, 2, 'a step and a stop are two things to take back');
    is($c->ply, 1, 'and one move');
    ok($c->undo, 'undo takes back the stop');
    ok($c->in_chain, 'and the chain is open again');
    is($c->ply, 0, 'with the move uncounted');
    ok($c->undo, 'undo again takes back the step');
    is($c->position, $start, 'and the position is the start');

    # UNDO A STOP AND STOP AGAIN. The move took a stone, so it is not a quiet
    # one, the second time as the first: undo has to put back that the move in
    # progress had taken, or the second stop counts it as quiet.
    my $again = game('9/2b6/9/1w1b5/8b w');
    $again->step(sq('b2'), E, APPROACH);
    $again->stop;
    is($again->quiet, 0, 'a move that took and stopped is not quiet');
    $again->undo;
    $again->stop;
    is($again->quiet, 0, 'nor is it after the stop is undone and made again');
    is($again->ply, 1, 'and it is still one move');

    # and the other way: undo a quiet move, make it again, and it is counted once
    my $quietly = game('8b/9/9/9/w8 w');
    play($quietly, 'a1-a2');
    $quietly->undo;
    play($quietly, 'a1-a2');
    is($quietly->quiet, 1, 'a quiet move undone and made again is one quiet move');

    # undo_move
    play($c, 'b2-c2Axd2-c3Axc4', 'i1-i2');
    is($c->ply, 2, 'two moves');
    ok($c->undo_move, 'undo_move');
    is($c->ply, 1, 'takes back the last whole move');
    ok($c->undo_move, 'and again');
    is($c->position, $start, 'takes back the chain of two steps whole');
    $c->step(sq('b2'), E, APPROACH);
    ok($c->undo_move, 'with a chain open, undo_move takes back the move in progress');
    is($c->position, $start, 'to the start');
    ok(!$c->in_chain, 'with no chain open');
};

subtest 'a clone is its own game' => sub {
    my $before = $R->live;
    {
        my $g = $R->new;
        play($g, 'd3-e3Axf3');
        my $copy = $g->clone;
        is($R->live, $before + 2, 'two games');
        is($copy->position, $g->position, 'the clone has the position');
        is($copy->ply, 1, 'the ply');
        is_deeply([ $copy->history ], [ $g->history ], 'and the history');
        play($copy, 'c3-d3Axe3');
        is($g->ply, 1, 'a move in the clone does not reach the original');
        ok($copy->undo && $copy->undo, 'the clone can take back the move made before it was cloned');
        is($copy->position, $R->new->position, 'down to the set-up');
        is($g->ply, 1, 'and still the original has not moved');

        my $limited = game('8b/9/9/9/w8 w', quiet_limit => 7, repeat => 2, ply_cap => 50)->clone;
        is_deeply([ $limited->quiet_limit, $limited->repeat, $limited->ply_cap ], [ 7, 2, 50 ], 'a clone keeps its limits');
    }
    is($R->live, $before, 'and every game is dropped when it goes out of scope');
};

subtest 'what new refuses' => sub {
    my $before = $R->live;
    ok(!eval { $R->new(position => '9/9/9/9 w'); 1 }, 'a position that will not load');
    like($@, qr/the position was refused/, 'saying so');
    ok(!eval { $R->new(board => 'grande'); 1 }, 'a board that is not one');
    like($@, qr/no board is called 'grande'/, 'naming it');
    ok(!eval { $R->new(board => 'telo', position => 'bbb/w1b/www w'); 1 }, 'a board and a position together');
    ok(!eval { $R->new(variant => { quiet => 5 }); 1 }, 'a limit that is not one');
    like($@, qr/no limit is called 'quiet'/, 'naming it');
    ok(!eval { $R->new(variant => { quiet_limit => -1 }); 1 }, 'a limit below nothing');
    ok(!eval { $R->new(variant => { repeat => 'x' }); 1 }, 'a limit that is not a number');
    ok(!eval { $R->new(variant => [ 5 ]); 1 }, 'a variant that is not a hash');
    ok(!eval { $R->new(_ptr => 12345); 1 }, 'an address');
    like($@, qr/a game is made by new or clone/, 'saying how a game is made');
    is($R->live, $before, 'and nothing refused left a game behind');
    is($R->new(variant => { repeat => 1 })->repeat, 2, 'a repeat of 1 would draw every game at its first position, and means 2');
    is($R->new(variant => { ply_cap => 0 })->ply_cap, 3000, 'a cap of 0 is the default: it cannot be turned off');
};

is_deeply([ ONGOING, BY_STONES, BY_NO_MOVES, DRAW_REPETITION, DRAW_QUIET, DRAW_PLY_CAP ], [ 0 .. 5 ],
    'the outcomes are 0 to 5 in the order they are asked');
is_deeply([ PLAY_OK, PLAY_OVER, PLAY_ILLEGAL ], [ 0 .. 2 ], 'and the answers 0 to 2');

done_testing();
