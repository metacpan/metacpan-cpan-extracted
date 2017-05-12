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
use Test::More tests => 2601;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

require Image::Base::GD;
diag "Image::Base version ", Image::Base->VERSION;


sub my_bounding_box {
  my ($image, $x1,$y1, $x2,$y2, $black, $white) = @_;
  my ($width, $height) = $image->get('-width','-height');

  my @bad;
  foreach my $y ($y1-1, $y2+1) {
    next if $y < 0 || $y >= $height;
    foreach my $x ($x1-1 .. $x2-1) {
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

sub my_bounding_box_and_sides {
  my ($image, $x1,$y1, $x2,$y2, $black, $white) = @_;

  my @bad = my_bounding_box(@_);
  if ($bad[0] eq '') {
    pop @bad;
  }

  foreach my $x ($x1, ($x1 == $x2 ? () : ($x2))) {
    my $found = 0;
    foreach my $y ($y1 .. $y2) {
      my $got = $image->xy($x,$y);
      if ($got ne $black) {
        $found = 1;
        last;
      }
    }
    if (! $found) {
    push @bad, "nothing in column x=$x";
    }
  }

  foreach my $y ($y1, ($y1 == $y2 ? () : ($y2))) {
    my $found = 0;
    foreach my $x ($x1 .. $x2) {
      my $got = $image->xy($x,$y);
      if ($got ne $black) {
        $found = 1;
        last;
      }
    }
    if (! $found) {
    push @bad, "nothing in row y=$y";
    }
  }

  return join("\n", @bad);
}


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 15;
  is ($Image::Base::GD::VERSION, $want_version, 'VERSION variable');
  is (Image::Base::GD->VERSION,  $want_version, 'VERSION class method');

  is (eval { Image::Base::GD->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  is (! eval { Image::Base::GD->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $image = Image::Base::GD->new (-gd => 'dummy');
  is ($image->VERSION,  $want_version, 'VERSION object method');

  is (eval { $image->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  is (! eval { $image->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# _colour_to_rgb255()

{
  foreach my $elem (['#000', [0,0,0]],
                    ['#ABC', [0xAA, 0xBB, 0xCC]],
                    ['#abc', [0xAA, 0xBB, 0xCC]],

                    ['#AABBCC', [0xAA, 0xBB, 0xCC]],
                    ['#aabbcc', [0xAA, 0xBB, 0xCC]],

                    ['#AA1BB2CC3', [0xAA, 0xBB, 0xCC]],
                    ['#aa9bb9cc9', [0xAA, 0xBB, 0xCC]],

                    ['#0123456789AB', [0x01, 0x45, 0x89]],
                    ['#AB03CD02EF01', [0xAB, 0xCD, 0xEF]],
                    ['#abcdabcdabcd', [0xAB, 0xAB, 0xAB]],
                   ) {
    my ($colour, $want_rgb) = @$elem;
    my @got_rgb = Image::Base::GD::_colour_to_rgb255($colour);
    is_deeply (\@got_rgb, $want_rgb, "_colour_to_rgb255() $colour");
  }
}

#------------------------------------------------------------------------------
# new()

{
  my $image = Image::Base::GD->new (-width => 6,
                                    -height => 7);
  is ($image->get('-file'), undef);
  is ($image->get('-file_format'), 'png');
  is ($image->get('-zlib_compression'), -1);
  is ($image->get('-width'), 6);
  is ($image->get('-height'), 7);
  is (defined $image && $image->isa('Image::Base') && 1,
      1,
      'isa Image::Base');
  is (defined $image && $image->isa('Image::Base::GD') && 1,
      1,
      'isa Image::Base::GD');
}

{
  my $image = Image::Base::GD->new (-width => 6,
                                    -height => 7);
  my $i2 = $image->new;
  is (defined $i2 && $i2->isa('Image::Base') && 1,
      1,
      'isa Image::Base');
  is (defined $i2 && $i2->isa('Image::Base::GD') && 1,
      1,
      'isa Image::Base::GD');
  is ($i2->get('-width'),  6, 'copy object -width');
  is ($i2->get('-height'), 7, 'copy object -height');
  is ($i2->get('-gd') != $image->get('-gd'),
      1,
      'copy object different -gd');
}

{
  my $image = Image::Base::GD->new (-width => 6,
                                    -height => 7,
                                    -zlib_compression => 1);
  is ($image->get('-zlib_compression'),  1, 'orig -zlib_compression, before');
  my $i2 = $image->new (-zlib_compression => 2);
  is ($image->get('-zlib_compression'),  1, 'orig -zlib_compression');
  is ($i2->get('-zlib_compression'),  2, 'clone -zlib_compression');
}

#------------------------------------------------------------------------------
# new() / load() of empty.dat

{
  require FindBin;
  require File::Spec;
  my $filename = File::Spec->catfile($FindBin::Bin, 'empty.dat');
  my $image = Image::Base::GD->new (-width => 1, -height => 1);
  isnt ($image->get('-gd'), undef);

  my $ret = eval { $image->load($filename); 1 };
  my $err = $@;
  # diag "load of $filename: ", $err;

  is ($ret, undef, "load() $filename");
  ok ($err);
  isnt ($image->get('-gd'), undef);
}
{
  require FindBin;
  require File::Spec;
  my $filename = File::Spec->catfile($FindBin::Bin, 'empty.dat');
  my $image = eval { Image::Base::GD->new (-file => $filename) };
  my $err = $@;
  is ($image, undef, "new() $filename");
  ok ($err);
}


#------------------------------------------------------------------------------
# colour_to_index

{
  my $image = Image::Base::GD->new (-width => 1, -height => 1);

  is ($image->colour_to_index('#000000'),
      $image->colour_to_index('#000000'));
  is ($image->colour_to_index('None'),
      $image->colour_to_index('None'));
}

#------------------------------------------------------------------------------
# line

{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0, 19,9, '#000000', 1);
  $image->line (5,5, 8,8, '#FFFFFF', 0);
  is (my_bounding_box ($image, 5,5, 8,8, '#000000'),
      '', 'line');

  is ($image->xy (4,4), '#000000');
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (5,6), '#000000');
  is ($image->xy (6,6), '#FFFFFF');
  is ($image->xy (7,7), '#FFFFFF');
  is ($image->xy (8,8), '#FFFFFF');
  is ($image->xy (9,9), '#000000');
}
{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0, 19,9, '#000000', 1);
  $image->line (0,0, 2,2, '#FFFFFF', 1);
  is (my_bounding_box ($image, 0,0, 2,2, '#000000'),
      '', 'line');

  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#000000');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# xy

foreach my $truecolor (1,0) {
  GD::Image->trueColor($truecolor);
  my $image = Image::Base::GD->new (-width  => 100,
                                    -height => 100);
  $image->get('-gd')->alphaBlending(0);
  diag "isTrueColor: ",$image->get('-gd')->isTrueColor;

  $image->rectangle (0,0, 99,99, '#000000', 1);
  $image->xy (50,60, '#112233');
  $image->xy (51,61, '#441155226633');
  $image->xy (52,62, 'black');
  $image->xy (53,63, 'white');
  $image->xy (54,64, 'None');
  is (my_bounding_box ($image, 50,60, 54,64, '#000000'),
      '', 'points');

  is ($image->xy (50,60), '#112233', 'xy() 50,50');
  is ($image->xy (51,61), '#445566', 'xy() 51,51');
  is ($image->xy (52,62), '#000000', 'xy() 52,62');
  is ($image->xy (53,63), '#FFFFFF', 'xy() 53,63');
  is ($image->xy (54,64), 'None',    'xy() 54,64');
}

#------------------------------------------------------------------------------
# rectangle

{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0, 19,9, '#000000', 1);
  $image->rectangle (5,5, 7,7, '#FFFFFF', 0);
  is (my_bounding_box_and_sides ($image, 5,5, 7,7, '#000000'),
      '', 'rectangle');
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (6,6), '#000000');
  is ($image->xy (7,6), '#FFFFFF');
  is ($image->xy (8,8), '#000000');
}
{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0, 19,9, '#000000', 1);
  $image->rectangle (0,0, 2,2, '#FFFFFF', 1);
  is (my_bounding_box_and_sides ($image, 0,0, 2,2, '#000000'),
      '', 'rectangle');
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#FFFFFF');
  is ($image->xy (3,3), '#000000');
}

my $black = '#000000';
my $white = '#FFFFFF';

sub image_to_bw {
  my ($image) = @_;
  my $str = '';
  foreach my $y (0 .. $image->get('-height')-1) {
    foreach my $x (0 .. $image->get('-width')-1) {
      my $colour = $image->xy($x,$y);
      my $char = ($colour eq $black ? '_'
                  : $colour eq $white ? '*'
                  : '?');
      $str .= $char;
    }
    $str .= "\n";
  }
  return $str;
}

foreach my $fill (0, 1) {
  my $image = Image::Base::GD->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, $black, 1);
  $image->rectangle (3,-1, 4,2, $white, $fill);
  is (image_to_bw($image), <<'HERE');
___**_____
___**_____
___**_____
__________
__________
HERE
}

{
  my $image = Image::Base::GD->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, $black, 1);
  $image->rectangle (3,-91, 6,2, $white, 1);
  is (image_to_bw($image), <<'HERE');
___****___
___****___
___****___
__________
__________
HERE
}

{
  my $image = Image::Base::GD->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, $black, 1);
  $image->rectangle (2,-5, 8,-5, '#FFFFFF', 1, 'rectangle() Y all negative');
  is (image_to_bw($image), <<'HERE');
__________
__________
__________
__________
__________
HERE
}
{
  my $image = Image::Base::GD->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, $black, 1);
  $image->rectangle (2,100, 8,200, '#FFFFFF', 1);
  is (image_to_bw($image), <<'HERE', 'rectangle() Y all too big');
__________
__________
__________
__________
__________
HERE
}
{
  my $image = Image::Base::GD->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, $black, 1);
  $image->rectangle (-8,1, -5,4, '#FFFFFF', 1, 'rectangle() X all negative');
  is (image_to_bw($image), <<'HERE');
__________
__________
__________
__________
__________
HERE
}
{
  my $image = Image::Base::GD->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, $black, 1);
  $image->rectangle (100,2, 200,4, '#FFFFFF', 1);
  is (image_to_bw($image), <<'HERE', 'rectangle() X all too big');
__________
__________
__________
__________
__________
HERE
}


