#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;

my $site = start_depends;
my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
$DRIVER->connect;

{
	# Test checking and unchecking checkboxes
	$DRIVER->window_size(x => 1920, y => 1080) if is_phantom;   # Set the screen size to 1920x1080
	$DRIVER->maximize; # Make sure its been maxed, redundent given how phantom works

	ok($DRIVER->check(selector => "input[type='checkbox']"), "checks boxing");
	ok($DRIVER->uncheck(selector => "input[type='checkbox']"),"unchecks boxing");
}
$DRIVER->disconnect;
stop_depends;
done_testing;
