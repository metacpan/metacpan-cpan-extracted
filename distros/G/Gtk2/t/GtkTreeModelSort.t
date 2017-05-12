#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 17, noinit => 1;

# $Id$

my $list = Gtk2::ListStore -> new("Glib::Int");

$list -> set($list -> append(), 0 => 42);
$list -> set($list -> append(), 0 => 23);

my $sort = Gtk2::TreeModelSort -> new_with_model($list);
isa_ok($sort, "Gtk2::TreeModelSort");
ginterfaces_ok($sort);
is($sort -> get_model(), $list);

$sort -> set_sort_column_id(0, "ascending");

# Make sure get() always resolves to the correct method.
is($sort -> get($sort -> get_iter_from_string("0"), 0), 23);
is($sort -> get("model"), $list);

my $path = Gtk2::TreePath -> new_from_string("1");
my $iter = $list -> get_iter($path);

my $sort_path = $sort -> convert_child_path_to_path($path);
isa_ok($sort_path, "Gtk2::TreePath");
is(Gtk2::TreeModel::get($sort, $sort -> get_iter($sort_path), 0), 23);

my $sort_iter = $sort -> convert_child_iter_to_iter($iter);
isa_ok($sort_iter, "Gtk2::TreeIter");
is(Gtk2::TreeModel::get($sort, $sort_iter, 0), 23);

my $child_path = $sort -> convert_path_to_child_path($sort_path);
isa_ok($child_path, "Gtk2::TreePath");
is($list -> get($list -> get_iter($child_path), 0), 23);

my $child_iter = $sort -> convert_iter_to_child_iter($sort_iter);
isa_ok($child_iter, "Gtk2::TreeIter");
is($list -> get($child_iter, 0), 23);

$sort -> reset_default_sort_func();
$sort -> clear_cache();

SKIP: {
  skip("iter_is_valid is new in 2.2", 1)
    unless Gtk2->CHECK_VERSION (2, 2, 0);

  is($sort -> iter_is_valid($sort -> get_iter($path)), 1);
}

# other ways to construct
ok (Gtk2::TreeModelSort->new ($list), 'new with one arg');
ok (Gtk2::TreeModelSort->new (model => $list), 'new with two args');
# this should die with a usage message.
eval { $sort = Gtk2::TreeModelSort->new(); };
ok ($@, 'new with no args is an error');

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
