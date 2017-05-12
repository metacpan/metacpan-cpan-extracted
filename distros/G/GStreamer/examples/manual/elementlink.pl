#!/usr/bin/perl
use strict;
use warnings;
use GStreamer -init;

# $Id$

# create elements
my ($source, $filter, $sink) =
  GStreamer::ElementFactory -> make(fakesrc => "source",
                                    identity => "filter",
                                    fakesink => "sink");

# link
$source -> link($filter, $sink);
