#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 16;

# $Id$

my $list = Gtk2::TargetList -> new();
isa_ok($list, "Gtk2::TargetList");
SKIP: {
  skip "2.10 stuff", 1
    unless Gtk2 -> CHECK_VERSION(2, 10, 0);

  isa_ok($list, "Glib::Boxed");
}

$list = Gtk2::TargetList -> new(
  { target => "STRING", flags => "same-app", info => 23 },
  { target => "COMPOUND_TEXT", flags => ["same-app", "same-widget"], info => 42 }
);

isa_ok($list, "Gtk2::TargetList");

$list -> add(Gtk2::Gdk->TARGET_BITMAP, ["same-app", "same-widget"], 2);
$list -> add_table({ target => "COLORMAP", flags => ["same-app", "same-widget"], info => 3 });

$list -> remove(Gtk2::Gdk->TARGET_BITMAP);

is($list -> find(Gtk2::Gdk->TARGET_BITMAP), undef);
is($list -> find(Gtk2::Gdk->TARGET_STRING), 23);

SKIP: {
  skip("2.6 stuff", 3)
    unless Gtk2 -> CHECK_VERSION(2, 6, 0);

  $list -> add_text_targets(42);
  $list -> add_image_targets(43, TRUE);
  $list -> add_uri_targets(44);

  is($list -> find(Gtk2::Gdk::Atom -> intern("text/plain")), 42);
  is($list -> find(Gtk2::Gdk::Atom -> intern("image/png")), 43);
  is($list -> find(Gtk2::Gdk::Atom -> intern("text/uri-list")), 44);
}

SKIP: {
  skip("2.10 stuff", 5)
    unless Gtk2 -> CHECK_VERSION(2, 10, 0);

  my $buffer = Gtk2::TextBuffer->new;
  $buffer->register_serialize_format (
    'text/rdf',
    sub { warn "here"; return 'bla!'; });
  $buffer->register_deserialize_format (
    'text/rdf',
    sub { warn "here"; $_[1]->insert ($_[2], 'bla!'); });
  $list -> add_rich_text_targets(45, TRUE, $buffer);

  is($list -> find(Gtk2::Gdk::Atom -> intern("text/rdf")), 45);

  my @targets = (
    Gtk2::Gdk::Atom -> intern("text/plain"),
    Gtk2::Gdk::Atom -> intern("text/uri-list"),
    Gtk2::Gdk::Atom -> intern("image/png"),
    Gtk2::Gdk::Atom -> intern("text/rdf"),
  );

  ok(Gtk2 -> targets_include_text(@targets));
  ok(Gtk2 -> targets_include_uri(@targets));
  ok(Gtk2 -> targets_include_rich_text($buffer, @targets));
  ok(Gtk2 -> targets_include_image(TRUE, @targets));
}

###############################################################################

my $window = Gtk2::Window -> new();
$window -> realize();

is(Gtk2::Selection -> owner_set($window,
                                Gtk2::Gdk->SELECTION_PRIMARY,
                                0), 1);

SKIP: {
  skip("GdkDisplay is new in 2.2", 1)
    unless Gtk2 -> CHECK_VERSION(2, 2, 0);

  is(Gtk2::Selection -> owner_set_for_display(Gtk2::Gdk::Display -> get_default(),
                                              $window,
                                              Gtk2::Gdk->SELECTION_SECONDARY,
                                              0), 1);
}

$window -> selection_add_target(Gtk2::Gdk->SELECTION_CLIPBOARD,
                                Gtk2::Gdk->TARGET_BITMAP,
                                5);

$window -> selection_add_targets(Gtk2::Gdk->SELECTION_PRIMARY,
                                 { target => "drawable", info => 7 },
                                 { target => "pixmap", info => 9 });

$window -> selection_clear_targets(Gtk2::Gdk->SELECTION_CLIPBOARD);

is($window -> selection_convert(Gtk2::Gdk->SELECTION_PRIMARY, Gtk2::Gdk->TARGET_PIXMAP, 0), 1);

# Test that this function continues to work, even if it's completely misbound.
Gtk2::SelectionData::gtk_selection_clear($window, Gtk2::Gdk::Event -> new("nothing"));

$window -> selection_remove_all();

###############################################################################

# The Gtk2::SelectionData stuff is tested in GtkClipboard.t.

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
