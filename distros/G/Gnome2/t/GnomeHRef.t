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

  my $link = Gnome2::HRef -> new("ftp://ftp.freenet.de/pub/", "Freenet");
  isa_ok($link, "Gnome2::HRef");

  $link -> set_url("bla://blub");
  is($link -> get_url(), "bla://blub");

  $link -> set_text("Hmm");
  is($link -> get_text(), "Hmm");
}
