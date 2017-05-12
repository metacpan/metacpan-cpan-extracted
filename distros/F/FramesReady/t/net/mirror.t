#!/usr/bin/perl -w
# $Id: mirror.t,v 1.2 2010/04/08 04:16:28 aederhaag Exp $
#
# Test mirroring a file
#

use File::Basename;
use Test::More tests => 5;
use diagnostics;

my ($junk,$path) = fileparse($0); # Just capture the path

require "${path}config.pl";
require LWP::Protocol::http;
require LWP::UserAgent::FramesReady;
require HTTP::Status;

# Kludge to get around the temporary file write problem for apache user
my $copy = "/var/tmp/lwp-test-$$";

my $ua = new LWP::UserAgent::FramesReady;    # create a useragent to test
isa_ok($ua, 'LWP::UserAgent::FramesReady');

my $url = "http://$net::httpserver" . $net::cgidir . "/test";
my $response = $ua->mirror($url, $copy);

isa_ok($response, 'HTTP::Response');
is($response->code, &HTTP::Status::RC_OK, "Got the expected good response code");

my $str = $response->as_string;
print "$str\n";

my $file = "file://$copy";
my $req = HTTP::Request->new('GET', $file);
my ($mtime) = ( stat($copy) )[9];
if ($mtime) {
    $req->header( 'If-Modified-Since' => HTTP::Date::time2str($mtime) );
}
print $req->as_string, "\n";

$response = $ua->request($req);
is($response->code, &HTTP::Status::RC_NOT_MODIFIED, "Expected NOT MODIFIED status code");
$str = $response->as_string;
print "$str\n";

unlink($copy);
isnt(-e $copy, 1, "Mirror copy cleanup successful");

$dummy = $net::httpserver;  # avoid -w warning
$dummy = $net::cgidir;

