#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use t::common;

my $site = start_depends;

my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
$DRIVER->connect;
{
	# Test getting and setting input values
	my $exists = $DRIVER->run(js => "return (function is_frameworked () {
		try {
			if (typeof(window) !== 'undefined') {
				return 1;
			} else {
				return 0;
			}
		} catch(err) {
				return 0;
		}
	})();");
	ok($exists, "The window var should exist");
}
$DRIVER->disconnect;
stop_depends;
done_testing;
