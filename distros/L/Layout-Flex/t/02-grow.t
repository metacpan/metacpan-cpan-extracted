#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# ── equal grow ───────────────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>0, grow=>1}, {basis=>0, grow=>1}
    ]);
    approx_ok($o[0][2], 150, 0.01, 'equal grow: item0 gets half');
    approx_ok($o[1][2], 150, 0.01, 'equal grow: item1 gets half');
}

# ── unequal grow: 1:2 ratio ───────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>0, grow=>1}, {basis=>0, grow=>2}
    ]);
    approx_ok($o[0][2], 100, 0.01, 'grow 1:2: item0 gets 1/3');
    approx_ok($o[1][2], 200, 0.01, 'grow 1:2: item1 gets 2/3');
}

# ── grow distributes remaining space after basis ──────────────────

{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>100, grow=>1}, {basis=>50, grow=>1}
    ]);
    # free = 300-150 = 150, split equally → each +75
    approx_ok($o[0][2], 175, 0.01, 'grow with basis: item0 = 100+75');
    approx_ok($o[1][2], 125, 0.01, 'grow with basis: item1 = 50+75');
}

# ── grow=0 stays at basis even with free space ───────────────────

{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>100, grow=>0}, {basis=>50, grow=>0}
    ]);
    approx_ok($o[0][2], 100, 0.01, 'grow=0: item0 stays at basis');
    approx_ok($o[1][2], 50,  0.01, 'grow=0: item1 stays at basis');
}

# ── grow=0 mixed with grow>0 ─────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>100, grow=>0},
        {basis=>0,   grow=>1},
    ]);
    approx_ok($o[0][2], 100, 0.01, 'mixed grow: no-grow item stays at basis');
    approx_ok($o[1][2], 200, 0.01, 'mixed grow: grow=1 item absorbs all free space');
}

# ── grow respects max_main ────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, items=>[
        {basis=>50, grow=>1, max_main=>80},
        {basis=>50, grow=>1},
    ]);
    # round 1: each proposed 50+100=150 → item0 capped at 80, frozen
    # round 2: remaining = 300-80-50=170, only item1 grows → 50+170=220
    approx_ok($o[0][2], 80,  0.01, 'max_main: item0 capped at 80');
    approx_ok($o[1][2], 220, 0.01, 'max_main: item1 absorbs remaining 220');
}

done_testing;
