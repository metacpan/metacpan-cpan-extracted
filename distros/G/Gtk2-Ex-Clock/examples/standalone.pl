#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Clock.
#
# Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Clock is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Clock.  If not, see <http://www.gnu.org/licenses/>.


# This is a bit of fun making an entire clock program based around
# Gtk2::Ex::Clock.  F10 or button3 brings up a menu to choose between the
# formats in @formats.
#
# Button1 does a drag, since the window title is disabled and you might have
# trouble remembering which window manager key starts a drag.  There's no
# snap-to-edge the way most window managers have though.
#

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Clock;

our @formats = (['Local Time',   '%H:%M'],
                ['With Seconds', '%H:%M:%S'],
                ['GMT',          '%H:%M GMT', 'GMT']);
my $initial_format = 0;

my $toplevel = Gtk2::Window->new('toplevel');

my $frame = Gtk2::Frame->new;
$frame->set (shadow_type => 'none');
$toplevel->add ($frame);

my $clock = Gtk2::Ex::Clock->new (format => '%a %I:%M%P');
$frame->add ($clock);

#------------------------------------------------------------------------------

my $menu = Gtk2::Menu->new;
my $radiogroup;
foreach my $format (@formats) {
  my ($name, $strftime, $timezone) = @$format;
  my $item = Gtk2::RadioMenuItem->new_with_label ($radiogroup, $name);
  $menu->add ($item);
  $radiogroup ||= $item;

  $item->signal_connect (activate => sub {
                           $clock->set (format => $strftime,
                                        timezone => $timezone);
                         });
}
($menu->get_children)[$initial_format]->activate;

$menu->add (Gtk2::SeparatorMenuItem->new);

my $accelgroup = Gtk2::AccelGroup->new;
$toplevel->add_accel_group ($accelgroup);
my $quit_button = Gtk2::ImageMenuItem->new_from_stock ('gtk-quit',$accelgroup);
$menu->add ($quit_button);
$quit_button->signal_connect (activate => sub { $toplevel->destroy });

$menu->show_all;

$toplevel->add_events (['button-press-mask',
                        'button-release-mask',
                        'button-motion-mask',
                        'key-press-mask']);
$toplevel->signal_connect
  (button_press_event => sub {
     my ($toplevel, $event) = @_;
     if ($event->button == 1) {
       drag_start ($event);
     } elsif ($event->button == 3) {
       $menu->popup (undef, undef, undef, undef,
                     $event->button, $event->time);
     }
   });
$toplevel->signal_connect
  (button_release_event => sub {
     my ($toplevel, $event) = @_;
     if ($event->button == 1) {
       drag_end ($event);
     }
   });
$toplevel->signal_connect
  (motion_notify_event => sub {
     my ($toplevel, $event) = @_;
     drag_move ($event);
   });

$toplevel->signal_connect
  (key_press_event => sub {
     my ($toplevel, $event) = @_;
     my $key = Gtk2::Gdk->keyval_name($event->keyval);
     if ($key eq 'F10') {
       $menu->popup (undef, undef,
                     \&menu_position_over_toplevel, undef,
                     0, $event->time);
     }
   });
sub menu_position_over_toplevel {
  return $toplevel->window->get_origin;
}


#------------------------------------------------------------------------------
my ($drag_x, $drag_y);
sub drag_start {
  my ($event) = @_;
  $drag_x = $event->x_root;
  $drag_y = $event->y_root;
}
sub drag_move {
  my ($event) = @_;
  if (defined $drag_x) { # when active
    my ($x, $y) = $toplevel->get_position;
    $x += $event->x_root - $drag_x;
    $y += $event->y_root - $drag_y;
    $toplevel->move ($x, $y);
    drag_start ($event);
  }
}
sub drag_end {
  my ($event) = @_;
  drag_move ($event);
  undef $drag_x;
}

#------------------------------------------------------------------------------

$toplevel->realize;
$toplevel->window->set_decorations (['border']);

$toplevel->signal_connect
  (destroy => sub {
     # explicitly destroy the menu since strange things can happen in perl's
     # final garbage collection with the accelgroup destroyed before the
     # menu items remove their accelerators from it
     $menu->destroy;
     Gtk2->main_quit;
   });
$toplevel->show_all;
Gtk2->main;
exit 0;
