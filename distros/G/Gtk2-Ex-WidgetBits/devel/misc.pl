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

use 5.010;
use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
use Smart::Comments;


{
  require Test::Without::Gtk2Things;
  Test::Without::Gtk2Things->import('-verbose', 'gdkdisplay');

   Gtk2->init;
  require Gtk2::Ex::WidgetBits;
  my $label = Gtk2::Label->new('hello');
  # my $toplevel = Gtk2::Window->new('toplevel');
  # $toplevel->add ($label);
  $, = ' ';
  my $width = 0.5;
  my $height = 0.0;
#  say $width/$height;
  say Gtk2::Ex::WidgetBits::xy_distance_mm($label, 10,20, 50,60);
  say Gtk2::Ex::WidgetBits::pixel_size_mm($label, 10,20, 50,60);
  say Gtk2::Ex::WidgetBits::pixel_aspect_ratio($label, 10,20, 50,60);
  exit 0;
}

{
  my $default_screen = Gtk2::Gdk::Screen->get_default;
  ### $default_screen

  my $default_root_window = Gtk2::Gdk->get_default_root_window;
  ### $default_root_window

  Gtk2->init_check;
  exit 0;
}

{
  ### isa: Foo->isa('bar')
  exit 0;
}


{
  # use Test::Without::Gtk2Things '-verbose', 'EXPERIMENTAL_GdkDisplay';
  require Gtk2::Ex::WidgetBits;
  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->realize;
  print Gtk2::Ex::WidgetBits::xy_distance_mm($toplevel, 10,20, 50,60);
  exit 0;
}

{
  my $screen = Gtk2::Gdk::Display->get_default->get_default_screen;

  my $mnum = 0;
  my $width_mm = $screen->get_monitor_width_mm ($mnum);
  my $height_mm = $screen->get_monitor_height_mm ($mnum);
  ### $mnum
  ### $width_mm
  ### $height_mm
  exit 0;
}

{
  require Test::Weaken;
  print Test::Weaken->VERSION,"\n";
  require Test::Weaken::Gtk2;

  # cellview doesn't like get_cells without set_display_row, or something
  my $cellview = Gtk2::CellView->new;
  my $renderer = Gtk2::CellRendererText->new;

  my @cells = Test::Weaken::Gtk2::contents_cell_renderers($cellview);
  ### @cells;

  $cellview->pack_start ($renderer, 0);

  @cells = Test::Weaken::Gtk2::contents_cell_renderers($cellview);
  ### @cells;

  exit 0;
}
