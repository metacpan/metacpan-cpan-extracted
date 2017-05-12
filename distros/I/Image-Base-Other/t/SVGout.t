#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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
use Test;
BEGIN {
  plan tests => 12;
}

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Image::Base::SVGout;
MyTestHelpers::diag("Image::Base version ", Image::Base->VERSION);


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 9;
  ok ($Image::Base::SVGout::VERSION, $want_version, 'VERSION variable');
  ok (Image::Base::SVGout->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Image::Base::SVGout->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Image::Base::SVGout->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $image = Image::Base::SVGout->new;
  ok ($image->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $image->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# new()

{
  my $image = Image::Base::SVGout->new (-width => 6,
                                        -height => 7);
  ok (! defined $image->get('-file'),
      1);
  ok ($image->get('-height'),
      7);
  ok (defined $image && $image->isa('Image::Base') && 1,
      1);
  ok (defined $image && $image->isa('Image::Base::SVGout') && 1,
      1);
}

#------------------------------------------------------------------------------
# -width change

{
  my $image = Image::Base::SVGout->new (-width => 10,
                                        -height => 10);
  $image->set (-width => 15);
  ok ($image->get('-width'), 15);
}

#------------------------------------------------------------------------------

exit 0;
