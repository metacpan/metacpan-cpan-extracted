# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
use strict;

#########################

use Test::More tests => 7;

use_ok('Device::SerialPort'); # test

#########################

# We need to test that the "get_tick_count" function actually works
# as expected, since we use it during other tests to verify toggle
# speeds, hang ups, etc.

can_ok('Device::SerialPort',qw(get_tick_count)); # test

my $then;
ok(defined($then = Device::SerialPort->get_tick_count),
	"get_tick_count returns a number"); # test

ok(sleep(2) <= 2, "sleep sleeps"); # test

my $now;
ok(defined($now = Device::SerialPort->get_tick_count),
	"get_tick_count still returns a number"); # test

ok( ($now-$then) >= 1000, "measured sleep as more than 1 second")
	or diag("then: $then now: $now diff: ".($now-$then)); # test

# Allow 100ms fudge-time for slow calls, etc
ok( ($now-$then) <= 2100, "measured sleep as less than 2 seconds")
	or diag("then: $then now: $now diff: ".($now-$then)); # test

