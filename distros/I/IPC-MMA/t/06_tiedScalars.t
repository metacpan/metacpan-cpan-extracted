#!/usr/local/bin/perl

# program to test tied scalars under IPC::MMA

use strict;
use warnings;
use Test::More tests => 18;
use Test::Warn;
use IPC::MMA qw(:basic :scalar);

# test 1: create acts OK
my $mm = mm_create (1, '/tmp/test_lockfile');
ok (defined $mm && $mm, "created shared mem");

# test 2: see if available answers civilly
my $memsize = mm_available ($mm);
ok (defined $memsize && $memsize, "read available mem");

# test 3: get the allocation size
my ($ALLOC_SIZE, $ALLOCBASE, $PSIZE, $IVSIZE, $NVSIZE, $DEFENTS) = mm_alloc_size();
ok ($ALLOC_SIZE && $ALLOC_SIZE <= 256
    && $ALLOCBASE && $ALLOCBASE <= 256
    && $PSIZE && $PSIZE <= 16
    && $IVSIZE && $IVSIZE <= 16
    && $NVSIZE && $NVSIZE <= 16
    && $DEFENTS && $DEFENTS <= 256, "read allocation sizes");

# test 4: make a scalar
my $scalar = mm_make_scalar ($mm);
ok (defined $scalar && $scalar, "make scalar");

# test 5: available should be less by the right amount
my $avail2 = mm_available ($mm);
my $expect = $ALLOCBASE + mm_round_up(2*$PSIZE);
is ($avail2 - $memsize, -$expect,
    "effect on available mem is " . ($avail2 - $memsize));

# test 6: tie the scalar
ok (tie(my $tiedScalar, 'IPC::MM::Scalar', $scalar), "tie scalar");

# test 7: set the scalar value, see how much memory it took
my $val = "0123456789ABCD";
$tiedScalar = $val;

my $avail3 = mm_available ($mm);
$expect = $ALLOCBASE + mm_round_up(length $val);
is ($avail3 - $avail2, -$expect,
    "effect on available mem is " . ($avail3 - $avail2) . " (expected -$expect)");

# test 8: read it back and compare
my $val1 = $tiedScalar;
is ($val1, $val, "check scalar (1)");

# test xx: set it to a longer string
#  effect on avail mem dropped as unreliable
my $val2 = "FEDCBA9876543210123";
$tiedScalar = $val2;
my $avail4 = mm_available ($mm);
#$expect = mm_round_up(length $val) - mm_round_up(length $val2);
#is ($avail4 - $avail3, $expect,
#my $got = $avail4 - $avail3;
#ok ($got >= $expect && $got <= $expect +8,
#    "effect of (increasing size) on available mem");

# test 9: read it back
my $val3 = $tiedScalar;
is ($val3, $val2, "check scalar (2)");

# test 10: set it to a shorter string
#  read back and compare the shorter scalar
my $val4 = "Z12345";
$tiedScalar = $val4;
my $val5 = mm_scalar_fetch ($scalar);
is ($val5, $val4, "check scalar (3)");

# test 11: effect on available memory
# malloc drops a total-16 block into a total-24 hole and can't give back the 8
$expect = mm_round_up(length $val2) - mm_round_up(length $val4) - $ALLOC_SIZE;
my $avail5 = mm_available($mm);
is ($avail5 - $avail4, $expect,
    "effect of store shorter string on avail mem");

# test 12: make another scalar
my $scalar2 = mm_make_scalar ($mm);
ok (defined $scalar2 && $scalar2, "make scalar (2)");

# test 13: tie it
ok (tie(my $tiedScalar2, 'IPC::MMA::Scalar', $scalar2), "tie scalar2");

# test xx: check effect on available memory dropped as unreliable
my $avail6 = mm_available($mm);
#$expect = -(SCALAR_SIZE + $ALLOCBASE);
#my $create2nd = $avail6 - $avail5;
#ok ($create2nd <= $expect && $create2nd >= $expect-8,
#   "effect of (creating 2nd scalar) on avail mem was $create2nd");

# test 14: set the first scalar to a long value
#  read it back and compare
my $val6 = 'x' x (($avail6 >> 1) + 70);
$tiedScalar = $val6;
my $val7 = $tiedScalar;
is ($val7, $val6, "check long scalar");

# test 15: test effect on available memory
my $avail7 = mm_available ($mm);
$expect = mm_round_up(length $val4) - mm_round_up(length $val6);
my $got = $avail7 - $avail6;
ok ($got >= $expect && $got <= $expect + 8,
    "effect of (setting scalar long) on available mem");

# test 16: should not be able to set the second scalar to the long value
warning_like {$tiedScalar2 = $val6} qr/out of memory/,
    "should give warning";

# test 17: free the second scalar, check the effect
mm_free_scalar ($scalar2);
my $avail8 = mm_available ($mm);
is ($avail8 - $avail7, $avail5 - $avail6,
    "effect of (freeing 2nd scalar) on avail mem");

# test 18: free the scalar
mm_free_scalar ($scalar);
my $avail9 = mm_available ($mm);
$expect = $avail8 - $memsize;
is ($avail8 - $avail9, $expect, "effect of (freeing scalar) on avail mem");

# not a test: destroy the shared memory
mm_destroy ($mm);
