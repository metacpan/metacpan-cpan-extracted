#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

# {
#   require DateTime::TimeZone::TAI;
#   my $tz = DateTime::TimeZone::TAI->new;
#   my $clock = Gtk2::Ex::Clock->new (format => "DateTime TAI:  %a %I:%M",
#                                     timezone => $tz);
#   $vbox->pack_start ($clock, 1,1,0);
# 
#   my $tod = time();
#   my $t = DateTime->from_epoch (epoch => $tod, time_zone => $tz);
#   print $t->strftime("TAI %H:%M:%S"), "\n";
#   print POSIX::strftime("GMT %H:%M:%S",gmtime($tod)), "\n";
# }
{
  require DateTime::TimeZone::TAI;
  my $tz = DateTime::TimeZone::TAI->new;
  my $clock = Gtk2::Ex::Clock->new (format => "DateTime TAI %a %H:%M:%S.%N</span>",
                                    timezone => $tz);
  $clock->signal_connect (notify => sub { print "update ...\n" });
  $vbox->pack_start ($clock, 1,1,0);
}
# {
#   # wide chars crunched through strftime
#   my $clock = Gtk2::Ex::Clock->new (format => "TZ GMT:  \x{263A} %a %I:%M%P",
#                                     timezone => 'GMT');
#   $vbox->pack_start ($clock, 1,1,0);
# }
# {
#   my $tz = DateTime::TimeZone->new (name => 'GMT');
#   my $clock = Gtk2::Ex::Clock->new (format => "DateTime GMT:  \x{263A} %a %I:%M%P",
#                                     timezone => $tz);
#   $vbox->pack_start ($clock, 1,1,0);
# }
# {
#   my $tz = DateTime::TimeZone->new (name => 'local');
#   my $clock = Gtk2::Ex::Clock->new (format => "DateTime Local:  \x{263A} %a %I:%M%P",
#                                     timezone => $tz);
#   $vbox->pack_start ($clock, 1,1,0);
# }
# {
#   my @methods = ('second', 'sec', 'hms', 'time', 'datetime', 'iso8601',
#                  'epoch');
#   my $tz = DateTime::TimeZone->new (name => 'GMT');
#   foreach my $method (@methods) {
#     my $clock = Gtk2::Ex::Clock->new (format => "DateTime::$method %{$method}",
#                                       timezone => $tz);
#     $vbox->pack_start ($clock, 1,1,0);
#   }
# }
# {
#   my $clock = Gtk2::Ex::Clock->new (format => "TZ %%s epoch: %s");
#   $vbox->pack_start ($clock, 1,1,0);
# }
# {
#   my $clock = Gtk2::Ex::Clock->new (format => "TZ Bad Zone: %H:%M:%S",
#                                     timezone => 'Some Bogosity');
#   $vbox->pack_start ($clock, 1,1,0);
# }
# {
#   my $clock = Gtk2::Ex::Clock->new (format => "TZ Bad Format: %! %%");
#   $vbox->pack_start ($clock, 1,1,0);
# }


$toplevel->show_all;

{
  require I18N::Langinfo;
  my $charset = I18N::Langinfo::langinfo (I18N::Langinfo::CODESET());
  print "charset $charset\n";
}

Gtk2->main;
exit 0;
