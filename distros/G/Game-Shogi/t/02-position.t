use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

my $live0 = $E->live;

my $START = 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1';
my $EMPTY = '9/9/9/9/9/9/9/9/9 b - 1';

# ---- the start ------------------------------------------------------------------------

{
    my $b = $E->new;
    is($b->sfen, $START, "the start is U's SFEN, byte for byte");
    is($b->side_to_move, 'b', 'Black to move');
    is($b->move_number, 1, 'move 1');
    is_deeply($b->hands, { b => {}, w => {} }, 'both hands empty');

    my (%count, $pieces);
    for my $sq (0 .. 80) {
        my $t = $b->at($sq);
        next unless defined $t;
        $pieces++;
        $count{$t}++;
    }
    is($pieces, SET_PIECES, 'forty pieces on the board');
    is_deeply(\%count, { P => 9, L => 2, N => 2, S => 2, G => 2, B => 1, R => 1, K => 1,
                         p => 9, l => 2, n => 2, s => 2, g => 2, b => 1, r => 1, k => 1 },
        'each side: nine pawns, two lances, knights, silvers and golds, a bishop, a rook and a king');
    is($b->at($E->square('7g')), 'P', 'a Black pawn on 7g');
    is($b->at($E->square('8h')), 'B', "Black's bishop on 8h");
    is($b->at($E->square('2h')), 'R', "Black's rook on 2h");
    is($b->at($E->square('2b')), 'b', "White's bishop on 2b");
    is($b->at($E->square('5e')), undef, '5e is empty');
    is($E->square_name($b->king_square('b')), '5i', "Black's king on 5i");
    is($E->square_name($b->king_square('w')), '5a', "White's king on 5a");
}

# ---- every SFEN in P and U, round trip --------------------------------------------------
#
# P is python-shogi's perft test (plan_game_shogi/perft-python-shogi-...txt):
# its positions include one with no Black king, so a side with no king loads.
# U is the USI document's own example, move 124 of a Ryu-O game.
#
# PINNED. Changing the zobrist generator, its seed or its fill order moves
# every one of these keys, and that must be a red test.

my @PINNED = (
    [ 'P start',  $START, '02c5ce3bde1899c6' ],
    [ 'P test_3', '+R+N+SGKG+S+N+R/+B+N+SG+LG+S+N+B/P+LPP+LPP+LP/1P2P2P1/9/9/9/9/4k4 b 9P 200', '24bd3d1ca3c74854' ],
    [ 'P test_4', 'R8/2K1S1SSk/4B4/9/9/9/9/9/1L1L1L3 b RBGSNLP3g3n17p 1', '60ee2044b44e0096' ],
    [ 'P test_5', '4k4/9/9/9/9/9/9/9/9 b 16P 1', 'c8388652faad3136' ],
    [ 'P test_6', 'r7k/6K2/7SP/4s2bb/9/9/9/9/9 b r4g2s4n4l17p 1', '170bf2cd5374d0d6' ],
    [ 'P test_7', 'l7l/5bS2/p1np5/6Sk1/4p2B1/PSpPPn1G1/1P1G2g1N/2+l6/L1KN1+r3 b R3Pgs7p 1', 'f909dd74adaad6ff' ],
    [ 'U move 124', '8l/1l+R2P3/p2pBG1pp/kps1p4/Nn1P2G2/P1P1P2PP/1PS6/1KSG3+r1/LN2+p3L w Sbgn3p 124', '8b779f92be331464' ],
    [ 'empty', $EMPTY, '0000000000000000' ],
);

for my $p (@PINNED) {
    my ($name, $sfen, $key) = @$p;
    my ($b, $code) = $E->from_sfen($sfen);
    is($code, POS_OK, "$name: loads") or next;
    is($b->sfen, $sfen, "$name: writes back byte for byte");
    is($b->key, $key, "$name: the pinned key");
    is($b->key, key_by_hand($b), "$name: the key is the XOR of its parts, worked in Perl");
}

{
    my ($b) = $E->from_sfen('4k4/9/9/9/9/9/9/9/9 b 16P 1');
    is($b->king_square('b'), undef, 'P test_5 has no Black king, and says so');
    is($E->square_name($b->king_square('w')), '5a', 'and the White king is on 5a');
    is($b->hand('b', 'P'), 16, 'Black holds sixteen pawns');
}

