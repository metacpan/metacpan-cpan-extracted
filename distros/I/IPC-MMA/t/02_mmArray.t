#!/usr/local/bin/perl

# test GP array (MM_ARRAY) features of IPC::MMA

use strict;
use warnings;
use Test::More tests => 143;
use Test::Warn;
use IPC::MMA qw(:basic :array);

use constant ARRAY_SIZE => 32;

# this encoder makes a zero-length string for a 0 argument
sub n2alpha {
    my $n = shift;
    my $ret = '';
    while ($n) {
        $ret .= chr(ord('a') + $n % 26);
        $n = int($n/26);
    }
    return $ret;
}

sub alpha2n {
    my $ret = 0;
    for (split //, shift) {
        if (!/^[a-z]$/) {die "non-lc-alpha character in alpha2n argument"}
        $ret = $ret * 26 + ord($_) - ord('a');
    }
    return $ret;
}

# test 1 is use_ok
BEGIN {use_ok ('IPC::MMA', qw(:basic :array))}

# test 2: create acts OK
my $mm = mm_create (1, '/tmp/test_lockfile');
ok (defined $mm && $mm, "create shared mem");

# test 3: see if available answers civilly
my $memsize = mm_available ($mm);
ok ($memsize && $memsize > 3800, "read available mem");

# test 4: get the allocation size
my ($ALLOC_SIZE, $ALLOCBASE, $PSIZE, $IVSIZE, $NVSIZE, $DEFENTS) = mm_alloc_size();

ok ($ALLOC_SIZE && $ALLOC_SIZE <= 256
    && $ALLOCBASE && $ALLOCBASE <= 256
    && $PSIZE && $PSIZE <= 16
    && $IVSIZE && $IVSIZE <= 16
    && $NVSIZE && $NVSIZE <= 16
    && $DEFENTS && $DEFENTS <= 256, "read allocation sizes");

# this may increase if we split out an options word
my $MM_ARRAY_ROOT_SIZE = mm_round_up(2*$PSIZE + 3*$IVSIZE);

# test 5: make a GP array
my $array = mm_make_array ($mm, MM_ARRAY, ARRAY_SIZE);
ok (defined $array && $array,
    "make array");

# test 6: memory reqd
my $avail2 = mm_available ($mm);
my $expect = $ALLOCBASE*2 + $MM_ARRAY_ROOT_SIZE + mm_round_up($PSIZE*ARRAY_SIZE);
is ($avail2 - $memsize, -$expect,
    "effect of (make_array MM_ARRAY) on avail mem");

# tests 7-38: populate the array
my ($i, $rc);
for ($i=0; $i < ARRAY_SIZE; $i++) {
    ok (($rc = mm_array_store ($array, $i, n2alpha($i))) == 1,
        "store element $i in MM_ARRAY returned $rc");
    if ($_ = mm_error()) {diag "$_ at mm_array_store (MM_ARRAY, $i)"}
}

# test 39
# element 0 is zero-length and so doesn't use any memory
my $avail3 = mm_available ($mm);
$expect = (ARRAY_SIZE - 1) * ($ALLOCBASE + mm_round_up(2));
is ($avail3 - $avail2, -$expect,
    "effect of ".ARRAY_SIZE." mm_array_store(MM_ARRAY)'s on avail mem");

# tests 40-71: read back and check the array elements
for ($i = ARRAY_SIZE-1; $i >= 0; $i--) {
#for ($i=0; $i < ARRAY_SIZE; $i++) {
    is (mm_array_fetch ($array, $i), n2alpha($i),
        "read element $i of MM_ARRAY");
}

# test 72: fetch returns undef outside the array
ok (!defined mm_array_fetch_nowrap ($array, -1),
    "fetch_nowrap -1 should return undef");

# test 73
ok (!defined mm_array_fetch ($array, -(ARRAY_SIZE+1)),
    "fetch -1 ".(-(ARRAY_SIZE+1))."should return undef");

# test 74
ok (!defined mm_array_fetch ($array, ARRAY_SIZE),
    "get ".ARRAY_SIZE." should return undef");

# test 75
is (mm_array_fetch ($array, -1), n2alpha(ARRAY_SIZE-1),
    "fetch -1 should return last entry");

# test 76: test array status: entries
my ($entries, $shiftCount, $type, $options) = mm_array_status ($array);
is ($entries, ARRAY_SIZE,
    "array size returned by mm_array_status");

# test 77
is ($shiftCount, 0,
    "shift count returned by mm_array_status");

# test 78
is ($type, MM_ARRAY,
    "array type returned by mm_array_status");

# test 79: array_status: options
is ($options, 0,
    "options returned by mm_array_status");

# test 80
is (mm_array_fetchsize ($array), ARRAY_SIZE,
    "array size returned by mm_array_fetchsize");

