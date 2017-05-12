#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
use Test::More tests => 8;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Image::Base::GD;


#------------------------------------------------------------------------------
# load() original GD 1.x format

my $filename = 't/GD-format-gd1.gd';

# new(-file)
{
  my $image = Image::Base::GD->new (-file => $filename);
  $image->add_colours('#111111','#222222');
  is ($image->get('-file'), $filename);
  is ($image->get('-file_format'), 'gd');
  is ($image->get('-width'), 13);
  is ($image->get('-height'), 17);
}

# load()
{
  my $image = Image::Base::GD->new (-width => 10,
                                    -height => 10);
  $image->load ($filename);
  $image->add_colours('#111111','#222222');
  is ($image->get('-file'), $filename);
  is ($image->get('-file_format'), 'gd');
  is ($image->get('-width'), 13);
  is ($image->get('-height'), 17);
}

exit 0;