#------------------------------------------------------------------------------
# ellipse

{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0,19,9, '#000000');
  $image->ellipse (1,1, 3,3, '#FFFFFF');
  is (my_bounding_box_and_sides ($image, 1,1, 3,3, '#000000'),
      '', 'ellipse');
  is ($image->xy (0,0), '#000000');
  is ($image->xy (0,1), '#000000');
  is ($image->xy (0,2), '#000000');
  is ($image->xy (0,3), '#000000');
  is ($image->xy (0,4), '#000000');

  is ($image->xy (4,0), '#000000');
  is ($image->xy (4,1), '#000000');
  is ($image->xy (4,2), '#000000');
  is ($image->xy (4,3), '#000000');
  is ($image->xy (4,4), '#000000');

  is ($image->xy (1,2), '#FFFFFF');

  is ($image->xy (1,0), '#000000');
  is ($image->xy (2,0), '#000000');
  is ($image->xy (3,0), '#000000');

  is ($image->xy (1,4), '#000000');
  is ($image->xy (2,4), '#000000');
  is ($image->xy (3,4), '#000000');
}
{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0,19,9, '#000000');
  $image->ellipse (5,5, 5,5, '#FFFFFF');
  is (my_bounding_box_and_sides ($image, 5,5, 5,5, '#000000'),
      '', 'ellipse');
  is ($image->xy (4,4), '#000000');
  is ($image->xy (4,5), '#000000');
  is ($image->xy (4,6), '#000000');
  is ($image->xy (5,4), '#000000');
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (5,6), '#000000');
  is ($image->xy (6,4), '#000000');
  is ($image->xy (6,5), '#000000');
  is ($image->xy (6,6), '#000000');
}
{
  my $image = Image::Base::GD->new (-width => 20,
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
    next if (($x2-$x1)&1);  # only GD dispatched ones
    foreach my $y2 ($y1+1 .. $y1+10) {
      next if (($y2-$y1)&1);  # only GD dispatched ones

      my $image = Image::Base::GD->new (-width  => 70,
                                        -height => 30);
      $image->rectangle (0,0,69,29, '#000000');
      $image->ellipse ($x1,$y1, $x2,$y2, '#FFFFFF');
      is (my_bounding_box_and_sides ($image, $x1,$y1, $x2,$y2, '#000000'),
          '', "ellipse $x1,$y1 $x2,$y2");
    }
  }
}

