#!/usr/bin/perl -w
use strict;
use Test::More;
use Gnome2::Canvas;

if (Gtk2->init_check) {
	plan tests => 19;
} else {
	plan skip_all => 'unable to open display, nothing to test';
}

my $window = Gtk2::Window -> new("toplevel");
my $canvas = Gnome2::Canvas -> new();
my $group = $canvas -> root();

$window -> add($canvas);
$window -> realize();
$window -> show_all();

my $item = Gnome2::Canvas::Item -> new($group, "Gnome2::Canvas::Rect",
                                       fill_color => "black");
isa_ok($item, "Gnome2::Canvas::Item");

$item -> set(width_units => 6);
$item -> move(10, 10);
$item -> affine_relative([23, 23, 42, 42, 0, 0]);
$item -> affine_absolute([23, 23, 42, 42, 0, 0]);
$item -> raise(3);
$item -> lower(2);
$item -> raise_to_top();
$item -> lower_to_bottom();
$item -> show();
$item -> request_update();

# is($item -> grab(qw(button-release-mask), Gtk2::Gdk::Cursor -> new("arrow")), "success");
# $item -> ungrab();

# warn $item -> w2i(0, 0);
# warn $item -> i2w(23, 42);

# this is broken, and will generate warnings
warn "\n# ignore the next two warnings\n";
$item -> i2w_affine([23, 23, 42, 42, 0, 0]);
$item -> i2c_affine([23, 23, 42, 42, 0, 0]);

# these signatures requires 1.002.
my $affine;
$affine = $item -> i2w_affine;
isa_ok ($affine, 'ARRAY');
is (scalar(@$affine), 6);
print "i2w_affine @$affine\n";
$affine = $item -> i2c_affine;
isa_ok ($affine, 'ARRAY');
is (scalar(@$affine), 6);
print "i2c_affine @$affine\n";


$item -> reparent($group);
$item -> grab_focus();

# versions of libgnomecanvas prior to 2.1.0 did not properly check the
# validity of paths when getting bounds on shape items.
# so, it is normal to get a GnomeCanvas-CRITICAL assertion from this line
# on Gnome 2.0 systems.
is_deeply([$item -> get_bounds()], [0, 0, 0, 0]);

$item -> hide();

$item -> reset_bounds();
$item -> update_bbox(10, 10, 23, 23);

###############################################################################

$item = Gnome2::Canvas::Item -> new($group, "Gnome2::Canvas::RichText");
my $buffer = $item -> get_buffer();

isa_ok($buffer, "Gtk2::TextBuffer");

$item -> set_buffer($buffer);
is($item -> get_buffer(), $buffer);

my $iter = $item -> get_iter_at_location(0, 0);
is($item -> get_iter_location($iter) -> x(), 0);

###############################################################################

$item = Gnome2::Canvas::Item -> new($group, "Gnome2::Canvas::Bpath");
my $path_def = Gnome2::Canvas::PathDef -> new();

$item -> set_path_def($path_def);
# is($item -> get_path_def(), $path_def);
isa_ok($item -> get_path_def(), "Gnome2::Canvas::PathDef");

###############################################################################

$item = Gnome2::Canvas::Item -> new($group, "Gnome2::Canvas::Shape");
$path_def = Gnome2::Canvas::PathDef -> new();

$item -> set_path_def($path_def);
# is($item -> get_path_def(), $path_def);
isa_ok($item -> get_path_def(), "Gnome2::Canvas::PathDef");

###############################################################################

$item = Gnome2::Canvas::Item -> new($group, "Gnome2::Canvas::Line");
$item -> set(points => [10 => 11, 12 => 13, 14 => 15]);
is_deeply($item -> get("points"), [10, 11, 12, 13, 14, 15]);

###############################################################################

# Gnome2::Canvas::Clipgroup?
foreach (qw(Ellipse Group Pixbuf Polygon RE Text Widget)) {
  isa_ok(Gnome2::Canvas::Item -> new($group, "Gnome2::Canvas::$_"),
         "Gnome2::Canvas::Item");
}
