#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Dashes.
#
# Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dashes.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Dashes;

use FindBin;
my $progname = $FindBin::Script;

Gtk2::Gdk::Window->set_debug_updates(1);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_default_size (100, -1);

my $vbox = Gtk2::VBox->new;
$vbox->set_border_width(0);
$toplevel->add ($vbox);

my $spin = Gtk2::SpinButton->new_with_range (0, 999, 1);
$spin->set_direction ('rtl');
my $adj = $spin->get_adjustment;
$adj->set (value => 100);
$vbox->pack_start ($spin, 0,0,0);
$adj->signal_connect (value_changed => sub {
                        my (undef, $height) = $toplevel->get_size;
                        $toplevel->resize ($adj->value, $height);
                      });

#   require Glib::Ex::ConnectProperties;
#   Glib::Ex::ConnectProperties->new ([$spin->get_adjustment,'value'],
#                                     [$dashes,'width_request']);

my @dashes_list;
{
  my $dashes = Gtk2::Ex::Dashes->new;
  push @dashes_list, $dashes;
  $vbox->pack_start ($dashes, 1,1,0);
  print "$progname: ythickness ", $dashes->style->ythickness, "\n";
  my $req = $dashes->size_request;
  print "$progname: size_request ",$req->width,"x",$req->height,"\n";
}
Gtk2::Rc->parse_string (<<HERE);
style "my_style" {
  ythickness = 20
}
class "Gtk2__Ex__Dashes" style "my_style"
HERE

{
  my $dashes = Gtk2::Ex::Dashes->new (width_request => 48,
                                      xalign => 1);
  print "$progname: ythickness ", $dashes->style->ythickness, "\n";
  push @dashes_list, $dashes;
  # $dashes->set_direction('rtl');
  $vbox->pack_start ($dashes, 1,1,0);
}
{
  my $dashes = Gtk2::Ex::Dashes->new;
  push @dashes_list, $dashes;
  $dashes->set(xalign => 0.5,
               yalign => 0);
  $vbox->pack_start ($dashes, 1,1,0);
}
{
  my $button = Gtk2::Button->new_with_label ("expose right");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub {
       foreach my $dashes (@dashes_list) {
         my $alloc = $dashes->allocation;
         my $x = int($alloc->width/2);
         $dashes->queue_draw_area ($alloc->x + $x, $alloc->y,
                                   $alloc->width-$x, $alloc->height);
       }
     });
}

my $tearoff = Gtk2::TearoffMenuItem->new;
print "$progname: tearoff border ", $tearoff->get_border_width,
  ",", $tearoff->get_border_width, "\n";

$toplevel->show_all;
print "$progname: ythickness after show ", $dashes_list[1]->style->ythickness, "\n";

Gtk2->main;
exit 0;
