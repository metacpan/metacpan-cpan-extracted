#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 43;

# $Id$

use Glib qw(TRUE FALSE);
use GStreamer -init;

my $caps = GStreamer::Caps::Empty -> new();
my $template = GStreamer::PadTemplate -> new("urgs", "src", "always", $caps);

my $pad = GStreamer::Pad -> new("urgs", "src");
isa_ok($pad, "GStreamer::Pad");

$pad = GStreamer::Pad -> new_from_template($template, "urgs");
isa_ok($pad, "GStreamer::Pad");

is($pad -> get_direction(), "src");

$pad -> set_active(TRUE);
ok($pad -> is_active());
ok($pad -> activate_push(FALSE));
ok($pad -> activate_pull(FALSE));

ok(!$pad -> set_blocked(FALSE));
ok(!$pad -> is_blocked());

is($pad -> get_pad_template(), $template);

my $source = GStreamer::ElementFactory -> make("fakesrc", "source");
my $sink = GStreamer::ElementFactory -> make("fakesink", "sink");

my $source_pad = $source -> get_pad("src");
my $sink_pad = $sink -> get_pad("sink");

ok(!$source_pad -> link($sink_pad));
ok($source_pad -> is_linked());
ok($sink_pad -> is_linked());
is($source_pad -> get_peer(), $sink_pad);
is($sink_pad -> get_peer(), $source_pad);
$source_pad -> unlink($sink_pad);

is($pad -> get_pad_template_caps(), $caps);
is($pad -> get_caps(), $caps);

my $structure = {
  name => "urgs",
  fields => [
    [field_one => "Glib::String" => "urgs"],
    [field_two => "Glib::Int" => 23]
  ]
};

my $fixed_caps = GStreamer::Caps::Full -> new($structure);

ok($pad -> set_caps($fixed_caps));
$pad -> fixate_caps($fixed_caps);
ok(defined $pad -> accept_caps($fixed_caps));

is($pad -> peer_get_caps(), undef);
ok($pad -> peer_accept_caps($caps));

is($source_pad -> get_allowed_caps(), undef);
is($source_pad -> get_negotiated_caps(), undef);

my $buffer = GStreamer::Buffer -> new();

is($source_pad -> push($buffer), "not-linked");
ok(!$source_pad -> check_pull_range());

is_deeply([$sink_pad -> pull_range(0, 23)], ["not-linked", undef]);

my $event = GStreamer::Event::EOS -> new();
ok(!$pad -> push_event($event));
ok(!$pad -> event_default($event));

$sink_pad -> activate_push(TRUE);
ok($sink_pad -> chain($buffer));

is_deeply([$source_pad -> get_range(0, 23)], ["wrong-state", undef]);

ok($sink_pad -> send_event($event));

SKIP: {
  skip 'pad tasks don\'t quite work yet', 3;

  ok($pad -> start_task(sub {
    ok($pad -> pause_task());
  }, 'bla'));
  ok($pad -> stop_task());
}

is($pad -> get_internal_links(), undef);
is($pad -> get_internal_links_default(), undef);

is($pad -> get_query_types(), undef);
is($pad -> get_query_types_default(), undef);

my $query = GStreamer::Query::Position -> new("time");
ok(!$pad -> query($query));
ok(!$pad -> query_default($query));

SKIP: {
  skip 'new 0.10.11 stuff', 1
    unless GStreamer->CHECK_VERSION(0, 10, 11);

  ok(defined $pad -> is_blocking());
}

SKIP: {
  skip 'new 0.10.15 stuff', 1
    unless GStreamer->CHECK_VERSION(0, 10, 15);

  ok(defined $pad -> peer_query($query));
}

SKIP: {
  skip 'new 0.10.21 stuff', 2
    unless GStreamer->CHECK_VERSION(0, 10, 21);

  is($pad -> iterate_internal_links(), undef);
  is($pad -> iterate_internal_links_default(), undef);
}
