#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 39;

# $Id$

use Glib qw(TRUE FALSE);
use GStreamer -init;

my $factory = GStreamer::ElementFactory -> find("queue");
my $element = $factory -> create(undef);
isa_ok($element, "GStreamer::Element");

$element = $factory -> create("source");
isa_ok($element, "GStreamer::Element");

my ($tmp_one, $tmp_two) = GStreamer::ElementFactory -> make("alsasink", "tmp one",
                                                            "alsasink", "tmp two");

SKIP: {
  skip 'failed to create alsa elements', 37
    unless defined $tmp_one && defined $tmp_two;

  isa_ok($tmp_one, "GStreamer::Element");
  isa_ok($tmp_two, "GStreamer::Element");

  $element = GStreamer::ElementFactory -> make("alsasrc", "src");
  isa_ok($element, "GStreamer::Element");

  my @types = $element -> get_query_types();
  ok(grep { $_ eq 'seeking' } @types);

  ok(defined $element -> requires_clock());
  ok(defined $element -> provides_clock());

  is($element -> get_clock(), undef);

  my $clock = $element -> provide_clock();
 SKIP: {
    skip "clock test", 1
      unless defined $clock;

    isa_ok($clock, "GStreamer::Clock");
  }

  $element = GStreamer::ElementFactory -> make("alsasink", "sink");

  $element -> set_clock($clock);

  $element -> set_base_time(23);
  is($element -> get_base_time(), 23);

  $element -> set_state("ready");

  $element -> no_more_pads();

  ok(!$element -> is_indexable());
  $element -> set_index(GStreamer::Index -> new());
  is($element -> get_index(), undef);

  is($element -> get_bus(), undef);

  my $pad = GStreamer::Pad -> new("urgs", "src");

  ok($element -> add_pad($pad));

  is($element -> get_pad("urgs"), $pad);
  is($element -> get_static_pad("urgs"), $pad);
  is($element -> get_request_pad("urgs"), undef);

  my $caps = GStreamer::Caps::Any -> new();
  my $compatible_pad = $element -> get_compatible_pad($pad, $caps);
  SKIP: {
    skip 'get_compatible_pad returned undef', 1
      unless defined $compatible_pad;
    isa_ok($compatible_pad, "GStreamer::Pad");
  }

  ok($element -> remove_pad($pad));

  isa_ok($element -> iterate_pads(), "GStreamer::Iterator");
  isa_ok($element -> iterate_src_pads(), "GStreamer::Iterator");
  isa_ok($element -> iterate_sink_pads(), "GStreamer::Iterator");

  my $element_one = $factory -> create("source one");
  my $element_two = $factory -> create("source two");
  my $element_three = $factory -> create("source three");
  my $element_four = $factory -> create("source four");
  my $element_five = $factory -> create("source five");

  my $bin = GStreamer::Pipeline -> new("urgs");
  $bin -> add($element_one, $element_two, $element_three, $element_four, $element_five);

  ok($element_one -> link($element_two));
  ok($element_two -> link($element_three, $element_four));
  ok($element_four -> link_filtered($element_five, $caps));

  $element_one -> unlink($element_two);
  $element_two -> unlink($element_three, $element_four, $element_five);

  my $pad_one = GStreamer::Pad -> new("urgs", "src");
  my $pad_two = GStreamer::Pad -> new("urgs", "sink");
  my $pad_three = GStreamer::Pad -> new("urgs", "src");
  my $pad_four = GStreamer::Pad -> new("urgs", "sink");

  $element_one -> add_pad($pad_one);
  $element_two -> add_pad($pad_two);
  $element_three -> add_pad($pad_three);
  $element_four -> add_pad($pad_four);

  ok(!$element_one -> link_pads("urgs", $element_two, "urgs"));
  ok(!$element_three -> link_pads_filtered("urgs", $element_four, "urgs", $caps));
  $element_three -> unlink_pads("urgs", $element_four, "urgs");

  ok(defined $element -> send_event(GStreamer::Event::EOS -> new()));

  ok(defined $element -> seek(1.0, "default", [qw(flush accurate)], "cur", 23, "set", 42));

  ok(!$element -> query(GStreamer::Query::Duration -> new("time")));

  ok(!$element -> post_message(GStreamer::Message::EOS -> new($element)));

  my $test_tags = { title => ["Urgs"], artist => [qw(Screw You)] };

  $element_one -> found_tags($test_tags);
  $element_one -> found_tags_for_pad($pad_one, $test_tags);

  ok($element -> set_locked_state(TRUE));
  ok($element -> is_locked_state());
  ok(!$element -> sync_state_with_parent());

  isa_ok($element -> get_factory(), "GStreamer::ElementFactory");

  $element -> abort_state();
  $element -> lost_state();

  is($element -> set_state("null"), "success");
  is($element -> continue_state("success"), "success");
  is_deeply([$element -> get_state(0)], ["success", "null", "void-pending"]);
}
