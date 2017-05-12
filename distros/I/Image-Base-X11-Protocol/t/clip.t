#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

# This file is part of Image-Base-X11-Protocol.
#
# Image-Base-X11-Protocol is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-X11-Protocol is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-X11-Protocol.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 29)[1];
plan tests => $test_count;

require Image::Base::X11::Protocol::Drawable;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# _line_end_clip()

foreach my $elem ([  0,0,  10,10,   10,10 ],
                  [-10,-10,10,10,   10,10 ],

                  [  0,0, 4*0x7FFF,2*0x7FFF,    0x7FFF,0x4000 ],
                  [  0,0, 2*0x7FFF,4*0x7FFF,    0x4000,0x7FFF ],
                  [  0,0, -4*0x8000,-2*0x8000,    -0x8000,-0x4000 ],
                  [  0,0, -2*0x8000,-4*0x8000,    -0x4000,-0x8000 ],

                  [  -0x10000,0, -0x10000,10,  ],
                  [  0x10000,0, 0x10000,10,    ],
                  [  0,-0x10000, 10,-0x10000,  ],
                  [  0,0x10000, 10,0x10000,    ],

                  [  0,0, 0x10000,0x10000,    0x7FFF,0x7FFF ],
                 ) {
  my ($x1,$y1, $x2,$y2, @want) = @$elem;
  {
    my @got = Image::Base::X11::Protocol::Drawable::_line_end_clip
      ($x1,$y1, $x2,$y2);
    ok (join(',',@got), join(',',@want),
        "clip $x1,$y1 $x2,$y2");
  }
}

#------------------------------------------------------------------------------
# _line_any_positive()

foreach my $elem ([ 1,  0,0, 0,0,    ],
                  [ 0,  -1,0, -2,0,  ],
                  [ 0,  0,-1, 0,-2,  ],
                  [ 1,  -1,1, 1,-1  ],


                  # x1=-10,y1=-10 
                  #      \
                  #       \-------
                  #       |\
                  #       |  x2=10,y2=10
                  [ 1,  -1,-1, 1,1  ],
                  [ 1,  -10,-10, 0,0  ],
                  [ 1,  -10,-10, 10,10  ],
                  [ 1,  -1,-1, 10,10  ],

                  #               x2=5,y2=-10
                  #              /
                  #             / +-------
                  # x1=-10,y1=5   |
                  [ 0,  -10,5, 5,-10 ],

                 ) {
  my ($want, $x1,$y1, $x2,$y2) = @$elem;
  {
    my $got = Image::Base::X11::Protocol::Drawable::_line_any_positive
      ($x1,$y1, $x2,$y2);
    $got = ($got ? 1 : 0);
    ok ($got, $want,
        "_line_any_positive() $x1,$y1 $x2,$y2");
  }

  # swap ends
  ($x1,$y1, $x2,$y2) = ($x2,$y2, $x1,$y1);

  {
    my $got = Image::Base::X11::Protocol::Drawable::_line_any_positive
      ($x1,$y1, $x2,$y2);
    $got = ($got ? 1 : 0);
    ok ($got, $want,
        "_line_any_positive() swapped to $x1,$y1 $x2,$y2");
  }
}
exit 0;

#------------------------------------------------------------------------------
# _line_clip_16bit()

foreach my $elem ([ 0x7FFF,0, 0x8000,0,       0x7FFF,0,0x7FFF,0 ],
                  [ 0,0x7FFF, 0,0x8000,       0,0x7FFF,0,0x7FFF ],
                  [ 0,0, 0x10000,0x10000,     0,0, 0x7FFF,0x7FFF ],
                  [ 0,0, -0x10000,-0x10000,   0,0, -0x8000,-0x8000 ],

                  [ 0x10000,0x10000, -0x10000,-0x10000,
                    0x7FFF,0x7FFF, -0x8000,-0x8000 ],

                  [ -0x8001,0x8000, 0x8000,-0x8001,
                    -0x8000,0x7FFF, 0x7FFF,-0x8000 ],

                  [ -10,10, -20,10, () ],
                  [ 10,-10, 20,-10, () ],

                  [ -10,5, 5,-10, () ],

                 ) {
  my ($x1,$y1, $x2,$y2, @want) = @$elem;
  {
    my @got = Image::Base::X11::Protocol::Drawable::_line_clip
      ($x1,$y1, $x2,$y2);
    ok (join(',',@got), join(',',@want),
        "clip $x1,$y1 $x2,$y2");
  }

  # swap ends
  ($x1,$y1, $x2,$y2) = ($x2,$y2, $x1,$y1);
  if (@want) {
    ($want[0],$want[1], $want[2],$want[3])
      = ($want[2],$want[3], $want[0],$want[1]);
  }

  {
    my @got = Image::Base::X11::Protocol::Drawable::_line_clip
      ($x1,$y1, $x2,$y2);
    ok (join(',',@got), join(',',@want),
        "clip swapped to $x1,$y1 $x2,$y2");
  }
}

#------------------------------------------------------------------------------
exit 0;
