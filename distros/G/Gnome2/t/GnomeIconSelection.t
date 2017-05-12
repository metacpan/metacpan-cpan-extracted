#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 3;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  my $selection = Gnome2::IconSelection -> new();
  isa_ok($selection, "Gnome2::IconSelection");
  isa_ok($selection -> get_gil(), "Gnome2::IconList");
  isa_ok($selection -> get_box(), "Gtk2::VBox");

  my $window = Gtk2::Window -> new();
  $window -> add($selection);
  $selection -> realize();

  $selection -> clear(1);

  $selection -> add_defaults();
  $selection -> add_directory("/usr/share/pixmaps");

  $selection -> stop_loading();
  $selection -> show_icons();

  $selection -> select_icon("yes.xpm");
  $selection -> get_icon(1); # FIXME: the return value should be checked.
}
