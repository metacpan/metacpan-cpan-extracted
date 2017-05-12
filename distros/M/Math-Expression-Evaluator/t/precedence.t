use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 82 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub e {
    return $m->parse(shift)->val();
}
sub o {
    return $m->parse(shift)->optimize->val();
}

sub c {
    return &{$m->parse(shift)->compiled}();
}

my @tests = (
    ['1+2*3',      7,      '* over +'],
    ['1+2*-3',     -5,      '*-3'],
    ['1+3%2',       2,     '% over +'],
    ['1-2*3',      -5,     '* over -'],
    ['1+4/2',      3,      '/ over +'],
    ['1-4/2',      -1,     '/ over -'],
    ['3*2^4',      48,     '^ over *'],
    ['4*2^-2',      1,     '^ with negative number'],
    ['3-2^4',      -13,    '^ over -'],
    ['3+2^4',      19,     '^ over +'],
    ['16/2^3',     2,      '^ over /'],
    ['16%3^2',     7,      '^ over %'],
    ['2 * 2 **4', 32,      'power ** tighter than multiplication'],
    ['2*3%5',      1,      '* and % evaluate left to right 1'],
    ['3%5*2',      6,      '* and % evaluate left to right 2'],
    ['12/2%5',     1,      '/ and % evaluate left to right 1'],
    ['4%5/2',      2,      '/ and % evaluate left to right 2'],
    ['2*3%4/2',    1,      '*, / and % eval left to right 1'],
    ['6%4/2*3',    3,      '*, / and % eval left to right 2'],
    ['6/2%2',      1,      '*, / and % eval left to right 3'],
    ['16%9%5',     2,      '% is left assoc'],
    ['(1)',        1,      'Parenthesis 0'],
    ['(1+2)*3',    9,      'Parenthesis 1'],
    ['(1-2)*3',    -3,     'Parenthesis 2'],
    ['(1+2)^2',    9,      'Parenthesis 3'],
    ['(2)^(1+2)',  8,      'Parenthesis 4'],
    ['((1))',      1,      'Double Parenthesis'],
);

for (@tests){
    is e($_->[0]), $_->[1], $_->[2];
    is o($_->[0]), $_->[1], $_->[2] . ' [optimized]';
    is c($_->[0]), $_->[1], $_->[2] . ' [compiled]';
}

# vim: sw=4 ts=4 expandtab
