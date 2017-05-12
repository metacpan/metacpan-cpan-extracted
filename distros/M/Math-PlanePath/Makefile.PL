#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME          => 'Math::PlanePath',
   ABSTRACT      => 'Mathematical paths through the 2-D plane.',
   VERSION_FROM  => 'lib/Math/PlanePath.pm',
   PREREQ_PM     => {
                     'Math::Libm' => 0, # for hypot() mainly
                     'List::Util' => 0,
                     'constant' => '1.02',   # 1.02 for leading underscore
                     'constant::defer' => 5, # v.5 for Perl 5.6 fixes
                    },
   TEST_REQUIRES => {
                     'Test' => 0,
                    },
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE       => 'gpl_3',
   SIGN          => 1,
   MIN_PERL_VERSION => '5.004',

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/math-planepath/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'],
                   # these are in Math-PlanePath-Toothpick but added to by
                   # Math::NumSeq::PlanePathCoord here
                   package   => [ 'Math::PlanePath::ToothpickTree',
                                  'Math::PlanePath::ToothpickReplicate',
                                  'Math::PlanePath::ToothpickUpist',
                                  'Math::PlanePath::LCornerTree',
                                  'Math::PlanePath::LCornerReplicate',
                                  'Math::PlanePath::OneOfEight',
                                ],
                 },
     prereqs =>
     { test =>
       { suggests =>
         {
          # have "make test" do as much as possible
          'Data::Float'        => 0,
          'Math::BigInt'       => 0,
          'Math::BigInt::Lite' => 0,
          'Math::BigFloat'     => '1.993',
          'Math::BigRat'       => 0,
         },
       },
     },
   },
  );
