#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Glib::Ex::ConnectProperties;


# This example uses a "func_in" / "func_out" pair to make one spin button
# track the other, with an extra +100 in the second.
#
# A spin button operates on a value held in a Gtk2::Adjustment object and so
# it's the values on those adjustment objects which are linked.
#
#
# When there's just two properties like this you could also set it up with
# the offset on the func_out of the first, like
#
#    [$adj1, 'value', func_out => \&offset ],
#    [$adj2, 'value', func_out => \&unoffset ]
#
# which is a way of saying how the value should be mangled on its way out to
# the other party.
#
# But for three or more in a ConnectProperties group this is no good, you
# normally have to decide the range or set of values that's going to be the
# common denominator and transform in/out on whichever of the targets then
# needs them massaged.


my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $spin1 = Gtk2::SpinButton->new_with_range (0, 999, 1);
my $adj1 = $spin1->get_adjustment;
$vbox->pack_start ($spin1, 0,0,0);

my $spin2 = Gtk2::SpinButton->new_with_range (100,1099, 1);
my $adj2 = $spin2->get_adjustment;
$vbox->pack_start ($spin2, 0,0,0);

sub offset {
  my ($x) = @_;
  return $x + 100;
}
sub unoffset {
  my ($x) = @_;
  return $x - 100;
}
Glib::Ex::ConnectProperties->new ([$adj1, 'value'],
                                  [$adj2, 'value',
                                   func_in => \&offset,
                                   func_out => \&unoffset ]);

$toplevel->show_all;
Gtk2->main;
exit 0;
