use strict;
use warnings;
use Test::More;

use Game::Fanorona::Engine ':all';
my $E = 'Game::Fanorona::Engine';

sub sq {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-i])([1-5])\z/ or die "not a point: $name";
    return $r * 11 + (ord($f) - ord('a') + 1);
}

{
    my $state = 10102026;
    sub roll {
        my ($n) = @_;
        $state = ($state * 1103515245 + 12345) % 2147483648;
        return int($state / 65536) % $n;
    }
}

my $SETUP = 'bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w';

subtest 'the set-up as a string' => sub {
    is($E->new->to_string, $SETUP, 'the set-up writes as the plan has it');
    my ($bd, $err) = $E->of_string($SETUP);
    is($err, POS_OK, 'and reads back with no complaint');
    is($bd->to_string, $SETUP, 'to the same string');
    is($bd->key_hex, $E->new->key_hex, 'and the same key');
    is($E->new(position => $SETUP)->to_string, $SETUP, 'new(position => ...) reads it too');
};

subtest 'the string is read top rank first' => sub {
    my ($bd) = $E->of_string('w8/9/9/9/8b b');
    is($bd->at(sq('a5')), WHITE, 'the first character of the string is a5');
    is($bd->at(sq('i1')), BLACK, 'and the last of the board is i1');
    is($bd->count(WHITE) + $bd->count(BLACK), 2, 'two stones and no more');
    is($bd->side, BLACK, 'the side field is the side to move');

    my $made = $E->new(empty => 1)->put(sq('a5'), WHITE)->put(sq('i1'), BLACK)->set_side(BLACK);
    is($made->to_string, 'w8/9/9/9/8b b', 'and the same position, built by hand, writes the same string');

    # one string that uses every kind of run
    my $mixed = '1w1b1w1b1/9/4w4/bb5ww/w7b w';
    my ($got) = $E->of_string($mixed);
    is($got->to_string, $mixed, 'runs of one, of four, of five, of seven and of nine survive a round trip');
    is($got->at(sq('e3')), WHITE, 'the stone in the middle of 4w4 is on e3');
    is($got->at(sq('a2')), BLACK, 'bb5ww starts on a2');
    is($got->at(sq('i2')), WHITE, 'and ends on i2');

    my ($full) = $E->of_string(join('/', ('wwwwwwwww') x 5) . ' w');
    is($full->count(WHITE), 45, 'forty-five white stones load: a string is refused for its shape, never its sense');
};

