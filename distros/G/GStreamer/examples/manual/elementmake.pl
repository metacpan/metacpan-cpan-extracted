#!/usr/bin/perl
use strict;
use warnings;
use GStreamer -init;

# $Id$

# create element
my $element = GStreamer::ElementFactory -> make("fakesrc", "source");
unless ($element) {
  print "Failed to create element of type 'fakesrc'\n";
  exit -1;
}
