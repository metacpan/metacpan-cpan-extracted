#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 75, noinit => 1;

# $Id$

###############################################################################

my $model = Gtk2::ListStore -> new("Glib::String", "Glib::Int");
isa_ok($model, "Gtk2::TreeModel");
ok($model -> get_flags() == ["iters-persist", "list-only"]);

$model = Gtk2::TreeStore -> new("Glib::String", "Glib::Int");
isa_ok($model, "Gtk2::TreeModel");
ok($model -> get_flags() == ["iters-persist"]);

my $count = $model -> get_n_columns();
is($count, 2);

is($model -> get_column_type(0), "Glib::String");
is($model -> get_column_type(1), "Glib::Int");

###############################################################################

foreach (qw(bla blee bliii bloooo)) {
	my $iter = $model -> append(undef);
	isa_ok($iter, "Gtk2::TreeIter");

	$model -> set($iter,
		      0 => $_,
		      1 => length($_));

	is($model -> get($iter, 0), $_);
	is($model -> get($iter, 1), length($_));

	is(($model -> get($iter, 0, 1))[0], $_);
	is(($model -> get($iter, 0, 1))[1], length($_));

	is($model -> get_value($iter, 0), $_);
	is($model -> get_value($iter, 1), length($_));

	#######################################################################

	foreach my $multiplier(1 .. 3) {
		my $iter_child = $model -> append($iter);

		$model -> set($iter_child,
			      0 => $_ x $multiplier,
			      1 => length($_ x $multiplier));

		my $iter_child_child = $model -> append($iter_child);

		$model -> set($iter_child_child,
			      0 => reverse($_) x $multiplier,
			      1 => length(reverse($_) x $multiplier));
	}
}

###############################################################################

SKIP: {
	skip("there doesn't seem to be a GType for GtkTreeRowReference in 2.0.x", 5)
		unless Gtk2 -> CHECK_VERSION(2, 2, 0);

	my ($ref_one, $ref_two, $ref_path);

	$ref_one = Gtk2::TreeRowReference -> new($model, Gtk2::TreePath -> new_from_string("0"));
	isa_ok($ref_one, "Gtk2::TreeRowReference");
	is($ref_one -> valid(), 1);

	$ref_path = $ref_one -> get_path();
	is($ref_path -> to_string(), "0");

	$ref_two = $ref_one -> copy();
	is($ref_two -> valid(), 1);

	SKIP: {
		skip("new 2.8 stuff", 1)
			unless Gtk2 -> CHECK_VERSION(2, 8, 0);

		is($ref_one -> get_model(), $model);
	}
}

###############################################################################

$model -> ref_node($model -> get_iter_first());
$model -> unref_node($model -> get_iter_first());

$model -> foreach(sub {
	my ($model, $path, $iter) = @_;

	isa_ok($model, "Gtk2::TreeStore");
	isa_ok($path, "Gtk2::TreePath");
	isa_ok($iter, "Gtk2::TreeIter");

	return 1;
});

###############################################################################

my ($path_one, $path_two);

$path_one = Gtk2::TreePath -> new();
isa_ok($path_one, "Gtk2::TreePath");

$path_one = Gtk2::TreePath -> new_from_string("0");
is($path_one -> to_string(), "0");

$path_one = Gtk2::TreePath -> new_first();
is($path_one -> to_string(), "0");

$path_two = $path_one -> copy();
is($path_one -> compare($path_two), 0);

$path_one = Gtk2::TreePath -> new("1");

SKIP: {
	skip("new_from_indices is new in 2.2.x", 1)
		unless Gtk2->CHECK_VERSION (2, 2, 0);

	$path_one = Gtk2::TreePath -> new_from_indices(1);
	is($model -> get($model -> get_iter($path_one), 0), "blee");
}

$path_one -> prepend_index(1);
is($model -> get($model -> get_iter($path_one), 0), "bleeblee");

$path_one -> append_index(0);
is($model -> get($model -> get_iter($path_one), 0), "eelbeelb");

is($path_one -> get_depth(), 3);
is_deeply([$path_one -> get_indices()], [1, 1, 0]);

$path_two = Gtk2::TreePath -> new("1:1");

$path_two -> down();
is($path_two -> to_string(), "1:1:0");

is($path_two -> up(), 1);
is($path_two -> to_string(), "1:1");

is($path_two -> is_ancestor($path_one), 1);
is($path_one -> is_descendant($path_two), 1);

$path_two -> next();
is($path_two -> to_string(), "1:2");

is($path_two -> prev(), 1);
is($path_two -> to_string(), "1:1");

###############################################################################

my $iter;

$iter = $model -> get_iter(Gtk2::TreePath -> new_from_string("0"));
isa_ok($iter, "Gtk2::TreeIter");
is($model -> get_path($iter) -> to_string(), "0");

$iter = $model -> get_iter_from_string("0");
is($model -> get_path($iter) -> to_string(), "0");

$iter = $model -> get_iter_first();
is($model -> get_path($iter) -> to_string(), "0");

my $next = $model -> iter_next($iter);
is($model -> get_path($iter) -> to_string(), "0");
is($model -> get_path($next) -> to_string(), "1");

SKIP: {
	skip("get_string_from_iter is new in 2.2.x", 1)
		unless Gtk2->CHECK_VERSION (2, 2, 0);

	is($model -> get_string_from_iter($iter), "0");
}

###############################################################################

my ($iter_one, $iter_two);

$iter_one = $model -> get_iter(Gtk2::TreePath -> new("2:2"));

$iter_two = $model -> iter_parent($iter_one);
is($model -> get($iter_two, 0), "bliii");

is($model -> iter_has_child($iter_two), 1);
is($model -> iter_n_children($iter_two), 3);

$iter_one = $model -> iter_nth_child($iter_two, 1);
is($model -> get($iter_one, 0), "bliiibliii");

$iter_two = $model -> iter_children($iter_one);
is($model -> get($iter_two, 0), "iiilbiiilb");

###############################################################################

$model -> row_changed($path_one, $iter_one);
$model -> row_inserted($path_one, $iter_one);
$model -> row_has_child_toggled($path_one, $iter_one);
$model -> row_deleted($path_one);

# Ensure that both spellings of the signal name get the custom marshaller.
foreach my $signal_name (qw/rows_reordered rows-reordered/) {
	my $id = $model -> signal_connect($signal_name => sub {
		is_deeply($_[3], [3, 2, 1, 0], $signal_name);
	});
	$model -> rows_reordered($path_one, undef, 3, 2, 1, 0);
	$model -> signal_handler_disconnect($id);
}

###############################################################################

# Ensure that getting all values of a row in a 1-column model does not result
# in a stack handling error with perl >= 5.23.
{
	my $model = Gtk2::ListStore -> new(qw/Glib::Int/);
	my $iter = $model -> append();
	$model -> set($iter, 0 => 23);
	is ($model -> get($iter), 23);
}

###############################################################################

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
