#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Gtk2::Ex::ContainerBits;

{
  require Gtk2;
  my $hbox = Gtk2::HBox->new;

  {
    my $l1 = Gtk2::Label->new;
    $l1->signal_connect (destroy => sub { print "l1 destroy\n"; });
    $l1->signal_connect ('notify::parent' => sub { print "l1 parent\n"; });
    my $l2 = Gtk2::Label->new;
    $l2->signal_connect (destroy => sub { print "l2 destroy\n"; });
    $l2->signal_connect ('notify::parent' => sub { print "l2 parent\n"; });
    $hbox->add($l1);
    $hbox->add($l2);
  }

  Gtk2::Ex::ContainerBits::remove_all ($hbox);
  exit 0;
}
