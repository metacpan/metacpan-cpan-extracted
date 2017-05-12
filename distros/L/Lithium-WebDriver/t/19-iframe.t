#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use t::common;

plan skip_all => "Selenium has not implemented /frame support"
	unless is_phantom;

my $site = start_depends;
my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
$DRIVER->connect;

{ # Simple context switch
	$DRIVER->open(url => "/iframe");
	ok(!$DRIVER->present("#i0-0"), "This should fail without context switching");
	$DRIVER->frame(selector => '#main-0');
	is($DRIVER->text('#i0-0'), "Hello there", "Found text of frame");
	$DRIVER->frame(selector => "default");
}

{ # do some more, with nesting
	$DRIVER->open(url => "/iframe");
	ok(!$DRIVER->present("#i0-0"), "This should fail without context switching");
	$DRIVER->frame(selector => '#main-0');
	is($DRIVER->text('#i0-0'), "Hello there", "Get the text of the first nested frame");
	$DRIVER->frame(selector => '#i0-1');
	is($DRIVER->text('#i2-0'), "Goodday Sir", "Get the text of the second nested frame");
	$DRIVER->frame(selector => "default");
}

{ # travese parent to go to siblings
	$DRIVER->open(url => "/iframe");
	ok($DRIVER->present("#main-1"), "If we focus on a frame the siblings are findable");
	$DRIVER->frame(selector => '#main-0');
	ok(!$DRIVER->present("#main-1"), "If we focus on a frame the siblings are findable");
	$DRIVER->frame(selector => "default");
}

{ # travese parent to go to siblings
	$DRIVER->open(url => "/iframe");
	$DRIVER->frame(selector => '#main-1');
	is($DRIVER->text('#texter'), 'placeholder', 'Initial div text');
	$DRIVER->click(selector => 'form.click_test button');
	$DRIVER->click(selector => 'div#btn-div');
	is($DRIVER->text('#texter'), 'New Text', 'Clicked text changed');
	is($DRIVER->text('#btn-div-txt'), 'New Div Text', 'Div text changed');
	$DRIVER->frame(selector => "default");
	# verify the js works
	$DRIVER->open(url => '/iframe1');
	$DRIVER->click(selector => 'form.click_test button');
	$DRIVER->click(selector => '#btn-div');
	is($DRIVER->text('#texter'), 'New Text', 'Clicked text changed');
	is($DRIVER->text('#btn-div-txt'), 'New Div Text', 'Div text changed');

}

{ # Dynamically load an iframe and verify its location
	$DRIVER->open(url => "/frame_location");
	my ($x, $y) = $DRIVER->attribute(attr => 'location', selector => 'div#loader');
	my ($x1, $y1) = $DRIVER->attribute(attr => 'location', selector => "#frame");
	is($x, $x1, "div should match iframe x coord");
	is($y, $y1, "div should match iframe y coord");
	$DRIVER->frame(selector => '#frame');

	is($DRIVER->text('#texter'), 'placeholder', 'Initial div text');
	$DRIVER->click(selector => 'form.click_test button');
	$DRIVER->click(selector => 'div#btn-div');

	is($DRIVER->text('#texter'), 'New Text', 'Clicked text changed');
	is($DRIVER->text('#btn-div-txt'), 'New Div Text', 'Div text changed');
	$DRIVER->frame(selector => "default");
}

$DRIVER->disconnect;
stop_depends;
done_testing;
