#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.


# The Busy/Open now has the new window noticed, the same as the way
# Busy/Open/Rebusy had to be done in WidgetCursor version 1.
# 

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_name ("my_toplevel_1");
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $t2 = Gtk2::Window->new ('toplevel');
$t2->set_name ("my_toplevel_2");
$t2->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

{
  my $button = Gtk2::Button->new_with_label ("Busy");
  $button->signal_connect (clicked => sub {
                             print "$progname: busy\n";
                             Gtk2::Ex::WidgetCursor->busy;
                             $toplevel->get_display->flush;
                             sleep (2);
                           });
  $vbox->pack_start ($button, 1,1,0);
}

$toplevel->show_all;
$t2->show_all;
Gtk2->main;
exit 0;
