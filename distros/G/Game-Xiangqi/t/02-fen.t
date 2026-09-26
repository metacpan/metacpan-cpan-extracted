use strict;
use warnings;
use Test::More;

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# The opening position as the two oracles spell it. THE SAME AUTHOR PUBLISHES
# BOTH: the Chess Programming Wiki's Chinese Chess perft page writes the horse h
# and the elephant e, and Maksim Korzh's TalkChess post of the same table writes
# them n and b after chess's knight and bishop. A reader that takes one
# convention cannot load half the oracles there are, and it fails in the bad
# way: the position does not parse, the test skips, and the suite is green.
my $HE = 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR w - - 0 1';
my $NB = 'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';

subtest 'the oracle FEN loads, in both conventions, to the same position' => sub {
    my $h = $E->new(fen => $HE);
    my $n = $E->new(fen => $NB);
    ok($h, 'the h/e spelling loads');
    ok($n, 'the n/b spelling loads');

    is($h->key_hex, $n->key_hex, 'both spellings give the identical position');
    for my $pt ($E->all_points) {
        next if $h->at($pt) == $n->at($pt);
        fail("point $pt differs between the two spellings");
        last;
    }
    pass('every point agrees');

    my $fresh = $E->new;
    is($h->key_hex, $fresh->key_hex, 'and it is the position board_new builds');
};

subtest 'the writer emits h and e, and what it writes reloads' => sub {
    my $b = $E->new;
    my $fen = $b->to_fen;
    like($fen, qr{\Arheakaehr/}, 'the writer spells the horse h and the elephant e');
    unlike($fen, qr{rnbakabnr}, 'and not chess-s knight and bishop');
    like($fen, qr/ w /, 'Red to move');

    my $again = $E->new(fen => $fen);
    ok($again, 'a written FEN reloads');
    is($again->to_fen, $fen, 'and writes the same string a second time');
    is($again->key_hex, $b->key_hex, 'and is the same position');
};

subtest 'the side field, and b really is black to move' => sub {
    my $b = $E->new(fen => 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR b');
    is($b->side, BLACK, 'b is Black');
    my $r = $E->new(fen => 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR r');
    is($r->side, RED, 'r is Red, which much of the xiangqi world writes');
    my $w = $E->new(fen => 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR w');
    is($w->side, RED, 'and so is w, which the perft sources write');

    isnt($b->key_hex, $r->key_hex,
        'the side is IN THE KEY, so the same board with the other player to move is a different position');
};

subtest 'a FEN with no side field defaults to Red and says nothing else' => sub {
    my $b = $E->new(fen => 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR');
    ok($b, 'the board alone is enough to load');
    is($b->side, RED, 'and a board with no side field is Red to move');
};

# ---- the refusals ------------------------------------------------------------
#
# Six of them, each named, because "that FEN is bad" is not something a caller
# can act on. A refusal is a code and never a croak.

subtest 'six malformed FENs are refused with a code, not a crash' => sub {
    my @bad = (
        [ '',                                                                FEN_NULL,   'the empty string' ],
        [ 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9',               FEN_ROWS,   'nine rows' ],
        [ 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR',   FEN_ROWS,   'eleven rows' ],
        [ 'rheakaehrr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR',    FEN_WIDTH,  'a row of ten' ],
        [ 'rheakaeh/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR',      FEN_WIDTH,  'a row of eight' ],
        [ 'rheakaexr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR',     FEN_LETTER, 'a letter that names no piece' ],
        [ 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR x',   FEN_SIDE,   'a side field that is not w, r or b' ],
    );
    for my $case (@bad) {
        my ($fen, $want, $why) = @$case;
        my ($b, $err) = $E->of_fen($fen);
        is($b, undef, "refused: $why");
        is($err, $want, "  and the code names it");
    }

    my ($long) = $E->of_fen('r' x 200);
    is($long, undef, 'refused: longer than the buffer');

    # the one that matters most: none of the above took the process with it
    pass('and the process is still here, so every refusal was a return');
};

subtest 'a position that is not the opening still round-trips' => sub {
    # phase 03 will pin eleven of these from the wiki. One is enough here to
    # show the reader and the writer agree away from the start.
    my $fen = '2bakab2/9/2n1c1n2/p1p1p1p1p/9/9/P1P1P1P1P/1C2C4/9/RNBAKABNR w';
    my $b = $E->new(fen => $fen);
    ok($b, 'a middlegame position loads');
    my $out = $b->to_fen;
    my $back = $E->new(fen => $out);
    is($back->key_hex, $b->key_hex, 'what the writer wrote is the same position');
    is($back->to_fen, $out, 'and it is stable on a second pass');
};

done_testing();
