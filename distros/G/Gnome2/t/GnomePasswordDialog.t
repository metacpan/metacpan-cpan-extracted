#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 7;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  do "t/TestBoilerplate";

  skip("GnomePasswordDialog and GnomeAuthenticationManager didn't appear until 2.4.0", TESTS)
    unless (Gnome2 -> CHECK_VERSION(2, 4, 0));

  Gnome2::AuthenticationManager -> init();

  SKIP: {
    skip("dialog_is_visible is new in 2.8", 1)
      unless (Gnome2 -> CHECK_VERSION(2, 8, 0));

    ok(!Gnome2::AuthenticationManager -> dialog_is_visible());
  }

  my $dialog = Gnome2::PasswordDialog -> new("Bla", "Bla!", "bla", "alb", 1);
  isa_ok($dialog, "Gnome2::PasswordDialog");

  $dialog -> set_username("urgs");
  is($dialog -> get_username(), "urgs");

  $dialog -> set_password("urgs");
  is($dialog -> get_password(), "urgs");

  $dialog -> set_readonly_username(1);

  SKIP: {
    skip("things new in 2.6.0", 2)
      unless (Gnome2 -> CHECK_VERSION(2, 6, 0));

    $dialog -> set_show_username(1);
    $dialog -> set_show_domain(1);
    $dialog -> set_show_password(1);
    $dialog -> set_show_remember(1);
    $dialog -> set_readonly_domain(1);

    $dialog -> set_remember("nothing");
    is($dialog -> get_remember(), "nothing");

    $dialog -> set_domain("urgs");
    is($dialog -> get_domain(), "urgs");
  }

  SKIP: {
    skip("things new in 2.8.0", 1)
      unless (Gnome2 -> CHECK_VERSION(2, 8, 0));

    $dialog -> set_show_userpass_buttons(1);
    ok(!$dialog -> anon_selected());
  }

  # $dialog -> run_and_block();
}
