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
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-MenuView.  If not, see <http://www.gnu.org/licenses/>.


# This contrivance shows how displayed menu items update when model data
# changes, in this case a twirling char and a clock.  The extra tearoff item
# lets you keep it open to look at.


use strict;
use warnings;
use Gtk2 '-init';
use POSIX ();
use Gtk2::Ex::MenuView;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $menubar = Gtk2::MenuBar->new;
$toplevel->add ($menubar);

my $baritem = Gtk2::MenuItem->new_with_label ('Click to Popup');
$menubar->add ($baritem);

#----------------------------------------------------------------------------
my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('One',
                 'Two',
                 'Three') {
  $liststore->set ($liststore->append, 0 => $str);
}

my $menuview = Gtk2::Ex::MenuView->new (model => $liststore);
$baritem->set_submenu ($menuview);
$menuview->signal_connect (item_create_or_update => \&my_create_or_update);
$menuview->signal_connect (activate => \&my_item_activate);

sub my_create_or_update {
  my ($menuview, $item, $model, $path, $iter) = @_;
  $item ||= Gtk2::MenuItem->new_with_label ('');
  my $str = $model->get ($iter, 0);  # column 0
  $item->get_child->set_text ($str);  # the Gtk2::Label child widget
  return $item;
}

sub my_item_activate {
  my ($menuview, $item, $model, $path, $iter) = @_;
  print "activate, path=",$path->to_string,"\n";
}

my $tearoff = Gtk2::TearoffMenuItem->new;
$tearoff->show;
$menuview->prepend ($tearoff);

#----------------------------------------------------------------------------
my @one_n_str = ('One /', 'One -', 'One \\', 'One |');
my $one_n = 0;
sub one_callback {
  $one_n++;
  $one_n %= scalar(@one_n_str);
  $liststore->set_value ($liststore->iter_nth_child (undef,0),
                         0, $one_n_str[$one_n]);
  return 1; # Glib::SOURCE_CONTINUE
}
one_callback();                            # initial time display
Glib::Timeout->add (500, \&one_callback); # periodic updates

#----------------------------------------------------------------------------
sub two_callback {
  my $str = POSIX::strftime ("Time %H:%M:%S", localtime(time()));
  $liststore->set_value ($liststore->iter_nth_child(undef,1), 0, $str);
  return 1; # Glib::SOURCE_CONTINUE
}
two_callback();                            # initial time display
Glib::Timeout->add (1000, \&two_callback); # periodic updates


#----------------------------------------------------------------------------
$toplevel->show_all;
Gtk2->main;
exit 0;
