#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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


# Some world times using Gtk2::Ex::Clock widgets.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Clock;


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new();
$toplevel->add ($vbox);

# The timezone names used here are based on Olson's database, as found on
# GNU systems and elsewhere.

foreach my $zone ('Pacific/Honolulu',    # -10:00
                  'America/Anchorage',   # -9:00
                  'America/Los_Angeles', # -8:00
                  'America/Edmonton',    # -7:00
                  'America/Chicago',     # -6:00
                  'America/New_York',    # -5:00
                  'America/Antigua',     # -4:00
                  'America/Sao_Paulo',   # -3:00
                  # -2:00 only maybe Noronha or South Georgia
                  'Atlantic/Reykjavik',  # -1:00
                  'GMT',                 # +0:00
                  'Europe/Budapest',     # +1:00
                  'Europe/Athens',       # +2:00
                  'Asia/Aden',           # +3:00
                  'Indian/Maldives',     # +5:00
                  'Asia/Kuala_Lumpur',   # +7:00
                  'Asia/Singapore',      # +8:00
                  'Asia/Tokyo',          # +9:00
                  'Australia/Sydney',    # +10:00
                  'Pacific/Noumea',      # +11:00
                  'Pacific/Auckland') {  # +12:00
  $zone =~ m{[^/]+$};
  my $name = $&;
  $name =~ s/_/ /;
  my $format = "%a %I:%M %P %Z    $name";
  my $clock = Gtk2::Ex::Clock->new(format   => $format,
                                   timezone => $zone,
                                   xalign   => 0.0);
  $vbox->add ($clock);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
