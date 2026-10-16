use strict;
use warnings;
use utf8;
use Test::More;

use Game::Shogi::Notation;
my $E = 'Game::Shogi::Engine';
my $N = 'Game::Shogi::Notation';
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

sub jp { my ($sfen, $usi, %o) = @_; $N->japanese($E->new(sfen => $sfen), $usi, %o) }
sub hg { my ($sfen, $usi) = @_; $N->hodges($E->new(sfen => $sfen), $usi) }

# ---- N's eleven ambiguity diagrams ------------------------------------------------------
#
# plan_game_shogi/rules-wikipedia-notation-1373913454.txt, lines 328-680. Each
# diagram shows the board after the move, the moved piece marked with an l and
# the square it came from with an arrow; the positions below are those boards
# before the move. N's caption is the Japanese. The Hodges is N's own form for
# the three golds (G77-78 and the rest, line 66, ranks as letters) and worked
# from N's rules for the rest.

my $GOLDS   = '9/9/9/9/9/9/2G6/3G5/2G6 b - 1';     # L328-362: golds on 7g, 6h, 7i
my $BISHOPS = '9/9/9/5B3/9/9/9/1B7/9 b - 1';       # L401-418: bishops on 4d, 8h
my $SILVERS = '9/3GG4/9/9/9/3S1S3/9/9/9 b - 1';    # L459-493: golds 6b 5b, silvers 6f 4f
my $FOUR    = '9/9/9/9/9/3S1S3/9/3S1S3/9 b - 1';   # L571-605: silvers 6f 4f 6h 4h
my $PAIRS   = '9/9/9/3+R+R4/9/9/3SS4/9/9 b - 1';   # L644-661: dragons 6d 5d, silvers 6g 5g
my $SIDES   = '3g1g3/9/9/9/9/9/9/9/3G1G3';         # L532: golds 6i 4i and 6a 4a

my @DIAGRAMS = (
    [ $GOLDS,   '7g7h', '７八金引',   'G7g-7h', 'L328 引' ],
    [ $GOLDS,   '6h7h', '７八金寄',   'G6h-7h', 'L345 寄' ],
    [ $GOLDS,   '7i7h', '７八金上',   'G7i-7h', 'L362 上: straight forward, and still 上, not 直' ],
    [ $BISHOPS, '4d6f', '６六角引',   'B4d-6f', 'L401 引' ],
    [ $BISHOPS, '8h6f', '６六角上',   'B8h-6f', 'L418 上' ],
    [ $SILVERS, '4f5g', '５七銀右',   'S4f-5g', 'L459 右' ],
    [ $SILVERS, '6f5g', '５七銀左',   'S6f-5g', 'L476 左' ],
    [ $SILVERS, '6b5a', '５一金左',   'G6b-5a', 'L476 左 (N writes "5一金左", with an ASCII 5)' ],
    [ $SILVERS, '5b5a', '５一金直',   'G5b-5a', 'L493 直 (N writes "5一金直", with an ASCII 5)' ],
    [ $FOUR,    '6f5g', '５七銀左引', 'S6f-5g', 'L571 左引' ],
    [ $FOUR,    '6h5g', '５七銀左上', 'S6h-5g', 'L588 左上' ],
    [ $FOUR,    '4h5g', '５七銀右上', 'S4h-5g', 'L605 右上' ],
    [ $PAIRS,   '6g5f', '５六銀左',   'S6g-5f', 'L644 左' ],
    [ $PAIRS,   '6d5c', '５三龍左',   '+R6d-5c', 'L644 左' ],
    [ $PAIRS,   '5g5f', '５六銀直',   'S5g-5f', 'L661 直' ],
    [ $PAIRS,   '5d5c', '５三龍右',   '+R5d-5c', 'L661 右: a dragon is never 直' ],
    [ "$SIDES b - 1", '4i5h', '５八金右', 'G4i-5h', 'L532 Black\'s right (N\'s caption "☗５八右" leaves out the piece)' ],
    [ "$SIDES w - 1", '6a5b', '５二金右', 'G6a-5b', 'L532 White\'s right is Black\'s left' ],
);

# N's three golds turned round for White: golds on 3c, 4b and 3a reaching 3b.
# For White, 3c to 3b is backward (引) and 3a to 3b forward (上).
my $WGOLDS = '6g2/5g3/6g2/9/9/9/9/9/9 w - 1';
push @DIAGRAMS,
    [ $WGOLDS, '3c3b', '３二金引', 'G3c-3b', 'L328 turned for White: 引' ],
    [ $WGOLDS, '4b3b', '３二金寄', 'G4b-3b', 'L345 turned for White: 寄' ],
    [ $WGOLDS, '3a3b', '３二金上', 'G3a-3b', 'L362 turned for White: 上' ];

for my $d (@DIAGRAMS) {
    my ($sfen, $usi, $jp, $hodges, $where) = @$d;
    is(jp($sfen, $usi), $jp, "$where: $jp");
    is(hg($sfen, $usi), $hodges, "  and in Hodges, $hodges");
}

# ---- N's other examples -------------------------------------------------------------------

my $START = 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1';

is(hg($START, '8g8f'), 'P-8f', 'N line 15: "a typical move might be notated P-8f (Hodges)"');
is(jp($START, '8g8f'), '８六歩', 'N line 192: "８六歩 (equivalent to western P-86)"');

