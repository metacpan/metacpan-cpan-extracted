#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

# $Id$

use GStreamer -init;

my $pad = GStreamer::Pad -> new("urgs", "src");

my $gpad = GStreamer::GhostPad -> new("urgs", $pad);
SKIP: {
  skip 'new() returned undef', 4
    unless defined $gpad;

  isa_ok($gpad, "GStreamer::GhostPad");
  is($gpad -> get_target(), $pad);

  ok($gpad -> set_target($pad));
  is($gpad -> get_target(), $pad);
}

$pad = GStreamer::Pad -> new("urgs", "src");
$gpad = GStreamer::GhostPad -> new(undef, $pad);
SKIP: {
  skip 'new() returned undef', 2
    unless defined $gpad;

  isa_ok($gpad, "GStreamer::GhostPad");
  is($gpad -> get_target(), $pad);
}

$gpad = GStreamer::GhostPad -> new_no_target("urgs", "src");
isa_ok($gpad, "GStreamer::GhostPad");
is($gpad -> get_target(), undef);
