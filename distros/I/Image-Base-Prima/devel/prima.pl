#!/usr/bin/perl -w

# Copyright 2010, 2011, 2015 Kevin Ryde

# This file is part of Image-Base-Prima.
#
# Image-Base-Prima is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Prima is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Prima.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
# use blib "$ENV{HOME}/perl/prima/Prima-1.29/blib";
# use lib "$ENV{HOME}/perl/prima/Prima-1.29/inst/local/lib/perl/5.10.1/";
use Prima::noX11;
use Prima;

use Smart::Comments;


{
  # Prima::noX11
  require Package::Stash;
  my $stash = Package::Stash->new('Prima::noX11');
  print "$stash\n";
  print $stash->list_all_symbols(),"\n";
  my $version = Prima::noX11->VERSION;
  ### $version
  exit 0;
}

{
  require Image::Base::Prima::Image;
  my $image = Image::Base::Prima::Image->new (-width => 50, -height => 20,
                                              -file_format => 'xpm');
  $image->rectangle (0,0, 49,29, 'black');
  my $d = $image->get('-drawable');
  $d->begin_paint;

  $image->diamond (1,1,6,6, 'white');
  $image->diamond (11,1,16,6, 'white', 1);
  $image->diamond (1,10,7,16, 'white');
  $image->diamond (11,10,17,16, 'white', 1);
  $d->end_paint;

  $image->save('/dev/stdout');
  exit 0;
}

{
  printf "white %X\n", cl::White();
  my $coderef = cl->can('White');
  printf "white coderef %s  %X\n", $coderef, &$coderef();

  require Image::Base::Prima::Drawable;
  my $d = Prima::Image->create (width => 100,
                                height => 100,
                                type => im::bpp8(),
                                # type => im::RGB(),
                               );
  # $d-> palette([0,255,0],[255,255,255], [0xFF,0x00,0xFF], [0x00,0xFF,0x00]);
  # $d-> palette([0,255,0, 255,255,255, 0xFF,0x00,0xFF, 0x00,0xFF,0x00]);
  # $d-> palette(0x000000, 0xFF00FF, 0xFFFFFF, 0x00FF00);
  ### palette: $d-> palette

  ### bpp: $d->get_bpp

  my $image = Image::Base::Prima::Drawable->new
    (-drawable => $d);
  print "width ", $image->get('-width'), "\n";
  $image->set('-width',60);
  $image->set('-height',40);
  print "width ", $image->get('-width'), "\n";

  $d->begin_paint;
  $d->color (cl::Black());
  $d->bar (0,0, 60,40);
  # $image->ellipse(1,1, 18,8, 'white');
  # $image->ellipse(1,1, 5,3, 'white', 1);
  # $image->xy(6,4, 'white');

  $image->diamond(1,1, 51,31, 'white', 0);
  $image->rectangle(0,0,10,10, 'green');

  # $image->xy(0,0, '#00FF00');
  # $image->xy(1,1, '#FFFF0000FFFF');
  # print "xy ", $image->xy(0,0), "\n";
  # say $d->pixel(0,0);

  $d->end_paint;
  $d-> save('/tmp/foo.gif') or die "Error saving:$@\n";
  system "xzgv -z /tmp/foo.gif";
  exit 0;
}

{
  # jpeg compression on save()
  #
  require Image::Base::Prima::Image;
  my $image = Image::Base::Prima::Image->new
    (-width => 200,
     -height => 100,
     -file => '/usr/share/doc/texlive-doc/dvipdfm/mwicks.jpeg');

  # my $image = Image::Base::Prima::Image->new
  #   (-width => 200,
  #    -height => 100,
  #    -file_format => 'jpeg');

  $image->ellipse (1,1, 100,50, 'green');
  $image->ellipse (100,50, 199,99, '#123456');
  $image->line (1,99, 199,0, 'red');
  $image->line (1,0, 199,99, '#654321');

  $image->set (-quality_percent => 1);
  $image->save ('/tmp/x-001.jpeg');
  $image->set (-quality_percent => 100);
  $image->save ('/tmp/x-100.jpeg');
  system "ls -l /tmp/x*";
  exit 0;
}

{
  my $d = Prima::Image->create (width => 1,
                                height => 1,
                               );
  $d->save ('/tmp/nosuchdir/z.png');
  exit 0;
}

{
  my $d = Prima::Image->create (width => 1,
                                height => 1,
                                type => im::bpp32(),
                               );
  my $green = cl::Green;
  ### green: $green;
  $d->begin_paint;
  $d->color (cl::Black());
  $d->pixel(0,0, cl::Green);
  ### pixel: $d->pixel(0,0)
  $d->end_paint;
  exit 0;
}





{
  my $image = Image::Base::Prima::Image->new (-width => 20, -height => 10);
  $image->rectangle (1,1, 8,8, 'white');
  exit 0;
}





{
  use Prima;
  use Prima::Const;

  my $d = Prima::Image->create (width => 5, height => 3);
  $d->begin_paint;
  $d->lineWidth(1);

  $d->color (cl::Black);
  $d->bar (0,0, 50,50);

  $d->color (cl::White);
  $d->fill_ellipse (2,1, 5,3);

  $d->end_paint;
  $d-> save('/tmp/foo.gif') or die "Error saving:$@\n";
  system "xzgv -z /tmp/foo.gif";
  exit 0;
}





{
  # available cL:: colour names
  require Prima;
  my @array;
  foreach my $name (keys %cl::) {
    if ($name eq 'AUTOLOAD' || $name eq 'constant') {
      print "$name\n";
      next;
    }
    my $var = "cl::$name";
    my $value = do { no strict 'refs'; &$var(); };
    push @array, [$name, $value];
  }
  foreach my $elem (sort {$a->[1] <=> $b->[1]} @array) {
    printf "%8s %s\n", sprintf('%06X',$elem->[1]), $elem->[0];
  }
  exit 0;
}