{
    my ($b) = $E->from_sfen($PINNED[6][1]);
    is_deeply($b->hands, { b => { S => 1 }, w => { B => 1, G => 1, N => 1, P => 3 } }, "U's hands, read");
    is($b->side_to_move, 'w', 'White to move');
    is($b->move_number, 124, 'move 124');
    is($b->at($E->square('7b')), '+R', 'a Black dragon on 7b');
    is($b->at($E->square('2h')), '+r', 'a White dragon on 2h');
}

# ---- what U leaves open, and what this reader decides --------------------------------

{
    my ($b, $code) = $E->from_sfen('lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b -');
    is($code, POS_OK, 'the move number may be left off: U calls it optional');
    is($b->move_number, 1, '  and is then 1');
    is($b->sfen, $START, '  and is always written');

    ($b, $code) = $E->from_sfen('4k4/9/9/9/9/9/9/9/9 b P2R 1');
    is($code, POS_OK, 'hands out of U\'s order load');
    is($b->sfen, '4k4/9/9/9/9/9/9/9/9 b 2RP 1', '  and are written in it');
}

# ---- each refusal -----------------------------------------------------------------------

my @REFUSED = (
    [ POS_NULL,    '' ],
    [ POS_NULL,    undef ],
    [ POS_LONG,    'x' x 256 ],
    [ POS_FIELDS,  'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL' ],
    [ POS_FIELDS,  "$START 1" ],
    [ POS_FIELDS,  'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL  b - 1' ],
    [ POS_FIELDS,  " $START" ],
    [ POS_FIELDS,  "$START " ],
    [ POS_RANKS,   '9/9/9/9/9/9/9/9 b - 1' ],
    [ POS_RANKS,   '9/9/9/9/9/9/9/9/9/9 b - 1' ],
    [ POS_LETTER,  '9/9/9/9/4X4/9/9/9/9 b - 1' ],
    [ POS_LETTER,  '9/9/9/9/0k8/9/9/9/9 b - 1' ],
    [ POS_LETTER,  '9/9/9/9/45/9/9/9/9 b - 1' ],
    [ POS_LETTER,  "9/9/9/9/4\tk3/9/9/9/9 b - 1" ],
    [ POS_WIDTH,   '9/9/9/9/8/9/9/9/9 b - 1' ],
    [ POS_WIDTH,   '9/9/9/9/9k/9/9/9/9 b - 1' ],
    [ POS_WIDTH,   '9/9/9/9/9/9/9/9/ b - 1' ],
    [ POS_PROMOTE, '9/9/9/9/4+G4/9/9/9/9 b - 1' ],
    [ POS_PROMOTE, '9/9/9/9/4+k4/9/9/9/9 b - 1' ],
    [ POS_PROMOTE, '9/9/9/9/9+/9/9/9/9 b - 1' ],
    [ POS_PROMOTE, '9/9/9/9/4++P4/9/9/9/9 b - 1' ],
    [ POS_SIDE,    '9/9/9/9/9/9/9/9/9 B - 1' ],
    [ POS_SIDE,    '9/9/9/9/9/9/9/9/9 bw - 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b K 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b +P 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b 1P 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b 0P 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b 02P 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b 19P 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b 3R 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b PP 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b P2 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b -P 1' ],
    [ POS_HAND,    '9/9/9/9/9/9/9/9/9 b X 1' ],
    [ POS_MOVE,    '9/9/9/9/9/9/9/9/9 b - 0' ],
    [ POS_MOVE,    '9/9/9/9/9/9/9/9/9 b - 01' ],
    [ POS_MOVE,    '9/9/9/9/9/9/9/9/9 b - 1000000' ],
    [ POS_MOVE,    '9/9/9/9/9/9/9/9/9 b - 1a' ],
    [ POS_MOVE,    '9/9/9/9/9/9/9/9/9 b - -1' ],
    [ POS_KINGS,   '4k4/9/9/9/9/9/9/9/3K1K3 b - 1' ],
    [ POS_KINGS,   'k3k4/9/9/9/9/9/9/9/9 b - 1' ],
    [ POS_COUNT,   'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b P 1' ],
    [ POS_COUNT,   'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b r 1' ],
    [ POS_COUNT,   'lnsgkgsnl/1r5b1/ppppppppp/9/9/4+R4/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1' ],
    [ POS_COUNT,   'lnsgkgsnl/1r5b1/ppppppppp/9/9/4+p4/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1' ],
);

