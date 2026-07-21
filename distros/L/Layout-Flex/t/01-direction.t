#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# ── row (default) ────────────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>80}, {basis=>120}, {basis=>60}
    ]);
    is(scalar @o, 3, 'row: 3 items returned');
    approx_ok($o[0][0], 0,   0.01, 'row: item0 x=0');
    approx_ok($o[0][2], 80,  0.01, 'row: item0 w=basis');
    approx_ok($o[1][0], 80,  0.01, 'row: item1 x=80');
    approx_ok($o[1][2], 120, 0.01, 'row: item1 w=basis');
    approx_ok($o[2][0], 200, 0.01, 'row: item2 x=200');
    approx_ok($o[2][2], 60,  0.01, 'row: item2 w=basis');
}

# y=0 and h=cross_size (stretch) for all items in a row
{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>80}, {basis=>120}
    ]);
    approx_ok($o[0][1], 0,  0.01, 'row: item0 y=0');
    approx_ok($o[0][3], 50, 0.01, 'row: item0 h=cross_size');
    approx_ok($o[1][1], 0,  0.01, 'row: item1 y=0');
    approx_ok($o[1][3], 50, 0.01, 'row: item1 h=cross_size');
}

# ── column ───────────────────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>80, direction=>'column', items=>[
        {basis=>80}, {basis=>120}, {basis=>60}
    ]);
    is(scalar @o, 3, 'column: 3 items returned');
    approx_ok($o[0][1], 0,   0.01, 'column: item0 y=0');
    approx_ok($o[0][3], 80,  0.01, 'column: item0 h=basis');
    approx_ok($o[1][1], 80,  0.01, 'column: item1 y=80');
    approx_ok($o[1][3], 120, 0.01, 'column: item1 h=basis');
    approx_ok($o[2][1], 200, 0.01, 'column: item2 y=200');
    approx_ok($o[2][3], 60,  0.01, 'column: item2 h=basis');
}

# x=0 and w=cross_size (stretch) for all items in a column
{
    my @o = c(main_size=>300, cross_size=>80, direction=>'column', items=>[
        {basis=>80}, {basis=>60}
    ]);
    approx_ok($o[0][0], 0,  0.01, 'column: item0 x=0');
    approx_ok($o[0][2], 80, 0.01, 'column: item0 w=cross_size');
    approx_ok($o[1][0], 0,  0.01, 'column: item1 x=0');
    approx_ok($o[1][2], 80, 0.01, 'column: item1 w=cross_size');
}

# ── edge cases ───────────────────────────────────────────────────

{
    my @o = c(main_size=>200, cross_size=>50, items=>[{basis=>200}]);
    is(scalar @o, 1, 'single item: 1 rect returned');
    approx_ok($o[0][0], 0,   0.01, 'single item: x=0');
    approx_ok($o[0][2], 200, 0.01, 'single item: w=basis');
}

{
    my @o = c(main_size=>300, cross_size=>50, items=>[]);
    is(scalar @o, 0, 'empty items: empty list returned');
}

done_testing;
