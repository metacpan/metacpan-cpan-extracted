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
  $, = ' ';
  Gtk2->init;
  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

  my $aframe = Gtk2::AspectFrame->new (undef, 0,0, 1, 0);
  # my $aframe = Gtk2::Frame->new;
  $toplevel->add ($aframe);

  my $child = Gtk2::DrawingArea->new;
   $child->set_size_request (10,10);
  $aframe->add($child);

  require Gtk2::Ex::WidgetBits;
  my $ratio = Gtk2::Ex::WidgetBits::pixel_aspect_ratio($child);
  # $child->set_size_request (800,800*$ratio);
  $aframe->set (ratio => $ratio*2);

  my $screen = $toplevel->get_screen;
  my $mnum = 0;
  say "screen mm", $screen->get_width_mm, $screen->get_height_mm;
  say "pixel mm", Gtk2::Ex::WidgetBits::pixel_size_mm($child);

  $child->signal_connect
    (size_allocate => sub {
       my ($child, $alloc) = @_;
       say "alloc", $alloc->width, $alloc->height;
       say "mm",
         $alloc->width / $screen->get_width * $screen->get_width_mm,
           $alloc->height / $screen->get_height * $screen->get_height_mm;
     });

  $toplevel->show_all;

  $child->window->set_background(Gtk2::Gdk::Color->new(0,0,0,0));
  Gtk2->main;
  exit 0;
}
