use strict;
use warnings;
use Test::More;

use Game::Shogi;
use Game::Shogi::Bot;
use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';
my $B = 'Game::Shogi::Bot';

sub mates_in_one {
    my ($b) = @_;
    for my $m ($b->legal) {
        $b->do_move($m);
        my $mate = $b->status eq 'mate';
        $b->undo_move;
        return $m if $mate;
    }
    return undef;
}

# ---- mates ---------------------------------------------------------------------------

{
    my $b = $E->new(sfen => '4k4/9/4P4/9/9/9/9/9/4K4 b G 1');
    my ($m, $info) = $b->search(nodes => 60_000, seed => 1);
    is($m, 'G*5b', 'a mate in one, a gold dropped on the king\'s head, is found');
    cmp_ok($info->{score}, '>', MATE_BOUND, '  and scored as a mate');
}

{
    # Found by a search over random sparse positions and proved here by the
    # rules alone, not by the search: no mate in one; after B*2b White has one
    # reply, and after it Black mates.
    my $sfen = '8k/9/1B5S1/7s1/9/9/9/9/4K4 b BP 1';
    my $b = $E->new(sfen => $sfen);
    is(mates_in_one($b), undef, 'a position with no mate in one');
    $b->do_move('B*2b');
    my @replies = $b->legal;
    my $all = @replies > 0;
    for my $r (@replies) {
        $b->do_move($r);
        $all = 0 unless mates_in_one($b);
        $b->undo_move;
    }
    ok($all, '  where after B*2b every White reply (' . scalar(@replies) . ') leaves Black a mate: a mate in three');
    $b->undo_move;

    my ($shallow, $i1) = $b->search(nodes => 1_000_000, depth => 1, seed => 1);
    cmp_ok($i1->{score}, '<', MATE_BOUND, 'searched one ply deep, no mate is seen');
    my ($m, $i3) = $b->search(nodes => 2_000_000, depth => 3, seed => 1);
    is($m, 'B*2b', 'three plies deep, the search plays B*2b');
    cmp_ok($i3->{score}, '>', MATE_BOUND, '  and scores it a mate');
}

{
    my $b = $E->new(sfen => '+R+N+SGKG+S+N+R/+B+N+SG+LG+S+N+B/P+LPP+LPP+LP/1P2P2P1/9/9/9/9/4k4 b 9P 200');
    is(scalar $b->search(nodes => 1000), undef, 'a side with no legal move has no move to play');
}

# ---- material ---------------------------------------------------------------------------

{
    my $b = $E->new(sfen => '4k4/9/9/9/4r4/9/9/1B7/4K4 b - 1');
    is(scalar $b->search(nodes => 60_000, seed => 3), '8h5e', 'a rook left hanging is taken');
}

# ---- the budget and the seed ------------------------------------------------------------

{
    my $b = $E->new;
    my $sfen = $b->sfen;
    for my $budget (400, 6_000, 60_000) {
        my (undef, $info) = $b->search(nodes => $budget, seed => 5);
        cmp_ok($info->{nodes}, '<=', $budget + 2_000, "a budget of $budget is kept to within one horizon\'s mate search");
    }
    is($b->sfen, $sfen, 'searching leaves the board as it was');
    is(scalar $b->search(nodes => 6_000, seed => 9), scalar $b->search(nodes => 6_000, seed => 9),
        'the same seed plays the same move');
    my %moves = map { (scalar $b->search(nodes => 400, seed => $_)) => 1 } 1 .. 30;
    cmp_ok(scalar(keys %moves), '>', 1, 'different seeds share the opening\'s equal moves out: ' . join(' ', sort keys %moves));
    ok(!eval { $b->search(nodes => 0); 1 }, 'a budget of 0 is refused');
}

# ---- a position the game has stood in is a draw, scored against the searcher -----------

