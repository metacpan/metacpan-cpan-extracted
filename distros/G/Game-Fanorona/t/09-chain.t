use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use FnT qw(sq name text texts mtext mtexts board);
my $E = 'Game::Fanorona::Engine';

# EVERY POSITION HERE WAS WORKED OUT BY HAND, the whole list of moves written
# down before the engine was asked, and each names the sentence it is for.

# "it is allowed to continue capturing with the same piece" and "the player
# may stop capturing after any number of opponent pieces are captured"
subtest 'a chain of two, and the same chain stopped after one' => sub {
    #  4  . . b . .      b2 east to c2 approaches d2;
    #  3  . . . . .      then c2 north to c3 approaches c4.
    #  2  . w . b .
    my $bd = board('9/2b6/9/1w1b5/9 w');
    is(mtexts($bd->moves), 'b2-c2Axd2 b2-c2Axd2-c3Axc4', 'two moves: take one and stop, or take both');
    is($bd->count_moves, '2', 'count_moves agrees');
    ok(!$bd->in_chain, 'no chain is open before a step');
    is($bd->chain_at, -1, 'chain_at is -1');
    ok(!$bd->can_stop, 'and there is nothing to stop');
    is($bd->stop, undef, 'stop does nothing and returns nothing');

    my ($first) = $bd->play_steps;
    is(text($first), 'b2-c2Axd2', 'the one step to begin with');
    my ($t1, $removed) = $bd->play($first);
    is($removed, 1, 'it takes one stone');
    ok($bd->in_chain, 'and now a chain is open');
    is($bd->chain_at, sq('c2'), 'on the stone that moved');
    is($bd->chain_dir, E, 'which went east');
    is_deeply([ map { name($_) } $bd->chain_seen ], [ qw(b2 c2) ], 'it has stood on b2, where it began, and c2');
    is($bd->side, WHITE, 'THE TURN HAS NOT PASSED');
    ok($bd->can_stop, 'the mover may stop');
    is(texts($bd->play_steps), 'c2-c3Axc4', 'or go on, one way');

    # stopping
    my $ts = $bd->stop;
    ok(defined $ts, 'stop hands back a token');
    is($bd->side, BLACK, 'and the turn passes');
    ok(!$bd->in_chain, 'the chain is closed');
    is(scalar($bd->chain_seen), 0, 'and remembers nothing');
    is($bd->to_string, '9/2b6/9/2w6/9 b', 'c4 still stands: the mover chose to leave it');
    $bd->unplay($ts);
    ok($bd->in_chain, 'unplay opens the chain again');
    is($bd->chain_at, sq('c2'), 'on c2');
    is($bd->chain_dir, E, 'facing east');
    is_deeply([ map { name($_) } $bd->chain_seen ], [ qw(b2 c2) ], 'with the same two points behind it');
    is($bd->side, WHITE, 'and White to move');

    # going on
    my ($second) = $bd->play_steps;
    my $t2 = $bd->play($second);
    is($bd->to_string, '9/9/2w6/9/9 b', 'both stones are gone, the stone is on c3');
    ok(!$bd->in_chain, 'nothing is left to take, so THE CHAIN CLOSED ITSELF');
    is($bd->side, BLACK, 'and the turn passed without a stop');
    is($bd->key_hex, $bd->key_full_hex, 'the key kept up');

    $bd->unplay($t2)->unplay($t1);
    is($bd->to_string, '9/2b6/9/1w1b5/9 w', 'two unplays, and the position is as it began');
    ok(!$bd->in_chain, 'with no chain open');
};

# "It is not allowed to make a capturing move in the same direction as the
# capturing move directly before": the source's own example, f4-e4W-d4A.
subtest 'never twice running in the same direction' => sub {
    #  4  . . b . . w b . .     f4 west to e4 withdraws from g4. Going on west
    #  3  . . . . b . . . .     to d4 would approach c4, and may not. North to
    #                           e5 withdraws from e3, and may.
    my $bd = board('9/2b2wb2/4b4/9/9 w');
    is(mtexts($bd->moves), 'f4-e4Wxg4 f4-e4Wxg4-e5Wxe3 f4-g5Wxe3',
        'three moves, and none of them is f4-e4-d4');
    $bd->play(sq('f4'), W, WITHDRAWAL);
    ok($bd->in_chain, 'after f4-e4 the chain is open');
    is($bd->play_why(sq('e4'), W, APPROACH), WHY_SAME_DIRECTION, 'e4-d4 is refused: the same direction again');
    is($bd->step_why(sq('e4'), W, APPROACH), WHY_OK, 'though as a step on its own it would take c4');
    is($bd->play_why(sq('e4'), N, WITHDRAWAL), WHY_OK, 'e4-e5 is another direction, and is allowed');
    is(texts($bd->play_steps), 'e4-e5Wxe3', 'so it is the only step offered');
};

