#!/usr/local/bin/perl

# test fixed-length array features of IPC::MMA

use strict;
use warnings;
use Test::More tests => 4750;
use IPC::MMA qw(:basic :array);

our @typeNames = ("MM_ARRAY", "MM_UINT_ARRAY", "MM_INT_ARRAY", "MM_DOUBLE_ARRAY");

# removed $entries 11/5/09
our ($array, $type, $option, $var_size_bytes, $cVexp_got);
our @checkArray;
our ($ALLOC_SIZE, $ALLOCBASE, $PSIZE, $IVSIZE, $NVSIZE, $DEFENTS);
our $isrand = open (RAND, "</dev/urandom");

sub randStr {
    my $len = shift;
    my $ret = '';
    my ($r, $le);
    if ($len) {
        if ($isrand) {sysread (RAND, $ret, $len)}
        else {
            while (($le = $len - length($ret)) > 0) {
                $r = pack 'L', int(rand(0xFFFFFFFF));
                $ret .= $le >= 4 ? $r : substr($r, 0, $le);
    }   }   }
    return $ret;
}

sub randVar {
    my ($x, $len);
    if ($type == MM_INT_ARRAY) {
        return unpack('i', randStr($IVSIZE));
    } elsif ($type == MM_UINT_ARRAY) {
        return unpack('I', randStr($IVSIZE));
    } elsif ($type == MM_DOUBLE_ARRAY) {
        # eliminate NaN's that random number generation will yield
        do {$x = unpack('d', randStr($NVSIZE))} until ($x == $x);
        return $x;
    } elsif ($option==MM_CSTRING) {
        # C string mode
        $len = int(rand $var_size_bytes+1);
        $x = '';
        while ($len--) {$x .= chr(int(rand 255)+1)} # no NULs
        return $x;
    } else {
        return randStr($var_size_bytes);
}   }

sub typeName {
    return ($type > 0) ? (($option==MM_CSTRING) ? "C string <= $type" : "fixed len $type")
                       : $typeNames[-$type];
}

sub makeZero {
    if ($type < MM_ARRAY) {return 0}
    if ($option == MM_CSTRING) {return ''}
    return (chr(0))x$var_size_bytes;
}

# check a returned value
# this needs to use the right kind of equality operator
#   (numeric == or string eq) because perl 5.6 has problems
#   with converting large UVs to strings
sub checkVal {
    my ($val, $ckval) = @_;
    my $ret = $type < 0 ? $val == $ckval
                        : $val eq $ckval;
    my $form = ($type == MM_DOUBLE_ARRAY) ? 'g'
                                          : ($type < 0) ? 'd'
                                                        : 's';
    $cVexp_got = $ret ? "" : sprintf(": expected %$form (len %d), got %$form (len %d)",
                                     $ckval, length($ckval), $val, length($val));
    return $ret;
}

# check the whole array
sub checkArray {
    my $testName = shift;
    my $size = mm_array_fetchsize($array);
    my $size2 = scalar @checkArray;
    is ($size, $size2,
        "$testName: size of test array and check array should match");
    if ($size2 < $size) {$size = $size2}
    for (my $i=0; $i < $size; $i++) {
        ok (checkVal(mm_array_fetch ($array, $i), $checkArray[$i]),
            "$testName: element $i$cVexp_got (type=" . typeName . ")");
}   }

# compare 2 arrays
sub compArray {
    my ($array1ref, $array2ref, $testName) = @_;
    my $size1 = scalar @$array1ref;
    my $size2 = scalar @$array2ref;
    is ($size1, $size2, "$testName: arrays should be same size");
    if ($size2 < $size1) {$size1 = $size2}
    for (my $i=0; $i <$size1; $i++) {
        ok (checkVal($$array1ref[$i], $$array2ref[$i]),
            "$testName: element $i$cVexp_got (type=" . typeName . ")")
}   }

# diag sprintf("process ID = %d", $$);

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
($ALLOC_SIZE, $ALLOCBASE, $PSIZE, $IVSIZE, $NVSIZE, $DEFENTS) = mm_alloc_size();

ok ($ALLOC_SIZE && $ALLOC_SIZE <= 256
    && $ALLOCBASE && $ALLOCBASE <= 256
    && $PSIZE  && $PSIZE  <= 16
    && $IVSIZE && $IVSIZE <= 16
    && $NVSIZE && $NVSIZE <= 16
    && $DEFENTS && $DEFENTS <= 256, "read allocation sizes");