# $image->save('/tmp/x.png');
# system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");


#------------------------------------------------------------------------------
# transparent

{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0, 19,9, 'None', 1);
}

#------------------------------------------------------------------------------
# get('-file')

{
  my $image = Image::Base::GD->new (-width => 10,
                                    -height => 10);
  is (scalar ($image->get ('-file')), undef);
  is_deeply  ([$image->get ('-file')], [undef]);
}

#------------------------------------------------------------------------------
# add_colours

foreach my $truecolor (1,0) {

  GD::Image->trueColor(0);
  my $image = Image::Base::GD->new (-width  => 100,
                                    -height => 100,
                                    -truecolor => $truecolor);
  diag "isTrueColor: ",$image->get('-gd')->isTrueColor;
  $image->get('-gd')->alphaBlending(0);
  $image->add_colours ('#FF00FF', 'None', '#FFAAAA');

  $image->xy (72,72, '#FF00FF');
  is ($image->xy (72,72), '#FF00FF',
      'add_colours() fetch #FF00FF');

  $image->xy (51,51, '#FFAAAA');
  is ($image->xy (51,51), '#FFAAAA',
      'add_colours() fetch #FFAAAA');

  $image->xy (60,60, 'None');
  is ($image->xy (60,60), 'None',
      'add_colours() fetch transparent');
}


#------------------------------------------------------------------------------

{
  require MyTestImageBase;
  my $image = Image::Base::GD->new (-width => 21,
                                    -height => 10);
  MyTestImageBase::check_diamond ($image);
  MyTestImageBase::check_image ($image,
                               big_fetch_expect => '#000000');
}

exit 0;
