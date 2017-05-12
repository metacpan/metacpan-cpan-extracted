#!/usr/bin/perl -w
# vim: set ft=perl et sw=8 sts=8 :
use strict;
use Gtk2::TestHelper tests => 44, noinit => 1;

# $Id$

###############################################################################

my $model = Gtk2::TreeStore -> new("Glib::String", "Glib::Int");
isa_ok($model, "Gtk2::TreeStore");
ginterfaces_ok($model);

$model -> set_column_types("Glib::String", "Glib::Int");
is($model -> get_column_type(0), "Glib::String");
is($model -> get_column_type(1), "Glib::Int");

foreach (qw(bla blee bliii bloooo)) {
	my $iter = $model -> append(undef);
	isa_ok($iter, "Gtk2::TreeIter");

	$model -> set($iter,
		      0 => $_,
		      1 => length($_));

	#######################################################################

	foreach my $multiplier(1 .. 3) {
		my $iter_child = $model -> append($iter);
		isa_ok($iter_child, "Gtk2::TreeIter");

		$model -> set($iter_child,
			      0 => $_ x $multiplier,
			      1 => length($_ x $multiplier));

		my $iter_child_child = $model -> append($iter_child);

		$model -> set_value($iter_child_child,
                                    0 => reverse($_) x $multiplier,
                                    1 => length(reverse($_) x $multiplier));
	}
}

###############################################################################

SKIP: {
	skip("swap, move_before, move_after and reorder are new in 2.2.x", 15)
		unless Gtk2->CHECK_VERSION (2, 2, 0);

	is($model->get($model->get_iter_from_string("1:1"), 0), "bleeblee");
	is($model->get($model->get_iter_from_string("1:2"), 0), "bleebleeblee");

	$model -> swap($model -> get_iter_from_string("1:1"),
		       $model -> get_iter_from_string("1:2"));

	is($model->get($model->get_iter_from_string("1:1"), 0), "bleebleeblee");
	is($model->get($model->get_iter_from_string("1:2"), 0), "bleeblee");

	is($model -> get($model -> get_iter_from_string("0:0"), 0), "bla");

	$model -> move_before($model -> get_iter_from_string("0:0"),
			      $model -> get_iter_from_string("0:2"));

	is($model -> get($model -> get_iter_from_string("0:1"), 0), "bla");

	is($model -> get($model -> get_iter_from_string("2:2"), 0),
	   "bliiibliiibliii");

	$model -> move_after($model -> get_iter_from_string("2:2"),
			     $model -> get_iter_from_string("2:0"));

	is($model -> get($model -> get_iter_from_string("2:1"), 0),
	   "bliiibliiibliii");

	eval { $model -> reorder(undef, 3, 2, 1); };
	like($@, qr/wrong number of positions passed/);

	my $tag = $model -> signal_connect(rows_reordered => sub {
		my $new_order = $_[3];
		isa_ok($new_order, "ARRAY", "new index order");
		is_deeply($new_order, [3, 1, 2, 0]);
	});
	$model -> reorder(undef, 3, 1, 2, 0);
	$model -> signal_handler_disconnect ($tag);

	is($model -> get($model -> get_iter_from_string("0:0"), 0), "bloooo");
	is($model -> get($model -> get_iter_from_string("1:0"), 0), "blee");
	is($model -> get($model -> get_iter_from_string("2:0"), 0), "bliii");
	is($model -> get($model -> get_iter_from_string("3:0"), 0), "blabla");

	$model -> move_before($model -> get_iter_from_string("0"), undef);
	$model -> move_after($model -> get_iter_from_string("3"), undef);
}

###############################################################################

my $path_model = Gtk2::TreePath -> new_from_string("0");
my $iter_model;

# boolean return even in gtk 2.0.0
is($model -> remove($model -> get_iter($path_model)), 1);
is($model -> get($model -> get_iter($path_model), 0), "blee");

$model -> clear();

$iter_model = $model -> prepend(undef);
$model -> set($iter_model, 0 => "bla", 1 => 3);
is($model -> get($iter_model, 0), "bla");

$iter_model = $model -> insert(undef, 1);
$model -> set($iter_model, 0 => "ble", 1 => 3);
is($model -> get($iter_model, 0), "ble");

$iter_model = $model -> insert_before(undef, $model -> get_iter_from_string("1"));
$model -> set($iter_model, 0 => "bli", 1 => 3);
is($model -> get($iter_model, 0), "bli");

$iter_model = $model -> insert_after(undef, $model -> get_iter_from_string("1"));
$model -> set($iter_model, 0 => "blo", 1 => 3);
is($model -> get($iter_model, 0), "blo");

SKIP: {
  skip "iter_is_valid is new in 2.2.x", 1
    unless Gtk2->CHECK_VERSION (2, 2, 0);
    
  is($model -> iter_is_valid($iter_model), 1);
}

SKIP: {
        skip "new stuff in gtk+ 2.10", 2
                unless Gtk2->CHECK_VERSION (2, 10, 0);

        my $nrows_before = $model->iter_n_children (undef);

        my $iter = $model->insert_with_values (undef, -1);
        isa_ok ($iter, 'Gtk2::TreeIter', 'insert_with_values with no values');

        $iter = $model->insert_with_values ($iter, -1, 1, 42, 0, 'foo');
        isa_ok ($iter, 'Gtk2::TreeIter', 'insert_with_values with values');
}

###############################################################################

__END__

Copyright (C) 2003-2006, 2009 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
