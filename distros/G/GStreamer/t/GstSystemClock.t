#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

# $Id$

use GStreamer -init;

my $clock = GStreamer::SystemClock -> obtain();
isa_ok($clock, "GStreamer::SystemClock");
isa_ok($clock, "GStreamer::Clock");
