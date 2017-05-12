#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;
use JSON::XS qw/decode_json/;

my $site   = start_depends;
my %config = %{driver_conf(site => $site)};
my $DRIVER = Lithium::WebDriver->new(%config);
$DRIVER->connect;
is $DRIVER->url, "$site", "The address bar should be: $site";
$DRIVER->disconnect;

my $ua  = LWP::UserAgent->new();
if ($config{browser} eq "phantomjs") {
	my $url = "http://$config{host}:$config{port}/sessions";
	note "Checking $url for sessions";
	my $res = $ua->get($url);
	ok 0, "Not able to get sessions from: $url"
		unless $res->is_success;
	my $data = decode_json($res->content);
	ok !scalar @{$data->{value}}, "Was unable to delete sessions from $url";
} else {
	note "Selenium grid doesn't implement sessions that well";
}

stop_depends;
done_testing;
