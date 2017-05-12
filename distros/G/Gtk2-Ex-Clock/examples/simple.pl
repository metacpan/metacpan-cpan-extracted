#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

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


# Simple clock display.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Clock;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $clock = Gtk2::Ex::Clock->new (format => '%a %I:%M%P');
$toplevel->add ($clock);

$toplevel->show_all;
Gtk2->main;
exit 0;
