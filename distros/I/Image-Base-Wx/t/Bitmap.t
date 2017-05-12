#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require Wx }
  or plan skip_all => "due to Wx display not available -- $@";

plan tests => 2509;

use_ok ('Image::Base::Wx::Bitmap');
diag "Image::Base version ", Image::Base->VERSION;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 4;
is ($Image::Base::Wx::Bitmap::VERSION,
    $want_version, 'VERSION variable');
is (Image::Base::Wx::Bitmap->VERSION,
    $want_version, 'VERSION class method');

ok (eval { Image::Base::Wx::Bitmap->VERSION($want_version); 1 },
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::Wx::Bitmap->VERSION($check_version); 1 },
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# save() then load() each format

{
  Wx::InitAllImageHandlers();
  my @file_formats = (qw(BMP
                         GIF
                         JPEG
                         PCX
                         PNG
                         PNM
                         TIF
                         CUR
                         ICO
                         ANI
                         XPM
                       ));
  my $filename = 'tempfile';
  foreach my $file_format (@file_formats) {
  SKIP: {
      my $got_file_format;
      {
        my $image = Image::Base::Wx::Bitmap->new
          (-width => 20, -height => 10,
           -file_format => $file_format);
        eval { $image->save($filename); 1 }
          or skip "due to cannot save $file_format", 1;
      }
      {
        my $image = Image::Base::Wx::Bitmap->new
          (-file => $filename);
        $got_file_format = $image->get('-file_format');
        is ($got_file_format, $file_format);
      }
    }
  }
  unlink $filename;
}

#------------------------------------------------------------------------------
# line()

{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10, -depth => 1);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->line (5,5, 7,7, 'white', 0);
  is ($image->xy (4,4), '#000000');
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (5,6), '#000000');
  is ($image->xy (6,6), '#FFFFFF');
  is ($image->xy (7,7), '#FFFFFF');
  is ($image->xy (8,8), '#000000');
  # require MyTestImageBase;
  # MyTestImageBase::dump_image($image);
}
{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->line (0,0, 2,2, 'white', 1);
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#000000');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# new()

{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Wx::Bitmap');

  is ($image->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $image->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  is ($image->get('-file'), undef, 'get() -file');
  is ($image->get('-width'),  21, 'get() -width');
  is ($image->get('-height'), 10, 'get() -height');
  # cmp_ok ($image->get('-depth'), '>', 0, 'get() -depth');
}

{
  my $wxbitmap = Wx::Bitmap->new(32,16);
  my $image = Image::Base::Wx::Bitmap->new
    (-wxbitmap => $wxbitmap);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Wx::Bitmap');

  is ($image->get('-file'), undef, 'get() -file');
  is ($image->get('-width'),  32, 'get() -width');
  is ($image->get('-height'), 16, 'get() -height');
  # is ($image->get('-depth'),  1, 'get() -depth');
}


#------------------------------------------------------------------------------
# new() clone

{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10);
  my $i2 = $image->new;
  $image->xy(0,0, '#000000');
  $i2->xy(0,0, '#FFFFFF');
  ### $image
  ### $i2
  isnt ($image->xy(0,0),
        $i2->xy(0,0));
}


#------------------------------------------------------------------------------
# load()

# diag "image handlers:";
# foreach my $handler (Wx::Bitmap::GetHandlers()) {
#   diag "  $handler";
# }
# Wx::InitAllImageHandlers();


{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 1, -height => 1);
  eval { $image->load('nosuchfile') };
  my $err = $@;
  diag "load error as expected: ",$err;
  like ($err, qr/Error|Cannot/i,
        'load(nosuchfile)');
}

#------------------------------------------------------------------------------
# save()

# Wx::InitAllImageHandlers();
{
  my $filename = 'tempfile.bmp';
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 20, -height => 10,
     -file_format => 'bmp');
  {
    $image->save($filename);
    unlink $filename;
  }
  {
    my $image = Image::Base::Wx::Bitmap->new 
      (-width => 20, -height => 10,
       -file_format => 'bmp');
    eval { $image->save('/no/such/direct/ory/test.bmp') };
    my $err = $@;
    diag "save error as expected: ",$err;
    like ($err, qr/Error|Cannot/i,
          'save(no/such/dir)');
  }
}


#------------------------------------------------------------------------------
# xy

{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->xy (2,2, 'black');
  $image->xy (3,3, 'white');
  $image->xy (4,4, '#ffffff');
  is ($image->xy (2,2), '#000000', 'xy()  ');
  is ($image->xy (3,3), '#FFFFFF', 'xy() *');
  is ($image->xy (4,4), '#FFFFFF', 'xy() *');
}

#------------------------------------------------------------------------------
# rectangle

{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->rectangle (5,5, 7,7, 'white', 0);
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (6,6), '#000000');
  is ($image->xy (7,6), '#FFFFFF');
  is ($image->xy (8,8), '#000000');
  # require MyTestImageBase;
  # MyTestImageBase::dump_image($image);
}
{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->rectangle (0,0, 2,2, '#FFFFFF', 1);
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#FFFFFF');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# diamond()

{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->diamond (0,0, 20,9, 'black', 1);
  $image->diamond (5,5, 7,7, 'white', 0);
}

#------------------------------------------------------------------------------
# ellipse()

{
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10);
  $image->rectangle (0,0, 20,9, 'black', 1);
  $image->ellipse (0,0, 20,9, 'black', 1);
  $image->ellipse (5,5, 7,7, 'white', 0);
}

#------------------------------------------------------------------------------

{
  require MyTestImageBase;
  my $image = Image::Base::Wx::Bitmap->new
    (-width => 21, -height => 10);

  local $MyTestImageBase::white = 'white';
  local $MyTestImageBase::black = 'black';

  # require MyTestImageBase;
  # MyTestImageBase::dump_image($image);

  MyTestImageBase::check_image ($image,
                                big_fetch_expect => '#FFFFFF');
  MyTestImageBase::check_diamond ($image);
}

# monochrome
{
  #   require MyTestImageBase;
  #   # my $bitmap = Wx::Pixmap->new ($rootwin,
  #   #                                      21,10, 1);
  #   my $image = Image::Base::Wx::Bitmap->new
  #     (-wxbitmap => $wxbitmap,
  #      -width => 21, -height => 10);
  local $MyTestImageBase::white = 1;
  local $MyTestImageBase::black = 0;
  #   MyTestImageBase::check_image ($image);
}

exit 0;
