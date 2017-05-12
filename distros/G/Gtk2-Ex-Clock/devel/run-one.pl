#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Clock;
use POSIX qw(setlocale LC_ALL LC_TIME);
use DateTime;
use DateTime::TimeZone;


{
  $ENV{'LANG'} = 'en_IN.UTF8';
  $ENV{'LANG'} = 'ar_IN';
  $ENV{'LANG'} = 'ja_JP';
  $ENV{'LANG'} = 'ja_JP.UTF8';
  setlocale(LC_ALL, '') or die;
}

{
  my $locale = setlocale (LC_TIME);
  DateTime->DefaultLocale ($locale);
  print "DateTime::DefaultLocale is ", DateTime->DefaultLocale, "\n";
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

require DateTime::TimeZone::TAI;
my $tz = DateTime::TimeZone::TAI->new;
my $clock = Gtk2::Ex::Clock->new (format => "DateTime TAI %a %H:%M:%S.%N",
                                  timezone => $tz);
$clock->signal_connect (notify => sub { print "update ...\n" });

{
  my $button = Gtk2::Button->new_with_label ('Unmap');
  $vbox->pack_start ($button, 0, 0, 0);
  $button->signal_connect (clicked => sub {
                             $clock->unmap;
                           });
}
{
  my $button = Gtk2::CheckButton->new_with_label ('Visible');
  $vbox->pack_start ($button, 0, 0, 0);
  require Glib::Ex::ConnectProperties;
  Glib::Ex::ConnectProperties->new ([$clock,'visible'],
                                    [$button,'active']);
}

$vbox->pack_start ($clock, 1,1,0);

$toplevel->show_all;
Gtk2->main;
exit 0;
