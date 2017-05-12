#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

# $Id$

use GStreamer -init;

my $factory = GStreamer::IndexFactory -> new("urgs", "Urgs!", "GStreamer::Index");
isa_ok($factory, "GStreamer::IndexFactory");

# FIXME
# isa_ok($factory -> create(), "GStreamer::Index");

is(GStreamer::IndexFactory -> find("urgs"), undef);
is(GStreamer::IndexFactory -> make("urgs"), undef);

$factory -> destroy();
