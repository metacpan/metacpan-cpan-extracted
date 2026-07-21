#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# ── gap shorthand (sets both main_gap and cross_gap) ─────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 50,
        gap        => 10,
        items      => [{basis=>80}, {basis=>80}, {basis=>80}],
    );
    # free = 300-240-20(gaps) = 40; justify=start → items pack left
    approx_ok($o[0][0], 0,   0.01, 'gap: item0 x=0');
    approx_ok($o[1][0], 90,  0.01, 'gap: item1 x=80+10=90');
    approx_ok($o[2][0], 180, 0.01, 'gap: item2 x=90+80+10=180');
}

# ── main_gap reduces free space before justify distributes it ─────

{
    my @o = c(
        main_size  => 300,
        cross_size => 50,
        main_gap   => 20,
        justify    => 'space-between',
        items      => [{basis=>60}, {basis=>60}, {basis=>60}],
    );
    # outer sizes total=180, gaps=40; free for space-between=80; 2 extra gaps=40 each
    # so gap_between = 20+40 = 60
    approx_ok($o[0][0], 0,   0.01, 'main_gap+space-between: item0 x=0');
    approx_ok($o[1][0], 120, 0.01, 'main_gap+space-between: item1 x=60+60=120');
    approx_ok($o[2][0], 240, 0.01, 'main_gap+space-between: item2 x=120+60+60=240');
}

# ── main_gap with grow: gap reduces available space for grow ──────

{
    my @o = c(
        main_size  => 300,
        cross_size => 50,
        main_gap   => 20,
        items      => [{basis=>0, grow=>1}, {basis=>0, grow=>1}],
    );
    # free after 1 gap of 20 = 280; split equally → each 140
    approx_ok($o[0][2], 140, 0.01, 'main_gap+grow: item0 w=140');
    approx_ok($o[0][0], 0,   0.01, 'main_gap+grow: item0 x=0');
    approx_ok($o[1][2], 140, 0.01, 'main_gap+grow: item1 w=140');
    approx_ok($o[1][0], 160, 0.01, 'main_gap+grow: item1 x=140+20=160');
}

# ── main_gap triggers wrap at correct boundary ────────────────────

{
    my @o = c(
        main_size     => 200,
        cross_size    => 100,
        main_gap      => 20,
        wrap          => 'wrap',
        align         => 'start',
        align_content => 'start',
        items         => [
            {basis=>100, cross=>40},
            {basis=>100, cross=>40},
        ],
    );
    # item0 outer=100; item1 outer=100; gap=20; 100+20+100=220>200 → wrap
    approx_ok($o[0][0], 0,  0.01, 'gap+wrap: item0 x=0 (line0)');
    approx_ok($o[1][0], 0,  0.01, 'gap+wrap: item1 x=0 (line1)');
    approx_ok($o[1][1], 40, 0.01, 'gap+wrap: item1 y=40 (after line0)');
}

# ── cross_gap between lines ───────────────────────────────────────

{
    my @o = c(
        main_size     => 200,
        cross_size    => 200,
        cross_gap     => 20,
        wrap          => 'wrap',
        align         => 'start',
        align_content => 'start',
        items         => [
            {basis=>120, cross=>40},
            {basis=>120, cross=>40},
            {basis=>80,  cross=>60},
        ],
    );
    # line0: item0 at y=0 (cross=40); line1: items1,2 at y=40+20=60
    approx_ok($o[0][1], 0,  0.01, 'cross_gap: line0 y=0');
    approx_ok($o[1][1], 60, 0.01, 'cross_gap: line1 y=40+20=60');
    approx_ok($o[2][1], 60, 0.01, 'cross_gap: item2 same y as item1');
}

# ── gap=0 (no effect on existing tests) ──────────────────────────

{
    my @o = c(
        main_size  => 300,
        cross_size => 50,
        gap        => 0,
        items      => [{basis=>100}, {basis=>100}],
    );
    approx_ok($o[0][0], 0,   0.01, 'gap=0: item0 x=0');
    approx_ok($o[1][0], 100, 0.01, 'gap=0: item1 x=100 (no gap)');
}

done_testing;
