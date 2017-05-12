#!/usr/bin/perl -w
# $Id: http-timeout.t,v 1.2 2010/04/06 06:55:19 aederhaag Exp $
#
# Check timeouts via HTTP.
#


use File::Basename;
use Test::More tests => 5;

my ($file,$path) = fileparse($0);

require "${path}config.pl";
require HTTP::Status;
require LWP::Protocol::http;
require LWP::UserAgent::FramesReady;
require URI;

my $ua = new LWP::UserAgent::FramesReady;    # create a useragent to test
$ua->timeout(4);
isa_ok($ua, 'LWP::UserAgent::FramesReady');

$netloc = $net::httpserver;
$script = $net::cgidir . "/timeout";

$url = new URI->new("http://$netloc$script");
isa_ok($url, 'URI');

my $request = new HTTP::Request('GET', $url);
isa_ok($request, 'HTTP::Request');

print $request->as_string;

my $response = $ua->request($request, undef);

my $str = $response->as_string;

print "$str\n";

is($response->is_error, 1, "Expected error return");
like($str, qr/Internal Server/, "Expected timeout error");
# like($str, qr/timeout/, "Expected timeout error");

# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
