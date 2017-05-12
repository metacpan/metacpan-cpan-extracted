#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

my $toplevel1 = Gtk2::Window->new('toplevel');
$toplevel1->signal_connect (destroy => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel1->add ($hbox);

my $vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($vbox, 1,1,0);

my $area = Gtk2::DrawingArea->new;
$area->set_size_request (100, 100);
$hbox->pack_start ($area, 1,1,0);

my $toplevel2 = Gtk2::Window->new('toplevel');
$toplevel2->signal_connect (destroy => sub { Gtk2->main_quit });

my $toplevel3 = Gtk2::Window->new('toplevel');
$toplevel3->signal_connect (destroy => sub { Gtk2->main_quit });


my $cross = Gtk2::Ex::CrossHair->new
  (widgets => [ $area, $toplevel2, $toplevel3 ],
   foreground => 'orange',
   active => 1,
  );
$cross->signal_connect (notify => sub {
                          my ($toplevel, $pspec, $self) = @_;
                          print "$progname: notify '",$pspec->get_name,"'\n";
                        });

{
  my $timer_id;
  my $idx = 0;
  my @delta = (20, 20, 20, -20, -20, -20);
  my $button = Gtk2::CheckButton->new_with_label ('Repos Toplevel');
  $button->set_tooltip_markup
    ("Check this to reposition the toplevel window under a timer, to test cross redraw");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    ('toggled' => sub {
       if ($button->get_active) {
         $timer_id ||= do {
           print "$progname: toplevel repositioning start\n";
           Glib::Timeout->add (1000, \&toplevel_repositioning_timer);
         };
       } else {
         if ($timer_id) {
           print "$progname: toplevel repositioning stop\n";
           Glib::Source->remove ($timer_id);
           $timer_id = undef;
         }
       }
     });
  sub toplevel_repositioning_timer {
    $idx++;
    if ($idx >= @delta) { $idx = 0; }
    my $delta = $delta[$idx];
    my ($x, $y) = $toplevel1->window->get_position;
    $x += $delta;
    $y += $delta;
    print "$progname: toplevel delta $delta reposition to $x,$y\n";
    $toplevel1->window->move ($x, $y);
    return 1; # keep running
  }
}

$toplevel1->show_all;
$toplevel2->show_all;
$toplevel3->show_all;

$toplevel1->move (300, 300);
$toplevel2->move (300, 100);
$toplevel3->move (100, 300);

Gtk2->main;
exit 0;
