use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 9 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;

sub o {
    return $m->parse(shift)->optimize->val();
}
sub e {
    return $m->parse(shift)->val();
}
sub c {
    return &{$m->parse(shift)->compiled}();
}

my @tests = (
        ['1 2',          2, 'space delimited expressions'],
        ['1; 2',         2, 'colon delimited expressions'],
        ['(1+2) (3-8)', -5, 'space delimited expressions 2'],
        );

for (@tests){
    is e($_->[0]), $_->[1], $_->[2];
    is o($_->[0]), $_->[1], $_->[2] . ' (optimized)';
    is c($_->[0]), $_->[1], $_->[2] . ' (compiled)';
}

# vim: expandtab