subtest 'a round trip over walked positions' => sub {
    my (@bad, %strings);
    my $bd = $E->new;
    my @all = $bd->all_squares;
    for my $n (1 .. 2000) {
        my $s = $all[ roll(45) ];
        my $what = roll(4);
        if    ($what == 0) { $bd->lift($s) }
        elsif ($what == 1) { $bd->put($s, WHITE) }
        elsif ($what == 2) { $bd->put($s, BLACK) }
        else               { $bd->set_side(other($bd->side)) }
        my $str = $bd->to_string;
        $strings{$str}++;
        my ($back, $err) = $E->of_string($str);
        if (!$back) { push @bad, "step $n: '$str' refused, code $err"; next }
        push @bad, "step $n: '$str' came back as '" . $back->to_string . "'" unless $back->to_string eq $str;
        push @bad, "step $n: the key moved" unless $back->key_hex eq $bd->key_hex;
        push @bad, "step $n: the counts moved"
            unless $back->count(WHITE) == $bd->count(WHITE) && $back->count(BLACK) == $bd->count(BLACK);
    }
    is(scalar(@bad), 0, 'two thousand positions each read back to themselves') or diag join "\n", @bad[0 .. ($#bad < 5 ? $#bad : 5)];
    cmp_ok(scalar(keys %strings), '>', 1000, scalar(keys %strings) . ' of them distinct');
};

subtest 'a string that is not a position, and why' => sub {
    my @refused = (
        [ undef,                                    POS_NULL,   'no string' ],
        [ '',                                       POS_NULL,   'an empty string' ],
        [ $SETUP . ' ' . ('x' x 20),                POS_LONG,   'sixty-four characters or more' ],
        [ 'bbbbbbbbb/bbbbbbbbb/bwbwxbwbw/wwwwwwwww/wwwwwwwww w', POS_LETTER, 'a letter that is not w or b' ],
        [ 'bbbbbbbbb/bbbbbbbbb/bwbw0bwbw/wwwwwwwww/wwwwwwwww w', POS_LETTER, 'a run of zero' ],
        [ 'BBBBBBBBB/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w', POS_LETTER, 'a capital' ],
        [ '9/9/9/9 w',                              POS_ROWS,   'four ranks' ],
        [ '9/9/9/9/9/9 w',                          POS_ROWS,   'six ranks' ],
        [ '9 w',                                    POS_ROWS,   'one rank' ],
        [ '9/9/8/9/9 w',                            POS_WIDTH,  'a rank of eight among nines' ],
        [ 'bbbbbbbbb/bbbbbbbbb/bwbw2bwbw/wwwwwwwww/wwwwwwwww w', POS_WIDTH, 'a rank of ten, which would be forty-six points' ],
        [ '8/8/8/8/8 w',                            POS_WIDTH,  'an even width' ],
        [ '1/1/1 w',                                POS_WIDTH,  'a width of one' ],
        [ '9/9//9/9 w',                             POS_WIDTH,  'an empty rank' ],
        [ '9/9/9/9/9',                              POS_SIDE,   'no side' ],
        [ '9/9/9/9/9 ',                             POS_SIDE,   'a space and no side' ],
        [ '9/9/9/9/9 x',                            POS_SIDE,   'a side that is not w or b' ],
        [ '9/9/9/9/9 W',                            POS_SIDE,   'a capital side' ],
        [ '9/9/9/9/9 w ',                           POS_SIDE,   'something after the side' ],
        [ '9/9/9/9/9 w 0 1',                        POS_SIDE,   'counters after the side, which a later version will read' ],
        [ '9/9/9/9/9  w',                           POS_SIDE,   'two spaces' ],
    );
    my $before = $E->live;
    for my $case (@refused) {
        my ($str, $want, $what) = @$case;
        my ($bd, $err) = $E->of_string($str);
        ok(!defined $bd, "$what: no board");
        is($err, $want, "$what: code $want");
    }
    is($E->live, $before, 'and a refused string leaves no board behind');

    # when a string has two faults, the earlier in the order is the one named
    is(($E->of_string('x/9/8 '))[1], POS_LETTER, 'a bad letter is named before the wrong number of ranks');
    is(($E->of_string('9/9/9/8'))[1], POS_ROWS, 'the wrong number of ranks before an uneven width');
    is(($E->of_string('9/9/8/9/9'))[1], POS_WIDTH, 'an uneven width before a missing side');

    ok(!eval { $E->new(position => '9/9/9/9 w'); 1 }, 'new(position => ...) croaks on a string of_string would refuse');
    like($@, qr/the position was refused, code 4/, 'and names the code');

    is_deeply([ POS_OK, POS_NULL, POS_LONG, POS_LETTER, POS_ROWS, POS_WIDTH, POS_SIDE ], [ 0 .. 6 ],
        'the codes are 0 to 6 in the order they are asked');
};

# A key is SIXTEEN HEX CHARACTERS and never a number. On a perl with 32-bit IVs
# a UV cannot hold a 64-bit key, the top half vanishes silently, and what is
# left is a test that passes while comparing half a number.
subtest 'a key is a hex string and it is the whole number' => sub {
    my $bd = $E->new;
    like($bd->key_hex, qr/\A[0-9a-f]{16}\z/, 'sixteen lowercase hex characters');
    like($bd->key_full_hex, qr/\A[0-9a-f]{16}\z/, 'the recomputed key has the same shape');
    is($bd->key_full_hex, $bd->key_hex, 'and is the same key');
    like($E->zobrist_hex(WHITE, sq('a1')), qr/\A[0-9a-f]{16}\z/, 'so has one stone on one point');
    isnt(substr($bd->key_hex, 0, 8), '0' x 8, 'the top half is not zero');
    isnt(substr($bd->key_hex, 8, 8), '0' x 8, 'nor the bottom');
};

# PINNED. Changing the generator, its seed or the order the table is filled in
# changes every key, and nothing but a red test here would say so.
subtest 'the table is the one that was published' => sub {
    is($E->new->key_hex,                     '11f6b635641af1ad', 'the set-up');
    is($E->new(empty => 1)->key_hex,         'b7446805c5b42efc', 'the empty nine by five, White to move');
    is($E->zobrist_size_hex(9, 5),           'b7446805c5b42efc', 'which is the size term and nothing else');
    is($E->zobrist_hex(WHITE, sq('a1')),     'df2510b3c10cee0d', 'a white stone on a1');
    is($E->zobrist_hex(BLACK, sq('e3')),     'a5a643ac49dc4d7e', 'a black stone on e3');
    is($E->zobrist_side_hex,                 '2f93123e22572110', 'Black to move');
    is($E->zobrist_size_hex(3, 3),           '5d932aae8980e866', 'the three by three');
    is($E->zobrist_hex(EMPTY, sq('a1')),     '0' x 16, 'an empty point contributes nothing');
    is($E->zobrist_hex(BORDER, sq('a1')),    '0' x 16, 'nor does the border');
    is($E->zobrist_hex(WHITE, 0),            '0' x 16, 'nor a stone in the ring');
    is($E->zobrist_size_hex(4, 4),           '0' x 16, 'nor a size that is not a board');
};

subtest 'the key is the position and nothing else' => sub {
    my $bd = $E->new;
    my @all = $bd->all_squares;
    my (@drift, %keys);
    for my $n (1 .. 3000) {
        my $s = $all[ roll(45) ];
        my $what = roll(4);
        if    ($what == 0) { $bd->lift($s) }
        elsif ($what == 1) { $bd->put($s, WHITE) }
        elsif ($what == 2) { $bd->put($s, BLACK) }
        else               { $bd->set_side(other($bd->side)) }
        push @drift, "step $n" unless $bd->key_hex eq $bd->key_full_hex;
        my $str = $bd->to_string;
        push @drift, "step $n: two positions share $str" if exists $keys{$str} && $keys{$str} ne $bd->key_hex;
        $keys{$str} = $bd->key_hex;
    }
    is("@drift[0 .. ($#drift < 5 ? $#drift : 5)]", '', 'the maintained key equals the recomputed one after each of 3,000 changes');
    my %by_key;
    $by_key{ $keys{$_} }++ for keys %keys;
    is(scalar(keys %by_key), scalar(keys %keys), scalar(keys %keys) . ' distinct positions have as many distinct keys');

    my $white = $E->new;
    my $black = $E->new->set_side(BLACK);
    isnt($black->key_hex, $white->key_hex, 'the side to move is in the key');
    is($black->set_side(WHITE)->key_hex, $white->key_hex, 'and setting it back restores the key');
    is($white->clone->set_side(WHITE)->key_hex, $white->key_hex, 'setting the side it already has changes nothing');

    my $one = $E->new(empty => 1)->put(sq('a1'), WHITE)->put(sq('b2'), BLACK);
    my $two = $E->new(empty => 1)->put(sq('b2'), BLACK)->put(sq('a1'), WHITE);
    is($one->key_hex, $two->key_hex, 'the same position reached two ways has one key');
    my $swapped = $E->new(empty => 1)->put(sq('a1'), BLACK)->put(sq('b2'), WHITE);
    isnt($swapped->key_hex, $one->key_hex, 'the colours swapped is a different key');
    is($one->clone->key_hex, $one->key_hex, 'a clone has the key of its original');

    # the same two stones on the same two points of a smaller board
    my $small = $E->new(board => 'telo', empty => 1)->put(sq('a1'), WHITE)->put(sq('b2'), BLACK);
    isnt($small->key_hex, $one->key_hex, 'the size of the board is in the key');
};

done_testing();
