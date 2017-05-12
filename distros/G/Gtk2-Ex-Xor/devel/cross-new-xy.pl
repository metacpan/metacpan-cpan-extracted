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

{
  require Devel::StackTrace;
  $SIG{'__WARN__'} = sub {
    print Devel::StackTrace->new->as_string;
    warn @_;
  };
}

my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $layout = Gtk2::Layout->new;
$toplevel->add ($layout);

my $f1 = Gtk2::Frame->new;
my $a1 = Gtk2::DrawingArea->new;
$a1->set_size_request (100, 100);
$f1->add ($a1);

my $f2 = Gtk2::Frame->new;
my $a2 = Gtk2::DrawingArea->new;
$a2->set_size_request (100, 100);
$f2->add ($a2);

$layout->put ($f2, 50,50);
$layout->put ($f1, 0,0);

my $cross = Gtk2::Ex::CrossHair->new
  (widgets => [ $a1, $a2 ],
   foreground => 'orange',
   active => 1,
  );
$cross->signal_connect (notify => sub {
                          my ($toplevel, $pspec, $self) = @_;
                          print "$progname: notify '",$pspec->get_name,"'\n";
                        });
$cross->signal_connect
  (moved => sub {
     print "$progname: moved ",
       join(' ', map {defined $_ ? $_ : 'undef'} @_),  "\n";
   });

$toplevel->add_events (['key-press-mask']);
$toplevel->signal_connect
  (key_press_event =>
   sub {
     my ($widget, $event) = @_;

     if ($event->keyval == Gtk2::Gdk->keyval_from_name('c')) {
       $cross->start ($event);
       return 1; # Gtk2::EVENT_STOP
       
     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('e')) {
       $cross->end;
       return 1; # Gtk2::EVENT_STOP
       
     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('x')) {
       $cross->set (widgets => [$a2]);
       return 1; # Gtk2::EVENT_STOP
     }
     return 0; # Gtk2::EVENT_PROPAGATE
   });

# if (0) {
#   my $timer_id;
#   my $idx = 0;
#   my @delta = (20, 20, 20, -20, -20, -20);
#   my $button = Gtk2::CheckButton->new_with_label ('Repos Toplevel');
#   $button->set_tooltip_markup
#     ("Check this to reposition the toplevel window under a timer, to test cross redraw");
#   $vbox->pack_start ($button, 0,0,0);
#   $button->signal_connect
#     ('toggled' => sub {
#        if ($button->get_active) {
#          $timer_id ||= do {
#            print "$progname: toplevel repositioning start\n";
#            Glib::Timeout->add (1000, \&toplevel_repositioning_timer);
#          };
#        } else {
#          if ($timer_id) {
#            print "$progname: toplevel repositioning stop\n";
#            Glib::Source->remove ($timer_id);
#            $timer_id = undef;
#          }
#        }
#      });
#   sub toplevel_repositioning_timer {
#     $idx++;
#     if ($idx >= @delta) { $idx = 0; }
#     my $delta = $delta[$idx];
#     my ($x, $y) = $toplevel->window->get_position;
#     $x += $delta;
#     $y += $delta;
#     print "$progname: toplevel delta $delta reposition to $x,$y\n";
#     $toplevel->window->move ($x, $y);
#     return 1; # keep running
#   }
# }

$toplevel->show_all;
Gtk2->main;
exit 0;
