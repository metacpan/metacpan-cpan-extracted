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


# If you want to have a "busy" indication across a Glib::Timeout or a
# Glib::IO socket then you just make a WidgetCursor and turn it on and off
# when starting or finishing.  The code here does that across some timer
# steps.
#
# You don't have to create the WidgetCursor immediately, you could do that
# when actually starting (the start() function here).  And of course the
# cursor could be just on an affected widget (or widgets) not the whole
# toplevel.
#
# If your job holds working state for the calculation in a hash or object or
# similar then that can be a good place to hold the WidgetCursor too.  When
# the job is either completed or aborted you discard the working data and
# the WidgetCursor is destroyed automatically (unsetting the cursor).
#

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

my $button = Gtk2::Button->new_with_label ("Click to Start");
$button->signal_connect (clicked => \&start);
$vbox->pack_start ($button, 1,1,0);

my $label = Gtk2::Label->new ("Status: <Ready> ");
$vbox->pack_start ($label, 1,1, 20);

my $widgetcursor = Gtk2::Ex::WidgetCursor->new (widget => $toplevel,
                                                cursor => 'watch',
                                                priority => 10);
my $timer_id;
my $counter;

sub start {
  $widgetcursor->active (1);
  $counter = 0;
  if (! $timer_id) { # if not already running
    $timer_id = Glib::Timeout->add (500, \&step);  # 500 milliseconds
    step();
  }
}
sub step {
  if (++$counter <= 6) {
    $label->set_text ("count $counter");
    return 1; # Glib::SOURCE_CONTINUE, timer continues
  } else {
    $label->set_text (' <Ended> ');
    $widgetcursor->active (0);
    $timer_id = undef;
    return 0; # Glib::SOURCE_REMOVE, stop timer
  }
}

$toplevel->show_all;
Gtk2->main;
exit 0;
