#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Deep qw/!set !any/;

use t::common;

my $site = start_depends;

my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
$DRIVER->connect;

{
	# Test getting and selecting dropdown options
	$DRIVER->window_size(x => 1920, y => 1080) if is_phantom; # Set the screen size to 1920x1080
	$DRIVER->maximize; # Make sure its been maxed, redundent given how phantom works

	ok($DRIVER->visible("select"), "Select dom element should be visible");
	cmp_bag([$DRIVER->dropdown(selector => "select")],
		['val 1','val 2','val 3'],
		"Ensuring the labels/text is correct for dropdown with default method");
	cmp_bag([$DRIVER->dropdown(selector => "select", method => "value")],
		['val 1','val 2','val 3'],
		"Ensuring the values are correct for the dropdown with value method");
	cmp_bag([$DRIVER->dropdown(selector => "select", method => "label")],
		['Label 1','Label 2','Label 3'],
		"Ensuring the labels/text is correct for dropdown with label method");

	is(
		$DRIVER->attribute(selector => "select", attr => 'value'),
		'val 1', "Defaults to first value");
	$DRIVER->dropdown(selector => "select", method => "label", value => "Label 3");
	is(
		$DRIVER->attribute(selector => "select", attr => 'value'),
		"val 3", "Ensuring select by label gets third value");
	$DRIVER->dropdown(selector => "select", value => "val 2");
	is(
		$DRIVER->attribute(selector => "select", attr => 'value'),
		'val 2', "Ensure picking by value, by default");
	$DRIVER->dropdown(selector => "select", value => "Label 1", method => "label");
	is(
		$DRIVER->attribute(selector => "select", attr => 'value'),
		"val 1", "Ensuring select by label gets third value");
}
$DRIVER->disconnect;
stop_depends;
done_testing;
