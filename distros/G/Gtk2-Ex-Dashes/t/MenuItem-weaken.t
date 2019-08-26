#!/usr/bin/perl -w

# Copyright 2010, 2012 Kevin Ryde

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
use Gtk2::Ex::Dashes::MenuItem;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# Test::Weaken 3 for "contents"
eval 'use Test::Weaken 3;
      use Test::Weaken::Gtk2;
      1'
  or plan skip_all => "due to Test::Weaken 3 and/or Test::Weaken::Gtk2 not available -- $@";
diag ("Test::Weaken version ", Test::Weaken->VERSION);

plan tests => 1;

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub { Gtk2::Ex::Dashes::MenuItem->new },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
}

exit 0;
