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

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require DateTime::TimeZone }
  or plan skip_all => "due to DateTime::TimeZone not available -- $@";

eval { require DateTime }
  or plan skip_all => "due to DateTime not available -- $@";

plan tests => 2;

require Gtk2::Ex::Clock;
MyTestHelpers::glib_gtk_versions();

diag "DateTime version ",DateTime->VERSION;
diag "DateTime::TimeZone version ",DateTime::TimeZone->VERSION;


#-----------------------------------------------------------------------------
# timezone / timezone-string aliasing

{
  my $dtz = DateTime::TimeZone->new (name => 'UTC');
  my $clock = Gtk2::Ex::Clock->new (timezone => $dtz);
  is ($clock->get('timezone-string'), 'UTC');
  is ($clock->get('timezone'), $dtz);
}

exit 0;
