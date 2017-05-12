#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Image-Base-PNGwriter.
#
# Image-Base-PNGwriter is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-PNGwriter is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-PNGwriter.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Test::More;
use Image::Base::PNGwriter;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# 3.018 for ignore_object=> option
eval "use Test::Weaken 3.018; 1"
  or plan skip_all => "due to Test::Weaken 3.018 not available -- $@";
diag ("Test::Weaken version ", Test::Weaken->VERSION);

plan tests => 1;

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub { return Image::Base::PNGwriter->new
                              (-width => 6, -height => 7);
                          },
       ignore_object => Image::Base::PNGwriter::_DEFAULT_PALETTE(),
     });
  is ($leaks, undef, 'deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
