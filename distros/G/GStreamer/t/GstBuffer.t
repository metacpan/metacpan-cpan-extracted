#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 16;

# $Id$

use GStreamer -init;

my $buffer = GStreamer::Buffer -> new();
isa_ok($buffer, "GStreamer::Buffer");
isa_ok($buffer, "GStreamer::MiniObject");

ok (!$buffer -> data_ptr());
$buffer -> set_data("urgs");
ok (defined $buffer -> data_ptr());
$buffer -> stamp(GStreamer::Buffer -> new());

my $caps = GStreamer::Caps::Simple -> new("audio/mpeg",
                                          foo => "Glib::String" => "bar");
$buffer -> set_caps($caps);
is($buffer -> get_caps(), $caps);

isa_ok($buffer -> create_sub(0, 4), "GStreamer::Buffer");
isa_ok($buffer -> merge(GStreamer::Buffer -> new()), "GStreamer::Buffer");
isa_ok($buffer -> span(0, GStreamer::Buffer -> new(), 4), "GStreamer::Buffer");
isa_ok($buffer -> join(GStreamer::Buffer -> new()), "GStreamer::Buffer");
like($buffer -> is_span_fast(GStreamer::Buffer -> new()), qr/^(?:1|)$/);

is($buffer -> data(), "urgs");
is($buffer -> size(), 4);
ok($buffer -> timestamp() > 0);
ok($buffer -> duration() > 0);
ok($buffer -> offset() > 0);
ok($buffer -> offset_end() > 0);
