#!/usr/bin/perl -w
use strict;
use warnings;
use HTML::Encoding 'encoding_from_http_message';
use LWP::UserAgent;

if (@ARGV != 1) {
  printf "Usage: %s http://www.example.org/\n", $0;
  exit;
}

my $resp = LWP::UserAgent->new->get('http://www.example.org');
my $enco = encoding_from_http_message($resp);
printf "%s is probably %s-encoded\n", $resp->request->uri, $enco;
