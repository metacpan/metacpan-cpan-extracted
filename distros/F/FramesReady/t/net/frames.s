#!/usr/local/bin/perl -w
# -*- mode: cperl; -*-
#
# Check GET via HTTP.
#

print "1..7\n";

#  use lib qw{../../blib/lib ../../blib/arch};
#  require "./config.pl";

require "net/config.pl";
require LWP::Protocol::http;
require LWP::UserAgent::FramesReady;
require URI;

my $ua = new LWP::UserAgent::FramesReady;    # create a useragent to test

$netloc = $net::httpserver;
$script = $net::cgidir . "/frametst";

$url = new URI->new("http://$netloc$script?query");

my $request = new HTTP::Request('GET', $url);

print "GET $url\n\n";

my $response = $ua->request($request);

my $str = $response->as_string;

print "$str\n";

my $tree_good = 0;
if ($response->is_success and $response->isa('HTTP::Response::Tree')) {
  print "ok 1\n";
  $tree_good = 1;
} else {
  print "not ok 1\n";
}

unless ($tree_good and scalar $response->descendants == 2) {
  print "not ";
}
print "ok 2\n";
unless ($tree_good and scalar $response->children == 2) {
  print "not ";
}
print "ok 3\n";

unless ($tree_good and $response->max_depth == 3 ) {
  print "not ";
}
print "ok 4\n";

if ($tree_good) {
  @childrn = $response->children;
  $chld = shift @childrn;
  unless ($chld->max_depth == 2) {
    print "not ";
  }
  print "ok 5\n";
  unless ($chld->code == 200) {
    print "not ";
  }
  print "ok 6\n";
  $chld = shift @childrn;
  unless ($chld->code == 404) {
    print "not ";
  }
  print "ok 7\n";
} else {
  for (5..7) {
    print "not ok $_\n";
  }
}

# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
