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


# Some experimenting with Gtk2::Entry.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $eventbox = Gtk2::EventBox->new;
$vbox->pack_start ($eventbox, 1,1,0);

my $entry = Gtk2::Entry->new;
$entry->set_name ('myentry');
$eventbox->add ($entry);

{
  my $wc = Gtk2::Ex::WidgetCursor->new (widget => $entry,
                                        cursor => 'umbrella');
  my $check = Gtk2::CheckButton->new_with_label ("Umbrella");
  $check->signal_connect
    ('notify::active' => sub {
       print "$progname: set umbrella ",$check->get_active,"\n";
       $wc->active ($check->get_active);
     });
  $vbox->pack_start ($check, 1,1,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Busy Shortly");
  $button->signal_connect
    (clicked => sub {
       Glib::Timeout->add (1000, sub {
                             print "$progname: busy\n";
                             Gtk2::Ex::WidgetCursor->busy;
                             sleep (4);
                             return 0; # stop timer
                           });
     });
  $vbox->pack_start ($button, 1,1,0);
}

$toplevel->show_all;

{
  # $win->set_cursor (Gtk2::Gdk::Cursor->new ('boat'));
  print "$progname: entry\n";
  print_windows ($entry->window);
}
sub print_windows {
  my ($win, $name) = @_;
  $name ||= '  window';
  my ($width,$height) = $win->get_size;
  my ($x,$y) = $win->get_position;
  print "$name ${width}x${height} $x,$y ",$win->get_window_type,"\n";

  $name =~ s/window/subwin/;
  $name = '  '.$name;
  foreach my $subwin ($win->get_children) {
    print_windows ($subwin, $name);
  }
}

Gtk2->main;
exit 0;
