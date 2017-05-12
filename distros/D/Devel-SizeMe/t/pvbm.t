#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;
use Devel::SizeMe ':all';
use Config;

use constant PVBM => 'galumphing';
my $dummy = index 'galumphing', PVBM;

if($Config{useithreads}) {
    cmp_ok(total_size(PVBM), '>', 0, "PVBMs don't cause SEGVs");
    # Really a core bug:
    local $TODO = 'Under ithreads, pad constants are no longer PVBMs';
    cmp_ok(total_size(PVBM), '>', total_size(PVBM . '') + 256,
	   "PVBMs use 256 bytes for a lookup table");
} else {
    cmp_ok(total_size(PVBM), '>', total_size(PVBM . ''),
	   "PVBMs don't cause SEGVs");
    cmp_ok(total_size(PVBM), '>', total_size(PVBM . '') + 256,
	   "PVBMs use 256 bytes for a lookup table");
}
