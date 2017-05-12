#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Data::Dumper;
use Gtk2 '-init';
use Gtk2::Ex::TextView::FollowAppend;

use FindBin;
my $progname = $FindBin::Script;

my $textbuf = Gtk2::TextBuffer->new;
my $textview;

# $textview = Gtk2::TextView->new_with_buffer ($textbuf);
# undef $textview;

$textview = Gtk2::Ex::TextView::FollowAppend->new (buffer => $textbuf);
undef $textview;

# $textview = Gtk2::Ex::TextView::FollowAppend->new_with_buffer ($textbuf);
# undef $textview;

exit 0;
