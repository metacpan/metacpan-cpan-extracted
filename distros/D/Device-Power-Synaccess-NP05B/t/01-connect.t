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

my ($ok, $err) = $np->connect();
ok $ok eq 'OK', "faux connection";
print "connect: $ok: $err\n" if ($ok ne 'OK');

done_testing();
exit(0);
