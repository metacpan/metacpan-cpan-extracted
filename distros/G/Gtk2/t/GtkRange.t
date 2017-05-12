#!/usr/bin/perl -w
# vim: set ft=perl :
use strict;
use Gtk2::TestHelper tests => 15;

# $Id$

my $adjustment = Gtk2::Adjustment -> new(0, 0, 100, 1, 5, 10);

my $range = Gtk2::HScale -> new($adjustment);
isa_ok($range, "Gtk2::Range");

$range -> set_adjustment($adjustment);
is($range -> get_adjustment(), $adjustment);

$range -> set_update_policy("continuous");
is($range -> get_update_policy(), "continuous");

$range -> set_inverted(1);
is($range -> get_inverted(), 1);

$range -> set_value(23.42);
delta_ok($range -> get_value(), 23.42);

$range -> set_increments(1, 5);
$range -> set_range(0, 100);

SKIP: {
        skip 'new stuff in 2.10', 2
                unless Gtk2 -> CHECK_VERSION(2, 10, 0);

        $range -> set_lower_stepper_sensitivity('off');
        is ($range -> get_lower_stepper_sensitivity, 'off');

	$range -> set_upper_stepper_sensitivity('on');
	is ($range -> get_upper_stepper_sensitivity, 'on');
}

SKIP: {
        skip 'new stuff in 2.12', 3
                unless Gtk2 -> CHECK_VERSION(2, 12, 0);

	$range -> set_show_fill_level(TRUE);
	ok($range -> get_show_fill_level());

	$range -> set_restrict_to_fill_level(FALSE);
	ok(!$range -> get_restrict_to_fill_level());

	$range -> set_fill_level(0.23);
	delta_ok($range -> get_fill_level(), 0.23);
}

SKIP: {
        skip 'new stuff in 2.18', 1
                unless Gtk2 -> CHECK_VERSION(2, 18, 0);

	$range -> set_flippable(TRUE);
	ok($range -> get_flippable, '[gs]et_flippable');
}

SKIP: {
	skip 'new 2.20 stuff', 4
		unless Gtk2->CHECK_VERSION(2, 20, 0);

	$range -> set_min_slider_size(TRUE);
	ok($range -> get_min_slider_size());
	my $rect = $range -> get_range_rect();
	ok(defined $rect -> width() && defined $rect -> height());
	my ($start, $end) = $range -> get_slider_range();
	ok(defined $start && defined $end);
	$range -> set_slider_size_fixed(TRUE);
	ok($range -> get_slider_size_fixed());
}

__END__

Copyright (C) 2003,2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
