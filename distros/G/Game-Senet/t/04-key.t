use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

# THE KEYS, AS LITERALS, worked out by hand in plan_game_senet/01: house h at
# bits 2(h - 1), the side to move at bit 60. A dark piece on house 2k - 1 and a
# light one on house 2k are the nibble 6, so the start is one 6 a pair.
my @PINNED = (
    [ '........../........../.......... l 5', '0000000000000000', 'the empty board, light to move' ],
    [ '........../........../.......... d 5', '1000000000000000', 'the same, dark to move' ],
    [ 'dldldldldl/........../.......... l 5', '0000000000066666', 'the start, five pieces' ],
    [ 'dldldldldl/dldl....../.......... l 7', '0000000006666666', 'the start, seven pieces' ],
    [ '........../........../.........d l 5', '0800000000000000', 'one dark piece on 30' ],
    [ 'l........./........../.......... l 5', '0000000000000001', 'one light piece on 1' ],
    [ '........../........../.........l d 5', '1400000000000000', 'light on 30, dark to move' ],
);

subtest 'the pinned keys' => sub {
    for my $case (@PINNED) {
        my ($s, $key, $what) = @$case;
        my ($bd) = $E->of_string($s);
        is($bd->key_hex, $key, $what);
    }
};

subtest 'what the key leaves out, each on purpose' => sub {
    my ($a5) = $E->of_string('dl......../........../.......... l 5');
    my ($a7) = $E->of_string('dl......../........../.......... l 7');
    is($a5->key_hex, $a7->key_hex,
        'PIECES IS NOT IN THE KEY: two games that differ in pieces never meet, so they need not differ');
    isnt($a5->home(SIDE_LIGHT), $a7->home(SIDE_LIGHT), 'though their homes differ');

    my $b = $a5->clone;
    $b->set_ply(77);
    is($b->key_hex, $a5->key_hex, 'THE PLY IS NOT IN THE KEY: how a position was reached is not the position');
};

subtest 'the side is in the key' => sub {
    my ($l) = $E->of_string('dldldldldl/........../.......... l 5');
    my ($d) = $E->of_string('dldldldldl/........../.......... d 5');
    isnt($l->key_hex, $d->key_hex, 'the same houses with the other side to move are another key');
};

subtest 'sixteen hex characters, whatever this perl is' => sub {
    my $bd = $E->new(position => 'ddddddd.../........../lllllll... d 7');
    like($bd->key_hex, qr/\A[0-9a-f]{16}\z/, 'sixteen lowercase hex characters');
    like($E->new->key_hex, qr/\A0{16}\z/, 'and the empty board is sixteen zeroes, not "0"');
};

subtest 'equal positions share a key, different ones do not' => sub {
    srand(17102026);
    my (%seen, @clash);
    my $made = 0;
    while ($made < 10_000) {
        my $bd = $E->new(pieces => 7);
        for my $side (SIDE_LIGHT, SIDE_DARK) {
            my $place = int(rand(8));
            while ($place) {
                my $h = 1 + int(rand(30));
                next if $bd->at($h) != EMPTY;
                $bd->put($h, piece_of($side));
                $place--;
            }
        }
        $bd->set_side(int(rand(2)));
        my $s = $bd->to_string;
        next if exists $seen{$s};
        $made++;
        my $k = $bd->key_hex;
        $seen{$s} = $k;
    }
    my %by_key;
    push @{ $by_key{ $seen{$_} } }, $_ for keys %seen;
    @clash = grep { @{ $by_key{$_} } > 1 } keys %by_key;
    is(scalar(keys %seen), 10_000, 'ten thousand different positions');
    is(scalar(@clash), 0, 'and ten thousand different keys');

    my $first = (sort keys %seen)[0];
    my ($x) = $E->of_string($first);
    my ($y) = $E->of_string($first);
    is($x->key_hex, $y->key_hex, 'and the same position read twice is one key');
};

done_testing();
