#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::TreeViewBits;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $scrolled = Gtk2::ScrolledWindow->new;
$vbox->pack_start ($scrolled, 1,1,0);

my $model = Gtk2::TreeStore->new ('Glib::String');
my $n = 1;
foreach my $top ('abc', 'def', 'ghi') {
  my $top_iter = $model->append(undef);
  $model->set ($top_iter, 0 => $top);
  foreach my $mid ('foo', 'bar', 'quux') {
    my $mid_iter = $model->append($top_iter);
    $model->set ($mid_iter, 0 => $mid);
    foreach my $i (1 .. 20) {
      my $str = "number $n";
      if ($n == 2) {
        $str .= "jdsk\njsk\nsjk\nsjk\nsjk\nsjk\nfsjk\nsjk\nsjk\nsjk\nfsjdk\n";
      }
      $model->set ($model->append($mid_iter), 0 => $str);
      $n++;
    }
  }
}

my $treeview = Gtk2::TreeView->new_with_model ($model);
$treeview->set (reorderable       => 1,
                fixed_height_mode => 1,
                headers_visible   => 0);
$treeview->collapse_all;
$treeview->expand_row (Gtk2::TreePath->new_from_indices(1), 0);
$scrolled->add ($treeview);

my $column = Gtk2::TreeViewColumn->new;
$column->set (sizing => 'fixed');
$treeview->append_column ($column);

my $renderer = Gtk2::CellRendererText->new;
#$renderer->set_fixed_height_from_font (1);
$column->pack_start ($renderer, 1);
$column->add_attribute ($renderer, text => 0);

{
  my $button = Gtk2::Button->new_with_label ("to big");
  $button->signal_connect
    (clicked => sub {
       print "$progname: to big\n";
       my $path = Gtk2::TreePath->new_from_indices (0,0,1);
       Gtk2::Ex::TreeViewBits::scroll_cursor_to_path ($treeview, $path);
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("to ord");
  $button->signal_connect
    (clicked => sub {
       print "$progname: to big\n";
       my $path = Gtk2::TreePath->new_from_indices (1,0,2);
       Gtk2::Ex::TreeViewBits::scroll_cursor_to_path ($treeview, $path);
     });
  $vbox->pack_start ($button, 0,0,0);
}

sub model_last_path {
  my ($model) = @_;
  my $iter = undef;
  for (;;) {
    $n = $model->iter_n_children($iter);
    if (! $n) {
      return $model->get_path($iter);
    }
    $iter = $model->iter_nth_child($iter,$n-1)
      // die "oops, no sub-row at ",$n-1;
  }
}

{
  my $button = Gtk2::Button->new_with_label ("to end");
  $button->signal_connect
    (clicked => sub {
       my $path = model_last_path($model);
       print "$progname: to end ",$path->to_string,"\n";
       Gtk2::Ex::TreeViewBits::scroll_cursor_to_path ($treeview, $path);
     });
  $vbox->pack_start ($button, 0,0,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
