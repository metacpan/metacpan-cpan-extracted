#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;

# $Id$

use Glib qw(TRUE FALSE);
use GStreamer -init;

ok(GStreamer::Tag::exists("artist"));
is(GStreamer::Tag::get_type("artist"), "Glib::String");
ok(defined GStreamer::Tag::get_nick("artist"));
ok(defined GStreamer::Tag::get_description("artist"));
isa_ok(GStreamer::Tag::get_flag("artist"), "GStreamer::TagFlag");
ok(!GStreamer::Tag::is_fixed("artist"));
