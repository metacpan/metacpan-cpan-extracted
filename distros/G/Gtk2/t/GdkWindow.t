#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 60;

# $Id$

my $attributes = {
  title => "Bla",
  event_mask => "button-press-mask",
  x => 10,
  "y" => 10,
  width => 20,
  height => 20,
  wclass => "output",
  (Gtk2->CHECK_VERSION (2,2,0)
   ? (visual => Gtk2::Gdk::Screen -> get_default() -> get_system_visual())
   : ()),
  colormap => Gtk2::Gdk::Colormap -> get_system(),
  window_type => "toplevel",
  cursor => Gtk2::Gdk::Cursor -> new("arrow"),
  override_redirect => ''
};

my $attributes_small = {
  width => 20,
  height => 20,
  wclass => "output",
  window_type => "toplevel"
};

my $window = Gtk2::Gdk::Window -> new(undef, $attributes);
my $window_two = Gtk2::Gdk::Window -> new(undef, $attributes_small);
my $window_three = Gtk2::Gdk::Window -> new(Gtk2::Gdk -> get_default_root_window(), $attributes);

isa_ok($window, "Gtk2::Gdk::Window");
isa_ok($window_two, "Gtk2::Gdk::Window");
isa_ok($window_three, "Gtk2::Gdk::Window");

is($window -> get_window_type(), "toplevel");

$window -> show_unraised();
$window -> show();

ok($window -> is_visible());
ok($window -> is_viewable());

$window -> withdraw();
$window -> iconify();
$window -> deiconify();
$window -> stick();
$window -> unstick();
$window -> maximize();
$window -> unmaximize();

SKIP: {
  skip("(un)fullscreen are new in 2.2.0", 0)
    unless Gtk2->CHECK_VERSION (2, 2, 0);

  $window -> fullscreen();
  $window -> unfullscreen();
}

ok(defined $window -> get_state());

my @position = $window -> get_position();
is(scalar @position, 2);

$window -> move(20, 20);
$window -> resize(40, 40);
$window -> move_resize(20, 20, 40, 40);
$window -> scroll(5, 5);

$window -> reparent($window_three, 0, 0);

$window -> clear();
$window -> clear_area(0, 0, 5, 5);
$window -> clear_area_e(0, 0, 5, 5);

$window -> raise();
$window -> lower();
$window -> focus(time());
$window -> register_dnd();

# See t/GtkWindow.t for why these are disabled.
# $window -> begin_resize_drag("south-east", 1, 20, 20, 0);
# $window -> begin_move_drag(1, 20, 20, 0);

# FIXME: separate .t for the GdkTypes.xs stuff?

my $geometry = Gtk2::Gdk::Geometry -> new();
isa_ok($geometry, "Gtk2::Gdk::Geometry");

$geometry -> min_width(10);
$geometry -> max_width(100);
$geometry -> min_height(10);
$geometry -> max_height(100);
$geometry -> base_width(5);
$geometry -> base_height(5);
$geometry -> width_inc(5);
$geometry -> height_inc(5);
$geometry -> min_aspect(0.5);
$geometry -> max_aspect(0.5);
$geometry -> gravity("south-west");
$geometry -> win_gravity("north-east");

is_deeply([$geometry -> min_width(),
           $geometry -> max_width(),
           $geometry -> min_height(),
           $geometry -> max_height(),
           $geometry -> base_width(),
           $geometry -> base_height(),
           $geometry -> width_inc(),
           $geometry -> height_inc(),
           $geometry -> min_aspect(),
           $geometry -> max_aspect(),
           $geometry -> gravity(),
           $geometry -> win_gravity()], [10, 100, 10, 100, 5, 5, 5, 5, 0.5, 0.5, "north-east", "north-east"]);

my $geometry_two = {
  min_width => 10,
  max_width => 100,
  min_height => 10,
  max_height => 100,
  base_width => 5,
  base_height => 5,
  width_inc => 5,
  height_inc => 5,
  min_aspect => 0.5,
  max_aspect => 0.5,
  win_gravity => "north-west"
};

my $mask = [qw(min-size
               max-size
               base-size
               aspect
               resize-inc
               win-gravity)];

my ($w, $h) = $geometry -> constrain_size($mask, 22, 23);
like ($w , qr/^\d+$/);
like ($h , qr/^\d+$/);
($w, $h) = $geometry -> constrain_size(22, 23);
like ($w , qr/^\d+$/);
like ($h , qr/^\d+$/);

