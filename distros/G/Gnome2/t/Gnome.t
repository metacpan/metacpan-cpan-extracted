#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 23;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  foreach (Gnome2::ModuleInfo -> libgnome(),
           Gnome2::ModuleInfo -> libgnomeui(),
           Gnome2::ModuleInfo -> bonobo()) {
    isa_ok($_, "Gnome2::ModuleInfo");
    ok(defined($_ -> name()));
    ok(defined($_ -> version()));
    ok(defined($_ -> description()));
  }

  ok(-e Gnome2 -> user_dir_get());
  ok(-e Gnome2 -> user_private_dir_get());
  ok(-e Gnome2 -> user_accels_dir_get());

  #############################################################################

  is(Gnome2::UIDefs -> pad, 8);
  is(Gnome2::UIDefs -> key_name_find, "f");
  is(Gnome2::UIDefs -> key_name_replace, "r");
  like(Gnome2::UIDefs -> key_name_pause_game, qr/^\d+$/);

  #############################################################################

  is(Gnome2::GConf -> get_gnome_libs_settings_relative("test"),
     "/apps/gnome-settings/Test/test");

  is(Gnome2::GConf -> get_app_settings_relative($application, "test"),
     "/apps/Test/test");

  #############################################################################

  my $window = Gtk2::Window -> new("toplevel");

  $window -> toplevel_set_title("test.doc", "Test", ".doc");
  is($window -> get_title(), "test : Test");

  Gnome2::WindowIcon -> init();
  Gnome2::WindowIcon -> set_from_default($window);
  Gnome2::WindowIcon -> set_from_file($window, "/usr/share/pixmaps/yes.xpm");
  Gnome2::WindowIcon -> set_from_file_list($window, ["/usr/share/pixmaps/yes.xpm"]);
  Gnome2::WindowIcon -> set_default_from_file("/usr/share/pixmaps/yes.xpm");
  Gnome2::WindowIcon -> set_default_from_file_list(["/usr/share/pixmaps/yes.xpm"]);

  #############################################################################

  my $about = Gnome2::About -> new("Test",
                                   "0.1",
                                   "Copyright © 1923-1942 Holy Shit, Inc.",
                                   "Schmih Schmah Schmuh",
                                   [qw(Bla Ble Bli Blo Blu)],
                                   "Only You",
                                   "Where's my calculator?");

  isa_ok($about, "Gtk2::Dialog");
}
