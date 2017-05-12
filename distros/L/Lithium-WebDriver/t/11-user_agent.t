#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;

plan skip_all => "We only test UA changes against phantom" unless is_phantom;

my $site = start_depends;

# Test defaults
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
	$DRIVER->connect;
	like($DRIVER->run(js => "return navigator.userAgent;"),
		qr/^Mozilla\/5\.0\s+\(Unknown; Linux x86_64\)\s+AppleWebKit\/\d+\.\d+\s+\(KHTML,\s+like\s+Gecko\)\s+PhantomJS\/\d\.\d\.\d\s+Safari\/\d+\.\d+$/,
		"Ensure the default user-agent for phantom is phantom");
	$DRIVER->disconnect;
}


# Be able to set UA to Firefox
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site, ua => 'linux firefox')});
	$DRIVER->connect;
	is($DRIVER->run(js => "return navigator.userAgent;"),
		"Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
		"Ensure the default user-agent is settable to Firefox");
	$DRIVER->disconnect;
}


# Be able to set UA to Chrome
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site, ua => 'linux chrome')});
	$DRIVER->connect;
	is($DRIVER->run(js => "return navigator.userAgent;"),
		"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.26 Safari/537.36",
		"Ensure the default user-agent is settable to Firefox");
	$DRIVER->disconnect;
}


# Be able to set UA to Android
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site, ua => 'android default')});
	$DRIVER->connect;
	is($DRIVER->run(js => "return navigator.userAgent;"),
		"Mozilla/5.0 (Linux; U; Android 4.0.3; de-de; Galaxy S II Build/GRJ22) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
		"Ensure the default user-agent is settable to an Android UA");
	$DRIVER->disconnect;
}


# Be able to set UA to Android Firefox
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site, ua => 'android firefox')});
	$DRIVER->connect;
	is($DRIVER->run(js => "return navigator.userAgent;"),
		"Mozilla/5.0 (Android; Mobile; rv:29.0) Gecko/29.0 Firefox/29.0",
		"Ensure the default user-agent is settable to an Android UA");
	$DRIVER->disconnect;
}


# Be able to set UA to Iphone
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site, ua => 'apple iphone')});
	$DRIVER->connect;
	is($DRIVER->run(js => "return navigator.userAgent;"),
		"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_2_1 like Mac OS X; da-dk) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8C148 Safari/6533.18.5",
		"Ensure the default user-agent is settable to an Iphone UA");
	$DRIVER->disconnect;
}


# Be able to set UA to ipad
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site, ua => 'Apple Ipad')});
	$DRIVER->connect;
	is($DRIVER->run(js => "return navigator.userAgent;"),
		"Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25",
		"Ensure the default user-agent is settable to an Ipad UA");
	$DRIVER->disconnect;
}


# Default to phantom on bad ua
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site, ua => 'DNE')});
	$DRIVER->connect;
	like($DRIVER->run(js => "return navigator.userAgent;"),
		qr/^Mozilla\/5\.0\s+\(Unknown; Linux x86_64\)\s+AppleWebKit\/\d+\.\d+\s+\(KHTML,\s+like\s+Gecko\)\s+PhantomJS\/\d\.\d\.\d\s+Safari\/\d+\.\d+$/,
		"Ensure the default user-agent is settable to phantom on bad ua");
	$DRIVER->disconnect;
}


# Set ua should stay same on target="_blank"
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site, ua => 'Linux - Firefox')});
	$DRIVER->connect;
	is($DRIVER->run(js => "return navigator.userAgent;"),
		"Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
		"Ensure the user-agent is firefox");
	$DRIVER->click(selector => 'a#_test2');
	$DRIVER->select_window(method => 'title', value => "webdriver test 2");

	my $ua = $DRIVER->run(js => "return navigator.userAgent;");
	TODO: {
		local $TODO = "Bug in ghostdriver see:"
			." https://github.com/detro/ghostdriver/issues/273"
			." for more information";
		is($ua, "Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
			"Ensure new window user-agent is firefox on target='_blank'");
	}
	$DRIVER->disconnect;
}


# Set ua should stay same on new_window creation
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site, ua => 'Linux - Firefox')});
	$DRIVER->connect;
	is($DRIVER->run(js => "return navigator.userAgent;"),
		"Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
		"Ensure the user-agent is firefox");
	$DRIVER->open_window(url => "http://www.google.com");
	$DRIVER->select_window(method => 'title', value => 'google');

	my $ua = $DRIVER->run(js => "return navigator.userAgent;");
	TODO: {
		local $TODO = "Bug in ghostdriver see:"
			." https://github.com/detro/ghostdriver/issues/273"
			." for more information";
		is($ua, "Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
			"Ensure new window user-agent is firefox on framework new_window call");
	}
	$DRIVER->disconnect;
}


stop_depends;
done_testing;
