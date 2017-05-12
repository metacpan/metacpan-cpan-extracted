#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Image::Base::Text;
use Test;
plan tests => 1;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

# 3.018 for "ignore_object"
my $have_test_weaken = eval "use Test::Weaken 3.018; 1";
my $skip;
if (! $have_test_weaken) {
  MyTestHelpers::diag ("Test::Weaken 3.018 not available -- $@");
  $skip = "due to Test::Weaken 3.018 not available";
}
MyTestHelpers::diag ("Test::Weaken version ", Test::Weaken->VERSION);


{
  my $leaks = $have_test_weaken && Test::Weaken::leaks
    ({ constructor => sub {
         return Image::Base::Text->new (-width => 10, -height => 10);
       },
       ignore_object => Image::Base::Text->default_colour_to_character,
     });
  skip ($skip,
        defined $leaks,
        '',
        'deep garbage collection');
  if ($leaks) {
    require Data::Dumper;
    MyTestHelpers::diag (Data::Dumper::Dumper($leaks));
  }
}

exit 0;
