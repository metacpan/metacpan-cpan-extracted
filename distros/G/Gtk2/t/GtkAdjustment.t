#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 25, noinit => 1;

# $Id$

my $adjustment = Gtk2::Adjustment -> new(0, 0, 100, 1, 5, 10);
isa_ok($adjustment, "Gtk2::Adjustment");

is($adjustment -> lower(1), 0);
is($adjustment -> lower(), 1);

is($adjustment -> upper(99), 100);
is($adjustment -> upper(), 99);

is($adjustment -> value(23), 0);
is($adjustment -> value(), 23);

is($adjustment -> step_increment(2), 1);
is($adjustment -> step_increment(), 2);

is($adjustment -> page_increment(6), 5);
is($adjustment -> page_increment(), 6);

is($adjustment -> page_size(11), 10);
is($adjustment -> page_size(), 11);

$adjustment -> set_value(23);
is($adjustment -> get_value(), 23);

$adjustment -> clamp_page(0, 100);

$adjustment -> changed();
$adjustment -> value_changed();

SKIP: {
  skip "stuff that's new in 2.14", 11
    unless Gtk2->CHECK_VERSION (2, 14, 0);

  # note "value" forced to "lower <= value <= upper-page_size" by
  # gtk_adjustment_configure(), so must ensure that among these numbers
  $adjustment->configure(1002,1001,10003,1004,1005,1006);
  is ($adjustment->value, 1002);
  is ($adjustment->lower, 1001);
  is ($adjustment->upper, 10003);
  is ($adjustment->step_increment, 1004);
  is ($adjustment->page_increment, 1005);
  is ($adjustment->page_size, 1006);

  # see that they match up with the accessors

  $adjustment->set_lower(2001);
  is ($adjustment->lower, 2001);

  $adjustment->set_page_increment(2002);
  is ($adjustment->page_increment, 2002);

  $adjustment->set_page_size(2003);
  is ($adjustment->page_size, 2003);

  $adjustment->set_step_increment(2004);
  is ($adjustment->step_increment, 2004);

  $adjustment->set_upper(2005);
  is ($adjustment->upper, 2005);
}

__END__

Copyright (C) 2003, 2009 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
