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
use Data::Dumper;

my $progname = $FindBin::Script;

# Gtk2::Gdk::Window->set_debug_updates (1);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

my $area1 = Gtk2::TextView->new;
$area1->set_name ('one');
$area1->set_size_request (400, 200);
$area1->set_flags ('can-focus');
$vbox->add ($area1);

my $label = Gtk2::Label->new (" xxx ");
$vbox->add ($label);

my $area2 = Gtk2::DrawingArea->new;
$area2->set_name ('two');
$area2->set_size_request (400, 200);
$area2->set_flags ('can-focus');
$vbox->add ($area2);

my $cross = Gtk2::Ex::CrossHair->new (widgets => [ $area1, $area2 ],
                                      # width => 20,
                                      foreground => 'orange',
                                     );
$area1->add_events (['button-press-mask','key-press-mask']);
$area1->signal_connect (button_press_event =>
                        sub {
                          my ($widget, $event) = @_;
                          print "$progname: start button $widget\n";
                          require Gtk2::Ex::Xor;
                          {
                            my $bg = $area1->Gtk2_Ex_Xor_background;
                            print "  area1 xor bg ",$bg->to_string,"\n";
                          }
                          {
                            my $bg = $area2->Gtk2_Ex_Xor_background;
                            print "  area2 xor bg ",$bg->to_string,"\n";
                          }

                          {
                            my $win = $area1->window;
                            my ($width,$height) = $win->get_size;
                            print "  window $win  ${width}x$height\n";
                            my @wins = $win->get_children;
                            foreach my $win (@wins) {
                              my ($width,$height) = $win->get_size;
                              print "  sub-window $win  ${width}x$height\n";
                            }
                          }

                          #                         $cross->start ($event);
                          return 0; # propagate
                        });
$area1->signal_connect
  (key_press_event =>
   sub {
     my ($widget, $event) = @_;
     if ($event->keyval == Gtk2::Gdk->keyval_from_name('c')) {
       print "$progname: start key $widget\n";
       $cross->start ($event);
       return 1; # don't propagate

     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('e')) {
       my ($width, $height) = $area1->window->get_size;
       print "$progname: queue draw top left quarter\n";
       $area1->queue_draw_area (0,0, $width/2, $height/2);
       return 1; # don't propagate

     } else {
       return 0; # propagate
     }
   });

$toplevel->show_all;
Gtk2->main;