# "A player is allowed to play a capturing sequence two times into the same
# direction if a capturing movement in another direction is done in between."
subtest 'north, east, north' => sub {
    #  4  . b . .      a1 north to a2 approaches a3;
    #  3  b . . .      a2 east to b2 approaches c2;
    #  2  . . b .      b2 north to b3 approaches b4.
    #  1  w . . .
    my $bd = board('9/1b7/b8/2b6/w8 w');
    is(mtexts($bd->moves), 'a1-a2Axa3 a1-a2Axa3-b2Axc2 a1-a2Axa3-b2Axc2-b3Axb4',
        'three moves, the longest going north twice with east between');
    $bd->play(sq('a1'), N, APPROACH);
    $bd->play(sq('a2'), E, APPROACH);
    is($bd->chain_dir, E, 'the chain last went east');
    is($bd->play_why(sq('b2'), N, APPROACH), WHY_OK, 'so north is open again: the rule looks back one step and no further');
};

# "The current capturing piece is not allowed to arrive on the same
# intersection twice during a capturing sequence." The source's example,
# f4-e4W-e3A-f4W, returns to the point the chain began on.
subtest 'never the same point twice, the start included' => sub {
    #  4  . . . . . w b . .
    #  3  . . b . . . . . .
    #  2  . . . b b . . . .
    my $bd = board('9/5wb2/2b6/3bb4/9 w');
    is(mtexts($bd->moves), join(' ', sort qw(
        f4-e4Wxg4
        f4-e4Wxg4-e3Axe2
        f4-e4Wxg4-e3Axe2-d3Axc3
        f4-e4Wxg4-e3Axe2-d3Axc3-d4Wxd2
        f4-e3Axd2
        f4-e3Axd2-d3Axc3
        f4-e3Axd2-e4Wxe2
    )), 'seven moves, counted by hand');

    $bd->play(sq('f4'), W, WITHDRAWAL);
    $bd->play(sq('e4'), S, APPROACH);
    is_deeply([ map { name($_) } $bd->chain_seen ], [ qw(e3 e4 f4) ], 'the chain has stood on f4, e4 and e3');
    # e3 north-east to f4 would withdraw from d2 and take it
    is($bd->step_why(sq('e3'), NE, WITHDRAWAL), WHY_OK, 'e3-f4 on its own is a capture');
    is($bd->play_why(sq('e3'), NE, WITHDRAWAL), WHY_REVISIT, 'and in this chain it is refused: f4 is where it began');
    is(texts($bd->play_steps), 'e3-d3Axc3', 'the one step left goes west');

    $bd->play(sq('e3'), W, APPROACH);
    is($bd->play_why(sq('d3'), E, WITHDRAWAL), WHY_REVISIT, 'from d3, back to e3 is refused too: a point in the middle of the chain');
    is(texts($bd->play_steps), 'd3-d4Wxd2', 'and one step is left');
};

# "you must keep moving the same piece"
subtest 'the same stone, and only that one' => sub {
    #  the first position again, with a second white stone that can take
    my $bd = board('9/2b6/7b1/1w1b5/7w1 w');
    is(mtexts($bd->moves), 'b2-c2Axd2 b2-c2Axd2-c3Axc4 h1-h2Axh3', 'three moves between the two stones');
    $bd->play(sq('b2'), E, APPROACH);
    is($bd->step_why(sq('h1'), N, APPROACH), WHY_OK, 'h1-h2 is a capture');
    is($bd->play_why(sq('h1'), N, APPROACH), WHY_NOT_THE_STONE, 'but not while b2\'s chain is open');
    is(texts($bd->play_steps), 'c2-c3Axc4', 'only the stone in the chain is offered a step');
};

