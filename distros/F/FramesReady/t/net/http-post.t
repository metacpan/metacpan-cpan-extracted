#!/usr/bin/perl -w
# $Id: http-post.t,v 1.2 2010/04/06 03:08:29 aederhaag Exp $
#
# Check POST via HTTP.
#

use File::Basename;
use Test::More tests => 8;

my ($file,$path) = fileparse($0);


require "${path}config.pl";
require LWP::Protocol::http;
require LWP::UserAgent::FramesReady;

$netloc = $net::httpserver;
$script = $net::cgidir . "/test";

my $ua = new LWP::UserAgent::FramesReady;    # create a useragent to test
isa_ok($ua, 'LWP::UserAgent::FramesReady');

$url = new URI::URL("http://$netloc$script");
isa_ok($url, 'URI::URL');

my $form = 'searchtype=Substring';

my $request = new HTTP::Request('POST', $url, undef, $form);
$request->header('Content-Type', 'application/x-www-form-urlencoded');
isa_ok($request, 'HTTP::Request');

my $response = $ua->request($request, undef, undef);
isa_ok($response, 'HTTP::Response');

my $str = $response->as_string;
like($str, qr/^REQUEST_METHOD=POST$/m, "Expected response content");
is($response->is_success, 1, "Good response");
print "$str\n";

like($str, qr/^CONTENT_LENGTH=(\d+)$/m, "Good content length");
$str =~ /^CONTENT_LENGTH=(\d+)$/m;
is($1, length($form), "Expected length matches form length");

# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
