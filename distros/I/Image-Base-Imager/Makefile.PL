#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2014, 2015, 2019 Kevin Ryde

# This file is part of Image-Base-Imager.
#
# Image-Base-Imager is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-Imager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Imager.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
                 # actually only need the base diamond() for testing
                 'Image::Base' => '1.16',  # for diamond()

                 # maybe 0.39 of Nov 2001 for oop style tags,
                 # oopery is from somewhere post 0.20 at least
                 'Imager' => 0.39,
                );
my %TEST_REQUIRES = (
                     'Test' => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME          => 'Image::Base::Imager',
   ABSTRACT      => 'Image::Base on various file formats using Imager.',
   VERSION_FROM  => 'lib/Image/Base/Imager.pm',
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE       => 'gpl_3',
   SIGN          => 1,
   PREREQ_PM     => \%PREREQ_PM,
   TEST_REQUIRES => \%TEST_REQUIRES,
   # Imager goes right back to 5.003 or some such
   MIN_PERL_VERSION => '5.004',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/image-base-imager/index.html',
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
