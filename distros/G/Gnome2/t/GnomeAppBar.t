#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 8;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  my $app_bar = Gnome2::AppBar -> new(1, 1, "always");
  isa_ok($app_bar, "Gnome2::AppBar");

  $app_bar -> set_default("-");

  $app_bar -> set_status("BLA!");
  isa_ok($app_bar -> get_status(), "Gtk2::Entry");
  is($app_bar -> get_status() -> get_text(), "BLA!");

  $app_bar -> clear_stack();
  is($app_bar -> get_status() -> get_text(), "-");

  $app_bar -> push("BLUB!");
  is($app_bar -> get_status() -> get_text(), "BLUB!");

  $app_bar -> pop();
  is($app_bar -> get_status() -> get_text(), "-");

  $app_bar -> set_progress_percentage(0.23);

  isa_ok($app_bar -> get_progress(), "Gtk2::ProgressBar");

  $app_bar -> refresh();

  $app_bar -> set_prompt("Hmm?", 0);
  is($app_bar -> get_response(), "");
  $app_bar -> clear_prompt();
}
