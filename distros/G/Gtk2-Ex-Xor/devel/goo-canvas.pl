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
use Goo::Canvas;

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

my $canvas = Goo::Canvas->new;
$canvas->set_scale (2.0);
$scrolled->add ($canvas);

my $root = $canvas->get_root_item;
my $item = Goo::Canvas::Rect->new ($root,
                                   10,10, 200,100,
                                   fill_color => 'red');

my $cross = Gtk2::Ex::CrossHair->new (widget => $canvas);
$cross->signal_connect
  (moved => sub {
     my ($cross, $widget, $x, $y) = @_;
     my $ix = $x;
     my $iy = $y;
     if (defined $x) {
       $canvas->convert_from_pixels ($ix, $iy);
     }
     print "$progname: moved ",
       defined $x ? $x : 'undef',
         ",", defined $y ? $y : 'undef',
           " canvas ",
             defined $ix ? $ix : 'undef',
               ",", defined $iy ? $iy : 'undef',
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
Gtk2->key_snooper_install
  (sub {
     my ($target_widget, $event) = @_;
     if ($event->type eq 'key-press') {
       if ($event->keyval == Gtk2::Gdk->keyval_from_name('c')
           || $event->keyval == Gtk2::Gdk->keyval_from_name('C')) {
         $cross->start;

       } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('x')
           || $event->keyval == Gtk2::Gdk->keyval_from_name('X')) {
         $cross->end;

       } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('l')
                || $event->keyval == Gtk2::Gdk->keyval_from_name('L')) {
         $lasso->start;
       }
     }
     return 0; # propagate event
   });

$vbox->pack_start (Gtk2::Label->new(<<'HERE'),0,0,0);
Drag button 1 for cross, drag other button for lasso.
Press C for cross start, X for end.
Press L for lasso start, Esc for end.
HERE

$toplevel->show_all;

printf "Toplevel %s xid %#x\n",
  $toplevel->window, $toplevel->window->XID,
  $canvas->window->get_size;
printf "Canvas %s xid %#x  %dx%d\n",
  $canvas->window, $canvas->window->XID, $canvas->window->get_size;
{ my $subwin = ($canvas->window->get_children)[0];
  printf "Canvas subwin %s xid %#x  %dx%d\n",
    $subwin, $subwin->XID, $subwin->get_size;
}

# printf "Canvas bin %s xid %#x\n",
#   $canvas->bin_window, $canvas->bin_window->XID;

Gtk2->main;
exit 0;
