#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use FindBin;
use Gtk2 '-init';
use Gnome2::Canvas;

use Gtk2::Ex::CrossHair;
use Gtk2::Ex::Lasso;

my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (500, 300);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $scrolled = Gtk2::ScrolledWindow->new;
$vbox->pack_start ($scrolled, 1,1,0);

my $canvas = Gnome2::Canvas->new;
$canvas->set_pixels_per_unit (2.0);
$canvas->set_scroll_region (500,500, 1000,1000);
$scrolled->add ($canvas);

my $group = $canvas->root;
my $item = Gnome2::Canvas::Item->new ($group,
                                      'Gnome2::Canvas::Ellipse',
                                      x1 => 510, y1 => 510,
                                      x2 => 700, y2 => 600,
                                      fill_color => 'red');

my $cross = Gtk2::Ex::CrossHair->new (widget => $canvas);
$cross->signal_connect
  (moved => sub {
     my ($cross, $widget, $x, $y) = @_;
     my ($bx, $by) = $canvas->get_scroll_offsets;
     my ($world_x, $world_y) = (defined $x
                                ? $canvas->window_to_world ($x + $bx, $y + $by)
                                : ());
     print "$progname: moved ",
       defined $x ? $x : 'undef',
         ",", defined $y ? $y : 'undef',
           " world ",
             defined $world_x ? $world_x : 'undef',
               ",", defined $world_y ? $world_y : 'undef',
                 "\n";
   });

my $lasso = Gtk2::Ex::Lasso->new (widget => $canvas);

$canvas->add_events ('button-press-mask');
$canvas->signal_connect (button_press_event => sub {
                           my ($canvas, $event) = @_;
                           if ($event->button == 1) {
                             $cross->start ($event);
                           } else {
                             $lasso->start ($event);
                           }
                           return 0; # propagate event
                         });

$canvas->add_events ('key-press-mask');
$canvas->signal_connect
  (key_press_event => sub {
     my ($canvas, $event) = @_;
     if ($event->keyval == Gtk2::Gdk->keyval_from_name('c')) {
       $cross->start;
     } else {
       $lasso->start;
     }
     return 0; # propagate event
   });

$vbox->pack_start (Gtk2::Label->new(<<'HERE'),0,0,0);
Drag button 1 for cross, drag other button for lasso.
Press C for cross, other key for lasso.
HERE

$toplevel->show_all;
printf "Canvas %s xid %#x  %dx%d\n",
  $canvas->window, $canvas->window->XID, $canvas->window->get_size;
printf "Canvas bin %s xid %#x  %dx%d\n",
  $canvas->bin_window, $canvas->bin_window->XID, $canvas->bin_window->get_size;

Gtk2->main;
exit 0;
