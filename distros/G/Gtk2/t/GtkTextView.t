#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 48;

# $Id$

my $window = Gtk2::Window -> new();
my $buffer = Gtk2::TextBuffer -> new();

$buffer -> insert($buffer -> get_start_iter(),
                  join("", "Lore ipsem dolor.  I think that is misspelled.\n" x 80));

my $view = Gtk2::TextView -> new_with_buffer($buffer);
isa_ok($view, "Gtk2::TextView");
is($view -> get_buffer(), $buffer);

$view = Gtk2::TextView -> new();
isa_ok($view, "Gtk2::TextView");

$window -> add($view);
$window -> realize();
$view -> realize();

$view -> set_buffer($buffer);
is($view -> get_buffer(), $buffer);

my $iter = $buffer -> get_iter_at_offset(1000);
my $mark = $buffer -> create_mark("bla", $iter, 1);

$view -> scroll_to_mark($mark, 0.23, 1, 0.5, 0.5);
$view -> scroll_mark_onscreen($mark);
ok(!$view -> move_mark_onscreen($mark));

is($view -> scroll_to_iter($iter, 0.23, 1, 0.5, 0.5), 1);
is($view -> place_cursor_onscreen(), 1);

isa_ok($view -> get_visible_rect(), "Gtk2::Gdk::Rectangle");
isa_ok($view -> get_iter_location($iter), "Gtk2::Gdk::Rectangle");

my @y = $view -> get_line_at_y(100);
isa_ok($y[0], "Gtk2::TextIter");
like($y[1], qr/^\d+$/);

my @yrange = $view -> get_line_yrange($iter);
like($yrange[0], qr/^\d+$/);
like($yrange[1], qr/^\d+$/);

isa_ok($view -> get_iter_at_location(23, 42), "Gtk2::TextIter");

my @window = $view -> buffer_to_window_coords("widget", 23, 42);
like($window[0], qr/^-?\d+$/);
like($window[1], qr/^-?\d+$/);

my @buffer = $view -> window_to_buffer_coords("widget", @window);
is($buffer[0], 23);
is($buffer[1], 42);

isa_ok($view -> get_window("text"), "Gtk2::Gdk::Window");
is($view -> get_window_type($view -> get_window("text")), "text");

$view -> set_border_window_size("bottom", 5);
is($view -> get_border_window_size("bottom"), 5);

is($view -> forward_display_line($iter), 1);
is($view -> starts_display_line($iter), 1);
is($view -> forward_display_line_end($iter), 1);
is($view -> backward_display_line($iter), 1);
is($view -> backward_display_line_start($iter), 1);
is($view -> starts_display_line($iter), 1);

is($view -> move_visually($iter, 5), 1);

my $anchor = $buffer -> create_child_anchor($iter);
my $button = Gtk2::Button -> new("Bla");
my $label = Gtk2::Label -> new("Bla");

$view -> add_child_at_anchor($button, $anchor);

$view -> add_child_in_window($label, "text", 23, 42);
$view -> move_child($label, 50, 50);

$view -> set_wrap_mode("char");
is($view -> get_wrap_mode(), "char");

$view -> set_editable(1);
is($view -> get_editable(), 1);

$view -> set_cursor_visible(1);
is($view -> get_cursor_visible(), 1);

$view -> set_pixels_above_lines(5);
is($view -> get_pixels_above_lines(), 5);

$view -> set_pixels_below_lines(5);
is($view -> get_pixels_below_lines(), 5);

$view -> set_pixels_inside_wrap(5);
is($view -> get_pixels_inside_wrap(), 5);

$view -> set_justification("center"),
is($view -> get_justification(), "center");

$view -> set_left_margin(5);
is($view -> get_left_margin(), 5);

$view -> set_right_margin(5);
is($view -> get_right_margin(), 5);

$view -> set_indent(5);
is($view -> get_indent(), 5);

$view -> set_tabs(Gtk2::Pango::TabArray -> new(8, 0));
isa_ok($view -> get_tabs(), "Gtk2::Pango::TabArray");

isa_ok($view -> get_default_attributes(), "Gtk2::TextAttributes");

SKIP: {
  skip("[sg]et_overwrite and [sg]et_accepts_tab are new in 2.4", 2)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  $view -> set_overwrite(1);
  is($view -> get_overwrite(), 1);

  $view -> set_accepts_tab(1);
  is($view -> get_accepts_tab(), 1);
}

SKIP: {
  skip("new stuff in 2.6", 3)
    unless Gtk2->CHECK_VERSION (2, 6, 0);

  my ($iter, $trailing) = $view->get_iter_at_position (10, 20);
  isa_ok ($iter, 'Gtk2::TextIter', 'get_iter_at_position in array context');
  like ($trailing, qr/^\d+$/, 'trailing');
  $iter = $view->get_iter_at_position (10, 20);
  isa_ok ($iter, 'Gtk2::TextIter', 'get_iter_at_position in scalar context');
}

SKIP: {
  skip 'new 2.22 stuff', 3
    unless Gtk2->CHECK_VERSION(2, 22, 0);

  my $event = Gtk2::Gdk::Event->new ('key-press');
  $event->window ($view->window);
  ok (defined $view->im_context_filter_keypress ($event));
  $view->reset_im_context;

  isa_ok ($view->get_hadjustment, 'Gtk2::Adjustment');
  isa_ok ($view->get_vadjustment, 'Gtk2::Adjustment');
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for
the full list).  See LICENSE for more information.
