#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

# $Id$

use GStreamer -init;

my $feature = GStreamer::ElementFactory -> find("alsasink");
SKIP: {
  skip 'failed to load alsasink', 5
    unless defined $feature;

  isa_ok($feature, "GStreamer::PluginFeature");

  isa_ok($feature = $feature -> load(), "GStreamer::PluginFeature");

  $feature -> set_rank(23);
  is($feature -> get_rank(), 23);

  $feature -> set_name("alsasink");
  is($feature -> get_name(), "alsasink");

  ok($feature -> check_version(0, 0, 0));
}
