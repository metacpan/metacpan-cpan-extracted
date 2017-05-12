#!/usr/bin/perl -w

# Copyright 2009, 2010, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./treeview-toggle-expand.pl
#
# This is a typical use for Gtk2::Ex::TreeViewBits::toggle_expand_row() in
# the 'row-activated' handler of a TreeView.
#
# Press "Ret" or click the mouse anywhere in a row to toggle the expand, not
# just in the expander arrow bits at the left.
#
# You can always click on the expander bits of a TreeView to expand or
# collapse parent rows.  The idea here is to get the same effect on
# double-clicking the rest of the row too.  The operative part is
# my_row_activated_handler().
#
# This sort of thing is good if the tree contents are read-only.  If they're
# editable then you probably want to leave double-click to start an edit in
# the usual way.
#
# The "$open_all" parameter to toggle_expand_row() is omitted here, so an
# expand just expands to the immediate children of a row.  If that parameter
# is true then an expand expands everything under the given row.  In a deep
# tree model that might be a lot of rows.  You could be creative and only do
# it only to the second-last level, or something like that.
#

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::TreeViewBits;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $model = Gtk2::TreeStore->new ('Glib::String');
my $n = 1;
foreach my $top ('abc', 'def', 'ghi') {
  my $top_iter = $model->append(undef);
  $model->set ($top_iter, 0 => $top);
  foreach my $mid ('foo', 'bar', 'quux') {
    my $mid_iter = $model->append($top_iter);
    $model->set ($mid_iter, 0 => $mid);
    foreach my $i (1 .. 3) {
      $model->set ($model->append($mid_iter), 0 => "number $n");
      $n++;
    }
  }
}

my $treeview = Gtk2::TreeView->new_with_model ($model);
$treeview->set (reorderable       => 1,
                headers_visible   => 0);
$treeview->collapse_all;
$treeview->expand_row (Gtk2::TreePath->new_from_indices(1), 0);
$toplevel->add ($treeview);

my $column = Gtk2::TreeViewColumn->new;
$treeview->append_column ($column);

my $renderer = Gtk2::CellRendererText->new;
$column->pack_start ($renderer, 1);
$column->add_attribute ($renderer, text => 0);

$treeview->signal_connect
  (row_activated => \&my_row_activated_handler);

sub my_row_activated_handler {
  my ($treeview, $path, $treeviewcolumn) = @_;

  my $iter = $model->get_iter($path);
  if ($model->iter_has_child($iter)) {
    # clicked on a heading row
    Gtk2::Ex::TreeViewBits::toggle_expand_row ($treeview, $path);
  } else {
    # clicked on a leaf row
    print "You chose ",$model->get($iter,0),"\n";
  }
}

$toplevel->show_all;
Gtk2->main;
exit 0;
