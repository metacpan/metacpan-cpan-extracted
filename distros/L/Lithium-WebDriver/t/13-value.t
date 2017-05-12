#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use t::common;

my $site = start_depends;
my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
$DRIVER->connect;

$DRIVER->window_size(x => 1920, y => 1080) if is_phantom;   # Set the screen size to 1920x1080
$DRIVER->maximize(); # Make sure its been maxed, redundent given how phantom works

subtest "Getting and Setting input values", sub {
	# Test getting and setting input values
	is($DRIVER->value("input._value"), "val 1", "Check for prefilled input value");
	is($DRIVER->attribute(selector => "input._placeholder", attr => 'placeholder'), "test?", "Esure getting other attributes work");

	$DRIVER->type(selector => "input._placeholder", value => "TEST TEXT");
	is($DRIVER->value("input._placeholder"), "TEST TEXT", "Ensure typed text matches");
};

subtest "value() sanity checking", sub {
	is $DRIVER->value("div#get_val input.empty"), '',
		"Empty element returns empty string for value()";
	is $DRIVER->value("div#get_val input.whitespace"), ' ',
		"Whitespace only element returns correct string for value()";
	is $DRIVER->value("div#get_val input.full"), "myVal",
		"value() returns correct string when data is present";
};
$DRIVER->disconnect;
stop_depends;
done_testing;
