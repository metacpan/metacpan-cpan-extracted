#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-Gtk2.
#
# Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Gtk2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use List::Util 'min';

my $width = 200;
my $height = 50;

my $rootwin = Gtk2::Gdk->get_default_root_window;
my $pixmap = Gtk2::Gdk::Pixmap->new ($rootwin, $width, $height, -1);
my $black = Gtk2::Gdk::Color->new(0,0,0,0);
my $gc = Gtk2::Gdk::GC->new ($pixmap,
                             { line_width => 1,
                               foreground => $black,
                             });
$pixmap->draw_rectangle ($gc,
                         1, # fill
                         0, 0,
                         $width,$height);

my $line_width = min ($height/2, $width/2);
$line_width = int($line_width + .5);  # up to integer
$line_width += !($line_width&1); # up to next odd integer
print "line_width=$line_width\n";

my $white = Gtk2::Gdk::Color->new(0xFFFF,0xFFFF,0xFFFF,0xFFFFFF);
$gc = Gtk2::Gdk::GC->new ($pixmap,
                          { line_width => $line_width,
                            function => 'xor',
                            foreground => $white,
                          });

my $shrink = int($line_width/2); # round down
print "shrink=$shrink\n";

my $x = 0 + $shrink;
my $y = 0 + $shrink;
my $w = $width-1 - 2*$shrink;
my $h = $height-1 - 2*$shrink;
print "x=$x, y=$y, w=$w, h=$h\n";
$pixmap->draw_arc ($gc,
                   0, # unfilled
                   $x,$y, $w,$h,
                   0, 360*64);

my $red = Gtk2::Gdk::Color->new(0xFFFF,0,0,0xFF0000);
$gc = Gtk2::Gdk::GC->new ($pixmap,
                          { line_width => 1,
                            foreground => $red,
                          });
$pixmap->draw_arc ($gc,
                   0, # unfilled
                   0,0, $width-1,$height-1,
                   0, 360*64);

my $blue = Gtk2::Gdk::Color->new(0,0xFFFF,0,0x00FF00);
$gc = Gtk2::Gdk::GC->new ($pixmap,
                          { line_width => 1,
                            foreground => $blue,
                          });
$pixmap->draw_arc ($gc,
                   0, # unfilled
                   $x,$y,$w,$h,
                   0, 360*64);

print "\n";
my $pixbuf = Gtk2::Gdk::Pixbuf->get_from_drawable
  ($pixmap, undef, 0,0, 0,0, $width,$height);
$pixbuf->save ('/tmp/x.png', 'png');
# system ("convert -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");
system ("xzgv -z /tmp/x.png");
exit 0;



# $pixmap->draw_line ($gc,
#                     2, 2,
#                     15, 5);

