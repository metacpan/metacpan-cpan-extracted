#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetBits;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $menubar = Gtk2::MenuBar->new;
$toplevel->add ($menubar);

my $topitem = Gtk2::MenuItem->new ('Menu');
$menubar->append ($topitem);

my $menu = Gtk2::Menu->new;
# $topitem->set_submenu ($menu);

my $zitem;
$menu->signal_connect
  (show => sub {
     # my $tearoff = Gtk2::TearoffMenuItem->new;
     # $tearoff->show;
     # $menu->append ($tearoff);
     # $menu->set (reserve_toggle_size => 0);
     # print "$progname: tearoff border ", $tearoff->get_border_width,
     #   ",", $tearoff->get_border_width, "\n";

     {
       my $item = Gtk2::MenuItem->new ('ZZZZZZZZZZZZ');
       $item->show;
       $menu->append ($item);
     }

     $zitem = Gtk2::MenuItem->new ('ZZZZZZZZZZZZ');
     $zitem->show;
     $menu->append ($zitem);
   });

$menu->popup (undef, undef, undef, undef,
              1, 0);

my $submenu = Gtk2::Menu->new;
$zitem->set_submenu ($submenu);

my $item;
$submenu->signal_connect
  (show => sub {
     {
       my $item = Gtk2::MenuItem->new ('SSSSSSSSSS');
       $item->show;
       $submenu->append ($item);
     }
     $item = Gtk2::MenuItem->new ('SSSSSSSSS');
     $item->show;
     $submenu->append ($item);
                          });

Glib::Timeout->add
  (2000,
   sub {
     {
       my ($x,$y) = Gtk2::Ex::WidgetBits::get_root_position ($menu);
       print "menu    $x,$y   $menu\n";
       my $window = $menu->window;
       print "window  $window\n";
     }
     {
       $submenu = $zitem->get_submenu;
       my ($x,$y) = Gtk2::Ex::WidgetBits::get_root_position ($submenu);
       print "submenu $x,$y   $submenu\n";
       my $window = $submenu->window;
       print "window  $window\n";
     }
     if ($item) {
       my $alloc = $item->allocation;
       { local $,=' '; print "item alloc",$alloc->values,"\n"; }
       my ($x,$y) = Gtk2::Ex::WidgetBits::get_root_position ($item);
       print "item    $x,$y  ",$item->get('label'),"\n";
       my $parent = $item->get_parent;
       print "parent  $parent\n";
       my $window = $item->window;
       my $rootwin = $menu->get_screen->get_root_window;
       for (my $w = $window; $w != $rootwin; $w = $w->get_parent) {
         local $,=' ';
         print "win  $w",$w->XID,$w->get_position,($w->get_geometry)[0,1],"\n";
       }
       system "xwininfo -children -id ".$window->XID;
     }
     exit 1;
     # return Glib::SOURCE_REMOVE;
   });

#$toplevel->show_all;
Gtk2->main;
exit 0;
