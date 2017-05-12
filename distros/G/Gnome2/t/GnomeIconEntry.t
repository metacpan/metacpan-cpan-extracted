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

  my $entry = Gnome2::IconEntry -> new("sometimes", "I wish you were here");
  isa_ok($entry, "Gnome2::IconEntry");

  $entry -> set_pixmap_subdir($ENV{ HOME });

  $entry -> set_filename("blablablub");
  ok(not defined($entry -> get_filename()));

  # $entry -> set_history_id("always");
  $entry -> set_browse_dialog_title("Boring");

  ok(not defined($entry -> pick_dialog()));

  $entry -> set_max_saved(23)
    if (Gnome2 -> CHECK_VERSION(2, 4, 0));
}
