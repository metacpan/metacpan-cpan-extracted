#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 18;

use FindBin;
use lib "$FindBin::Bin";
use my_helper;

use Glib qw(TRUE FALSE);
use Gtk2::SourceView2;


exit tests();


sub tests {
	test_constructors();
	test_properties();
	return 0;
}


sub test_constructors {
	my $parent = Gtk2::HBox->new();
	my $view = Gtk2::SourceView2::View->new();
	$parent->add($view);
	isa_ok($view, 'Gtk2::SourceView2::View');

	my $buffer = Gtk2::SourceView2::Buffer->new(undef);
	$view = Gtk2::SourceView2::View->new_with_buffer($buffer);
	$parent->add($view);
	isa_ok($view, 'Gtk2::SourceView2::View');
}


sub test_properties {
	my $parent = Gtk2::HBox->new();
	my $view = Gtk2::SourceView2::View->new();
	$parent->add($view);

	is_int_ok($view, 'tab_width', 4, 6);
	is_int_ok($view, 'indent_width', 4, 6);
	is_int_ok($view, 'right_margin_position', 4, 6);

	is_boolean_ok($view, 'show_line_numbers');
	is_boolean_ok($view, 'auto_indent');
	is_boolean_ok($view, 'insert_spaces_instead_of_tabs');
	is_boolean_ok($view, 'indent_on_tab');
	is_boolean_ok($view, 'highlight_current_line');
	is_boolean_ok($view, 'show_right_margin');
	is_boolean_ok($view, 'show_line_marks');

	is_enum_ok($view, 'smart_home_end', 'before', 'after');


	# Draw spaces
	$view->set_draw_spaces(['space', 'tab']);
	# Test::Simple 0.95 no longer stringifies its arguments before comparing
	is('' . $view->get_draw_spaces, '[ space tab ]', "draw_spaces");


	# Mark category (pixbuf, priority, background)
	my $pixbuf = Gtk2::Gdk::Pixbuf->new("rgb", FALSE, 8, 10, 10);
	$view->set_mark_category_pixbuf(test => $pixbuf);
	is(
		$view->get_mark_category_pixbuf('test'),
		$pixbuf,
		"mark_category_pixbuf"
	);
	$view->set_mark_category_pixbuf(test => undef);
	is(
		$view->get_mark_category_pixbuf('test'),
		undef,
		"mark_category_pixbuf undef"
	);

	$view->set_mark_category_priority(test => 15);
	is(
		$view->get_mark_category_priority('test'),
		15,
		"mark_category_priority"
	);

	my $color = Gtk2::Gdk::Color->new(65535, 0, 0);
	$view->set_mark_category_background(test => $color);
	is(
		$view->get_mark_category_background('test')->pixel,
		$color->pixel,
		"mark_category_background"
	);
}
