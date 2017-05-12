#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

# $Id$

use Glib qw(TRUE FALSE);
use GStreamer -init;

my $tagger = GStreamer::ElementFactory -> make(vorbisenc => "tagger");

SKIP: {
  skip "tagger tests -- vorbisenc not found", 3
    unless defined $tagger;

  isa_ok($tagger, "GStreamer::TagSetter");

  my $tags = { title => ["Urgs"], artist => [qw(Screw You)] };

  $tagger -> merge_tags($tags, "replace");
  $tagger -> add_tags("append",
                      title => "Urgs 2",
                      artist => "Screw You");

  is_deeply($tagger -> get_tag_list(), { title => ["Urgs", "Urgs 2"], artist => ["Screw", "You", "Screw You"] });

  $tagger -> set_tag_merge_mode("replace-all");
  is($tagger -> get_tag_merge_mode(), "replace-all");
}
