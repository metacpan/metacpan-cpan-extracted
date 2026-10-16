use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

# THE FLOORS FROM B. George I. Bell, "The shortest game of Chinese Checkers and
# related problems", INTEGERS 9 (2009) #G01, arXiv:0803.1245, the abstract:
#   - no co-operative two-player game is shorter than 30 moves, 15 each;
#   - no one-player crossing of ten pieces is shorter than 27 moves.
# B proves both for exactly these rules, the stop optional included. A move
# generator that is too generous (a hop over two pieces, a step after a hop)
# lets a strong enough player beat them. This catches that; the twins, not
# this, show the generator is complete.

# ---- one seat crossing alone, by a beam search ---------------------------------------------
#
# Each round keeps the WIDTH positions nearest home (by distance left, then by
# key so the run is repeatable) and tries every move of each. Measured 15 Oct
# 2026: width 60 finds 45 moves, 200 finds 32 (1.4 s), 1,000 finds 29 (8.6 s),
# 3,000 still 29 (36 minutes). 200 is near enough to 27 to notice a shortcut.

sub crossing {
    my ($width, $rounds) = @_;
    my @beam = ($E->new(seats => 1, pieces => 10));
    for my $round (1 .. $rounds) {
        my (%seen, @next);
        for my $bd (@beam) {
            for my $m ($bd->legal) {
                my $c = $bd->clone;
                $c->play(@$m);
                return $round if $c->over;
                next if $seen{ $c->key }++;
                push @next, [ $c->distance_left(0), $c->key, $c ];
            }
        }
        @next = sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] } @next;
        @beam = map { $_->[2] } @next[0 .. ($#next < $width - 1 ? $#next : $width - 1)];
    }
    return undef;
}

my $solo = crossing(200, 60);
ok(defined $solo, 'one seat crosses alone, found by a beam of 200');
cmp_ok($solo, '>=', 27, "  in $solo moves, never fewer than B's 27");
cmp_ok($solo, '<=', 34, '  and within 34, so the search is strong enough to have noticed a shortcut');

# ---- two seats, each racing greedily ---------------------------------------------------------
#
# Each seat takes a move that brings it nearest home, ties broken by the seed.
# No seat may finish in fewer than 15 of its own moves (B's 30, shared).

srand 20261021;
my ($games, $shortest) = (0, 1e9);
for (1 .. 40) {
    my $bd = $E->new(seats => 2);
    my @moves = (0, 0);
    while (!$bd->over) {
        my $s = $bd->to_move;
        my ($best, $at);
        my @l = $bd->legal;
        for my $i (0 .. $#l) {
            my $j = $i + int rand(@l - $i);
            @l[ $i, $j ] = @l[ $j, $i ];
        }
        for my $m (@l) {
            my $c = $bd->clone;
            $c->play(@$m);
            my $d = $c->distance_left($s);
            ($best, $at) = ($d, $m) if !defined $best || $d < $best;
        }
        $at ? $bd->play(@$at) : $bd->pass;
        $moves[$s]++;
    }
    $games++;
    for my $s (0, 1) {
        $shortest = $moves[$s] if $bd->place_of($s) == 1 && $moves[$s] < $shortest;
    }
}
is($games, 40, '40 two-seat games between greedy seats');
cmp_ok($shortest, '>=', 15, "  the quickest winner took $shortest moves, never fewer than B's 15");

done_testing();
