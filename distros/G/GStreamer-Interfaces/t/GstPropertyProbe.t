#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

use Glib qw(TRUE FALSE);
use GStreamer -init;
use GStreamer::Interfaces;

my $plugin = "alsamixer";
my $property = "device";

my $element = GStreamer::ElementFactory -> make($plugin => "element");
SKIP: {
  skip 'could not find the alsamixer plugin', 5
    unless defined $element;
  isa_ok($element, "GStreamer::PropertyProbe");

  my @pspecs = $element -> get_probe_properties();
  skip 'got no probe properties', 4
    unless @pspecs;
  isa_ok($pspecs[0], "Glib::ParamSpec");

  my $pspec = $element -> get_probe_property($property);
  skip 'did not get desired property', 3
    unless defined $pspec;
  isa_ok($pspec, "Glib::ParamSpec");

  ok(defined $element -> needs_probe($pspec));
  $element -> probe_property($pspec);

  my @values;
  # these might return an empty list, apparently
  @values = $element -> get_probe_values($pspec);
  @values = $element -> probe_and_get_probe_values($pspec);

  ok(defined $element -> needs_probe_name($property));
  $element -> probe_property_name($property);

  # these might return an empty list too, apparently
  @values = $element -> get_probe_values_name($property);
  @values = $element -> probe_and_get_probe_values_name($property);
}
