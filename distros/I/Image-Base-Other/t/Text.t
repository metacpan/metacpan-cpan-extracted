#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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
plan tests => 2023;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Image::Base::Text;
MyTestHelpers::diag("Image::Base version ", Image::Base->VERSION);


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 9;
  ok ($Image::Base::Text::VERSION, $want_version, 'VERSION variable');
  ok (Image::Base::Text->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Image::Base::Text->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Image::Base::Text->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $image = Image::Base::Text->new;
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
  my $image = Image::Base::Text->new (-width => 6,
                                      -height => 7);
  ok (! defined $image->get('-file'),
      1);
  ok ($image->get('-height'),
      7);
  ok (defined $image && $image->isa('Image::Base') && 1,
      1);
  ok (defined $image && $image->isa('Image::Base::Text') && 1,
      1);
}

#------------------------------------------------------------------------------
# -width when -height 0

{
  my $image = Image::Base::Text->new (-width => 20,
                                                      -height => 10);
  ok ($image->get('-width'), 20);
  ok ($image->get('-height'), 10);

  $image->set (-height => 0);
  ok ($image->get('-width'), 20);
  ok ($image->get('-height'), 0);
}

#------------------------------------------------------------------------------
# -width expand/contract

{
  my $image = Image::Base::Text->new (-width => 10,
                                                      -height => 10);
  $image->set (-width => 20);
  ok ($image->xy(15,0), ' ', '-width increase fills with spaces');

  $image->set (-width => 20);
  $image->set (-width => 15);
  ok ($image->get('-width'), 15);
}

#------------------------------------------------------------------------------
# -height expand/contract

{
  my $image = Image::Base::Text->new (-width => 10,
                                                      -height => 10);
  $image->set (-height => 20);
  ok ($image->xy(5,15), ' ', '-height increase fills with spaces');

  $image->set (-height => 20);
  $image->set (-height => 15);
  ok ($image->get('-height'), 15);
}

#------------------------------------------------------------------------------
# load_lines()

{
  my $image = Image::Base::Text->new;
  $image->load_lines ("* *", " * ");
  ok ($image->get('-width'), 3);
  ok ($image->get('-height'), 2);
  $image->xy (0,0, '*');
  $image->xy (1,0, ' ');
  $image->xy (2,0, '*');
  $image->xy (0,1, ' ');
  $image->xy (1,1, '*');
  $image->xy (2,1, ' ');
}

#------------------------------------------------------------------------------
# load_string()

{
  my $image = Image::Base::Text->new;
  $image->load_string ("* *\n * \n");
  ok ($image->get('-width'), 3);
  ok ($image->get('-height'), 2);
  $image->xy (0,0, '*');
  $image->xy (1,0, ' ');
  $image->xy (2,0, '*');
  $image->xy (0,1, ' ');
  $image->xy (1,1, '*');
  $image->xy (2,1, ' ');
}

foreach my $elem (["", 0,0],
                  ["ab", 2,1],
                  ["ab\n", 2,1],
                  ["ab\n\n", 2,2],
                  ["ab\n\n\n", 2,3],
                  ["ab\ncde\n", 3,2],
                  ["ab\ncde", 3,2],

                  ["\nabcd\n", 4,2],
                  ["\n\nabcd\n", 4,3],
                  ["\nabcd\n\n", 4,3],
                  ["\n\n\n", 0,3],

                 ) {
  my ($str, $want_width, $want_height) = @$elem;
  my $image = Image::Base::Text->new;
  my $name = "load_string() $str";
  $image->load_string ($str);
  ok ($image->get('-width'),  $want_width,  $name);
  ok ($image->get('-height'), $want_height, $name);
}

#------------------------------------------------------------------------------
# save() / load()

