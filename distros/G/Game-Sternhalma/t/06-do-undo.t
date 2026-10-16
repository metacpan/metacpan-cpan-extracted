use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

srand 20261014;

for my $seats (2, 3, 4, 6) {
    my $bd = $E->new(seats => $seats);
    my $start_string = $bd->to_string;
    my $start_key = $bd->key;
    my (@done, $key_ok, $one_ok);
    ($key_ok, $one_ok) = (1, 1);
    for (1 .. 10_000) {
        my @mine = grep { defined $bd->at($_) } 0 .. HOLES - 1;
        my @free = grep { !defined $bd->at($_) } 0 .. HOLES - 1;
        my ($from, $to) = ($mine[ rand @mine ], $free[ rand @free ]);
        my ($s, $k) = ($bd->to_string, $bd->key);
        $bd->do_move($from, $to) or do { $one_ok = 0; last };
        my ($fresh) = $E->from_string($bd->to_string);
        $key_ok = 0 unless $fresh->key eq $bd->key;
        if (rand() < 0.5) {
            $bd->undo_move($from, $to);
            $one_ok = 0 unless $bd->to_string eq $s && $bd->key eq $k;
            $bd->do_move($from, $to);
        }
        push @done, [ $from, $to ];
    }
    ok($one_ok, "$seats seats: 10,000 moves, each undone once at random to exactly the board and key before it");
    ok($key_ok, "$seats seats: after every move the key is the key a fresh board of that string has");
    $bd->undo_move(@{ pop @done }) while @done;
    is($bd->to_string, $start_string, "$seats seats: all 10,000 undone, last first, give the set-up back");
    is($bd->key, $start_key, "$seats seats: and its key");
    is($bd->to_move, 0, "$seats seats: and nobody's turn was moved");
}

# ---- refused, and nothing changes -----------------------------------------------------

{
    my $bd = $E->new(seats => 2);
    my ($s, $k) = ($bd->to_string, $bd->key);
    my $piece = 0;
    my $empty = $E->hole_at(0, 0);
    my $other = 1;
    is($bd->do_move($empty, $piece), 0, 'from an empty hole: refused');
    is($bd->do_move($piece, $other), 0, 'onto a piece: refused');
    is($bd->do_move($piece, $piece), 0, 'onto itself: refused');
    is($bd->do_move($piece, 121), 0, 'off the star: refused');
    is($bd->do_move(-1, $empty), 0, 'from off the star: refused');
    is($bd->undo_move($piece, $empty), 0, 'taking back a move that was not made: refused');
    is($bd->to_string, $s, 'and the board is as it was');
    is($bd->key, $k, 'and its key');
    is($bd->count(0), 10, 'and the counts');
}

done_testing();
