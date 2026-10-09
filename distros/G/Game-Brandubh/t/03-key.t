use strict;
use warnings;
use Test::More;

use Game::Brandubh::Engine ':all';
my $E = 'Game::Brandubh::Engine';

sub sq {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-g])([1-7])\z/ or die "not a square: $name";
    return $r * 9 + (ord($f) - ord('a') + 1);
}

{
    my $state = 8102026;
    sub roll {
        my ($n) = @_;
        $state = ($state * 1103515245 + 12345) % 2147483648;
        return int($state / 65536) % $n;
    }
}

# A key is SIXTEEN HEX CHARACTERS and never a number. On a perl with 32-bit IVs
# a UV cannot hold a 64-bit key, the top half vanishes silently, and what is
# left is a test that passes while comparing half a number.
subtest 'a key is a hex string and it is the whole number' => sub {
    my $bd = $E->new;
    like($bd->key_hex, qr/\A[0-9a-f]{16}\z/, 'sixteen lowercase hex characters');
    isnt($bd->key_hex, '0' x 16, 'and the set-up is not zero');
    like($bd->key_full_hex, qr/\A[0-9a-f]{16}\z/, 'the recomputed key has the same shape');
    is($E->new(empty => 1)->key_hex, '0' x 16, 'an empty board with the attackers to move is zero');
};

# PINNED. Changing the generator, its seed or the order the table is filled in
# changes every key, and nothing but a red test here would say so.
subtest 'the table is the one that was published' => sub {
    is($E->new->key_hex, 'f161530840d30927', 'the set-up');
    is($E->zobrist_hex(KING, sq('d4')),     'fa26dc19dcc41964', 'the king on the throne');
    is($E->zobrist_hex(ATTACKER, sq('a1')), '9f6841b8aac743c7', 'an attacker on a1');
    is($E->zobrist_side_hex,                'dca9f8bb22f5c613', 'the defenders to move');
    is($E->zobrist_hex(EMPTY, sq('d4')),  '0' x 16, 'an empty square contributes nothing');
    is($E->zobrist_hex(BORDER, sq('d4')), '0' x 16, 'nor does a border');
    is($E->zobrist_hex(KING, 0),          '0' x 16, 'nor a piece on the ring');
};

subtest 'put then lift restores the key' => sub {
    my $bd = $E->new;
    my $before = $bd->key_hex;
    my $bad = 0;
    for my $s (grep { $bd->at($_) == EMPTY } $E->all_squares) {
        for my $piece (ATTACKER, DEFENDER, KING) {
            $bd->put($s, $piece);
            $bad++ if $bd->key_hex eq $before;
            $bd->lift($s);
            $bad++ unless $bd->key_hex eq $before;
        }
    }
    is($bad, 0, 'for every empty square and each of the three pieces');
};

subtest 'the side to move is in the key' => sub {
    my $bd = $E->new;
    my $attackers = $bd->key_hex;
    $bd->set_side(DEFENDERS);
    isnt($bd->key_hex, $attackers, 'the same squares with the defenders to move is another key');
    $bd->set_side(DEFENDERS);
    isnt($bd->key_hex, $attackers, 'setting the side it already has changes nothing');
    $bd->set_side(ATTACKERS);
    is($bd->key_hex, $attackers, 'and back again is the first key');
};

subtest 'the same position reached two ways has one key' => sub {
    my $x = $E->new(empty => 1);
    $x->put(sq('a2'), ATTACKER)->put(sq('f6'), KING)->put(sq('c3'), DEFENDER);
    my $y = $E->new(empty => 1);
    $y->put(sq('c3'), DEFENDER)->put(sq('g1'), ATTACKER)->put(sq('f6'), KING)
      ->lift(sq('g1'))->put(sq('a2'), KING)->put(sq('a2'), ATTACKER);
    is($y->to_string, $x->to_string, 'the two boards are the same position');
    is($y->key_hex, $x->key_hex, 'and have the same key');
};

# THE COUNT IS ASSERTED. A loop that skipped most of its iterations would
# leave the comparison below passing on a handful of cases.
subtest 'the maintained key equals the key from nothing' => sub {
    my $bd = $E->new;
    my @squares = $E->all_squares;
    my ($steps, $bad) = (0, 0);
    for my $i (1 .. 2000) {
        my $s = $squares[ roll(49) ];
        my $what = roll(5);
        if    ($what == 0) { $bd->lift($s) }
        elsif ($what <= 3) { $bd->put($s, $what) }
        else               { $bd->set_side(roll(2) ? DEFENDERS : ATTACKERS) }
        $steps++;
        $bad++ unless $bd->key_hex eq $bd->key_full_hex;
    }
    is($steps, 2000, 'two thousand puts, lifts and side changes, counted');
    is($bad, 0, 'and the two keys agreed after every one');
};

# A collision here is a fault in the table and not bad luck: ten thousand keys
# drawn from 2**64 collide by chance about once in four hundred billion runs.
subtest 'ten thousand different positions have ten thousand keys' => sub {
    my (%by_key, %by_string);
    my $collisions = 0;
    my $tries = 0;
    while (keys %by_string < 10_000 && $tries < 40_000) {
        $tries++;
        my $bd = $E->new(empty => 1);
        for my $s ($E->all_squares) {
            my $what = roll(7);
            $bd->put($s, $what) if $what >= 1 && $what <= 3;
        }
        $bd->set_side(roll(2) ? DEFENDERS : ATTACKERS);
        my $string = $bd->to_string;
        next if $by_string{$string}++;
        my $key = $bd->key_hex;
        $collisions++ if exists $by_key{$key};
        $by_key{$key} = $string;
    }
    is(scalar(keys %by_string), 10_000, 'ten thousand distinct positions were made');
    is($collisions, 0, 'and no two share a key');
};

subtest 'one piece moved one square changes the key' => sub {
    my $bd = $E->new;
    my %seen = ($bd->key_hex => 1);
    my $n = 0;
    for my $from (map { sq($_) } qw(d1 d2 a4 b4 d3 c4)) {
        my $piece = $bd->at($from);
        for my $to (grep { $bd->at($_) == EMPTY } $E->all_squares) {
            my $c = $bd->clone;
            $c->lift($from)->put($to, $piece);
            $seen{ $c->key_hex }++;
            $n++;
        }
    }
    is($n, 6 * 36, 'six pieces each tried on all thirty-six empty squares');
    is(scalar(keys %seen), $n + 1, 'every one of them is a key nothing else had');
};

done_testing();
