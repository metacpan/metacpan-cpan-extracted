#!/usr/local/bin/perl

# test hash features of IPC::MMA

use strict;
use warnings;
use Test::More tests => 726;
use Test::Warn;

our ($hash, $entries);
our %checkHash;
our $isrand = open (RAND, "</dev/urandom");

sub randStr {
    my $len = int(rand shift())+1;
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

sub shoHex {
    my ($s) = @_;
    my $ret = '';
    while (my $c = substr ($s, 0, 1, '')) {
        $ret .= sprintf ("%02X", ord($c));
    }
    return $ret;
}

# test 1 is use_ok
BEGIN {use_ok ('IPC::MMA', qw(:basic :hash))}

# test 2: create acts OK
my $mm = mm_create ((1<<20) - 200, '/tmp/test_lockfile');
ok (defined $mm && $mm, "create shared mem");

# test 3: see if available answers civilly
my $memsize = mm_available ($mm);
ok (defined $memsize && $memsize, "read available mem = $memsize");

# test 4: get the allocation size
my ($ALLOC_SIZE, $ALLOCBASE, $PSIZE, $IVSIZE, $NVSIZE, $DEFENTS) = mm_alloc_size();

ok ($ALLOC_SIZE && $ALLOC_SIZE <= 256
    && $ALLOCBASE && $ALLOCBASE <= 256
    && $PSIZE && $PSIZE <= 16
    && $IVSIZE && $IVSIZE <= 16
    && $NVSIZE && $NVSIZE <= 16
    && $DEFENTS && $DEFENTS <= 256, "read allocation sizes");

my $MM_HASH_ROOT_SIZE = mm_round_up (2*$PSIZE + $IVSIZE);

# test 5: make a hash
$hash = mm_make_hash ($mm);
ok (defined $hash && $hash, "make hash");

%checkHash = ();

# test 6: memory reqd
my $avail2 = mm_available ($mm);
my $expect = 2*$ALLOCBASE + $MM_HASH_ROOT_SIZE + mm_round_up($PSIZE * $DEFENTS);
is ($avail2 - $memsize, -$expect,
    "effect of making default-alloc hash on avail mem");

# tests 7-134: populate the hash
my ($i, $rc, $key, $value, $exists, $dups);
my ($keyBlockSize, $oldValBlockSize, $newValBlockSize, $decreased);
my $incFrom = my $incTo = '';
$expect = $entries = $dups = $decreased = 0;

do {
    $key = randStr(16);
    $value = randStr(256);

    is ($exists = mm_hash_exists ($hash, $key), exists $checkHash{$key},
        "key ". shoHex($key) . " (" . ($entries + $dups)
        . ") existance in MMA hash vs. existance in check hash");

    $oldValBlockSize = $exists ? mm_round_up (length (mm_hash_fetch($hash, $key))) : 0;
    $keyBlockSize = mm_round_up ($PSIZE + length($key));
    $newValBlockSize = mm_round_up (length($value));

    ok (($rc = mm_hash_store ($hash, $key, $value)) == 1,
        "storing to key " . shoHex($key) . " in hash returned $rc ("
        . ($entries + $dups) . ")");

    $checkHash{$key} = $value;

    if ($_ = mm_error()) {
        diag "$_ at mm_hash_store (".($entries + $dups)."), key=".shoHex($key).")";
    }
    # add in the memory contribution of this entry
    if ($exists) {
        $expect += $newValBlockSize - $oldValBlockSize;
        # keep track of how much we have decreased value-block sizes
        if ($newValBlockSize < $oldValBlockSize) {
            $decreased += $oldValBlockSize - $newValBlockSize;
        } else {
            $incTo   = $newValBlockSize;
            $incFrom = $oldValBlockSize;
        }
        $dups++;
        # quietly sneak another entry in to keep the number of tests constant
        do {$key = randStr(16)} until (!mm_hash_exists($hash, $key));
        $keyBlockSize = mm_round_up ($PSIZE + length($key));
        mm_hash_store ($hash, $key, $value);
        $checkHash{$key} = $value;
    }
    $expect += $keyBlockSize + $newValBlockSize + 2*$ALLOCBASE;
    $entries++;
} until ($entries == $DEFENTS);

#if ($dups) {diag "$dups duplicate keys ($lt <) occurred in "
#                    . $DEFENTS ." random 1-16 byte keys"}

# test 135
my $avail3 = mm_available ($mm);
my $got = $avail3 - $avail2;
ok ($got <= -$expect
 && $got >= -$expect - 128,  # subject to random shortages (replaced $decreased)
    "effect of stores on avail mem: got $got, expected -$expect, "
  . "decreased $decreased, incFrom $incFrom, incTo $incTo");

# test 136
my $mmEntries = mm_hash_scalar ($hash);
is ($mmEntries, $entries,
    "entries reported by mm_hash_scalar vs. count in this test");

# test 137
is ($mmEntries, scalar(keys(%checkHash)),
    "same number of entries in MMA hash and check hash");

# test 138
my $prevKey = '';
$key = mm_hash_first_key ($hash);
ok (defined($key) && $key, "get first key");

# tests 139-394: read back and check the two hashes against each other,
#   keys from the MMA hash

my ($value2, $length1, $length2);
my @keys = ();
$i = 0;
do {
    $i++;
    # check that MMA hash delivers keys in sorted order
    ok ($prevKey lt $key,
        "'".shoHex($prevKey) . "' should be less than key " . shoHex($key));

    $value = mm_hash_fetch($hash, $key);
    $value2 = $checkHash{$key};
    $length1 = defined($value)  ? length($value)  : 0;
    $length2 = defined($value2) ? length($value2) : 0;

    ok ($length1, "MMA hash key ".shoHex($key)." exists in / returns value from MMA hash");
    ok ($length2, "MMA hash key ".shoHex($key)." exists in / returns value from check hash");
    if ($length1 && $length2) {
        ok ($value eq $value2,
            "same value for MMA hash key " . shoHex($key) . " in MMA hash and check hash");
    }
    $prevKey = $key;
    # keep a sorted key array for use in delete
    push @keys, $key;

        # it's important to include "defined" in a check for end-of-hash,
        #  because once in a while the random key maker will make a key composed
        #  only of ASCII zeroes (0x30), which evaluates as false

} while (defined ($key = mm_hash_next_key ($hash, $key)));

# test 395
is ($i, $mmEntries, "count of keys returned from MMA hash vs. entries reported");

# tests 396-587: compare the hashes using keys from check hash
$i = 0;

while (($key, $value) = each (%checkHash)) {
    $i++;
    $value2 = mm_hash_fetch($hash, $key);
    $length1 = defined($value)  ? length($value)  : 0;
    $length2 = defined($value2) ? length($value2) : 0;

    ok ($length1, "check hash key ".shoHex($key)." exists in / returns value from MMA hash");
    ok ($length2, "check hash key ".shoHex($key)." exists in / returns value from check hash");
    if ($length1 && $length2) {
        ok ($value eq $value2,
            "same value for check hash key " . shoHex($key) . " in MMA hash and check hash");
}   }

# test 588
is ($i, $mmEntries, "count of keys returned by check hash");

# tests 589-716: mm_hash_get_entry
for ($i=0; $i < $mmEntries; $i++) {
    ($key, $value) = mm_hash_get_entry ($hash, $i);
    is ($key, $keys[$i],
        "match key from mm_hash_get_entry, element $i");
    is ($value, $checkHash{$keys[$i]},
        "match value from mm_hash_get_entry, element $i");
}

# last thing to check is delete
# test 717
my $delKey = $keys[$#keys - 1];
my $delVal;
ok (($delVal = mm_hash_delete ($hash, $delKey)) eq delete($checkHash{$delKey}),
    "delete 2nd-last returns same value as delete same key from check Hash");

# test 718
is (mm_hash_scalar($hash), --$entries,
    "hash should contain 1 less entry");

# test 719
ok (mm_hash_next_key ($hash, $keys[$#keys - 2]) eq $keys[$#keys],
    "check last two keys after delete 2nd-last");

# test 720
my $avail4 = mm_available ($mm);
my $delta4 = 2*$ALLOCBASE+mm_round_up($PSIZE+length($delKey))
             + mm_round_up(length $delVal);
is ($avail4 - $avail3, $delta4,
    "effect of delete 2nd-last on available memory");

# test 721: store with MM_NO_OVERWRITE
warning_like {$rc = mm_hash_store ($hash, $keys[22], 1943, MM_NO_OVERWRITE)}
    qr /already exists/, "store with MM_NO_OVERWRITE and existant key should give warning";

# test 722
ok (!$rc, "store with MM_NO_OVERWRITE and existant key should fail");

# test 723: store with MM_NO_CREATE
my $notKey;
do {$notKey = randStr(16)} until (!mm_hash_exists ($hash, $notKey));
warning_like {$rc = mm_hash_store ($hash, $notKey, 1943, MM_NO_CREATE)}
    qr /does not exist/, "store with MM_NO_CREATE and new key should give warning";

# test 724
ok (!$rc, "store with MM_NO_CREATE and new key should fail");

# test 725: clear the array and test effect on mem avail
mm_hash_clear ($hash);
my $avail9 = mm_available ($mm);

is ($avail9, $avail2,
    "after mm_hash_clear, avail mem should be what it was after mm_make_hash");

# test 726: free the MM_ARRAY and see that all is back to where we started
mm_free_hash ($hash);
my $avail99 = mm_available ($mm);
is ($avail99, $memsize,
    "after mm_free_hash, avail mem should be what it was before mm_make_hash");

# not a test: destroy the shared memory
mm_destroy ($mm);
