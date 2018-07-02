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

my ($ok, $err) = $np->login();
is $ok,  'ERROR', "premature login correctly failed";
is $err, 'not connected', "premature login error message";

($ok, $err) = $np->connect();
is $ok, "OK", "connected";

($ok, $err) = $np->login();  # TODO - improve on this
is $ok, "OK", "login works";

($ok, $err) = $np->power_status();  # TODO - improve on this
is $ok, "OK", "power_status works";

($ok, $err) = $np->power_set(1, 1);  # TODO - improve on this
is $ok, "OK", "power_set works";

($ok, $err) = $np->status();  # TODO - improve on this
is $ok, "OK", "status works";

($ok, $err) = $np->status();  # TODO - improve on this
is $ok, "OK", "status works";

($ok, $err) = $np->logout();  # TODO - improve on this
is $ok, "OK", "logout works";

done_testing();
exit(0);
