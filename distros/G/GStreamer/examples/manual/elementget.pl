#!/usr/bin/perl
use strict;
use warnings;
use GStreamer -init;

# $Id$

my $element = GStreamer::ElementFactory -> make("fakesrc", "source");

printf "The name of the element is '%s'.\n",
       $element -> get("name");
