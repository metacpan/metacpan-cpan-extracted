#!/usr/bin/perl -w
# $Id: http-get.t,v 1.2 2010/04/06 02:56:35 aederhaag Exp $
#
# Check GET via HTTP.
#

use File::Basename;
use Test::More tests => 6;

my ($file,$path) = fileparse($0);

require URI::URL;
require LWP::Protocol::http;
require LWP::UserAgent::FramesReady;

require "${path}config.pl";

my $ua = new LWP::UserAgent::FramesReady;    # create a useragent to test
isa_ok($ua, 'LWP::UserAgent::FramesReady');

$netloc = $net::httpserver;
$script = $net::cgidir . "/test";
$url = new URI::URL("http://$netloc$script?query");
isa_ok($url, 'URI::URL');

my $request = new HTTP::Request('GET', $url);
isa_ok($request, 'HTTP::Request');

print "GET $url\n\n";

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;
like($str, qr/^REQUEST_METHOD=GET$/m, "Expected response content");

print "$str\n";

is($response->is_success, 1, "Good HTTP response");
like($str, qr/^QUERY_STRING=query$/m, "Expected query response");


# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