#### cycle thru the array types
foreach $type (MM_INT_ARRAY, MM_UINT_ARRAY, MM_DOUBLE_ARRAY, 1, 12, 37) {

    #### all test numbers below refer to the first pass through

    # test 5: make an array of the current type
    $option = $type > 0 && !($type & 1) ? MM_CSTRING : MM_FIXED_REC;

    $array = mm_make_array ($mm, $type, 64, $option);
    ok (defined $array && $array,
        "make array of $DEFENTS ".typeName);

    @checkArray = ();

    # test 6: memory reqd
    my $avail2 = mm_available ($mm);
    $var_size_bytes = $type < 0 ? ($IVSIZE, $IVSIZE, $NVSIZE)[$type - MM_INT_ARRAY]
                                : $type;
    # this may increase if we split out an options word
    my $MM_ARRAY_ROOT_SIZE = mm_round_up(2*$PSIZE + 3*$IVSIZE);

    my $expect = 2 * $ALLOCBASE + $MM_ARRAY_ROOT_SIZE + mm_round_up($DEFENTS * $var_size_bytes);
    is ($avail2 - $memsize, -$expect,
        "impact of array of $DEFENTS ".typeName." on avail memory");

    # tests 7-70: populate the array
    my ($i, $rc, $val, $val2);
    my $rand=0;
    for ($i=0; $i < $DEFENTS; $i++) {
        $rand = randVar();
        push @checkArray, $rand;
        ok (($rc = mm_array_store ($array, $i, $rand)) == 1,
            "store " . ($type < 0 ? "$rand " : '')
          . "in element $i in array returned $rc");
        if ($_ = mm_error()) {
            diag "$_ at mm_array_store (type=" . typeName . ", index $i)";
    }   }

    # test 71
    my $avail3 = mm_available ($mm);
    is ($avail3 - $avail2, 0,
        "storing ".$DEFENTS." array elements should not use any memory");

    # tests 72-136: read back and check the array elements
    checkArray "initial array";

    # test 137: fetch returns undef outside the array
    ok (!defined mm_array_fetch_nowrap ($array, -1),
        "fetch_nowrap -1 should return undef");

    # test 138
    ok (!defined mm_array_fetch ($array, $DEFENTS),
        "fetch ".$DEFENTS." should return undef");

    # test 139: fetch -1 returns last entry
    ok (checkVal(mm_array_fetch ($array, -1), $checkArray[-1]),
        "fetch -1 should return last element$cVexp_got");

    # test 140: fetch_nowrap -1 should return undef
    ok (!defined mm_array_fetch_nowrap ($array, -1),
        "fetch_nowrap -1 should return undef");

    # test 141: test array status: entries
    my ($entries, $shiftCount, $typeRet, $options) = mm_array_status ($array);
    is ($entries, $DEFENTS,
        "array size returned by mm_array_status");

    # test 142
    is ($shiftCount, 0,
        "shift count returned by mm_array_status");

    # test 143
    is ($typeRet, $type,
        "array type returned by mm_array_status");

    # test 144: array_status: options
    is ($options, $option,
        "options returned by mm_array_status");

    # test 145
    is (mm_array_fetchsize ($array), $DEFENTS,
        "array size returned by mm_array_fetchsize");

    # test 146
    ok (mm_array_exists ($array, $DEFENTS - 1),
        "mm_array_exists: should");

    # test 147
    ok (mm_array_exists ($array, 0),
        "mm_array_exists: should");

    # test 148
    ok (mm_array_exists ($array, -1),
        "mm_array_exists -1: should");

    # test 149
    ok (!mm_array_exists_nowrap ($array, -1),
        "mm_array_exists_nowrap -1: shouldn't");

    # test 150
    ok (!mm_array_exists ($array, $DEFENTS),
        "mm_array_exists: shouldn't");

    # test 151: delete the end element using -1, see that it returns the last value
    ok (checkVal(mm_array_delete ($array, -1), pop @checkArray),
        "delete -1 should return deleted (last) value$cVexp_got");

    # test 152: delete at end reduces array size
    is (mm_array_fetchsize ($array), $DEFENTS - 1,
        "array size down by 1 after delete");

    # test 153
    my $avail4 = mm_available ($mm);
    is ($avail4 - $avail3, 0,
        "delete at end ".typeName." should have no effect on avail mem");

    # test 154: delete_nowrap -1 fails
    ok (!defined mm_array_delete_nowrap ($array, -1),
        "delete_nowrap -1 should fail");

    # test 155: can't delete the same one twice
    ok (!defined mm_array_delete ($array, $DEFENTS - 1),
        "can't delete ".($entries - 1)." twice");

    # test 156: array size again
    is (mm_array_fetchsize ($array), $DEFENTS - 1,
        "array size not changed by failing delete");

    # test 157: delete middle delete
    my $delix = ($DEFENTS >> 1) - 3;
    ok (checkVal(mm_array_delete ($array, $delix), $checkArray[$delix]),
        "delete element $delix should return element value$cVexp_got");

    # test 158
    my $avail5 = mm_available ($mm);
    is ($avail5 - $avail4, 0,
        "deleting element $delix should have no effect on on avail mem");

    # test 159
    is (mm_array_fetchsize ($array), $DEFENTS - 1,
        "array size not changed by delete in middle");

    # middle-deleted fixed-length element can't return undef, only false
    $checkArray[$delix] = makeZero;

    # test 160-223
    checkArray "after middle delete";

    # test 224: try pop
    $val = mm_array_pop ($array);
    ok (checkVal($val, pop @checkArray),
        "pop from both arrays$cVexp_got");

    # test 225
    my $size;
    ($size, $shiftCount) = mm_array_status ($array);
    is ($size, $DEFENTS - 2,
        "pop decreases array size by 1");

    # test 226
     is ($shiftCount, 0,
        "pop should not affect shift count");

    # test 227
    is (mm_array_fetch ($array, $DEFENTS-2), undef,
        "get popped index should return undef");

    # test 228-290
    checkArray "after pop";

    # test 291
    my $avail6 = mm_available ($mm);
    is ($avail6 - $avail5, 0,
        "pop should have no effect on avail mem");

    # test 292: push it back
    is (mm_array_push ($array, $val), $DEFENTS - 1,
        "push should return new array size");
    push @checkArray, $val;

    # test 293
    ($size, $shiftCount) = mm_array_status ($array);
    is ($size, $DEFENTS - 1,
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
    ok (checkVal(mm_array_shift ($array), shift @checkArray),
        "value returned by shift$cVexp_got");

    # test 361
    ($size, $shiftCount) = mm_array_status ($array);
    is ($size, $DEFENTS - 2,
        "shift should decrease array size by 1");

    # test 362
    is ($shiftCount, 1,
        "shift should increase shift count by 1");

    # test 363
    my $avail8 = mm_available ($mm);
    is ($avail8, $avail7,
        "shift should have no effect on avail mem");

    # test 364-426
    checkArray "after shift";

    # test 427: unshift 7 elements into array
    my @ioArray = ();
    my $ioN = 7;
    $i=0;
    while (++$i <= $ioN) {push @ioArray, randVar}
    is (mm_array_unshift ($array, @ioArray), $size + $ioN,
        "unshifting $ioN elements should return OK");

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

    # tests 500: splice out 9
    $ioN = 9;
    @ioArray = mm_array_splice ($array, 29, $ioN);
    is (scalar @ioArray, $ioN,
        "splice out $ioN should return $ioN elements");

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
    my @two = (randVar, randVar);
    (@ioArray) = mm_array_splice ($array, 3, $ioN, @two);
    (@ioArray2) = splice (@checkArray, 3, $ioN, @two);
    is (scalar @ioArray, $ioN,
        "splice out $ioN within word should return $ioN elements");

    # tests 648-669
    compArray (\@ioArray, \@ioArray2, "check splice out (within word) return arrays");

    # tests 670-720
    checkArray "after splice out $ioN within word";

    # tests 721: splice in within word
    ok (!defined mm_array_splice ($array, 5, 0, @ioArray),
        "splice in $ioN within word (no delete) should return undef");

    # tests 722-793
    splice (@checkArray, 5, 0, @ioArray);
    checkArray "after splice in $ioN within word";

    # test 794: clear the array and test effect on mem avail
    mm_array_clear ($array);
    my $avail9 = mm_available ($mm);

    # after the clear, avail mem should be back to what is was after the make
    $expect = $avail2 - $avail8;
    # some fudging here
    is ($avail9 - $avail8, $expect,
        "effect of mm_array_clear (". typeName . ") on avail mem");

    # test 791: free the MM_ARRAY and see that all is back to where we started
    mm_free_array ($array);
    my $avail99 = mm_available ($mm);
    is ($avail99 - $avail9, $memsize - $avail9,
        "effect of free_array on avail mem");

} # cycle thru the array types

# not a test: destroy the shared memory
mm_destroy ($mm);
