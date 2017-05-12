#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Clock.
#
# Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Clock is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Clock.  If not, see <http://www.gnu.org/licenses/>.


# Clock display using "7 Segment" font by Harvey Twyman,
#
#     http://www.twyman.org.uk/Fonts/
#
# Put the "7 Segment.ttf" file in your ~/.fonts directory (or other
# directory selected by your ~/.fonts.conf or system /etc/fonts/fonts.conf).
#
# The size is roughly 30 points (size="30000" in 1/1024's of a point), and
# the font is applied to the numbers, but not to the ":" since it's done as
# two horizontal bars, which is true to the 7-segment style, but two dots
# are usual on an alarm clock, so the ":" is left to the default font.
#
# An alarm clock often has "AM" letters at the top and "PM" at the bottom.
# An optional superscript depending on the time value can't be easily done
# by the Gtk2::Ex::Clock format string currently.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Clock;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $clock = Gtk2::Ex::Clock->new
  (format => ' <span font_size="30000"><span font="7 Segment">%I</span>:<span font="7 Segment">%M</span></span> %P ');
$vbox->pack_start ($clock, 0,0,0);

my $label = Gtk2::Label->new ("
Clock with 7-segment font.
If you don't have the font then
it's the ordinary default.");
$vbox->pack_start ($label, 0,0,0);

$toplevel->show_all;
Gtk2->main;
exit 0;
