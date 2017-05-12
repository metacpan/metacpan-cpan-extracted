#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Dashes.
#
# Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dashes.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::Dashes;

# Test::Weaken 2 for leaks()
eval "use Test::Weaken 2; 1"
  or plan skip_all => "due to Test::Weaken 2 not available -- $@";
diag ("Test::Weaken version ", Test::Weaken->VERSION);

plan tests => 1;

{
  my $leaks = Test::Weaken::leaks (sub { Gtk2::Ex::Dashes->new });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

exit 0;
