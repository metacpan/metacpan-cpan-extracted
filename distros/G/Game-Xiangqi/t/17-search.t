use strict;
use warnings;
use Test::More;

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Bot;

my $E = 'Game::Xiangqi::Engine';

# XQ_MATE_SCORE, from include/xq_abi.h. It is a #define rather than a call, so it
# is repeated here; anything above 29000 is a mate score and nothing else is.
my $MATE = 30000;

sub build {
    my $b = $E->new(empty => 1);
    $b->put($E->point_of(@{$_}[0, 1]), $_->[2]) for @_;
    $b->set_side(RED);
    return $b;
}

sub iccs {
    my $m = shift;
    my ($f, $t) = ($E->move_from($m), $E->move_to($m));
    return sprintf '%s%d%s%d', chr(97 + $E->file_of($f)), $E->rank_of($f),
                               chr(97 + $E->file_of($t)), $E->rank_of($t);
}

# Every move that ENDS THE GAME here, mate or stalemate, because in this game
# both are wins and the search may not prefer one to the other.
sub winning_moves {
    my $b = shift;
    my @w;
    for my $mv ($b->legal) {
        my (undef, $u) = $b->do_move($mv);
        push @w, $mv if ($b->outcome)[0];
        $b->undo_move($u);
    }
    return @w;
}

subtest 'the move that comes back is always one the board would accept' => sub {
    # Positions taken by letting the search play itself, so they are positions the
    # bot will actually meet rather than positions chosen to be easy.
    my $b = $E->new;
    my @seen;
    for my $ply (0 .. 19) {
        push @seen, $b->clone;
        my ($mv) = $b->search(2_000, $ply);
        last unless $mv;
        $b->do_move($mv);
    }
    is(scalar @seen, 20, 'twenty positions off a self-played opening');

    for my $i (0 .. $#seen) {
        my %legal = map { $_ => 1 } $seen[$i]->legal;
        for my $budget (@Game::Xiangqi::Bot::LADDER) {
            my ($mv) = $seen[$i]->search($budget, 11);
            ok($legal{$mv}, "position $i at budget $budget: " . iccs($mv) . ' is legal')
                or diag('  fen: ' . $seen[$i]->to_fen);
        }
    }
};

subtest 'the same position, budget and seed give the same move' => sub {
    my $b = $E->new;
    $b->do_move(($b->search(3_000, 1))[0]) for 1 .. 4;

    for my $seed (0, 1, 7, 4294967295) {
        my ($first)  = $b->search(9_000, $seed);
        my ($second) = $b->search(9_000, $seed);
        is($second, $first, "seed $seed answers " . iccs($first) . ' both times');
    }

    # AND THE SEED IS ACTUALLY WIRED THROUGH. Not that two seeds must differ,
    # which depends on there being a tie to break, but that the seat changes the
    # number the bot hands in. Without this the two bots in a bot-versus-bot game
    # are the same player: Game::Goofspiel shipped exactly that.
    my $B = 'Game::Xiangqi::Bot';
    my $seed = 'q' x 32;
    isnt($B->tiebreak_seed($seed, 'p2'), $B->tiebreak_seed($seed, 'p1'),
         'the seat changes the tie-break seed');
    is($B->tiebreak_seed($seed, 'p1'), $B->tiebreak_seed($seed, 'p1'),
       '  and the same seat does not');
};

# Red general f0, two chariots and a horse against a bare general on e9 with one
# soldier to keep it out of stalemate. a8e8 and a8a9 are mates; a8a5 takes the
# soldier and leaves black with no legal move at all, which in this game is also
# a win, so the assertion is on ENDING the game and not on the word checkmate.
my @MATE_IN_ONE = ([5, 0, RED | GENERAL], [0, 8, RED | CHARIOT], [3, 1, RED | CHARIOT],
                   [6, 7, RED | HORSE],
                   [4, 9, BLACK | GENERAL], [0, 5, BLACK | SOLDIER]);

subtest 'a mate in one is found at every rung, and at no budget at all' => sub {
    my $ref = build(@MATE_IN_ONE);
    ok($ref->mate_in(1), 'the fixture is a mate in one, by the phase 04 prover');
    my %win = map { $_ => 1 } winning_moves($ref);
    is(scalar keys %win, 3, '  with three moves that end the game');

    for my $budget (0, 1, @Game::Xiangqi::Bot::LADDER) {
        my $b = build(@MATE_IN_ONE);
        my ($mv, $nodes, $depth, $score) = $b->search($budget, 3);
        ok($win{$mv}, "budget $budget plays " . iccs($mv) . ", which ends the game");
        cmp_ok($score, '>', $MATE - 10, "  and says so: score $score at depth $depth");
    }
};

# The same box with the d file blocked by a black soldier and rank 9 blocked by a
# black elephant, so nothing mates this move and the win takes three plies:
# chariot takes the soldier, black moves, chariot to e8.
my @MATE_IN_THREE = ([5, 0, RED | GENERAL], [0, 8, RED | CHARIOT], [3, 1, RED | CHARIOT],
                     [6, 7, RED | HORSE],
                     [4, 9, BLACK | GENERAL], [2, 9, BLACK | ELEPHANT], [3, 5, BLACK | SOLDIER]);

