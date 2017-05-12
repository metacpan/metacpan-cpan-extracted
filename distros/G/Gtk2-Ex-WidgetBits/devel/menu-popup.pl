#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 1.220 '-init';
use Gtk2::Ex::MenuBits;

use FindBin;
my $progname = $FindBin::Script;

my $d = Gtk2::Gdk::Display->get_default;
my $s = $d->get_default_screen;
my $d2 = Gtk2::Gdk::Display->open (undef);
my $s2 = $d2->get_default_screen;
print "$progname: s  ", $s, "\n";
print "$progname: s2 ", $s2, "\n";

my $toplevel = Gtk2::Window->new('toplevel');
# $toplevel->set (screen => $s2);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->set_default_size (100, 100);

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $menu = Gtk2::Menu->new;
{
  my $item = Gtk2::TearoffMenuItem->new;
  $item->show;
  $menu->append ($item);
}
{
  my $item = Gtk2::MenuItem->new_with_label ('Foo');
  $item->show;
  $menu->append ($item);
}
print "$progname: initial parent ", $menu->parent, "\n";
print "$progname: initial screen ", $menu->get_screen, "\n";

{
  my $button = Gtk2::Button->new_with_label ("Popup");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (button_press_event => sub {
       my ($button, $event) = @_;
       print "$progname: event ",$event,"x\n";
       print "$progname: e cur ", Gtk2->get_current_event, "\n";
       print "$progname: event screen ", $event->window->get_screen, "\n";
       print "$progname: e cur screen ", Gtk2->get_current_event->window->get_screen, "\n";
       print "$progname: parent ", $menu->parent, "\n";
       # $menu->set_screen ($s);
       $menu->popup (undef, undef,
                     \&my_position, $toplevel,
                     $event->button, $event->time);
       print "$progname: pmenu screen ", $menu->get_screen, "\n";

       #      Glib::Timeout->add (2000,  # milliseconds
       #                          sub {
       #                            $menu->set_screen ($s);
       #                          });

       return Gtk2::EVENT_PROPAGATE;
     });
}
sub my_position {
  my ($menu, $x, $y) = @_;
  print "$progname: my_position() input  $x,$y\n";
  print "  toplevel mapped:   ", ($toplevel->mapped?"yes":"no"),"\n";
  print "  toplevel visible:  ", ($toplevel->visible?"yes":"no"),"\n";
  print "  toplevel iconfied: ", ($toplevel->visible?"yes":"no"),"\n";

  ($x, $y) = Gtk2::Ex::MenuBits::position_widget_topcentre
    ($menu, $x, $y, $toplevel);

  #     $x = 500;
  #   $y = 100;
  print "$progname: my_position() decide $x,$y\n";
  return ($x, $y, 1);
}

{
  my $button = Gtk2::Button->new_with_label ("Iconify");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (button_press_event => sub {
       my ($button, $event) = @_;
       print "$progname: iconify\n";
       $toplevel->iconify;
       Glib::Timeout->add
           (1000,  # milliseconds
            sub {
              print "$progname: popup\n";
              $menu->popup (undef, undef,
                            \&my_position, $toplevel,
                            0, 0);
            });


       return Gtk2::EVENT_PROPAGATE;
     });
}

$toplevel->show_all;
print "$progname: toplevel screen ", $toplevel->get_screen, "\n";

# $menu->popup (undef, undef,
#               # \&Gtk2::Ex::MenuBits::position_screen_centre, undef,
#               \&Gtk2::Ex::MenuBits::position_widget_topcentre, $toplevel,
#               # undef, undef,
#               1, 0);

Gtk2->main;
exit 0;
