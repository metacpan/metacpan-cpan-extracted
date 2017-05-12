#!/usr/bin/env perl

use Gtk2::TestHelper
	tests => 28,
	at_least_version => [2, 4, 0, "GtkComboBox is new in 2.4"],
	;

my $combo_box;

## convenience -- text
$combo_box = Gtk2::ComboBox->new_text;
isa_ok ($combo_box, 'Gtk2::ComboBox');
ginterfaces_ok($combo_box);

$combo_box->append_text ("some text");
$combo_box->append_text ("more text");
$combo_box->prepend_text ("more text");
$combo_box->prepend_text ("more text");
$combo_box->insert_text (1, "even more text");
$combo_box->insert_text (5, "even more text");
$combo_box->remove_text (0);
$combo_box->remove_text (2);

$combo_box->set_active (2);
is ($combo_box->get_active, 2);

my $model = $combo_box->get_model;
isa_ok ($model, 'Gtk2::TreeModel');

is ($model->get_path ($combo_box->get_active_iter)->to_string,
    $combo_box->get_active);

my $iter = $model->get_iter_first;
$combo_box->set_active_iter ($iter);
is ($model->get_path ($combo_box->get_active_iter)->to_string,
    $model->get_path ($iter)->to_string);

$combo_box->set_active_iter (undef);
is ($combo_box->get_active, -1);
is ($combo_box->get_active_iter, undef);

$combo_box = Gtk2::ComboBox->new;
isa_ok ($combo_box, 'Gtk2::ComboBox');
# set a model to avoid a nastygram when destroying; some versions of gtk+
# do not check for NULL before unreffing the model.
$combo_box->set_model ($model);

$combo_box = Gtk2::ComboBox->new ($model);
isa_ok ($combo_box, 'Gtk2::ComboBox');

$combo_box = Gtk2::ComboBox->new_with_model ($model);
isa_ok ($combo_box, 'Gtk2::ComboBox');

## getters and setters

$model = Gtk2::ListStore->new ('Glib::String', 'Glib::Int');
$combo_box->set_model ($model);
is ($combo_box->get_model, $model);

# get active returns -1 when nothing is selected
is ($combo_box->get_active, -1);

foreach my $t (qw(fee fie foe fum)) {
	$model->set ($model->append, 0, $t, 1, 1);
}

$combo_box->set_active (1);
is ($combo_box->get_active, 1, 'set and get active');

SKIP: {
	skip "new api in gtk+ 2.6", 12
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	my $active_path = Gtk2::TreePath->new_from_string
				("".$combo_box->get_active."");
	is ($combo_box->get_active_text,
	    $model->get ($model->get_iter ($active_path), 0),
	    'get active text');

	$combo_box->set_add_tearoffs (TRUE);
	ok ($combo_box->get_add_tearoffs, 'tearoff accessors');
	$combo_box->set_add_tearoffs (FALSE);
	ok (!$combo_box->get_add_tearoffs, 'tearoff accessors');

	$combo_box->set_focus_on_click (TRUE);
	ok ($combo_box->get_focus_on_click, 'focus-on-click accessors');
	$combo_box->set_focus_on_click (FALSE);
	ok (!$combo_box->get_focus_on_click, 'focus-on-click accessors');

	$combo_box->set_row_separator_func (sub {
		my ($model, $iter, $data) = @_;

		my $been_here = 0 if 0;
		return if $been_here++;

		isa_ok ($model, 'Gtk2::ListStore');
		isa_ok ($iter, 'Gtk2::TreeIter');
		is_deeply ($data, { something => 'else' });
	}, { something => 'else'});

	# make sure the widget is parented, realized and sized, or popup
	# and popdown will assert when they try to use combo_box's GdkWindow.
	# er, also make sure there's stuff in it.
	my $cell = Gtk2::CellRendererText->new;
	$combo_box->pack_start ($cell, TRUE);
	$combo_box->set_attributes ($cell, text => 0);
	my $window = Gtk2::Window->new;
	$window->add ($combo_box);
	$combo_box->show;
	$window->show;

	$combo_box->popup;
	$combo_box->popdown;

	$combo_box->set_wrap_width (1);
	$combo_box->set_row_span_column (1);
	$combo_box->set_column_span_column (1);

	is ($combo_box->get_wrap_width, 1);
	is ($combo_box->get_row_span_column, 1);
	is ($combo_box->get_column_span_column, 1);

	# setting undef for no model is allowed
	$combo_box->set_model (undef);
	is ($combo_box->get_model, undef, 'set_model() of undef giving undef');
}

SKIP: {
	skip "new api in gtk+ 2.10", 1
		unless Gtk2->CHECK_VERSION (2, 10, 0);

	$combo_box->set_title ("whee");
	is ($combo_box->get_title, "whee");
}

SKIP: {
	skip 'new 2.14 stuff', 1
		unless Gtk2->CHECK_VERSION(2, 14, 0);

	my $combo_box = Gtk2::ComboBox->new;
	$combo_box->set_button_sensitivity ('auto');
	is ($combo_box->get_button_sensitivity, 'auto');
}

__END__

Copyright (C) 2003-2006, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

vim: set ft=perl :
