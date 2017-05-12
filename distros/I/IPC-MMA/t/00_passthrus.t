#!/usr/local/bin/perl

# program to test basics of IPC::MM::Array

use strict;
use warnings;
use Test::More tests => 8;

# test 1 is use_ok
BEGIN {use_ok ('IPC::MMA', qw(:basic))}

# test 2, get the maxsize
my $maxsize = mm_maxsize();
ok (defined $maxsize && $maxsize, "get max shared mem size");

# test 3, try a create
my $mm = mm_create (1, '/tmp/test_lockfile');
ok (defined $mm && $mm, "created shared mem");

# test 4: see if available answers civilly
my $memsize = mm_available ($mm);
ok (defined $memsize && $memsize, "read available mem");

# test 5: avail is reasonable
ok ($memsize <= $maxsize && $memsize > 3800, "avail mem reasonable");

# test 6: get the allocation size
my ($ALLOC_SIZE, $ALLOCBASE, $PSIZE, $IVSIZE, $NVSIZE, $DEFENTS) = mm_alloc_size();

ok ($ALLOC_SIZE && $ALLOC_SIZE <= 256
    && $ALLOCBASE && $ALLOCBASE <= 256
    && $PSIZE && $PSIZE <= 16
    && $IVSIZE && $IVSIZE <= 16
    && $NVSIZE && $NVSIZE <= 16
    && $DEFENTS && $DEFENTS <= 256, "read allocation sizes");

# get the version of the mm library
my $vers = `mm-config --version`;

# show the max and min shared memory size and allocation size
diag sprintf ("max shared mem size on this platform is %d (0x%X),\n"
. "                         min shared mem size is %d (0x%X), allocation unit is $ALLOC_SIZE bytes,\n"
. "                         allocation base is $ALLOCBASE bytes, pointer size is $PSIZE bytes,\n"
. "                         IV size is $IVSIZE bytes, NV size is $NVSIZE bytes, $vers",
                $maxsize, $maxsize, $memsize, $memsize);

# test 7: lock returns 1
my $locked = mm_lock($mm, MM_LOCK_RW);
ok ($locked == 1, "lock(RW) returned 1");

# test 8: unlock returns 1
my $unlocked = mm_unlock($mm);
ok ($unlocked == 1, "unlock returned 1");

# not a test: destroy the shared memory
mm_destroy $mm;
