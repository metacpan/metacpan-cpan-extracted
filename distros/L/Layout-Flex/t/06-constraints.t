#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# ── max_main ──────────────────────────────────────────────────────

# max_main clamps item before grow
{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>50, grow=>1, max_main=>80},
        {basis=>50, grow=>1},
    ]);
    approx_ok($o[0][2], 80,  0.01, 'max_main: item0 capped at 80');
    approx_ok($o[1][2], 220, 0.01, 'max_main: item1 absorbs remaining space');
}

# max_main applies even without grow (basis clamped at init)
{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>200, max_main=>80},
    ]);
    approx_ok($o[0][2], 80, 0.01, 'max_main: basis clamped at init');
}

# ── min_main ──────────────────────────────────────────────────────

# min_main floors item during shrink
{
    my @o = c(main_size=>100, cross_size=>50, items=>[
        {basis=>80, shrink=>1, min_main=>60},
        {basis=>80, shrink=>1},
    ]);
    approx_ok($o[0][2], 60, 0.01, 'min_main: item0 floored at 60');
    approx_ok($o[1][2], 40, 0.01, 'min_main: item1 absorbs remaining overflow');
}

# min_main raises basis at init (before shrink)
{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>20, min_main=>60},
    ]);
    approx_ok($o[0][2], 60, 0.01, 'min_main: basis raised at init');
}

# ── max_cross ─────────────────────────────────────────────────────

# max_cross clamps stretch height
{
    my @o = c(main_size=>200, cross_size=>100, items=>[
        {basis=>80, max_cross=>60},
    ]);
    approx_ok($o[0][3], 60, 0.01, 'max_cross: stretch h clamped to 60');
}

# max_cross clamps natural cross size under non-stretch align
{
    my @o = c(main_size=>200, cross_size=>100, align=>'start', items=>[
        {basis=>80, cross=>90, max_cross=>60},
    ]);
    approx_ok($o[0][3], 60, 0.01, 'max_cross: natural cross clamped to 60');
}

# ── min_cross ─────────────────────────────────────────────────────

# min_cross raises stretch height above cross_size (when min > line cross)
{
    my @o = c(main_size=>200, cross_size=>40, items=>[
        {basis=>80, min_cross=>60},
    ]);
    approx_ok($o[0][3], 60, 0.01, 'min_cross: stretch h raised to 60');
}

# min_cross raises natural cross size under non-stretch align
{
    my @o = c(main_size=>200, cross_size=>100, align=>'start', items=>[
        {basis=>80, cross=>20, min_cross=>50},
    ]);
    approx_ok($o[0][3], 50, 0.01, 'min_cross: natural cross raised to 50');
}

done_testing;
