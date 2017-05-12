#!/usr/local/bin/perl

# test boolean array features of IPC::MMA

use strict;
use warnings;
use Test::More tests => 795;
use IPC::MMA qw(:basic :array);

my $array;
my @checkArray = ();

# check the whole array
sub checkArray {
    my $testName = shift;
    my ($size, $size2);
    is ($size = mm_array_fetchsize($array), $size2 = scalar @checkArray,
        "$testName: size of test array and check array should match");
    if ($size2 < $size) {$size = $size2}
    for (my $i=0; $i < $size; $i++) {
        is (mm_array_fetch ($array, $i), $checkArray[$i],
            "$testName: element $i");
}   }

# compare 2 arrays
sub compArray {
    my ($array1ref, $array2ref, $testName) = @_;
    my ($size1, $size2);
    is ($size1 = scalar @$array1ref, $size2 = scalar @$array2ref,
        "$testName: arrays should be same size");
    if ($size2 < $size1) {$size1 = $size2}
    for (my $i=0; $i <$size1; $i++) {
        is ($$array1ref[$i], $$array2ref[$i],
            "$testName: element $i")
}   }

# test 1 is use_ok
BEGIN {use_ok ('IPC::MMA', qw(:basic :array))}

# test 2: create acts OK
my $mm = mm_create (1, '/tmp/test_lockfile');
ok (defined $mm && $mm,
    "create shared mem");

# test 3: see if available answers civilly
my $memsize = mm_available ($mm);
ok (defined $memsize && $memsize,
    "read available mem");

# test 4: get the allocation size
my ($ALLOC_SIZE, $ALLOCBASE, $PSIZE, $IVSIZE, $NVSIZE, $DEFENTS) = mm_alloc_size();

ok ($ALLOC_SIZE && $ALLOC_SIZE <= 256
    && $ALLOCBASE && $ALLOCBASE <= 256
    && $PSIZE && $PSIZE <= 16
    && $IVSIZE && $IVSIZE <= 16
    && $NVSIZE && $NVSIZE <= 16
    && $DEFENTS && $DEFENTS <= 256, "read allocation sizes");

# no alloc_len operand to make array makes default elements at 8/byte
my $ARRAY_SIZE = $DEFENTS>>3;

# the next may increase to 24 if we split out an options word
my $MM_ARRAY_ROOT_SIZE = mm_round_up(2*$PSIZE + 3*$IVSIZE);

# test 5: make a boolean array
$array = mm_make_array ($mm, MM_BOOL_ARRAY);
ok (defined $array && $array,
    "make boolean array");

# test 6: memory reqd
my $avail2 = mm_available ($mm);
my $ARRAY_SIZE_BYTES = mm_round_up($ARRAY_SIZE);
my $expect = $ALLOCBASE*2 + $MM_ARRAY_ROOT_SIZE + $ARRAY_SIZE_BYTES;
is ($avail2 - $memsize, -$expect,
    "effect of (make_array MM_BOOL_ARRAY) on avail mem");

# tests 7-70: populate the array
my $ARRAY_SIZE_BITS = $ARRAY_SIZE_BYTES<<3;
my ($i, $rc, $bool, $bool2);
my $rand=0;
for ($i=0; $i < $ARRAY_SIZE_BITS; $i++) {
    if (!$rand) {$rand = int(rand 1<<30)}
    $bool = $rand & 1 ? 1 : '';;
    $rand >>= 1;
    push @checkArray, $bool;
    ok (($rc = mm_array_store ($array, $i, $bool)) == 1,
        "store element $i in MM_BOOL_ARRAY returned $rc");
    if ($_ = mm_error()) {diag "$_ at mm_array_store (MM_BOOL_ARRAY, $i)"}
}

# test 71
my $avail3 = mm_available ($mm);
is ($avail3 - $avail2, 0,
    "storing ".$ARRAY_SIZE_BITS." BOOL_ARRAY elements should not use any memory");

# tests 72-136: read back and check the array elements
checkArray "initial array";

# test 137: fetch returns undef outside the array
ok (!defined mm_array_fetch_nowrap ($array, -1),
    "fetch_nowrap -1 should return undef");

# test 138
ok (!defined mm_array_fetch ($array, $ARRAY_SIZE_BITS),
    "fetch ".$ARRAY_SIZE_BITS." should return undef");

