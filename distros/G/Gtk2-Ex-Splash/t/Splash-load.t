#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Splash.
#
# Gtk2-Ex-Splash is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Splash is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Splash.  If not, see <http://www.gnu.org/licenses/>.


## no critic (RequireUseStrict, RequireUseWarnings)
use Gtk2::Ex::Splash;

if (Gtk2->init_check) {
  my $splash = Gtk2::Ex::Splash->new;
  $splash->destroy;
}

use Test::More tests => 1;
ok (1, 'Gtk2::Ex::Splash load as first thing');
exit 0;
