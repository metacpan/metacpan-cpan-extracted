#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 20;

# $Id$

use Gtk2::Gdk::Keysyms;

my @devices = Gtk2::Gdk -> devices_list();
isa_ok($devices[0], "Gtk2::Gdk::Device");

my $device = Gtk2::Gdk::Device -> get_core_pointer();
isa_ok($device, "Gtk2::Gdk::Device");
is($device -> name, "Core Pointer");
is($device -> source, "mouse");
is($device -> mode, "screen");
is($device -> has_cursor, 1);

my @axes = $device -> axes;
is(@axes, 2);

my $axis = $axes[0];
isa_ok($axis, "HASH");
is($axis -> { use }, "x");
like($axis -> { min }, qr/^\d+$/);
like($axis -> { max }, qr/^\d+$/);

# FIXME:
# warn $device -> keys;
# $device -> set_key(0, $Gtk2::Gdk::Keysyms{ Escape }, [qw/shift-mask/]);

$device -> set_source("mouse");
$device -> set_mode("screen");
$device -> set_axis_use(1, "x");

my $window = Gtk2::Window -> new();
$window -> realize();

my ($mask, @positions) = $device -> get_state($window -> window());
isa_ok($mask, "Gtk2::Gdk::ModifierType");
is(scalar @positions, 2);

# FIXME: warn $device -> get_history($window -> window(), 0, time());

delta_ok($device -> get_axis("x", 1.23, 2, 3, 4), 1.23);

Gtk2::Gdk::Input -> set_extension_events($window -> window(), [qw/pointer-motion-mask/], "all");

SKIP: {
  skip 'new 2.22 stuff', 6
    unless Gtk2->CHECK_VERSION(2, 22, 0);

  my $device = Gtk2::Gdk::Device -> get_core_pointer();
  ok(defined $device->get_axis_use(0));
  ok(defined $device->get_mode());
  ok(defined $device->get_name());
  ok(defined $device->get_n_axes());
  ok(defined $device->get_source());

  skip 'no keys on device', 1
    unless $device -> keys();

  my ($keyval, $modifiers) = $device->get_key(0);
  ok(defined $keyval && defined $modifiers);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
