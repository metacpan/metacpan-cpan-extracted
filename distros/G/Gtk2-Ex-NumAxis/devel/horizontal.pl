#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NumAxis.
#
# Gtk2-Ex-NumAxis is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NumAxis is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NumAxis.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use POSIX;
use Gtk2;
use Glib::Ex::ConnectProperties;
use Gtk2::Ex::NumAxis;

use FindBin;
my $progname = $FindBin::Script;

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (500, -1);

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $adj = Gtk2::Adjustment->new (100, # value
                                 -1000, # lower
                                 1000,  # upper
                                 10,   # step increment
                                 80,  # page increment
                                 100); # page size
my $axis = Gtk2::Ex::NumAxis->new(adjustment => $adj,
                                  orientation => 'horizontal',
                                  min_decimals => 2);
$axis->signal_connect (number_to_text => sub {
                         my ($axis, $number, $decimals) = @_;
                         return sprintf "%.*f\nblah", $decimals, $number;
                        });
$vbox->add($axis);

my $hscroll = Gtk2::HScrollbar->new($adj);
$vbox->pack_start($hscroll, 0,0,0);

{
  my $button = Gtk2::CheckButton->new_with_label ("inverted");
  Glib::Ex::ConnectProperties->new ([$axis,'inverted'],
                                    [$hscroll,'inverted'],
                                    [$button,'active']);
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $spin = Gtk2::SpinButton->new_with_range (0, 10*$adj->page_size, 10);
  Glib::Ex::ConnectProperties->new ([$adj,'page-size'],
                                    [$spin,'value']);
  $vbox->pack_start ($spin, 0,0,0);
}
{
  my $spin = Gtk2::SpinButton->new_with_range (0, 50, 1);
  Glib::Ex::ConnectProperties->new ([$axis,'min-decimals'],
                                    [$spin,'value']);
  $vbox->pack_start ($spin, 0,0,0);
}

$toplevel->show_all;

Gtk2->main();
exit 0;
