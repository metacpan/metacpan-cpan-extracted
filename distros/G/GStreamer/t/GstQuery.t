#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 22;

# $Id$

use GStreamer -init;

is(GStreamer::QueryType::register("urgs", "Urgs!"), "urgs");
is(GStreamer::QueryType::get_by_nick("segment"), "segment");
is_deeply([GStreamer::QueryType::get_details("urgs")], ["urgs", "urgs", "Urgs!"]);
# is_deeply((GStreamer::QueryType::get_definitions())[-1], ["urgs", "urgs", "Urgs!"]);

# --------------------------------------------------------------------------- #

my $query = GStreamer::Query::Position -> new("time");
isa_ok($query, "GStreamer::Query::Position");
isa_ok($query, "GStreamer::Query");
isa_ok($query, "GStreamer::MiniObject");

$query -> position("time", 23);
is_deeply([$query -> position()], ["time", 23]);

# --------------------------------------------------------------------------- #

$query = GStreamer::Query::Duration -> new("time");
isa_ok($query, "GStreamer::Query::Duration");
isa_ok($query, "GStreamer::Query");
isa_ok($query, "GStreamer::MiniObject");

$query -> duration("time", 23);
is_deeply([$query -> duration()], ["time", 23]);

# --------------------------------------------------------------------------- #

$query = GStreamer::Query::Convert -> new("time", 23, "buffers");
isa_ok($query, "GStreamer::Query::Convert");
isa_ok($query, "GStreamer::Query");
isa_ok($query, "GStreamer::MiniObject");

$query -> convert("time", 23, "buffers", 42);
is_deeply([$query -> convert()], ["time", 23, "buffers", 42]);

# --------------------------------------------------------------------------- #

$query = GStreamer::Query::Segment -> new("time");
isa_ok($query, "GStreamer::Query::Segment");
isa_ok($query, "GStreamer::Query");
isa_ok($query, "GStreamer::MiniObject");

$query -> segment(1.0, "time", 23, 42);
is_deeply([$query -> segment()], [1.0, "time", 23, 42]);

# --------------------------------------------------------------------------- #

my $structure = {
  name => "urgs",
  fields => [
    [field_one => "Glib::String" => "urgs"],
    [field_two => "Glib::Int" => 23]
  ]
};

$query = GStreamer::Query::Application -> new("urgs", $structure);
isa_ok($query, "GStreamer::Query");
isa_ok($query, "GStreamer::MiniObject");

is_deeply($query -> get_structure(), $structure);
