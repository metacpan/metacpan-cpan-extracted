#!perl
use strict;
use Test::More tests => 5;

use Haiku::SysInfo;

my $si = Haiku::SysInfo->new;
ok($si, "make sysinfo object");
ok($si->cpu_count, "at least one cpu");
ok($si->max_pages, "have some memory");
ok($si->cpu_clock_speed, "the cpu runs");

# this can, in theory, fail, on old, old CPUs
ok($si->cpu_brand_string, "it has a brand string");
