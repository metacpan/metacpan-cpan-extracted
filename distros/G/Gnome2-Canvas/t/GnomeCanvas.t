#!/usr/bin/perl -w
use strict;
use Test::More;
use Gnome2::Canvas;

if (Gtk2->init_check) {
	plan tests => 25;
} else {
	plan skip_all => 'unable to open display, nothing to test';
}

my $canvas = Gnome2::Canvas -> new();
isa_ok($canvas, "Gnome2::Canvas");

$canvas = Gnome2::Canvas -> new_aa();
isa_ok($canvas, "Gnome2::Canvas");

$canvas -> update_now();

isa_ok($canvas -> root(), "Gnome2::Canvas::Group");

$canvas -> set_scroll_region(23, 42, 23, 42);
is_deeply([$canvas -> get_scroll_region()], [23, 42, 23, 42]);

$canvas -> set_center_scroll_region(1);
ok($canvas -> get_center_scroll_region());

$canvas -> set_pixels_per_unit(96);
$canvas -> scroll_to(10, 10);

is_deeply([$canvas -> get_scroll_offsets()], [0, 0]);

# $canvas -> get_item_at(..., ...);
# $canvas -> request_redraw_uta(...);

$canvas -> request_redraw(10, 10, 12, 12);

# w2c_affine was misbound before 1.002; make sure we still allow
# code that uses the broken signature.
warn "\n# ignore the warning about w2c_affine here:\n";
$canvas -> w2c_affine([10, 10, 12, 12, 23, 23]);

# and test the proper signature.
my $affine = $canvas->w2c_affine;
isa_ok ($affine, 'ARRAY');
is (scalar(@$affine), 6);
print "w2c_affine @$affine\n";


is_deeply([$canvas -> w2c(23, 43)], [0, 96]);
is_deeply([$canvas -> w2c_d(23, 43)], [0, 96]);
is_deeply([$canvas -> c2w(0, 96)], [23, 43]);
is_deeply([$canvas -> window_to_world(0, 0)], [23, 42]);
is_deeply([$canvas -> world_to_window(23, 42)], [0, 0]);

my ($result, $color) = $canvas -> get_color("red");
is($result, 1);
isa_ok($color, "Gtk2::Gdk::Color");

# is($canvas -> get_color_pixel(0xFF00FFFF), 63519);

my $window = Gtk2::Window -> new("toplevel");
$window -> realize();

$canvas -> set_stipple_origin(Gtk2::Gdk::GC -> new($window -> window()));

$canvas -> set_dither("max");
is($canvas -> get_dither(), "max");

foreach (Gnome2::Canvas -> get_miter_points(1, 2, 3, 4, 5, 6, 100),
         Gnome2::Canvas -> get_butt_points(1, 2, 3, 4, 100, 200)) {
  like(int(abs($_)), qr/^\d+$/);
}

is(Gnome2::Canvas -> polygon_to_point([10, 10, 20, 20], 23, 24), 5);
