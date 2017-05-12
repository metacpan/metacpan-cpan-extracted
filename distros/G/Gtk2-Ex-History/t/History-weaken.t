#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# Test::Weaken 2 for "constructor"
eval "use Test::Weaken 2; 1"
  or plan skip_all => "Test::Weaken 2 not available -- $@";
plan tests => 1;

require Gtk2::Ex::History;
{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub { return Gtk2::Ex::History->new },
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
