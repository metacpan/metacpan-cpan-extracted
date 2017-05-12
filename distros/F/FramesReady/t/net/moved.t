#!/usr/local/bin/perl -w
# $Id: moved.t,v 1.2 2010/04/07 09:18:26 aederhaag Exp $
#

use File::Basename;
use Test::More tests => 6;
use diagnostics;

my ($junk,$path) = fileparse($0); # Just capture the path

require_ok("${path}config.pl");
require_ok('LWP::Debug');
require_ok('LWP::UserAgent::FramesReady');

$url = "http://$net::httpserver$net::cgidir/moved";

#LWP::Debug::level('+trace');

my $ua = new LWP::UserAgent::FramesReady;    # create a useragent to test
$ua->timeout(30);               # timeout in seconds
isa_ok($ua, 'LWP::UserAgent::FramesReady');

my $request = new HTTP::Request('GET', $url);
isa_ok($request,'HTTP::Request');

print $request->as_string;

my $response = $ua->request($request, undef, undef);

print $response->as_string, "\n";
is($response->is_success, 1, "Expected good return");

# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
