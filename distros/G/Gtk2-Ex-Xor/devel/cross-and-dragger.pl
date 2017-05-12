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
use Gtk2::Ex::Dragger;
use Data::Dumper;

my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->set_size_request (150, 150);

my $scrolled = Gtk2::ScrolledWindow->new;
$toplevel->add ($scrolled);

my $viewport = Gtk2::Viewport->new;
$scrolled->add ($viewport);

# Maybe should work with Viewport passed directly to the crosshair, without
# the EventBox in between, by getting the secret viewport window as per
# Gtk2::Ex::Dragger.  But only no-window widgets in a viewport are affected.
#
my $eventbox = Gtk2::EventBox->new;
$viewport->add ($eventbox);

my $image = Gtk2::Image->new_from_file
  ('/usr/share/doc/libgtk2.0-doc/gtk/tree-view-coordinates.png');
$eventbox->add ($image);

my $cross = Gtk2::Ex::CrossHair->new (widgets => [ $eventbox ],
                                      foreground => 'orange');
my $dragger = Gtk2::Ex::Dragger->new
  (widget => $viewport,
   hadjustment => $scrolled->get('hadjustment'),
   vadjustment => $scrolled->get('vadjustment'),
   cursor => 'fleur');

$toplevel->add_events (['button-press-mask', 'key-press-mask']);
$toplevel->signal_connect
  (button_press_event =>
   sub {
     my ($widget, $event) = @_;
     if ($event->button == 1) {
       print "$progname: start button $widget\n";
       $cross->start ($event);
     } else {
       $dragger->start ($event);
     }
   });
$toplevel->signal_connect
  (key_press_event =>
   sub {
     my ($widget, $event) = @_;
     if ($event->keyval == Gtk2::Gdk->keyval_from_name('Escape')) {
       print "$progname: end key\n";
       $cross->end ($event);
       $dragger->stop ($event);
       print Dumper($cross);
       print "\n";
       print Dumper($dragger);
       print "\n";
       Scalar::Util::weaken ($viewport->{'Gtk2::Ex::WidgetCursor.installed'});
       my $wc = $viewport->{'Gtk2::Ex::WidgetCursor.installed'};
       print "x\n";

     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('space')) {
       print "$progname: start key\n";
       $cross->start ($event);

     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('r')) {
       print "$progname: redraw top left\n";
       $image->queue_draw_area (0, 0,
                                $image->allocation->width / 2,
                                $image->allocation->height / 2);
     }
     return 0; # propagate
   });

# print "line-style is ",$cross->get('line-style'),"\n";
$cross->signal_connect (moved => sub {
                          print "$progname: moved ",
                            join (' ', map {defined $_ ? $_ : 'undef'} @_),
                              "\n";
                        });
$cross->signal_connect
  (notify => sub {
     my ($cross, $pspec) = @_;
     my $pname = $pspec->get_name;
     my $value = $cross->get($pname);
     print "$progname: cross property $pname now ",
       defined $value ? $value : 'undef',"\n";
   });

$toplevel->show_all;
Gtk2->main;
exit 0;
