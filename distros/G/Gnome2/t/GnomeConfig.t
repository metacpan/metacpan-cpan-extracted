#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 50;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  Gnome2::Config -> push_prefix("Test");

  #############################################################################

  Gnome2::Config -> set_string("/State/Shit", "Oh yes.");
  is(Gnome2::Config -> get_string("/State/Shit"), "Oh yes.");

  Gnome2::Config -> set_translated_string("/State/Shit", "Oh yes.");
  is(Gnome2::Config -> get_translated_string("/State/Shit"), "Oh yes.");

  is_deeply([Gnome2::Config -> get_string_with_default("/State/Whops=bla")], [1, "bla"]);
  is_deeply([Gnome2::Config -> get_string_with_default("/State/Shit")], [0, "Oh yes."]);

  is_deeply([Gnome2::Config -> get_translated_string_with_default("/State/Whops=bla")], [1, "bla"]);
  is_deeply([Gnome2::Config -> get_translated_string_with_default("/State/Shit")], [0, "Oh yes."]);

  Gnome2::Config -> set_vector("/State/Env", ["bla=blub", "blub=bla"]);
  is_deeply(Gnome2::Config -> get_vector("/State/Env"), ["bla=blub", "blub=bla"]);

  is_deeply([Gnome2::Config -> get_vector_with_default("/State/Whops")], [1, []]);
  is_deeply([Gnome2::Config -> get_vector_with_default("/State/Env")], [0, ["bla=blub", "blub=bla"]]);

  Gnome2::Config -> set_int("/Geometry/Width", 1024);
  is(Gnome2::Config -> get_int("/Geometry/Width"), 1024);

  is_deeply([Gnome2::Config -> get_int_with_default("/Geometry/Whops=1600")], [1, 1600]);
  is_deeply([Gnome2::Config -> get_int_with_default("/Geometry/Width")], [0, 1024]);

  Gnome2::Config -> set_float("/Geometry/Ratio", 1.23);
  is(Gnome2::Config -> get_float("/Geometry/Ratio"), 1.23);

  is_deeply([Gnome2::Config -> get_float_with_default("/Geometry/Whops=0.5")], [1, 0.5]);
  is_deeply([Gnome2::Config -> get_float_with_default("/Geometry/Ratio")], [0, 1.23]);

  Gnome2::Config -> set_bool("/State/Hidden", 1);
  ok(Gnome2::Config -> get_bool("/State/Hidden"));

  is_deeply([Gnome2::Config -> get_bool_with_default("/State/Whops=0")], [1, 0]);
  is_deeply([Gnome2::Config -> get_bool_with_default("/State/Hidden")], [0, 1]);

  ok(Gnome2::Config -> has_section("/State"));
  ok(not Gnome2::Config -> has_section("/Whops"));

  # #############################################################################

  Gnome2::Config::Private -> set_string("/State/Shit", "Oh yes.");
  is(Gnome2::Config::Private -> get_string("/State/Shit"), "Oh yes.");

  Gnome2::Config::Private -> set_translated_string("/State/Shit", "Oh yes.");
  is(Gnome2::Config::Private -> get_translated_string("/State/Shit"), "Oh yes.");

  is_deeply([Gnome2::Config::Private -> get_string_with_default("/State/Whops=bla")], [1, "bla"]);
  is_deeply([Gnome2::Config::Private -> get_string_with_default("/State/Shit")], [0, "Oh yes."]);

  is_deeply([Gnome2::Config::Private -> get_translated_string_with_default("/State/Whops=bla")], [1, "bla"]);
  is_deeply([Gnome2::Config::Private -> get_translated_string_with_default("/State/Shit")], [0, "Oh yes."]);

  Gnome2::Config::Private -> set_vector("/State/Env", ["bla=blub", "blub=bla"]);
  is_deeply(Gnome2::Config::Private -> get_vector("/State/Env"), ["bla=blub", "blub=bla"]);

  is_deeply([Gnome2::Config::Private -> get_vector_with_default("/State/Whops")], [1, []]);
  is_deeply([Gnome2::Config::Private -> get_vector_with_default("/State/Env")], [0, ["bla=blub", "blub=bla"]]);

  Gnome2::Config::Private -> set_int("/Geometry/Width", 1024);
  is(Gnome2::Config::Private -> get_int("/Geometry/Width"), 1024);

  is_deeply([Gnome2::Config::Private -> get_int_with_default("/Geometry/Whops=1600")], [1, 1600]);
  is_deeply([Gnome2::Config::Private -> get_int_with_default("/Geometry/Width")], [0, 1024]);

  Gnome2::Config::Private -> set_float("/Geometry/Ratio", 1.23);
  is(Gnome2::Config::Private -> get_float("/Geometry/Ratio"), 1.23);

  SKIP: {
    skip("get_float_with_default was broken prior to 2.6.0", 2)
      unless (Gnome2 -> CHECK_VERSION(2, 6, 0));

    is_deeply([Gnome2::Config::Private -> get_float_with_default("/Geometry/Whops=0.5")], [1, 0.5]);
    is_deeply([Gnome2::Config::Private -> get_float_with_default("/Geometry/Ratio")], [0, 1.23]);
  }

  Gnome2::Config::Private -> set_bool("/State/Hidden", 1);
  ok(Gnome2::Config::Private -> get_bool("/State/Hidden"));

  is_deeply([Gnome2::Config::Private -> get_bool_with_default("/State/Whops=0")], [1, 0]);
  is_deeply([Gnome2::Config::Private -> get_bool_with_default("/State/Hidden")], [0, 1]);

  ok(Gnome2::Config::Private -> has_section("/State"));
  ok(not Gnome2::Config::Private -> has_section("/Whops"));

  #############################################################################

  my $handle = Gnome2::Config -> init_iterator("/Geometry");
  isa_ok($handle, "Gnome2::Config::Iterator");

  $handle = Gnome2::Config::Private -> init_iterator("/Geometry");
  isa_ok($handle, "Gnome2::Config::Iterator");

  my ($key, $value);

  while (@_ = $handle -> next()) {
    ($handle, $key, $value) = @_;
    ok($key eq "Ratio" || $key eq "Width");
    ok($value == 1.23 || $value == 1024);
  }

  #############################################################################

  # FIXME: hrm, no sections?

  $handle = Gnome2::Config -> init_iterator_sections("Test");
  isa_ok($handle, "Gnome2::Config::Iterator");

  $handle = Gnome2::Config::Private -> init_iterator_sections("Test");
  isa_ok($handle, "Gnome2::Config::Iterator");

  while (@_ = $handle -> next()) {
    ($handle, $key, $value) = @_;
    warn $key, $value;
  }

  #############################################################################

  # ok(Gnome2::Config -> sync());
  # ok(Gnome2::Config -> sync_file("Test"));
  # ok(Gnome2::Config::Private -> sync_file("Test"));

  Gnome2::Config -> clean_key("/Geometry/Ratio");
  Gnome2::Config::Private -> clean_file("/Geometry/Ratio");
  Gnome2::Config -> clean_section("/Geometry");
  Gnome2::Config::Private -> clean_section("/Geometry");
  Gnome2::Config -> clean_file("Test");
  Gnome2::Config::Private -> clean_file("Test");

  Gnome2::Config -> drop_file("Test");
  Gnome2::Config::Private -> drop_file("Test");

  Gnome2::Config -> drop_all();

  #############################################################################

  Gnome2::Config -> pop_prefix();

  #############################################################################

  is(Gnome2::Config -> get_real_path("Test"), "$ENV{ HOME }/.gnome2/Test");
  is(Gnome2::Config::Private -> get_real_path("Test"), "$ENV{ HOME }/.gnome2_private/Test");
}
