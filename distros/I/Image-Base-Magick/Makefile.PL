#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2014, 2015 Kevin Ryde

# This file is part of Image-Base-Magick.
#
# Image-Base-Magick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-Magick is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Magick.  If not, see <http://www.gnu.org/licenses/>.

require 5.001;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Image::Base::Magick',
   ABSTRACT     => 'Image::Base on files using ImageMagick.',
   VERSION_FROM => 'lib/Image/Base/Magick.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   PREREQ_PM    => {
                    'Image::Base' => 0,

                    # maybe 0.39 of Nov 2001 for oop style tags,
                    # oopery is from somewhere post 0.20 at least
                    'Image::Magick' => 0,
                   },
   TEST_REQUIRES => {
                     'Test' => 0,
                    },

   # Magick might go right back to 5.002 or some such
   MIN_PERL_VERSION => '5.001',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/image-base-magick/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },

     prereqs =>
     { test =>
       { suggests =>
         { 'Test::Weaken' => '2.000',
         },
       },
     },
   },
  );
