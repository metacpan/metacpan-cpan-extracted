#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 15;

# $Id$

my $label = Gtk2::Label -> new("Bla");

my $context = $label -> create_pango_context();
isa_ok($context, "Gtk2::Pango::Context");

my @families = $context->list_families;
ok (@families > 0, 'got a list of somethings');
isa_ok ($families[0], 'Gtk2::Pango::FontFamily');

my $font = Gtk2::Pango::FontDescription -> from_string("Sans 12");
my $language = Gtk2 -> get_default_language();

$context -> set_font_description($font);
isa_ok($context -> get_font_description(), "Gtk2::Pango::FontDescription");

$context -> set_language($language);
isa_ok($context -> get_language(), "Gtk2::Pango::Language");

$context -> set_base_dir("ltr");
is($context -> get_base_dir(), "ltr");

isa_ok($context -> load_font($font), "Gtk2::Pango::Font");
isa_ok($context -> load_fontset($font, $language), "Gtk2::Pango::Fontset");
isa_ok($context -> get_metrics($font, $language), "Gtk2::Pango::FontMetrics");

SKIP: {
  skip("[sg]et_matrix are new in 1.6", 2)
    unless (Gtk2::Pango -> CHECK_VERSION(1, 6, 0));

  $context -> set_matrix(Gtk2::Pango::Matrix -> new());
  isa_ok($context -> get_matrix(), "Gtk2::Pango::Matrix");

  $context -> set_matrix(undef);
  is($context -> get_matrix(), undef);
}

SKIP: {
  skip("get_font_map is new in 1.6", 1)
    unless (Gtk2::Pango -> CHECK_VERSION(1, 6, 0));

  isa_ok($context -> get_font_map(), "Gtk2::Pango::FontMap");
}

SKIP: {
  skip("new 1.16 stuff", 3)
    unless (Gtk2::Pango -> CHECK_VERSION(1, 16, 0));

  ok(defined $context -> get_gravity());

  $context -> set_base_gravity("north");
  is($context -> get_base_gravity(), "north");

  $context -> set_gravity_hint("natural");
  is($context -> get_gravity_hint(), "natural");
}

__END__

Copyright (C) 2003-2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
