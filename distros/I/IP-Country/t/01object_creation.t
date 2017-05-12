# *-*-perl-*-*
use Test;
BEGIN { plan tests => 5 }
use strict;
$^W = 1;
use IP::Country;
use IP::Country::Fast;
use IP::Country::Medium;
use IP::Country::Slow;
use IP::Authority;

ok(IP::Country->new());
ok(IP::Country::Fast->new());
ok(IP::Country::Medium->new());
ok(IP::Country::Slow->new());
ok(IP::Authority->new());
