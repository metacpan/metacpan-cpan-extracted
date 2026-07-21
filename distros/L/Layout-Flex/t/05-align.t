#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# ── stretch (default) ─────────────────────────────────────────────

{
    my @o = c(main_size=>200, cross_size=>100, items=>[
        {basis=>80}, {basis=>80}
    ]);
    approx_ok($o[0][1], 0,   0.01, 'stretch: item0 y=0');
    approx_ok($o[0][3], 100, 0.01, 'stretch: item0 h=cross_size');
    approx_ok($o[1][1], 0,   0.01, 'stretch: item1 y=0');
    approx_ok($o[1][3], 100, 0.01, 'stretch: item1 h=cross_size');
}

# stretch respects max_cross
{
    my @o = c(main_size=>200, cross_size=>100, items=>[
        {basis=>80, max_cross=>60}
    ]);
    approx_ok($o[0][3], 60, 0.01, 'stretch: h clamped to max_cross');
}

# stretch respects min_cross
{
    my @o = c(main_size=>200, cross_size=>40, items=>[
        {basis=>80, min_cross=>60}
    ]);
    approx_ok($o[0][3], 60, 0.01, 'stretch: h raised to min_cross');
}

# ── start ─────────────────────────────────────────────────────────

{
    my @o = c(main_size=>200, cross_size=>100, align=>'start', items=>[
        {basis=>80, cross=>30},
        {basis=>80, cross=>50},
    ]);
    approx_ok($o[0][1], 0,  0.01, 'start: item0 y=0');
    approx_ok($o[0][3], 30, 0.01, 'start: item0 h=natural cross');
    approx_ok($o[1][1], 0,  0.01, 'start: item1 y=0');
    approx_ok($o[1][3], 50, 0.01, 'start: item1 h=natural cross');
}

# ── end ───────────────────────────────────────────────────────────

{
    my @o = c(main_size=>200, cross_size=>100, align=>'end', items=>[
        {basis=>80, cross=>30},
        {basis=>80, cross=>50},
    ]);
    approx_ok($o[0][1], 70, 0.01, 'end: item0 y = 100-30');
    approx_ok($o[0][3], 30, 0.01, 'end: item0 h=natural cross');
    approx_ok($o[1][1], 50, 0.01, 'end: item1 y = 100-50');
    approx_ok($o[1][3], 50, 0.01, 'end: item1 h=natural cross');
}

# ── center ────────────────────────────────────────────────────────

{
    my @o = c(main_size=>200, cross_size=>100, align=>'center', items=>[
        {basis=>80, cross=>40},
        {basis=>80, cross=>60},
    ]);
    approx_ok($o[0][1], 30, 0.01, 'center: item0 y = (100-40)/2');
    approx_ok($o[0][3], 40, 0.01, 'center: item0 h=natural cross');
    approx_ok($o[1][1], 20, 0.01, 'center: item1 y = (100-60)/2');
    approx_ok($o[1][3], 60, 0.01, 'center: item1 h=natural cross');
}

# ── align_self overrides container align ──────────────────────────

{
    my @o = c(main_size=>200, cross_size=>100, align=>'stretch', items=>[
        {basis=>80, cross=>30, align_self=>'start'},
        {basis=>80, cross=>30, align_self=>'end'},
        {basis=>80, cross=>30, align_self=>'center'},
        {basis=>80},
    ]);
    approx_ok($o[0][1], 0,  0.01, 'align_self start: y=0');
    approx_ok($o[0][3], 30, 0.01, 'align_self start: h=natural cross');
    approx_ok($o[1][1], 70, 0.01, 'align_self end: y=70');
    approx_ok($o[1][3], 30, 0.01, 'align_self end: h=natural cross');
    approx_ok($o[2][1], 35, 0.01, 'align_self center: y=35');
    approx_ok($o[2][3], 30, 0.01, 'align_self center: h=natural cross');
    approx_ok($o[3][3], 100, 0.01, 'no align_self: inherits container stretch');
}

# align_self=stretch on a container with align=start
{
    my @o = c(main_size=>200, cross_size=>100, align=>'start', items=>[
        {basis=>80, cross=>40, align_self=>'stretch'},
        {basis=>80, cross=>40},
    ]);
    approx_ok($o[0][3], 100, 0.01, 'align_self stretch overrides align=start');
    approx_ok($o[1][3], 40,  0.01, 'no align_self: inherits container start');
}

done_testing;
