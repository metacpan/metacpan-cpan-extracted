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


# This is a typical example to get a crosshair shown temporarily while a
# mouse button is pressed down.
#
# The status label is updated under the "moved" signal from the crosshair to
# show a current position.  In this case it just shows pixel X,Y, but you'd
# probably normally turn that into the coordinate system of a graph, or
# maybe a row/column of some text.
#
# When you drag the mouse outside the area the X,Y reported to the "moved"
# go negative, or beyond the width,height.  This is from the implicit button
# grab described in the CrossHair pod.  Usually it's a good thing, though
# it's possible you could want to stop displaying the position on wildly
# distant values.
#


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::CrossHair;
use Data::Dumper;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $label = Gtk2::Label->new ('
Press and hold the  mouse button in the area to show the cross.
');
$vbox->pack_start ($label, 0,0,0);

my $area = Gtk2::DrawingArea->new;
$area->set_size_request (200, 100);
$area->modify_bg ('normal', Gtk2::Gdk::Color->parse ('black'));
$vbox->pack_start ($area, 1,1,0);

my $status = Gtk2::Label->new;
$vbox->pack_start ($status, 0,0,0);

my $cross = Gtk2::Ex::CrossHair->new (widget => $area,
                                      foreground => 'green');
$cross->signal_connect (moved => sub {
                          my ($cross, $widget, $x, $y) = @_;
                          if (defined $x) {
                            $status->set_text ("now at $x,$y");
                          } else {
                            $status->set_text ('');
                          }
                        });

$area->add_events ('button-press-mask');
$area->signal_connect (button_press_event => sub {
                         my ($area, $event) = @_;
                         $cross->start ($event);
                         return 0; # Gtk2::EVENT_PROPAGATE
                       });

$toplevel->show_all;
Gtk2->main;
exit 0;
