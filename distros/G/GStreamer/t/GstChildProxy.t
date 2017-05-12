#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

# $Id$

use GStreamer -init;

my $bin = GStreamer::Bin -> new("urgs");
isa_ok($bin, "GStreamer::ChildProxy");

my $element = GStreamer::ElementFactory -> make(alsasink => "sink");
SKIP: {
  skip 'failed to create an alsasinnk', 7
    unless defined $element;

  $bin -> add($element);
  $bin -> child_added($element);

  is($bin -> get_children_count(), 1);
  is($bin -> get_child_by_name("sink"), $element);
  is($bin -> get_child_by_index(0), $element);
  is($bin -> get_child_by_name("knis"), undef);
  is($bin -> get_child_by_index(1), undef);

  $bin -> set_child_property("sink::device" => "/dev/dsp");
  is($bin -> get_child_property("sink::device"), "/dev/dsp");

  $bin -> set_child_property("sink::buffer-time" => 23, "sink::latency-time" => 42);
  is_deeply([$bin -> get_child_property("sink::buffer-time", "sink::latency-time")], [23, 42]);

  $bin -> remove($element);
  $bin -> child_removed($element);
}
