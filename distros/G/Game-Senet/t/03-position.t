use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

my $EMPTY  = '........../........../.......... l 5';
my $START5 = 'dldldldldl/........../.......... l 5';
my $START7 = 'dldldldldl/dldl....../.......... l 7';

subtest 'the strings this file pins' => sub {
    is($E->new->to_string, $EMPTY, 'an empty board');

    my $five = $E->new;
    $five->put($_, $_ % 2 ? DARK : LIGHT) for 1 .. 10;
    is($five->to_string, $START5, 'the start at five: dark on the odd houses, light on the even');

    my $seven = $E->new(pieces => 7);
    $seven->put($_, $_ % 2 ? DARK : LIGHT) for 1 .. 14;
    is($seven->to_string, $START7, 'the start at seven runs into the middle group');
};

subtest 'the middle group is in track order, not grid order' => sub {
    my $bd = $E->new;
    $bd->put(11, LIGHT);
    is($bd->to_string, '........../l........./.......... l 5',
        'house 11, drawn at the RIGHT of the middle row, is the FIRST character of its group');
    my ($back) = $E->of_string('........../.........d/.......... d 5');
    is($back->at(20), DARK, 'and the last character of the middle group is house 20');
    is($E->col_of(20), 0, 'which the board draws at the left');
};

subtest 'round trips' => sub {
    for my $s ($EMPTY, $START5, $START7,
               '........../........../.........d d 1',
               'l........./........../.......... d 1',
               '.l.d.l.d../...ll..dd./ll.d.ddl.. l 7') {
        my ($bd, $err) = $E->of_string($s);
        is($err, POS_OK, "'$s' loads");
        is($bd->to_string, $s, 'and writes back the same');
        is($E->new(position => $s)->to_string, $s, 'and new(position => ...) agrees');
    }

    srand(20261017);
    my @bad;
    for my $n (1 .. 500) {
        my $pieces = 1 + int(rand(7));
        my $bd = $E->new(pieces => $pieces);
        for my $side (SIDE_LIGHT, SIDE_DARK) {
            my $place = int(rand($pieces + 1));
            while ($place) {
                my $h = 1 + int(rand(30));
                next if $bd->at($h) != EMPTY;
                $bd->put($h, piece_of($side));
                $place--;
            }
        }
        $bd->set_side(int(rand(2)));
        my $s = $bd->to_string;
        my ($back, $err) = $E->of_string($s);
        push @bad, "#$n $s ($err)" and next unless defined $back;
        push @bad, "#$n $s" unless $back->to_string eq $s && $back->key_hex eq $bd->key_hex
                                && $back->pieces == $pieces;
    }
    is("@bad", '', '500 random consistent boards round-trip, with their key and pieces');
};

subtest 'a board read from a string is at ply 0' => sub {
    my $bd = $E->new;
    $bd->set_ply(9);
    my ($back) = $E->of_string($bd->to_string);
    is($back->ply, 0, 'the ply is not in the string');
};

my @REFUSED = (
    [ POS_NULL,   '',                                            'the empty string' ],
    [ POS_NULL,   undef,                                         'no string at all' ],
    [ POS_GROUPS, '........../.......... l 5',                   'two groups' ],
    [ POS_GROUPS, '........../........../........../.......... l 5', 'four groups' ],
    [ POS_GROUPS, '.......... l 5',                              'one group' ],
    [ POS_WIDTH,  '........./........../.......... l 5',         'a first group of nine' ],
    [ POS_WIDTH,  '........../.........../.......... l 5',       'a middle group of eleven' ],
    [ POS_WIDTH,  '........../........../......... l 5',         'a last group of nine' ],
    [ POS_WIDTH,  '/........../.......... l 5',                  'an empty first group' ],
    [ POS_LETTER, '.........x/........../.......... l 5',        'an x' ],
    [ POS_LETTER, '.........L/........../.......... l 5',        'a capital L' ],
    [ POS_LETTER, '9........./........../.......... l 5',        'a digit, which could only be misread as a house' ],
    [ POS_SIDE,   '........../........../.......... x 5',        'a side of x' ],
    [ POS_SIDE,   '........../........../.......... L 5',        'a side of L' ],
    [ POS_SIDE,   '........../........../.......... ld 5',       'a side two letters long' ],
    [ POS_PIECES, '........../........../.......... l 0',        'pieces 0' ],
    [ POS_PIECES, '........../........../.......... l 8',        'pieces 8' ],
    [ POS_PIECES, '........../........../.......... l x',        'pieces x' ],
    [ POS_PIECES, '........../........../.......... l 55',       'pieces two digits long' ],
    [ POS_EXCESS, 'llllll..../........../.......... l 5',        'six light pieces when pieces is 5' ],
    [ POS_EXCESS, 'dd......../........../.......... d 1',        'two dark pieces when pieces is 1' ],
    [ POS_FIELD,  '........../........../..........',            'no side and no pieces' ],
    [ POS_FIELD,  '........../........../.......... l',          'a string cut after the side' ],
    [ POS_FIELD,  '........../........../.......... l ',         'a string cut after the space' ],
    [ POS_FIELD,  '........../........../.......... l 5 0',      'something after the last field' ],
    [ POS_SIDE,   '........../........../..........  l 5',       'two spaces, so the side is a space' ],
    [ POS_LONG,   join('/', ('.' x 10) x 3) . ' l 5' . (' ' x 12), 'forty-eight characters' ],
);

subtest 'every refusal, with its code' => sub {
    cmp_ok(scalar(@REFUSED), '>=', 25, 'at least twenty-five strings written for it');
    my %reached;
    for my $case (@REFUSED) {
        my ($code, $string, $what) = @$case;
        my ($bd, $err) = $E->of_string($string);
        ok(!defined $bd, "refused: $what");
        is($err, $code, "  with code $code");
        $reached{$err}++;
    }
    is_deeply([ sort { $a <=> $b } keys %reached ],
              [ POS_NULL, POS_GROUPS, POS_WIDTH, POS_LETTER, POS_SIDE,
                POS_PIECES, POS_EXCESS, POS_FIELD, POS_LONG ],
              'all nine codes were reached');
    is(length($REFUSED[-1][1]), 48, 'and the long one is exactly forty-eight');
};

subtest 'new(position => ...) croaks on a refusal' => sub {
    ok(!eval { $E->new(position => 'llllll..../........../.......... l 5'); 1 }, 'an excess croaks');
    like($@, qr/refused, code 7/, 'with the code');
};

done_testing();
