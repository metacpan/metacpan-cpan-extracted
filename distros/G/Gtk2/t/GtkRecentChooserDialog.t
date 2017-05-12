#!/usr/bin/perl -w
use strict;

sub on_unthreaded_freebsd {
  if ($^O eq 'freebsd') {
    require Config;
    if ($Config::Config{ldflags} !~ m/-pthread\b/) {
      return 1;
    }
  }
  return 0;
}

use Gtk2::TestHelper
  tests => 14,
  at_least_version => [2, 10, 0, "GtkRecentChooserDialog"],
  (on_unthreaded_freebsd () ? (skip_all => 'need a perl compiled with "-pthread" on freebsd') : ());

# $Id$

my $window = Gtk2::Window -> new();
my $manager = Gtk2::RecentManager -> new();

my $chooser = Gtk2::RecentChooserDialog -> new("Test", $window);
isa_ok($chooser, "Gtk2::RecentChooser");
isa_ok($chooser, "Gtk2::RecentChooserDialog");

$chooser = Gtk2::RecentChooserDialog -> new("Test", undef);
isa_ok($chooser, "Gtk2::RecentChooser");
isa_ok($chooser, "Gtk2::RecentChooserDialog");

$chooser = Gtk2::RecentChooserDialog -> new_for_manager("Test", $window, $manager);
isa_ok($chooser, "Gtk2::RecentChooser");
isa_ok($chooser, "Gtk2::RecentChooserDialog");

$chooser = Gtk2::RecentChooserDialog -> new_for_manager("Test", undef, $manager);
isa_ok($chooser, "Gtk2::RecentChooser");
isa_ok($chooser, "Gtk2::RecentChooserDialog");

$chooser = Gtk2::RecentChooserDialog -> new("Test", $window, "gtk-ok" => "ok");
isa_ok($chooser, "Gtk2::RecentChooser");
isa_ok($chooser, "Gtk2::RecentChooserDialog");

my @buttons = $chooser -> action_area -> get_children();
is(scalar @buttons, 1);

$chooser = Gtk2::RecentChooserDialog -> new_for_manager("Test", $window, $manager, "gtk-ok" => "ok", "gtk-cancel" => "cancel");
isa_ok($chooser, "Gtk2::RecentChooser");
isa_ok($chooser, "Gtk2::RecentChooserDialog");

@buttons = $chooser -> action_area -> get_children();
is(scalar @buttons, 2);

__END__

Copyright (C) 2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
