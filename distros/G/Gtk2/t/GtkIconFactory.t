#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 24;

# $Id$

my $pixbuf = Gtk2::Gdk::Pixbuf -> new("rgb", 0, 8, 10, 10);
my $style = Gtk2::Style -> new();
my $button = Gtk2::Button -> new("Bla");
# my $settings = Gtk2::Settings -> get_default();

###############################################################################

my ($width, $height) = Gtk2::IconSize -> lookup("button");

like($width, qr/^\d+$/);
like($height, qr/^\d+$/);

SKIP: {
  skip "lookup_for_settings is new in 2.2.0", 2
    unless Gtk2->CHECK_VERSION (2, 2, 0);
  my $settings = $button -> get_settings();
  ($width, $height) = Gtk2::IconSize -> lookup_for_settings($settings, "button");

  like($width, qr/^\d+$/);
  like($height, qr/^\d+$/);
}

is(Gtk2::IconSize -> register("answer", 23, 42), "answer");

Gtk2::IconSize -> register_alias("everything", "answer");
is(Gtk2::IconSize -> from_name("everything"), "answer");

###############################################################################

my $source = Gtk2::IconSource -> new();
isa_ok($source, "Gtk2::IconSource");

SKIP: {
  skip("[sg]et_icon_name are new in 2.4", 1)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  $source -> set_icon_name("gtk-save");
  is($source -> get_icon_name(), "gtk-save");
}

$source = Gtk2::IconSource -> new();
isa_ok($source, "Gtk2::IconSource");

$source -> set_direction("ltr");
is($source -> get_direction(), "ltr");

$source -> set_direction_wildcarded(1);
is($source -> get_direction_wildcarded(), 1);

$source -> set_filename("/tmp/bla");
is($source -> get_filename(), "/tmp/bla");

$source -> set_pixbuf($pixbuf);
is($source -> get_pixbuf(), $pixbuf);

$source -> set_size("button");
is($source -> get_size(), "button");

$source -> set_size_wildcarded(1);
is($source -> get_size_wildcarded(), 1);

$source -> set_state("prelight");
is($source -> get_state(), "prelight");

$source -> set_state_wildcarded(1);
is($source -> get_state_wildcarded(), 1);

###############################################################################

my $set = Gtk2::IconSet -> new();
isa_ok($set, "Gtk2::IconSet");

$set = Gtk2::IconSet -> new_from_pixbuf($pixbuf);
isa_ok($set, "Gtk2::IconSet");

$set -> add_source($source);

isa_ok($set -> render_icon($style, "rtl", "prelight", "button", $button),
       "Gtk2::Gdk::Pixbuf");

my %sizes = map { $_ => 1 } $set -> get_sizes();
is($sizes{ answer }, 1);

###############################################################################

my $factory = Gtk2::IconFactory -> new();
isa_ok($factory, "Gtk2::IconFactory");

$factory -> add("kaffee-splatter", $set);

isa_ok($factory -> lookup("kaffee-splatter"), "Gtk2::IconSet");
isa_ok($factory -> lookup_default("gtk-find-and-replace"), "Gtk2::IconSet");

$factory -> add_default();
$factory -> remove_default();

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
