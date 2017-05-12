#!/usr/local/bin/perl

# test tied array features of IPC::MMA

use strict;
use warnings;
use Test::More tests => 130;
use IPC::MMA qw(:basic :array);

our ($array, @mmArray, @checkArray);
our $isrand = open (RAND, "</dev/urandom");

sub randStr {
    my $ret = '';
    my ($r, $le);
    if ($_ = int(rand 256)) {
        if ($isrand) {sysread (RAND, $ret, $_)}
        else {
            while (($le = $_ - length($ret)) > 0) {
                $r = pack 'L', int(rand(0xFFFFFFFF));
                $ret .= $le >= 4 ? $r : substr($r, 0, $le);
    }   }   }
    return $ret;
}

# check the whole array
sub checkArray {
    my $testName = shift;
    my $size = scalar @mmArray;
    my $size2 = scalar @checkArray;
    is ($size, $size2,
        "$testName: size of test array and check array should match");
    if ($size2 < $size) {$size = $size2}
    for (my $i=0; $i < $size; $i++) {
        is ($mmArray[$i], $checkArray[$i],"$testName: element $i");
}   }

# compare 2 arrays
sub compArray {
    my ($array1ref, $array2ref, $testName) = @_;
    my $size1 = scalar @$array1ref;
    my $size2 = scalar @$array2ref;
    is ($size1, $size2, "$testName: arrays should be same size");
    if ($size2 < $size1) {$size1 = $size2}
    for (my $i=0; $i <$size1; $i++) {
        is ($$array1ref[$i], $$array2ref[$i], "$testName: element $i");
}   }

# test 1: create acts OK
my $mm = mm_create ((1<<20) - 200, '/tmp/test_lockfile');
ok (defined $mm && $mm,
    "create shared mem");

# test 2: see if available answers civilly
my $memsize = mm_available ($mm);
ok (defined $memsize && $memsize,
    "read available mem");

# test 3: get the allocation size
my ($ALLOC_SIZE, $ALLOCBASE, $PSIZE, $IVSIZE, $NVSIZE, $DEFENTS) = mm_alloc_size();

ok ($ALLOC_SIZE && $ALLOC_SIZE <= 256
    && $ALLOCBASE && $ALLOCBASE <= 256
    && $PSIZE && $PSIZE <= 16
    && $IVSIZE && $IVSIZE <= 16
    && $NVSIZE && $NVSIZE <= 16
    && $DEFENTS && $DEFENTS <= 256, "read allocation sizes");

# the next may increase to 24 if we split out an options word
my $MM_ARRAY_ROOT_SIZE = mm_round_up(2*$PSIZE + 3*$IVSIZE);

# test 4: make a GP array
$array = mm_make_array ($mm, MM_ARRAY);
ok (defined $array && $array, "make array");

# test 5: tie it to a perl array
ok (tie (@mmArray, 'IPC::MM::Array', $array),
    "tie array");

# test 6: memory reqd
my $avail2 = mm_available ($mm);
my $expect = $ALLOCBASE*2 + $MM_ARRAY_ROOT_SIZE + mm_round_up($PSIZE*$DEFENTS);
is ($avail2 - $memsize, -$expect,
    "effect of (make_array MM_ARRAY) on avail mem");

@checkArray = ();

# tests 7-70: populate the array
my ($i, $rc, $bool, $bool2);
my $rand;
$expect = 0;
for ($i=0; $i < $DEFENTS; $i++) {
    $rand = randStr;
    $checkArray[$i] = $rand;
    $mmArray[$i] = $rand;
    if (length($rand)) {$expect += $ALLOCBASE + mm_round_up(length $rand)}
    ok (!($_ = mm_error() || ''),
        "'$_' in assigning to tied array at index $i");
}

# test 71
my $avail3 = mm_available ($mm);
if ($avail3 > $memsize) {BAIL_OUT("mm_avail is nuts after populating array")}
is ($avail3 - $avail2, -$expect,
    "effect of storing ".$DEFENTS." array elements on available memory");

# tests 72: read back and check the array elements
is_deeply (\@mmArray, \@checkArray, "compare arrays after populating");

# test 73
ok ($mmArray[-1] eq $checkArray[-1],
    "element -1 should return last element");

# test 74: fetch returns undef outside the array
ok (!defined $mmArray[-($DEFENTS+1)],
    "element ".(-($DEFENTS+1))." should be undef");

# test 75
ok (!defined $mmArray[$DEFENTS],
    "element ".$DEFENTS." should be undef");

# test 76: test array status: entries
my ($entries, $shiftCount, $typeRet, $options) = mm_array_status ($array);
is ($entries, $DEFENTS,
    "array size returned by mm_array_status");

# test 77
is ($shiftCount, 0,
    "shift count returned by mm_array_status");