subtest 'a mate in one is preferred to a mate in three' => sub {
    my $three = build(@MATE_IN_THREE);
    ok(!$three->mate_in(1), 'the second fixture has no mate in one');
    ok($three->mate_in(3),  '  and does have one in three');

    my (undef, undef, undef, $near) = build(@MATE_IN_ONE)->search(200_000, 3);
    my (undef, undef, undef, $far)  = $three->search(200_000, 3);

    cmp_ok($near, '>', $MATE - 10, "the mate in one scores $near");
    cmp_ok($far,  '>', $MATE - 10, "the mate in three scores $far");

    # THIS IS THE ASSERTION. The scores are mate-minus-distance, so a shorter mate
    # is a bigger number, and that is the whole mechanism by which a search that
    # can see both takes the quick one. A search that scored every mate the same
    # would pass every other test in this file and dawdle for ever in a won game.
    cmp_ok($far, '<', $near, '  and the longer mate scores STRICTLY LOWER');
    is($MATE - $near, 1, 'the near mate is one ply away');
    is($MATE - $far,  3, 'and the far one is three');
};

# Red chariot on a5, black soldier on e5, black cannon on e9 with a soldier on e7
# as its screen. Taking the soldier wins 100 and loses a chariot to e9e5.
my @TRAP = ([4, 0, RED | GENERAL], [0, 5, RED | CHARIOT],
            [3, 9, BLACK | GENERAL], [4, 9, BLACK | CANNON],
            [4, 7, BLACK | SOLDIER], [4, 5, BLACK | SOLDIER]);

subtest 'the greedy capture into a cannon screen is not played' => sub {
    my $b = build(@TRAP);
    my $greedy = $E->move($E->point_of(0, 5), $E->point_of(4, 5));

    # The fixture says what it says: this is the ONLY capture red has, so a
    # material-greedy chooser has no other way to be greedy, and it really does
    # lose the chariot.
    my @caps = grep { $b->at($E->move_to($_)) } $b->legal;
    is_deeply([ map iccs($_), @caps ], [ 'a5e5' ], 'a5e5 is the only capture');

    my (undef, $u) = $b->do_move($greedy);
    my @recapture = grep { $E->move_to($_) == $E->point_of(4, 5) } $b->legal;
    is_deeply([ map iccs($_), @recapture ], [ 'e9e5' ],
              '  and the cannon takes the chariot over its screen');
    $b->undo_move($u);

    # NON-VACUITY FIRST: a chooser that looks one ply ahead DOES fall for it.
    # Without this the test below could be passing because the search never
    # considers a5e5 at all, which is the shape of a green test that proves
    # nothing.
    my ($shallow, $shallow_score);
    for my $mv ($b->legal) {
        my (undef, $uu) = $b->do_move($mv);
        my $score = -$b->evaluate;               # the reply is black's, so negate
        $b->undo_move($uu);
        ($shallow, $shallow_score) = ($mv, $score)
            if !defined $shallow_score || $score > $shallow_score;
    }
    is(iccs($shallow), 'a5e5', 'a chooser that looks one ply ahead takes it');

    for my $budget (@Game::Xiangqi::Bot::LADDER) {
        my ($mv) = build(@TRAP)->search($budget, 5);
        isnt(iccs($mv), 'a5e5', "budget $budget does not: it plays " . iccs($mv));
    }
};

