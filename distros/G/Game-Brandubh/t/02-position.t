use strict;
use warnings;
use Test::More;

use Game::Brandubh::Engine ':all';
my $E = 'Game::Brandubh::Engine';

my $SETUP = '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a';

sub sq {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-g])([1-7])\z/ or die "not a square: $name";
    return $r * 9 + (ord($f) - ord('a') + 1);
}

# A small generator of its own, so the positions are the same on every perl and
# every platform and a failure can be reproduced from its number.
{
    my $state = 20261008;
    sub roll {
        my ($n) = @_;
        $state = ($state * 1103515245 + 12345) % 2147483648;
        return int($state / 65536) % $n;
    }
}

subtest 'the set-up, written out' => sub {
    my $bd = $E->new;
    is($bd->to_string, $SETUP, 'the set-up is the string the documentation shows');
    is(length($bd->to_string), 33, 'thirty-three characters');
};

subtest 'the first row of the string is rank 7' => sub {
    my ($bd, $err) = $E->of_string('k6/7/7/7/7/7/6a d');
    is($err, POS_OK, 'it loads');
    is($bd->at(sq('a7')), KING, 'the first character of the first row is a7');
    is($bd->at(sq('g1')), ATTACKER, 'the last character of the last row is g1');
    is($bd->at(sq('a1')), EMPTY, 'and a1 is empty, which it would not be read upside down');
    is($bd->side, DEFENDERS, 'the defenders to move');
};

subtest 'a string comes back as it went in' => sub {
    for my $s (
        $SETUP,
        '7/7/7/7/7/7/7 a',
        '7/7/7/7/7/7/7 d',
        'aaaaaaa/ddddddd/kkkkkkk/aaaaaaa/ddddddd/kkkkkkk/aaaaaaa d',
        'a1a1a1a/1d1d1d1/k5k/7/3k3/a5d/1a3d1 a',
        'k5k/7/7/3d3/7/7/k5k a',
    ) {
        my ($bd, $err) = $E->of_string($s);
        is($err, POS_OK, "loads: $s") or next;
        is($bd->to_string, $s, 'and writes the same string');
    }
};

subtest 'five hundred random boards round-trip' => sub {
    my ($bad_string, $bad_key, $made) = (0, 0, 0);
    for my $i (1 .. 500) {
        my $bd = $E->new(empty => 1);
        for my $s ($E->all_squares) {
            my $what = roll(6);
            $bd->put($s, $what) if $what >= 1 && $what <= 3;
        }
        $bd->set_side(roll(2) ? DEFENDERS : ATTACKERS);
        my $string = $bd->to_string;
        my ($again, $err) = $E->of_string($string);
        $made++;
        if (!$again) { $bad_string++; next }
        $bad_string++ unless $again->to_string eq $string;
        $bad_key++    unless $again->key_hex eq $bd->key_hex;
    }
    is($made, 500, 'five hundred boards were made, and counted');
    is($bad_string, 0, 'every string read back to the same string');
    is($bad_key,    0, 'and to the same key');
};

# EACH REFUSAL IS PRODUCED BY A STRING WRITTEN TO PRODUCE IT, and the six codes
# are six different numbers: a reader that answered POS_LETTER for everything
# would pass a test that only checked for a refusal.
subtest 'the six refusals, each from its own string' => sub {
    my @cases = (
        [ POS_NULL,   undef,                                   'no string at all' ],
        [ POS_NULL,   '',                                      'an empty string' ],
        [ POS_ROWS,   '7/7/7/7/7/7 a',                         'six rows' ],
        [ POS_ROWS,   '7/7/7/7/7/7/7/7 a',                     'eight rows' ],
        [ POS_LETTER, '8/7/7/7/7/7/7 a',                       'the digit eight, which no row can hold' ],
        [ POS_WIDTH,  '6/7/7/7/7/7/7 a',                       'a row of six' ],
        [ POS_WIDTH,  '7/7/7/aaaaaaaa/7/7/7 a',                'eight pieces in a row' ],
        [ POS_WIDTH,  '7/7/7/7/7/7/6 a',                       'a short last row' ],
        [ POS_WIDTH,  '7/7/7/3a4/7/7/7 a',                     'a row that adds up to eight' ],
        [ POS_LETTER, '7/7/7/3K3/7/7/7 a',                     'an upper-case king' ],
        [ POS_LETTER, '7/7/7/3x3/7/7/7 a',                     'a letter that names nothing' ],
        [ POS_LETTER, '7/7/7/3.3/7/7/7 a',                     'a full stop for an empty square' ],
        [ POS_LETTER, '7/7/7/0k6/7/7/7 a',                     'a zero' ],
        [ POS_SIDE,   '7/7/7/7/7/7/7',                         'no side field' ],
        [ POS_SIDE,   '7/7/7/7/7/7/7 ',                        'a space and then nothing' ],
        [ POS_SIDE,   '7/7/7/7/7/7/7 w',                       'a side from another game' ],
        [ POS_SIDE,   '7/7/7/7/7/7/7 A',                       'an upper-case side' ],
        [ POS_SIDE,   '7/7/7/7/7/7/7 ad',                      'two sides' ],
        [ POS_SIDE,   '7/7/7/7/7/7/7  a',                      'two spaces' ],
        [ POS_SIDE,   '7/7/7/7/7/7/7 a ',                      'something after the side' ],
        [ POS_LONG,   '7/7/7/7/7/7/7 a' . (' ' x 60),          'a string too long to be a position' ],
    );
    my %seen;
    for my $case (@cases) {
        my ($want, $string, $why) = @$case;
        my ($bd, $err) = $E->of_string($string);
        ok(!defined $bd, "refused: $why");
        is($err, $want, "with code $want");
        $seen{$want}++;
    }
    is(join(' ', sort keys %seen), '1 2 3 4 5 6', 'all six codes were produced');
    is(scalar(keys %{{ map { $_ => 1 } POS_NULL, POS_ROWS, POS_WIDTH, POS_LETTER, POS_SIDE, POS_LONG }}),
        6, 'and they are six different numbers');
    isnt(POS_OK, POS_NULL, 'none of which is POS_OK');
};

subtest 'the longest real position is accepted' => sub {
    my $full = join('/', ('adkadka') x 7) . ' d';
    is(length($full), 57, 'fifty-seven characters is the longest a position can be');
    my ($bd, $err) = $E->of_string($full);
    is($err, POS_OK, 'and it loads');
    is($bd->to_string, $full, 'and writes back');
};

# A string is refused for its SHAPE and never for its sense. These are
# positions no game reaches and a test needs to build.
subtest 'a senseless position still loads' => sub {
    for my $case (
        [ 'k5k/7/7/7/7/7/7 a', 'two kings' ],
        [ '7/7/7/7/7/7/7 a',   'no king, no pieces' ],
        [ 'd6/7/7/3d3/7/7/7 a', 'a defender on a corner and one on the throne' ],
    ) {
        my ($bd, $err) = $E->of_string($case->[0]);
        is($err, POS_OK, "loads: $case->[1]");
    }
};

subtest 'new takes a position, and croaks on a bad one' => sub {
    my $bd = $E->new(position => '7/7/7/3k3/7/7/7 d');
    is($bd->to_string, '7/7/7/3k3/7/7/7 d', 'new(position => ...) builds that position');
    ok(!eval { $E->new(position => '7/7/7 a'); 1 }, 'a bad string croaks');
    like($@, qr/refused, code 2/, 'and the message carries the code');
};

done_testing();
