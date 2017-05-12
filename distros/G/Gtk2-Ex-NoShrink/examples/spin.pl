#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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


# NoShrink widget with size requested by numeric spinner.
#
# This is a manually operated example.  The desired size of the spinner
# widget is set (set_size_request), in pixels, from the value you enter or
# scroll up or down to.  Then because it's inside a NoShrink container the
# actual request (and hence the allocated size) is subject to that widget's
# no-shrink policy.
#
# The NoShrink has the shrink_width_factor option is set in this example and
# you can see how it allows shrinks of a certain big enough amount.  In this
# case a setting 2 means a factor of 2 (or more) smaller than the current
# recorded peak will be obeyed (and it resets the peak to that new smaller
# size).  So for instance if you run the spinner up to 300 pixels and then
# start running it down again, when it reaches 150 pixel that size will be
# obeyed.
#
# If you uncomment the line "$noshrink = Gtk2::Frame->new;" you can see what
# happens in a GtkFrame container instead of a NoShrink.  A frame simply
# passes its child's size requests upwards, so running the spinner up or
# down in that case is immediately reflected in the spinners size.
#
# Incidentally, everything works the same vertically on requested heights
# (width and height are handled independently).  But for this example the
# spinner looks better getting wider and narrower than taller and shorter.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::NoShrink;

my $toplevel = Gtk2::Window->new('toplevel');
my $screen_width = $toplevel->get_screen->get_width;
$toplevel->set_default_size ($screen_width / 2, -1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $adj = Gtk2::Adjustment->new (40,            # initial value
                                 0,             # lower
                                 $screen_width, # upper
                                 1,             # step_increment
                                 10,            # page_increment
                                 0);            # page_size not applicable

my $spin = Gtk2::SpinButton->new ($adj, 10, 0);
$spin->set_size_request ($spin->get_value, -1);
$spin->signal_connect (value_changed => sub {
                         # width from the spinner value
                         $spin->set_size_request ($spin->get_value, -1);
                       });

my $noshrink = Gtk2::Ex::NoShrink->new (shrink_width_factor => 2);
#
# try this for plain frame instead of noshrink:
# $noshrink = Gtk2::Frame->new;
#
$noshrink->set_border_width (5);
$noshrink->add ($spin);

my $layout = Gtk2::Layout->new;
$layout->add ($noshrink);
$layout->show_all;
$toplevel->add ($layout);

# lock height of the spinner and any noshrink border width because a layout
# widget doesn't otherwise offer a desired height
my $req = $noshrink->size_request;
$layout->set_size_request (-1, $req->height);

$toplevel->show;
Gtk2->main;
exit 0;
