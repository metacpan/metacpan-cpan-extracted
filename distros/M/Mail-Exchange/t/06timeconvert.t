#!/usr/bin/perl -w

use Test::More;
use Mail::Exchange::Time qw(mstime_to_unixtime unixtime_to_mstime);
use strict;
# use diagnostics;
use utf8;

plan tests => 8;
my $t;

is(mstime_to_unixtime(123456789010000000), 701205301, "ms to unix");
is(unixtime_to_mstime(1234567890), 128790414900000000, "unix to ms");

$t=Mail::Exchange::Time->new(1350048139);
isa_ok($t, "Mail::Exchange::Time");
is($t->unixtime, 1350048139, "unix to unix");
is($t->mstime, 129945217390000000, "unix to ms");

$t=Mail::Exchange::Time->from_mstime(129943353270000000);
isa_ok($t, "Mail::Exchange::Time");
is($t->unixtime, 1349861727, "ms to unix");
is($t->mstime, 129943353270000000, "ms to ms");
