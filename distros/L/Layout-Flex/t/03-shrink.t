#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# ── equal shrink ─────────────────────────────────────────────────

{
    my @o = c(main_size=>100, cross_size=>50, items=>[
        {basis=>80, shrink=>1}, {basis=>80, shrink=>1}
    ]);
    # overflow=60, scaled factors equal → each shrinks by 30
    approx_ok($o[0][2], 50, 0.01, 'equal shrink: item0 → 50');
    approx_ok($o[1][2], 50, 0.01, 'equal shrink: item1 → 50');
    approx_ok($o[1][0], 50, 0.01, 'equal shrink: item1 starts at 50');
}

# ── shrink=0 freezes item at basis ───────────────────────────────

{
    my @o = c(main_size=>100, cross_size=>50, items=>[
        {basis=>80, shrink=>0}, {basis=>80, shrink=>0}
    ]);
    approx_ok($o[0][2], 80, 0.01, 'shrink=0: item0 keeps basis');
    approx_ok($o[1][2], 80, 0.01, 'shrink=0: item1 keeps basis');
}

# ── shrink=0 mixed: only shrinkable item absorbs overflow ─────────

{
    my @o = c(main_size=>100, cross_size=>50, items=>[
        {basis=>80, shrink=>0},
        {basis=>80, shrink=>1},
    ]);
    approx_ok($o[0][2], 80, 0.01, 'mixed shrink: no-shrink item keeps basis');
    approx_ok($o[1][2], 20, 0.01, 'mixed shrink: shrinkable item absorbs all overflow');
}

# ── unequal shrink: weighted by shrink*basis ──────────────────────

{
    my @o = c(main_size=>100, cross_size=>50, items=>[
        {basis=>100, shrink=>1},
        {basis=>100, shrink=>2},
    ]);
    # overflow=100; ts = 1*100 + 2*100 = 300
    # item0 shrinks: -100 * (1*100/300) = -33.33 → 66.67
    # item1 shrinks: -100 * (2*100/300) = -66.67 → 33.33
    approx_ok($o[0][2], 200/3, 0.01, 'weighted shrink: item0 shrinks less');
    approx_ok($o[1][2], 100/3, 0.01, 'weighted shrink: item1 shrinks more');
}

# ── min_main floors shrink ────────────────────────────────────────

{
    my @o = c(main_size=>100, cross_size=>50, items=>[
        {basis=>80, shrink=>1, min_main=>60},
        {basis=>80, shrink=>1},
    ]);
    # item0 would shrink to 50 but min_main=60 → frozen at 60
    # remaining = 100-60-80 = -40, only item1 → 80-40=40
    approx_ok($o[0][2], 60, 0.01, 'min_main: item0 floored at 60');
    approx_ok($o[1][2], 40, 0.01, 'min_main: item1 absorbs remaining overflow');
}

done_testing;
