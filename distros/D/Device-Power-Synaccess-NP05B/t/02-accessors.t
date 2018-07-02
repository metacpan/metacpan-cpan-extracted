#!/bin/env perl

use strict;
use warnings;
use Test::Most;

use lib "./lib";
use Device::Power::Synaccess::NP05B;

use lib "./tlib";
use Mock::Net::Telnet;

my $fake_telnet = Mock::Net::Telnet->new();
my $np = Device::Power::Synaccess::NP05B->new(telnet_or => $fake_telnet);

$np->addr = "10.1.2.3";
is $np->addr, "10.1.2.3", "get/set address";

$np->user = "kerr";
is $np->user, "kerr", "get/set username";

$np->pass = "avon";
is $np->pass, "avon", "get/set password";

$np->cond = "connected";
is $np->cond, "connected", "get/set condition";

done_testing();
exit(0);
