#!/usr/bin/perl -w

# $Id$

###############################################################################

use Gtk2::TestHelper tests => 29;

###############################################################################

my $model = Gtk2::ListStore -> new("Glib::String");
my $view = Gtk2::TreeView -> new($model);

my $renderer = Gtk2::CellRendererText -> new();
my $column = Gtk2::TreeViewColumn -> new_with_attributes(
				       "Hmm",
				       $renderer,
				       text => 0);

$view -> append_column($column);

foreach (qw(bla ble bli blo blu)) {
	$model -> set($model -> append(), 0 => $_);
}

###############################################################################

my $selection = $view -> get_selection();
isa_ok($selection, "Gtk2::TreeSelection");

$selection -> select_path(Gtk2::TreePath -> new_from_string(0));

###############################################################################

$selection -> set_mode("browse");
ok($selection -> get_mode() eq "browse");

###############################################################################

isa_ok($selection -> get_tree_view(), "Gtk2::TreeView");

###############################################################################

my ($tmp_model, $tmp_iter) = $selection -> get_selected();
isa_ok($tmp_model, "Gtk2::ListStore");
isa_ok($tmp_iter, "Gtk2::TreeIter");

is($tmp_model -> get($tmp_iter, 0), "bla");

isa_ok($selection -> get_selected(), "Gtk2::TreeIter");

###############################################################################

isa_ok($selection -> get_selected_rows(), "Gtk2::TreePath");

###############################################################################

is($selection -> count_selected_rows(), 1);

my $path = Gtk2::TreePath -> new_from_string(1);

$selection -> select_path($path);
ok($selection -> path_is_selected($path));

$selection -> unselect_path($path);
ok(not $selection -> path_is_selected($path));

###############################################################################

my $iter = $model -> get_iter($path);

is($model -> get($iter, 0), "ble");

$selection -> select_iter($iter);
ok($selection -> iter_is_selected($iter));

$selection -> unselect_iter($iter);
ok(not $selection -> iter_is_selected($iter));

###############################################################################

$selection -> set_mode("multiple");

$selection -> select_all();
is($selection -> count_selected_rows(), 5);

$selection -> unselect_all();
is($selection -> count_selected_rows(), 0);

my $path_start = Gtk2::TreePath -> new_from_string(3);
my $path_end = Gtk2::TreePath -> new_from_string(4);

$selection -> select_range($path_start, $path_end);
is($selection -> count_selected_rows(), 2);

SKIP: {
	skip("unselect_range is new in 2.2.x", 1)
		unless Gtk2->CHECK_VERSION (2, 2, 0);

	$selection -> unselect_range($path_start, $path_end);
	is($selection -> count_selected_rows(), 0);
}

###############################################################################

$selection -> unselect_all();

is($selection -> get_user_data(), undef);

$selection -> set_select_function(sub {
	my ($selection, $model, $path, $selected) = @_;

	isa_ok($selection, "Gtk2::TreeSelection");
	isa_ok($model, "Gtk2::ListStore");
	isa_ok($path, "Gtk2::TreePath");

	return 0;
});
is($selection -> get_user_data(), undef);

$selection -> select_path(Gtk2::TreePath -> new_from_string(1));
is($selection -> count_selected_rows(), 0);

$selection -> set_select_function(sub { return 1; }, "bla");
is($selection -> get_user_data(), "bla");

###############################################################################

$selection -> select_path(Gtk2::TreePath -> new_from_string(1));

$selection -> selected_foreach(sub {
	my ($model, $path, $iter) = @_;

	is($model -> get($iter, 0), "ble");

	isa_ok($model, "Gtk2::ListStore");
	isa_ok($path, "Gtk2::TreePath");
	isa_ok($iter, "Gtk2::TreeIter");
});

###############################################################################

run_main;

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
