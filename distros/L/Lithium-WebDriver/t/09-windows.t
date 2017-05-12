#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;


my $site = start_depends;


# Check to make sure visit works
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
	$DRIVER->connect;
	is $DRIVER->url, "$site", "The address bar should be: $site";
	$DRIVER->open(url => '/test3');
	is $DRIVER->url, "${site}test3", "The address bar should be: ${site}test3";
	is $DRIVER->title, 'webdriver test 3', "Ensure the title is correct";
	$DRIVER->disconnect;
}

# Slowness is from waiting for the page to load everytime window_titles is called
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
	$DRIVER->connect;
	$DRIVER->click(selector => "a#_test2");
	my $titles = $DRIVER->window_names;
	is $titles->[-1], "webdriver test 2",   "webdriver 2 should be the last window";
	$DRIVER->click(
		selector => "a#_test3"
	);
	$titles = $DRIVER->window_names;
	is $titles->[-1], "webdriver test 3", "webdriver 3 should be the last window";
	$DRIVER->disconnect;
}

# yes this was an issue and yes this helped me solve it
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
	$DRIVER->connect;
	$DRIVER->window_tracking('strict');
	$DRIVER->click(selector => "a#_test1");
	$DRIVER->click(selector => "a#_test2");
	$DRIVER->click(selector => "a#_test3");
	my $titles = $DRIVER->window_names;
	is $titles->[1], "webdriver test",  "test 1 should be the second window";
	is $titles->[2], "webdriver test 2",   "test 2 should be the third window";
	is $titles->[3], "webdriver test 3", "test 3 should be the last window";
	$DRIVER->disconnect;
}

{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
	$DRIVER->connect;
	$DRIVER->click(selector => "a#_test1");
	$DRIVER->click(selector => "a#_test2");
	$DRIVER->click(selector => "a#_test3");
	my $titles = $DRIVER->window_names;
	$DRIVER->open_window(url => "http://www.google.com");
	$titles = $DRIVER->window_names;
	is $titles->[-1], "Google", "google should now be the last window";
	$DRIVER->disconnect;
}
{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
	$DRIVER->connect;
	$DRIVER->window_tracking('strict');
	$DRIVER->click(selector => "a#_test1");
	$DRIVER->click(selector => "a#_test2");
	$DRIVER->click(selector => "a#_test3");
	$DRIVER->open_window(url => "http://www.google.com");
	my $titles = $DRIVER->window_names;
	is $titles->[1], "webdriver test", "test 1 should be the second window";
	is $titles->[-1], "Google", "google should now be the last window";
	$DRIVER->disconnect;
}

{
	my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
	$DRIVER->connect;
	$DRIVER->click(selector => "a#_test1");
	$DRIVER->click(selector => "a#_test2");
	$DRIVER->click(selector => "a#_test3");
	$DRIVER->open_window(url => "http://www.google.com");
	like $DRIVER->title, qr/google/i, 'Auto select last window opened';
	$DRIVER->disconnect;
}

stop_depends;
done_testing;
