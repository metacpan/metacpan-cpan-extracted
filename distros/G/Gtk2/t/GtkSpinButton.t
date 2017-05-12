#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 12;

# $Id$

my $adjustment = Gtk2::Adjustment -> new(0, 0, 100, 1, 5, 0);

my $spin = Gtk2::SpinButton -> new($adjustment, 0.2, 1);
isa_ok($spin, "Gtk2::SpinButton");
ginterfaces_ok($spin);

$spin -> configure($adjustment, 0.2, 1);

$spin -> set_adjustment($adjustment);
is($spin -> get_adjustment(), $adjustment);

$spin = Gtk2::SpinButton -> new_with_range(0, 100, 5);

$spin -> set_digits(3);
is($spin -> get_digits(), 3);

$spin -> set_increments(5, 20);
is_deeply([$spin -> get_increments()], [5, 20]);

$spin -> set_range(0, 100);
is_deeply([$spin -> get_range()], [0, 100]);

$spin -> set_value(23.42);
is($spin -> get_value_as_int(), 23);
delta_ok($spin -> get_value(), 23.42);

$spin -> set_update_policy("if-valid");
is($spin -> get_update_policy(), "if-valid");

$spin -> set_numeric(1);
is($spin -> get_numeric(), 1);

$spin -> spin("end", 10);

$spin -> set_wrap(1);
is($spin -> get_wrap(), 1);

$spin -> set_snap_to_ticks(1);
is($spin -> get_snap_to_ticks(), 1);

$spin -> update();

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