# test 81
ok (!defined mm_array_fetch_nowrap ($array, -1),
    "fetch_nowrap -1 should return undef");

# test 82
ok (mm_array_exists ($array, ARRAY_SIZE - 1),
    "mm_array_exists: should");

# test 83
ok (mm_array_exists ($array, 0),
    "mm_array_exists: should");

# test 84
ok (mm_array_exists ($array, -1),
    "mm_array_exists -1: should");

# test 85
ok (!mm_array_exists_nowrap ($array, -1),
    "mm_array_exists_nowrap -1: shouldn't");

# test 86
ok (!mm_array_exists ($array, ARRAY_SIZE),
    "mm_array_exists: shouldn't");

# test 87: delete the end element, see that it returns the right value
is (mm_array_delete ($array, -1),
    n2alpha(ARRAY_SIZE - 1),
    "delete last element returns value");

# test 88: delete at end reduces array size
is (mm_array_fetchsize ($array), ARRAY_SIZE - 1,
    "array size down by 1 after delete");

# test 89
my $avail4 = mm_available ($mm);
$expect = $ALLOCBASE + mm_round_up(2);
is ($avail4 - $avail3, $expect,
    "effect of delete at end (2 byte value) on avail mem");

# test 90: delete -1 with nowrap should not
ok (!defined mm_array_delete_nowrap ($array, -1),
    "delete -1 element with nowarp shoyld fail");

# test 91: array size again
is (mm_array_fetchsize ($array), ARRAY_SIZE - 1,
    "array size not changed by failing delete");

# test 92: can't delete the same one twice
ok (!defined mm_array_delete ($array, ARRAY_SIZE - 1),
    "can't delete ".(ARRAY_SIZE - 1)." twice");

# test 93: array size again
is (mm_array_fetchsize ($array), ARRAY_SIZE - 1,
    "array size not changed by failing delete");

# test 94: delete element in the middle
use constant MIDDLE_INDEX => (ARRAY_SIZE >> 1) - 3;
is (mm_array_delete ($array, MIDDLE_INDEX), n2alpha(MIDDLE_INDEX),
    "delete in middle returns its value");

# test 95
my $avail5 = mm_available ($mm);
# $expect should have the same value
is ($avail5 - $avail4, $expect,
    "effect of delete in middle (2 byte value) on avail mem");

# test 96
is (mm_array_fetchsize ($array), ARRAY_SIZE - 1,
    "array size not changed by delete in middle");

# test 97
is (mm_array_fetch ($array, MIDDLE_INDEX-1), n2alpha(MIDDLE_INDEX-1),
    "element before middle delete is still there");

# test 98
my $val;
is (mm_array_fetch ($array, MIDDLE_INDEX), undef,
    "getting deleted element should return undefined");

# test 99
is (mm_array_fetch ($array, MIDDLE_INDEX+1), n2alpha(MIDDLE_INDEX+1),
    "element after middle delete is still there");

# test 100: try pop
my $n2aM2 = n2alpha(ARRAY_SIZE - 2);
is (mm_array_pop ($array), $n2aM2,
    "pop array returns proper value");

# test 101
my $size;
($size, $shiftCount) = mm_array_status ($array);
is ($size, ARRAY_SIZE - 2,
    "pop decreases array size by 1");

# test 102
is ($shiftCount, 0,
    "pop should not affect shift count");

# test 103
is (mm_array_fetch ($array, ARRAY_SIZE - 2), undef,
    "get popped element should return undef");

# test 104
my $n2aM3 = n2alpha(ARRAY_SIZE - 3);
is (mm_array_fetch ($array, ARRAY_SIZE - 3), $n2aM3,
    "element before popped one should be unchanged");

# test 105
my $avail6 = mm_available ($mm);
is ($avail6 - $avail5, $expect,
    "effect of pop on avail mem");

# test 106: push it back
is (mm_array_push ($array, $n2aM2), ARRAY_SIZE - 1,
    "push should return array size");

# test 107
($size, $shiftCount) = mm_array_status ($array);
is ($size, ARRAY_SIZE - 1,
    "push should increase array size by 1");

# test 108
is ($shiftCount, 0,
    "push should not affect shift count");

# test 109
is (mm_array_fetch ($array, ARRAY_SIZE - 2), $n2aM2,
    "get pushed element");

# test 110
is (mm_array_fetch ($array, ARRAY_SIZE - 3), $n2aM3,
    "element before pushed one should be unchanged");

# test 111
my $avail7 = mm_available ($mm);
is ($avail7, $avail5,
    "avail mem after push should == before pop");

# test 112: try shift
my $n2a0 = n2alpha(0);
is (mm_array_shift ($array), $n2a0,
    "shift returns proper value");

