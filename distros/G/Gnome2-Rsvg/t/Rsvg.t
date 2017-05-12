#!/usr/bin/perl -w
use strict;
use Cwd qw(cwd);
use Test::More;
use Gnome2::Rsvg;

sub read_file {
  open(SVG, '<', $_[0]) or return ();
  my @data = <SVG>;
  close(SVG);
  return @data;
}

my $svg = "t/window.svg";
my @svg_data = read_file($svg);

plan @svg_data
  ? (tests => @svg_data + 40)
  : (skip_all => "Could not read test image $svg");

###############################################################################

my $number = qr/^\d+$/;

my $been_here = 0;
my $size_callback = sub {
  my ($width, $height) = @_;

  unless ($been_here++) {
    like($width, $number);
    like($height, $number);
  }

  return ($width * 2,
          $height * 2);
};

my $handle = Gnome2::Rsvg::Handle -> new();
isa_ok($handle, "Gnome2::Rsvg::Handle");

$handle -> set_size_callback($size_callback);
foreach (@svg_data) {
  ok($handle -> write($_));
}

ok($handle -> close());

my $pixbuf = $handle -> get_pixbuf();
isa_ok($pixbuf, "Gtk2::Gdk::Pixbuf");

like($pixbuf -> get_width(), $number);
like($pixbuf -> get_height(), $number);

###############################################################################

my $uri = cwd() . "/" . $svg;

# Bug in librsvg: no relative paths?

foreach (Gnome2::Rsvg -> pixbuf_from_file($uri),
         Gnome2::Rsvg -> pixbuf_from_file_at_zoom($uri, 1.5, 1.5),
         Gnome2::Rsvg -> pixbuf_from_file_at_size($uri, 23, 42),
         Gnome2::Rsvg -> pixbuf_from_file_at_max_size($uri, 23, 42),
         Gnome2::Rsvg -> pixbuf_from_file_at_zoom_with_max($uri, 1.5, 1.5, 23, 42)) {
  isa_ok($_, "Gtk2::Gdk::Pixbuf");
}

###############################################################################

SKIP: {
  skip("get_title and get_desc are new in 2.4", 2)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 4, 0));

  is($handle -> get_title(), "Urgs");
  is($handle -> get_desc(), "Urgs");
}

SKIP: {
  skip("set_default_dpi and set_dpi are new in 2.8", 0)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 8, 0));

  Gnome2::Rsvg -> set_default_dpi(96);
  Gnome2::Rsvg -> set_default_dpi_x_y(96, 96);
  $handle -> set_dpi(96);
  $handle -> set_dpi_x_y(96, 96);
}

SKIP: {
  skip("[sg]et_base_uri and get_metadata are new in 2.10", 2)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 10, 0));

  $handle -> set_base_uri("file:///tmp/window.svg");
  is($handle -> get_base_uri(), "file:///tmp/window.svg");

  is($handle -> get_metadata(), "Urgs");
}

SKIP: {
  skip('2.14 stuff', 11)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 14, 0));

  is (eval { Gnome2::Rsvg::Handle -> new_from_data('<>'); }, undef);
  isa_ok (Gnome2::Rsvg::Handle -> new_from_data('<svg></svg>'),
          'Gnome2::Rsvg::Handle');

  is (eval { Gnome2::Rsvg::Handle -> new_from_file($0); }, undef);
  my $handle = Gnome2::Rsvg::Handle -> new_from_file($uri);
  isa_ok ($handle, 'Gnome2::Rsvg::Handle');

  my $surface = Cairo::ImageSurface -> create("argb32", 10, 10);
  my $cr = Cairo::Context -> create($surface);

  $handle -> render_cairo($cr);
  $handle -> render_cairo_sub($cr, '#defs22');
  $handle -> render_cairo_sub($cr, undef);

  isa_ok ($handle -> get_pixbuf_sub('#path9'), 'Gtk2::Gdk::Pixbuf');
  isa_ok ($handle -> get_pixbuf_sub(undef), 'Gtk2::Gdk::Pixbuf');

  dimensions_ok($handle -> get_dimensions());
}

SKIP: {
  skip('2.22 stuff', 13)
    unless (Gnome2::Rsvg -> CHECK_VERSION(2, 22, 0));

  my $handle = Gnome2::Rsvg::Handle -> new_from_file($svg);
  isa_ok ($handle, 'Gnome2::Rsvg::Handle');

  my $surface = Cairo::ImageSurface -> create('argb32', 10, 10);
  my $cr = Cairo::Context -> create($surface);

  ok($handle -> render_cairo($cr));
  ok($handle -> render_cairo_sub($cr, "#defs22"));
  ok($handle -> render_cairo_sub($cr, undef));

  ok($handle -> has_sub('#path9'));
  dimensions_ok($handle -> get_dimensions_sub('#path9'));
  position_ok($handle -> get_position_sub('#path9'));
}

###############################################################################

sub dimensions_ok {
  my ($d) = @_;
  isa_ok($d, 'HASH');
  ok(exists $d->{width});
  ok(exists $d->{height});
  ok(exists $d->{em});
  ok(exists $d->{ex});
}

sub position_ok {
  my ($p) = @_;
  isa_ok ($p, 'HASH');
  ok(exists $p->{x});
  ok(exists $p->{y});
}
