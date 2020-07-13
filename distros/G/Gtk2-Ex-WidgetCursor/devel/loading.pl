#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Gtk2 -init;

my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file
  ('/usr/share/doc/libgtk2-perl-doc/examples/gtk-demo/apple-red.png');
my $width = $pixbuf->get_width;
my $height = $pixbuf->get_height;

my $popup = Gtk2::Window->new ('toplevel');
$popup->set_default_size ($width, $height);
$popup->realize;
my $win = $popup->window;
my $gc = $popup->style->bg_gc('normal');
my $pixmap = Gtk2::Gdk::Pixmap->new ($win, $width, $height, -1);
$pixmap->draw_rectangle ($gc, 1, 0,0, $width,$height); # clear
$pixmap->draw_pixbuf ($gc, $pixbuf, 0,0, 0,0, $width,$height, 'none', 0,0);
$win->set_back_pixmap ($pixmap);
$win->set_cursor (Gtk2::Gdk::Cursor->new('watch'));

$popup->show;
$popup->get_display->flush;
sleep 30;


my $window = Gtk2::Window->new;
$window->set_title ("My window");

my $label = Gtk2::Label->new ("Hello, world!");
$window->add ($label);

$popup->destroy;
$window->show_all;
Gtk2->main;