{
    my $b = $E->new(sfen => '4k3g/9/9/9/9/9/9/9/K4R3 b - 1');
    my @after;
    for my $m ($b->legal) {
        my $c = $b->clone;
        $c->do_move($m);
        push @after, $c->key;
    }
    my (undef, $free) = $b->search(nodes => 50_000, depth => 1, seed => 1, history => []);
    my (undef, $all)  = $b->search(nodes => 50_000, depth => 1, seed => 1, history => \@after);
    isnt($free->{score}, -50, 'with no history, the best move scores what the evaluation says');
    is($all->{score}, -50, '  with every move\'s position already stood in, the best scores -50: a draw, held against the searcher');
}

# ---- every move it plays is legal ------------------------------------------------------------

{
    srand(20261015);
    my ($bad, $n) = (0, 0);
    my $b = $E->new;
    for (1 .. 120) {
        my @legal = $b->legal;
        last unless @legal;
        my %ok = map { $_ => 1 } @legal;
        my $m = $b->search(nodes => 2_000, seed => $n);
        $bad++ unless defined $m && $ok{$m};
        $n++;
        $b->do_move($legal[ int rand @legal ]);
    }
    is($bad, 0, "$n searches along a random game, every move legal");
}

# ---- the evaluation ------------------------------------------------------------------------------

