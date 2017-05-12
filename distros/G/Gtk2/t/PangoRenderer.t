#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 7;

# $Id$

SKIP: {
  skip("PangoRenderer is new in 1.8", 5)
    unless (Gtk2::Pango -> CHECK_VERSION(1, 8, 0));

  my $screen = Gtk2::Gdk::Screen -> get_default();

  my $renderer = Gtk2::Gdk::PangoRenderer -> new($screen);
  isa_ok($renderer, "Gtk2::Pango::Renderer");

  my $window = Gtk2::Window -> new();
  $window -> realize();
  $renderer -> set_drawable($window -> window);

  my $gc = Gtk2::Gdk::GC -> new($window -> window);
  $renderer -> set_gc($gc);

  $renderer -> activate();

  my $layout = $window -> create_pango_layout("Bla");
  $renderer -> draw_layout($layout, 0, 0);
  $renderer -> draw_layout_line($layout -> get_line(0), 0, 0);

  $renderer -> draw_rectangle("foreground", 0, 0, 10, 10);
  $renderer -> draw_error_underline(0, 0, 10, 10);

  my $description = Gtk2::Pango::FontDescription -> new();
  $description -> set_family("Sans");
  $description -> set_size(23);

  my $context = $window -> create_pango_context();
  my $font = $context -> load_font($description);

  $renderer -> draw_glyph($font, 0, 0, 0);
  $renderer -> part_changed("foreground");

  $renderer -> set_color("foreground", undef);
  is($renderer -> get_color("foreground"), undef);

  $renderer -> set_color("background", [0xaaaa, 0xbbbb, 0xcccc]);
  is_deeply($renderer -> get_color("background"), [0xaaaa, 0xbbbb, 0xcccc]);

  $renderer -> set_matrix(undef);
  is($renderer -> get_matrix(), undef);

  my $matrix = Gtk2::Pango::Matrix -> new();
  $renderer -> set_matrix($matrix);
  isa_ok($renderer -> get_matrix(), "Gtk2::Pango::Matrix");

  $renderer -> deactivate();

  SKIP: {
    skip 'new 1.20 stuff', 2
      unless (Gtk2::Pango -> CHECK_VERSION(1, 20, 0));

    # These always return undef unless called from inside a subclass' drawing
    # function.  How do we test that?
    is($renderer -> get_layout(), undef);
    is($renderer -> get_layout_line(), undef);
  }
}

__END__

Copyright (C) 2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
