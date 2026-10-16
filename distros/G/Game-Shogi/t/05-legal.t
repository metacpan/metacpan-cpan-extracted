use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

sub sq { $E->square($_[0]) }

# ---- attack against the move generator ------------------------------------------
#
# Two ways to the same answer that share no code: `attacked` looks backwards
# from the square, and the move generator looks forwards from the piece. On a
# board with one piece, the squares it attacks are exactly the squares its
# moves reach. Every kind, both sides, from every square.

{
    my ($boards, $bad, $reached) = (0, 0, 0);
    for my $side (qw(b w)) {
        for my $t (qw(P L N S G B R K +P +L +N +S +B +R)) {
            my $token = $side eq 'w' ? lc $t : $t;
            for my $from (0 .. 80) {
                my $b = $E->new(empty => 1)->put($from, $token)->set_side_to_move($side);
                my %reach = map { substr($_, 2, 2) => 1 } $b->pseudo_moves;
                my %hit = map { $E->square_name($_) => 1 } grep { $b->attacked($_, $side) } 0 .. 80;
                $boards++;
                $reached += keys %reach;
                $bad++ unless join(',', sort keys %reach) eq join(',', sort keys %hit);
            }
        }
    }
    is($bad, 0, "$boards one-piece boards: what each piece attacks is where its moves go");
    cmp_ok($reached, '>', 2268 * 3, "  and they agree on $reached squares, not on nothing");
}

{
    my $b = $E->new(empty => 1)->put(sq('1e'), 'N');
    is_deeply([ map { $E->square_name($_) } grep { $b->attacked($_, 'b') } 0 .. 80 ], ['2c'],
        'a knight on 1e attacks 2c and nothing round the edge');
    $b = $E->new(empty => 1)->put(sq('2a'), 'n');
    is_deeply([ sort map { $E->square_name($_) } grep { $b->attacked($_, 'w') } 0 .. 80 ], [qw(1c 3c)],
        "White's knight on 2a attacks 1c and 3c, two ranks towards i");
}

# ---- the start -------------------------------------------------------------------

{
    my $b = $E->new;
    ok(!$b->in_check('b') && !$b->in_check('w'), 'nobody is in check at the start');
    ok($b->attacked(sq('7f'), 'b'), 'the pawn on 7g attacks 7f');
    ok($b->attacked(sq('7g'), 'b'), 'the bishop on 8h attacks 7g, its own pawn: attacked asks only who could move there');
    ok(!$b->attacked(sq('6g'), 'w'), 'White attacks nothing on rank g');
    ok(!$b->attacked(sq('5e'), 'b') && !$b->attacked(sq('5e'), 'w'), 'and nobody attacks 5e');
    ok(!$b->attacked(81, 'b') && !$b->attacked(0, 'x'), 'a square or a side that is not one is attacked by nobody');
}

# ---- the pin ---------------------------------------------------------------------

{
    my $b = $E->new(sfen => '4r4/9/9/9/9/9/9/4G4/4K4 b - 1');
    is_deeply([ sort grep { /^5h/ } $b->pseudo_moves ], [ sort qw(5h5g 5h4g 5h6g 5h4h 5h6h) ],
        'a gold pinned on the file by a rook has five pseudo-legal moves');
    is_deeply([ sort grep { /^5h/ } $b->board_moves ], ['5h5g'], 'and one legal: along the pin');
    is_deeply([ sort grep { /^5i/ } $b->board_moves ], [ sort qw(5i4h 5i6h 5i4i 5i6i) ],
        'while the king behind it moves freely');
}

# ---- the king may not take a defended piece -----------------------------------------

{
    my $b = $E->new(sfen => '9/9/9/9/9/9/5s3/4g4/4K4 b - 1');
    ok($b->in_check('b'), 'a gold on 5h checks the king on 5i');
    ok((grep { $_ eq '5i5h' } $b->pseudo_moves), 'the king could take it');
    is_deeply([ $b->board_moves ], [], 'but the silver on 4g defends it, and every square round is the gold\'s: no legal move');

    $b = $E->new(sfen => '9/9/9/9/9/9/9/4g4/4K4 b - 1');
    ok((grep { $_ eq '5i5h' } $b->board_moves), 'with no silver, the king takes the gold');
}

