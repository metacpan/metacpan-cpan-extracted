#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Tk.
#
# Image-Base-Tk is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Tk is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Tk.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Test::More;
use Tk;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Image::Base::Tk::Photo;
diag "Tk version ", Tk->VERSION;
diag "Image::Base version ", Image::Base->VERSION;

my $mw;
eval { $mw = MainWindow->new }
  or plan skip_all => "due to no display -- $@";

plan tests => 1937;


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
  my $want_version = 3;
  is ($Image::Base::Tk::Photo::VERSION, $want_version, 'VERSION variable');
  is (Image::Base::Tk::Photo->VERSION,  $want_version, 'VERSION class method');

  is (eval { Image::Base::Tk::Photo->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  is (! eval { Image::Base::Tk::Photo->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $image = Image::Base::Tk::Photo->new (-tkphoto => 'dummy');
  is ($image->VERSION,  $want_version, 'VERSION object method');

  is (eval { $image->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  is (! eval { $image->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# new()

{
  my $image = Image::Base::Tk::Photo->new (-for_widget => $mw,
                                           -width => 6,
                                           -height => 7);
  is ($image->get('-file'), undef);
  is ($image->get('-file_format'), undef);
  is ($image->get('-width'), 6);
  is ($image->get('-height'), 7);
  is (defined $image && $image->isa('Image::Base') && 1,
      1,
      'isa Image::Base');
  is (defined $image && $image->isa('Image::Base::Tk::Photo') && 1,
      1,
      'isa Image::Base::Tk::Photo');
}

# no clone yet
# {
#   my $image = Image::Base::Tk::Photo->new (-for_widget => $mw,
#                                            -width => 6,
#                                            -height => 7);
#   my $i2 = $image->new;
#   is (defined $i2 && $i2->isa('Image::Base') && 1,
#       1,
#       'isa Image::Base');
#   is (defined $i2 && $i2->isa('Image::Base::Tk::Photo') && 1,
#       1,
#       'isa Image::Base::Tk::Photo');
#   is ($i2->get('-width'),  6, 'copy object -width');
#   is ($i2->get('-height'), 7, 'copy object -height');
#   is ($i2->get('-tkphoto') != $image->get('-tkphoto'),
#       1,
#       'copy object different -tkphoto');
# }

#------------------------------------------------------------------------------
# new() / load() of empty.dat

{
  require FindBin;
  require File::Spec;
  my $filename = File::Spec->catfile($FindBin::Bin, 'empty.dat');
  my $image = Image::Base::Tk::Photo->new (-for_widget => $mw,
                                           -width => 1, -height => 1);
  isnt ($image->get('-tkphoto'), undef);

  my $ret = eval { $image->load($filename); 1 };
  my $err = $@;
  # diag "load of $filename: ", $err;

  is ($ret, undef, "load() $filename");
  ok ($err);
  isnt ($image->get('-tkphoto'), undef);
}
{
  require FindBin;
  require File::Spec;
  my $filename = File::Spec->catfile($FindBin::Bin, 'empty.dat');
  my $image = eval { Image::Base::Tk::Photo->new (-for_widget => $mw,
                                                  -file => $filename) };
  my $err = $@;
  is ($image, undef, "new() $filename");
  ok ($err);
}


#------------------------------------------------------------------------------

{
  require MyTestImageBase;
  my $image = Image::Base::Tk::Photo->new (-for_widget => $mw,
                                           -width => 21,
                                           -height => 10);
  MyTestImageBase::check_image ($image);
}

exit 0;
