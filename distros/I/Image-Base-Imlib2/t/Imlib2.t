#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-Imlib2.
#
# Image-Base-Imlib2 is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Imlib2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Imlib2.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Devel::Comments;

my $test_count = 2480;
plan tests => $test_count;

if (! eval { require Image::Imlib2; 1 }) {
  MyTestHelpers::diag ('Image::Imlib2 not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Image::Imlib2 not available', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ("Image::Imlib2 VERSION $Image::Imlib2::VERSION");

require Image::Base::Imlib2;


my $test_file_format = 'argb';
# {
#   foreach my $format ('png','gif') {
#     my $temp_filename = "tempfile.$format";
#     MyTestHelpers::diag ("Tempfile try $temp_filename");
#
#     my $image = Image::Imlib2->new(1,1);
#     if (eval { $image->save($temp_filename); 1 }) {
#       $test_file_format = $format;
#     }
#   }
#   if (! $test_file_format) {
#   }
# }
# MyTestHelpers::diag ("test_file_format ", $test_file_format);


#------------------------------------------------------------------------------
# VERSION

my $want_version = 1;
ok ($Image::Base::Imlib2::VERSION,
    $want_version,
    'VERSION variable');

# ->VERSION() only in 5.004 up ...
#
# ok (Image::Base::Imlib2->VERSION,
#     $want_version,
#     'VERSION class method');
# 
# ok (eval { Image::Base::Imlib2->VERSION($want_version); 1 },
#     1,
#     "VERSION class check $want_version");
# my $check_version = $want_version + 1000;
# ok (! eval { Image::Base::Imlib2->VERSION($check_version); 1 },
#     1,
#     "VERSION class check $check_version");


#-----------------------------------------------------------------------------
# -file_format

{
  my $image = Image::Base::Imlib2->new;
  # {
  #   my $format = $test_file_format;
  #   $image->set (-file_format => $format);
  #   ok ($image->get('-file_format'), $format,
  #       "set() -file_format to $format");
  # }
  # {
  #   $image->set (-file_format => '');
  #   ok ($image->get('-file_format'),
  #       '',
  #       "set() -file_format to empty ''");
  # }

  # -file_format is not checked on set()
  # {
  #   my $eval = eval {
  #     $image->set(-file_format => 'image-base-imlib2-test-no-such-format');
  #     1;
  #   };
  #   my $err = $@;
  #   ok ($eval, undef,
  #       'set() -file_format invalid eval');
  #   like ($err, '/Unrecognised -file_format/',
  #         'set() -file_format invalid error');
  # }
}


#------------------------------------------------------------------------------
# new() clone image, and resize

{
  my $i1 = Image::Base::Imlib2->new
    (-width => 11, -height => 22);
  my $i2 = $i1->new;
  # no resize yet ...
  # $i2->set (-width => 33, -height => 44);

  ok ($i1->get('-width'), 11, 'clone original width');
  ok ($i1->get('-height'), 22, 'clone original height');
  ok ($i2->get('-width'), 11, 'clone new width');
  ok ($i2->get('-height'), 22, 'clone new height');
  ok ($i1->get('-imlib') != $i2->get('-imlib'),
      1,
      'cloned -imlib object different');
}

#------------------------------------------------------------------------------
# xy

{
  my $image = Image::Base::Imlib2->new
    (-width => 20,
     -height => 10);
  $image->xy (2,2, '#000');
  ok ($image->xy (2,2), '#000000', 'xy() #000');

  $image->xy (3,3, "#010203");
  ok ($image->xy (3,3), '#010203', 'xy() rgb');
}

# no resize yet
# {
#   my $image = Image::Base::Imlib2->new
#     (-width => 2, -height => 2);
#   $image->set(-width => 20, -height => 20);
# 
#   $image->xy (10,10, 'white');
#   ok ($image->xy (10,10), '#FFFFFF', 'xy() in resize');
# }


#------------------------------------------------------------------------------
# load() errors

my $temp_filename = "tempfile.$test_file_format";
MyTestHelpers::diag ("Tempfile $temp_filename");
unlink $temp_filename;
ok (! -e $temp_filename,
    1,
    "removed any existing $temp_filename");
END {
  if (defined $temp_filename) {
    MyTestHelpers::diag ("Remove tempfile $temp_filename");
    unlink $temp_filename
      or MyTestHelpers::diag("Oops, cannot remove $temp_filename: $!");
  }
}

{
  my $eval_ok = 0;
  my $ret = eval {
    my $image = Image::Base::Imlib2->new (-file => $temp_filename);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  ### $eval_ok
  ### $err
  ok ($eval_ok, 0, 'new() error for no file - doesn\'t reach end');
  ok (! defined $ret, 1, 'new() error for no file - return undef');
  ok ($err,
      '/does not exist/',
      'new() error for no file - error string "Cannot"');
}
{
  my $eval_ok = 0;
  my $image = Image::Base::Imlib2->new;
  my $ret = eval {
    $image->load ($temp_filename);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  # diag "load() err is \"",$err,"\"";
  ok ($eval_ok, 0, 'load() error for no file - doesn\'t reach end');
  ok (! defined $ret, 1, 'load() error for no file - return undef');
  ok ($err,
      '/does not exist/',
      'load() error for no file - error string "Cannot"');
}

#-----------------------------------------------------------------------------
# save() errors

{
  my $eval_ok = 0;
  my $nosuchdir = "no/such/directory/foo.$test_file_format";
  my $image = Image::Base::Imlib2->new (-width => 1,
                                        -height => 1);
  my $ret = eval {
    $image->save ($nosuchdir);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  # diag "save() err is \"",$err,"\"";
  ok ($eval_ok, 0, 'save() error for no dir - doesn\'t reach end');
  ok (! defined $ret, 1, 'save() error for no dir - return undef');
  ok ($err, '/error/', 'save() error for no dir - error string');
}
{
  my $eval_ok = 0;
  my $nosuchext = 'tempfile.unrecognisedextension';
  my $image = Image::Base::Imlib2->new (-width => 1,
                                        -height => 1);
  my $ret = eval {
    $image->save ($nosuchext);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  # diag "save() err is \"",$err,"\"";
  ok ($eval_ok, 0, 'save() error for unknown ext - doesn\'t reach end');
  ok (! defined $ret, 1, 'save() error for unknown ext - return undef');
  ok ($err, '/error/', 'save() error for no dir - error string');
}


#-----------------------------------------------------------------------------
# save() / load()

{
  require Image::Imlib2;
  my $imlib_obj = Image::Imlib2->new (20, 10);
  ok ($imlib_obj->width, 20);
  ok ($imlib_obj->height, 10);
  my $image = Image::Base::Imlib2->new
    (-imlib => $imlib_obj);
  $image->save ($temp_filename);
  ok (-e $temp_filename,
      1,
      "save() to $temp_filename, -e exists");
  ok (-s $temp_filename > 0,
      1,
      "save() to $temp_filename, -s non-empty");
}
{
  my $image = Image::Base::Imlib2->new (-file => $temp_filename);
  # ok ($image->get('-file_format'),
  #     $test_file_format,
  #     'load() with new(-file)');
}
{
  my $image = Image::Base::Imlib2->new;
  $image->load ($temp_filename);
  # ok ($image->get('-file_format'),
  #     $test_file_format,
  #     'load() method');
}

#------------------------------------------------------------------------------
# save -file_format

{
  my $imlib_obj = Image::Imlib2->new (10, 10);
  my $image = Image::Base::Imlib2->new
    (-imlib       => $imlib_obj,
     -file_format => $test_file_format);
  $image->save ($temp_filename);
  ok (-e $temp_filename,
      1,
      'save() with -file_format exists');
  ok (-s $temp_filename > 0,
      1,
      'save() with -file_format not empty');

  # system ("ls -l $temp_filename");
  # system ("file $temp_filename");
}
{
  my $image = Image::Base::Imlib2->new (-file => $temp_filename);
  # ok ($image->get('-file_format'),
  #     $test_file_format,
  #     'save() -file_format load back format');
}

#------------------------------------------------------------------------------
# save -quality_percent

# {
#   my $good = 1;
#   foreach my $file_format ('jpeg'->write_types) {
#     my $image = Image::Base::Imlib2->new
#       (-width => 100,
#        -height => 50,
#        -file_format => $test_file_format,
#        -quality_percent => 50);
#     $image->save ($temp_filename);
#     # system ("ls -l $temp_filename");
#     # system ("file $temp_filename");
#     unless (-e $temp_filename) {
#       MyTestHelpers::diag ("save() $file_format with -quality_percent, file does not exist");
#       $good = 0;
#       next;
#     }
#     unless (-s $temp_filename > 0) {
#       MyTestHelpers::diag ("save() $file_format with -quality_percent, file is empty");
#       $good = 0;
#       next;
#     }
#   }
#   ok ($good, 1, "each write_types with -quality_percent");
# }


#------------------------------------------------------------------------------
# check_image

{
  my $image = Image::Base::Imlib2->new
    (-width  => 20,
     -height => 10);
  ok ($image->get('-width'), 20);
  ok ($image->get('-height'), 10);

  $image->xy (0,0, '#FFFF00000000');
  ok ($image->xy(0,0), '#FF0000');

  require MyTestImageBase;
  $MyTestImageBase::black = '#000000';
  $MyTestImageBase::white = '#FFFFFF';
  $MyTestImageBase::black = '#000000';
  $MyTestImageBase::white = '#FFFFFF';
  MyTestImageBase::check_image ($image);
  MyTestImageBase::check_diamond ($image);
}

exit 0;
