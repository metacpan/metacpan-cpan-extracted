#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;

my $site = start_depends;
my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
$DRIVER->connect;

subtest "Basic text checking on /" => sub {
	# Test getting and setting input values
	$DRIVER->window_size(x => 1920, y => 1080) if is_phantom;   # Set the screen size to 1920x1080
	$DRIVER->maximize; # Make sure its been maxed, redundent given how phantom works
	is($DRIVER->text("p#test_text"), "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
		." incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation"
		." ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit"
		." in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat"
		." non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.");
};

subtest "text() sanity checking", sub {
	$DRIVER->open(url => '/');
	is $DRIVER->text("div#get_text p.empty"), '',
		"Empty element returns empty string for text()";
	is $DRIVER->text("div#get_text p.whitespace"), ' ',
		"Whitespace only element returns correct string for text()";
	is $DRIVER->text("div#get_text p.full"), "There's data in them thar P tags",
		"text() returns correct string when data is present";
};

subtest "More advanced counter testing on /p_tag" => sub {
	# Test getting and setting input values
	$DRIVER->open(url => '/p_tag');
	is($DRIVER->text('p'), "this is text and some more and now the end", "Getting text by p tag");
	is($DRIVER->text('.p_test'), "this is text and some more and now the end", "Getting text by class only");
	$DRIVER->click(selector => "#_adder");
	is($DRIVER->text('.p_test'), "this is text 1 and now the end", "Getting text by class after updating it");
	$DRIVER->click(selector => "#_creator");
	is($DRIVER->text('._p_'),
		"New text begins Spanner Text Speak for those that cannot",
		"Ensure new p tag has the entire text");
};

subtest "Html text on /p_tag" => sub {
	# Test getting and setting input values
	$DRIVER->open(url => '/p_tag');
	$DRIVER->click(selector => "#_creator");
	is($DRIVER->attribute(selector => '._p_', attr => "html"),
		'New text begins <span id="_span_man">Spanner Text </span>Speak for those that cannot',
		"Ensure new p tag has the entire text");
};

subtest "html() sanity checking", sub {
	$DRIVER->open(url => '/');
	is $DRIVER->attribute(selector => "div#get_html div.empty", attr => 'html'), '',
		"Empty element returns empty string for html()";
	is $DRIVER->attribute(selector => "div#get_html div.full", attr => 'html'), "<div>&nbsp;</div>",
		"html() returns correct string when data is present";
};
$DRIVER->disconnect;
stop_depends;
done_testing;