for my $r (@REFUSED) {
    my ($want, $sfen) = @$r;
    my ($b, $code) = $E->from_sfen($sfen);
    my $show = defined $sfen ? (length $sfen > 60 ? substr($sfen, 0, 57) . '...' : $sfen) : 'undef';
    $show =~ s/\t/\\t/g;
    ok(!defined $b, "refused: '$show'");
    is($code, $want, '  for ' . $E->reason($want));
}

# THE ORDER. A string with two faults gives the one asked first.
{
    my (undef, $code) = $E->from_sfen('9/9/9/9/9/9/9/9/9 x K 0');
    is($code, POS_SIDE, 'a bad side, a bad hand and a bad move number: the side is asked first');
    (undef, $code) = $E->from_sfen('9/9/9/9/9/9/9/9/8 b - 1 2');
    is($code, POS_FIELDS, 'five fields and a short rank: the fields are asked first');
    (undef, $code) = $E->from_sfen('k3k4/9/9/9/9/9/9/9/9 b 18Pp 1');
    is($code, POS_KINGS, 'two kings and nineteen pawns: the kings are asked first');
}

my %reasons;
$reasons{ $E->reason($_) }++ for POS_OK .. POS_COUNT;
is(scalar(keys %reasons), POS_COUNT + 1, 'every code has a reason of its own');
is($E->reason(99), undef, 'and a code that is not one has none');

ok(!eval { $E->new(sfen => '9/9/9 b - 1'); 1 }, 'new(sfen => ...) croaks on a refused SFEN');
like($@, qr/the SFEN was refused: the board is not nine ranks/, '  with the reason');
ok(!eval { $E->new(_ptr => 12345); 1 }, 'a board cannot be made from a number');
like($@, qr/a board is made by new, from_sfen or clone/, '  and says how one is made');

# ---- the key ------------------------------------------------------------------------------

{
    my $b = $E->new;
    my $start = $b->key;

    $b->set_side_to_move('w');
    isnt($b->key, $start, 'the key names the side to move');
    $b->set_side_to_move('w');
    isnt($b->key, $start, '  and setting it twice is setting it once');
    $b->set_side_to_move('b');
    is($b->key, $start, '  and comes back when the turn does');

    $b->set_move_number(57);
    is($b->key, $start, 'the key does NOT name the move number');
    like($b->sfen, qr/ 57\z/, '  though the SFEN does');
    $b->set_move_number($_) for 0, MOVE_MAX + 1, -3, 'x';
    is($b->move_number, 57, 'a move number of 0, too large, negative or not a number is ignored');
    $b->set_move_number(1);

    my $sq = $E->square('7g');
    $b->lift($sq);
    isnt($b->key, $start, 'the key names each piece');
    $b->put($sq, 'p');
    my $white = $b->key;
    $b->put($sq, '+P');
    isnt($b->key, $white, '  which side it is');
    my $tokin = $b->key;
    $b->put($sq, 'P');
    isnt($b->key, $tokin, '  and whether it is promoted');
    is($b->key, $start, '  and a put over a piece takes the old one out of the key');
    $b->lift($E->square('5e'));
    is($b->key, $start, 'lifting an empty square changes nothing');
    $b->put($E->square('5e'), $_) for 'X', '+G', '+K', '', undef;
    $b->put(81, 'P');
    $b->put(-1, 'P');
    is($b->key, $start, 'a token or a square that is not one is ignored');
}

# THE HANDS ARE IN THE KEY. Two positions that differ only in a hand are two
# positions (W line 613: "the same pieces in hand for each player").
{
    my $b = $E->new(empty => 1);
    my $none = $b->key;
    is($none, '0000000000000000', 'an empty board with empty hands, Black to move, has the key 0');

    $b->set_hand('b', 'P', 1);
    my $one = $b->key;
    isnt($one, $none, 'a pawn in Black\'s hand changes the key');
    $b->set_hand('b', 'P', 2);
    isnt($b->key, $one, '  a second pawn changes it again');
    $b->set_hand('b', 'P', 1);
    is($b->key, $one, '  and taking it back restores it');
    $b->set_hand('b', 'P', 0);
    is($b->key, $none, '  and so does emptying the hand');

    $b->set_hand('w', 'P', 1);
    isnt($b->key, $one, 'a pawn in White\'s hand is not a pawn in Black\'s');
    $b->set_hand('w', 'P', 0);
    $b->set_hand('b', 'L', 1);
    isnt($b->key, $one, 'a lance in hand is not a pawn in hand');
    $b->set_hand('b', 'L', 0);

    for my $bad (['b', 'P', 19], ['b', 'R', 3], ['b', 'K', 1], ['b', '+P', 1], ['x', 'P', 1], ['b', 'P', -1], ['b', 'P', 'one']) {
        $b->set_hand(@$bad);
    }
    is($b->key, $none, 'a count past the set, a king, a promoted piece, a bad side or count: ignored');
    is_deeply($b->hands, { b => {}, w => {} }, '  and the hands are still empty');

    $b->set_hand('w', 'R', 2)->set_hand('b', 'P', 18);
    is($b->hand('w', 'r'), 2, 'a hand reads in either case');
    is($b->sfen, '9/9/9/9/9/9/9/9/9 b 18P2r 1', 'and is written Black first, rook first');
    is($b->key, key_by_hand($b), 'and the key is still the XOR of its parts');
}