{
    my $log = $N->record(undef, qw(7g7f 3c3d 2g2f 4a3b));
    is(join('', map { $_->{japanese} } @{ $log->{moves} }), '▲７六歩△３四歩▲２六歩△３二金',
        'N line 198: "▲７六歩△３四歩▲２六歩△３二金"');
    is(join(' ', map { $_->{hodges} } @{ $log->{moves} }), 'P-7f P-3d P-2f G-3b', '  and in Hodges');
}

{
    # N line 210: "☗２四歩 ☖同歩 ☗同角 ☖同角 ☗同飛", western "1.P-24 Px24 2.Bx24
    # Bx24 3.Rx24". Black: pawn 2e, bishop 4f, rook 2h; White: pawn 2c,
    # bishop 4b.
    my $log = $N->record('4k4/5b3/7p1/9/7P1/5B3/9/7R1/4K4 b - 1', qw(2e2d 2c2d 4f2d 4b2d 2h2d));
    is(join('', map { $_->{japanese} } @{ $log->{moves} }), '▲２四歩△同歩▲同角△同角▲同飛',
        'N line 210: ２四歩 同歩 同角 同角 同飛, 同 for each recapture');
    is(join(' ', map { $_->{hodges} } @{ $log->{moves} }), 'P-2d Px2d Bx2d Bx2d Rx2d', '  and Px24 Bx24 Bx24 Rx24, ranks as letters');
    is(jp('4k4/5b3/7p1/9/7P1/5B3/9/7R1/4K4 b - 1', '2e2d', marks => 1, previous => '2d'), '▲同歩',
        '同 is the previous move\'s square, given');
}

{
    # N line 15: "S72x83+ or S7bx8c+"; line 192: "☗８三銀引成 (which could be
    # either S72-83+ or S72x83+)". Silvers on 7b and 9d both reach 8c: 7b
    # moving down (引), 9d moving up (上).
    my $s = '9/2S6/9/S8/9/9/9/9/9 b - 1';
    is(jp($s, '7b8c+', marks => 1), '▲８三銀引成', 'N line 192: ▲８三銀引成');
    is(hg($s, '7b8c+'), 'S7b-8c+', '  S72-83+');
    my $x = '9/2S6/1p7/S8/9/9/9/9/9 b - 1';
    is(jp($x, '7b8c+'), '８三銀引成', '  with a piece taken on 8c the Japanese is the same');
    is(hg($x, '7b8c+'), 'S7bx8c+', '  and the Hodges is S7bx8c+, N\'s five-part example');
    is(hg($x, '7b8c'), 'S7bx8c=', '  declining the promotion is =');
}

{
    # N line 167: "Nx73= ... Nx73+"; line 287: "７三桂成 (N-73+)", "７三桂不成 (N-73=)".
    my $s = '9/9/9/9/1N7/9/9/9/9 b - 1';
    is(jp($s, '8e7c+'), '７三桂成', 'N: ７三桂成');
    is(hg($s, '8e7c+'), 'N-7c+', '  N-73+');
    is(jp($s, '8e7c'), '７三桂不成', 'N: ７三桂不成');
    is(hg($s, '8e7c'), 'N-7c=', '  N-73=');
    my $x = '9/9/2p6/9/1N7/9/9/9/9 b - 1';
    is(hg($x, '8e7c'), 'Nx7c=', '  Nx73=, taking');
}

# ---- 打 only when a board piece could have gone there ----------------------------------------

{
    my $s = '9/9/9/9/9/9/9/4G4/9 b G 1';
    is(jp($s, 'G*5g'), '５七金打', 'a gold dropped where a gold on the board could go: 打');
    is(jp($s, '5h5g'), '５七金', '  and the board gold\'s move needs nothing');
    is(jp($s, 'G*1a'), '１一金', '  a drop no board gold could make: no 打');
    is(hg($s, 'G*5g'), 'G*5g', '  Hodges always writes the drop');
    is(jp('9/9/9/9/9/9/9/9/9 b P 1', 'P*2c'), '２三歩', 'N line 285: "P*23 will be notated simply as ２三歩"');
}

# ---- promotion only when possible, and forced ----------------------------------------------

is(jp($START, '7g7f'), '７六歩', 'a move that cannot promote says nothing of promotion');
is(hg('9/4P4/9/9/9/9/9/9/9 b - 1', '5b5a+'), 'P-5a+', 'a forced promotion is still written +');
is(jp('9/4P4/9/9/9/9/9/9/9 b - 1', '5b5a+'), '５一歩成', '  and 成');
is(jp('9/9/9/9/9/9/9/9/4k4 w - 1', '5i4i', marks => 1), '△４九玉', 'White\'s king, marked △');

# ---- what N's rules cannot settle ------------------------------------------------------------
#
# Three dragons in a row, the middle one moving straight up: every one moves
# 上, a dragon is never 直, and the middle one is neither the right nor the
# left. A real set has two rooks, so only put can make this board.

{
    my $b = $E->new(empty => 1);
    $b->put($E->square($_), '+R') for qw(6d 5d 4d);
    is($N->japanese($b, '5d5c'), '５三龍(54)', 'when no rule of N\'s settles it, the origin, as KIF writes it');
}

# ---- what is not a legal move -----------------------------------------------------------------

is(jp($START, '7g7e'), undef, 'a move that is not legal has no notation');
is(hg($START, 'x'), undef, '  nor does a string that is not a move');

done_testing();
