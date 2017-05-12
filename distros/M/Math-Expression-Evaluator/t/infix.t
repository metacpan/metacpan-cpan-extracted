use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 25 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new() works");

sub e {
    return $m->parse(shift)->val();
}
sub o {
    return $m->parse(shift)->optimize()->val();
}

my @tests = (
    ['1+2'          ,3      ,'infix + with two args'],
    ['1+2+3'        ,6      ,'infix + with three args'],
    ['2*3'          ,6      ,'* with two args'],
    ['2*3*4'        ,24     ,'* with three args'],
    ['3-2'          ,1      ,'infix - with two args'],
    ['3-2-1'        ,0      ,'infix - with three args'],
    ['4/2'          ,2      ,'/ with two args'],
    ['16/4/2'       ,2      ,'/ with three args'],
    ['4*3/2'        ,6      ,'* and / mixed 1'],
    ['4/2*3'        ,6      ,'* and / mixed 2'],
    ['1+2-3'        ,0      ,'+ and - mixed 1'],
    ['1-2+3'        ,2      ,'+ and - mixed 2'],
);

for (@tests){
    cmp_ok e($_->[0]), '==', $_->[1], $_->[2];
    cmp_ok o($_->[0]), '==', $_->[1], $_->[2] . ' (optimized)';
}

# vim: sw=4 ts=4 expandtab
