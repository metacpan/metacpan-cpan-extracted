#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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


use strict;
use warnings;
use Gtk2 '-init';
use POSIX ();

use FindBin;
my $progname = $FindBin::Script;

my $liststore = Gtk2::ListStore->new ('Glib::String');
$liststore->set ($liststore->append, 0 => 'Item one');

my $cellview = Gtk2::CellView->new;
$cellview->set_model ($liststore);
$cellview->set_displayed_row (Gtk2::TreePath->new_from_indices(0));

my $renderer = Gtk2::CellRendererText->new;
$cellview->pack_start ($renderer, 1);
$cellview->add_attribute ($renderer, markup => 0);  # from column 0


sub timer_callback {
  my $str = POSIX::strftime ("Time <tt>%H:%M:%S</tt>", localtime(time()));
  print "$progname: $str\n";
  $liststore->set_value ($liststore->iter_nth_child(undef,0), 0, $str);
#  $cellview->set_displayed_row (Gtk2::TreePath->new_from_indices(0));
  return 1; # Glib::SOURCE_CONTINUE
}
timer_callback();                            # initial time display
Glib::Timeout->add (1000, \&timer_callback); # periodic updates

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->add ($cellview);

$toplevel->show_all;
Gtk2->main;
exit 0;
