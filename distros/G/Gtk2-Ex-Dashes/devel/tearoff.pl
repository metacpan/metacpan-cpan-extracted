#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Dashes.
#
# Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dashes.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Dashes::MenuItem;

use FindBin;
my $progname = $FindBin::Script;

my $menu = Gtk2::Menu->new;

my $tearoff = Gtk2::TearoffMenuItem->new;
$tearoff->show;
$menu->append ($tearoff);
$menu->set (reserve_toggle_size => 0);
print "$progname: tearoff border ", $tearoff->get_border_width,
  ",", $tearoff->get_border_width, "\n";

my $dashesitem = Gtk2::Ex::Dashes::MenuItem->new;
print "$progname: dashesitem $dashesitem\n";
$dashesitem->signal_connect
  (direction_changed => sub {
     print "$progname: dashesitem direction-changed\n";
   });
$dashesitem->signal_connect
  (show => sub {
     print "$progname: dashesitem show\n";
   });
$dashesitem->signal_connect
  (style_set => sub {
     print "$progname: dashesitem style-set\n";
   });
my $dashes = $dashesitem->get_child;
print "$progname: dashes $dashes\n";
$dashes->signal_connect
  (direction_changed => sub {
     print "$progname: child direction-changed\n";
   });
$dashes->signal_connect
  (show => sub {
     my ($dashes) = @_;
     print "$progname: child show\n";
   });
$dashes->signal_connect
  (style_set => sub {
     my ($dashes, $prev_style) = @_;
     print "$progname: child style_set, was ",$prev_style//'undef'," now ",$dashes->get_style,"\n";
   });
print "$progname: dashesitem show\n";
$dashesitem->show;
print "$progname: dashesitem append\n";
$menu->append ($dashesitem);
print "$progname: done\n";

my $zitem = Gtk2::MenuItem->new ('ZZZZZZZZZZZZ');
$zitem->show;
$menu->append ($zitem);

$dashesitem->set_direction ('rtl');
print "$progname: child direction is ",$dashes->get_direction,"\n";

print "$progname: popup\n";
$menu->popup (undef, undef, undef, undef,
              1, 0);

print "$progname: dashes ypad ",$dashes->get('ypad'),"\n";
print "$progname: main loop\n";
Gtk2->main;
exit 0;
