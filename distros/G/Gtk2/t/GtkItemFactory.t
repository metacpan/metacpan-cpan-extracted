#!/usr/bin/perl
#
# $Id$
#

#########################
# Gtk2::ItemFactory Tests
# 	- rm
#########################

use strict;
use Gtk2::TestHelper tests => 58;

my @actions_used = (qw/1 0 0 0 0 0/);
my @items = (
	[
		'/_Menu',
		undef,
		undef,
		undef,
		'<Branch>',
	],
	[
		'/_Menu/Test _1',
		undef,
		\&callback,
		1,
		'<StockItem>',
		'gtk-execute'
	],
	{
		path => '/_Menu/Test _2',
		callback => \&callback,
		callback_action => 2,
		item_type => '<StockItem>',
		extra_data => 'gtk-execute'
	},
	{
		path => '/_Menu/Sub _Menu',
		item_type => '<Branch>',
	},
	[
		'/_Menu/Sub Menu/Test _1',
		undef,
		\&callback,
		3,
		'<StockItem>',
		'gtk-execute'
	],
	[
		'/_Menu/Sub Menu/Test _2',
		undef,
		sub {
			my ($data, $action, $widget) = @_;

			isa_ok( $data, 'HASH' );
			isa_ok( $widget, "Gtk2::MenuItem" );

			my $tmp_fac = Gtk2::ItemFactory->popup_data_from_widget($widget);

			isa_ok( $tmp_fac, "Gtk2::ItemFactory" );
			is( $tmp_fac->popup_data, $tmp_fac );

			$actions_used[4]++;
		},
		undef,
		undef,
	],
	[
		'/_Menu/_Quit',
		undef,
		\&callback,
		5,
		'<StockItem>',
		'gtk-quit'
	],
);

sub callback
{
	my ($data, $action, $item) = @_;
	isa_ok ($data, 'HASH', 'callback data');
	$actions_used[$action]++;
	isa_ok ($item, 'Gtk2::MenuItem');
	# Add some "padding" so all menu callbacks have the same number of
	# tests.
	ok (TRUE);
	ok (TRUE);
}

ok( my $fac = Gtk2::ItemFactory->new('Gtk2::Menu', '<main>', undef) );

my $item = pop @items;
$fac->create_items({foo=>'bar'}, @items);
$fac->create_item ($item, {foo=>'bar'});
push @items, $item;

$fac->set_translate_func(sub {
	my ($path, $data) = @_;

	like( $path, qr(^/_Menu/) );
	is( $data, "bla" );

	"_Meenyoo"
}, "bla");

$fac->popup(10, 10, 1, 0, $fac);
isa_ok( $fac->get_widget('<main>'), "Gtk2::Menu" );

# is( Gtk2::ItemFactory->path_from_widget($fac->get_widget_by_action(2)),
#     '<main>/Menu/Test 2' );

# sometimes, these can apparently return undef
SKIP: {
	my $widget = $fac->get_widget_by_action(2);
	skip 'get_widget_by_action returned undef', 1
		unless defined $widget;

	isa_ok( $widget, "Gtk2::Widget" );
}

SKIP: {
	my $item = $fac->get_item_by_action(2);
	skip 'get_item_by_action returned undef', 1
		unless defined $item;

	isa_ok( $item, "Gtk2::MenuItem" );
}

my $skip_actions_tests = FALSE;

foreach ('<main>/Menu/Test 1',
         '<main>/Menu/Test 2',
         '<main>/Menu/Sub Menu/Test 1',
         '<main>/Menu/Sub Menu/Test 2',
         '<main>/Menu/Quit') {

	my $widget = $fac->get_widget($_);

	SKIP: {
		unless (defined $widget) {
			$skip_actions_tests = TRUE;
			# $widget->activate would have invoked one of the
			# callbacks, so add their number of tests to the skip
			# count.
			skip "for some reason, get_widget returned undef", 7;
		}

		isa_ok( $fac->get_item($_), "Gtk2::MenuItem" );

		is( Gtk2::ItemFactory->from_widget($widget), $fac );
		is( Gtk2::ItemFactory->path_from_widget($widget), $_ );

		$widget->activate;
	}
}

$fac->delete_item('<main>/Menu/Test 1');
$fac->delete_entry($items[2]);
$fac->delete_entries(@items[4..6]);

foreach ('<main>/Menu/Test 1',
         '<main>/Menu/Test 2',
         '<main>/Menu/Sub Menu/Test 1',
         '<main>/Menu/Sub Menu/Test 2',
         '<main>/Menu/Quit') {
	is( $fac->get_widget($_), undef );
}

SKIP: {
	skip "actions tests", scalar @actions_used
		if $skip_actions_tests;

	foreach (@actions_used)
	{
		ok( $_ );
	}
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
