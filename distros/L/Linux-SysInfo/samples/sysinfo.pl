#!/bin/env perl

use strict;
use warnings;

use lib qw<blib/lib blib/arch>;

use Linux::SysInfo qw<sysinfo LS_HAS_EXTENDED>;

my $si = sysinfo;
die 'sysinfo() failed ! (should be pretty rare but it did happen)' unless $si;

print 'Extended fields are ', (LS_HAS_EXTENDED ? '' : 'NOT '), "available on your system.\n\n";

print "Values :\n";
print "- $_: $si->{$_}\n" for sort keys %$si;

if (LS_HAS_EXTENDED) {
 print "\n";
 print 'You have the mem_unit field set to ', $si->{mem_unit}, ', hence ',
 ($si->{mem_unit} == 1) ? "the memory values are the actual sizes in bytes :\n"
                        : "the sizes in bytes are actually :\n";
 print '- ', $_, ': ', $si->{$_} * $si->{mem_unit}, "\n" for sort
 qw<totalram freeram sharedram bufferram totalswap freeswap totalhigh freehigh>;
}
