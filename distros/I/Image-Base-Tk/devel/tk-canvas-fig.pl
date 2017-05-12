#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-Tk.
#
# Image-Base-Tk is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Tk is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Tk.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Tk;
use Tk::Mwm;
use Image::Base::Tk::Canvas;
use lib 't';

# uncomment this to run the ### lines
use Devel::Comments;

{
  my $mw = MainWindow->new;
  my $canvas = $mw->Canvas (-borderwidth => 0,
                            -highlightthickness => 0,
                            -width => 30,
                            -height => 15,
                            -background => 'black');
  $canvas->pack (-expand => 1, -fill => 'both');
  ### canvas id: $canvas->id

  my $image = Image::Base::Tk::Canvas->new
    (-tkcanvas => $canvas);

   $image->rectangle (2,2, 4,4, 'orange', 0);
 # $image->rectangle (0,0, 0,6, 'black', 1);
  #
  # $image->rectangle (6,1, 8,10, 'black', 0);
  # $image->xy (0,0, 'black');
  #  $image->xy (1,2, 'black');
  #  $image->xy (2,1, 'black');

  # $image->ellipse (1,1, 16,6, 'green', 1);
  # $image->diamond (1,1, 15,5, 'green', 0);

  # $image->line (12,1, 15,4, 'black');

  # my $c = $image->xy(12,1);
  # ### $c;

  # { my $str = $image->save_string;
  #   ### $str
  # }

  # $image->rectangle (0,0, 19,9, 'white', 1);
  # $image->line (10,10, 0,10, 'green', 1);
  # $image->diamond (0,0, 16,4, 'blue', 1);

  #  my @ret = $image->save('/tmp/x/x.eps');
  # ### @ret

  #$image->ellipse (5,7, 5,7, 'white', 1);
  # $image->ellipse (2,2,8,8, 'white', 0);

  my $label = $canvas->Label(-text=>'E');

  require Tk::CanvasFig;
  {
    my $str = $canvas->fig;
    ### $str
  }
  {
    my $ret = $canvas->fig (-file => '/tmp/x.fig');
    ### $ret
  }
  {
    my $ret = $canvas->fig (-file => '/no/such/dir/foo.fig');
    ### $ret
  }
  exit 0;
}
