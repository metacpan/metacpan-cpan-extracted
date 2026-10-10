use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Engine ':all';
my $E = 'Game::RoyalUr::Engine';

sub c {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-h])([1-3])\z/ or die "not a square: $name";
    return $E->cell_of(ord($f) - ord('a'), $r - 1);
}

my $START = '4xx2/8/4xx2 l 7 0 7 0';

subtest 'the empty board writes itself' => sub {
    is($E->new->to_string, $START, 'seven a side, light to move');
    is($E->new(pieces => 5)->to_string, '4xx2/8/4xx2 l 5 0 5 0', 'five a side');
    my ($bd, $err) = $E->of_string($START);
    is($err, POS_OK, 'and reads itself back');
    is($bd->to_string, $START, 'to the same string');
};

# ROW 3 IS WRITTEN FIRST. One piece, on a square whose mirror is a different
# square, read back by name.
subtest 'which row is which' => sub {
    my ($bd) = $E->of_string('l3xx2/8/4xx1d l 6 0 6 0');
    is($bd->at(c('a3')), LIGHT, 'the first row of the string is row 3: a light piece on a3');
    is($bd->at(c('a1')), EMPTY, 'and not on a1');
    is($bd->at(c('h1')), DARK,  'the last row is row 1: a dark piece on h1');
    is($bd->at(c('h3')), EMPTY, 'and not on h3');

    my ($mid) = $E->of_string('4xx2/3d1l2/4xx2 l 6 0 6 0');
    is($mid->at(c('d2')), DARK,  'the middle row: d2');
    is($mid->at(c('f2')), LIGHT, 'and f2');
};

subtest 'the five fields, in their order' => sub {
    my ($bd) = $E->of_string('4xx2/8/4xx2 d 1 2 3 4');
    is($bd->side, SIDE_DARK, 'the side to move');
    is($bd->hand(SIDE_LIGHT), 1, 'then light hand');
    is($bd->home(SIDE_LIGHT), 2, 'light home');
    is($bd->hand(SIDE_DARK),  3, 'dark hand');
    is($bd->home(SIDE_DARK),  4, 'dark home');
    is($bd->to_string, '4xx2/8/4xx2 d 1 2 3 4', 'and it writes them back in that order');
};

# A string is refused for its SHAPE and never for its sense.
subtest 'what is not refused' => sub {
    my ($bd, $err) = $E->of_string('llllxxll/lll5/4xx2 l 7 7 7 7');
    is($err, POS_OK, 'nine light pieces and two full hands load');
    is($bd->count(SIDE_LIGHT), 9, 'all nine of them');
    ok(!$bd->consistent(7), 'and the board knows it is not consistent');
    is($bd->to_string, 'llllxxll/lll5/4xx2 l 7 7 7 7', 'and writes it back');

    my ($full) = $E->of_string('ddddxxdd/dddddddd/ddddxxdd d 0 0 0 0');
    is($full->count(SIDE_DARK), 20, 'a board with no empty square has no digit in it');
    is($full->to_string, 'ddddxxdd/dddddddd/ddddxxdd d 0 0 0 0', 'and round-trips');
};

