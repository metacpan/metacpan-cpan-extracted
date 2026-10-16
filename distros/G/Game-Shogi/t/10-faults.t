use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

sub fault { $E->new(sfen => $_[0])->move_fault($_[1]) }

my $START = 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1';
my $PIN   = '4r4/9/9/9/9/9/9/4G4/4K4 b - 1';

# ---- each fault ----------------------------------------------------------------------

my @FAULTS = (
    [ FAULT_OK,                  $START, '7g7f',  'a legal move' ],
    [ FAULT_OK,                  '4k4/9/9/9/9/9/9/9/4K4 b P 1', 'P*5e', 'a legal drop' ],
    [ FAULT_BAD,                 $START, 'x',     'not a move' ],
    [ FAULT_BAD,                 $START, '7g7g',  'a move to where it stands' ],
    [ FAULT_BAD,                 $START, 'K*5e',  'a king dropped' ],
    [ FAULT_BAD,                 $START, 'p*5e',  'a drop in lower case' ],
    [ FAULT_NOT_YOURS,           $START, '3c3d',  'White\'s pawn, on Black\'s turn' ],
    [ FAULT_NOT_YOURS,           $START, '5e5d',  'an empty square' ],
    [ FAULT_NOT_HELD,            $START, 'P*5e',  'a pawn not in hand' ],
    [ FAULT_CANNOT_REACH,        $START, '7g7e',  'a pawn two squares' ],
    [ FAULT_CANNOT_REACH,        $START, '8h7g',  'a bishop onto its own pawn' ],
    [ FAULT_CANNOT_REACH,        $START, '2h5e',  'a rook anywhere' ],
    [ FAULT_OCCUPIED,            '4k4/9/9/9/9/9/9/9/4K4 b P 1', 'P*5i', 'a pawn dropped on its own king' ],
    [ FAULT_PROMOTE_NOT_ALLOWED, $START, '7g7f+', 'a promotion outside the zone' ],
    [ FAULT_PROMOTE_NOT_ALLOWED, $START, '6i6h+', 'a gold promoting' ],
    [ FAULT_PROMOTE_REQUIRED,    'k8/4P4/9/9/9/9/9/9/4K4 b - 1', '5b5a', 'a pawn onto the last rank without promoting' ],
    [ FAULT_PROMOTE_REQUIRED,    'k8/9/9/4N4/9/9/9/9/4K4 b - 1', '5d4b', 'a knight onto the second rank without promoting' ],
    [ FAULT_DEAD,                '4k4/9/9/9/9/9/9/9/4K4 b P 1', 'P*3a', 'a pawn dropped on the last rank' ],
    [ FAULT_TWO_PAWNS,           '4k4/9/9/9/9/9/4P4/9/4K4 b P 1', 'P*5c', 'a second pawn on the file' ],
    [ FAULT_IN_CHECK,            $PIN,   '5h4g',  'a pinned gold off its file' ],
    [ FAULT_IN_CHECK,            '4r4/9/9/9/9/9/9/9/4K4 b G 1', 'G*3e', 'a drop that does not block a check' ],
    [ FAULT_PAWN_MATE,           '8k/6G2/7S1/9/9/9/9/9/9 b P 1', 'P*1b', 'a pawn dropped to give mate' ],
);

my %seen;
for my $f (@FAULTS) {
    my ($want, $sfen, $move, $what) = @$f;
    is(fault($sfen, $move), $want, "$what ($move): " . $E->fault_reason($want));
    $seen{$want}++;
}
is(scalar(keys %seen), FAULT_PAWN_MATE + 1, 'every fault code is reached by some move');
is($E->new->move_fault(undef), FAULT_BAD, 'undef is not a move');

my %reasons;
$reasons{ $E->fault_reason($_) }++ for FAULT_OK .. FAULT_PAWN_MATE;
is(scalar(keys %reasons), FAULT_PAWN_MATE + 1, 'every code has a reason of its own');
is($E->fault_reason(99), undef, 'and a code that is not one has none');

# ---- two faults: the one asked first ----------------------------------------------------

is(fault($PIN, '5h3h'), FAULT_CANNOT_REACH, 'pinned AND out of reach: the reach is asked first');
is(fault($PIN, '5h4g+'), FAULT_PROMOTE_NOT_ALLOWED, 'pinned AND a gold promoting: the promotion is asked first');
is(fault($START, '3c3d+'), FAULT_NOT_YOURS, 'not yours AND a promotion outside the zone: whose piece is asked first');
is(fault('4k4/9/9/9/9/9/6P2/9/4K4 b P 1', 'P*3a'), FAULT_DEAD, 'a dead drop AND a second pawn on the file: the dead drop first');
is(fault('4k4/9/9/9/9/9/9/9/4K4 b - 1', 'G*5i'), FAULT_NOT_HELD, 'not held AND onto a piece: not held first');
is(fault('4r4/9/9/9/9/9/6P2/9/4K4 b P 1', 'P*3e'), FAULT_TWO_PAWNS, 'a second pawn AND leaving a check: two pawns first');

# ---- move_fault agrees with legal --------------------------------------------------------
#
# On positions from random games, every candidate move: each of the side to
# move's pieces to every square, with a + and without, and every piece a hand
# can hold onto every square. A move is OK exactly when legal lists it.

{
    srand(20261015);
    my ($positions, $candidates, $bad, $ok) = (0, 0, 0, 0);
    my $b = $E->new;
    while ($positions < 30) {
        my %legal = map { $_ => 1 } $b->legal;
        my $side = $b->side_to_move;
        my @mine = grep { my $t = $b->at($_); defined $t && (($t =~ /[a-z]/) == ($side eq 'w')) } 0 .. 80;
        my @cand;
        for my $from (@mine) {
            for my $to (0 .. 80) {
                my $m = $E->square_name($from) . $E->square_name($to);
                push @cand, $m, "$m+";
            }
        }
        for my $l (qw(R B G S N L P)) {
            push @cand, map { "$l*" . $E->square_name($_) } 0 .. 80;
        }
        for my $m (@cand) {
            my $f = $b->move_fault($m);
            $candidates++;
            $ok++ if $f == FAULT_OK;
            $bad++ if ($f == FAULT_OK) != !!$legal{$m};
        }
        $positions++;
        my @moves = keys %legal;
        if (!@moves) { $b = $E->new; next }
        $b->do_move((sort @moves)[ int rand @moves ]);
    }
    is($bad, 0, "$candidates candidate moves in $positions positions: OK exactly for the legal ones");
    cmp_ok($ok, '>', $positions * 20, "  $ok of them OK, so the agreement is not on nothing");
}

done_testing();
