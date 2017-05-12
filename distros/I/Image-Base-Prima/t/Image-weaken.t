#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Prima.
#
# Image-Base-Prima is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Prima is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Prima.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 1)[1];
plan tests => $test_count;

# Test::Weaken 3 for "contents"
if (! eval 'use Test::Weaken 3; 1') {
  MyTestHelpers::diag ("Test::Weaken 3 not available -- $@");
  foreach (1 .. $test_count) {
    skip ('Test::Weaken 3 not available', 1, 1);
  }
  exit 0;
}

use Prima::noX11; # without connecting to the server
require Image::Base::Prima::Image;

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Image::Base::Prima::Image->new;
       },
     });
  ok ($leaks, undef, 'new() defaults');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
