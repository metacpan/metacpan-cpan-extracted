#!/usr/local/bin/perl

# test tied-hash features of IPC::MMA

use strict;
use warnings;
use Test::More tests => 142;

our ($hash, %tiedHash, $entries);
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

# it seems that perl 5.6.2 doesn't call IPC::MMA's scalar function
sub getScalar {
    my ($hashRef, $keyArrayRef) = @_;
    return $^V ge v5.8 ? scalar(%$hashRef) : scalar(@$keyArrayRef);
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

# the check hash
%checkHash = ();

# test 6: memory reqd
my $avail2 = mm_available ($mm);
my $expect = 2*$ALLOCBASE + $MM_HASH_ROOT_SIZE + mm_round_up($PSIZE * $DEFENTS);
is ($avail2 - $memsize, -$expect,
    "effect of making default-alloc hash on avail mem");

# test 7: tie the hash
ok (tie (%tiedHash, 'IPC::MMA::Hash', $hash), "tie hash");

# tests 8-71: populate the tied and check hashes
my ($i, $key, $value, $exists, $dups);
my ($keyBlockSize, $oldValBlockSize, $newValBlockSize, $decreased);
my $incFrom = my $incTo = '';
$expect = $entries = $dups = $decreased = 0;

do {
    $key = randStr(16);
    $value = randStr(256);

    is ($exists = exists $tiedHash{$key}, exists $checkHash{$key},
        "key ". shoHex($key) . " (" . ($entries + $dups)
        . ") existance in tied hash vs. existance in check hash");

    $oldValBlockSize = $exists ? mm_round_up (length $tiedHash{$key}) : 0;
    $keyBlockSize = mm_round_up ($PSIZE + length($key));
    $newValBlockSize = mm_round_up (length($value));

    $tiedHash{$key} = $value;
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
        do {$key = randStr(16)} until (!exists $tiedHash{$key});
        $keyBlockSize = mm_round_up ($PSIZE + length($key));
        $tiedHash {$key} = $value;
        $checkHash{$key} = $value;
    }
    $expect += $keyBlockSize + $newValBlockSize + 2*$ALLOCBASE;
    $entries++;
} until ($entries == $DEFENTS);

#if ($dups) {diag "$dups duplicate keys ($lt <) occurred in "
#                    . $DEFENTS ." random 1-16 byte keys"}

# test 72
my $avail3 = mm_available ($mm);
my $got = $avail3 - $avail2;
ok ($got <= -$expect
 && $got >= -$expect - 128,  # subject to random shortages (replaced $decreased)
    "effect of stores on avail mem: got $got, expected -$expect, "
  . "decreased $decreased, incFrom $incFrom, incTo $incTo");

# test 73
my @keys = keys (%tiedHash);
my $mmEntries = getScalar(\%tiedHash, \@keys);

is ($mmEntries, $entries,
    "entries reported by scalar(tied hash) vs. count in this test");

# test 74
is ($mmEntries, scalar(keys(%checkHash)),
    "same number of entries in tied hash and check hash");

# test 75: compare the two hashes against each other,
is_deeply (\%tiedHash, \%checkHash, "compare hashes after populating");

# second-last thing to check is delete
# test 76
my $delKey = $keys[$#keys - 1];
my $delVal;
ok (($delVal = delete ($tiedHash{$delKey})) eq delete($checkHash{$delKey}),
    "delete 2nd-last returns same value as delete same key from check Hash");

# test 77
@keys = keys(%tiedHash);
is ($mmEntries = getScalar(\%tiedHash, \@keys), --$entries,
    "hash should contain 1 less entry");

# test 78
my $avail4 = mm_available ($mm);
my $delta4 = $ALLOCBASE + mm_round_up ($PSIZE + length($delKey))
           + (length($delVal) ? $ALLOCBASE + mm_round_up(length $delVal)
                              : 0);

is ($avail4 - $avail3, $delta4,
    "effect of delete 2nd-last on available memory");
$expect -= $delta4;

# test 79-140: check that keys(%tiedHash) returns sorted array
my $prevKey = $keys[0];
for ($i = 1; $i < $mmEntries; $i++) {
    $key = $keys[$i];
    ok ($prevKey lt $key, "keys[" . ($i-1) . "]=" . shoHex($prevKey)
           . " < keys[$i]=" . shoHex($key));
    $prevKey = $key;
}

# test 141: clear the hash and test effect on mem avail
%tiedHash = ();
my $avail9 = mm_available ($mm);

is ($avail9, $avail2,
    "after mm_hash_clear, avail mem should be what it was after mm_make_hash");

# test 142: free the MM_ARRAY and see that all is back to where we started
mm_free_hash ($hash);
my $avail99 = mm_available ($mm);
is ($avail99, $memsize,
    "after mm_free_hash, avail mem should be what it was before mm_make_hash");

# not a test: destroy the shared memory
mm_destroy ($mm);