my $rectangle = Gtk2::Gdk::Rectangle -> new(10, 10, 20, 20);
isa_ok($rectangle, "Gtk2::Gdk::Rectangle");
is($rectangle -> x(), 10);
is($rectangle -> y(), 10);
is($rectangle -> width(), 20);
is($rectangle -> height(), 20);
is_deeply([$rectangle -> values()], [10, 10, 20, 20]);

my $region = Gtk2::Gdk::Region -> rectangle($rectangle);

$window_two -> begin_paint_rect($rectangle);
$window_two -> begin_paint_region($region);
$window_two -> end_paint();

$window_two -> invalidate_rect($rectangle, 1);
$window_two -> invalidate_rect(undef, 1);
$window_two -> invalidate_region($region, 1);

# FIXME: never called?
$window_three -> invalidate_maybe_recurse($region, sub { warn @_; return 0; }, "bla");

$window -> freeze_updates();
$window -> thaw_updates();

# FIXME: when does it return something defined?
is($window_two -> get_update_area(), undef);

$window -> process_all_updates();
$window -> process_updates(0);
$window -> set_debug_updates(0);

my ($drawable, $x_offset, $y_offset) = $window -> get_internal_paint_info();
isa_ok($drawable, "Gtk2::Gdk::Drawable");
is($x_offset, 0);
is($y_offset, 0);

$window -> set_override_redirect(0);

# FIXME
# $window -> add_filter(...);
# $window -> remove_filter(...);

my $bitmap = Gtk2::Gdk::Bitmap->create_from_data ($window, "", 1, 1);

$window -> shape_combine_mask($bitmap, 5, 5);
$window -> shape_combine_region($region, 1, 1);

# test with undef
$window -> shape_combine_mask(undef, 0, 0);
$window -> shape_combine_region(undef, 0, 0);

SKIP: {
  skip 'child shapes functions trigger a bug', 0
    if (Gtk2->CHECK_VERSION (2, 24, 26) && !Gtk2->CHECK_VERSION (2, 24, 29));

  # Introduced in
  # <https://git.gnome.org/browse/gtk+/commit/?h=gtk-2-24&id=aff976ef0dad471edc35d65b9d1b5ba97da1698e>,
  # fixed in
  # <https://git.gnome.org/browse/gtk+/commit/?h=gtk-2-24&id=7ee8b1fd9af52842e87c26465b9aa8921e62ec90>.

  $window -> set_child_shapes();
  $window -> merge_child_shapes();
}

$window -> set_static_gravities(0); # FIXME: check retval?
$window -> set_title("Blub");
$window -> set_background(Gtk2::Gdk::Color -> new(255, 255, 255));

my $pixmap = Gtk2::Gdk::Pixmap->new ($window, 1, 1, $window->get_depth);

$window -> set_back_pixmap($pixmap, 0);

$window -> set_cursor(Gtk2::Gdk::Cursor -> new("arrow"));

Gtk2 -> main_iteration() while (Gtk2 -> events_pending());
# can't predict what these will be
my @ret = $window -> get_geometry();
is (scalar (@ret), 5, 'get_geomerty');

$window -> set_geometry_hints($geometry, $mask);
$window -> set_geometry_hints($geometry_two);

$window -> set_icon_list();
$window -> set_icon_list(Gtk2::Gdk::Pixbuf -> new("rgb", 0, 8, 10, 10),
                         Gtk2::Gdk::Pixbuf -> new("rgb", 0, 8, 10, 10));

$window -> set_modal_hint(0);
$window -> set_type_hint("normal");

SKIP: {
  skip "new 2.10 stuff", 1
    unless Gtk2 -> CHECK_VERSION(2, 10, 0);

  ok(defined $window -> get_type_hint());

  $window -> set_child_input_shapes();
  $window -> merge_child_input_shapes();
  $window -> input_shape_combine_mask($bitmap, 23, 42);
  $window -> input_shape_combine_region($region, 23, 42);

  # test with undef
  $window -> input_shape_combine_mask(undef, 0,0);
  $window -> input_shape_combine_region(undef, 0,0);

}

SKIP: {
  skip("set_skip_taskbar_hint and set_skip_pager_hint are new in 2.2.0", 0)
    unless Gtk2->CHECK_VERSION (2, 2, 0);

  $window_three -> set_skip_taskbar_hint(0);
  $window_three -> set_skip_pager_hint(0);
}

# there's no way to predict this
@ret = $window -> get_root_origin();
is (scalar (@ret), 2, 'get_root_origin');

@ret = $window -> get_origin();
is (scalar (@ret), 2, 'get_origin');

isa_ok($window -> get_frame_extents(), "Gtk2::Gdk::Rectangle");