# test 78
is ($typeRet, MM_ARRAY,
    "array type returned by mm_array_status");

# test 79: array_status: options
is ($options, 0,
    "options returned by mm_array_status");

# test 80
is (scalar @mmArray, $DEFENTS,
    "array size returned by scalar");

# test 81
ok (exists $mmArray[$DEFENTS - 1],
    "exists: should");

# test 82
ok (exists $mmArray[0],
    "exists: should");

# test 83
ok (exists $mmArray[-1],
    "exists: should");

# test 84
ok (!exists $mmArray[-($DEFENTS+1)],
    "exists: shouldn't");

# test 85
ok (!exists $mmArray[$DEFENTS],
    "exists: shouldn't");

# test 86: delete the end element, see that it returns the right value
my $val = delete $mmArray[$DEFENTS - 1];
is ($val, delete $checkArray[$DEFENTS - 1], "delete should return deleted value");

# test 87: delete at end reduces array size
is (scalar @mmArray, $DEFENTS - 1,
    "array size down by 1 after delete at end");

# test 88
$expect = length($val) ? $ALLOCBASE + mm_round_up(length $val) : 0;
my $avail4 = mm_available ($mm);
if ($avail4 > $memsize) {BAIL_OUT("mm_avail is nuts after delete at end")}
is ($avail4 - $avail3, $expect,
    "effect of delete at end on avail mem");

# test 89: can't delete the same one twice
ok (!defined delete $mmArray[$DEFENTS - 1],
    "can't delete ".($entries - 1)." twice");

# test 90: array size again
is (scalar @mmArray, $DEFENTS - 1,
    "array size not changed by failing delete");

# test 91: middle delete
my $delix = ($DEFENTS >> 1) - 3;
$val = delete $mmArray[$delix];
is ($val, $checkArray[$delix],
    "delete element $delix should have returned element value");

# test 92: reading it should return undef
ok (!defined $mmArray[$delix],
    "deleted element should fetch undef");

# test 93
$expect = length($val) ? $ALLOCBASE + mm_round_up(length $val) : 0;
my $avail5 = mm_available ($mm);
if ($avail5 > $memsize) {BAIL_OUT("mm_avail is nuts after middle delete")}
is ($avail5 - $avail4, $expect,
    "effect of deleting element $delix on avail mem");

# test 94
is (scalar @mmArray, $DEFENTS - 1,
    "array size not changed by delete in middle");

# make checkArray match
$checkArray[$delix] = undef;

# test 95
is_deeply (\@mmArray, \@checkArray, "compare arrays after middle delete");

# test 96: try pop
$val = pop @mmArray;
is ($val, pop @checkArray, "pop both arrays");
$expect = length($val) ? $ALLOCBASE + mm_round_up(length $val) : 0;
# diag "expect = $expect";

# test 97
my $size;
($size, $shiftCount) = mm_array_status ($array);
is ($size, $DEFENTS - 2,
    "pop decreases array size by 1");

# test 98
is ($shiftCount, 0,
    "pop should not affect shift count");

# test 99
is ($mmArray[$DEFENTS-2], undef,
    "get popped index should return undef");

# test 100
is_deeply (\@mmArray, \@checkArray, "compare arrays after pop");

# test 101
my $avail6 = mm_available ($mm);
if ($avail6 > $memsize) {BAIL_OUT("mm_avail is nuts after pop")}
is ($avail6 - $avail5, $expect,
    "effect of pop on avail mem");

# test 102: push it back
is (push (@mmArray, $val), $DEFENTS - 1,
    "push array should return new array size");

push @checkArray, $val;

# test ???
################## come back to this someday ###############
# once in a while the push takes as many as 88 bytes more than it should

my $avail7 = mm_available ($mm);
if ($avail7 > $memsize) {BAIL_OUT("mm_avail is nuts after push")}
#is ($avail7 - $avail6, -$expect,
#    "effect of push on avail mem (length is ".length($val)
#   .", alloc len ".mm_round_up(length $val).")");

# test 103
($size, $shiftCount) = mm_array_status ($array);
is ($size, $DEFENTS - 1,
    "push should increase array size by 1");

# test 104
is ($shiftCount, 0,
    "push should not affect shift count");

# test 105
is_deeply (\@mmArray, \@checkArray, "compare arrays after push");

# test 106: try shift
$val = shift @mmArray;
is ($val, shift @checkArray,
    "value returned by shift");

# test 107
($size, $shiftCount) = mm_array_status ($array);
is ($size, $DEFENTS - 2,
    "shift should decrease array size by 1");

# test 108
is ($shiftCount, 1,
    "shift should increase shift count by 1");

