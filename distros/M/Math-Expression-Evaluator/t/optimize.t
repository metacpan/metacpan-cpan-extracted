use strict;
use warnings;
use Test::More;

# Test that evaluation with and without optimize() yields the same
# result

my @tests;
BEGIN {
    @tests = (
            'a + 2 * 3',
            '3 + a + 2',
            'a * 2 * 3',
            'a + (2 + 3)',
            'a * (2 * 3)',
            'a + 2 ^ 3',
            'a ^ (-2)',
            'a * 2 * (3 * 4)',
            'a + 2 + (3 + 4)',
            'b = a; b * 2',
    );
    plan tests => scalar @tests;
}

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;

sub o {
    return $m->parse(shift)->optimize->val(shift);
}
sub e {
    return $m->parse(shift)->val(shift);
}


for (@tests){
    my $vars = { a => 1, b => 2 };
    cmp_ok(
            o($_, $vars), 
            '==', 
            e($_, $vars), 
            "Invariant under optimization: $_",
    );
}

# vim: expandtab
