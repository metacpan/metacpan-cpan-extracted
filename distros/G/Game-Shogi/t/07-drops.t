use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

sub sq { $E->square($_[0]) }

sub fault {
    my ($sfen, $letter, $square) = @_;
    return $E->new(sfen => $sfen)->drop_fault($letter, sq($square));
}

# ---- a drop -------------------------------------------------------------------

{
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b S 1');
    my @drops = $b->drops;
    is(scalar @drops, 79, 'a silver in hand may go on any of the 79 empty squares');
    ok(!(grep { /\+/ } @drops), '  and never promotes on landing');
    ok($b->do_move('S*4c'), 'dropped into the zone');
    is($b->at(sq('4c')), 'S', '  it lands a silver, unpromoted');
    is($b->hand('b', 'S'), 0, '  and leaves the hand');
    $b->set_side_to_move('b');
    ok((grep { $_ eq '4c3d+' } $b->board_moves), '  and its next move, out of the zone, may promote');
}

# ---- the order ----------------------------------------------------------------

{
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b RBGSNLP 1');
    my @order;
    for ($b->drops) { my ($l) = /^(.)/; push @order, $l unless @order && $order[-1] eq $l }
    is("@order", 'R B G S N L P', 'drops come rook first and pawn last, as U orders a hand');
    my @rook = grep { /^R/ } $b->drops;
    is_deeply(\@rook, [ map { "R*" . $E->square_name($_) } grep { !defined $b->at($_) } 0 .. 80 ],
        '  and each piece square by square, in square order');
    my @legal = $b->legal;
    is_deeply([ @legal[ -scalar($b->drops) .. -1 ] ], [ $b->drops ], 'legal is the board moves, then the drops');
    is(scalar @legal, scalar($b->board_moves) + scalar($b->drops), '  all of both');
}

# ---- restriction 1: no piece where it could never move -------------------------

{
    my $s = '4k4/9/9/9/9/9/9/9/4K4 b PLN 1';
    is(fault($s, 'P', '3a'), DROP_DEAD, 'a pawn on rank a could never move');
    is(fault($s, 'P', '3b'), DROP_OK,   '  on rank b it could');
    is(fault($s, 'L', '3a'), DROP_DEAD, 'a lance on rank a could never move');
    is(fault($s, 'L', '3b'), DROP_OK,   '  on rank b it could');
    is(fault($s, 'N', '3a'), DROP_DEAD, 'a knight on rank a could never move');
    is(fault($s, 'N', '3b'), DROP_DEAD, '  nor on rank b');
    is(fault($s, 'N', '3c'), DROP_OK,   '  on rank c it could');
    my $w = '4k4/9/9/9/9/9/9/9/4K4 w pln 1';
    is(fault($w, 'P', '3i'), DROP_DEAD, "White's pawn on rank i could never move");
    is(fault($w, 'N', '3h'), DROP_DEAD, "White's knight on rank h could never move");
    is(fault($w, 'N', '3g'), DROP_OK,   '  on rank g it could');
    is(fault('4k4/9/9/9/9/9/9/9/4K4 b SGBR 1', $_, '3a'), DROP_OK, "a $_ may go on rank a: it can still move")
        for qw(S G B R);
}

# ---- restriction 2: two pawns (nifu) --------------------------------------------

{
    is(fault('4k4/9/9/9/9/9/4P4/9/4K4 b P 1', 'P', '5c'), DROP_TWO_PAWNS, 'a pawn onto a file with an unpromoted pawn of its own: two pawns');
    is(fault('4k4/9/9/9/9/9/4P4/9/4K4 b P 1', 'P', '4c'), DROP_OK, '  the next file is free');
    is(fault('4k4/9/9/9/9/9/4+P4/9/4K4 b P 1', 'P', '5c'), DROP_OK, 'a tokin does not count (W line 506)');
    is(fault('4k4/9/9/9/9/9/4p4/9/4K4 b P 1', 'P', '5c'), DROP_OK, 'nor does a rival\'s pawn');
    my $b = $E->new(sfen => '4k4/9/9/9/4p4/9/4P4/9/4K4 w p 1');
    is($b->drop_fault('P', sq('5c')), DROP_TWO_PAWNS, 'White has a pawn on file 5');
    $b->set_side_to_move('b');
    ok($b->do_move('5g5f') && $b->do_move('5e5f'), 'until Black\'s pawn is taken by it, after a move each');
    $b->set_side_to_move('w');
    ok($b->do_move('5f5g'), '  and it moves on');
    ok($b->undo_move, '  (and back)');
    $b->lift(sq('5f'));
    is($b->drop_fault('P', sq('5c')), DROP_OK, 'with no pawn of its own left on the file, it may drop one there');
}

# ---- the king -------------------------------------------------------------------

{
    my $s = '4r4/9/9/9/9/9/9/9/4K4 b G 1';
    is(fault($s, 'G', '3e'), DROP_IN_CHECK, 'in check from a rook, a gold dropped elsewhere leaves the king attacked');
    is(fault($s, 'G', '5e'), DROP_OK, '  dropped on the file between, it blocks the check');
}

# ---- restriction 3: drop pawn mate (uchifuzume) ----------------------------------
#
# White's king on 1a. Black's gold on 3b holds 2a and 2b; Black's silver on 2c
# defends 1b. A pawn dropped on 1b checks the king, the king cannot take it,
# and it has nowhere to go.

