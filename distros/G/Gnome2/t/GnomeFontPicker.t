#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 6;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  my $picker = Gnome2::FontPicker -> new();
  isa_ok($picker, "Gnome2::FontPicker");

  $picker -> set_title("Sociol Distortion For President!");
  is($picker -> get_title(), "Sociol Distortion For President!");

  $picker -> set_mode("font-info");
  is($picker -> get_mode(), "font-info");

  $picker -> fi_set_use_font_in_label(1, 14);
  $picker -> fi_set_show_size(1);

  $picker -> set_mode("user-widget");

  my $label = Gtk2::Label -> new("Really?");

  $picker -> uw_set_widget($label);
  is($picker -> uw_get_widget(), $label);

  $picker -> set_font_name("sans 14");
  is($picker -> get_font_name(), "sans 14");

  $picker -> set_preview_text("Brown foxes suck.");
  is($picker -> get_preview_text(), "Brown foxes suck.");
}
