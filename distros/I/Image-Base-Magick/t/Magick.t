#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Magick.
#
# Image-Base-Magick is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Magick is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Magick.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;

my $test_count = (tests => 2518)[1];
plan tests => $test_count;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;


# only test on 6.6 up since 6.5.5 seen doing dodgy stuff on a 3x3 ellipse,
# coming out with an excess to the right like
#     _____www____________
#     _____wwwww__________
#     _____www____________
#

my $have_image_magick = eval { require Image::Magick; 1 };
if ($have_image_magick) {
  MyTestHelpers::diag ("Image::Magick VERSION $Image::Magick::VERSION");

  # Demand 6.6 or higher for bug fixes.  But not Image::Magick->VERSION(6.6)
  # as that provokes badness when non-numeric $VERSION='6.6.0'.
  my $im_version = Image::Magick->VERSION;
  if ($im_version =~ /([0-9]*(\.[0-9]*)?)/) {
    my $im_two_version = $1;
    if ($im_two_version < 6.6) {
      MyTestHelpers::diag ("Image::Magick 6.6 not available -- im_version $im_version im_two_version $im_two_version");
      $have_image_magick = 0;
    }
  }
}
if (! $have_image_magick) {
  foreach (1 .. $test_count) {
    skip ('no Image::Magick 6.6', 1, 1);
  }
  exit 0;
}

require Image::Base::Magick;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 4;
ok ($Image::Base::Magick::VERSION,
    $want_version,
    'VERSION variable');
ok (Image::Base::Magick->VERSION,
    $want_version, 'VERSION class method');