# ELEVEN REFUSALS, each from a string written to produce it and no other.
subtest 'every refusal, by name' => sub {
    my @cases = (
        [ POS_NULL,   '',                               'an empty string' ],
        [ POS_ROWS,   '4xx2/8 l 7 0 7 0',               'two rows' ],
        [ POS_ROWS,   '4xx2/8/4xx2/8 l 7 0 7 0',        'four rows' ],
        [ POS_WIDTH,  '4xx1/8/4xx2 l 7 0 7 0',          'a row of seven' ],
        [ POS_WIDTH,  '4xx2/8l/4xx2 l 7 0 7 0',         'a row of nine' ],
        [ POS_WIDTH,  '4xx2/8/4xx3 l 7 0 7 0',          'a last row of nine' ],
        [ POS_LETTER, '4xx2/3k4/4xx2 l 7 0 7 0',        'a letter that is no piece' ],
        [ POS_LETTER, '4xx2/9/4xx2 l 7 0 7 0',          'a nine' ],
        [ POS_LETTER, '4xx2/L7/4xx2 l 7 0 7 0',         'a capital' ],
        [ POS_GAP,    '4lx2/8/4xx2 l 6 0 7 0',          'a piece on e3' ],
        [ POS_GAP,    '4xx2/8/4xd2 l 7 0 6 0',          'a piece on f1' ],
        [ POS_GAP,    '8/8/4xx2 l 7 0 7 0',             'a run of empties across e3 and f3' ],
        [ POS_GAP,    '4xx2/8/5x2 l 7 0 7 0',           'a run that covers e1' ],
        [ POS_X,      '4xx2/4x3/4xx2 l 7 0 7 0',        'an x in the middle row' ],
        [ POS_X,      'x3xx2/8/4xx2 l 7 0 7 0',         'an x on a3' ],
        [ POS_SIDE,   '4xx2/8/4xx2 w 7 0 7 0',          'a side that is neither' ],
        [ POS_SIDE,   '4xx2/8/4xx2 7 0 7 0',            'a count where the side should be' ],
        [ POS_COUNT,  '4xx2/8/4xx2 l 8 0 7 0',          'a hand of eight' ],
        [ POS_COUNT,  '4xx2/8/4xx2 l 7 0 7 12',         'a home of two digits' ],
        [ POS_COUNT,  '4xx2/8/4xx2 l 7 a 7 0',          'a home that is a letter' ],
        [ POS_COUNT,  '4xx2/8/4xx2 l -1 0 7 0',         'a hand below nothing' ],
        [ POS_FIELD,  '4xx2/8/4xx2',                    'no side and no counts' ],
        [ POS_FIELD,  '4xx2/8/4xx2 l',                  'a side and no counts' ],
        [ POS_FIELD,  '4xx2/8/4xx2 l 7 0',              'no dark counts' ],
        [ POS_FIELD,  '4xx2/8/4xx2 l 7 0 7',            'no dark home' ],
        [ POS_FIELD,  '4xx2/8/4xx2 l 7 0 7 0 0',        'a fifth count' ],
        [ POS_FIELD,  '4xx2/8/4xx2 l 7 0 7 0 ',         'a space after the last' ],
        [ POS_FIELD,  '4xx2/8/4xx2 l7 0 7 0',           'no space after the side' ],
        [ POS_LONG,   '4xx2/8/4xx2 l 7 0 7 0' . (' ' x 30), 'a string too long to be a position' ],
    );
    for my $case (@cases) {
        my ($want, $string, $what) = @$case;
        my ($bd, $err) = $E->of_string($string);
        ok(!defined $bd, "$what: no board") or diag("it loaded as " . $bd->to_string);
        is($err, $want, "$what: the code");
    }
    my %distinct = map { $_->[0] => 1 } @cases;
    is(scalar(keys %distinct), 10, 'ten codes between them, and POS_GAP is reached two ways');

    my ($none, $err) = $E->of_string(undef);
    is($err, POS_NULL, 'undef is no string');
};

subtest 'new croaks where of_string answers' => sub {
    ok(!eval { $E->new(position => '4xx2/8/4xx2 l 7 0') ; 1 }, 'a string cut short');
    like($@, qr/the position was refused, code 9/, 'names the code');
    my $bd = $E->new(position => '4xx2/3d4/4xx2 d 7 0 6 0');
    is($bd->at(c('d2')), DARK, 'and a good one is the position it says');
    is($bd->side, SIDE_DARK, 'with its side');
};

# Five hundred boards nobody chose, inconsistent ones among them: any piece on
# any cell and any count in any hand.
subtest 'five hundred random boards round-trip' => sub {
    srand(20261009);
    my (@bad, %seen);
    for my $n (1 .. 500) {
        my $bd = $E->new;
        $bd->put($_, int rand 3) for $E->all_cells;
        $bd->set_side(int rand 2);
        $bd->set_hand($_, int rand 8)->set_home($_, int rand 8) for SIDE_LIGHT, SIDE_DARK;
        my $string = $bd->to_string;
        $seen{$string}++;
        my ($back, $err) = $E->of_string($string);
        if (!$back) { push @bad, "$string refused, code $err"; next }
        push @bad, "$string came back " . $back->to_string unless $back->to_string eq $string;
        for my $cell ($E->all_cells) {
            push @bad, "$string differs at cell $cell" unless $back->at($cell) == $bd->at($cell);
        }
        for my $side (SIDE_LIGHT, SIDE_DARK) {
            push @bad, "$string differs in a count"
                unless $back->hand($side) == $bd->hand($side) && $back->home($side) == $bd->home($side);
        }
        push @bad, "$string differs in the side" unless $back->side == $bd->side;
        push @bad, "$string is too long" unless length($string) < 48;
    }
    is(scalar @bad, 0, 'every one') or diag(join "\n", @bad[0 .. ($#bad > 5 ? 5 : $#bad)]);
    cmp_ok(scalar(keys %seen), '>', 490, 'and they were different boards');
};

done_testing();
