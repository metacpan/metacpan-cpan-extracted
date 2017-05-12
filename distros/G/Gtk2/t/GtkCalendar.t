#!/usr/bin/perl
#
# $Id$
#

#########################
# GtkCalendar Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 18;

ok( my $cal = Gtk2::Calendar->new );

$cal->freeze;

$cal->select_month (11, 2003);
$cal->select_day (4);
foreach (qw/6 13 20 27 7 14 21 28 25/)
{
	$cal->mark_day ($_);
}

$cal->thaw;

is ($cal->num_marked_dates, 9);
$cal->mark_day (24);
is ($cal->num_marked_dates, 10);
$cal->unmark_day (24);
is ($cal->num_marked_dates, 9);

ok (eq_array ([ $cal->marked_date ], 
		[ 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 
		1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0]));

$cal->clear_marks;
is ($cal->num_marked_dates, 0);

is ($cal->year, 2003);
is ($cal->month, 11);
is ($cal->selected_day, 4);
ok (eq_array ([ $cal->get_date ], [ 2003, 11, 4 ]));

$cal->display_options ([qw/show-day-names no-month-change/]);
$cal->set_display_options ([qw/show-day-names no-month-change/]);
ok ($cal->get_display_options == [qw/show-day-names no-month-change/]);

SKIP: {
	skip 'new 2.14 stuff', 7
		unless Gtk2->CHECK_VERSION(2, 14, 0);

	my $cal = Gtk2::Calendar->new;

	my $number = qr/\A\d+\z/;
	my $called = 0;
	$cal->set_detail_func(sub {
		my ($tmp_cal, $year, $month, $day, $data) = @_;

		unless ($called++) {
			is ($tmp_cal, $cal);
			like ($year, $number);
			like ($month, $number);
			like ($day, $number);
			is ($data, undef);
		}

		return '<b>bla</b>';
	});

	my $window = Gtk2::Window->new;
	$window->add ($cal);
	$window->show_all;
	$window->hide;

	$cal->set_detail_height_rows (3);
	is ($cal->get_detail_height_rows, 3);

	$cal->set_detail_width_chars (5);
	is ($cal->get_detail_width_chars, 5);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
