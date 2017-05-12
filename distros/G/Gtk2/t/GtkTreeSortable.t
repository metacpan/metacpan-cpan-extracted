#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 5, noinit => 1;

# $Id$

my $list = Gtk2::ListStore -> new("Glib::Int");
isa_ok($list, "Gtk2::TreeSortable");

my $tree = Gtk2::ListStore -> new("Glib::Int");
isa_ok($tree, "Gtk2::TreeSortable");

my $sort = Gtk2::TreeModelSort -> new_with_model($list);
isa_ok($sort, "Gtk2::TreeSortable");

$sort -> sort_column_changed();

$sort -> set_sort_column_id(0, "ascending");
is_deeply([$sort -> get_sort_column_id()], [0, "ascending"]);

$sort -> set_sort_func(0, sub { warn @_; }, 23);
$sort -> set_default_sort_func(sub { warn @_; }, 23);

is($sort -> has_default_sort_func(), 1);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
