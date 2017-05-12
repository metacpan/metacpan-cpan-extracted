#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 13;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  my $app = Gnome2::App -> new("test", "Test");
  isa_ok($app, "Gnome2::App");

  is($app -> prefix, "/test/");
  isa_ok($app -> dock, "Gnome2::Bonobo::Dock");
  isa_ok($app -> vbox, "Gtk2::VBox");
  isa_ok($app -> layout, "Gnome2::Bonobo::DockLayout");
  isa_ok($app -> accel_group, "Gtk2::AccelGroup");

  $app -> set_menus(Gtk2::MenuBar -> new());
  isa_ok($app -> menubar, "Gtk2::MenuBar");

  $app -> set_toolbar(Gtk2::Toolbar -> new());

  $app -> set_statusbar(Gtk2::Label -> new("Statusbar"));
  # $app -> set_statusbar_custom(Gtk2::HBox -> new(0, 0), Gtk2::Label -> new("Statusbar"));
  isa_ok($app -> statusbar, "Gtk2::Label");

  $app -> set_contents(Gtk2::Label -> new("Content"));
  isa_ok($app -> contents, "Gtk2::Label");

  $app -> add_toolbar(Gtk2::Toolbar -> new(), "toolbar", "normal", "top", 1, 1, 0);
  isa_ok($app -> add_docked(Gtk2::Toolbar -> new(), "dock", "normal", "left", 1, 2, 0), "Gnome2::Bonobo::DockItem");

  my $dock_item = Gnome2::Bonobo::DockItem -> new("dock item", "normal");
  $dock_item -> add(Gtk2::Toolbar -> new());
  $app -> add_dock_item($dock_item, "right", 1, 3, 0);

  $app -> enable_layout_config(0);
  is($app -> get_enable_layout_config, 0);

  isa_ok($app -> get_dock(), "Gnome2::Bonobo::Dock");
  isa_ok($app -> get_dock_item_by_name("dock item"), "Gnome2::Bonobo::DockItem");
}
