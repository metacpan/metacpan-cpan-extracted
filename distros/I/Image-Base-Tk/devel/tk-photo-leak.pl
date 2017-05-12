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

use 5.004;
use strict;
use Tk;
use Scalar::Util;

# uncomment this to run the ### lines
use Devel::Comments;

{
  my $mw = MainWindow->new;
  my $photo;
  $mw->repeat (500,
               sub {
                 if ($photo) {
                   print "Not weakened away\n";
                   exit 0;
                 }
                 $photo = $mw->Photo ("myname",
                                      -width => 1000, -height => 1000);
                 $photo->delete;
                 Scalar::Util::weaken($photo);
               });
  MainLoop;
  exit 0;
}

