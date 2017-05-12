#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base.
#
# Image-Base is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Image-Base.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Image::Xpm;
use POSIX 'floor', 'ceil';

my $w = 10;
my $h = 10;
my $image = Image::Xpm->new (-width => $w, -height => $h);
$image->rectangle (0,0, $w-1,$h-1, 'black', 1);

$image->ellipse (0,0, $w-1,$h-1, 'white');

foreach my $x (0 .. ceil($w/2)) {
  my $x2 = $w-1 - $x;
  foreach my $y (0 .. ceil($h/2)) {
    my $y2 = $h-1 - $y;
    my $c = $image->xy($x,$y);

    my $c12 = $image->xy($x,$y2);
    my $c21 = $image->xy($x2,$y);
    my $c22 = $image->xy($x2,$y2);

    if ($c ne $c12
        || $c ne $c12
        || $c ne $c21
        || $c ne $c22) {
      print "not symmetric\n";
      print "  $x,$y  $c\n";
      print "  $x,$y2  $c12\n";
      print "  $x2,$y  $c21\n";
      print "  $x2,$y2  $c22\n";
    }
  }
}

# $image->save('/dev/stdout');

#   # print $image->{'str'};
#   $image->save('/tmp/ellipse.xpm');
#   system ('xzgv /tmp/ellipse.xpm');

exit 0;
