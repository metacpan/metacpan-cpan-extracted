#!/usr/bin/perl -w

# Copyright 2008, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Dragger.
#
# Gtk2-Ex-Dragger is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dragger is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dragger.  If not, see <http://www.gnu.org/licenses/>.


# This example shows the interaction between the WidgetCursor "busy"
# mechanism and a Dragger.
#
# Basically the busy cursor is shown, but the Dragger state isn't lost and
# the cursor is restored when unbusy - which is pretty much what you want if
# a scroll provokes some time consuming activity.
#
# As noted in the text below, if you keep wiggling the mouse around the busy
# cursor will continue to show.  That's because it's only removed when idle,
# and the main loop activity you create by wiggling means it's not idle yet.
# This is logical, and you do normally want the busy cursor to stay while
# doing drawing for such wiggling, even if in this case the program is
# interacting and therefore from the user's point of view not really busy.
#

use 5.008;
use strict;
use warnings;
use Time::HiRes;
use Glib 1.220;
use Gtk2 1.220 '-init';
use Gtk2::Ex::WidgetCursor;
use Gtk2::Ex::Dragger;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $viewport = Gtk2::Viewport->new;
$toplevel->add ($viewport);

my $label = Gtk2::Label->new
  ("
Drag
with
mouse
button-1
to move
this
up and
down.
The
busy
indication
comes and
goes on
a timer
and if
you
keep
moving
the
mouse
you can
extend
the
busy
since
it doesn't
get
back to
idle
state
to be
turned
off.
");
$viewport->add ($label);

# unspecified width to get from label, but fixed lesser height
$viewport->set_size_request (-1, 100);

my $dragger = Gtk2::Ex::Dragger->new
  (widget      => $viewport,
   vadjustment => $viewport->get_vadjustment,
   confine     => 1);

$viewport->signal_connect
  (button_press_event => sub {
     my ($viewport, $event) = @_;
     if ($event->button == 1) {
       $dragger->start ($event);
       return Gtk2::EVENT_STOP;
     } else {
       return Gtk2::EVENT_PROPAGATE;
     }
   });


sub busy {
  Gtk2::Ex::WidgetCursor->busy;
  Time::HiRes::usleep (400_000);   # 400 milliseconds
  return Glib::SOURCE_CONTINUE;
}
Glib::Timeout->add (1200, \&busy);  # 800 milliseconds

$toplevel->show_all;
Gtk2->main;
exit 0;
