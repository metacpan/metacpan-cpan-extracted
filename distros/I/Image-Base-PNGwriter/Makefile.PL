#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-PNGwriter.
#
# Image-Base-PNGwriter is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-PNGwriter is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-PNGwriter.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Image-Base-PNGwriter',
   ABSTRACT     => 'Image::Base on PNG files using PNGwriter.',
   VERSION_FROM => 'lib/Image/Base/PNGwriter.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   PREREQ_PM    => {
                    'Image::Base' => '1.12',  # for ellipse() $fill
                    'Image::PNGwriter' => 0,

                    # for testing
                    'Test::More' => 0,
                   },
   # PNGwriter itself is 5.8.5 or some such ...
   MIN_PERL_VERSION => '5.006',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/image-base-pngwriter/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'] },

     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::Weaken' => '2.000',
                     },
       },
     },
   },
  );
