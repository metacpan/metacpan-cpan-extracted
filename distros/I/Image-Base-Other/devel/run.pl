#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Smart::Comments;

# use lib "$ENV{HOME}/p/base/108/lib";

{
  require File::Temp;
  my $stdout = \*STDOUT;
  my $fh = File::Temp->new;
  my $eq = ($fh == $stdout);
  # my $eq = ($fh == $fh);
  print "$fh $eq\n";
  exit 0;
}

{
  require Image::Base::Text;
  print "Image::Base version ", Image::Base->VERSION, "\n";
  my $image = Image::Base::Text->new (-width => 30, -height => 30);

  $image->rectangle (0,0, 29,29, ' ', 1);
  $image->ellipse (1,1, 28,28, '*');
  $image->save('>mystrangename');

  exit 0;
}

{
  require Image::Base::Text;
  print "Image::Base version ", Image::Base->VERSION, "\n";
  my $image = Image::Base::Text->new (-width => 10, -height => 10);

  # $image->rectangle (3,3, 7,7, '#FFFF0000FFFF');

  $image->rectangle (0,0, 9,9, 'black', 1);
  $image->line (0,0, 5,9, '#FFFF0000FFFF');
  $image->save('/dev/stdout');

  $image->rectangle (0,0, 9,9, 'black', 1);
  $image->line (0,0, 9,5, '#FFFF0000FFFF');
  $image->save('/dev/stdout');

  $image->rectangle (0,0, 9,9, 'black', 1);
  $image->line (0,5, 9,0, '#FFFF0000FFFF');
  $image->save('/dev/stdout');

  $image->rectangle (0,0, 9,9, 'black', 1);
  $image->line (0,9, 5,0, '#FFFF0000FFFF');
  $image->save('/dev/stdout');

  $image->rectangle (0,0, 9,9, 'black', 1);
  $image->line (3,3, 9,3, '#FFFF0000FFFF');
  $image->save('/dev/stdout');

  $image->rectangle (0,0, 9,9, 'black', 1);
  $image->line (3,3, 3,9, '#FFFF0000FFFF');
  $image->save('/dev/stdout');

  exit 0;
}
