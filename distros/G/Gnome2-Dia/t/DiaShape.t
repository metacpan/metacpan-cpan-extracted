#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 16;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaShape.t,v 1.3 2004/11/10 18:41:44 kaffeetisch Exp $

###############################################################################

my $shape = Gnome2::Dia::Shape -> new(qw(path));
isa_ok($shape, "Gnome2::Dia::Shape");
isa_ok($shape, "Gnome2::Dia::Shape::Path");

$shape -> request_update();
$shape -> set_color(23);

###############################################################################

my $path = Gnome2::Dia::Shape::Path -> new();
isa_ok($path, "Gnome2::Dia::Shape");
isa_ok($path, "Gnome2::Dia::Shape::Path");

$path -> line([0, 0], [10, 10]);
$path -> rectangle([0, 0], [10, 10]);

$path -> polyline();
$path -> polyline([10, 10]);
$path -> polyline([1, 1], [2, 2], [3, 3]);

$path -> polygon();
$path -> polygon([10, 10]);
$path -> polygon([1, 1], [2, 2], [3, 3]);

$path -> set_fill_color(42);
$path -> set_line_width(13);
$path -> set_join("bevel");
$path -> set_cap("square");
$path -> set_fill("solid");
$path -> set_cyclic(1);
$path -> set_clipping(1);

$path -> set_dash(3);
$path -> set_dash(3, 0.1);
$path -> set_dash(3, 0.2, 0.3, 0.4);

ok($path -> is_clip_path());

###############################################################################

my $bezier = Gnome2::Dia::Shape::Bezier -> new();
isa_ok($bezier, "Gnome2::Dia::Shape");
isa_ok($bezier, "Gnome2::Dia::Shape::Bezier");

$bezier -> bezier([10, 10], [12, 12], [14, 14], [16, 16]);

$bezier -> set_fill_color(42);
$bezier -> set_line_width(13);
$bezier -> set_join("bevel");
$bezier -> set_cap("square");
$bezier -> set_fill("solid");
$bezier -> set_cyclic(1);
$bezier -> set_clipping(1);

$bezier -> set_dash(3);
$bezier -> set_dash(3, 0.1);
$bezier -> set_dash(3, 0.2, 0.3, 0.4);

ok($bezier -> is_clip_path());

###############################################################################

my $ellipse = Gnome2::Dia::Shape::Ellipse -> new();
isa_ok($ellipse, "Gnome2::Dia::Shape");
isa_ok($ellipse, "Gnome2::Dia::Shape::Ellipse");

$ellipse -> ellipse([10, 10], 5, 5);

$ellipse -> set_fill_color(42);
$ellipse -> set_line_width(13);
$ellipse -> set_fill("solid");
$ellipse -> set_clipping(1);

$ellipse -> set_dash(3);
$ellipse -> set_dash(3, 0.1);
$ellipse -> set_dash(3, 0.2, 0.3, 0.4);

ok($ellipse -> is_clip_path());

###############################################################################

my $text = Gnome2::Dia::Shape::Text -> new();
isa_ok($text, "Gnome2::Dia::Shape");
isa_ok($text, "Gnome2::Dia::Shape::Text");

my $desc = Gtk2::Pango::FontDescription -> new();

$text -> text($desc, "Urgs");

$text -> set_font_description($desc);
$text -> set_text("Urgs");
$text -> set_affine([1, 0, 0, 1, 0, 0]);
$text -> set_pos([12, 13]);
$text -> set_text_width(23);
$text -> set_line_spacing(2);
$text -> set_max_width(23);
$text -> set_max_height(23);
$text -> set_justify(1);
$text -> set_markup(1);
$text -> set_wrap_mode("word");
$text -> set_alignment("right");

my $layout = $text -> to_pango_layout(1);
isa_ok($layout, "Gtk2::Pango::Layout");

$text -> fill_pango_layout($layout);

###############################################################################

my $image = Gnome2::Dia::Shape::Image -> new();
isa_ok($image, "Gnome2::Dia::Shape");
isa_ok($image, "Gnome2::Dia::Shape::Image");

my $pixbuf = Gtk2::Gdk::Pixbuf -> new("rgb", 1, 8, 10, 10);

$image -> image($pixbuf);

$image -> set_affine([1, 0, 0, 1, 0, 0]);
$image -> set_pos([0, 0]);
