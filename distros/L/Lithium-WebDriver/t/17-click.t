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
	ok(!$DRIVER->visible("div#_div_test_a"), "#_div_test_a should not be visible");
	$DRIVER->click(selector => "a#_test_a");
	ok(
		$DRIVER->wait_for_it(sub {$DRIVER->visible("#_div_test_a")}, 3),
		"Div should be visible after 2 seconds, and timeout is 3");
	is $DRIVER->text("div#_div_test_a"), "You clicked on the link! Good on you", "wait for link text to appear";
}

$DRIVER->disconnect;
stop_depends;
done_testing;
