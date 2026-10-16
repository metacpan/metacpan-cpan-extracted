use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

# Y lines 101-106 and 125. Worked by hand: Black's king on 5b, in the enemy
# camp; two rooks, two bishops, four golds on rank a and two silvers on rank
# b, ten pieces worth 26; two pawns in hand, 28.
my $BLACK = 'RRBB1GGGG/4K1SS1/9/9/9/9/9/9/4k4 b 2P 1';

# The same for White in its camp, ranks g to i: 26 on the board, a pawn in
# hand, 27.
my $WHITE = '4K4/9/9/9/9/9/9/1ss1k4/gggg1bbrr w p 1';

# ---- all four met ----------------------------------------------------------------------

{
    my $b = $E->new(sfen => $BLACK);
    is($b->impasse_pieces('b'), 10, 'Black has ten pieces in the camp');
    is($b->impasse_points('b'), 28, '  and 28 points with its hand');
    is($b->declare_fault, DECLARE_OK, '  and may declare');
    ok($b->can_declare, '  can_declare says so');
    my $r = $b->declare;
    is($r && $r->how, 'impasse_declared', 'declaring ends the game');
    is($r && $r->winner, 'b', '  and the declarer wins (Y line 125)');
    is($b->sfen, $BLACK, '  and the board is untouched');

    my $w = $E->new(sfen => $WHITE);
    is($w->impasse_points('w'), 27, 'White has 27');
    is($w->declare_fault, DECLARE_OK, '  and 27 is enough for White');
    is($w->declare && $w->declare->winner, 'w', '  who wins by declaring');
}

# ---- the points: Black needs 28, White 27 ----------------------------------------------

{
    my $b = $E->new(sfen => 'RRBB1GGGG/4K1SS1/9/9/9/9/9/9/4k4 b P 1');
    is($b->impasse_points('b'), 27, 'Black with 27');
    is($b->declare_fault, DECLARE_FEW_POINTS, '  may not: Black needs 28');
    is($b->declare, undef, '  and declare refuses');
    my $w = $E->new(sfen => '4K4/9/9/9/9/9/9/1ss1k4/gggg1bbrr w - 1');
    is($w->impasse_points('w'), 26, 'White with 26');
    is($w->declare_fault, DECLARE_FEW_POINTS, '  may not');
}

# ---- what the points count -----------------------------------------------------------------

{
    my $b = $E->new(sfen => '+RRBB1GGGG/4K1SS1/9/9/9/9/9/9/4k4 b 2P 1');
    is($b->impasse_points('b'), 28, 'a dragon is worth 5, as its rook was');
    $b = $E->new(sfen => '+R+R+B+B1+P+P+P+P/4K1SS1/9/9/9/9/9/9/4k4 b 2P 1');
    is($b->impasse_points('b'), 28, 'a horse 5, a tokin 1');
    $b = $E->new(sfen => 'RRB2GGGG/4K1SS1/9/9/3B5/9/9/9/4k4 b 2P 1');
    is($b->impasse_pieces('b'), 9, 'a bishop on 6e is outside the camp: nine pieces');
    is($b->impasse_points('b'), 23, '  and it counts nothing (Y line 106)');
    is($b->impasse_points('w'), 0, 'White has nothing in its camp and nothing in hand');
    is($b->impasse_points('x'), undef, 'a side that is not one has no points');
}

# ---- each condition failed in turn, and the order --------------------------------------------

{
    my %F = (
        'RRBB1GGGG/6SS1/9/4K4/9/9/9/9/4k4 b 2P 1'   => [ DECLARE_NO_KING, 'the king on 5d, outside the camp' ],
        'RRBB1GGGG/6SS1/9/9/9/9/9/9/4k4 b 2P 1'     => [ DECLARE_NO_KING, 'no king at all' ],
        'RRBB1GGGG/4K1S2/9/9/9/9/9/9/4k4 b 3P 1'    => [ DECLARE_FEW_PIECES, 'nine pieces, though 28 points' ],
        'RRBBpGGGG/4K1SS1/9/9/9/9/9/9/4k4 b 2P 1'   => [ DECLARE_IN_CHECK, 'a White pawn on 5a checks the king' ],
        'RRBB1GGGG/6SS1/9/4K4/9/9/9/9/4k4 b P 1'    => [ DECLARE_NO_KING, 'no king in the camp AND too few points: the king first' ],
        'RRBBpGGG1/4K1SS1/9/9/9/9/9/9/4k4 b 2P 1'   => [ DECLARE_FEW_PIECES, 'too few pieces AND in check: the pieces first' ],
        'RRBBpGGGG/4K1SS1/9/9/9/9/9/9/4k4 b P 1'    => [ DECLARE_IN_CHECK, 'in check AND too few points: the check first' ],
    );
    for my $sfen (sort keys %F) {
        my ($want, $what) = @{ $F{$sfen} };
        is($E->new(sfen => $sfen)->declare_fault, $want, "$what: " . $E->declare_reason($want));
    }
    my %reasons;
    $reasons{ $E->declare_reason($_) }++ for DECLARE_OK .. DECLARE_FEW_POINTS;
    is(scalar(keys %reasons), DECLARE_FEW_POINTS + 1, 'every declaration code has a reason of its own');
}

# ---- the cap ------------------------------------------------------------------------------------
#
# Y line 128: at 500 moves the game is drawn; if the side to move is in check
# then, play goes on until it is not.

{
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K3G b - 500');
    is($b->cap, 500, 'the cap is 500 unless given');
    is($b->outcome, undef, 'at move 500, 499 moves played: play on');
    $b->do_move('1i1h');
    my $r = $b->outcome;
    is($r && $r->how, 'cap', '500 moves played: a draw at the cap');
    ok($r && $r->is_draw, '  nobody wins');
    is($r && $r->ply, 500, '  after 500 plies');

    my $c = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K2R1 b - 500');
    $c->do_move('2i2a');
    ok($c->in_check('w'), 'the 500th move gives check');
    is($c->outcome, undef, '  so play goes on');
    $c->do_move('5a5b');
    is($c->outcome && $c->outcome->how, 'cap', '  and the cap ends it once the check is answered');

    my $d = $E->new(sfen => 'RRBB1GGGG/4K1SS1/9/9/9/9/9/9/4k4 b 2P 501');
    ok($d->can_declare, 'the declaration\'s conditions hold after the cap');
    is($d->declare, undef, '  but the game is over, so declare refuses');

    my $short = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K3G b - 10', cap => 10);
    is($short->cap, 10, 'a cap may be given');
    $short->do_move('1i1h');
    is($short->outcome && $short->outcome->how, 'cap', '  and is kept');
    is($short->clone->cap, 10, '  and a clone keeps it');
    for my $bad (0, -1, 'x', '') {
        ok(!eval { $E->new(cap => $bad); 1 }, "a cap of '$bad' is refused");
    }
}

done_testing();
