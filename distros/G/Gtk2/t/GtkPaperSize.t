#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 20,
  at_least_version => [2, 10, 0, "GtkPaperSize is new in 2.10"];

# $Id$

my $size = Gtk2::PaperSize -> new(undef);
isa_ok($size, "Gtk2::PaperSize");

$size = Gtk2::PaperSize -> new_from_ppd("urgs?", "A4", 23, 42);
isa_ok($size, "Gtk2::PaperSize");
is($size -> get_ppd_name(), "urgs?");

$size = Gtk2::PaperSize -> new_custom("bla", "Bla", 23, 42, "mm");
isa_ok($size, "Gtk2::PaperSize");
is($size -> get_width("mm"), 23);
is($size -> get_height("mm"), 42);
ok($size -> is_custom());
$size -> set_size(42, 23, "mm");

$size = Gtk2::PaperSize -> new("iso_a4");
isa_ok($size, "Gtk2::PaperSize");
ok($size -> is_equal($size));
is($size -> get_name(), "iso_a4");
is($size -> get_display_name(), "A4");
ok(defined $size -> get_default_top_margin("mm"));
ok(defined $size -> get_default_bottom_margin("points"));
ok(defined $size -> get_default_left_margin("inch"));
ok(defined $size -> get_default_right_margin("mm"));

ok(defined Gtk2::PaperSize -> get_default());

SKIP: {
  skip 'new 2.12 stuff', 4
    unless Gtk2->CHECK_VERSION (2, 12, 0);

  my $key_file = Glib::KeyFile -> new();
  my $group = 'bla';
  $size -> to_key_file($key_file, $group);

  my $new_size;
  eval {
    $new_size = Gtk2::PaperSize -> new_from_key_file($key_file, $group);
  };
  is($@, '');
  isa_ok($new_size, 'Gtk2::PaperSize');
  is($new_size -> get_name(), 'iso_a4');

  my @sizes = Gtk2::PaperSize::get_paper_sizes(FALSE);
  isa_ok($sizes[0], 'Gtk2::PaperSize');
}

__END__

Copyright (C) 2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
