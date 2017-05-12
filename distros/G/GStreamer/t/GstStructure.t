#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;

# $Id$

use Glib qw(TRUE FALSE);
use GStreamer -init;

my $structure_one = {
  name => "urgs",
  fields => [
    [field_one => "Glib::String" => "urgs"],
    [field_two => "Glib::Int" => 23]
  ]
};

my $structure_two = {
  name => "sgru",
  fields => [
    [field_one => "Glib::String" => "sgru"],
    [field_two => "Glib::Int" => 42]
  ]
};

my $caps = GStreamer::Caps::Full -> new($structure_one);
isa_ok($caps, "GStreamer::Caps");

$caps -> append_structure($structure_two);
is($caps -> get_size(), 2);

is_deeply($caps -> get_structure(0), $structure_one);
is_deeply($caps -> get_structure(1), $structure_two);

my $string_one = GStreamer::Structure::to_string($structure_one);
my $string_two = GStreamer::Structure::to_string($structure_two);

# remove trailing semicolon that start to appear sometime in the past
$string_one =~ s/;\Z//;
$string_two =~ s/;\Z//;

is($string_one, "urgs, field_one=(string)urgs, field_two=(int)23");
is($string_two, "sgru, field_one=(string)sgru, field_two=(int)42");

is_deeply(GStreamer::Structure::from_string($string_one), $structure_one);
is_deeply(GStreamer::Structure::from_string($string_two), $structure_two);

is_deeply((GStreamer::Structure::from_string($string_one))[0], $structure_one);
