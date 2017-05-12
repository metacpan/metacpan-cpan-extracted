#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-MenuView.
#
# Gtk2-Ex-MenuView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-MenuView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;
use Data::Dumper;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel->add ($hbox);

my $left_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($left_vbox, 0,0,0);

my $right_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($right_vbox, 1,1,0);

my $model = Gtk2::TreeStore->new ('Glib::String');
foreach my $str ('Item one',
                 'Item two',
                 'Item three',
                 'Item four',
                 'Item five') {
  $model->insert_with_values (undef, 9999, 0 => $str);
}
{
  my $iter = $model->iter_nth_child (undef, 2);
  $model->insert_with_values ($iter, 9999, 0 => 'Subitem one');
  $model->insert_with_values ($iter, 9999, 0 => 'Subitem two');
}

my $menu = Gtk2::Ex::MenuView->new (model => $model);
$menu->signal_connect (item_create_or_update => \&item_create);
sub item_create {
  my ($menu, $item, $model, $path, $iter) = @_;
  print "$progname: item_create at ",$path->to_string,"\n";
  if ($item) { return $item; }

  my $cellview = Gtk2::CellView->new;
  $cellview->set_model ($model);
  $cellview->set_displayed_row ($path);
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 1); # right align
  $cellview->pack_start ($renderer, 1);
  $cellview->add_attribute ($renderer, text => 0);

  $item = Gtk2::MenuItem->new;
  $item->add ($cellview);
  return $item;
}
$menu->signal_connect (separator_create_or_update => \&separator_create);
sub separator_create {
  my ($menu, $separator, $model, $path, $iter) = @_;
  if ($path->get_depth == 1) {
    my $i = ($path->get_indices)[0];
    if (($i % 2) == 1) {
      print "$progname: separator_create at 0\n";
      my $item = Gtk2::SeparatorMenuItem->new;
      $item->show;
      return $item;
    }
  }
  return undef;
}
$menu->signal_connect (activate => sub {
                         my ($menu, $item, $model, $path, $iter) = @_;
                         print "$progname: activate path ",
                           $path->to_string,"\n";
                       });

my $tearoff = Gtk2::TearoffMenuItem->new;
$menu->prepend ($tearoff);

{
  my $treeview = Gtk2::TreeView->new_with_model ($model);
  $treeview->set (reorderable => 1);
  $right_vbox->pack_start ($treeview, 1,1,0);

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (editable => 1);
  $renderer->signal_connect
    (edited => sub {
       print Dumper(\@_);
       my ($renderer, $pathstr, $newstr) = @_;
       my $path = Gtk2::TreePath->new_from_string ($pathstr);
       my $iter = $model->get_iter ($path);
       $model->set_value ($iter, 0 => $newstr);
     });

  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("TreeView:", $renderer, text => 0);
  $column->set (resizable => 1);
  $treeview->append_column ($column);
}

{
  my $menubar = Gtk2::MenuBar->new;
  $left_vbox->pack_start ($menubar, 0,0,0);
  my $item = Gtk2::MenuItem->new_with_label ('Menu');
  $item->set_submenu ($menu);
  $menubar->add ($item);
}
{
  my $label = Gtk2::Label->new (' ');
  $left_vbox->add ($label);
}
{
  my $button = Gtk2::Button->new_with_label ('Insert');
  $button->signal_connect
    (clicked => sub {
       $model->insert_with_values (undef, 99999, 0 => rand());
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Change 2');
  $button->signal_connect
    (clicked => sub {
       my $iter = $model->iter_nth_child (undef, 1);
       $model->set ($iter, 0, 'x' . $model->get($iter,0));
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Insert 2');
  $button->signal_connect
    (clicked => sub {
       $model->insert_with_values (undef, 1, 0 => rand());
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Delete');
  $button->signal_connect
    (clicked => sub {
       my $iter = $model->get_iter (Gtk2::TreePath->new(2));
       if ($iter) { $model->remove ($iter); }
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Reorder Up');
  $button->signal_connect
    (clicked => sub {
       my $len = $model->iter_n_children (undef);
       my $end = $len - 1;
       $model->reorder (undef, 1 .. $end, 0);  # rotate
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Reorder Down');
  $button->signal_connect
    (clicked => sub {
       my $len = $model->iter_n_children (undef);
       my $end = $len - 1;
       $model->reorder (undef, $end, 0 .. $end-1); # rotate
     });
  $left_vbox->pack_start ($button, 0,0,0);
}

$menu->popup (undef, undef, undef, undef, 0, 0);

$toplevel->show_all;
Gtk2->main;
exit 0;