# ---- a promotion that uncovers check -------------------------------------------------

{
    my $b = $E->new(sfen => 'r8/9/S8/9/9/9/9/9/K8 b - 1');
    is_deeply([ sort grep { /^9c/ } $b->pseudo_moves ], [ sort qw(9c9b+ 9c9b 9c8b+ 9c8b 9c8d+ 9c8d) ],
        'a silver on 9c, between a rook and its king, has six pseudo-legal moves');
    is_deeply([ sort grep { /^9c/ } $b->board_moves ], [ sort qw(9c9b+ 9c9b) ],
        'only the two along the file are legal: promoting off the file uncovers check all the same');
}

# ---- check, and a side with no king -----------------------------------------------------

{
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4R4 w - 1');
    ok($b->in_check('w'), 'a rook on an open file checks the king at its end');
    ok(!(grep { /^5a5b/ } $b->board_moves), 'and the king may not step along the file');
    $b = $E->new(sfen => '4k4/9/9/9/4P4/9/9/9/4R4 w - 1');
    ok(!$b->in_check('w'), 'a pawn in between blocks it');

    $b = $E->new(sfen => '9/9/9/9/9/9/9/9/4R4 b - 1');
    ok(!$b->in_check('b') && !$b->in_check('w'), 'a side with no king is never in check');
    is_deeply([ sort $b->board_moves ], [ sort $b->pseudo_moves ], 'and has every pseudo-legal move');
}

# ---- P's positions where Black has no drop ------------------------------------------------
#
# P counts drops too. test_6 gives Black an empty hand, so its 4 is all board
# moves; test_3's total of 0 means there is no board move either. test_7's
# total is 1, so its board moves are at most one.

{
    my $b = $E->new(sfen => 'r7k/6K2/7SP/4s2bb/9/9/9/9/9 b r4g2s4n4l17p 1');
    is_deeply([ sort $b->board_moves ], [ sort qw(2c1d+ 2c1d 1c1b+ 1c1b) ], 'P test_6: the four moves P counts');
    $b = $E->new(sfen => '+R+N+SGKG+S+N+R/+B+N+SG+LG+S+N+B/P+LPP+LPP+LP/1P2P2P1/9/9/9/9/4k4 b 9P 200');
    is_deeply([ $b->board_moves ], [], 'P test_3: no board move');
    $b = $E->new(sfen => 'l7l/5bS2/p1np5/6Sk1/4p2B1/PSpPPn1G1/1P1G2g1N/2+l6/L1KN1+r3 b R3Pgs7p 1');
    cmp_ok(scalar(my @m = $b->board_moves), '<=', 1, 'P test_7: at most one board move');
}

# ---- attack against the generator, in real positions --------------------------------------
#
# Along random games from the start: the squares the side to move's moves
# reach are the squares it attacks that do not hold its own piece.

{
    srand(20261015);
    my ($positions, $bad, $reached) = (0, 0, 0);
    for my $game (1 .. 4) {
        my $b = $E->new;
        for my $ply (1 .. 120) {
            my $side = $b->side_to_move;
            my %reach = map { substr($_, 2, 2) => 1 } $b->pseudo_moves;
            my %hit;
            for my $sq (0 .. 80) {
                my $t = $b->at($sq);
                next if defined $t && (($t =~ /[a-z]/ ? 'w' : 'b') eq $side);
                $hit{ $E->square_name($sq) } = 1 if $b->attacked($sq, $side);
            }
            $positions++;
            $reached += keys %reach;
            $bad++ unless join(',', sort keys %reach) eq join(',', sort keys %hit);
            my @legal = $b->legal;
            last unless @legal;
            $b->do_move($legal[ int rand @legal ]) or die "a legal move was refused";
        }
    }
    is($bad, 0, "$positions positions from random games: the moves reach exactly the attacked squares");
    cmp_ok($reached, '>', $positions * 10, "  on $reached squares in all");
}

done_testing();