my $MATE = '8k/6G2/7S1/9/9/9/9/9/9 b P 1';
{
    my $b = $E->new(sfen => $MATE);
    is($b->drop_fault('P', sq('1b')), DROP_PAWN_MATE, 'a pawn dropped to give mate is refused');
    ok(!(grep { $_ eq 'P*1b' } $b->drops), '  and is not a legal drop');
    ok($b->do_move('P*1b'), '  though do_move, which judges only shape, will make it');
    ok($b->in_check('w') && !$b->has_legal_move, '  and it is indeed mate');
}

# W, line 507, on what the rule does NOT forbid. Each is allowed.
{
    for my $piece (qw(L G)) {
        my $b = $E->new(sfen => "8k/6G2/7S1/9/9/9/9/9/9 b $piece 1");
        is($b->drop_fault($piece, sq('1b')), DROP_OK, "a $piece dropped to give the same mate is allowed");
        ok($b->do_move("$piece*1b") && !$b->has_legal_move, '  and it is mate');
    }
    my $b = $E->new(sfen => '8k/6G2/8G/9/9/9/9/9/9 b N 1');
    is($b->drop_fault('N', sq('2c')), DROP_OK, 'a knight dropped to give mate is allowed (a gold on 1c holds 1b)');
    ok($b->do_move('N*2c') && $b->in_check('w') && !$b->has_legal_move, '  and it is mate');

    $b = $E->new(sfen => '8k/6G2/7SP/9/9/9/9/9/9 b - 1');
    ok((grep { $_ eq '1c1b' } $b->board_moves), 'a pawn already on the board may give the same mate');
    ok($b->do_move('1c1b') && !$b->has_legal_move, '  and it is mate');

    $b = $E->new(sfen => '8k/9/7S1/9/9/9/9/9/9 b P 1');
    is($b->drop_fault('P', sq('1b')), DROP_OK, 'a pawn dropped to give check that is not mate is allowed');
    ok($b->do_move('P*1b') && $b->in_check('w') && $b->has_legal_move, '  the king has 2a to go to');

    $b = $E->new(sfen => '8k/6G2/9/9/9/9/9/9/9 b P 1');
    is($b->drop_fault('P', sq('1b')), DROP_OK, 'an undefended pawn the king can take is allowed');
}

{
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/9 b P 1');
    is_deeply([ $b->board_moves ], [], 'a side with nothing on the board but a pawn in hand has no board move');
    ok($b->has_legal_move, '  and still has a legal move: a drop');
}

# ---- the order the faults are asked in --------------------------------------------

{
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/4P4/9/4K4 b - 1');
    is($b->drop_fault('P', sq('5e')), DROP_NOT_HELD, 'none in hand is asked before anything about the square');
    $b = $E->new(sfen => '4k4/9/9/9/9/9/4P4/9/4K4 b P 1');
    is($b->drop_fault('P', sq('5g')), DROP_OCCUPIED, 'an occupied square before two pawns');
    is($b->drop_fault('P', sq('5a')), DROP_OCCUPIED, 'and before a dead piece');
    is($b->drop_fault('P', sq('4a')), DROP_DEAD, 'a dead piece before two pawns (file 4 is free; rank a is not)');
    is($b->drop_fault($_->[0], $_->[1]), DROP_BAD, "'" . ($_->[0] // 'undef') . "' on " . ($_->[1] // 'undef') . ': not a drop')
        for ['K', 10], ['+P', 10], ['p', 10], ['X', 10], [undef, 10], ['P', 81], ['P', -1], ['P', 'x'];
    my %reasons;
    $reasons{ $E->drop_reason($_) }++ for DROP_OK .. DROP_PAWN_MATE;
    is(scalar(keys %reasons), DROP_PAWN_MATE + 1, 'every drop code has a reason of its own');
}

# ---- do_move and a drop --------------------------------------------------------------

{
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b P 1');
    my ($sfen, $key) = ($b->sfen, $b->key);
    is($b->do_move($_), 0, "refused: '$_'") for 'p*5e', 'K*5e', '+P*5e', 'P*5i', 'G*5e', 'P*5', 'P*0e', 'P5e';
    is($b->sfen, $sfen, '  and nothing changed');
    ok($b->do_move('P*3a'), 'do_move makes a dead drop: it judges shape, and drops lists only legal ones');
    ok($b->undo_move, '  (and back)');
    is($b->key, $key, '  to the same key');
}

# ---- full hands -----------------------------------------------------------------------

{
    my $s = '9/9/9/9/9/9/9/9/9 b 2R2B4G4S4N4L18P 1';
    my $b = $E->new(sfen => $s);
    is($b->sfen, $s, 'a hand of the whole set reads and writes');
    my ($bad, $n) = (0, 0);
    for my $m ($b->drops) {
        my $key = $b->key;
        $b->do_move($m) or $bad++;
        $bad++ unless $b->key eq $E->new(sfen => $b->sfen)->key;
        $b->undo_move or $bad++;
        $bad++ unless $b->key eq $key && $b->sfen eq $s;
        $n++;
    }
    is($bad, 0, "all $n of its drops make and unmake to the same key and SFEN");
    is($n, 4 * 81 + (81 - 18) + (81 - 9) + (81 - 9), "  and there are $n: one a kind a square; knights miss two ranks, lances and pawns one");
}

done_testing();