{
    is($E->zobrist_hand('b', 'P', 0), '0000000000000000', 'an empty hand is all zeros');
    isnt($E->zobrist_hand('b', 'P', 1), '0000000000000000', 'a count of one is not');
    is($E->zobrist_hand('b', 'P', 19), '0000000000000000', 'a count past the set has no number');
    is($E->zobrist('b', 'K', 81), '0000000000000000', 'nor a square past the board');
    my %seen;
    for my $side (qw(b w)) {
        for my $t (qw(P L N S G B R K +P +L +N +S +B +R)) {
            $seen{ $E->zobrist($side, $t, $_) }++ for 0 .. 80;
        }
        for my $k (qw(P L N S G B R)) {
            $seen{ $E->zobrist_hand($side, $k, $_) }++ for 1 .. $E->set_count($k);
        }
    }
    $seen{ $E->zobrist_move }++;
    my $want = 2 * 14 * 81 + 2 * (18 + 4 * 4 + 2 * 2) + 1;
    is(scalar(keys %seen), $want, "all $want numbers the key is made of are different");
}

# ---- the kings ----------------------------------------------------------------------------

{
    my $b = $E->new;
    my $k = $b->king_square('b');
    $b->lift($k);
    is($b->king_square('b'), undef, 'lifting the king leaves Black without one');
    $b->put($E->square('4h'), 'K');
    is($E->square_name($b->king_square('b')), '4h', 'putting one back is found');
    $b->put($E->square('6h'), 'K');
    is($E->square_name($b->king_square('b')), '6h', 'a second king, which only put can make, is the one put last');
    $b->put($E->square('6h'), 'G');
    is($b->king_square('b'), undef, '  and putting a gold over it leaves the cache empty, as documented');
    is($b->king_square('x'), undef, 'a side that is not one has no king');
}

# ---- clones and lifetimes -------------------------------------------------------------------

{
    my $b = $E->new;
    my $c = $b->clone;
    is($c->key, $b->key, 'a clone has the same key');
    is($c->sfen, $b->sfen, '  and the same SFEN');
    $c->lift($E->square('7g'))->set_hand('b', 'P', 1);
    is($b->at($E->square('7g')), 'P', '  and is a board of its own');
    is($b->hand('b', 'P'), 0, '  with a hand of its own');

    my $built = $E->new(empty => 1);
    for my $sq (0 .. 80) {
        my $t = $b->at($sq);
        $built->put($sq, $t) if defined $t;
    }
    is($built->key, $b->key, 'a board built by puts has the key the constructor gives');
}

is($E->live, $live0, 'every board made in this file was let go');

done_testing();

# ---- the key worked by hand -------------------------------------------------------------
#
# Every piece's number, every hand count's number, and White to move, XORed in
# two halves of 32 bits so a perl with 32-bit integers gets the same answer.

sub key_by_hand {
    my ($b) = @_;
    my ($hi, $lo) = (0, 0);
    my $mix = sub {
        my ($hex) = @_;
        $hi ^= hex substr($hex, 0, 8);
        $lo ^= hex substr($hex, 8, 8);
    };
    for my $sq (0 .. 80) {
        my $t = $b->at($sq);
        next unless defined $t;
        my $side = $t =~ /[a-z]/ ? 'w' : 'b';
        $mix->($E->zobrist($side, $t, $sq));
    }
    for my $side (qw(b w)) {
        for my $k (qw(P L N S G B R)) {
            $mix->($E->zobrist_hand($side, $k, $b->hand($side, $k)));
        }
    }
    $mix->($E->zobrist_move) if $b->side_to_move eq 'w';
    return sprintf '%08x%08x', $hi, $lo;
}
