#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TreeModelFilter-DragDest.
#
# Gtk2-Ex-TreeModelFilter-DragDest is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# Gtk2-Ex-TreeModelFilter-DragDest is distributed in the hope that it will
# be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TreeModelFilter-DragDest.  If not, see
# <http://www.gnu.org/licenses/>.


use 5.010;
use strict;
use warnings;
use Gtk2;
use Data::Dumper;

{
  package MyNewFilterModel;
  use strict;
  use warnings;
  use Gtk2;
  use base 'Gtk2::Ex::TreeModelFilter::DragDest';

  use Glib::Object::Subclass
    Gtk2::TreeModelFilter::,
        interfaces => [ 'Gtk2::TreeDragDest' ];

}

my $tree = Gtk2::TreeStore->new ('Glib::String');
{ my $top = $tree->insert_after (undef, undef);
  my $sub = $tree->insert_after ($top, undef);
  $tree->set ($sub, 0 => 123);
}

my $store2 = Gtk2::ListStore->new ('Glib::String');
$store2->insert_with_values (0, 0=>456);

my $virtual_root = Gtk2::TreePath->new_from_indices (0);
my $filter = MyNewFilterModel->new (child_model => $tree,
                                    virtual_root => $virtual_root);

my $overfil = MyNewFilterModel->new (child_model => $filter);

print "$tree\n$store2\n$filter\n$overfil\n\n";

{
  my $path = Gtk2::TreePath->new_from_indices (0);
  my $sel = $tree->drag_data_get ($path);
  print "drag_data_get ",$sel//'undef',"\n";
  { my ($src_model, $src_path) = $sel->get_row_drag_data;
    print "  src_model=$src_model src_path=",
      $src_path->to_string,"\n";
  }

  print "row_drop_possible ",
    $tree->row_drop_possible($path,$sel) ? "yes" : "no", "\n";
  print "row_drop_possible ",
    $store2->row_drop_possible($path,$sel) ? "yes" : "no", "\n";
  print "row_drop_possible ",
    $filter->row_drop_possible($path,$sel) ? "yes" : "no", "\n";
}

print "\n";
{
  my $path = Gtk2::TreePath->new_from_indices (0);
  my $sel = $overfil->drag_data_get ($path);
  print "drag_data_get ",$sel//'undef',"\n";
  { my ($src_model, $src_path) = $sel->get_row_drag_data;
    print "  src_model=$src_model src_path=",
      $src_path->to_string,"\n";
  }

  print "row_drop_possible ",
    $tree->row_drop_possible($path,$sel) ? "yes" : "no", "\n";
  print "row_drop_possible ",
    $store2->row_drop_possible($path,$sel) ? "yes" : "no", "\n";
  print "row_drop_possible ",
    $filter->row_drop_possible($path,$sel) ? "yes" : "no", "\n";
}

exit 0;
