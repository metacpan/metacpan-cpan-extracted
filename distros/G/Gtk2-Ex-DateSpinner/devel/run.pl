#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

BEGIN {
  $ENV{'LANG'} = 'ja_JP.utf8';
  $ENV{'LC_ALL'} = 'ja_JP.utf8';
  delete $ENV{'LANGUAGE'};

  $ENV{'LANG'} = 'de_DE';
  $ENV{'LC_ALL'} = 'de_DE';
  $ENV{'LANGUAGE'} = 'de';

  require POSIX;
  print "setlocale to ",POSIX::setlocale(POSIX::LC_ALL(),""),"\n";
}

use Gtk2::Ex::DateSpinner;
# {
#   print Locale::Messages::dgettext ('gtk20-properties','Day');
#   exit 0;
# }

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub {
                             print "$progname: destroy\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $datespinner = Gtk2::Ex::DateSpinner->new;
$datespinner->signal_connect ('notify::value' => sub {
                                my ($obj, $pspec) = @_;
                                my $pname = $pspec->get_name;
                                my $value = $obj->get($pname);
                                print "$progname: notify:value now $value\n";
                              });
$vbox->pack_start ($datespinner, 0,0,0);

my $entry = Gtk2::Entry->new;
$entry->set_text ('1990-12-31');
$vbox->pack_start ($entry, 1, 1, 0);
$entry->signal_connect (activate => sub {
                          my $str = $entry->get_text;
                          print "$progname: set datespinner value '$str'\n";
                          $datespinner->set (value => $str);
                        });

my $hbox = Gtk2::HBox->new;
$vbox->pack_start ($hbox, 0,0,0);

my $quit = Gtk2::Button->new_from_stock ('gtk-quit');
$quit->signal_connect (clicked => sub { $toplevel->destroy; });
$hbox->pack_start ($quit, 0,0,0);

$toplevel->show_all;
Gtk2->main;
exit 0;