# test 109
$expect = length($val) ? $ALLOCBASE + mm_round_up(length $val) : 0;
my $avail8 = mm_available ($mm);
if ($avail8 > $memsize) {BAIL_OUT("mm_avail is nuts after shift")}
is ($avail8 - $avail7, $expect,
    "effect of shift on avail mem");

# test 110
is_deeply (\@mmArray, \@checkArray, "compare arrays after shift");

# test 111: unshift 7 elements into array
my @ioArray = ();
my $ioN = 7;
$i=0;
while (++$i <= $ioN) {push @ioArray, randStr}
is (unshift (@mmArray, @ioArray), $size + $ioN,
    "unshift $ioN should return new array size");

my $avail8A = mm_available ($mm);
if ($avail8A > $memsize) {BAIL_OUT("mm_avail is nuts after unshift $ioN")}

# test 112:
my ($newsize, $newshiftCount) = mm_array_status ($array);
is ($newsize, $size + $ioN,
    "unshift $ioN should increase array size by $ioN");

# test 113
is ($newshiftCount, $shiftCount - $ioN,
    "unshift $ioN should subtract $ioN from shift count");

# test 114: compare the resulting arrays
unshift (@checkArray, @ioArray);
is_deeply (\@mmArray, \@checkArray, "compare arrays after unshift $ioN");

# tests 115: splice out 9
$ioN = 9;
@ioArray = splice (@mmArray, 38, $ioN);
is (scalar @ioArray, $ioN,
    "splice out $ioN should return correct number of elements");

# tests 116
my @ioArray2 = splice (@checkArray, 38, $ioN);
is_deeply (\@ioArray, \@ioArray2, "compare returned arrays from splice out ${ioN}s");

# test 117
$size = $newsize;
$shiftCount = $newshiftCount;
($newsize, $newshiftCount) = mm_array_status ($array);
is ($newsize, $size - $ioN,
    "splice out $ioN should decrease array size by $ioN");

# test 118
is ($newshiftCount, $shiftCount,
    "splice out $ioN in middle should not affect shift count");

# tests 119
is_deeply (\@mmArray, \@checkArray, "compare arrays after splice out $ioN");

my $avail8B = mm_available ($mm);
if ($avail8B > $memsize) {BAIL_OUT("mm_avail is nuts after splice out $ioN")}

# test 120: splice the same data back in
ok (!defined(splice (@mmArray, 38, 0, @ioArray)),
    "splice in $ioN without deletion should return undef");

# test 121
$size = $newsize;
$shiftCount = $newshiftCount;
($newsize, $newshiftCount) = mm_array_status ($array);
is ($newsize, $size + $ioN,
    "splice in $ioN should increase array size by $ioN");

# test 122
is ($newshiftCount, $shiftCount,
    "splice in $ioN in middle should not affect shift count");

# tests 123
splice (@checkArray, 38, 0, @ioArray);
is_deeply (\@mmArray, \@checkArray, "compare arrays after splice in $ioN");

my $avail8C = mm_available ($mm);
if ($avail8C > $memsize) {BAIL_OUT("mm_avail is nuts after splice in $ioN")}

# tests 124: splice out 21, add 2
$ioN = 21;
my @two = (randStr, randStr);
(@ioArray)  = splice (@mmArray, 3, $ioN, @two);
(@ioArray2) = splice (@checkArray, 3, $ioN, @two);
is (scalar @ioArray, $ioN,
    "splice out $ioN, add 2 should return $ioN elements");

my $avail8D = mm_available ($mm);
if ($avail8D > $memsize) {BAIL_OUT("mm_avail is nuts after splice out $ioN")}

# test 125
is_deeply (\@ioArray, \@ioArray2, "compare returned arrays from splice out");

# test 126
is_deeply (\@mmArray, \@checkArray, "after splice out $ioN");

# tests 127: splice in
ok (!defined(splice (@mmArray, 5, 0, @ioArray)),
    "splice out $ioN (no delete) should return undef");

# tests 128
splice (@checkArray, 5, 0, @ioArray);
is_deeply (\@mmArray, \@checkArray, "compare arrays after splice out $ioN");

# test 129: clear the array and test effect on mem avail
my $avail9 = mm_available ($mm);

@mmArray = ();
my $avail10 = mm_available ($mm);
if ($avail10 > $memsize) {BAIL_OUT("mm_avail is nuts after \@array = ()")}

is ($avail10 - $avail9, $avail2 - $avail9,
    "effect of '\@array = ()' on avail mem a2=$avail2, a9=$avail9, a10=$avail10");

# test 130: free the MM_ARRAY and see that all is back to where we started
mm_free_array ($array);
my $avail99 = mm_available ($mm);
is ($avail99 - $avail10, $memsize - $avail10,
    "effect of mm_free_array on avail mem ms=$memsize, a10=$avail10, a99=$avail99");

# not a test: destroy the shared memory
mm_destroy ($mm);
