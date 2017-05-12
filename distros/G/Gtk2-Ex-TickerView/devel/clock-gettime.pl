#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Time::HiRes qw(clock_gettime clock_getres CLOCK_REALTIME);

print "clock_getres(CLOCK_REALTIME) is ", clock_getres(CLOCK_REALTIME), "\n";
foreach (0 .. 30) {
  printf "%.6f\n", clock_gettime(CLOCK_REALTIME);
}
exit 0;
