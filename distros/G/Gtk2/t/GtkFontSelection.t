#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 23;

# $Id$

my $fs = Gtk2::FontSelection -> new();
isa_ok($fs, "Gtk2::FontSelection");

my $window = Gtk2::Window -> new();
$window -> add($fs);

ok($fs -> set_font_name("Sans 12"));
ok(defined($fs -> get_font_name()));

$fs -> set_preview_text("Quick brown gtk2-perl.");
is($fs -> get_preview_text(), "Quick brown gtk2-perl.");

my $dialog = Gtk2::FontSelectionDialog -> new("Bla");
isa_ok($dialog, "Gtk2::FontSelectionDialog");

isa_ok($dialog -> get_ok_button(), "Gtk2::Button");
isa_ok($dialog -> get_apply_button(), "Gtk2::Button");
isa_ok($dialog -> get_cancel_button(), "Gtk2::Button");

# The accessors without "get" prefix are deprecated.
ok($dialog -> ok_button == $dialog -> get_ok_button());
ok($dialog -> apply_button == $dialog -> get_apply_button());
ok($dialog -> cancel_button == $dialog -> get_cancel_button());

ok($dialog -> set_font_name("Sans 12"));
ok(defined($dialog -> get_font_name()));

$dialog -> set_preview_text("Quick brown gtk2-perl.");
is($dialog -> get_preview_text(), "Quick brown gtk2-perl.");

SKIP: {
  skip 'new 2.14 stuff', 8
    unless Gtk2->CHECK_VERSION(2, 14, 0);

  isa_ok($fs -> get_face(), 'Gtk2::Pango::FontFace');
  isa_ok($fs -> get_face_list(), 'Gtk2::Widget');
  isa_ok($fs -> get_family(), 'Gtk2::Pango::FontFamily');
  isa_ok($fs -> get_family_list(), 'Gtk2::Widget');
  isa_ok($fs -> get_preview_entry(), 'Gtk2::Widget');
  ok(defined $fs -> get_size());
  isa_ok($fs -> get_size_entry(), 'Gtk2::Widget');
  isa_ok($fs -> get_size_list(), 'Gtk2::Widget');
}

SKIP: {
  skip 'new 2.22 stuff', 1
    unless Gtk2->CHECK_VERSION(2, 22, 0);

  isa_ok($dialog -> get_font_selection(), 'Gtk2::FontSelection');
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
