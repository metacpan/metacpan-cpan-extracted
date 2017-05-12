#!/usr/bin/perl -w
use Gtk2::TestHelper tests => 47;

# $Id$

###############################################################################

my $model = Gtk2::ListStore -> new("Glib::String", "Glib::Int");
isa_ok($model, "Gtk2::ListStore");
ginterfaces_ok($model);

$model -> set_column_types("Glib::String", "Glib::Int");
is($model -> get_column_type(0), "Glib::String");
is($model -> get_column_type(1), "Glib::Int");

foreach (qw(bla blee bliii bloooo)) {
	my $iter = $model -> append();
	isa_ok($iter, "Gtk2::TreeIter");

	$model -> set($iter,
		      0 => $_,
		      1 => length($_));

	$model -> set_value($iter,
                            0 => $_,
                            1 => length($_));
}

###############################################################################

my $path_model = Gtk2::TreePath -> new_from_string("0");
my $iter_model;

# boolean return even in gtk 2.0.0
ok($model -> remove($model -> get_iter($path_model)));
is($model -> get($model -> get_iter($path_model), 0), "blee");

$model -> clear();

$iter_model = $model -> prepend();
$model -> set($iter_model, 0 => "bla", 1 => 3);
is($model -> get($iter_model, 0), "bla");

$iter_model = $model -> insert(1);
$model -> set($iter_model, 0 => "ble", 1 => 3);
is($model -> get($iter_model, 0), "ble");

$iter_model = $model -> insert_before($model -> get_iter_from_string("1"));
$model -> set($iter_model, 0 => "bli", 1 => 3);
is($model -> get($iter_model, 0), "bli");

$iter_model = $model -> insert_after($model -> get_iter_from_string("1"));
$model -> set($iter_model, 0 => "blo", 1 => 3);
is($model -> get($iter_model, 0), "blo");

###############################################################################

SKIP: {
	skip("swap, move_before, move_after and reorder are new in 2.2.x", 11)
		unless Gtk2->CHECK_VERSION (2, 2, 0);


	$model -> swap($model -> get_iter_from_string("1"),
		       $model -> get_iter_from_string("2"));

	is($model -> get($model -> get_iter_from_string("1"), 0), "blo");
	is($model -> get($model -> get_iter_from_string("2"), 0), "bli");

	$model -> move_before($model -> get_iter_from_string("1"),
			      $model -> get_iter_from_string("3"));

	is($model -> get($model -> get_iter_from_string("2"), 0), "blo");

	$model -> move_after($model -> get_iter_from_string("3"),
			     $model -> get_iter_from_string("0"));

	is($model -> get($model -> get_iter_from_string("1"), 0), "ble");

	eval { $model -> reorder(3, 2, 1); };
	like($@, qr/wrong number of positions passed/);

	my $tag = $model -> signal_connect(rows_reordered => sub {
		my $new_order = $_[3];
		isa_ok($new_order, "ARRAY", "new index order");
		is_deeply($new_order, [3, 2, 1, 0]);
	});
	$model -> reorder(3, 2, 1, 0);
	$model -> signal_handler_disconnect ($tag);

	is($model -> get($model -> get_iter_from_string("0"), 0), "blo");
	is($model -> get($model -> get_iter_from_string("1"), 0), "bli");
	is($model -> get($model -> get_iter_from_string("2"), 0), "ble");
	is($model -> get($model -> get_iter_from_string("3"), 0), "bla");

	$model -> move_before($model -> get_iter_from_string("0"), undef);
	$model -> move_after($model -> get_iter_from_string("3"), undef);
}

###############################################################################
# Ross' 05.GtkListStore-etc.t.  I did not have the heart to simply merge both
# tests.

my @cols = (
		{ title => 'Author', type => 'Glib::String',  },
		{ title => 'Work',   type => 'Glib::String',  },
		{ title => 'Sold',   type => 'Glib::Uint',    },
		{ title => 'Print',  type => 'Glib::Boolean', },
	);

ok (my $store = Gtk2::ListStore->new (map {$_->{type}} @cols), 'new liststore');

$store->set_column_types (map {$_->{type}} @cols);
ok (1, '$store->set_column_types');

my @data = (
	{ Author => 'John Doe', Work => 'Who am I', Sold => '32', Print => 0 },
	{ Author => 'John Doe', Work => 'Who am I', Sold => '44', Print => 1 },
);

