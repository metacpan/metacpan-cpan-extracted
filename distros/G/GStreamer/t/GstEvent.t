#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 53;

# $Id$

use GStreamer -init;
use Glib qw(TRUE FALSE);

my $structure = {
  name => "urgs",
  fields => [
    [field_one => "Glib::String" => "urgs"],
    [field_two => "Glib::Int" => 23]
  ]
};

my $event = GStreamer::Event::Custom -> new("seek", $structure);
isa_ok($event, "GStreamer::Event::Seek");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

is_deeply($event -> get_structure(), $structure);

# --------------------------------------------------------------------------- #

$event = GStreamer::Event::FlushStart -> new();
isa_ok($event, "GStreamer::Event::FlushStart");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

# --------------------------------------------------------------------------- #

$event = GStreamer::Event::FlushStop -> new();
isa_ok($event, "GStreamer::Event::FlushStop");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

# --------------------------------------------------------------------------- #

$event = GStreamer::Event::EOS -> new();
isa_ok($event, "GStreamer::Event::EOS");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

# --------------------------------------------------------------------------- #

$event = GStreamer::Event::NewSegment -> new(TRUE, 1.0, "time", 1, 2, 3);
isa_ok($event, "GStreamer::Event::NewSegment");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

ok($event -> update());
is($event -> rate(), 1.0);
is($event -> format(), "time");
is($event -> start_value(), 1);
is($event -> stop_value(), 2);
is($event -> stream_time(), 3);

# --------------------------------------------------------------------------- #

my $tag = { title => ["Urgs"], artist => [qw(Screw You)] };

$event = GStreamer::Event::Tag -> new($tag);
isa_ok($event, "GStreamer::Event::Tag");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

is_deeply($event -> tag(), $tag);

# --------------------------------------------------------------------------- #

$event = GStreamer::Event::Navigation -> new($structure);
isa_ok($event, "GStreamer::Event::Navigation");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

is_deeply($event -> get_structure(), $structure);

# --------------------------------------------------------------------------- #

$event = GStreamer::Event::BufferSize -> new("time", 1, 2, TRUE);
isa_ok($event, "GStreamer::Event::BufferSize");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

is($event -> format(), "time");
is($event -> minsize(), 1);
is($event -> maxsize(), 2);
ok($event -> async());

# --------------------------------------------------------------------------- #

$event = GStreamer::Event::QOS -> new(1.0, 23, 42);
isa_ok($event, "GStreamer::Event::QOS");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

is($event -> proportion(), 1.0);
is($event -> diff(), 23);
is($event -> timestamp(), 42);

# --------------------------------------------------------------------------- #

$event = GStreamer::Event::Seek -> new(1.0, "time", [qw(flush accurate)], "cur", 23, "set", 42);
isa_ok($event, "GStreamer::Event::Seek");
isa_ok($event, "GStreamer::Event");
isa_ok($event, "GStreamer::MiniObject");

is($event -> rate(), 1.0);
is($event -> format(), "time");
ok($event -> flags() == [qw(flush accurate)]);
is($event -> cur_type(), "cur");
is($event -> cur(), 23);
is($event -> stop_type(), "set");
is($event -> stop(), 42);
