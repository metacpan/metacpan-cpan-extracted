#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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


# Some experimenting with Gtk2::Combo.  The main thing to do is press "busy
# shortly" and then quickly open the combo popup to see the watch cursor is
# put on there.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub {
                             print "combo.pl: quit\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $button = Gtk2::Button->new_with_label ("Busy Shortly");
$button->signal_connect
  (clicked => sub {
     Glib::Timeout->add (1000, sub {
                           print "combo.pl: busy\n";
                           Gtk2::Ex::WidgetCursor->busy;
                           sleep (4);
                           return 0; # stop timer
                         });
   });
$vbox->pack_start ($button, 1,1,0);

my $combo = Gtk2::Combo->new;
$vbox->pack_start ($combo, 1,1,0);
$combo->set_popdown_strings ('One', 'Two', 'Three', 'Four');

$toplevel->show_all;

print "combo get_children\n";
foreach my $child ($combo->get_children) {
  print "  $child\n";
}

print "combo forall\n";
$combo->forall (sub {
                  my ($child) = @_;
                  print "  $child\n";
                });

print "list_toplevels\n";
foreach my $top (Gtk2::Window->list_toplevels) {
  print "  $top  ",$top->get_name,"\n";

  if ($top->get_name eq 'gtk-combo-popup-window') {
    foreach my $child ($top->get_children) {
      print "    $child  ",$child->get_name,"\n";
    }
  }
}

Gtk2->main;
exit 0;
