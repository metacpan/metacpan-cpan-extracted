#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2014, 2015, 2019 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
                 'Image::Base' => '1.12', # for ellipse() $fill
                 'GD'          => '2.45', # 2.45 for GD::Group inst fix
                 'GD::Simple'  => 0,      # no version num in 2.45
                 'File::Temp'  => 0,      # reading XPM
                );
my %TEST_REQUIRES = (
                     'Test::More' => 0,
                     'List::Util' => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME          => 'Image::Base::GD',
   ABSTRACT      => 'Image::Base on PNG and other files using GD.',
   VERSION_FROM  => 'lib/Image/Base/GD.pm',
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE       => 'gpl_3',
   SIGN          => 1,
   PREREQ_PM     => \%PREREQ_PM,
   TEST_REQUIRES => \%TEST_REQUIRES,

   # GD is 5.6.0 (in its 2.45 Makefile.PL, perhaps not the GD.pm as such)
   MIN_PERL_VERSION => '5.006',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/image-base-gd/index.html',
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
