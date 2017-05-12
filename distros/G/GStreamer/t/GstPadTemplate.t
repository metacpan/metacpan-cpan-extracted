#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

# $Id$

use Glib qw(TRUE FALSE);
use GStreamer -init;

my $caps = GStreamer::Caps::Empty -> new();

my $template = GStreamer::PadTemplate -> new("urgs", "src", "always", $caps);
isa_ok($template, "GStreamer::PadTemplate");
is($template -> get_name_template(), "urgs");
is($template -> get_direction(), "src");
is($template -> get_presence(), "always");
is($template -> get_caps(), $caps);

my $pad = GStreamer::Pad -> new("urgs", "src");
$template -> pad_created($pad);
