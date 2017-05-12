#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 12;
use Test::More skip_all => "Seems to be broken", tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  my $adjustment = Gtk2::Adjustment -> new(50, 0, 100, 5, 5, 20);
  my $list = Gnome2::IconList -> new(23, $adjustment, [qw(static-text is-editable)]);
  isa_ok($list, "Gnome2::IconList");

  $list -> set_hadjustment($adjustment);
  $list -> set_vadjustment($adjustment);

  $list -> freeze();
  $list -> thaw();

  $list -> insert(0, "/usr/share/pixmaps/yes.xpm", "YES!");
  $list -> insert_pixbuf(1,
                         Gtk2::Gdk::Pixbuf -> new("rgb", 1, 8, 23, 42),
                         "/usr/share/pixmaps/yes.xpm",
                         "YES!");

  $list -> append("/usr/share/pixmaps/yes.xpm", "YES!");
  $list -> append_pixbuf(Gtk2::Gdk::Pixbuf -> new("rgb", 1, 8, 23, 42),
                         "/usr/share/pixmaps/yes.xpm",
                         "YES!");

  is($list -> get_icon_filename(2), "/usr/share/pixmaps/yes.xpm");
  is($list -> find_icon_from_filename("/usr/share/pixmaps/yes.xpm"), 0);

  $list -> remove(1);

  is($list -> get_num_icons(), 3);

  $list -> set_selection_mode("multiple");
  is($list -> get_selection_mode(), "multiple");

  $list -> select_icon(1);
  is_deeply([$list -> get_selection()], [1]);

  $list -> unselect_icon(1);
  $list -> unselect_all();

  SKIP: {
    skip("select_all is new in 2.8", 0)
      unless (Gnome2 -> CHECK_VERSION(2, 8, 0));

    $list -> select_all();
  }

  $list -> focus_icon(1);

  $list -> set_icon_width(42);
  $list -> set_row_spacing(5);
  $list -> set_col_spacing(5);
  $list -> set_text_spacing(5);
  $list -> set_icon_border(5);
  $list -> set_separators("--");

  # FIXME: why does moveto() yield a warning?
  # $list -> moveto(1, 0.0);

  is($list -> icon_is_visible(1), "none");
  is($list -> get_icon_at(20, 20), -1);

  like($list -> get_items_per_line(), qr/^\d+$/);

  my $item = $list -> get_icon_text_item(1);
  isa_ok($item, "Gnome2::IconTextItem");
  $item -> configure(10, 10, 23, "Sans 12", "BLA!", 0, 1);
  is($item -> get_text(), "BLA!");
  $item -> setxy(11, 11);
  $item -> select(1);
  $item -> focus(1);
  $item -> start_editing();
  isa_ok($item -> get_editable(), "Gtk2::Editable");
  $item -> stop_editing(0);

  # isa_ok($list -> get_icon_pixbuf_item(1), "Gnome2::Canvas::Pixbuf");

  # FIXME
  # on rh8, with libgnomeui-2.0 version 2.0.3, this line causes the test
  # to segfault and pop up the Gnome crash dialog when running under
  # make test, but not when running directly from the terminal.  probably
  # something strange going on with refcounts somewhere.  -mup
  # $list -> clear();
}
