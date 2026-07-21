#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';
use Layout::Flex;

sub c { Layout::Flex->compute(@_) }
my @items = ({basis=>60}, {basis=>60}, {basis=>60});

# ── start (default) ───────────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, items=>\@items);
    approx_ok($o[0][0], 0,   0.01, 'start: item0 x=0');
    approx_ok($o[1][0], 60,  0.01, 'start: item1 x=60');
    approx_ok($o[2][0], 120, 0.01, 'start: item2 x=120');
}

# ── end ──────────────────────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, justify=>'end', items=>\@items);
    # free=120 pushed before first item
    approx_ok($o[0][0], 120, 0.01, 'end: item0 x=120');
    approx_ok($o[1][0], 180, 0.01, 'end: item1 x=180');
    approx_ok($o[2][0], 240, 0.01, 'end: item2 x=240');
}

# ── center ───────────────────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, justify=>'center', items=>\@items);
    # free=120, half=60 before first item
    approx_ok($o[0][0], 60,  0.01, 'center: item0 x=60');
    approx_ok($o[1][0], 120, 0.01, 'center: item1 x=120');
    approx_ok($o[2][0], 180, 0.01, 'center: item2 x=180');
}

# ── space-between ─────────────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, justify=>'space-between', items=>\@items);
    # free=120, 2 gaps of 60
    approx_ok($o[0][0], 0,   0.01, 'space-between: item0 x=0');
    approx_ok($o[1][0], 120, 0.01, 'space-between: item1 x=120');
    approx_ok($o[2][0], 240, 0.01, 'space-between: item2 x=240');
}

# space-between with 1 item: item sits at start (no gaps possible)
{
    my @o = c(main_size=>300, cross_size=>50, justify=>'space-between',
              items=>[{basis=>60}]);
    approx_ok($o[0][0], 0, 0.01, 'space-between single item: x=0');
}

# ── space-around ──────────────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, justify=>'space-around', items=>\@items);
    # free=120, 3 items → gap_between=40, gap_before=20
    approx_ok($o[0][0], 20,  0.01, 'space-around: item0 x=20');
    approx_ok($o[1][0], 120, 0.01, 'space-around: item1 x=120');
    approx_ok($o[2][0], 220, 0.01, 'space-around: item2 x=220');
}

# ── space-evenly ──────────────────────────────────────────────────

{
    my @o = c(main_size=>300, cross_size=>50, justify=>'space-evenly', items=>\@items);
    # free=120, 4 equal gaps → each 30
    approx_ok($o[0][0], 30,  0.01, 'space-evenly: item0 x=30');
    approx_ok($o[1][0], 120, 0.01, 'space-evenly: item1 x=120');
    approx_ok($o[2][0], 210, 0.01, 'space-evenly: item2 x=210');
}

done_testing;
