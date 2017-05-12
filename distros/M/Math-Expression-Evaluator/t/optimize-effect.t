use strict;
use warnings;
use Test::More;
use Math::Expression::Evaluator;

# tests that optimize() actually has an effect
# do this by comparing AST sizes
my @tests = (
        # format: [expression, original AST size, reduced AST size]

        # basic sanity checks for _ast_size:
        ['1',               1,  1],
        ['1 + a',           2,  2],

        # optimizer: constant sub expressions are reduced
        ['a + 2 * 3',               3,  2],
        ['a + (2 + 3)',             3,  2],
        ['b + 2^3',                 3,  2],
        ['b * 2^3',                 3,  2],
        [' - 1',                    1,  1],
        # ... indepently of their position in the AST:
        ['a + 2 * 3 + b',           4,  3],
        # ... and inside nested sub trees as well
        ['a + b * 2^3',             4,  3],
        # even nested constant expressions should be fully reduced:
        ['a + (2 + 3 * 4)',         4,  2],
        ['2 + 1 * 5',               3,  1],

        # multiple constants on the same nesting levels:
        ['a + 2 + 3',               3,  2],
        ['2 + a + 3',               3,  2],
        ['a * 2 * 3',               3,  2],
        ['2 * a * 3',               3,  2],
        # ... nested with sub expression:
        ['2 + a + 3 * 4',           4,  2],

        # flattening of non-constant sub expressions:
        ['a + 2 + (b + 3)',         4,  3],
        ['a * 2 * (b * 3)',         4,  3],
        ['a + (1 + (b + 2) + 3)',   5,  3],
        ['a * (1 * (b * 2) * 3)',   5,  3],
        
);

plan tests => 2 * scalar @tests;
my $m = Math::Expression::Evaluator->new();

for (@tests) {
    my ($expr, $l1, $l2) = @$_;
    $m->parse($expr);
    cmp_ok($m->ast_size, '==', $l1, "Unoptimized AST size for $expr");
    $m->optimize();
    cmp_ok($m->ast_size, '==', $l2, "Optimized AST size for $expr");
}

# vim: expandtab
