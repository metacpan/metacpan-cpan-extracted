#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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


# Updates are fairly erratic since time() amounts no longer correspond to
# Glib::Timeout->add() amounts.  Maybe Time::Mock could mangle those
# timeouts similar to its speedup of sleep().

use strict;
use warnings;
use Time::Mock throttle => 4;
use POSIX ();

use Gtk2 '-init';
use Gtk2::Ex::Clock;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $clock = Gtk2::Ex::Clock->new (format => '%a %H:%M:%S');
$toplevel->add ($clock);

$clock->signal_connect (notify => sub {
                          my $t = time();
                          my $ctime = POSIX::ctime($t);
                          my @tm = localtime($t);
                          my $strftime = POSIX::strftime('%H:%M:%S',@tm);
                          print "time() $t  $strftime   $ctime";
                        });

$toplevel->show_all;
Gtk2->main;
exit 0;
