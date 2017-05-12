#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Image-Base-Other',
   ABSTRACT     => 'Misc other helpers for Image::Base.',
   VERSION_FROM => 'lib/Image/Base/Text.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   PREREQ_PM    => {
                    'Image::Base' => '1.12',  # for ellipse() $fill
                    'List::Util' => 0,
                    'Test' => 0,
                   },
   # maybe aiming for 5.004 same as Image::Base,
   # though file open()s easier in 5.6
   MIN_PERL_VERSION => '5.006',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/image-base-other/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     optional_features =>
     {
      maximum_tests =>
      { description => 'Have "make test" do as much as possible.',
        requires => { # Test::Weaken 2.002 for "ignore"
                     'Test::Weaken' => '2.002',
                     'File::Temp' => '0.14',
                    },
      },
     },
   },
  );
