#!/usr/bin/perl -w
use strict;
use Glib qw/TRUE FALSE/;
use Gtk2;
use Test::More;

if (UNIVERSAL::can("Gtk2::Pango::Cairo::FontMap", "new") &&
    Gtk2::Pango -> CHECK_VERSION(1, 10, 0)) {
  plan tests => 22;
} else {
  plan skip_all => "PangoCairo stuff: need Cairo and pango >= 1.10.0";
}

# $Id$

my $fontmap = Gtk2::Pango::Cairo::FontMap -> new();
isa_ok($fontmap, "Gtk2::Pango::Cairo::FontMap");
isa_ok($fontmap, "Gtk2::Pango::FontMap");

SKIP: {
  skip 'new 1.18 stuff', 3
    unless Gtk2::Pango -> CHECK_VERSION(1, 18, 0);

  $fontmap = Gtk2::Pango::Cairo::FontMap -> new_for_font_type('ft');
  
  skip 'new_for_font_type returned undef', 3
    unless defined $fontmap;

  isa_ok($fontmap, "Gtk2::Pango::Cairo::FontMap");
  isa_ok($fontmap, "Gtk2::Pango::FontMap");
  is($fontmap -> get_font_type(), 'ft');
}

$fontmap = Gtk2::Pango::Cairo::FontMap -> get_default();
isa_ok($fontmap, "Gtk2::Pango::Cairo::FontMap");
isa_ok($fontmap, "Gtk2::Pango::FontMap");

$fontmap -> set_resolution(72);
is($fontmap -> get_resolution(), 72);

my $context = $fontmap -> create_context();
isa_ok($context, "Gtk2::Pango::Context");

# Just to make sure this is a valid Gtk2::Pango::FontMap
isa_ok(($fontmap -> list_families())[0], "Gtk2::Pango::FontFamily");

my $target = Cairo::ImageSurface -> create("argb32", 100, 100);
my $cr = Cairo::Context -> create($target);

Gtk2::Pango::Cairo::update_context($cr, $context);

my $options = Cairo::FontOptions -> create();

# Function interface
{
  Gtk2::Pango::Cairo::Context::set_font_options($context, $options);
  isa_ok(Gtk2::Pango::Cairo::Context::get_font_options($context),
         "Cairo::FontOptions");

  Gtk2::Pango::Cairo::Context::set_resolution($context, 72);
  is(Gtk2::Pango::Cairo::Context::get_resolution($context), 72);
}

# Method interface
{
  isa_ok($context, "Gtk2::Pango::Cairo::Context");

  $context -> set_font_options($options);
  isa_ok($context -> get_font_options(), "Cairo::FontOptions");

  $context -> set_resolution(72);
  is($context -> get_resolution(), 72);
}

my $layout = Gtk2::Pango::Cairo::create_layout($cr);
isa_ok($layout, "Gtk2::Pango::Layout");

my $line = $layout -> get_line(0);

Gtk2::Pango::Cairo::show_layout_line($cr, $line);
Gtk2::Pango::Cairo::show_layout($cr, $layout);
Gtk2::Pango::Cairo::layout_line_path($cr, $line);
Gtk2::Pango::Cairo::layout_path($cr, $layout);

Gtk2::Pango::Cairo::update_layout($cr, $layout);

# FIXME: pango_cairo_show_glyph_string, pango_cairo_glyph_string_path.

SKIP: {
  skip "error line stuff", 0
    unless Gtk2::Pango -> CHECK_VERSION(1, 14, 0);

  Gtk2::Pango::Cairo::show_error_underline($cr, 23, 42, 5, 5);
  Gtk2::Pango::Cairo::error_underline_path($cr, 23, 42, 5, 5);
}

SKIP: {
  skip 'new 1.18 stuff', 6
    unless Gtk2::Pango -> CHECK_VERSION(1, 18, 0);

  $context -> set_shape_renderer(undef, undef);

  my $target = Cairo::ImageSurface -> create('argb32', 100, 100);
  my $cr = Cairo::Context -> create($target);

  my $layout = Gtk2::Pango::Cairo::create_layout($cr);
  Gtk2::Pango::Cairo::Context::set_shape_renderer(
    $layout -> get_context(),
    sub {
      my ($cr, $shape, $do_path, $data) = @_;

      isa_ok($cr, 'Cairo::Context');
      isa_ok($shape, 'Gtk2::Pango::AttrShape');
      ok(defined $do_path);
      is($data, 'bla');
    },
    'bla');
  $layout -> set_text('Bla');

  my $ink     = { x => 23, y => 42, width => 10, height => 15 };
  my $logical = { x => 42, y => 23, width => 15, height => 10 };
  my $attr = Gtk2::Pango::AttrShape -> new($ink, $logical, 0, 1);
  my $list = Gtk2::Pango::AttrList -> new();
  $list -> insert($attr);
  $layout -> set_attributes($list);

  Gtk2::Pango::Cairo::show_layout($cr, $layout);

  my $desc = Gtk2::Pango::FontDescription -> from_string('Sans 10');
  my $font = $fontmap -> load_font($context, $desc);
  skip 'could not find font', 2
    unless defined $font;
  isa_ok($font, 'Gtk2::Pango::Cairo::Font');
  isa_ok($font -> get_scaled_font(), 'Cairo::ScaledFont');
}

__END__

Copyright (C) 2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
