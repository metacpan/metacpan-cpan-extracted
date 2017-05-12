#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::AdjustmentBits;

# uncomment this to run the ### lines
use Smart::Comments;

my $adj = Gtk2::Adjustment->new (0,0,0,0,0,0);
$adj->signal_connect (changed => sub {
                        ### changed signal
                      });
$adj->signal_connect (value_changed => sub {
                        ### value-changed signal
                      });
$adj->signal_connect (notify => sub {
                        my ($adj, $pspec) = @_;
                        ### notify signal: $pspec->get_name
                      });
### upper: $adj->upper
$adj->configure (0,0,0,0,0,0);
### upper: $adj->upper
