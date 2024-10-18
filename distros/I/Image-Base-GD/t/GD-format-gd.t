#!/usr/bin/perl -w

# Copyright 2010, 2011, 2024 Kevin Ryde

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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Image::Base::GD;

# "gd" and "gd2" file formats were GD's internal dumps intended for
# quick reading and writing.  Incompatible change in libgd 2.3.2
# removed them.
use GD;
(GD::Image->can('gd') && GD::Image->can('gd2'))
  or plan skip_all => "due to no gd and/or gd2 format support in GD";

plan tests => 28;


#------------------------------------------------------------------------------
# save() / load()

my $filename = 'testfile.tmp';

foreach my $file_format ('gd', 'gd2') {
  {
    my $image = Image::Base::GD->new (-width  => 2,
                                      -height => 1,
                                      -file_format => $file_format);
    is ($image->get('-file_format'), $file_format);
    $image->xy (0,0, '#FFFFFF');
    $image->xy (1,0, '#000000');
    $image->save($filename);

    is ($image->get('-file'), $filename);
  }

  # new(-file)
  {
    my $image = Image::Base::GD->new (-file => $filename);
    is ($image->get('-file'), $filename);
    is ($image->get('-file_format'), $file_format);
    is ($image->get('-width'), 2);
    is ($image->get('-height'), 1);
    is ($image->xy(0,0), '#FFFFFF');
    is ($image->xy(1,0), '#000000');
  }

  # load()
  {
    my $image = Image::Base::GD->new (-width => 10,
                                      -height => 10);
    $image->load ($filename);
    is ($image->get('-file'), $filename);
    is ($image->get('-file_format'), $file_format);
    is ($image->get('-width'), 2);
    is ($image->get('-height'), 1);
    is ($image->xy(0,0), '#FFFFFF');
    is ($image->xy(1,0), '#000000');
  }
}

unlink $filename;
exit 0;