{
    is($E->new->evaluate, 0, 'the start is level');
    my $b = $E->new(sfen => 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/1PPPPPPPP/1B5R1/LNSGKGSNL b P 1');
    cmp_ok($b->evaluate, '>', 0, 'Black\'s 9g pawn taken into hand: worth more there than on the board');
    cmp_ok($b->evaluate, '>', $b->evaluate(EVAL_NO_HAND_BONUS), '  and more than a pawn on the board would be');
    my $w = $E->new(sfen => 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/1PPPPPPPP/1B5R1/LNSGKGSNL w P 1');
    is($w->evaluate, -$b->evaluate, 'the score is the side to move\'s');
    my $k = $E->new(sfen => '4k4/9/9/9/9/9/9/4G4/4K4 b - 1');
    cmp_ok($k->evaluate, '>', $k->evaluate(EVAL_NO_KING_SAFETY) - 600, 'a gold beside the king is worth more than a gold');
    my $e = $E->new(sfen => '4K4/9/9/9/4k4/9/9/9/9 b - 1');
    cmp_ok($e->evaluate, '>', $e->evaluate(EVAL_NO_ENTERING), 'a king in the enemy camp is worth something');
}

# ---- the bot -----------------------------------------------------------------------------------

{
    is_deeply(\@Game::Shogi::Bot::LADDER, [ 400, 6_000, 60_000, 300_000 ], 'four rungs, weakest first');
    my %rung = map { $B->level_for($_) => 1 } 1 .. 200;
    is_deeply([ sort { $a <=> $b } keys %rung ], [ 400, 6_000, 60_000, 300_000 ], 'every rung is drawn by some seed');
    is($B->level_for('x'), $B->level_for('x'), 'one seed draws one rung');
    isnt($B->tiebreak_seed(1, 'b'), $B->tiebreak_seed(1, 'w'), 'the side is in the tie-break');
    {
        local $Game::Shogi::Bot::LEVEL = 400;
        is($B->level_for('anything'), 400, '$LEVEL pins the rung');
    }
    my $g = Game::Shogi->new;
    is($B->choose($g, 'w', seed => 1), undef, 'not White\'s turn: no move');
    my $m = $B->choose($g, 'b', seed => 1, nodes => 2_000);
    ok((grep { $_->usi eq $m } $g->legal), "Black's move, $m, is legal");
    ok(defined $B->hint($g, 'b'), 'a hint is a move');
    ok(!$B->declares($g, 'b'), 'nobody declares at the start');
    ok($B->declares(Game::Shogi->new(sfen => 'RRBB1GGGG/4K1SS1/9/9/9/9/9/9/4k4 b 2P 1'), 'b'), 'a bot that may declare does');
}

# ---- what the search does that the mutation run asked for --------------------------------

{
    # P's test_3 turned round and the colours swapped: whatever Black plays,
    # White is left with no legal move and is not in check. Only a node that is
    # not the horizon sees that, so one ply finds nothing and two find a win.
    my $b = $E->new(sfen => '5K3/9/9/9/9/1p2p2p1/p+lpp+lpp+lp/+b+n+sg+lg+s+n+b/+r+n+sgkg+s+n+r b 9p 1');
    my (undef, $one) = $b->search(nodes => 200_000, depth => 1, seed => 1, history => []);
    my (undef, $two) = $b->search(nodes => 200_000, depth => 2, seed => 1, history => []);
    cmp_ok($one->{score}, '<', 0, 'leaving the opponent no move, not in check: one ply sees only the material');
    cmp_ok($two->{score}, '>', MATE_BOUND, '  two plies see the win: no legal move is a loss, not a draw');
}

{
    # A rook facing a pawn a gold defends. One ply deep, quiescence sees the
    # gold take back; without it the pawn looks free.
    my $b = $E->new(sfen => 'k8/4g4/4p4/9/9/9/9/9/4R3K b - 1');
    my @took = grep { /^5i5[cd]/ } map { scalar $b->search(nodes => 200_000, depth => 1, seed => $_, history => []) } 1 .. 5;
    is_deeply(\@took, [], 'a defended pawn is left alone one ply deep: quiescence sees the recapture');
}

{
    # A budget too small to finish even the first iteration still plays the
    # best root move it finished. The dragon taking a gold-defended silver is
    # ordered first (the bigger victim) and loses the dragon; the silver taking
    # an undefended pawn comes second.
    my $b = $E->new(sfen => 'k8/4g4/4s4/6p2/4+R1S2/9/9/9/K8 b 2B3G2S4N4L17P 1');
    my ($m, $info) = $b->search(nodes => 100, seed => 1, history => []);
    is($info->{depth}, 0, 'a budget of 100 finishes no iteration of 435 moves');
    is($m, '3e3d', '  and still plays the better of the two moves it finished, not the first in order');
}

{
    # The ordering decides the depth: drops are most of the moves and most are
    # bad. Over twenty positions from random games with full hands, the mean
    # depth reached at 60,000 nodes; drops ordered first reached 1.5 (measured
    # 15 Oct 2026), this ordering 2.3.
    my @twenty = (
        'rn1+N3n1/3P1k1pL/+N1p2p1P1/1b1gpsP2/3p2p1P/PPP1sPl2/1+B6S/1+lSG3R1/3K2G1L w G3Pp 136',
        'rn1+N5/3P1k1pL/+N1p2pnP1/1b1gpsP2/3p2p1P/PpP1sPl2/1+B5RS/1+lSG5/3K2G1L b 3Pgp 141',
        'rn1+N5/3PPk1pL/+N1p2pnP1/1b1gpsP2/3p2p1P/PpP1sP3/1+B5RS/1+lSKG1+l2/6G1L w 2Pgp 146',
        '1n1+N+P4/r2P3pL/+N1p1kpPP1/1b1gps3/3p1Pp1P/PpP1s4/1+B2G2+lS/+l1SKP4/2g2N1GL b Prp 161',
        '1n1+N+P4/+N2P3pL/2p1kpPP1/1b1gps3/5Pp1P/PpPps4/1+B1rG2+lS/+l1S1P3L/2K2N1G1 w RGPp 166',
        '1n1+N+P4/+N2P3pL/2p1kpPP1/1b1gps3/5Pp1P/P1Pps2G1/p+pr1G2+lS/+l1S1P3L/2K2NG2 b RPb 171',
        'gnk1p2nl/3r1ss2/lpps+P1P1p/3p4P/pP6L/2K2pGp1/P1bRP1NP1/LBG6/1NS6 b Pg2p 111',
        'gnk1p2nl/3r1ss2/lpps+P1P1P/3p5/pP6L/2K2pGp1/P3P1NP1/LB1G2g2/1NSR5 w B2P2p 116',
        'gn2p2nl/k2rs1G2/lpp3P1P/5s3/pP1p4L/2G2pGp1/P1K1P1NPp/LB7/1NS2R1B1 b S2P2p 131',
        'gn2p2nl/k2rs1G2/lpp3P1P/9/pP1p2G1L/2G4p1/P3P+pNPp/LBK6/1NSP1R1B1 w 2SP2p 136',
        'gn2p3l/k2rs1G1+P/lpp2nn2/9/pP1p2G1L/2G4p1/P3P1+pPp/LBK2S3/1NSP1R1B1 b SP3p 141',
        'gn2ps1pl/k7+P/lpp3r1G/5N3/pP1pn3L/G4p+p2/P1P1P1p1p/LBK4+p1/SNSP1R1B1 b gsp 161',
        'gn2ps1pl/k7+P/lpp3r2/5N2G/pP1pn3L/G3BR+p1g/P1P1P1p2/LBK4+pp/SNSP5 w Psp 166',
        'ln5nl/4Ps1g1/2ps1k2p/1pg1pB1p1/1P1p2p2/5PPPP/+r1PPGS2L/B2R5/L1SGK2N1 b 2Pnp 71',
        'ln5nl/4Psng1/2ps1k2p/1pg4p1/1P1pp1p2/4SPPPP/+r1PPG3L/B6R1/L1SGK2N1 w 2Pbp 76',
        '1n3+P2l/6s1g/ls5kp/b1pp1P3/P2PS1PPP/1pN3pp1/4GGNRL/B3P4/L+rG1K4 w 3Psnp 176',
        '5p+N2/2g1ks1r1/1s3Pbp1/lpnplg2P/p2Np1p2/P2PP2P1/+n1+p5G/1+s3RG1L/L3K3S w B2P2p 116',
        '5p3/2g1ks+Nr1/1sp2Pbp1/lpnplg2P/p2Np1p2/+n2PPR1P1/1+s+p5G/6G1L/L3K3S b B2P2p 121',
        '3k1p3/2g2s+N2/1sp2P1p1/lpn1lg1br/p2pP1p2/+n2P1R1P1/1+s+p5G/P4BGSL/L1P1K4 b Pn3p 131',
        '3k1p3/2g2s+N2/1sp2P1pb/lp2lg2P/p2pPRp2/+nn1P3P1/1+s+p5G/P4BGSL/L1P1K4 w Rn3p 136',
    );
    my $depth = 0;
    for my $sfen (@twenty) {
        my (undef, $info) = $E->new(sfen => $sfen)->search(nodes => 60_000, seed => 1, history => []);
        $depth += $info->{depth};
    }
    cmp_ok($depth / @twenty, '>=', 2.0, sprintf('twenty hand-heavy positions reach a mean depth of %.2f at 60,000 nodes', $depth / @twenty));
}

{
    # The bot hands the game's history to the search. Kings and a gold each,
    # the golds shuffled twice: at the start again, 5h4h walks back into the
    # cycle. Without the history some seeds pick it; through the bot none do.
    my (%bot, %bare);
    for my $seed (1 .. 40) {
        my $g = Game::Shogi->new(sfen => '4k4/4g4/9/9/9/9/9/4G4/4K4 b - 1');
        $g->play($_) for (qw(5h4h 5b4b 4h5h 4b5b)) x 2;
        $bot{ $B->choose($g, 'b', seed => $seed, nodes => 20_000) }++;
        $bare{ scalar $g->board->search(nodes => 20_000, seed => $B->tiebreak_seed($seed, 'b'), history => []) }++;
    }
    ok($bare{'5h4h'}, "with no history, $bare{'5h4h'} of 40 seeds walk back into the cycle with 5h4h");
    ok(!$bot{'5h4h'}, '  through the bot, which passes the game\'s history, none do');
}

done_testing();
