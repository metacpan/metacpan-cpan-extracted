#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;

# $Id$

use GStreamer -init;

my $object = GStreamer::ElementFactory -> make("queue", "source");
isa_ok($object, "GStreamer::Object");

$object -> set_name("urgs");
is($object -> get_name(), "urgs");

$object -> set_name_prefix("urgs");
is($object -> get_name_prefix(), "urgs");

my $parent = GStreamer::ElementFactory -> make("queue", "source");

$object -> set_parent($parent);
is($object -> get_parent(), $parent);

ok($object -> has_ancestor($parent));

ok(defined($object -> get_path_string()));

$object -> unparent();
