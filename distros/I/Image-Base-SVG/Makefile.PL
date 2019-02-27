#!/usr/bin/perl -w

# Copyright 2011, 2012, 2014, 2015, 2019 Kevin Ryde

# This file is part of Image-Base-SVG.
#
# Image-Base-SVG is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-SVG is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-SVG.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
                 'Image::Base' => 0,
                 # 2.38 to avoid redefinition warnings, though previous
                 # versions may work well enough if only one "use SVG"
                 # anywhere
                 'SVG'         => '2.38',
                 'SVG::Parser' => 0,
                );
my %TEST_REQUIRES = (
                     'Test::More' => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME          => 'Image::Base::SVG',
   ABSTRACT      => 'Image::Base on SVG files using the SVG module.',
   VERSION_FROM  => 'lib/Image/Base/SVG.pm',
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE       => 'gpl_3',
   SIGN          => 1,
   PREREQ_PM     => \%PREREQ_PM,
   TEST_REQUIRES => \%TEST_REQUIRES,

   # SVG.pm is 5.6.0 for weaken
   MIN_PERL_VERSION => '5.006',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/image-base-svg/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },

     prereqs =>
     { test =>
       { suggests =>
         { 'Test::Weaken' => '2.000',
           'XML::Parser::Expat' => '2.41',
         },
       },
     },
   },
  );