# test 139: fetch undef outside the array
is (mm_array_fetch ($array, -1), $checkArray[-1],
    "fetch -1 should return last element");

# test 140: test array status: entries
my ($entries, $shiftCount, $type, $options) = mm_array_status ($array);
is ($entries, $ARRAY_SIZE_BITS,
    "array size returned by mm_array_status");

# test 141
is ($shiftCount, 0,
    "shift count returned by mm_array_status");

# test 142
is ($type, MM_BOOL_ARRAY,
    "array type returned by mm_array_status");

# test 143: array_status: options
is ($options, 0,
    "options returned by mm_array_status");

# test 144
is (mm_array_fetchsize ($array), $ARRAY_SIZE_BITS,
    "array size returned by mm_array_fetchsize");

# test 145
ok (mm_array_exists ($array, $ARRAY_SIZE_BITS - 1),
    "mm_array_exists: should");

# test 146
ok (mm_array_exists ($array, 0),
    "mm_array_exists: should");

# test 147
ok (mm_array_exists ($array, -1),
    "mm_array_exists -1: should");

# test 148
ok (!mm_array_exists_nowrap ($array, -1),
    "mm_array_exists: shouldn't");

# test 149
ok (!mm_array_exists ($array, $ARRAY_SIZE_BITS),
    "mm_array_exists: shouldn't");

# test 150: delete the end element, see that it returns the right value
is (mm_array_delete ($array, -1), pop @checkArray,
    "delete -1 should return deleted (last) value");

# test 151: delete at end reduces array size
is (mm_array_fetchsize ($array), $ARRAY_SIZE_BITS - 1,
    "array size down by 1 after delete");

# test 152
ok (!mm_array_delete_nowrap ($array, -1),
    "delete_nowrap -1 should fail");

# test 153
is (mm_array_fetchsize ($array), $ARRAY_SIZE_BITS - 1,
    "no change in array size from losing delete_nowrap -1");

# test 154
my $avail4 = mm_available ($mm);
is ($avail4 - $avail3, 0,
    "delete at end (BOOL) should have no effect on avail mem");

# test 155: can't delete the same one twice
ok (!defined mm_array_delete ($array, $ARRAY_SIZE_BITS - 1),
    "can't delete ".($ARRAY_SIZE_BITS - 1)." twice");

# test 156: array size again
is (mm_array_fetchsize ($array), $ARRAY_SIZE_BITS - 1,
    "array size not changed by failing delete");

# test 157: select a true element for middle delete
my $delix = ($ARRAY_SIZE_BITS >> 1) - 3;
while (!$checkArray[$delix]) {$delix--}

is (mm_array_delete ($array, $delix), $checkArray[$delix],
    "delete element $delix should have returned true");

# test 158
my $avail5 = mm_available ($mm);
is ($avail5 - $avail4, 0,
    "deleting element $delix should have no effect on on avail mem");

# test 159
is (mm_array_fetchsize ($array), $ARRAY_SIZE_BITS - 1,
    "array size not changed by delete in middle");

# middle-deleted bool element can't return undef, only false
$checkArray[$delix] = '';

# test 140-223
checkArray "after middle delete";

# test 224: try pop
$bool = mm_array_pop ($array);
is ($bool, pop @checkArray,
    "pop '$bool' from both arrays");

# test 225
my $size;
($size, $shiftCount) = mm_array_status ($array);
is ($size, $ARRAY_SIZE_BITS - 2,
    "pop decreases array size by 1");

# test 226
 is ($shiftCount, 0,
    "pop should not affect shift count");

# test 227
is (mm_array_fetch ($array, $ARRAY_SIZE_BITS-2), undef,
    "get popped index should return undef");

# test 228-290
checkArray "after pop";

# test 291
my $avail6 = mm_available ($mm);
is ($avail6 - $avail5, 0,
    "pop should have no effect on avail mem");

# test 292: push it back
is (mm_array_push ($array, $bool), $ARRAY_SIZE_BITS - 1,
    "push '$bool' should return array size");
push @checkArray, $bool;

# test 293
($size, $shiftCount) = mm_array_status ($array);
is ($size, $ARRAY_SIZE_BITS - 1,
    "push should increase array size by 1");

# test 294
is ($shiftCount, 0,
    "push should not affect shift count");

