#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 6;

# $Id$

my $button = Gtk2::Button -> new("Bla");
my $window = Gtk2::Window -> new();

$window -> add($button);
$window -> realize();
$button -> realize();

# Dest ########################################################################

$button -> drag_dest_set("all", "copy",
  { target => "BITMAP", info => 23 },
  { target => "STRING", flags => ["same-app", "same-widget"], info => 42 }
);

my $list = $button -> drag_dest_get_target_list();
$button -> drag_dest_set_target_list(undef);
$button -> drag_dest_set_target_list($list);

is($list -> find(Gtk2::Gdk -> TARGET_BITMAP), 23);
is($list -> find(Gtk2::Gdk -> TARGET_STRING), 42);

my $pixbuf = Gtk2::Gdk::Pixbuf -> new("rgb", 0, 8, 10, 10);

my $event = Gtk2::Gdk::Event -> new("button-press");

my $context = Gtk2::Drag -> begin($button, $list, "default", 1, $event);
SKIP: {
  skip "context test", 1 unless defined $context;
  isa_ok($context, "Gtk2::Gdk::DragContext");
}

$context = $button -> drag_begin($list, "default", 1, $event);
SKIP: {
  skip "context test", 1 unless defined $context;
  isa_ok($context, "Gtk2::Gdk::DragContext");
}

if (defined($context)) {
  # warn $button -> drag_dest_find_target($context, $list);
  # $context -> finish(1, 0, 0);
  # $button -> drag_get_data($context, Gtk2::Gdk -> TARGET_STRING, 0);
  # warn $context -> get_source_widget();

  $context -> set_icon_widget($window, 5, 5);

  my $pixmap = Gtk2::Gdk::Pixmap->new ($window->window, 16, 16, -1);
  $context -> set_icon_pixmap($pixmap->get_colormap, $pixmap, undef, 5, 5);
  my $mask = Gtk2::Gdk::Pixmap->new ($window->window, 16, 16, 1);
  $context -> set_icon_pixmap($pixmap->get_colormap, $pixmap, $mask, 5, 5);

  $context -> set_icon_pixbuf($pixbuf, 5, 5);
  $context -> set_icon_stock("gtk-add", 5, 5);
  $context -> set_icon_default();

  SKIP: {
    skip "new 2.8 stuff", 0
      unless Gtk2 -> CHECK_VERSION(2, 8, 0);

    $context -> set_icon_name("gtk-add", 5, 5);
  }
}

is($button -> drag_check_threshold(5, 5, 100, 100), 1);

$button -> drag_highlight();
$button -> drag_unhighlight();

$button -> drag_dest_set_proxy($window -> window(), "xdnd", 0);

SKIP: {
  skip("2.6 stuff", 0)
    unless Gtk2 -> CHECK_VERSION(2, 6, 0);

  $button -> drag_dest_add_text_targets();
  $button -> drag_dest_add_image_targets();
  $button -> drag_dest_add_uri_targets();
}

SKIP: {
  skip("2.10 stuff", 1)
    unless Gtk2 -> CHECK_VERSION(2, 10, 0);

  $button -> drag_dest_set_track_motion(FALSE);
  ok(!$button -> drag_dest_get_track_motion());
}

$button -> drag_dest_unset();

# Source ######################################################################

$button -> drag_source_set("shift-mask", "copy",
  { target => "BITMAP", info => 23 },
  { target => "STRING", flags => ["same-app", "same-widget"], info => 42 }
);

# $button -> drag_source_set_icon(...);
$button -> drag_source_set_icon_pixbuf($pixbuf);
$button -> drag_source_set_icon_stock("gtk-quit");

SKIP: {
  skip("drag_source_[sg]et_target_list is new in 2.4", 0)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  $list = $button -> drag_source_get_target_list();
  $button -> drag_source_set_target_list(undef);
  $button -> drag_source_set_target_list($list);
}

SKIP: {
  skip("2.6 stuff", 0)
    unless Gtk2 -> CHECK_VERSION(2, 6, 0);

  $button -> drag_source_add_text_targets();
  $button -> drag_source_add_image_targets();
  $button -> drag_source_add_uri_targets();
}

SKIP: {
  skip("2.8 stuff", 0)
    unless Gtk2 -> CHECK_VERSION(2, 8, 0);

  $button -> drag_source_set_icon_name("gtk-ok");
}

$button -> drag_source_unset();

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for
the full list).  See LICENSE for more information.
