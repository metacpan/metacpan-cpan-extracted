use strict;
use warnings;
use Test::More;
use FindBin ();

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# THE LADDER IS CITED, NOT GENERATED. t/perft.txt is transcribed from
# https://www.chessprogramming.org/Chinese_Chess_Perft_Results (data by Patrice
# Duhamel and Nguyen Pham), fetched 25 Sep 2026. A baseline of our own counts
# would prove only that the code has not changed since the day it was wrong.
#
# FOUR COUNTERS AND NOT ONE, and what that actually buys was measured rather
# than assumed. It is NOT that a given bug shows on one column first: a cannon
# that captures adjacently reads 46 nodes and 4 captures at depth 1 against the
# true 44 and 2, so it moves both. What four columns buy is the case where THREE
# AGREE AND ONE DOES NOT, which says the generator is right and the accounting is
# ours. That happened here: mates was shifted by exactly one ply while nodes,
# checks and captures were exact everywhere, and a single-column ladder would
# have read as a bug in the cannon code.

my $FIXTURE = "$FindBin::Bin/perft.txt";

sub ladder {
    open my $fh, '<', $FIXTURE or die "cannot read $FIXTURE: $!";
    my (%fen, %want, $n);
    while (<$fh>) {
        next if /^\s*(#|$)/;
        if (/^P\s+(\d+)\s+(.+?)\s*$/)                   { $n = $1; $fen{$n} = $2 }
        elsif (/^D\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
            $want{$n}[$1] = [ $2, $3, $4, $5 ];
        }
    }
    return (\%fen, \%want);
}

my ($fen, $want) = ladder();
is(scalar keys %$fen, 11, 'eleven positions in the fixture');

# What runs in the ordinary suite, and why not more: depth 5 of the opening is
# 133 million nodes and 35 seconds on this machine, which belongs in xt/ and not
# in an installer's smoke test. Depth 4 everywhere is under a second in total.
my %RUN = (
    1 => 4, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 4,
    7 => 4, 8 => 4, 9 => 4, 10 => 4, 11 => 4,
);

for my $p (sort { $a <=> $b } keys %RUN) {
    subtest "position $p" => sub {
        my $b = $E->new(fen => $fen->{$p});
        ok($b, "loads: $fen->{$p}") or return;

        for my $d (1 .. $RUN{$p}) {
            my @got  = $b->perft($d);
            my @wish = @{ $want->{$p}[$d] };
            my @name = qw(nodes checks captures mates);

            if ("@got" eq "@wish") {
                pass("depth $d: @got");
                next;
            }
            # DIVIDE ON THE COUNTER THAT DISAGREES, NOT ON NODES. If captures
            # are wrong while nodes are right, the bug is a capture generated
            # as a quiet move or the reverse, and a node divide will not say so.
            for my $i (0 .. 3) {
                is($got[$i], $wish[$i], "depth $d $name[$i]");
            }
            diag("divide at depth $d, by root move:");
            my %div = $b->perft_divide($d);
            for my $mv (sort { $div{$b} <=> $div{$a} } keys %div) {
                diag(sprintf("  %d -> %d  (%d,%d) to (%d,%d)",
                    $mv, $div{$mv},
                    $E->file_of($E->move_from($mv)), $E->rank_of($E->move_from($mv)),
                    $E->file_of($E->move_to($mv)),   $E->rank_of($E->move_to($mv))));
            }
            last;
        }
    };
}

# The cheapest possible test of the cannon screen rule, and it needs no search:
# from the opening the ONLY captures available are cannon jumps, so a generator
# that lets a cannon take an adjacent piece, or take with no screen, gets this 2
# wrong before anything else exists.
subtest 'two captures at depth 1, and both are cannon jumps' => sub {
    my $b = $E->new;
    my @caps;
    for my $mv ($b->legal) {
        my $to = $E->move_to($mv);
        next if $b->at($to) == EMPTY;
        push @caps, $mv;
    }
    is(scalar @caps, 2, 'exactly two captures from the opening');

    for my $mv (@caps) {
        my ($from, $to) = ($E->move_from($mv), $E->move_to($mv));
        is(Game::Xiangqi::Engine::kind_of($b->at($from)), CANNON, 'the taker is a cannon');
        is(Game::Xiangqi::Engine::kind_of($b->at($to)), HORSE, 'and it takes a horse');
        is($b->cannon_screens($from, $to), 1, 'jumping exactly one screen');
        is($E->file_of($from), $E->file_of($to), 'straight up its own file');
    }

    # named, so a reader can check them on a board: the cannons on files b and h
    # take the black horses on the same files
    my %named = map {
        sprintf('%s%d-%s%d',
            ('a' .. 'i')[ $E->file_of($E->move_from($_)) ], $E->rank_of($E->move_from($_)),
            ('a' .. 'i')[ $E->file_of($E->move_to($_)) ],   $E->rank_of($E->move_to($_))) => 1
    } @caps;
    is_deeply([ sort keys %named ], [ 'b2-b9', 'h2-h9' ],
        'they are b2xb9 and h2xh9, the two cannon-takes-horse jumps');
};

# Nothing in the first five plies from the opening is a mate, so perft never
# exercises that branch in the shallow suite. That is the argument for the other
# ten positions rather than for a deeper ladder, and it is why phase 04 gets
# hand-built endings instead of leaning on this file.
subtest 'the mate branch is not exercised by the opening at all' => sub {
    my $b = $E->new;
    for my $d (1 .. 4) {
        my @got = $b->perft($d);
        is($got[3], 0, "depth $d finds no mate, as the source says");
    }
    my $p2 = $E->new(fen => $fen->{2});
    my @d4 = $p2->perft(4);
    is($d4[3], 23, 'position 2 at depth 4 finds the 23 the source names');
    cmp_ok($d4[3], '>', 0, 'so the mate branch IS reached, just not from the opening');
};

# THIS GUARD EXISTS BECAUSE THE SUITE ABOVE PASSED ON A BUG.
#
# Mates are counted at the LEAF ply only. A version that counted them at every
# node with no legal moves accumulated the shallower plies into the deeper rows,
# so position 2 at depth 5 read 1560 instead of 1537: the true count plus the 23
# that belong to depth 4. Every position above still passed, because none of
# them has a mate above the leaf ply within depth 4, and only xt/perft-deep.t
# caught it.
#
# A ladder is not enough on its own: the depths t/ can afford are the depths
# where the bug is invisible. This asserts the RULE instead of a number, and it
# costs nothing.
subtest 'mates are counted at the leaf ply and nowhere else' => sub {
    # 4k4/3RRR3/9/9/9/9/9/9/9/4K4 b: three red chariots abreast on rank 8. The
    # one on e8 gives check and the other two defend it along the rank, so the
    # general can neither take it nor step aside onto d9 or f9.
    #
    # THE RED GENERAL GOES ON e0 AND THAT IS NOT ARBITRARY. The first version of
    # this fixture put the chariots on rank 0 and the general on d1, where it
    # stood on its own chariot's file and blocked it, leaving d9 open. A mate
    # fixture that is not mate asserts nothing, and the general has to live on
    # d, e or f because the palace is those three files.
    my $b = $E->new(empty => 1);
    $b->put($E->point_of(4, 9), BLACK | GENERAL);
    $b->put($E->point_of(3, 8), RED | CHARIOT);
    $b->put($E->point_of(4, 8), RED | CHARIOT);
    $b->put($E->point_of(5, 8), RED | CHARIOT);
    $b->put($E->point_of(4, 0), RED | GENERAL);
    $b->set_side(BLACK);
    is($b->to_fen, '4k4/3RRR3/9/9/9/9/9/9/9/4K4 b - - 0 1', 'the fixture is the position it says');

    # scalar context gives a COUNT because Engine.pm makes it so. The XSUB
    # underneath is PPCODE and would hand back the last packed move instead.
    is(scalar($b->legal), 0, 'black has no legal move');
    my @none = $b->legal;
    is(scalar @none, 0, '  and the list agrees with the count');
    ok($b->in_check(BLACK), 'and is in check, so it is mate and not stalemate');

    my @d1 = $b->perft(1);
    is($d1[0], 0, 'depth 1 has no nodes, because there is no move to make');
    is($d1[3], 1, 'and one mate, counted at the leaf ply');

    # THE ASSERTION THAT CATCHES THE BUG. At depth 2 the leaf ply is ply 1, and
    # there are no ply-1 positions at all because the root has no moves. So the
    # root's mate must NOT be counted again. The accumulating version returns 1.
    my @d2 = $b->perft(2);
    is($d2[3], 0, 'depth 2 counts it ZERO times, not again');
    is($d2[0], 0, '  and still has no nodes');
    my @d3 = $b->perft(3);
    is($d3[3], 0, 'and depth 3 likewise');
};

done_testing();
