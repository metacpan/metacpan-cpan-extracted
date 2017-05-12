#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use ITM;

my @tests = (
 'Sync Packet 1',            '00000000', { type => ITM_SYNC,            size => 0 },
 'Sync Packet 2',            '10000000', { type => ITM_SYNC,            size => 0 },
 'Overflow Packet',          '01110000', { type => ITM_OVERFLOW,        size => 0 },
 'Instrumentation Packet 1', '00000001', { type => ITM_INSTRUMENTATION, size => 1, source => 0 },
 'Instrumentation Packet 2', '00000011', { type => ITM_INSTRUMENTATION, size => 4, source => 0 },
 'Instrumentation Packet 3', '00001010', { type => ITM_INSTRUMENTATION, size => 2, source => 1 },
 'Instrumentation Packet 4', '01000010', { type => ITM_INSTRUMENTATION, size => 2, source => 8 },
 'Instrumentation Packet 5', '01010010', { type => ITM_INSTRUMENTATION, size => 2, source => 10 },
 'Hardware Source Packet 1', '00010101', { type => ITM_HARDWARE_SOURCE, size => 1, source => 2 },
);

while (@tests) {
  my $testname = shift @tests;
  my $byte = pack('b8',join("",reverse(split("",shift @tests))));
  my $expected = shift @tests;
  my $header = itm_header($byte);
  is_deeply($header,$expected,$testname);
}

done_testing;
