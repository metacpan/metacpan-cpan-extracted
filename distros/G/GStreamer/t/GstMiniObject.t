#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

# $Id$

use GStreamer -init;

my $object = GStreamer::Buffer -> new();
isa_ok($object, "GStreamer::MiniObject");

ok($object -> is_writable());
isa_ok($object -> make_writable(), "GStreamer::MiniObject");
