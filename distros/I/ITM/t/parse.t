#!/usr/bin/env perl
use strict;
use warnings;
use bytes;
use Test::More;

use ITM;

my @tests = (
 'Sync Packet 1',            '00000000', { class => 'ITM::Sync' },
 'Sync Packet 2',            '10000000', { class => 'ITM::Sync' },
 'Overflow Packet',          '01110000', { class => 'ITM::Overflow' },
 'Instrumentation Packet 1', '00000001', { class => 'ITM::Instrumentation', source => 0,  payload => chr(36) },
 'Instrumentation Packet 2', '00000011', { class => 'ITM::Instrumentation', source => 0,  payload => chr(41).chr(39).chr(38).chr(37) },
 'Instrumentation Packet 3', '00001010', { class => 'ITM::Instrumentation', source => 1,  payload => chr(42).chr(43) },
 'Instrumentation Packet 4', '01000010', { class => 'ITM::Instrumentation', source => 8,  payload => chr(44).chr(45) },
 'Instrumentation Packet 5', '01010010', { class => 'ITM::Instrumentation', source => 10, payload => chr(46).chr(47) },
 'Hardware Source Packet 1', '00010101', { class => 'ITM::HardwareSource',  source => 2,  payload => chr(48) },
);

while (@tests) {
  my $testname = shift @tests;
  my $header = pack('b8',join("",reverse(split("",shift @tests))));
  my $expected = shift @tests;
  my $class = delete $expected->{class};
  my $payload = delete $expected->{payload};
  my $packet = $header.( defined $payload ? $payload : '' );
  my $itm = itm_parse($packet);
  isa_ok($itm,$class,$testname);
  if (defined $payload) {
    is($itm->payload,$payload,$testname.' correct payload');
  } else {
    ok(!$itm->has_payload,$testname.' has no payload');    
  }
}

done_testing;
