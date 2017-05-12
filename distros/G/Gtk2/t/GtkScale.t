#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 7;

# $Id$

my $adjustment = Gtk2::Adjustment -> new(0, 0, 100, 1, 5, 10);

my $scale = Gtk2::HScale -> new($adjustment);
isa_ok($scale, "Gtk2::Scale");

$scale -> set_digits(5);
is($scale -> get_digits(), 5);

$scale -> set_draw_value(1);
is($scale -> get_draw_value(), 1);

$scale -> set_value_pos("right");
is($scale -> get_value_pos(), "right");

SKIP: {
  skip("get_layout and get_layout_offsets are new in 2.4", 2)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  isa_ok($scale -> get_layout(), "Gtk2::Pango::Layout");
  is(@{[$scale -> get_layout_offsets()]}, 2);
}

SKIP: {
  skip("gtk_scale_add_mark and gtk_scale_clear_marks are new in 2.16", 1)
    unless Gtk2->CHECK_VERSION (2, 16, 0);

    # no way to test it other than checking they don't crash
  $scale -> add_mark(50,'top','this is the middle');
  $scale -> add_mark(80,'bottom',undef);
  $scale -> clear_marks;
  ok(1,"add_mark and clear_marks");
}

__END__

Copyright (C) 2003,2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
