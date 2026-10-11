use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use FnT qw(sq name text texts mtext mtexts board roller);
my $E = 'Game::Fanorona::Engine';

# THE STEP TREE, WALKED IN PERL. A whole move is a path from the root to a
# place the mover may stop: after a paika, after a step that closed its own
# chain, and after ANY step of a chain still open. This walks play_steps, play
# and unplay and shares nothing with the C that lists moves but those three.
sub tree_moves {
    my ($bd, $prefix, $out) = @_;
    for my $s ($bd->play_steps) {
        my $token = $bd->play($s);
        my $so_far = defined $prefix ? $prefix . substr(text($s), 2) : text($s);
        push @$out, $so_far;
        tree_moves($bd, $so_far, $out) if $bd->in_chain;
        $bd->unplay($token);
    }
    return $out;
}

sub random_board {
    my ($roll, $thicket) = @_;
    my $bd = $E->new(empty => 1);
    my @all = $bd->all_squares;
    my $mover = $roll->(2) ? WHITE : BLACK;
    if ($thicket) {
        $bd->put($all[ $roll->(45) ], $mover) for 1 .. 1 + $roll->(3);
        for (1 .. 6 + $roll->(14)) {
            my $s = $all[ $roll->(45) ];
            $bd->put($s, other($mover)) if $bd->at($s) == EMPTY;
        }
    }
    else {
        $bd->put($all[ $roll->(45) ], $roll->(2) ? WHITE : BLACK) for 1 .. 2 + $roll->(36);
    }
    return $bd->set_side($mover);
}