# Every step of a chain after the first must take.
subtest 'a stone that has taken may stop, and may not then stroll' => sub {
    my $bd = board('9/2b6/9/1w1b5/9 w');
    $bd->play(sq('b2'), E, APPROACH);
    is($bd->play_why(sq('c2'), S, PAIKA), WHY_PAIKA_IN_CHAIN, 'c2-c1 takes nothing, and is refused');
    is($bd->play_why(sq('c2'), N, PAIKA), WHY_NOT_A_PAIKA, 'c2-c3 asked as a paika is refused for what it is: it takes');
    is($bd->play_why(sq('c2'), S, APPROACH), WHY_TAKES_NOTHING, 'c2-c1 asked as an approach takes nothing');
    is($bd->play_why(sq('c2'), W, WITHDRAWAL), WHY_REVISIT, 'c2-b2 goes back where it came from');
    is($bd->play_why(sq('c2'), E, APPROACH), WHY_SAME_DIRECTION, 'c2-d2 goes the way it came');
    is($bd->play_why(sq('c2'), NE, APPROACH), WHY_NO_LINE, 'c2 is weak and has no diagonal');
    is($bd->play_why(sq('c4'), S, APPROACH), WHY_NOT_YOURS, 'Black\'s stone is not the mover\'s');
    is($bd->play_why(sq('a1'), N, PAIKA), WHY_NO_STONE, 'an empty point has no stone');
    is(scalar(grep { $_->{kind} == PAIKA } $bd->play_steps), 0, 'no paika is ever offered in a chain');
    is_deeply([ WHY_NOT_THE_STONE, WHY_SAME_DIRECTION, WHY_REVISIT, WHY_PAIKA_IN_CHAIN ], [ 10 .. 13 ],
        'the four reasons a chain adds are 10 to 13');
};

# "It is not allowed to capture by approach and withdrawal at the same time"
subtest 'a step with two lines, inside a chain' => sub {
    #  4  . b . .       a2 east to b2 approaches c2. Then b2 north to b3 has
    #  3  . . . b       b4 ahead of it and b1 behind: two entries. What can
    #  2  w . b .       follow depends on which was left standing.
    #  1  . b . .
    my $bd = board('9/1b7/3b5/w1b6/1b7 w');
    is(mtexts($bd->moves), join(' ', sort qw(
        a2-b2Axc2
        a2-b2Axc2-b3Axb4
        a2-b2Axc2-b3Axb4-c3Axd3
        a2-b2Axc2-b3Wxb1
        a2-b2Axc2-b3Wxb1-c3Axd3
        a2-b2Axc2-b3Wxb1-c3Axd3-d2Wxb4
    )), 'six moves, counted by hand');
    $bd->play(sq('a2'), E, APPROACH);
    is(texts($bd->play_steps), 'b2-b3Axb4 b2-b3Wxb1', 'b2-b3 is offered twice');

    my $approach = $bd->clone;
    ok($approach->in_chain, 'a clone of a board mid-chain is mid-chain');
    $approach->play(sq('b2'), N, APPROACH);
    $approach->play(sq('b3'), E, APPROACH);
    ok(!$approach->in_chain, 'after the approach and c3, nothing is left on any line: the chain closes');
    is($approach->count(BLACK), 1, 'and b1 is still standing');

    $bd->play(sq('b2'), N, WITHDRAWAL);
    $bd->play(sq('b3'), E, APPROACH);
    is(texts($bd->play_steps), 'c3-d2Wxb4', 'after the withdrawal, b4 is still there to be withdrawn from');
};

# "The last movement direction of the capturing move in the previous turn ...
# does not influence possible capturing directions in the current turn."
subtest 'nothing of a chain outlives it' => sub {
    #  3  w . b . b . . . .
    my $bd = board('9/9/w1b1b4/9/9 w');
    $bd->play(sq('a3'), E, APPROACH);
    ok(!$bd->in_chain, 'a3-b3 takes c3 and has nothing to follow: closed');
    is($bd->chain_dir, -1, 'no direction is remembered');
    is($bd->side, BLACK, 'Black to move');
    is($bd->play_why(sq('e3'), W, PAIKA), WHY_OK, 'e3-d3 is a paika for Black');
    $bd->play(sq('e3'), W, PAIKA);
    is($bd->side, WHITE, 'a paika passes the turn');
    ok(!$bd->in_chain, 'and opens no chain');
    is($bd->play_why(sq('b3'), E, APPROACH), WHY_OK,
        'White\'s first step of the new move goes east again, as its last move did, and that is allowed');

    # and after an explicit stop
    my $two = board('9/2b6/9/1w1b5/9 w');
    $two->play(sq('b2'), E, APPROACH);
    $two->stop;
    is($two->chain_at, -1, 'a stop leaves no stone in a chain');
    is($two->chain_dir, -1, 'no direction');
    is(scalar($two->chain_seen), 0, 'and no point stood on');
};