my ($pointer_window, $relative_x, $relative_y, $pointer_mask) = $window -> get_pointer();
# $pointer_window
like($relative_x, qr/^-?\d+$/);
like($relative_y, qr/^-?\d+$/);
isa_ok($pointer_mask, "Gtk2::Gdk::ModifierType");

is($window -> get_parent(), $window_three);
isa_ok($window -> get_toplevel(), "Gtk2::Gdk::Window");
# is($window -> get_toplevel(), $window_three);

is($window_three -> get_children(), $window);
is($window_three -> peek_children(), $window);

$window -> set_events("button-press-mask");
isa_ok($window -> get_events(), "Gtk2::Gdk::EventMask");

$window_three -> set_icon(undef, undef, undef);
$window -> set_icon_name("Wheeee");
$window -> set_icon_name(undef);
$window -> set_transient_for($window_three);
$window -> set_role("Playa");
$window_three -> set_group($window_three);

$window -> set_decorations("all");

my @deco = $window -> get_decorations();
is(scalar @deco, 2);
isa_ok($deco[1], "Gtk2::Gdk::WMDecoration");

$window -> set_functions("all");

isa_ok((Gtk2::Gdk::Window -> get_toplevels())[0], "Gtk2::Gdk::Window");

isa_ok(Gtk2::Gdk -> get_default_root_window(), "Gtk2::Gdk::Window");

$window -> set_user_data(123);
is($window -> get_user_data(), 123);

SKIP: {
  skip("new 2.6 stuff", 0)
    unless Gtk2 -> CHECK_VERSION(2, 6, 0);

  $window -> enable_synchronized_configure();
  $window -> configure_finished();
  $window -> set_focus_on_map(TRUE);
}

SKIP: {
  skip("new 2.8 stuff", 0)
    unless Gtk2 -> CHECK_VERSION(2, 8, 0);

  $window_three -> set_urgency_hint(TRUE);
  $window_three -> move_region($region, 10, 10);
}

SKIP: {
  skip "new 2.12 stuff", 0
    unless Gtk2 -> CHECK_VERSION(2, 12, 0);

  $window -> set_startup_id('bla');
  $window -> set_opacity(1.0);
  $window -> set_composited(FALSE);
  # $window -> beep();
}

SKIP: {
  skip 'new 2.14 stuff', 0
    unless Gtk2->CHECK_VERSION(2, 14, 0);

  $window -> redirect_to_drawable($window_two, 0, 0, 0, 0, 10, 10);
  $window -> remove_redirection();
}

$window -> hide();

SKIP: {
  skip 'new 2.18 stuff', 7
    unless Gtk2->CHECK_VERSION(2, 18, 0);

  my $window = Gtk2::Gdk::Window -> new(undef, { window_type => 'toplevel' });
  $window -> flush();
  ok($window -> ensure_native());
  $window -> geometry_changed();

  is($window -> get_cursor(), undef);
  $window -> set_cursor(Gtk2::Gdk::Cursor -> new("arrow"));
  isa_ok($window -> get_cursor(), 'Gtk2::Gdk::Cursor');

  my $sibling = Gtk2::Gdk::Window -> new(undef, { window_type => 'toplevel' });
  $window -> restack(undef, TRUE);
  $window -> restack($sibling, TRUE);

  my $gtkwindow= Gtk2::Window->new;
  $gtkwindow->show_all;
  $gtkwindow->realize;
  my $offscreen= Gtk2::Gdk::Window->new(undef, { window_type	=> 'offscreen', });
  $offscreen->set_embedder($gtkwindow->window);
  isa_ok($offscreen->get_pixmap,  'Gtk2::Gdk::Pixmap');
  isa_ok($offscreen->get_embedder,'Gtk2::Gdk::Window');

  my ($rx, $ry) = $window->get_root_coords(0, 0);
  ok(defined $rx && defined $ry);
  ok(defined $window->is_destroyed());
}

SKIP: {
  skip 'new 2.22 stuff', 11
    unless Gtk2->CHECK_VERSION(2, 22, 0);

  my $window = Gtk2::Gdk::Window -> new(undef, { window_type => 'toplevel' });
  is_deeply ([$window->coords_from_parent (0, 0)], [0, 0]);
  is_deeply ([$window->coords_to_parent (0, 0)], [0, 0]);
  ok (defined $window->get_accept_focus);
  ok (defined $window->get_composited);
  isa_ok ($window->get_effective_parent, 'Gtk2::Gdk::Window');
  isa_ok ($window->get_effective_toplevel, 'Gtk2::Gdk::Window');
  ok (defined $window->get_focus_on_map);
  ok (defined $window->get_modal_hint);
  ok (defined $window->has_native);
  ok (defined $window->is_input_only);
  ok (defined $window->is_shaped);
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
