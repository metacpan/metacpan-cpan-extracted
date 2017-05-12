#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

# $Id: GstGConf.t,v 1.1 2005/08/13 17:22:58 kaffeetisch Exp $

use GStreamer -init;
use GStreamer::GConf;

my $sink = GStreamer::GConf -> get_string("default/audiosink");
ok(defined $sink);

# GStreamer::GConf -> set_string("default/audiosink", $sink);

my $key = "default/visualization";
my $desc = GStreamer::GConf -> get_string($key);

foreach (GStreamer::GConf -> render_bin_from_key($key),
         GStreamer::GConf -> render_bin_from_description($desc),
         GStreamer::GConf -> get_default_video_sink(),
         GStreamer::GConf -> get_default_audio_sink(),
         GStreamer::GConf -> get_default_video_src(),
         GStreamer::GConf -> get_default_audio_src(),
         GStreamer::GConf -> get_default_visualization_element()) {
  isa_ok($_, "GStreamer::Element");
}