foreach (@data)
{
	my $iter = $store->append;
	$store->set($iter,
		1, $_->{Work},
		0, $_->{Author},
		2, $_->{Sold},
		3, $_->{Print} );
	ok (eq_array ([$store->get ($iter)], 
		      [$_->{Author}, $_->{Work}, $_->{Sold}, $_->{Print},]),
		'$store->set/get');
}

my $iter;
ok ($iter = $store->insert (0), '$store->insert (5)');
ok ($iter = $store->insert (0), '$store->insert (0)');
ok ($iter = $store->insert_before ($iter), '$store->insert_before');
ok ($iter = $store->insert_after ($iter), '$store->insert_after');
ok ($iter = $store->get_iter_first, '$store->get_iter_first, treemodel');
ok ($store->remove ($iter), '$store->remove 1');
ok ($iter = $store->prepend, '$store->prepend');
ok ($store->remove ($iter), '$store->remove 2');

SKIP: {
    # on RH8 with 2.0.6, i get a crash from pango xft, complaining that
    # there's no display.  xft does require an x server...  later versions
    # don't use xft and appear to be fine without a display.
    skip "can't create a treeview on 2.0.x without a display", 7
	unless Gtk2->CHECK_VERSION (2, 2, 0) or Gtk2->init_check;

    ok (my $tree = Gtk2::TreeView->new_with_model($store), 'new treeview');

    my $renderer;
    my $column;
    my $i = 0;
    foreach (@cols)
    {
	if( $_->{type} =~ /Glib::String/ )
	{
		$renderer = Gtk2::CellRendererText->new;
		$column = Gtk2::TreeViewColumn->new_with_attributes(
			$_->{title}, $renderer, text => $i );
		$tree->append_column($column);
	}
	elsif( $_->{type} =~ /Glib::Uint/ )
	{
		$renderer = Gtk2::CellRendererText->new;
		$column = Gtk2::TreeViewColumn->new_with_attributes(
			$_->{title}, $renderer, text =>  $i );
		$tree->append_column($column);
	}
	elsif( $_->{type} =~ /Glib::Boolean/ )
	{
  		$renderer = Gtk2::CellRendererToggle->new;
		$column = Gtk2::TreeViewColumn->new_with_attributes(
			$_->{title}, $renderer, active =>  $i );
		$tree->append_column($column);
	}
	$i++;
    }

    run_main sub {
		SKIP: {
			skip 'function only in version > 2.2', 5
				unless Gtk2->CHECK_VERSION (2, 2, 0);
			$store->reorder(4, 3, 2, 1, 0);
			$iter = $store->get_iter_first;
			ok ($store->iter_is_valid ($iter), 
				'$store->iter_is_valid');
			is_deeply ([$store->get ($iter), 
				    $store->get ($store->iter_next($iter))],
				   ['John Doe', 'Who am I', 44, 1,
				    'John Doe', 'Who am I', 32, 0], 
			       '$store->reorder worked');
			$store->swap ($iter, $store->iter_next($iter));
			$iter = $store->get_iter_first;
			is_deeply ([$store->get ($iter), 
				    $store->get ($store->iter_next($iter))],
				   ['John Doe', 'Who am I', 32, 0,
				    'John Doe', 'Who am I', 44, 1],
			       '$store->swap worked');
			$iter = $store->get_iter_first;
			$store->move_before ($iter, undef);
			is_deeply ([$store->get 
					($store->iter_nth_child(undef, 4))],
				   ['John Doe', 'Who am I', 32, 0], 
			       '$store->move_before worked');
			$store->move_after ($iter, $store->get_iter_first);
			is_deeply ([$store->get 
				      ($store->iter_nth_child(undef, 1))],
				   ['John Doe', 'Who am I', 32, 0], 
			       '$store->move_after worked');
		}
		$store->clear;
		ok ($store->iter_n_children == 0, 
			'$store->clear/iter_n_children');
	};
}

SKIP: {
	skip "new stuff in gtk+ 2.6", 3
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	my $nrows_before = $store->iter_n_children;

	my $iter = $store->insert_with_values (-1);
	isa_ok ($iter, 'Gtk2::TreeIter', 'insert_with_values with no values');

	$iter = $store->insert_with_values (-1, 0, 'foo', 3, TRUE, 2, 42);
	isa_ok ($iter, 'Gtk2::TreeIter', 'insert_with_values with values');

	is ($store->iter_n_children, $nrows_before + 2,
	    'added expected number of rows');
}

__END__

Copyright (C) 2003-2005, 2009 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
