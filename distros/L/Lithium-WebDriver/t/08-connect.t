use strict;
use warnings;

use Test::More;
use t::common;

my $site   = start_depends;
my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
ok($DRIVER->connect, "Driver->connect returns 1 if connected.");
is($DRIVER->title, "webdriver test",
	"Ensure title is correct to ensure we are on the right page.");
ok($DRIVER->disconnect, "Driver->disconnect returns 1 on good delete.");

stop_depends;
done_testing;
