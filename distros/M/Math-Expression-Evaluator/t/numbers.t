use strict;
use warnings;
use Test::More;

my @tests;
BEGIN{
    @tests = (
            ['0'        , 0     ,'single 0'],			
            ['.1'       , .1    ,'Leading dot'],
            ['1e1'      , 10    ,'exponentials (lower case)'],
            ['1E1'      , 10    ,'exponentials (upper case)'],
            ['1.e1'     , 10    ,'exponentials after dot (lower case)'],
            ['1.E1'     , 10    ,'exponentials after dot (upper case)'],
            ['.1e1'     , 1,    ,'.1e1'],
            ['.1E1'     , 1,    ,'.1E1'],
    );
    plan tests => 1 + 2 * @tests;
}

use_ok('Math::Expression::Evaluator');

my $m = Math::Expression::Evaluator->new();

sub e {
    return $m->parse(shift)->val();
}

sub o {
    return $m->parse(shift)->optimize->val();
}


for (@tests){
    cmp_ok e($_->[0]), '==', $_->[1], $_->[2];
    cmp_ok o($_->[0]), '==', $_->[1], $_->[2] . ' (optimized)';
}



# vim: sw=4 ts=4 expandtab
