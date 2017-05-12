#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 23,
  at_least_version => [2, 10, 0, "GtkPageSetup is new in 2.10"];

# $Id$

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

my $setup = Gtk2::PageSetup -> new();
isa_ok($setup, "Gtk2::PageSetup");

$setup -> set_orientation("landscape");
is($setup -> get_orientation(), "landscape");

my $size = Gtk2::PaperSize -> new("iso_a4");

$setup -> set_paper_size($size);
isa_ok($setup -> get_paper_size(), "Gtk2::PaperSize");

$setup -> set_top_margin(23, "mm");
is($setup -> get_top_margin("mm"), 23);

$setup -> set_bottom_margin(23, "mm");
is($setup -> get_bottom_margin("mm"), 23);

$setup -> set_left_margin(23, "mm");
is($setup -> get_left_margin("mm"), 23);

$setup -> set_right_margin(23, "mm");
is($setup -> get_right_margin("mm"), 23);

$setup -> set_paper_size_and_default_margins($size);

ok(defined $setup -> get_paper_width("mm"));
ok(defined $setup -> get_paper_height("mm"));
ok(defined $setup -> get_page_width("mm"));
ok(defined $setup -> get_page_height("mm"));

SKIP: {
  skip "new 2.12 stuff", 7
    unless Gtk2->CHECK_VERSION (2, 12, 0);

  my $new_setup;
  $setup -> set_top_margin(23, 'mm');

  my $file = "$dir/tmp.setup";

  eval {
    $setup -> to_file($file);
  };
  is($@, '');

  eval {
    $new_setup = Gtk2::PageSetup -> new_from_file($file);
  };
  is($@, '');
  isa_ok($new_setup, 'Gtk2::PageSetup');
  is($new_setup -> get_top_margin('mm'), 23);

  my $key_file = Glib::KeyFile -> new();
  my $group = undef;
  $setup -> to_key_file($key_file, $group);
  open my $fh, '>', $file or skip 'key file tests', 3;
  print $fh $key_file -> to_data();
  close $fh;

  $key_file = Glib::KeyFile -> new();
  eval {
    $key_file -> load_from_file($file, 'none');
    $new_setup = Gtk2::PageSetup -> new_from_key_file($key_file, $group);
  };
  is($@, '');
  isa_ok($new_setup, 'Gtk2::PageSetup');
  is($new_setup -> get_top_margin('mm'), 23);

}

SKIP: {
  skip 'new 2.14 stuff', 5
    unless Gtk2->CHECK_VERSION(2, 14, 0);

  my $file = "$dir/tmp.setup";

  my $setup = Gtk2::PageSetup -> new();
  $setup -> set_top_margin(23, 'mm');

  $setup -> to_file($file);

  my $key_file = Glib::KeyFile -> new();
  my $group = undef;
  $setup -> to_key_file($key_file, $group);

  my $copy = Gtk2::PageSetup -> new();
  eval {
    $copy -> load_file($file);
  };
  is($@, '');
  is($copy -> get_top_margin('mm'), 23);

  eval {
    $copy -> load_file('asdf');
  };
  ok(defined $@);

  $copy = Gtk2::PageSetup -> new();
  eval {
    $copy -> load_key_file($key_file, $group);
  };
  is($@, '');
  is($copy -> get_top_margin('mm'), 23);

}

__END__

Copyright (C) 2006, 2013 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
