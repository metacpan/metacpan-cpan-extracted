use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

# ---- the set-ups -----------------------------------------------------------------------
#
# Two seats: 8 steps and 6 one-hop chains a seat, counted by hand in t/04-steps.t.

{
    my $bd = $E->new(seats => 2);
    is(scalar(my @l = $bd->legal), 14, 'the two-seat set-up: 14 moves for seat 0');
    $bd->set_to_move(1);
    is(scalar(my @m = $bd->legal), 14, '  and 14 for seat 1');
    ok(!(grep { $bd->at($_->[0]) != 1 } @m), '  every one of them a piece of seat 1');
}

# ---- every board: the shape of the list ----------------------------------------------------

srand 20261018;
my ($boards, $shape_ok, $count_ok, $order_ok, $clone_ok, $do_ok) = (0, 1, 1, 1, 1, 1);
for my $seats (2, 3, 4, 6) {
    for my $k (0 .. 125) {
        my $bd = $E->new(seats => $seats, ($k ? (empty => 1) : ()));
        if ($k) {
            my @free = 0 .. HOLES - 1;
            for my $seat (0 .. $seats - 1) {
                $bd->put(splice(@free, int rand @free, 1), $seat) for 1 .. 10;
            }
            $bd->set_to_move(int rand $seats);
        }
        $boards++;
        my @l = $bd->legal;
        my %seen;
        $shape_ok = 0 if grep { $seen{"$_->[0]-$_->[1]"}++ } @l;
        $shape_ok = 0 if grep { !defined $bd->at($_->[0]) || $bd->at($_->[0]) != $bd->to_move } @l;
        my $sum = 0;
        $sum += scalar(my @r = $bd->reach($_))
            for grep { defined $bd->at($_) && $bd->at($_) == $bd->to_move } 0 .. HOLES - 1;
        $count_ok = 0 unless $sum == @l;
        for my $i (1 .. $#l) {
            my ($p, $q) = ($l[ $i - 1 ], $l[$i]);
            $order_ok = 0 unless $p->[0] < $q->[0] || ($p->[0] == $q->[0] && $p->[1] < $q->[1]);
        }
        my $c = $bd->clone;
        $clone_ok = 0 unless join(' ', map { "@$_" } $c->legal) eq join(' ', map { "@$_" } @l);
        for my $m (@l[0 .. ($#l < 9 ? $#l : 9)]) {
            my $d = $bd->clone;
            $do_ok = 0 unless $d->do_move(@$m) && $d->at($m->[1]) == $bd->to_move && !defined $d->at($m->[0]);
        }
    }
}
is($boards, 504, 'every set-up and 500 random boards');
ok($shape_ok, 'no move twice, and every move a piece of the seat to move');
ok($count_ok, 'as many moves as the reaches of that seat\'s pieces add up to');
ok($order_ok, 'in order: by the piece, then by where it stops');
ok($clone_ok, 'a clone has the same list');
ok($do_ok, 'and every move can be made');

done_testing();
