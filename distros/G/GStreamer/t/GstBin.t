#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;

# $Id$

use GStreamer -init;

my $bin = GStreamer::Bin -> new("urgs");
isa_ok($bin, "GStreamer::Bin");

my $factory = GStreamer::ElementFactory -> find("alsasink");
SKIP: {
  skip 'failed to create an alsasink factory', 8
    unless defined $factory;

  my $element_one = $factory -> create("sink one");
  my $element_two = $factory -> create("sink two");
  my $element_three = $factory -> create("sink three");
  my $element_four = $factory -> create("sink four");

  $bin -> add($element_one);
  $bin -> add($element_two, $element_three, $element_four);

  is($bin -> get_by_name("sink one"), $element_one);
  is($bin -> get_by_name_recurse_up("sink one"), $element_one);
  is($bin -> get_by_interface("GStreamer::TagSetter"), undef);

  isa_ok($bin -> iterate_elements(), "GStreamer::Iterator");
  isa_ok($bin -> iterate_sorted(), "GStreamer::Iterator");
  isa_ok($bin -> iterate_recurse(), "GStreamer::Iterator");
  isa_ok($bin -> iterate_sinks(), "GStreamer::Iterator");
  isa_ok($bin -> iterate_all_by_interface("GStreamer::TagSetter"), "GStreamer::Iterator");

  $bin -> remove($element_four);
  $bin -> remove($element_three, $element_two, $element_one);
}
