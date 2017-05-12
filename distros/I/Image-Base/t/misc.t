#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base.
#
# Image-Base is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Image-Base.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test;
BEGIN {
  plan tests => 5;
}

{
  package MyTestImage;
  use Image::Base;
  use vars '@ISA';
  @ISA = ('Image::Base');
  sub new {
    my $class = shift;
    return bless { @_}, $class;
  }
}

#------------------------------------------------------------------------------
# VERSION

my $want_version = 1.17;
ok ($Image::Base::VERSION,
    $want_version,
    'VERSION variable');
ok (Image::Base->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { Image::Base->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");


#------------------------------------------------------------------------------
# add_colours()

{
  # just that the method exists
  my $image = MyTestImage->new;
  $image->add_colours ('red','#112233');
  ok (defined $image->can('add_colours'),
      1,
      'add_colours() exists');
}

exit 0;