ok (eval { Image::Base::Magick->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::Magick->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");


my $temp_filename = 'tempfile.png';
MyTestHelpers::diag ("Tempfile ",$temp_filename);
unlink $temp_filename;
ok (! -e $temp_filename, 1, "removed any existing $temp_filename");
END {
  if (defined $temp_filename) {
    MyTestHelpers::diag ("Remove tempfile ",$temp_filename);
    unlink $temp_filename
      or MyTestHelpers::diag ("No remove $temp_filename: ",$!);
  }
}

#-----------------------------------------------------------------------------
# save() -zlib_compression

{
  my $image = Image::Base::Magick->new (-width => 300,
                                        -height => 300,
                                        -file_format => 'png',
                                        -zlib_compression => 0);
  $image->rectangle(0,0, 299,299, '#000000', 1); # black fill
  $image->rectangle(0,0, 299,299, '#FFFFFF');    # white border
  $image->save ($temp_filename);
  my $uncomp_size = -s $temp_filename;

  $image->set (-zlib_compression => 9);
  $image->save;
  my $comp_size = -s $temp_filename;

  ### $uncomp_size
  ### $comp_size
  if ($comp_size >= $uncomp_size) {
    MyTestHelpers::diag ("oops, uncomp_size $uncomp_size  comp_size $comp_size");
  }
  ok ($comp_size < $uncomp_size, 1,
      "save() -zlib_compression makes a smaller file");
}

#------------------------------------------------------------------------------
# %d filename ... not yet ready for 'temp%d.png'

my $percent_filename = 'temp%d.png';
MyTestHelpers::diag ("Percentfile ",$percent_filename);
unlink $percent_filename;
ok (! -e $percent_filename, 1, "removed any existing $percent_filename");
END {
  if (defined $percent_filename) {
    MyTestHelpers::diag ("Remove percentfile ",$percent_filename);
    unlink $percent_filename
      or MyTestHelpers::diag ("No remove $percent_filename: ",$!);
  }
}
{
  my $image = Image::Base::Magick->new (-width => 20,
                                                        -height => 10,
                                                        -file_format => 'png');
  $image->save ($percent_filename);
  ok (-e $percent_filename, 1,
      "save() to $percent_filename, -e exists");
  ok (-s $percent_filename > 0, 1,
      "save() to $percent_filename, -s non-empty");
  ok ($image->get('-file'), $percent_filename,
      'save() sets -file');
}

my $num_filename = 'temp001.png';
MyTestHelpers::diag ("Numfile ",$num_filename);
unlink $num_filename;
ok (! -e $num_filename, 1, "removed any existing $num_filename");
END {
  if (defined $num_filename) {
    MyTestHelpers::diag ("Remove numfile ",$num_filename);
    unlink $num_filename
      or MyTestHelpers::diag ("No remove $num_filename: ",$!);
  }
}
{
  my $image = Image::Base::Magick->new (-width => 5,
                                                        -height => 6,
                                                        -file_format => 'png');
  $image->save ($num_filename);
  ok (-e $num_filename, 1,
      "save() to $num_filename, -e exists");
  ok (-s $num_filename > 0, 1,
      "save() to $num_filename, -s non-empty");
  ok ($image->get('-file'), $num_filename,
      'save() sets -file');
}

# system "ls -l '$percent_filename' '$num_filename'";

{
  my $image = Image::Base::Magick->new;
  $image->load ($percent_filename);
  ### $image

  ok ($image->get('-width'), 20,
      "load() $percent_filename -width");
  ok ($image->get('-height'), 10,
      "load() $percent_filename -height");
  ok ($image->get('-file_format'), 'PNG',
      "load() $percent_filename -file_format");
  ok ($image->get('-file'), $percent_filename,
      "load() $percent_filename sets -file");
}

{
  my $image = Image::Base::Magick->new
    (-file => $num_filename);
  ok ($image->get('-width'), 5,
      'new(-file) -width');
  ok ($image->get('-height'), 6,
      'new(-file) -height');
  ok ($image->get('-file_format'), 'PNG',
      'new(-file) -file_format');
  ok ($image->get('-file'), $num_filename,
      'new(-file) sets -file');
}

#------------------------------------------------------------------------------
# new

{
  my $image = Image::Base::Magick->new
    (-width => 20,
     -height => 10);
  ok (! exists $image->{'-width'}, 1);
  ok (! exists $image->{'-height'}, 1);
  ok ($image->get('-width'), 20);
  ok ($image->get('-height'), 10);

  $image->set (-width => 15);
  ok ($image->get('-width'), 15, 'resize -width');
  ok ($image->get('-height'), 10, 'unchanged -height');
}


#------------------------------------------------------------------------------
# new() clone image, and resize

{
  my $i1 = Image::Base::Magick->new
    (-width => 11, -height => 22);
  my $i2 = $i1->new;
  $i2->set(-width => 33, -height => 44);

  ok ($i1->get('-width'), 11);
  ok ($i1->get('-height'), 22);
  ok ($i2->get('-width'), 33);
  ok ($i2->get('-height'), 44);
  ok ($i1->get('-imagemagick') != $i2->get('-imagemagick'), 1);
}


#------------------------------------------------------------------------------
# xy()

{
  my $image = Image::Base::Magick->new
    (-width => 20,
     -height => 10);
  $image->xy(3,4, '#AABBCC');
  ok ($image->xy(3,4), '#AABBCC', 'xy() stored');
}
{
  my $image = Image::Base::Magick->new
    (-width => 2, -height => 2);
  $image->set(-width => 20, -height => 20);

  # MyTestHelpers::dump ($image);
  # MyTestHelpers::diag ("xy() in resize store");
  $image->xy (10,10, '#FFFFFF');
  # MyTestHelpers::diag ("xy() in resize read");
  ok ($image->xy (10,10), '#FFFFFF', 'xy() in resize');
}


#------------------------------------------------------------------------------
# rectangle()

{
  my $image = Image::Base::Magick->new
    (-width => 20,
     -height => 10);
  $image->get('-imagemagick')->Set (antialias => 0);

  $image->rectangle(2,2, 4,4, '#AABBCC');
  ok ($image->xy(2,2), '#AABBCC', 'rectangle() unfilled drawn');
  ok ($image->xy(3,3), '#000000', 'rectangle() unfilled centre undrawn');
}
{
  my $image = Image::Base::Magick->new
    (-width => 20,
     -height => 10);
  $image->get('-imagemagick')->Set (antialias => 0);

  $image->rectangle(2,2, 4,4, '#AABBCC', 1);
  ok ($image->xy(2,2), '#AABBCC', 'rectangle() filled drawn');
  ok ($image->xy(3,3), '#AABBCC', 'rectangle() filled centre');

  # $image->get('-imagemagick')->Write ('xpm:-');  
}
{
  my $image = Image::Base::Magick->new
    (-width => 20,
     -height => 10);
  $image->get('-imagemagick')->Set (antialias => 0);

  $image->rectangle(2,2, 2,2, '#AABBCC', 1);
  ok ($image->xy(2,2), '#AABBCC', 'rectangle() 1x1 filled drawn');
}
{
  my $image = Image::Base::Magick->new
    (-width => 20,
     -height => 10);
  $image->get('-imagemagick')->Set (antialias => 0);

  $image->rectangle(2,2, 2,2, '#AABBCC', 0);
  ok ($image->xy(2,2), '#AABBCC', 'rectangle() 1x1 unfilled drawn');
}


#------------------------------------------------------------------------------
# line()

{
  my $image = Image::Base::Magick->new
    (-width => 20,
     -height => 10);

  $image->get('-imagemagick')->Set (width => 10, height=> 5);
  $image->get('-imagemagick')->Set (antialias => 0);
  $image->line(0,0, 5,5, '#AABBCC');
  ok ($image->xy(5,0), '#000000', 'line() away');
  ok ($image->xy(2,2), '#AABBCC', 'line() drawn');
}


#------------------------------------------------------------------------------
# load() errors

{
  unlink $temp_filename;
  ok (! -e $temp_filename);

  my $eval_ok = 0;
  my $ret = eval {
    my $image = Image::Base::Magick->new
      (-file => $temp_filename);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  # MyTestHelpers::diag "new() err is \"",$err,"\"";
  ok ($eval_ok, 0,
      'new() error for no file - eval no succeed');
  ok ($ret, undef,
      'new() error for no file - return undef');
  ok ($err, '/^Cannot|unable/',
      'new() error for no file - error string');
}
{
  my $eval_ok = 0;
  my $image = Image::Base::Magick->new;
  my $ret = eval {
    $image->load ($temp_filename);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  # MyTestHelpers::diag "load() err is \"",$err,"\"";
  ok ($eval_ok, 0,
      'load() error for no file - doesn\'t reach end');
  ok ($ret, undef,
      'load() error for no file - return undef');
  ok ($err, '/^Cannot|unable/',
      'load() error for no file - error string');
}

#-----------------------------------------------------------------------------
# save() / load()

{
  my $image = Image::Base::Magick->new (-width => 20,
                                        -height => 10,
                                        -file_format => 'png');
  $image->save ($temp_filename);
  ok (-e $temp_filename, 1,
      "save() to $temp_filename, -e exists");
  ok (-s $temp_filename > 0, 1,
      "save() to $temp_filename, -s non-empty");
}

{
  my $image = Image::Base::Magick->new (-file => $temp_filename);
  ok ($image->get('-width'), 20, 'new(-file) -width');
  ok ($image->get('-height'), 10, 'new(-file) -height');
  ok ($image->get('-file_format'), 'PNG', 'new(-file) -file_format');
  ok ($image->get('-file'), $temp_filename, 'new() sets -file');
  ### $image
}

{
  my $image = Image::Base::Magick->new;
  $image->load ($temp_filename);
  ok ($image->get('-width'), 20, 'load() -width');
  ok ($image->get('-height'), 10, 'load() -height');
  ok ($image->get('-file_format'), 'PNG', 'load() -file_format');
  ok ($image->get('-file'), $temp_filename, 'load() sets -file');
}

#------------------------------------------------------------------------------
# check_image()

{
  my $image = Image::Base::Magick->new
    (-width  => 20,
     -height => 10);
  ok ($image->get('-width'), 20);
  ok ($image->get('-height'), 10);
  my $m = $image->get('-imagemagick');
  $m->Set (antialias => 0);

  require MyTestImageBase;
  MyTestImageBase::check_image ($image,
                               big_fetch_expect => '#000000');
  MyTestImageBase::check_diamond ($image);
}

exit 0;
