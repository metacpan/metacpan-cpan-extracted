use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

my $START = 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1';

# ---- P: python-shogi's perft test, commit a814cbf ------------------------------------
#
# plan_game_shogi/perft-python-shogi-a814cbf-2026-10-14.txt. Every count, with
# the drops in it: test_3's 0 has nine pawns in hand, test_4's 593 is mostly
# drops, test_5 is a lone king against sixteen pawns in hand.

my @P = (
    [ 'start',  $START, 1, 30 ],
    [ 'start',  $START, 2, 900 ],
    [ 'test_3', '+R+N+SGKG+S+N+R/+B+N+SG+LG+S+N+B/P+LPP+LPP+LP/1P2P2P1/9/9/9/9/4k4 b 9P 200', 1, 0 ],
    [ 'test_4', 'R8/2K1S1SSk/4B4/9/9/9/9/9/1L1L1L3 b RBGSNLP3g3n17p 1', 1, 593 ],
    [ 'test_5', '4k4/9/9/9/9/9/9/9/9 b 16P 1', 1, 72 ],
    [ 'test_5', '4k4/9/9/9/9/9/9/9/9 b 16P 1', 2, 355 ],
    [ 'test_6', 'r7k/6K2/7SP/4s2bb/9/9/9/9/9 b r4g2s4n4l17p 1', 1, 4 ],
    [ 'test_7', 'l7l/5bS2/p1np5/6Sk1/4p2B1/PSpPPn1G1/1P1G2g1N/2+l6/L1KN1+r3 b R3Pgs7p 1', 1, 1 ],
);

for my $p (@P) {
    my ($name, $sfen, $depth, $want) = @$p;
    my $b = $E->new(sfen => $sfen);
    is($b->perft($depth), $want, "P $name, depth $depth: $want");
    is($b->sfen, $sfen, '  and perft leaves the board as it was');
}

{
    my $b = $E->new(sfen => $P[3][1]);
    my @legal = $b->legal;
    my %seen;
    $seen{$_}++ for @legal;
    is(scalar(keys %seen), 593, 'the 593 are 593 different moves');
    is(scalar(grep { /\*/ } @legal), scalar $b->drops, '  drops among them');
}

# ---- D: Duhamel's table, TalkChess 2016 ------------------------------------------------
#
# plan_game_shogi/perft-talkchess-duhamel-2016-06-12.txt. Every column, which
# is what makes it worth more than a count: at depth 3 the 59 captures, the 30
# promotions and the 48 checks are each a separate thing to get right.
# Depth 5, the first with drops, is in xt/perft-deep.t.

my @D = (
    [ 1, 30,      0,    0, 0,   0,    0 ],
    [ 2, 900,     0,    0, 0,   0,    0 ],
    [ 3, 25470,   59,   0, 30,  48,   0 ],
    [ 4, 719731,  1803, 0, 842, 1121, 0 ],
);

for my $d (@D) {
    my ($depth, @want) = @$d;
    my $c = $E->new->perft_counts($depth);
    is_deeply([ @$c{qw(nodes captures drops promotions checks mates)} ], \@want,
        "D depth $depth: nodes $want[0], captures $want[1], drops $want[2], promotions $want[3], checks $want[4], mates $want[5]");
}

# ---- perft's edges ---------------------------------------------------------------------

is($E->new->perft(0), 1, 'depth 0 is the board itself: one node');
is($E->new->perft($_), 0, "depth '$_' counts nothing") for -1, 'x', '';
is($E->new(sfen => $P[2][1])->perft(3), 0, 'a position with no legal move has no perft at any depth');

done_testing();