# THIS SUBTEST EXISTS BECAUSE THE BUG IT CATCHES COST THE PHASE A LADDER RUN, and
# a bug that only a sixty-game soak can see is a bug that comes back.
#
# The root used to pool every move whose score EQUALLED the best and pick among
# them with the seed. With alpha raised during the root loop, a move that is not an
# improvement comes back as a BOUND that lands exactly on alpha, so the pool filled
# with moves that were merely not-worse and the bot played one at random. The bot
# then got worse with depth: rung 40000 scored 38.3% against rung 8000.
#
# From the outside it is one number. Thirteen of the 44 opening moves are not
# genuinely equal, and no honest evaluation says they are.
# THE SEARCH'S LEGALITY TEST HAS TWO HALVES AND THE SECOND ONE HAD NO TEST.
#
# The search generates pseudo-legal moves and filters them after `do_move` with
# `legal_after`, which asks two things: the mover's general is not attacked, and the
# two generals are not facing. A mutation dropping the SECOND half was the only one
# of seven this phase could not catch, because positions off a self-played game
# hardly ever offer an exposing move worth making.
#
# So here is one that does. A red cannon on e4 is the only thing between the two
# generals, and it can win a chariot on a4 by jumping the soldier on c4. That
# capture is the best move on the board by 900 centi-soldiers and it is ILLEGAL,
# because leaving the e file makes the generals face. A search blind to that plays
# it, and the facade refuses the bot's own move.
subtest 'the flying general is part of the legality test the search uses' => sub {
    my $b = build([4, 0, RED | GENERAL], [4, 4, RED | CANNON],
                  [4, 9, BLACK | GENERAL], [2, 4, BLACK | SOLDIER], [0, 4, BLACK | CHARIOT]);
    my $grab = $E->move($E->point_of(4, 4), $E->point_of(0, 4));
    my %legal = map { $_ => 1 } $b->legal;

    # the fixture says what it says
    ok((grep { $_ == $grab } $b->moves), 'e4a4 is generated as pseudo-legal');
    ok(!$legal{$grab}, '  and is NOT legal, because it exposes the generals');
    is(scalar(grep { $b->at($E->move_to($_)) } keys %legal), 0,
       '  so there is no legal capture at all here');
    is(scalar keys %legal, 10, '  and ten legal moves that are not it');

    for my $budget (0, 1_000, @Game::Xiangqi::Bot::LADDER) {
        my ($mv) = build([4, 0, RED | GENERAL], [4, 4, RED | CANNON],
                         [4, 9, BLACK | GENERAL], [2, 4, BLACK | SOLDIER],
                         [0, 4, BLACK | CHARIOT])->search($budget, 9);
        ok($legal{$mv}, "budget $budget played " . iccs($mv) . ', which is legal')
            or diag('  the search took the chariot and left its general facing');
    }

    # AND THAT IS STILL NOT THE ASSERTION THAT CATCHES THE MUTATION, which took a
    # second try to see. The ROOT move list comes from `gen_legal`, so the search
    # can never RETURN an illegal move however broken `legal_after` is: the damage
    # is done inside the tree, where it credits the OPPONENT with escapes they do
    # not have.
    #
    # So the fixture has to be one where the opponent's only escape is the illegal
    # one. Black's general on e9 is walled in by its own advisors on d9 and f9 and
    # its own horse on e8, and that horse is the only thing standing between the two
    # generals. Every one of the horse's six moves leaves the e file, so every one
    # is illegal, so Black has SIX pseudo-legal moves and NONE legal. Red plays
    # e0e1, keeping its general on the file, and Black is stalemated, which in this
    # game is a loss.
    my @wall = ([4, 0, RED | GENERAL], [6, 7, RED | HORSE],
                [4, 9, BLACK | GENERAL], [3, 9, BLACK | ADVISOR], [5, 9, BLACK | ADVISOR],
                [4, 8, BLACK | HORSE]);
    my $w = build(@wall);
    my $black = build(@wall);
    $black->set_side(BLACK);
    is(scalar $black->moves, 6, 'Black has six pseudo-legal moves in the wall fixture');
    is(scalar $black->legal, 0, '  and not one of them is legal');

    # NOTE WHAT KIND OF WIN THIS IS: a stalemate and not a checkmate, so phase 04's
    # `mate_in` says nothing about it, and the search sees it only because "no legal
    # move" is scored as a loss whether or not the side is in check.
    for my $budget (2_000, 20_000) {
        my ($mv, undef, undef, $score) = build(@wall)->search($budget, 5);
        is(iccs($mv), 'e0e1', "budget $budget finds the waiting move that walls it in");
        cmp_ok($score, '>', $MATE - 10, "  and scores it as a win ($score)");
    }
};

subtest 'the choice is not a lottery: few moves are genuinely tied' => sub {
    my $b = $E->new;
    for my $budget (8_000, 40_000) {
        my %moves;
        $moves{ (scalar $b->search($budget, $_ * 7919)) }++ for 1 .. 24;
        cmp_ok(scalar keys %moves, '<=', 6,
               "budget $budget: " . scalar(keys %moves) . ' distinct moves over 24 seeds')
            or diag('  a pool this wide means the root is tie-breaking on BOUNDS, '
                  . 'not on values. See the root of xq_search.c.');
    }

    # AND IT IS NOT ZERO EITHER, because a bot with no variety at all opens the
    # same way every game and the seat in the tie-break seed stops meaning
    # anything. The opening really does have a handful of equal moves.
    my %opening;
    $opening{ (scalar $b->search(1_500, $_ * 104729)) }++ for 1 .. 24;
    cmp_ok(scalar keys %opening, '>', 1, 'but more than one, so the seed still matters');
};

subtest 'the evaluation answers the side to move, and is exactly antisymmetric' => sub {
    is($E->new->evaluate, 0, 'the opening is level, which a symmetric position must be');

    # ONE POSITION CANNOT BE GOOD FOR BOTH SIDES. Every term is a difference taken
    # from the mover's point of view, so handing the same board to the other side
    # must return exactly the negative. This is the assertion that catches a term
    # written for Red and copied to Black with a sign or a rank left unflipped,
    # which is a bug no game ever shows you and every ladder blames on the search.
    my $b = $E->new;
    for my $ply (1 .. 12) {
        my ($mv) = $b->search(2_000, $ply);
        $b->do_move($mv);

        my $mine = $b->evaluate;
        $b->set_side($b->side == RED ? BLACK : RED);
        my $theirs = $b->evaluate;
        $b->set_side($b->side == RED ? BLACK : RED);

        is($theirs, -$mine, "ply $ply: $mine for the mover is " . (-$mine) . ' for the other')
            or diag('  fen: ' . $b->to_fen);
    }
};

done_testing();
