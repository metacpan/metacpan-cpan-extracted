#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 4;

# $Id$

my $label = Gtk2::Label -> new("Bla");

my $context = $label -> create_pango_context();
isa_ok($context, "Gtk2::Pango::Context");

SKIP: {
  skip("get_font_map is new in 1.6", 3)
    unless (Gtk2::Pango -> CHECK_VERSION(1, 6, 0));

  my $map = $context -> get_font_map();
  my $desc = Gtk2::Pango::FontDescription -> from_string("Sans 12");
  my $lang = Gtk2::Pango::Language -> from_string("de_DE");

  isa_ok($map -> load_font($context, $desc), "Gtk2::Pango::Font");
  isa_ok($map -> load_fontset($context, $desc, $lang), "Gtk2::Pango::Fontset");
  isa_ok(($map -> list_families())[0], "Gtk2::Pango::FontFamily");
}

__END__

Copyright (C) 2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
