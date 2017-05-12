#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 20;

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
	my $print;
	$print = Gtk2::SourceView2::PrintCompositor->new(
		Gtk2::SourceView2::Buffer->new(undef)
	);
	isa_ok($print, 'Gtk2::SourceView2::PrintCompositor');

	my $window = Gtk2::Window->new();
	my $view = Gtk2::SourceView2::View->new();
	$window->add($view);

	$print = Gtk2::SourceView2::PrintCompositor->new_from_view($view);
	isa_ok($print, 'Gtk2::SourceView2::PrintCompositor');
}


sub test_properties {
	my $print = Gtk2::SourceView2::PrintCompositor->new(
		Gtk2::SourceView2::Buffer->new(undef)
	);
	isa_ok($print, 'Gtk2::SourceView2::PrintCompositor');

	isa_ok($print->get_buffer, 'Gtk2::SourceView2::Buffer');

	is_int_ok($print, 'tab_width', 4, 6);
	is_enum_ok($print, 'wrap_mode', 'word', 'char');
	is_boolean_ok($print, 'highlight_syntax');
	is_int_ok($print, 'print_line_numbers', 5, 10);

	is_string_ok($print, 'body_font_name', "Sans 10", "Sans 12");
	is_string_ok($print, 'line_numbers_font_name', "Sans 10", "Sans 12");
	is_string_ok($print, 'header_font_name', "Sans 10", "Sans 12");
	is_string_ok($print, 'footer_font_name', "Sans 10", "Sans 12");

	is_unit_ok($print, 'top_margin', 10, 20, 'mm');
	is_unit_ok($print, 'bottom_margin', 10, 20, 'inch');
	is_unit_ok($print, 'left_margin', 10, 20, 'points');
	is_unit_ok($print, 'right_margin', 10, 20, 'mm');

	is_boolean_ok($print, 'print_header');
	is_boolean_ok($print, 'print_footer');

	is($print->get_n_pages, -1, "get_n_pages");
	is($print->get_pagination_progress, 0, "get_pagination_progress");

	# Can't be tested but at least we try them
	$print->set_header_format(TRUE, "hello", "world", "!");
	$print->set_header_format(TRUE, undef, undef, undef);
	$print->set_footer_format(TRUE, "perl", "gtk2", "sourceview");
	$print->set_footer_format(TRUE, undef, undef, undef);
}


sub is_unit_ok {
	my ($view, $property, $val1, $val2, $unit) = @_;
	my $get = "get_$property";
	my $set = "set_$property";

	my $value = $view->$get($unit);
	my ($new_value) = ($value eq $val1 ? $val2 : $val1);

	$view->$set($new_value, $unit);
	my $tester = Test::Builder->new();
	$tester->is_eq($view->$get($unit), $new_value, $property);
}
