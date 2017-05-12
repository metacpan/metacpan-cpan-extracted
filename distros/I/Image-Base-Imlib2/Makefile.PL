#!/usr/bin/perl

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-Imlib2.
#
# Image-Base-Imlib2 is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-Imlib2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Imlib2.  If not, see <http://www.gnu.org/licenses/>.

require 5;
use strict;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Image-Base-Imlib2',
   ABSTRACT     => 'Image::Base on files using Image::Imlib2.',
   VERSION_FROM => 'lib/Image/Base/Imlib2.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   PREREQ_PM    => {
                    'Image::Base' => 0,
                    'Image::Imlib2' => 0,

                    # for testing
                    'Test' => 0,
                   },
   # Imlib2 might use almost any
   MIN_PERL_VERSION => '5',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/image-base-imlib2/index.html',
     },
     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::Weaken' => '2.000',
                     },
       },
     },
   },
  );