# test 113
($size, $shiftCount) = mm_array_status ($array);
is ($size, ARRAY_SIZE - 2,
    "shift should decrease array size by 1");

# test 114
is ($shiftCount, 1,
    "shift should increase shift count by 1");

# test 115
my $n2a1 = n2alpha(1);
is (mm_array_fetch ($array, 0), $n2a1,
    "check element 0 after shift");

# test 116
my $avail8 = mm_available ($mm);
is ($avail8, $avail7,
    "shifting off a zero-length string should have no effect on avail mem");

# test 117: unshift two values into front of array
is (mm_array_unshift ($array, 2009, $n2a0), ARRAY_SIZE,
    "unshift should return array size");

# test 118
($size, $shiftCount) = mm_array_status ($array);
is ($size, ARRAY_SIZE,
    "unshift 2 values should increase array size by 2");

# test 119
is ($shiftCount, -1,
    "unshift 2 values should decrease shift count from 1 to -1");

# test 120
is (mm_array_fetch ($array, 0), 2009,
    "check first unshifted value");

# test 121
is (mm_array_fetch ($array, 1), $n2a0,
    "check 2nd unshifted value");

# test 122
is (mm_array_fetch ($array, 2), $n2a1,
    "check value following unshifted ones");

# test 123
my $avail9 = mm_available ($mm);
is ($avail9 - $avail8, -$expect,
    "effect of unshifting (0-length value, normal value) on avail mem");

# test 124: a full-blown splice
my @dels = mm_array_splice ($array, 1, 2, 4701, '', "foo");
is (scalar @dels, 2,
    "splice with 2 deleted should return 2 elements");

# test 125
is ($dels[0], $n2a0,
    "1st element returned by splice");

# test 126
is ($dels[1], $n2a1,
    "2nd element returned by splice");

# test 127
($size, $shiftCount) = mm_array_status ($array);
is ($size, ARRAY_SIZE+1,
    "splice replacing 2 by 3 should increase array size by 1");

# test 128
is ($shiftCount, -1,
    "splice at 1 should not change shift count");

# test 129
is (mm_array_fetch ($array, 0), 2009,
    "element before splice should not be changed");

# test 130
is (mm_array_fetch ($array, 1), 4701,
    "1st spliced-in element");

# test 131
is (mm_array_fetch ($array, 2), '',
    "2nd spliced-in element");

# test 132
is (mm_array_fetch ($array, 3), 'foo',
    "3rd spliced-in element");

# test 133
is (mm_array_fetch ($array, 4), n2alpha(2),
    "check element after splice");

# test 134
# the expansion of the array block is by 16 plus an allocation block,
#  and the splice added a short element
my $avail10 = mm_available ($mm);
$expect = 16 + $ALLOC_SIZE + $ALLOCBASE + mm_round_up(4);

is ($avail10 - $avail9, -$expect,
    "effect of splice on avail mem");

# test 135: make a long scalar and overwrite the last entry with it
my $longString = 'x' x (($avail10 >> 1) + 256);
ok (mm_array_store ($array, ARRAY_SIZE, $longString),
    "result of storing long string");

# test 136
ok (mm_array_fetch($array, ARRAY_SIZE) eq $longString,
    "read back long string and compare it");

# test 137
my $avail11 = mm_available ($mm);
# we replaced a short entry by a long one
$expect = mm_round_up(length $longString) - mm_round_up(2);
is ($avail11 - $avail10, -$expect,
    "effect of storing long string on avail mem");

# test 138
is (mm_array_fetchsize ($array), ARRAY_SIZE+1,
    "array size is +1 after first long store");

# test 139: shouldn't be able to add another string like that
warning_like {$rc = mm_array_store ($array, ARRAY_SIZE+1, $longString)} qr/out of memory/,
    "trying to store 2nd long string should give warning";

# test 140
ok (defined $rc && !$rc,
    "return code should say 2nd long string didn't get stored");

# test 141
is (mm_array_fetchsize ($array), ARRAY_SIZE+1,
    "array size not changed by 2nd long store");

# test 142: clear the MM_ARRAY and test effect on mem avail
# should be back to avail after original make
mm_array_clear ($array, ARRAY_SIZE);
my $avail12 = mm_available ($mm);
$expect = $avail2 - $avail11;
my $got = $avail12 - $avail11;
is ($got, $expect,
    "effect of mm_array_clear on avail mem, got $got, expected $expect");

# test 143: free the MM_ARRAY and see that all is back to where we started
mm_free_array ($array);
my $avail99 = mm_available ($mm);
is ($avail99 - $avail12, $memsize - $avail12,
    "effect of (free_array MM_ARRAY) on avail mem");

# not a test: destroy the shared memory
mm_destroy ($mm);
