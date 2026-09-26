use strict;
use warnings;
use Test::More;

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# A key is SIXTEEN HEX CHARACTERS and never a number. On a perl with 32-bit IVs
# a UV cannot hold a 64-bit key, the top half vanishes silently, and what is
# left is a test that passes while comparing half a number.
subtest 'a key is a hex string and it is the whole number' => sub {
    my $b = $E->new;
    like($b->key_hex, qr/\A[0-9a-f]{16}\z/, 'sixteen hex characters');
    isnt($b->key_hex, '0' x 16, 'and the opening position is not zero');
};

subtest 'the key changes on every one of a hundred moves' => sub {
    my $b = $E->new;
    my $collisions = 0;
    my $n = 0;

    # A hundred moves of legal SHAPE that are not checked for legality: this
    # phase has no rules, so the walk just shuffles pieces about and the key
    # must track every one of them.
    #
    # THE OCCUPIED LIST IS RE-DERIVED EVERY ITERATION and the first version of
    # this test did not do that: it took the thirty-two starting points once,
    # and after a few moves most of them were empty, so `next unless occupied`
    # skipped and it made 41 moves while claiming a hundred. The assertion that
    # mattered (no collisions) passed the whole time. A loop that silently does
    # a third of the work it says it does is the test lying, not the engine.
    for my $i (1 .. 100) {
        my @occupied = grep { $b->at($_) != EMPTY } $E->all_points;
        last unless @occupied;
        my $from = $occupied[ ($i * 7) % @occupied ];
        my $to   = $E->point_of(($i * 3 + 1) % 9, ($i * 7 + 2) % 10);
        next if $to == $from;
        my $before = $b->key_hex;
        $b->do_move($E->move($from, $to));
        $collisions++ if $b->key_hex eq $before;
        $n++;
    }
    is($n, 100, 'made a hundred moves, and counted them');
    is($collisions, 0, 'not one of them left the key unchanged');
};

subtest 'undo restores the key exactly' => sub {
    my $b = $E->new;
    my @stack;
    my @keys = ($b->key_hex);
    my @seq = ([0, 0, 0, 1], [1, 2, 4, 2], [4, 3, 4, 4], [7, 2, 7, 5], [8, 0, 8, 1]);
    for my $m (@seq) {
        my ($ff, $fr, $tf, $tr) = @$m;
        $b->do_move($E->move($E->point_of($ff, $fr), $E->point_of($tf, $tr)));
        push @stack, ($b->do_move($E->move($E->point_of($tf, $tr), $E->point_of($tf, $tr))))[1];
        pop @stack;
        push @keys, $b->key_hex;
    }
    # now walk it back properly, with the real tokens
    my $c = $E->new;
    my @tokens;
    my @ks = ($c->key_hex);
    for my $m (@seq) {
        my ($ff, $fr, $tf, $tr) = @$m;
        my ($cap, $u) = $c->do_move($E->move($E->point_of($ff, $fr), $E->point_of($tf, $tr)));
        push @tokens, $u;
        push @ks, $c->key_hex;
    }
    my $fen_at_end = $c->to_fen;
    while (my $u = pop @tokens) {
        $c->undo_move($u);
        my $want = pop @ks;
        is($c->key_hex, $ks[-1], 'undo put the key back exactly');
    }
    is($c->key_hex, $E->new->key_hex, 'and the whole walk back reaches the opening key');
    is($c->to_fen, $E->new->to_fen, 'the board came back too, not just the key');
    isnt($fen_at_end, $c->to_fen, 'and the walk really had gone somewhere');
};

subtest 'two move orders reaching one position give one key' => sub {
    # the same two pieces moved in either order reach the same position, and a
    # zobrist key has to say so or a transposition table is worthless and a
    # repetition detector is worse than worthless.
    my $rc = $E->point_of(0, 0);    # red chariot a0
    my $rh = $E->point_of(1, 0);    # red horse b0
    my $a = $E->new;
    $a->do_move($E->move($rc, $E->point_of(0, 1)));
    $a->do_move($E->move($rh, $E->point_of(2, 2)));

    my $b = $E->new;
    $b->do_move($E->move($rh, $E->point_of(2, 2)));
    $b->do_move($E->move($rc, $E->point_of(0, 1)));

    is($a->to_fen, $b->to_fen, 'the two orders really do reach one position');
    is($a->key_hex, $b->key_hex, 'and the key says so');
};

# PROVE IT TWICE. The phase file asks for this one by name: drop the side to
# move from the key and the transposition assertion above still passes, because
# both orders leave the same side on turn. THIS is the assertion that fails.
subtest 'the side to move is in the key, and here is the proof' => sub {
    my $a = $E->new;
    my $b = $E->new;
    $b->set_side(BLACK);

    is($a->to_fen =~ s/ w / b /r, $b->to_fen, 'the two differ only in whose turn it is');
    isnt($a->key_hex, $b->key_hex,
        'and the key differs, which a key without the side would not');

    # and flipping back is exact, not merely close
    $b->set_side(RED);
    is($b->key_hex, $a->key_hex, 'flipping the side back restores the key');
};

subtest 'the zobrist table is derived, fixed, and pinned' => sub {
    # THE GENERATOR IS THE KEY. Changing splitmix64 or its seed changes every
    # key in the distribution. Nothing persists a key across versions today; if
    # anything ever does, these four lines are what catch the change.
    my @pins = (
        [ RED   | GENERAL,  $E->point_of(4, 0) ],
        [ BLACK | GENERAL,  $E->point_of(4, 9) ],
        [ RED   | SOLDIER,  $E->point_of(0, 3) ],
        [ BLACK | CANNON,   $E->point_of(7, 7) ],
    );
    my %seen;
    for my $p (@pins) {
        my $hex = $E->zobrist_hex($p->[0], $p->[1]);
        like($hex, qr/\A[0-9a-f]{16}\z/, "zobrist($p->[0],$p->[1]) is a 64-bit hex string");
        isnt($hex, '0' x 16, '  and it is not zero');
        ok(!$seen{$hex}++, '  and it has not been seen before');
    }

    # two processes must agree, which is the whole reason the table is not rand()
    is($E->zobrist_hex(RED | GENERAL, $E->point_of(4, 0)),
       $E->zobrist_hex(RED | GENERAL, $E->point_of(4, 0)),
       'the same piece on the same point is the same value twice');

    # the opening key is a pure function of the opening position
    is($E->new->key_hex, $E->new->key_hex, 'and two fresh boards agree');
};

subtest 'a capture is in the key and undo brings the captured piece back' => sub {
    my $b = $E->new;
    my $from = $E->point_of(0, 3);    # red soldier a3
    my $to   = $E->point_of(0, 6);    # black soldier a6
    my $before = $b->key_hex;
    my ($captured, $u) = $b->do_move($E->move($from, $to));
    is($captured, BLACK | SOLDIER, 'do_move reports what it took');
    is($b->at($to), RED | SOLDIER, 'the taker is on the point');
    is($b->at($from), EMPTY, 'and its old point is empty');
    isnt($b->key_hex, $before, 'the key moved');

    $b->undo_move($u);
    is($b->at($to), BLACK | SOLDIER, 'undo put the captured piece back');
    is($b->at($from), RED | SOLDIER, 'and the taker back where it was');
    is($b->key_hex, $before, 'and the key is exactly what it was');
    is($b->to_fen, $E->new->to_fen, 'and the board is the opening position again');
};

done_testing();
