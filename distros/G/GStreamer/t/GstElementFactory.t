#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 12;

# $Id$

use Glib qw(TRUE FALSE);
use GStreamer -init;

my $factory = GStreamer::ElementFactory -> find("__nada__");
is($factory, undef);

$factory = GStreamer::ElementFactory -> find("queue");
isa_ok($factory, "GStreamer::ElementFactory");

# Can't reliably test this.
my $type = $factory -> get_element_type();

ok(defined $factory -> get_longname());
ok(defined $factory -> get_klass());
ok(defined $factory -> get_description());
ok(defined $factory -> get_author());

is($factory -> get_uri_type(), "unknown");
is($factory -> get_uri_protocols(), ());

isa_ok($factory -> create("urgs"), "GStreamer::Element");
isa_ok(GStreamer::ElementFactory -> make(queue => "urgs"), "GStreamer::Element");

my $caps = GStreamer::Caps::Any -> new();
ok($factory -> can_src_caps($caps));
ok($factory -> can_sink_caps($caps));
