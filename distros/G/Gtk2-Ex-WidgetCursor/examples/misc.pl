#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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


# This is a miscellaneous contrivance showing three WidgetCursors variously
# acting.  There's a base cursor starting undef or settable to a boat or
# umbrella, then a "heart" on and off under a timer, and a button drag
# cursor.  A button for the Gtk2::Ex::WidgetCursor->busy mechanism shows how
# it trumps them all (in this case for a 3 second sleep()).
#
# There's no priority level settings, we instead use the rule that the
# newest created has precedence (among equal priorities).  This means the
# heart trumps the base, and the button drag cursor which is created
# on-demand is the newest of all three when it exists.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_default_size (300, 200);

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel->add ($hbox);

my $vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($vbox, 0,0,0);

my $layout = Gtk2::Layout->new;
$layout->set_size_request (200, 100);
$hbox->pack_start ($layout, 1,1,0);

my $label = Gtk2::Label->new ("Drag Here");
$layout->put ($label, 0,0);

my $base_cursor = Gtk2::Ex::WidgetCursor->new (widget => $layout,
                                               active => 1);
my $heart_cursor = Gtk2::Ex::WidgetCursor->new (widget => $layout,
                                                cursor => 'heart');
my $drag_cursor;

my $boat_button = Gtk2::Button->new_with_label ("Boat");
$boat_button->signal_connect (clicked => sub {
                                $base_cursor->cursor('boat') });
$vbox->pack_start ($boat_button, 0,0,0);

my $umbrella_button = Gtk2::Button->new_with_label ("Umbrella");
$umbrella_button->signal_connect (clicked => sub {
                                    $base_cursor->cursor('umbrella')});
$vbox->pack_start ($umbrella_button, 0,0,0);


# drag cursor created and destroyed as button pressed and released
#
$layout->add_events (['button-press-mask', 'button-release-mask']);
$layout->signal_connect
  (button_press_event => sub {
     $drag_cursor = Gtk2::Ex::WidgetCursor->new (widget => $layout,
                                                 cursor => 'hand1',
                                                 active => 1);
   });
$layout->signal_connect (button_release_event => sub {
                           $drag_cursor = undef;  # destroy
                         });


# heart cursor turned on and off by timer, when enabled
#
my $heart_button = Gtk2::CheckButton->new_with_label ("Heart");
$vbox->pack_start ($heart_button, 0,0,0);
my $heart_timer_id;
$heart_button->signal_connect
  (clicked => sub {
     if ($heart_button->get_active) {
       $heart_timer_id = Glib::Timeout->add (1000, \&heart_beat);
     } else {
       Glib::Source->remove ($heart_timer_id);
       $heart_timer_id = undef;
       $heart_cursor->active (0);
     }
   });
sub heart_beat {
  $heart_cursor->active (! $heart_cursor->active);
  return 1; # Glib::SOURCE_CONTINUE, continue timer
}


my $busy_button = Gtk2::Button->new_with_label ("Busy");
$busy_button->signal_connect (clicked => sub {
                           Gtk2::Ex::WidgetCursor->busy;
                           sleep (3);
                         });
$vbox->pack_start ($busy_button, 0,0,0);


$toplevel->show_all;
Gtk2->main;
exit 0;
