#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NoShrink.
#
# Gtk2-Ex-NoShrink is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NoShrink is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NoShrink.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::NoShrink;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
my $screen_width = $toplevel->get_screen->get_width;
$toplevel->set_default_size ($screen_width / 2, -1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

#my $layout = Gtk2::Frame->new;
my $layout = Gtk2::Layout->new;
$toplevel->add ($layout);

my $noshrink = Gtk2::Ex::NoShrink->new (shrink_width_factor => 2);
$noshrink->set_border_width (5);
$noshrink->signal_connect (size_allocate => sub {
                             my ($noshrink, $rect) = @_;
                             print "$progname: NoShrink size_allocate ",
                               $rect->x,",",$rect->y,
                                 " ",$rect->width,"x",$rect->height,
                                   "\n";
                           });
$noshrink->signal_connect (expose_event => sub {
                             my ($noshrink, $event) = @_;
                             print "$progname: NoShrink expose ",
                               region_to_string($event->region),"\n";
                             return 0; # Gtk2::EVENT_PROPAGATE
                           });
$layout->add ($noshrink);

my $adj = Gtk2::Adjustment->new (40, 0,$screen_width, 1,10,0);

my $spin = Gtk2::SpinButton->new ($adj, 10, 0);
$spin->set_size_request ($spin->get_value, -1);
$noshrink->add ($spin);
$spin->signal_connect (value_changed => sub {
                         # width from the spinner value
                         $spin->set_size_request ($spin->get_value, -1);
                       });
$spin->signal_connect (size_allocate => sub {
                         my ($noshrink, $rect) = @_;
                         print "$progname: SpinButton size_allocate ",
                           $rect->x,",",$rect->y,
                             " ",$rect->width,"x",$rect->height,
                               "\n";
                       });
# $spin->signal_connect (expose_event => sub {
#                          my ($spin, $event) = @_;
#                          print "$progname: SpinButton expose ",
#                            region_to_string($event->region),"\n";
#                          return 0; # Gtk2::EVENT_PROPAGATE
#                        });

Gtk2->key_snooper_install
  (sub {
     my ($widget, $event) = @_;
     $event->type eq 'key-press' or return 0;  # Gtk2::EVENT_PROPAGATE
     my $key = Gtk2::Gdk->keyval_name ($event->keyval);
     print "$progname: key $key\n";
     
     if ($key eq 'l' && $event->state & 'control-mask') {
       print "$progname: queue_draw\n";
       $toplevel->queue_draw;
       return 1;  # Gtk2::EVENT_STOP
     }
     if ($key eq 'Down' && $event->state & 'control-mask') {
       my $x = $layout->child_get_property($noshrink,'x');
       my $y = $layout->child_get_property($noshrink,'y');
       $y += 10;
       print "$progname: move noshrink to $x,$y\n";
       $layout->move($noshrink, $x, $y);
       return 1;  # Gtk2::EVENT_STOP
     }
     if ($key eq 'Up' && $event->state & 'control-mask') {
       my $x = $layout->child_get_property($noshrink,'x');
       my $y = $layout->child_get_property($noshrink,'y');
       $y -= 10;
       print "$progname: move noshrink to $x,$y\n";
       $layout->move($noshrink, $x, $y);
       return 1;  # Gtk2::EVENT_STOP
     }
     return 0;  # Gtk2::EVENT_PROPAGATE
   });

my $req = $noshrink->size_request;
$layout->set_size_request (-1, $req->height * 3);

$toplevel->show_all;
Gtk2->main;
exit 0;



sub region_to_string {
  my ($region) = @_;
  if (my @rectangles = $region->get_rectangles) {
    return join (' ', map {$_->x.','.$_->y.'='.$_->width.'x'.$_->height}
                 @rectangles);
  } else {
    return 'empty';
  }
}
