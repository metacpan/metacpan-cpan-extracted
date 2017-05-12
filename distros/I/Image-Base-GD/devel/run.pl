#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;

use Smart::Comments;

{
  my @ords = grep { ! (($_ >= 0x7F && $_ <= 0x9F)
                       || ($_ >= 0xD800 && $_ <= 0xDFFF)
                       || ($_ >= 0xFDD0 && $_ <= 0xFDEF)
                       || ($_ >= 0xFFFE && $_ <= 0xFFFF)
                       || ($_ >= 0x1FFFE && $_ <= 0x1FFFF)) }
    32 .. 0x2FA1D;
  foreach my $ord (@ords) {
    my $c = chr($ord);
    if ($c =~ /[[:xdigit:]]/) {
      my $h = hex($c);
      print "$ord  $h\n";
    }

  }
  exit 0;
}

{
  require Image::Base::GD;
  my $gd = Image::Base::GD->new (-width => 10, -height => 10);
  $gd->rectangle (0,0, 9,9, 'black');
  $gd->rectangle (3,3, 7,7, '#FFFF0000FFFF');

  exit 0;
}
