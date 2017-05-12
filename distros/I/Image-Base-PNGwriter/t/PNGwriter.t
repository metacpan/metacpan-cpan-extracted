#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-PNGwriter.
#
# Image-Base-PNGwriter is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-PNGwriter is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-PNGwriter.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use warnings;
use Test::More tests => 2628;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Image::Base::PNGwriter;
diag "Image::Base version ", Image::Base->VERSION;


sub my_bounding_box {
  my ($image, $x1,$y1, $x2,$y2, $black, $white) = @_;
  my ($width, $height) = $image->get('-width','-height');

  my @bad;
  foreach my $y ($y1-1, $y2+1) {
    next if $y < 0 || $y >= $height;
    foreach my $x ($x1-1 .. $x2-1) {
      next if $x < 0 || $x >= $width;
      my $got = $image->xy($x,$y);
      if ($got ne $black) {
        push @bad, "$x,$y=$got";
      }
    }
  }
  foreach my $x ($x1-1, $x2+1) {
    next if $x < 0 || $x >= $width;
    foreach my $y ($y1 .. $y2) {
      my $got = $image->xy($x,$y);
      if ($got ne $black) {
        push @bad, "$x,$y=$got";
      }
    }
  }

  my $found_set;
 Y_SET: foreach my $y ($y1, $y2) {
    next if $y < 0 || $y >= $height;
    foreach my $x ($x1 .. $x2) {
      my $got = $image->xy($x,$y);
      if ($got ne $black) {
        $found_set = 1;
        last Y_SET;
      }
    }
  }
 X_SET: foreach my $x ($x1, $x2) {
    next if $x < 0 || $x >= $width;
    foreach my $y ($y1+1 .. $y2-1) {
      next if $y < $y1 || $y > $y2;
      my $got = $image->xy($x,$y);
      if ($got ne $black) {
        $found_set = 1;
        last X_SET;
      }
    }
  }

  if (! $found_set) {
    push @bad, 'nothing set within';
  }

  return join("\n", @bad);
}

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 8;
  is ($Image::Base::PNGwriter::VERSION, $want_version, 'VERSION variable');
  is (Image::Base::PNGwriter->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Image::Base::PNGwriter->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Image::Base::PNGwriter->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $image = Image::Base::PNGwriter->new (-pngwriter => 'dummy');
  is ($image->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $image->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# colour_to_rgb

{
  my $image = Image::Base::PNGwriter->new (-pngwriter => 'dummy');
  foreach my $elem (['#F0F',          [1.0, 0.0, 1.0] ],
                    ['#FF00FF',       [1.0, 0.0, 1.0] ],
                    ['#FFFFFF000',    [1.0, 1.0, 0.0] ],
                    ['#FFFFFFFF0000', [1.0, 1.0, 0.0] ],
                    ['black', [0,0,0] ],
                    ['white', [1,1,1] ],
                   ) {
    my ($colour, $want) = @$elem;
    is_deeply ([$image->colour_to_drgb ($colour)],
               $want,
               "colour_to_drgb '$colour'");
  }
}

#------------------------------------------------------------------------------
# new()

{
  my $image = Image::Base::PNGwriter->new (-width => 1,
                                           -height => 1);
  is ($image->get('-zlib_compression'), -1,
      'new() -zlib_compression default');
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::PNGwriter');

  $image->set(-zlib_compression => 7);
  is ($image->get('-zlib_compression'), 7,
      'set() -zlib_compression to 7');

  $image->set(-file => 'PNGwriter-test.tmp');
  is ($image->get('-file'), 'PNGwriter-test.tmp', 'set() -file');
}

# new from -pngwriter object, per POD
{
  my $pwobj = Image::PNGwriter->new(200,100, 0, '/tmp/foo.png');
  my $image = Image::Base::PNGwriter->new (-pngwriter => $pwobj);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::PNGwriter');
  is ($image->get('-width'), 200);
  is ($image->get('-height'), 100);
}

#------------------------------------------------------------------------------
# save() / load()

my $have_File_Temp = eval { require File::Temp; 1 };
if (! $have_File_Temp) {
  diag "File::Temp not available: $@";
}

SKIP: {
  $have_File_Temp
    or skip 'File::Temp not available', 6;

  my $fh = File::Temp->new;
  my $filename = $fh->filename;

  # save file
  {
    my $image = Image::Base::PNGwriter->new (-width => 1,
                                                             -height => 1);
    $image->xy (0,0, '#FFFFFF');
    $image->set(-file => $filename,
                -zlib_compression => 1);
    is ($image->get('-file'), $filename);
    $image->save;
    cmp_ok (-s $filename, '>', 0);
  }

  # existing file with new(-file)
  {
    my $image = Image::Base::PNGwriter->new (-width => 1,
                                                             -height => 1,
                                                             -file => $filename);
    is ($image->get('-file'), $filename);
    is ($image->xy (0,0), '#FFFFFF');
  }

  # existing file with load()
  {
    my $image = Image::Base::PNGwriter->new (-width => 1,
                                                             -height => 1);
    $image->load ($filename);
    is ($image->get('-file'), $filename);
    is ($image->xy (0,0), '#FFFFFF');
  }
}


#------------------------------------------------------------------------------
# xy

{
  my $image = Image::Base::PNGwriter->new (-width => 20,
                                           -height => 10);
  $image->xy (0,0, '#112233');
  $image->xy (1,1, '#445566');
  is (my_bounding_box ($image, 0,0, 1,1, '#000000'),
      '', 'points');
  is ($image->xy (0,0), '#112233');
  is ($image->xy (1,1), '#445566');
}

#------------------------------------------------------------------------------
# rectangle

{
  my $image = Image::Base::PNGwriter->new (-width => 20,
                                           -height => 10);
  $image->rectangle (15,5, 17,7, '#FFFFFF', 0);
  is (my_bounding_box ($image, 15,5, 17,7, '#000000'),
      '', 'rectangle');
  is ($image->xy (15,5), '#FFFFFF');
  is ($image->xy (16,6), '#000000');
  is ($image->xy (17,6), '#FFFFFF');
  is ($image->xy (18,8), '#000000');
}
{
  my $image = Image::Base::PNGwriter->new (-width => 20,
                                                           -height => 10);
  $image->rectangle (0,0, 2,2, '#FFFFFF', 1);
  is (my_bounding_box ($image, 0,0, 2,2, '#000000'),
      '', 'rectangle');
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#FFFFFF');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# line

{
  my $image = Image::Base::PNGwriter->new (-width => 20,
                                           -height => 10);
  $image->line (15,5, 18,8, '#FFFFFF', 0);
  is (my_bounding_box ($image, 15,5, 18,8, '#000000'),
      '', 'line');
  is ($image->xy (14,4), '#000000');
  is ($image->xy (15,5), '#FFFFFF');
  is ($image->xy (15,6), '#000000');
  is ($image->xy (16,6), '#FFFFFF');
  is ($image->xy (17,7), '#FFFFFF');
  is ($image->xy (18,8), '#FFFFFF');
  is ($image->xy (19,9), '#000000');
}
{
  my $image = Image::Base::PNGwriter->new (-width => 20,
                                                           -height => 10);
  $image->line (0,0, 2,2, '#FFFFFF', 1);
  is (my_bounding_box ($image, 0,0, 2,2, '#000000'),
      '', 'line');
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#000000');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# ellipse

{
  my $image = Image::Base::PNGwriter->new (-width => 20,
                                           -height => 10);
  $image->ellipse (11,1, 13,3, '#FFFFFF');
  is (my_bounding_box ($image, 11,1, 13,3, '#000000'),
      '', 'ellipse');
  is ($image->xy (10,0), '#000000');
  is ($image->xy (10,1), '#000000');
  is ($image->xy (10,2), '#000000');
  is ($image->xy (10,3), '#000000');
  is ($image->xy (10,4), '#000000');

  is ($image->xy (14,0), '#000000');
  is ($image->xy (14,1), '#000000');
  is ($image->xy (14,2), '#000000');
  is ($image->xy (14,3), '#000000');
  is ($image->xy (14,4), '#000000');

  is ($image->xy (11,2), '#FFFFFF');

  is ($image->xy (11,0), '#000000');
  is ($image->xy (12,0), '#000000');
  is ($image->xy (13,0), '#000000');

  is ($image->xy (11,4), '#000000');
  is ($image->xy (12,4), '#000000');
  is ($image->xy (13,4), '#000000');
}
{
  my $image = Image::Base::PNGwriter->new (-width => 20,
                                           -height => 10);
  $image->ellipse (15,5, 15,5, '#FFFFFF');
  is (my_bounding_box ($image, 15,5, 15,5, '#000000'),
      '', 'ellipse');
  is ($image->xy (14,4), '#000000');
  is ($image->xy (14,5), '#000000');
  is ($image->xy (14,6), '#000000');
  is ($image->xy (15,4), '#000000');
  is ($image->xy (15,5), '#FFFFFF');
  is ($image->xy (15,6), '#000000');
  is ($image->xy (16,4), '#000000');
  is ($image->xy (16,5), '#000000');
  is ($image->xy (16,6), '#000000');
}
{
  my $image = Image::Base::PNGwriter->new (-width => 20,
                                           -height => 10);
  # unfilled 3x3
  $image->rectangle (0,0,19,9, '#000000');
  $image->ellipse (5,5, 7,7, '#FFFFFF');
  is ($image->xy (6,6), '#000000');

  # filled 3x3
  $image->rectangle (0,0,19,9, '#000000');
  $image->ellipse (5,5, 7,7, '#FFFFFF', 1);
  is ($image->xy (6,6), '#FFFFFF');
}

{
  my $x1 = 1;
  my $y1 = 11;
  foreach my $x2 ($x1+1 .. $x1+10) {
    foreach my $y2 ($y1+1 .. $y1+10) {

      my $image = Image::Base::PNGwriter->new (-width => 70,
                                               -height => 30);
      $image->rectangle (0,0,69,29, '#000000');
      $image->ellipse ($x1,$y1, $x2,$y2, '#FFFFFF');
      is (my_bounding_box ($image, $x1,$y1, $x2,$y2, '#000000'),
          '', "ellipse $x1,$y1 $x2,$y2");

      #     $image->save('/tmp/x.png');
      #     system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");

    }
  }
}


#------------------------------------------------------------------------------
# get -file

{
  my $image = Image::Base::PNGwriter->new (-width => 10,
                                           -height => 10);
  is (scalar ($image->get ('-file')), undef,
      '-file undef if never set, scalar context');
  is_deeply  ([$image->get ('-file')], [undef],
              '-file undef if never set, array context');
}

#------------------------------------------------------------------------------

# return true if given ellipse parameters uses Image::Base
sub ellipse_uses_imagebase {
  my ($x1,$y1, $x2,$y2) = @_;
  my $xr = $x2 - $x1;
  if (! ($xr & 1) && $xr == ($y2 - $y1)) {
    diag "pngwriter ellipse";
    return 0;
  } else {
    diag "base ellipse";
    return 1;
  }
}

{
  require MyTestImageBase;
  my $image = Image::Base::PNGwriter->new (-width  => 21,
                                           -height => 10);
  MyTestImageBase::check_image ($image,
                                pngwriter_exceptions => 1,
                                big_fetch_expect => '#000000',
                                base_ellipse_func => \&ellipse_uses_imagebase,
                               );
  MyTestImageBase::check_diamond ($image,
                                  pngwriter_exceptions => 1,
                                  skip_top_hline_fill=>1);
}

exit 0;