{
  my $filename = 'tempfile.tmp';
  unlink $filename;
  END { unlink $filename; }
  MyTestHelpers::diag("test file '$filename'");

  # save file
  {
    my $image = Image::Base::Text->new (-width => 1,
                                        -height => 1);
    $image->xy (0,0, '*');
    $image->set(-file => $filename);
    ok ($image->get('-file'), $filename);
    $image->save;
    ok (-e $filename,
        1,
        "tempfile exists");
    ok (-s $filename > 0,
        1,
        "tempfile not empty");
    # system ("cat $filename");
  }

  # existing file with new(-file)
  {
    my $image = Image::Base::Text->new (-file => $filename);
    ok ($image->get('-file'),
        $filename);
    my $rows = $image->{'-rows_array'};
    ok (defined $rows && ref $rows eq 'ARRAY' && @$rows == 1
        && $rows->[0] eq "*",
        1);
    ok ($image->xy(0,0),
        '*');
  }

  # existing file with load()
  {
    my $image = Image::Base::Text->new (-width => 1,
                                        -height => 1);
    $image->load ($filename);
    ok ($image->get('-file'),
        $filename);
    ok ($image->xy(0,0),
        '*');
  }
}


#------------------------------------------------------------------------------
# save() / load() filename with space

{
  my $filename = ' tempspace.tmp';
  unlink $filename;
  END { unlink $filename; }
  MyTestHelpers::diag("test file '$filename'");

  # save file
  {
    my $image = Image::Base::Text->new (-width => 1, -height => 1);
    $image->save ($filename);
    ok (-e $filename,
        1,
        "file '$filename' exists");
    ok (-s $filename > 0,
        1,
        "file '$filename' not empty");
  }
  {
    my $image = Image::Base::Text->new (-width => 1,
                                        -height => 1,
                                        -file => $filename);
  }
}


#------------------------------------------------------------------------------
# colour_to_character

{
  my $image = Image::Base::Text->new (-width => 1, -height => 1);

  ok ($image->colour_to_character(' '),
      $image->colour_to_character(' '));
  ok ($image->colour_to_character('*'),
      $image->colour_to_character('*'));
}

#------------------------------------------------------------------------------
# line

{
  my $image = Image::Base::Text->new (-width => 20, -height => 10);
  $image->rectangle (0,0, 19,9, ' ', 1);
  $image->line (5,5, 7,7, '*', 0);
  ok ($image->xy (4,4), ' ');
  ok ($image->xy (5,5), '*');
  ok ($image->xy (5,6), ' ');
  ok ($image->xy (6,6), '*');
  ok ($image->xy (7,7), '*');
  ok ($image->xy (8,8), ' ');
}
{
  my $image = Image::Base::Text->new (-width => 20, -height => 10);
  $image->rectangle (0,0, 19,9, ' ', 1);
  $image->line (0,0, 2,2, '*', 1);
  ok ($image->xy (0,0), '*');
  ok ($image->xy (1,1), '*');
  ok ($image->xy (2,1), ' ');
  ok ($image->xy (3,3), ' ');
}

{
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->line (3,3, -1,-1, '*');
  ok ($image->save_string, <<'HERE');
*_________
_*________
__*_______
___*______
__________
HERE
}
{
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
   $image->line (-2,1, 2,1, '*');  # horizontal
  ok ($image->save_string, <<'HERE');
__________
***_______
__________
__________
__________
HERE
}
{
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->line (6,2, 10,2, '*', 1);
  ok ($image->save_string, <<'HERE');
__________
__________
______****
__________
__________
HERE
}
{
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->line (3,-1, 6,-1, '*', 1);  # horizontal, Y negative
  ok ($image->save_string, <<'HERE');
__________
__________
__________
__________
__________
HERE
}
{
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  # various outside 
  $image->line (1000,2, 999,2, '*', 1);
  $image->line (-1000,2, -999,2, '*', 1);
  $image->line (1,-2, 1,-2, '*', 1);
  $image->line (1,200, 1,200, '*', 1);
  $image->line (3,5, 6,5, '*', 1);
  ok ($image->save_string, <<'HERE');
__________
__________
__________
__________
__________
HERE
}


