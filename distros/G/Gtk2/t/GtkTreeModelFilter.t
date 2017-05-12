#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 27,
  noinit => 1,
  at_least_version => [2, 4, 0, "GtkTreeModelFilter is new in 2.4"];

# $Id$

my $list = Gtk2::ListStore -> new("Glib::Int", "Glib::String");

$list -> set($list -> append(), 0 => 42);
$list -> set($list -> append(), 0 => 23);
$list -> set($list -> append(), 0 => 23);
$list -> set($list -> append(), 0 => 23);

my $filter = Gtk2::TreeModelFilter -> new($list);
isa_ok($filter, "Gtk2::TreeModelFilter");
ginterfaces_ok($filter);

# make sure the GInterfaces are set up correctly
isa_ok($filter, "Gtk2::TreeModel");
isa_ok($filter, "Gtk2::TreeDragSource");
is(Gtk2::TreeModelFilter->can('get'), Gtk2::TreeModel->can('get'),
   ' $filter->get should be Gtk2::TreeModel::get');

$filter = Gtk2::TreeModelFilter -> new($list, undef);
isa_ok($filter, "Gtk2::TreeModelFilter");

is($filter -> get_model(), $list);

my $path = Gtk2::TreePath -> new_from_string("1");
my $iter = $list -> get_iter($path);

isa_ok(my $tmp = $filter -> convert_child_iter_to_iter($iter), "Gtk2::TreeIter");
isa_ok($filter -> convert_iter_to_child_iter($tmp), "Gtk2::TreeIter");

isa_ok($tmp = $filter -> convert_child_path_to_path($path), "Gtk2::TreePath");
isa_ok($filter -> convert_path_to_child_path($tmp), "Gtk2::TreePath");

$filter -> set_visible_func(sub {
  my ($model, $iter, $data) = @_;

  is($model, $list);
  isa_ok($iter, "Gtk2::TreeIter");
  is($data, 23);

  return 1;
}, 23);

$filter -> refilter();
$filter -> clear_cache();

$filter = Gtk2::TreeModelFilter -> new($list, undef);
$filter -> set_modify_func
  (["Glib::Int", "Glib::String"],
   sub { my ($filter, $iter, $col, $userdata) = @_;
         my $path = $filter->get_path ($iter);
         if ($col == 0) {
           my ($pos) = $path->get_indices;
           return $pos * 100 + $col;
         }
         if ($col == 1) {
           return "column $col userdata $userdata path "
             . $path->to_string;
         }
       }, 12345);

is ($filter->get_value($filter->iter_nth_child(undef,2), 0),
    200);
is ($filter->get_value($filter->get_iter_first, 1),
    'column 1 userdata 12345 path 0');

$filter = Gtk2::TreeModelFilter -> new($list, Gtk2::TreePath -> new_from_string("1"));
isa_ok($filter, "Gtk2::TreeModelFilter");

$filter -> set_visible_column(0);

{
  require Scalar::Util;
  my $f = Gtk2::TreeModelFilter->new($list);
  Scalar::Util::weaken($f);
  is ($f, undef, 'destroyed by weakening');
}

__END__

Copyright (C) 2003-2009 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
