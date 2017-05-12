#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Test::More;

# $Id$

use GStreamer -init;

my $src = GStreamer::ElementFactory -> make(alsasrc => "urgs");

if (not defined $src) {
  plan skip_all => 'failed to create an alsasrc';
} else {
  plan tests => 82;
}

# --------------------------------------------------------------------------- #

my $message = GStreamer::Message::EOS -> new($src);
isa_ok($message, "GStreamer::Message::EOS");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

ok($message -> type() & "eos");
ok(defined $message -> timestamp());
is($message -> src(), $src);

# --------------------------------------------------------------------------- #

my $error = Glib::Error::new("Glib::File::Error", "noent", "oops!");

$message = GStreamer::Message::Error -> new($src, $error, "oops!");
isa_ok($message, "GStreamer::Message::Error");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

isa_ok($message -> error(), "Glib::File::Error");
is($message -> error() -> value(), "noent");
is($message -> error() -> message(), "oops!");
is($message -> debug(), "oops!");

# --------------------------------------------------------------------------- #

$message = GStreamer::Message::Warning -> new($src, $error, "oops!");
isa_ok($message, "GStreamer::Message::Warning");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

isa_ok($message -> error(), "Glib::File::Error");
is($message -> error() -> value(), "noent");
is($message -> error() -> message(), "oops!");
is($message -> debug(), "oops!");

# --------------------------------------------------------------------------- #

my $tags = { title => ["Urgs"], artist => [qw(Screw You)] };

$message = GStreamer::Message::Tag -> new($src, $tags);
isa_ok($message, "GStreamer::Message::Tag");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

is_deeply($message -> tag_list(), $tags);

# --------------------------------------------------------------------------- #

$message = GStreamer::Message::StateChanged -> new($src, "null", "ready", "playing");
isa_ok($message, "GStreamer::Message::StateChanged");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

is($message -> old_state(), "null");
is($message -> new_state(), "ready");
is($message -> pending(), "playing");

# --------------------------------------------------------------------------- #

$message = GStreamer::Message::StateDirty -> new($src);
isa_ok($message, "GStreamer::Message::StateDirty");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

# --------------------------------------------------------------------------- #

my $clock = $src -> provide_clock();

SKIP: {
  skip "clock tests", 13
    unless defined $clock;

  $message = GStreamer::Message::ClockProvide -> new($src, $clock, TRUE);
  isa_ok($message, "GStreamer::Message::ClockProvide");
  isa_ok($message, "GStreamer::Message");
  isa_ok($message, "GStreamer::MiniObject");

  is($message -> clock(), $clock);
  is($message -> ready(), TRUE);

  $message = GStreamer::Message::ClockLost -> new($src, $clock);
  isa_ok($message, "GStreamer::Message::ClockLost");
  isa_ok($message, "GStreamer::Message");
  isa_ok($message, "GStreamer::MiniObject");

  is($message -> clock(), $clock);

  $message = GStreamer::Message::NewClock -> new($src, $clock);
  isa_ok($message, "GStreamer::Message::NewClock");
  isa_ok($message, "GStreamer::Message");
  isa_ok($message, "GStreamer::MiniObject");

  is($message -> clock(), $clock);
}

# --------------------------------------------------------------------------- #

my $structure = {
  name => "urgs",
  fields => [
    [field_one => "Glib::String" => "urgs"],
    [field_two => "Glib::Int" => 23]
  ]
};

$message = GStreamer::Message::Application -> new($src, $structure);
isa_ok($message, "GStreamer::Message::Application");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

is_deeply($message -> get_structure(), $structure);

# --------------------------------------------------------------------------- #

$message = GStreamer::Message::Element -> new($src, $structure);
isa_ok($message, "GStreamer::Message::Element");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

is_deeply($message -> get_structure(), $structure);

# --------------------------------------------------------------------------- #

$message = GStreamer::Message::SegmentStart -> new($src, "time", 23);
isa_ok($message, "GStreamer::Message::SegmentStart");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

is($message -> format(), "time");
is($message -> position(), 23);

# --------------------------------------------------------------------------- #

$message = GStreamer::Message::SegmentDone -> new($src, "time", 23);
isa_ok($message, "GStreamer::Message::SegmentDone");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

is($message -> format(), "time");
is($message -> position(), 23);

# --------------------------------------------------------------------------- #

$message = GStreamer::Message::Duration -> new($src, "time", 23);
isa_ok($message, "GStreamer::Message::Duration");
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

is($message -> format(), "time");
is($message -> duration(), 23);

# --------------------------------------------------------------------------- #

SKIP: {
  skip 'latency', 3
    unless GStreamer -> CHECK_VERSION(0, 10, 12);

  $message = GStreamer::Message::Latency -> new($src);
  isa_ok($message, "GStreamer::Message::Latency");
  isa_ok($message, "GStreamer::Message");
  isa_ok($message, "GStreamer::MiniObject");
}

# --------------------------------------------------------------------------- #

SKIP: {
  skip 'async start & done', 7
    unless GStreamer -> CHECK_VERSION(0, 10, 13);

  $message = GStreamer::Message::AsyncStart -> new($src, TRUE);
  isa_ok($message, "GStreamer::Message::AsyncStart");
  isa_ok($message, "GStreamer::Message");
  isa_ok($message, "GStreamer::MiniObject");

  is($message -> new_base_time, TRUE);

  $message = GStreamer::Message::AsyncDone -> new($src);
  isa_ok($message, "GStreamer::Message::AsyncDone");
  isa_ok($message, "GStreamer::Message");
  isa_ok($message, "GStreamer::MiniObject");
}

# --------------------------------------------------------------------------- #

$structure = {
  name => "urgs",
  fields => [
    [format => "GStreamer::Format" => "time"],
    [position => "Glib::Int" => 42],
    [duration => "Glib::Int" => 23],
    [sgru => "Glib::String" => "urgs"]
  ]
};

$message = GStreamer::Message::Custom -> new([qw(segment-done duration)], $src, $structure);
isa_ok($message, "GStreamer::Message");
isa_ok($message, "GStreamer::MiniObject");

is_deeply($message -> get_structure(), $structure);
