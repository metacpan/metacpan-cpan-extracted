#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 8;

# $Id$

my $viewport = Gtk2::Viewport -> new();
isa_ok($viewport, "Gtk2::Viewport");

my $adjustment = Gtk2::Adjustment -> new(0, 0, 100, 1, 5, 10);

$viewport -> set_hadjustment($adjustment);
is($viewport -> get_hadjustment(), $adjustment);

$viewport -> set_vadjustment($adjustment);
is($viewport -> get_vadjustment(), $adjustment);

$viewport = Gtk2::Viewport -> new(undef, undef);
isa_ok($viewport, "Gtk2::Viewport");

$viewport = Gtk2::Viewport -> new($adjustment, $adjustment);
isa_ok($viewport, "Gtk2::Viewport");

$viewport -> set_shadow_type("etched-in");
is($viewport -> get_shadow_type(), "etched-in");

my $window = Gtk2::Window->new;
$window->add ($viewport);
$viewport->realize;

SKIP: {
    skip "new 2.20 stuff", 1
        unless Gtk2->CHECK_VERSION(2, 20, 0);

    isa_ok ($viewport->get_bin_window, 'Gtk2::Gdk::Window');
}

SKIP: {
    skip "new 2.22 stuff", 1
        unless Gtk2->CHECK_VERSION(2, 22, 0);

    isa_ok ($viewport->get_view_window, 'Gtk2::Gdk::Window');
}

__END__

Copyright (C) 2003, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
