#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }

# ── nowrap (default) ──────────────────────────────────────────────

# all items stay on one line even if they overflow
{
    my @o = c(main_size=>100, cross_size=>50, items=>[
        {basis=>80, shrink=>0}, {basis=>80, shrink=>0}
    ]);
    approx_ok($o[0][0], 0,  0.01, 'nowrap: item0 x=0');
    approx_ok($o[1][0], 80, 0.01, 'nowrap: item1 x=80 (no wrap)');
    approx_ok($o[0][1], 0,  0.01, 'nowrap: both items at y=0');
    approx_ok($o[1][1], 0,  0.01, 'nowrap: item1 also at y=0');
}

# ── wrap: basic line-breaking ─────────────────────────────────────

# 3 items, item0 fits on line0, items 1+2 wrap to line1
{
    my @o = c(
        main_size  => 200,
        cross_size => 100,
        wrap       => 'wrap',
        align      => 'start',
        align_content => 'start',
        items => [
            {basis=>120, cross=>40},
            {basis=>120, cross=>40},
            {basis=>80,  cross=>40},
        ],
    );
    is(scalar @o, 3, 'wrap: 3 items returned');
    # line0: item0
    approx_ok($o[0][0], 0,   0.01, 'wrap: line0 item0 x=0');
    approx_ok($o[0][2], 120, 0.01, 'wrap: line0 item0 w=basis');
    approx_ok($o[0][1], 0,   0.01, 'wrap: line0 item0 y=0');
    approx_ok($o[0][3], 40,  0.01, 'wrap: line0 item0 h=cross');
    # line1: items 1,2
    approx_ok($o[1][0], 0,   0.01, 'wrap: line1 item1 x=0 (new line)');
    approx_ok($o[1][2], 120, 0.01, 'wrap: line1 item1 w=basis');
    approx_ok($o[1][1], 40,  0.01, 'wrap: line1 item1 y=40 (after line0)');
    approx_ok($o[2][0], 120, 0.01, 'wrap: line1 item2 x=120');
    approx_ok($o[2][2], 80,  0.01, 'wrap: line1 item2 w=basis');
    approx_ok($o[2][1], 40,  0.01, 'wrap: line1 item2 y=40');
}

# each item exactly fills line (basis = main_size): each on its own line
{
    my @o = c(
        main_size  => 100,
        cross_size => 150,
        wrap       => 'wrap',
        align      => 'start',
        align_content => 'start',
        items => [
            {basis=>100, cross=>50},
            {basis=>100, cross=>50},
            {basis=>100, cross=>50},
        ],
    );
    approx_ok($o[0][1], 0,   0.01, 'wrap exact: item0 y=0');
    approx_ok($o[1][1], 50,  0.01, 'wrap exact: item1 y=50');
    approx_ok($o[2][1], 100, 0.01, 'wrap exact: item2 y=100');
    approx_ok($o[0][0], 0,   0.01, 'wrap exact: all x=0');
    approx_ok($o[1][0], 0,   0.01, 'wrap exact: item1 x=0');
    approx_ok($o[2][0], 0,   0.01, 'wrap exact: item2 x=0');
}

# ── wrap + grow: per-line independent grow pass ───────────────────

{
    my @o = c(
        main_size  => 200,
        cross_size => 100,
        wrap       => 'wrap',
        align      => 'start',
        align_content => 'start',
        items => [
            {basis=>80, grow=>1, cross=>40},
            {basis=>80, grow=>1, cross=>40},
            {basis=>80, grow=>1, cross=>40},
        ],
    );
    # line0: items 0,1 (80+80=160≤200); item2 would make 240>200 → wraps
    # line0 free=40, split equally → each +20 → 100
    approx_ok($o[0][2], 100, 0.01, 'wrap+grow: line0 item0 grows to 100');
    approx_ok($o[1][2], 100, 0.01, 'wrap+grow: line0 item1 grows to 100');
    approx_ok($o[1][0], 100, 0.01, 'wrap+grow: line0 item1 starts at x=100');
    # line1: item2 alone, grows to fill main_size=200
    approx_ok($o[2][2], 200, 0.01, 'wrap+grow: line1 item2 grows to 200');
    approx_ok($o[2][0], 0,   0.01, 'wrap+grow: line1 item2 x=0');
}

# ── wrap-reverse: lines in reverse cross order ────────────────────

{
    my @o = c(
        main_size     => 200,
        cross_size    => 100,
        wrap          => 'wrap-reverse',
        align         => 'start',
        align_content => 'start',
        items => [
            {basis=>120, cross=>30},
            {basis=>120, cross=>30},
            {basis=>80,  cross=>40},
        ],
    );
    # line0 (item0): cross=30; line1 (items 1,2): cross=max(30,40)=40
    # wrap-reverse: line1 placed first (y=0), then line0 (y=40)
    approx_ok($o[0][1], 40, 0.01, 'wrap-reverse: first line at y=40');
    approx_ok($o[1][1], 0,  0.01, 'wrap-reverse: second line at y=0');
    approx_ok($o[2][1], 0,  0.01, 'wrap-reverse: item2 in second line at y=0');
}

# ── column + wrap ─────────────────────────────────────────────────

{
    my @o = c(
        main_size     => 200,
        cross_size    => 200,
        direction     => 'column',
        wrap          => 'wrap',
        align         => 'start',
        align_content => 'start',
        items => [
            {basis=>120, cross=>40},
            {basis=>120, cross=>40},
            {basis=>80,  cross=>50},
        ],
    );
    # col0: item0 (h=120); item1 would make 240>200 → new column
    # col0: item0 at x=0 y=0 w=40 h=120
    # col1: items 1,2 at x=40; item1 y=0 h=120; item2 y=120 h=80
    approx_ok($o[0][0], 0,   0.01, 'col wrap: item0 x=0 (col0)');
    approx_ok($o[0][1], 0,   0.01, 'col wrap: item0 y=0');
    approx_ok($o[0][2], 40,  0.01, 'col wrap: item0 w=cross');
    approx_ok($o[0][3], 120, 0.01, 'col wrap: item0 h=basis');
    approx_ok($o[1][0], 40,  0.01, 'col wrap: item1 x=40 (col1)');
    approx_ok($o[1][1], 0,   0.01, 'col wrap: item1 y=0');
    approx_ok($o[2][0], 40,  0.01, 'col wrap: item2 x=40 (same col)');
    approx_ok($o[2][1], 120, 0.01, 'col wrap: item2 y=120');
}

done_testing;
