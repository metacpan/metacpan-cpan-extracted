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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Image::Base::GD;
use GD;
GD::Image->can('png')
  or plan skip_all => "due to no png support in GD";

plan tests => 32;

my $test_filename = 'testfile.tmp';

#------------------------------------------------------------------------------
# save() default png

{
  my $image = Image::Base::GD->new (-width  => 2,
                                    -height => 1);
  $image->xy (0,0, '#FFFFFF');
  $image->xy (1,0, '#000000');
  $image->save($test_filename);

  is ($image->get('-file'), $test_filename);
}

# new(-file)
{
  my $image = Image::Base::GD->new (-file => $test_filename);
  is ($image->get('-file'), $test_filename);
  is ($image->get('-file_format'), 'png');
  is ($image->get('-width'), 2);
  is ($image->get('-height'), 1);
  is ($image->xy(0,0), '#FFFFFF');
  is ($image->xy(1,0), '#000000');
}


#------------------------------------------------------------------------------
# save() / load()

{
  my $image = Image::Base::GD->new (-width  => 2,
                                    -height => 1,
                                    -file_format => 'PNG');
  is ($image->get('-file_format'), 'PNG');
  $image->xy (0,0, '#FFFFFF');
  $image->xy (1,0, '#000000');
  $image->save($test_filename);

  is ($image->get('-file'), $test_filename);
}

# new(-file)
{
  my $image = Image::Base::GD->new (-file => $test_filename);
  is ($image->get('-file'), $test_filename);
  is ($image->get('-file_format'), 'png');
  is ($image->get('-width'), 2);
  is ($image->get('-height'), 1);
  is ($image->xy(0,0), '#FFFFFF');
  is ($image->xy(1,0), '#000000');
}

# load()
{
  my $image = Image::Base::GD->new (-width => 10,
                                    -height => 10);
  $image->load ($test_filename);
  is ($image->get('-file'), $test_filename);
  is ($image->get('-file_format'), 'png');
  is ($image->get('-width'), 2);
  is ($image->get('-height'), 1);
  is ($image->xy(0,0), '#FFFFFF');
  is ($image->xy(1,0), '#000000');
}


#------------------------------------------------------------------------------
# new() / load() of GIF8.png

{
  require Cwd;
  my $orig_cwd = Cwd::cwd();
  $orig_cwd =~ /(.*)/ and $orig_cwd = $1; # untaint

  chdir 't' or die "Cannot chdir to 't': $!";

  my $filename = 'GIF8.png';
  {
    my $image = Image::Base::GD->new (-width => 100, -height => 50);
    isnt ($image->get('-gd'), undef);

    my $ret = eval { $image->load($filename); 1 };
    my $err = $@;
    # diag "load of $filename: ", $err;

    is ($ret, 1, "load() $filename - completes");
    is ($err, '', "load() $filename - error message");
    isnt ($image->get('-gd'), undef);
    is ($image->get('-gd') && $image->get('-width'), 1);
    is ($image->get('-gd') && $image->get('-height'), 1);
  }
  {
    my $image = eval { Image::Base::GD->new (-file => $filename) };
    my $err = $@;
    isnt ($image, undef, "new() $filename");
    is ($err, '');
    isnt ($image && $image->get('-gd'), undef);
    is ($image && $image->get('-gd') && $image->get('-width'), 1);
    is ($image && $image->get('-gd') && $image->get('-height'), 1);
  }

  chdir $orig_cwd or die "Cannot chdir back to $orig_cwd: $!";
}

unlink $test_filename;
exit 0;
