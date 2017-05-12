#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Imager.
#
# Image-Base-Imager is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Imager is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Imager.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use warnings;
use Test;

my $test_count = (tests => 1)[1];
plan tests => $test_count;

use Image::Base::Imager;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

if (! eval "use Test::Weaken 2.000; 1") {
  MyTestHelpers::diag("Test::Weaken 2.000 not available -- $@");
  foreach (1 .. $test_count) {
    skip ('due to Test::Weaken 2.000 not available', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ("Test::Weaken version ", Test::Weaken->VERSION);


{
  my $leaks = Test::Weaken::leaks
    (sub { return Image::Base::Imager->new (-width => 6, -height => 7) });
  ok ($leaks, undef, 'deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
