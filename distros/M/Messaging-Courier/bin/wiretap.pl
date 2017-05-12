#!/usr/bin/perl -w
use strict;
use warnings;
use lib 'lib';
use Messaging::Courier::Wiretap;
use XML::LibXML;

my $w = Messaging::Courier::Wiretap->new();

my $p = XML::LibXML->new;

while (1) {
  my $xml = $w->tap(10);
  next unless $xml;
  if ($xml !~ /NoiseMessage/) {
    my $d = $p->parse_string($xml);
    print $d->toString(1), "\n";
  }
}