subtest 'the list of moves is the step tree' => sub {
    my $roll = roller(31102026);
    my ($positions, $moves, $chains, $longest, @bad) = (0, 0, 0, 0);
    for my $i (1 .. 400) {
        my $bd = random_board($roll, $i % 2);
        my $before = $bd->to_string;
        my @list = $bd->moves;
        my $want = join ' ', sort @{ tree_moves($bd, undef, []) };
        $positions++;
        $moves += @list;
        for my $m (@list) {
            $chains++ if $m->length > 1;
            $longest = $m->length if $m->length > $longest;
        }
        push @bad, "$before\n  tree:  $want\n  moves: " . mtexts(@list) unless mtexts(@list) eq $want;
        push @bad, "$before: count_moves says " . $bd->count_moves . ', the list has ' . scalar(@list)
            unless $bd->count_moves eq scalar(@list);
        push @bad, "$before: listing the moves changed the board" unless $bd->to_string eq $before && !$bd->in_chain;
    }
    is($positions, 400, 'four hundred positions');
    cmp_ok($moves, '>', 3000, "$moves whole moves between them");
    cmp_ok($chains, '>', 500, "$chains of them chains of two steps or more");
    cmp_ok($longest, '>=', 5, "the longest of $longest steps");
    is(scalar(@bad), 0, 'and every list is exactly the paths of the tree')
        or diag join "\n", @bad[0 .. ($#bad < 2 ? $#bad : 2)];
};

subtest 'a chain\'s shorter beginnings come before its longer ones' => sub {
    my $bd = board('9/5wb2/2b6/3bb4/9 w');
    my @order = map { mtext($_) } $bd->moves;
    is_deeply(\@order, [ qw(
        f4-e3Axd2
        f4-e3Axd2-e4Wxe2
        f4-e3Axd2-d3Axc3
        f4-e4Wxg4
        f4-e4Wxg4-e3Axe2
        f4-e4Wxg4-e3Axe2-d3Axc3
        f4-e4Wxg4-e3Axe2-d3Axc3-d4Wxd2
    ) ], 'depth first, a move before the moves that extend it');
    my %at = map { $order[$_] => $_ } 0 .. $#order;
    my @late = grep { my $m = $_; grep { index($m, "$_-") == 0 && $at{$_} > $at{$m} } @order } @order;
    is("@late", '', 'no move is listed before one it extends');
};

subtest 'a move is a value' => sub {
    my $bd = board('9/5wb2/2b6/3bb4/9 w');
    my ($long) = grep { $_->length == 4 } $bd->moves;
    isa_ok($long, 'Game::Fanorona::Move');
    is(mtext($long), 'f4-e4Wxg4-e3Axe2-d3Axc3-d4Wxd2', 'the move of four steps');
    is($long->from, sq('f4'), 'it starts on f4');
    is($long->to, sq('d4'), 'and ends on d4');
    is($long->length, 4, 'four steps');
    is_deeply([ map { name($_) } $long->taken ], [ qw(g4 e2 c3 d2) ], 'taking g4, e2, c3 and d2 in that order');
    is_deeply([ map { name($_) } $long->points ], [ qw(f4 e4 e3 d3 d4) ], 'standing on five points');
    ok(!$long->is_paika, 'it is not a paika');

    # a capture of ONE step is not a paika either: what makes a paika is that
    # it takes nothing, not that it is short
    my ($one) = grep { $_->length == 1 } $bd->moves;
    is(mtext($one), 'f4-e3Axd2', 'the first one-step move takes d2');
    ok(!$one->is_paika, 'and is not a paika');
    is($one->to, sq('e3'), 'it ends on e3');
    is_deeply([ map { $_->{kind} } @{ $long->steps } ], [ WITHDRAWAL, APPROACH, APPROACH, WITHDRAWAL ], 'its steps keep their kinds');
    is_deeply([ map { $_->{dir} } @{ $long->steps } ], [ W, S, W, N ], 'and their directions');

    my $quiet = board('9/9/4w4/9/9 w');
    my @paikas = $quiet->moves;
    is(scalar(@paikas), 8, 'a lone stone on e3 has eight moves');
    is(scalar(grep { $_->is_paika && $_->length == 1 && !$_->taken } @paikas), 8, 'each a paika of one step taking nothing');
    is($paikas[0]->to, sq('e4'), 'the first of them goes north');
};

subtest 'playing a move, and taking it back' => sub {
    my $roll = roller(909);
    my ($played, @bad) = (0);
    for my $i (1 .. 120) {
        my $bd = random_board($roll, $i % 2);
        my $before = $bd->to_string;
        my $key = $bd->key_hex;
        my $mover = $bd->side;
        my $enemy = $bd->count(other($mover));
        for my $m ($bd->moves) {
            my $tokens = $bd->play_move($m);
            $played++;
            if (!$tokens) { push @bad, "$before: " . mtext($m) . ' would not play'; next }
            push @bad, "$before: after " . mtext($m) . ' a chain is still open' if $bd->in_chain;
            push @bad, "$before: after " . mtext($m) . ' the turn has not passed' unless $bd->side == other($mover);
            # a taken point holds no ENEMY stone. It may hold the mover's: a
            # chain can end on a point it emptied three steps before.
            push @bad, "$before: " . mtext($m) . ' left a taken stone standing'
                if grep { $bd->at($_) == other($mover) } $m->taken;
            push @bad, "$before: " . mtext($m) . ' took ' . scalar($m->taken) . ' and the count fell by another number'
                unless $bd->count(other($mover)) == $enemy - scalar($m->taken);
            push @bad, "$before: " . mtext($m) . ' did not end where it says' unless $bd->at($m->to) == $mover;
            $bd->unplay_move($tokens);
            push @bad, "$before: " . mtext($m) . ' did not come back'
                unless $bd->to_string eq $before && $bd->key_hex eq $key && !$bd->in_chain;
        }
    }
    cmp_ok($played, '>', 800, "$played moves played and taken back");
    is(scalar(@bad), 0, 'each passed the turn, closed its chain, and was undone exactly')
        or diag join "\n", @bad[0 .. ($#bad < 3 ? $#bad : 3)];

    # A STOP IS PART OF THE MOVE. The short move of a longer chain leaves the
    # chain open after its last step, and play_move closes it.
    my $bd = board('9/2b6/9/1w1b5/9 w');
    my ($short) = grep { $_->length == 1 } $bd->moves;
    my $tokens = $bd->play_move($short);
    is(scalar(@$tokens), 2, 'the one-step move of a two-step chain is a step and a stop');
    is($bd->to_string, '9/2b6/9/2w6/9 b', 'and it leaves c4 standing with Black to move');
    $bd->unplay_move($tokens);

    # a move that is not one from here
    my $elsewhere = board('9/9/4w4/9/9 w');
    is($elsewhere->play_move($short), undef, 'a move from another position is not played');
    is($elsewhere->to_string, '9/9/4w4/9/9 w', 'and the board is as it was');

    # A MOVE THAT CAN BE BUILT HERE AND IS NOT LEGAL HERE. e3-e4 is a paika on
    # an empty board. With a black stone on g3 the same step is still there to
    # be made, and may not be: e3-f3 would take, so taking is compulsory.
    my ($north) = grep { mtext($_) eq 'e3-e4' } $elsewhere->moves;
    ok($north, 'e3-e4 is a move of the lone stone');
    my $must = board('9/9/4w1b2/9/9 w');
    ok(defined $must->step(sq('e3'), N, PAIKA), 'with g3 black, e3-e4 can still be built as a step');
    is($must->play_move($north), undef, 'but play_move refuses it: a capture is there to be made');
    is($must->to_string, '9/9/4w1b2/9/9 w', 'and nothing moved');
    $bd->play(sq('b2'), E, APPROACH);
    is($bd->play_move($short), undef, 'nor is any move while a chain is open');

    # NOT EVEN THE STEP THE CHAIN COULD TAKE NEXT. With the chain open on c2,
    # c2-c3 is a legal step; as a whole move handed to play_move it is refused,
    # because a move is played from between moves.
    my ($onward) = board($bd->to_string)->moves;
    is(mtext($onward), 'c2-c3Axc4', 'from the same stones with no chain open, c2-c3 is a move');
    is($bd->play_why(sq('c2'), N, APPROACH), WHY_OK, 'and with the chain open it is a legal step');
    is($bd->play_move($onward), undef, 'but play_move will not play a move into an open chain');
    ok($bd->in_chain, 'the chain is still open');
    is($bd->at(sq('c4')), BLACK, 'and c4 still stands');
};

# A POSITION CAN HAVE MORE WHOLE MOVES THAN ANYONE WILL WAIT FOR. This one was
# found by a search for exactly that: four white stones and twenty-five black.
subtest 'too many to list' => sub {
    my $bd = board('bwbbb1bbb/b1wbbb1bb/1b3b2b/w1b3b2/bwbbb1bbb w');
    is($bd->count_moves, '15898', 'fifteen thousand eight hundred and ninety-eight');
    is($bd->count_moves(1000), '1000', 'a count with a cap stops at the cap');
    is($bd->count_moves(1), '1', 'even a cap of one');
    my $next = $bd->play_steps;
    cmp_ok($next, '<=', 16, "though the steps to choose from next are $next");
    ok(!eval { my @m = $bd->moves(500); 1 }, 'moves croaks when there are more than it was asked to list');
    like($@, qr/more than 500 whole moves/, 'and says so');
    is(scalar(my @all = $bd->moves(20_000)), 15898, 'asked for enough room, it lists them all');
    is($bd->to_string, 'bwbbb1bbb/b1wbbb1bb/1b3b2b/w1b3b2/bwbbb1bbb w', 'and the board is as it was');
    is($E->chain_max, 44, 'no chain is longer than forty-four steps');
};

done_testing();
