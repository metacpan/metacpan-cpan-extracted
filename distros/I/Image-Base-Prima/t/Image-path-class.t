#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Prima.
#
# Image-Base-Prima is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Prima is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Prima.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

use Prima::noX11; # without connecting to the server
use Prima;

my $test_count = (tests => 4)[1];
plan tests => $test_count;

if (! eval { require Path::Class; 1 }) {
  MyTestHelpers::diag ("Path::Class not available -- $@");
  foreach (1 .. $test_count) {
    skip ('due to Path::Class not available', 1, 1);
  }
  exit 0;
}

{
  my $d = Prima::Image->new;
  my $codecs = $d->codecs;
  MyTestHelpers::diag ("codecs: ",
                       join(' ',map {$_->{'fileShortType'}} @$codecs));
  my $have_bmp = 0;
  foreach my $codec (@$codecs) {
    if ($codec->{'fileShortType'} eq 'BMP') {
      $have_bmp = 1;
    }
  }
  if (! $have_bmp) {
    foreach (1 .. $test_count) {
      skip ('due to no BMP codec', 1, 1);
    }
    exit 0;
  }
}

require Image::Base::Prima::Image;

my $filename = Path::Class::File->new('tempfile.bmp');
MyTestHelpers::diag ("Tempfile ",ref($filename)," stringize $filename");
unlink $filename;
ok (! -e $filename, 1, "removed any existing $filename");
END {
  if (defined $filename) {
    MyTestHelpers::diag ("Remove tempfile ",$filename);
    unlink $filename
      or MyTestHelpers::diag ("Oops, cannot remove $filename: $!");
  }
}

#------------------------------------------------------------------------------
# save() / load()

{
  my $prima_image = Prima::Image->new (width => 10, height => 10);
  my $image = Image::Base::Prima::Image->new (-drawable => $prima_image,
-file_format => 'BMP');
  $image->save ($filename);
  ok (-e $filename, 1, "save() -file_format \"BMP\" to $filename");
}
{
  my $image = Image::Base::Prima::Image->new (-file => $filename);
  ok ($image->get('-file_format'), 'BMP',
     'load() with new(-file)');
}
{
  my $image = Image::Base::Prima::Image->new;
  $image->load ($filename);
  ok ($image->get('-file_format'), 'BMP',
      'load() method');
}

exit 0;
