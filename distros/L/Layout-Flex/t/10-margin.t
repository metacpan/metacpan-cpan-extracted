#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# ── margin shorthand (all sides) ─────────────────────────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 100,
        items      => [
            {basis=>80, margin=>10},
            {basis=>80, margin=>10},
        ],
    );
    # item0 outer=100, item1 outer=100; total=200; free=100; justify=start
    # item0: x = margin_left=10, w=80
    # item1: x = 10+80+10(margin_right) + 10(margin_left) = 110, w=80
    approx_ok($o[0][0], 10,  0.01, 'margin: item0 x=margin_left');
    approx_ok($o[0][2], 80,  0.01, 'margin: item0 w=basis');
    approx_ok($o[1][0], 110, 0.01, 'margin: item1 x=10+80+10+10=110');
    approx_ok($o[1][2], 80,  0.01, 'margin: item1 w=basis');
    # cross: stretch → h = cross_size - margin_top - margin_bottom = 80
    approx_ok($o[0][1], 10,  0.01, 'margin: item0 y=margin_top');
    approx_ok($o[0][3], 80,  0.01, 'margin: item0 h=cross_size-margins');
}

# ── individual margin sides ───────────────────────────────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 100,
        items      => [
            {basis=>80, margin_left=>5, margin_right=>15},
            {basis=>80},
        ],
    );
    # item0 outer_main = 5+80+15=100; item1 outer=80
    # item0 x = margin_left=5; item1 x = 5+80+15=100
    approx_ok($o[0][0], 5,   0.01, 'margin_left/right: item0 x=5');
    approx_ok($o[1][0], 100, 0.01, 'margin_left/right: item1 x=100');
}

# ── margin_top / margin_bottom affect cross placement ─────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 100,
        items      => [
            {basis=>80, margin_top=>10, margin_bottom=>20},
        ],
    );
    # stretch: h = 100-10-20=70; y=margin_top=10
    approx_ok($o[0][1], 10, 0.01, 'margin_top: item y=10');
    approx_ok($o[0][3], 70, 0.01, 'margin_top/bottom: item h=70');
}

# ── margin affects grow: outer size reduces free space ────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 50,
        items      => [
            {basis=>0, grow=>1, margin_left=>10, margin_right=>10},
            {basis=>0, grow=>1},
        ],
    );
    # item0 outer = 10+w0+10; item1 outer = w1
    # free = 300-20-0-w0-w1; grow equally → w0=w1=140
    # but: free_after_margins = 300-20 = 280; split equally → each 140
    approx_ok($o[0][2], 140, 0.01, 'margin+grow: item0 w=140');
    approx_ok($o[0][0], 10,  0.01, 'margin+grow: item0 x=margin_left=10');
    approx_ok($o[1][2], 140, 0.01, 'margin+grow: item1 w=140');
    approx_ok($o[1][0], 160, 0.01, 'margin+grow: item1 x=10+140+10=160');
}

# ── margin + align center on cross axis ───────────────────────────

{
    my @o = c(
        main_size  => 200,
        cross_size => 100,
        align      => 'center',
        items      => [
            {basis=>80, cross=>40, margin_top=>5, margin_bottom=>5},
        ],
    );
    # avail = 100-5-5=90; center within avail: offset=(90-40)/2=25; y=5+25=30
    approx_ok($o[0][1], 30, 0.01, 'margin+center: item y=5+25=30');
    approx_ok($o[0][3], 40, 0.01, 'margin+center: item h=natural cross');
}

# ── margin + align end on cross axis ──────────────────────────────

{
    my @o = c(
        main_size  => 200,
        cross_size => 100,
        align      => 'end',
        items      => [
            {basis=>80, cross=>40, margin_top=>10, margin_bottom=>10},
        ],
    );
    # end: cp = lcs - ic - margin_bottom = 100-40-10=50; y = 50
    approx_ok($o[0][1], 50, 0.01, 'margin+end: item y=50');
    approx_ok($o[0][3], 40, 0.01, 'margin+end: item h=natural cross');
}

# ── column direction: margin_top/bottom → main axis ───────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 100,
        direction  => 'column',
        items      => [
            {basis=>80, margin_top=>10, margin_bottom=>15},
            {basis=>80},
        ],
    );
    # column: main=y axis; margin_top→margin_main_start, margin_bottom→margin_main_end
    # item0 outer_main = 10+80+15=105; item1=80; total=185; free=115
    # justify=start: item0 y=10 (margin_top), item1 y=10+80+15=105
    approx_ok($o[0][1], 10,  0.01, 'column margin: item0 y=margin_top');
    approx_ok($o[0][3], 80,  0.01, 'column margin: item0 h=basis');
    approx_ok($o[1][1], 105, 0.01, 'column margin: item1 y=105');
}

# ── margin + gap combined ─────────────────────────────────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 50,
        main_gap   => 10,
        items      => [
            {basis=>80, margin_left=>5,  margin_right=>5},
            {basis=>80, margin_left=>5,  margin_right=>5},
        ],
    );
    # item0 outer=90, item1 outer=90; gap=10; total=190; free=110
    # item0: x=5; item1: x=5+80+5+10+5=105
    approx_ok($o[0][0], 5,   0.01, 'margin+gap: item0 x=margin_left');
    approx_ok($o[1][0], 105, 0.01, 'margin+gap: item1 x=5+80+5+10+5=105');
}

done_testing;