# play_why agrees with play_steps on every stone, direction and kind, WITH A
# CHAIN OPEN as well as without. Every chain of every position is walked and
# the question asked at each stop along it.
subtest 'play_why is the list, inside a chain too' => sub {
    my ($asked, $open, @bad) = (0, 0);
    my $ask;
    $ask = sub {
        my ($bd, $depth) = @_;
        my %legal = map { join(',', @{$_}{qw(from dir kind)}) => 1 } $bd->play_steps;
        for my $from ($bd->all_squares) {
            for my $dir (0 .. 7) {
                for my $kind (PAIKA, APPROACH, WITHDRAWAL) {
                    $asked++;
                    my $ok = $bd->play_why($from, $dir, $kind) == WHY_OK;
                    push @bad, $bd->to_string . ' at ' . name($bd->chain_at < 0 ? $from : $bd->chain_at)
                        . ': ' . name($from) . " dir $dir kind $kind"
                        if $ok != !!$legal{"$from,$dir,$kind"};
                }
            }
        }
        return if $depth >= 3;
        for my $s ($bd->play_steps) {
            next if $s->{kind} == PAIKA;
            my $token = $bd->play($s);
            if ($bd->in_chain) { $open++; $ask->($bd, $depth + 1) }
            $bd->unplay($token);
        }
    };
    $ask->(board($_), 0) for
        '9/5wb2/2b6/3bb4/9 w', '9/1b7/3b5/w1b6/1b7 w', '9/2b6/7b1/1w1b5/7w1 w',
        '1bbbbbbb1/bwbb1bbb1/3b3b1/www1b3w/ww1wb1www w', 'bbw5b/4wbb1b/bw5bw/wwww2www/wwwww1www b';
    cmp_ok($open, '>', 50, "$open positions with a chain open among them");
    cmp_ok($asked, '>', 50_000, "$asked questions asked");
    is(scalar(@bad), 0, 'and play_why says OK exactly when the step is in play_steps')
        or diag join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)];
};

subtest 'the chain is not the position' => sub {
    my $bd = board('9/2b6/9/1w1b5/9 w');
    $bd->play(sq('b2'), E, APPROACH);
    my $mid = $bd->key_hex;
    is($mid, $bd->key_full_hex, 'mid-chain, the key is the key of the stones and the side');
    my ($plain) = $E->of_string($bd->to_string);
    is($plain->key_hex, $mid, 'the same stones with no chain open have the same key');
    ok(!$plain->in_chain, 'and a position string carries no chain');
    is(texts($plain->play_steps), 'c2-c3Axc4', 'so from the string the stone may take c4');
    is($plain->play_why(sq('c2'), E, PAIKA), WHY_MUST_CAPTURE, 'and going east is refused only because something can be taken');
};

subtest 'taking the last stone' => sub {
    my $bd = board('9/9/w1b6/9/9 w');
    my ($move) = $bd->moves;
    is(mtext($move), 'a3-b3Axc3', 'one move');
    $bd->play_move($move);
    is($bd->count(BLACK), 0, 'Black has no stones');
    ok(!$bd->in_chain, 'the chain closed');
    is($bd->side, BLACK, 'and it is Black\'s turn, with nothing to move');
    is(scalar(my @none = $bd->moves), 0, 'no moves');
    is($bd->count_moves, '0', 'none counted');
    is(scalar(my @no = $bd->play_steps), 0, 'and no steps');
};

subtest 'the version 2 step is as it was' => sub {
    my $bd = board('9/2b6/9/1w1b5/9 w');
    my $token = $bd->do_step(sq('b2'), E, APPROACH);
    is($bd->side, BLACK, 'do_step still passes the turn after a capture');
    ok(!$bd->in_chain, 'and opens no chain');
    $bd->undo_step($token);
    is($bd->to_string, '9/2b6/9/1w1b5/9 w', 'and undo_step still undoes it');
    is($E->new->perft_steps(4), '647', 'the step ladder has not moved');
};

done_testing();
