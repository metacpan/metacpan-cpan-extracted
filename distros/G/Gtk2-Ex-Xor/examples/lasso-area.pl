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


# This is a simple but typical use for the lasso to select an area.  What
# you do with it is a matter for the "ended" signal handler, in this case
# it's just a printout.
#


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Lasso;
use Data::Dumper;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $label = Gtk2::Label->new
  ('
Press and drag mouse button 1 to select an area.
Release the button, or Return or Esc to end.
Press Space to swap ends.
');
$vbox->pack_start ($label, 0,0,0);

my $area = Gtk2::DrawingArea->new;
$area->set_size_request (200, 100);
$area->modify_bg ('normal', Gtk2::Gdk::Color->parse ('black'));
$vbox->pack_start ($area, 1,1,0);

my $lasso = Gtk2::Ex::Lasso->new (widget => $area,
                                  foreground => 'yellow');
$lasso->signal_connect (ended => sub {
                          my ($lasso, $x1,$y1, $x2,$y2) = @_;
                          print "You selected area $x1,$y1 to $x2,$y2\n";
                        });
$lasso->signal_connect (aborted => sub {
                          my ($lasso) = @_;
                          print "You aborted the selection\n";
                        });

$area->add_events ('button-press-mask');
$area->signal_connect (button_press_event => sub {
                         my ($area, $event) = @_;
                         if ($event->button == 1) {
                           $lasso->start ($event);
                         }
                         return 0; # Gtk2::EVENT_PROPAGATE
                       });

$toplevel->show_all;
Gtk2->main;
exit 0;
