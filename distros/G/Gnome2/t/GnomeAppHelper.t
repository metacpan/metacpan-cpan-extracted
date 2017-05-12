#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 2;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  my $menubar_info = [
    { type => "item", label => "Item", callback => sub { warn @_; } },
    { type => "toggleitem", label => "Toggle", callback => sub { warn @_; } },
    {
      type => "subtree",
      label => "Radio Items",
      subtree => [
        {
          type => "radioitems",
          moreinfo => [
            {
              type => "item",
              label => "A",
              callback => sub { warn @_; },
              hint => "Don't click me!"
            },
            {
              type => "item",
              label => "B"
            },
            {
              type => "item",
              label => "C"
            },
            {
              type => "item",
              label => "D"
            },
            {
              type => "item",
              label => "E"
            }
          ]
        }
      ]
    },
    {
      type => "subtree",
      label => "Help Me, PLEASE!",
      subtree => [
        {
          type => "help",
          moreinfo => "test"
        }
      ]
    },
  ];

  my $toolbar_info = [
    [ "item", "Item", undef, sub { warn @_; }, undef, undef, undef, undef ],
    { type => "separator" },
    { type => "toggleitem", label => "Toggle", callback => sub { warn @_; } }
  ];

  #############################################################################

  Gnome2 -> accelerators_sync();

  my $app = Gnome2::App -> new("test", "Test");

  my $accel_group = Gtk2::AccelGroup -> new();
  my $menubar = Gtk2::MenuBar -> new();
  my $toolbar = Gtk2::Toolbar -> new();

  $menubar -> fill_menu($menubar_info, $accel_group, 1, 1);
  $toolbar -> fill_toolbar($toolbar_info, $accel_group);

  $app -> create_menus($menubar_info);
  $app -> create_toolbar($toolbar_info);

  $app -> insert_menus("Toggle", $menubar_info);

  my ($widget, $pos) = $menubar -> find_menu_pos("Item");
  isa_ok($widget, "Gtk2::MenuBar");
  is($pos, 1);

  $app -> remove_menus("Item", 1);
  $app -> remove_menu_range("Toggle", 1, 2);

  my $dock_item = Gnome2::Bonobo::DockItem -> new("dock item", "normal");
  my $dock_toolbar = Gtk2::Toolbar -> new();

  $dock_item -> add($dock_toolbar);
  $app -> setup_toolbar($dock_toolbar, $dock_item);

  my $appbar = Gnome2::AppBar -> new(1, 1, "always");
  my $statusbar = Gtk2::Statusbar -> new();

  $app -> set_statusbar($appbar);

  $appbar -> install_menu_hints($menubar_info);
  $statusbar -> install_menu_hints($menubar_info);
  $app -> install_menu_hints($menubar_info);
}
