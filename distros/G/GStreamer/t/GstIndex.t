#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;

# $Id$

use GStreamer -init;

my $index = GStreamer::Index -> new();
isa_ok($index, "GStreamer::Index");

$index -> commit(23);

is($index -> new_group(), 1);
ok($index -> set_group(1));
is($index -> get_group(), 1);

$index -> set_certainty("fuzzy");
is($index -> get_certainty(), "fuzzy");

$index -> set_filter(sub { warn @_; 1; }, "bla");

my $object = GStreamer::ElementFactory -> make("alsasink", "sink");
SKIP: {
  skip 'index entry tests: failed to create an alsasink', 10
    unless defined $object;

  # Called by get_writer_id()
  $index -> set_resolver(sub {
    my ($index, $element, $data) = @_;

    isa_ok($index, "GStreamer::Index");
    isa_ok($element, "GStreamer::Element");
    is($data, "blub");

    return "urgs";
  }, "blub");

  my $id = $index -> get_writer_id($object);
  skip 'index entry tests: failed to obtain a writer id', 7
    unless defined $id;

  my $entry = $index -> add_format($id, "bytes");
  isa_ok($entry, "GStreamer::IndexEntry");

  $entry = $index -> add_association($id, "key-unit", bytes => 12, time => 13);
  isa_ok($entry, "GStreamer::IndexEntry");
  is($entry -> assoc_map("bytes"), 12);
  is($entry -> assoc_map("time"), 13);

  $entry = $index -> add_object($id, "urgs", $object);
  TODO: {
    local $TODO = 'add_object always returns undef';
    isa_ok($entry, "GStreamer::IndexEntry");
  }

  $entry = $index -> add_id($id, "sgru");
  isa_ok($entry, "GStreamer::IndexEntry");

  $entry = $index -> get_assoc_entry($id, "exact", "key-unit", bytes => 12);
  TODO: {
    local $TODO = 'get_assoc_entry always returns undef';
    isa_ok($entry, "GStreamer::IndexEntry");
  }
}
