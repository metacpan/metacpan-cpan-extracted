#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# 3 items that produce 2 lines:
#   line0: item0 (cross=40)
#   line1: items 1,2 (cross=max(40,60)=60)
# total line cross = 100, container cross_size = 200, free = 100

sub two_line_items {
    return (
        main_size     => 200,
        cross_size    => 200,
        wrap          => 'wrap',
        align         => 'start',
        items => [
            {basis=>120, cross=>40},
            {basis=>120, cross=>40},
            {basis=>80,  cross=>60},
        ],
    );
}

# ── stretch (default) ─────────────────────────────────────────────

{
    # align=stretch (default) — line cross size uses min_cross as baseline
    my @o = c(
        main_size     => 200,
        cross_size    => 200,
        wrap          => 'wrap',
        align_content => 'stretch',
        items => [
            {basis=>120, min_cross=>40},
            {basis=>120, min_cross=>40},
            {basis=>80,  min_cross=>60},
        ],
    );
    # line0 baseline=40, line1 baseline=60; total=100, free=100
    # stretch distributes equally (+50 each) → line0=90, line1=110
    approx_ok($o[0][1], 0,   0.01, 'stretch: line0 starts at y=0');
    approx_ok($o[1][1], 90,  0.01, 'stretch: line1 starts at y=90');
    # items stretch to fill their (expanded) line cross size
    approx_ok($o[0][3], 90,  0.01, 'stretch: item0 h=line0 cross=90');
    approx_ok($o[1][3], 110, 0.01, 'stretch: item1 h=line1 cross=110');
}

# ── start ─────────────────────────────────────────────────────────

{
    my @o = c(two_line_items(), align_content=>'start');
    approx_ok($o[0][1], 0,  0.01, 'start: line0 y=0');
    approx_ok($o[0][3], 40, 0.01, 'start: item0 h=natural cross');
    approx_ok($o[1][1], 40, 0.01, 'start: line1 y=40');
    approx_ok($o[2][3], 60, 0.01, 'start: item2 h=natural cross');
}

# ── end ───────────────────────────────────────────────────────────

{
    my @o = c(two_line_items(), align_content=>'end');
    # free=100 before line0; line0 at 100, line1 at 140
    approx_ok($o[0][1], 100, 0.01, 'end: line0 y=100');
    approx_ok($o[1][1], 140, 0.01, 'end: line1 y=140');
}

# ── center ────────────────────────────────────────────────────────

{
    my @o = c(two_line_items(), align_content=>'center');
    # free=100, half=50 before line0
    approx_ok($o[0][1], 50,  0.01, 'center: line0 y=50');
    approx_ok($o[1][1], 90,  0.01, 'center: line1 y=90');
}

# ── space-between ─────────────────────────────────────────────────

{
    my @o = c(two_line_items(), align_content=>'space-between');
    # 2 lines: gap_before=0, gap_between=100
    approx_ok($o[0][1], 0,   0.01, 'space-between: line0 y=0');
    approx_ok($o[1][1], 140, 0.01, 'space-between: line1 y=40+100=140');
}

# ── space-around ──────────────────────────────────────────────────

{
    my @o = c(two_line_items(), align_content=>'space-around');
    # 2 lines: gap_between=50, gap_before=25
    approx_ok($o[0][1], 25,  0.01, 'space-around: line0 y=25');
    approx_ok($o[1][1], 115, 0.01, 'space-around: line1 y=25+40+50=115');
}

# ── space-evenly ──────────────────────────────────────────────────

{
    my @o = c(two_line_items(), align_content=>'space-evenly');
    # 2 lines: 3 equal gaps of 100/3≈33.33
    my $g = 100 / 3;
    approx_ok($o[0][1], $g,        0.01, 'space-evenly: line0 y=33.33');
    approx_ok($o[1][1], $g+40+$g,  0.01, 'space-evenly: line1 y=106.67');
}

# ── single line: align_content has no effect ──────────────────────

{
    my @o = c(
        main_size     => 200,
        cross_size    => 100,
        wrap          => 'wrap',
        align_content => 'end',
        items => [{basis=>60}, {basis=>60}],
    );
    # only one line (60+60=120≤200), so align_content is irrelevant
    approx_ok($o[0][1], 0, 0.01, 'single line: align_content end has no effect');
    approx_ok($o[0][3], 100, 0.01, 'single line: item fills cross_size');
}

done_testing;