# test 295-358
checkArray "after push";

# test 359
my $avail7 = mm_available ($mm);
is ($avail7, $avail5,
    "avail mem after push should == before pop");

# test 360: try shift
is (mm_array_shift ($array), shift @checkArray,
    "value returned by shift");

# test 361
($size, $shiftCount) = mm_array_status ($array);
is ($size, $ARRAY_SIZE_BITS - 2,
    "shift should decrease array size by 1");

# test 362
is ($shiftCount, 1,
    "shift should increase shift count by 1");

# test 363
my $avail8 = mm_available ($mm);
is ($avail8, $avail7,
    "shifting off a zero-length string should have no effect on avail mem");

# test 364-426
checkArray "after shift";

# test 427: unshift 7 elements into array
my @ioArray = ();
my $ioN = 7;
$i=0;
while (++$i <= $ioN) {push @ioArray, int(rand 2) ? 1 : ''}
is (mm_array_unshift ($array, @ioArray), $size + $ioN,
    "unshifting $ioN elements should return new array size");

# test 428
my ($newsize, $newshiftCount) = mm_array_status ($array);
is ($newsize, $size + $ioN,
    "unshift $ioN should increase array size by $ioN");

# test 429
is ($newshiftCount, $shiftCount - $ioN,
    "unshift $ioN should subtract $ioN from shift count");

# tests 430-499: compare the resulting arrays
unshift (@checkArray, @ioArray);
checkArray "after unshift $ioN";

# tests 500: splice out 9 bits that cross a word boundary
$ioN = 9;
@ioArray = mm_array_splice ($array, 29, $ioN);
is (scalar @ioArray, $ioN,
    "splice out $ioN should return correct # elements");

# tests 501-510
my @ioArray2 = splice (@checkArray, 29, $ioN);
compArray (\@ioArray, \@ioArray2,
    "check splice out $ioN (across words) return arrays");

# test 511
$size = $newsize;
$shiftCount = $newshiftCount;
($newsize, $newshiftCount) = mm_array_status ($array);
is ($newsize, $size - $ioN,
    "splice out $ioN should decrease array size by $ioN");

# test 512
is ($newshiftCount, $shiftCount,
    "splice out $ioN in middle should not affect shift count");

# tests 513-573
checkArray "after splice out $ioN";

# test 574: splice the same data back in
is (mm_array_splice ($array, 29, 0, @ioArray), undef,
    "splice in $ioN without deletion should return undef");

# test 575
$size = $newsize;
$shiftCount = $newshiftCount;
($newsize, $newshiftCount) = mm_array_status ($array);
is ($newsize, $size + $ioN,
    "splice in $ioN should increase array size by $ioN");

# test 576
is ($newshiftCount, $shiftCount,
    "splice in $ioN in middle should not affect shift count");

# tests 577-646
splice (@checkArray, 29, 0, @ioArray);
checkArray "after splice in $ioN";

# tests 647: splice out within word, rand
$ioN = 21;
(@ioArray) = mm_array_splice ($array, 3, $ioN, '', 1);
(@ioArray2) = splice (@checkArray, 3, $ioN, '', 1);
is (scalar @ioArray, $ioN,
    "splice out $ioN within word should return $ioN elements");

# tests 648-669
compArray (\@ioArray, \@ioArray2, "check splice out (within word) return arrays");

# tests 670-720
checkArray "after splice out $ioN within word";

# tests 721: splice in within word
is (mm_array_splice ($array, 5, 0, @ioArray), undef,
    "splice in $ioN within word (no delete) should return undef");

# tests 722-793
splice (@checkArray, 5, 0, @ioArray);
checkArray "after splice in $ioN within word";

# test 794: clear the MM_BOOL_ARRAY and test effect on mem avail
mm_array_clear ($array);
my $avail9 = mm_available ($mm);

# after clear, avail mem sould be back to what it was after the make
$expect = $avail2 - $avail8;
is ($avail9 - $avail8, $expect,
    "effect of mm_array_clear on avail mem");

# test 795: free the MM_ARRAY and see that all is back to where we started
mm_free_array ($array);
my $avail99 = mm_available ($mm);
is ($avail99 - $avail9, $memsize - $avail9,
    "effect of (free_array MM_ARRAY) on avail mem");

# not a test: destroy the shared memory
mm_destroy ($mm);
