#!/usr/bin/env perl
use strict;
use warnings;
use bytes;
use Test::More;

use ITM;

my $itm = itm_parse(chr(0));
isa_ok($itm,'ITM::Sync');
ok(!$itm->has_payload,'Sync has no payload');

$itm = itm_parse(chr(112));
isa_ok($itm,'ITM::Overflow');
ok(!$itm->has_payload,'Overflow has no payload');

$itm = itm_parse(chr(1).chr(42));
isa_ok($itm,'ITM::Instrumentation');
is(ord($itm->payload),42,'Sample Instrumentation payload is correct');

done_testing;
