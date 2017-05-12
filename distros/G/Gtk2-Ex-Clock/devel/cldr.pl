#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

use strict;
use warnings;
use Time::HiRes;
use DateTime;

print "DateTime::DefaultLocale is ", DateTime->DefaultLocale, "\n";
my $tod = Time::HiRes::gettimeofday();
my $t = DateTime->from_epoch (epoch => $tod);
print $t->format_cldr("'today is 'EEEE  GG QQQ QQQQ"), "\n";
exit 0;