#------------------------------------------------------------------------------
# xy

{
  my $image = Image::Base::Text->new (-width => 20,
                                                      -height => 10);
  $image->xy (2,2, ' ');
  $image->xy (3,3, '*');
  ok ($image->xy (2,2), ' ', 'xy()  ');
  ok ($image->xy (3,3), '*', 'xy() *');
}

#------------------------------------------------------------------------------
# rectangle

{
  my $image = Image::Base::Text->new (-width => 20,
                                                      -height => 10);
  $image->rectangle (0,0, 19,9, ' ', 1);
  $image->rectangle (5,5, 7,7, '*', 0);
  ok ($image->xy (5,5), '*');
  ok ($image->xy (5,6), '*');
  ok ($image->xy (5,7), '*');

  ok ($image->xy (6,5), '*');
  ok ($image->xy (6,6), ' ');
  ok ($image->xy (6,7), '*');

  ok ($image->xy (7,5), '*');
  ok ($image->xy (7,6), '*');
  ok ($image->xy (7,7), '*');

  ok ($image->xy (7,8), ' ');
  ok ($image->xy (8,7), ' ');
  ok ($image->xy (8,8), ' ');
}
{
  my $image = Image::Base::Text->new (-width => 20,
                                      -height => 10);
  $image->rectangle (0,0, 19,9, ' ', 1);
  $image->rectangle (0,0, 2,2, '*', 1);
  ok ($image->xy (0,0), '*');
  ok ($image->xy (1,1), '*');
  ok ($image->xy (2,1), '*');
  ok ($image->xy (3,3), ' ');
}

foreach my $fill (0, 1) {
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->rectangle (3,-1, 4,2, '*', $fill);
  ok ($image->save_string, <<'HERE');
___**_____
___**_____
___**_____
__________
__________
HERE
}

foreach my $fill (0, 1) {
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->rectangle (-1,2, 3,2, '*', $fill);
  ok ($image->save_string, <<'HERE');
__________
__________
****______
__________
__________
HERE
}

foreach my $fill (0, 1) {
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->rectangle (7,2, 1000,2, '*', $fill);
  ok ($image->save_string, <<'HERE');
__________
__________
_______***
__________
__________
HERE
}

{
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->rectangle (-1,-1, 4,2, '*'); # unfilled
  ok ($image->save_string, <<'HERE');
____*_____
____*_____
*****_____
__________
__________
HERE
}
{
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->rectangle (-1,0, 4,2, '*'); # unfilled
  ok ($image->save_string, <<'HERE');
*****_____
____*_____
*****_____
__________
__________
HERE
}
foreach my $fill (0, 1) {
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->rectangle (0,-1, 1,3, '*', $fill);
  ok ($image->save_string, <<'HERE');
**________
**________
**________
**________
__________
HERE
}
{
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->rectangle (7,1, 10,5, '*', 1); # filled
  ok ($image->save_string, <<'HERE');
__________
_______***
_______***
_______***
_______***
HERE
}
{
  my $image = Image::Base::Text->new (-width => 10, -height => 5);
  $image->rectangle (0,0,9,4, '_', 1);
  $image->rectangle (7,1, 10,5, '*'); # unfilled
  ok ($image->save_string, <<'HERE');
__________
_______***
_______*__
_______*__
_______*__
HERE
}

#------------------------------------------------------------------------------
# get('-file')

{
  my $image = Image::Base::Text->new (-width => 10,
                                                      -height => 10);
  ok (! defined (scalar ($image->get ('-file'))),
      1);
  my @array = $image->get ('-file');
  ok (scalar(@array), 1);
  ok (! defined $array[0], 1);
}

#------------------------------------------------------------------------------

{
  require MyTestImageBase;
  my $image = Image::Base::Text->new
    (-width => 21,
     -height => 10,
     -character_to_colour => { ' ' => 'black',
                               '*' => 'white' });
  MyTestImageBase::check_image ($image);
}

exit 0;
