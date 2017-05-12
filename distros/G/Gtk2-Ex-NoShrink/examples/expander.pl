#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NoShrink.
#
# Gtk2-Ex-NoShrink is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NoShrink is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NoShrink.  If not, see <http://www.gnu.org/licenses/>.


# Demonstrate NoShrink with a pulsing expanding label.
#
# This is an automated demo of the noshrink policy.  The text of a label
# widget is set to a run of stars "****" growing and shrinking on a timer.
# The changing text makes the label ask to be bigger and smaller, but the
# NoShrink widget keeps it at its peak size.
#
# The label is setup as white text on a black background, and that can be
# seen growing into space provided by a GtkLayout widget (with a white
# background).
#
# The "xalign" property is set to 0 in the label to have the text aligned at
# the left when the space is more than the text needs.  You can change that
# to say 1.0 to have it aligned at the right -- the no-shrink policy remains
# the same.
#
# If you're wondering what the EventBox is for, it just gives a different
# background colour for the label.  A label is a no-window widget (and
# NoShrink is a no-window too) and hence gets the background of its parent,
# put it in something with a window to have a background colour contrasting
# against the layout parent.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::NoShrink;
use Math::Trig;


Gtk2::Rc->parse_string ('
style "White_on_Black" {
    fg[NORMAL]    = { 1.0, 1.0, 1.0 }
    bg[NORMAL]    = { 0, 0, 0 }
    base[NORMAL]  = { 0, 0, 0 }
}
style "Black_on_White" {
    fg[NORMAL]    = { 0, 0, 0 }
    text[NORMAL]  = { 0, 0, 0 }
    bg[NORMAL]    = { 1.0, 1.0, 1.0 }
}
widget "*.GtkLabel"    style "White_on_Black"
widget "*.GtkEventBox" style "White_on_Black"
widget "*.GtkLayout"   style "Black_on_White"
');

my $label = Gtk2::Label->new ('*');
$label->set (xalign => 0);

my $eventbox = Gtk2::EventBox->new;
$eventbox->add ($label);

my $noshrink = Gtk2::Ex::NoShrink->new (child => $eventbox);

my $layout = Gtk2::Layout->new;
$layout->add ($noshrink);
# use label's desired height
my $req = $label->size_request;
$layout->set_size_request (-1, $req->height);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->add ($layout);
$toplevel->set_default_size ($toplevel->get_screen->get_width / 2, -1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->show_all;

my $x = 0;
sub timer_callback {
  my $len = int ($x/4 + 10 * sin ($x));
  $label->set_text ('*' x $len);
  $x += Math::Trig::pi / 10;
  return 1; # Glib::SOURCE_CONTINUE
}
Glib::Timeout->add (100, \&timer_callback);

Gtk2->main;
exit 0;
