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

use Gtk2::Ex::CrossHair;
use Gtk2::Ex::Lasso;

my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (500, 300);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $scrolled = Gtk2::ScrolledWindow->new;
$toplevel->add ($scrolled);

my $layout = Gtk2::Layout->new;
$layout->set_size (500,500);
$scrolled->add ($layout);

my $label = Gtk2::Label->new ("hello\nworld");
$layout->put ($label, 100, 100);

my $cross = Gtk2::Ex::CrossHair->new (widget => $layout);
$cross->signal_connect
  (moved => sub {
     my ($cross, $widget, $x, $y) = @_;
     print "$progname: moved ",
       defined $x ? $x : 'undef',
         ",", defined $y ? $y : 'undef',
           "\n";
   });

my $lasso = Gtk2::Ex::Lasso->new (widget => $layout);

$layout->add_events ('button-press-mask');
$layout->signal_connect (button_press_event => sub {
                           my ($layout, $event) = @_;
                           if ($event->button == 1) {
                             $cross->start ($event);
                           } else {
                             $lasso->start ($event);
                           }
                           return 0; # propagate event
                         });

$layout->add_events ('key-press-mask');
$layout->signal_connect
  (key_press_event => sub {
     my ($layout, $event) = @_;
     if ($event->keyval == Gtk2::Gdk->keyval_from_name('c')) {
       $cross->start;
     } else {
       $lasso->start;
     }
     return 0; # propagate event
   });

$toplevel->show_all;
printf "Layout %s xid %#x  %dx%d\n",
  $layout->window, $layout->window->XID, $layout->window->get_size;
printf "Layout bin %s xid %#x  %dx%d\n",
  $layout->bin_window, $layout->bin_window->XID, $layout->bin_window->get_size;

Gtk2->main;
exit 0;
