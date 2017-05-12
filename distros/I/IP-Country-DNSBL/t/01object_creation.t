# *-*-perl-*-*
use Test;
BEGIN { plan tests => 1 }
use strict;
$^W = 1;
use IP::Country::DNSBL;

ok(IP::Country::DNSBL->new());
