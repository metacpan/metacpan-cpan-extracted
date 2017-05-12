#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Digest::DJB32 qw( djb );

is(djb("model"),267518966);
is(djb("model_id"),1692379714);
is(djb("pwm_count"),1720465889);
is(djb("factory_version"),3311349730);
is(djb("language"),1516978633);
is(djb("timezone"),567635856);
is(djb("updated"),1051190796);
is(djb("name"),2090536006);
is(djb("showhelp"),4001324719);
is(djb("showexpert"),2251042814);
is(djb("hostname"),3953423524);
is(djb("usentp"),556064228);
is(djb("ntpserver"),3465123150);
is(djb("useip4"),556058591);
is(djb("ip4"),193495090);
is(djb("ip4_subnet"),2003743074);
is(djb("ip4_gateway"),2619599939);
is(djb("ip4_dns"),2676431158);
is(djb("ip4_filter"),1481117815);
is(djb("ip4_whitelist"),3311454894);
is(djb("webport"),3201799624);

done_testing;

