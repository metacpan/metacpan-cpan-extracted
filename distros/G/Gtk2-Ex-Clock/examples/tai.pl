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


# Display of TAI atomic time using DateTime::TimeZone::TAI, together with
# GMT/UTC and local time for comparison.
#
# As of May 2010 TAI is ahead of UTC by 34 seconds.  The earth rotates a
# little slower than once every 86400 SI seconds, and in fact the speed of
# rotation varies very slightly.  The cumulative amount slower has added up
# to 34 SI seconds so far.
#.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Clock;
use DateTime::TimeZone;
use DateTime::TimeZone::TAI;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $table = Gtk2::Table->new (4, 2);
$toplevel->add ($table);

my $vpos = 0;
{
  my $tz = DateTime::TimeZone::TAI->new;
  my $label = Gtk2::Label->new('TAI atomic time');
  $table->attach ($label, 0,1, $vpos,$vpos+1,
                  ['expand','shrink','fill'], ['expand','shrink','fill'],
                  4,1);
  my $clock = Gtk2::Ex::Clock->new (format => '%H:%M:%S',
                                    timezone => $tz,
                                    xalign => 0);
  $table->attach ($clock, 1,2, $vpos,$vpos+1,
                  ['expand','shrink','fill'], ['expand','shrink','fill'],
                  4,1);
  $vpos++;
}
{
  my $tz = DateTime::TimeZone::TAI->new;
  my $label = Gtk2::Label->new('TAI minutes');
  $table->attach ($label, 0,1, $vpos,$vpos+1,
                  ['expand','shrink','fill'], ['expand','shrink','fill'],
                  4,1);
  my $clock = Gtk2::Ex::Clock->new (format => '%H:%M',
                                    timezone => $tz,
                                    xalign => 0);
  $table->attach ($clock, 1,2, $vpos,$vpos+1,
                  ['expand','shrink','fill'], ['expand','shrink','fill'],
                  4,1);
  $vpos++;
}
{
  my $tz = DateTime::TimeZone->new (name => 'GMT');
  my $label = Gtk2::Label->new('GMT/UTC time');
  $table->attach ($label, 0,1, $vpos,$vpos+1,
                  ['expand','shrink','fill'], ['expand','shrink','fill'],
                  4,1);
  my $clock = Gtk2::Ex::Clock->new (format => '%H:%M:%S',
                                    timezone => $tz,
                                    xalign => 0);
  $table->attach ($clock, 1,2, $vpos,$vpos+1,
                  ['expand','shrink','fill'], ['expand','shrink','fill'],
                  4,1);
  $vpos++;
}
{
  my $tz = DateTime::TimeZone->new (name => 'local');
  my $label = Gtk2::Label->new('Local time');
  $table->attach ($label, 0,1, $vpos,$vpos+1,
                  ['expand','shrink','fill'], ['expand','shrink','fill'],
                  4,1);
  my $clock = Gtk2::Ex::Clock->new (format => '%H:%M:%S',
                                    timezone => $tz,
                                    xalign => 0);
  $table->attach ($clock, 1,2, $vpos,$vpos+1,
                  ['expand','shrink','fill'], ['expand','shrink','fill'],
                  4,1);
  $vpos++;
}

$toplevel->show_all;
Gtk2->main;
exit 0;
