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

Gtk2::Rc->parse_string (<<HERE);
style "my_style" {
  xthickness = 10
}
class "Gtk2__Ex__Dashes" style "my_style"
HERE

Gtk2::Gdk::Window->set_debug_updates(1);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_default_size (-1, 200);

my $vbox = Gtk2::VBox->new;
$vbox->set_border_width(0);
$toplevel->add ($vbox);

my $spin = Gtk2::SpinButton->new_with_range (0, 999, 1);
$spin->set_direction ('rtl');
my $adj = $spin->get_adjustment;
$adj->set (value => 200);
$vbox->pack_start ($spin, 0,0,0);
$adj->signal_connect (value_changed => sub {
                        my ($width, $height) = $toplevel->get_size;
                        $toplevel->resize ($width, $adj->value);
                      });

my $hbox = Gtk2::HBox->new;
$hbox->set_border_width(0);
$vbox->pack_start ($hbox, 1,1,0);

my @dashes_list;
{
  my $dashes = Gtk2::Ex::Dashes->new (orientation => 'vertical');
  push @dashes_list, $dashes;
  $hbox->pack_start ($dashes, 1,1,0);
  print "$progname: ythickness ", $dashes->style->ythickness, "\n";
  my $req = $dashes->size_request;
  print "$progname: size_request ",$req->width,"x",$req->height,"\n";
}
{
  my $dashes = Gtk2::Ex::Dashes->new (orientation => 'vertical',
                                      width_request => 48,
                                      xalign => 1);
  push @dashes_list, $dashes;
  # $dashes->set_direction('rtl');
  $hbox->pack_start ($dashes, 1,1,0);
}
{
  my $dashes = Gtk2::Ex::Dashes->new (orientation => 'vertical',
                                      xalign => 0.5,
                                      yalign => 0);
  push @dashes_list, $dashes;
  $hbox->pack_start ($dashes, 1,1,0);
}
{
  my $button = Gtk2::Button->new_with_label ("expose lower");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub {
       foreach my $dashes (@dashes_list) {
         my $alloc = $dashes->allocation;
         my $y = int($alloc->height/2);
         $dashes->queue_draw_area ($alloc->x, $alloc->y + $y,
                                   $alloc->width, $alloc->height - $y);
       }
     });
}

$toplevel->show_all;
Gtk2->main;
exit 0;
