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


# This is a bit of fun presenting all available cursor types in a combobox,
# to be set onto the label widget.
#
# It also illustrates one of the failings of the current implementation.
# Gtk2::Label is a no-window widget, as is Gtk2::ComboBox, so a WidgetCursor
# on the label would actually set the toplevel window and show on both label
# and combobox.  Putting the label in a Gtk2::EventBox creates a subwindow
# to confine its effect.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $eventbox = Gtk2::EventBox->new;
$vbox->pack_start ($eventbox, 1,1,0);
my $label = Gtk2::Label->new ("\nChoose a cursor from the list\n");
$eventbox->add ($label);

my $combobox = Gtk2::ComboBox->new_text;
$vbox->pack_start ($combobox, 1,1,0);
$combobox->append_text ('undef');
foreach my $elem (Glib::Type->list_values ('Gtk2::Gdk::CursorType')) {
  next if ($elem->{'nick'} eq 'last-cursor'  # these two not actual cursors
           || $elem->{'nick'} eq 'cursor-is-pixmap');
  $combobox->append_text ($elem->{'nick'});
}
$combobox->set_active (0);

my $widgetcursor = Gtk2::Ex::WidgetCursor->new (widget => $eventbox,
                                                active => 1);
$combobox->signal_connect
  (changed => sub {
     my $type = $combobox->get_active_text;
     $widgetcursor->cursor ($type eq 'undef' ? undef : $type);
   });

$toplevel->show_all;
Gtk2->main;
exit 0;
