#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME          => 'Math::PlanePath::Toothpick',
   ABSTRACT      => 'Toothpick and other cellular automaton mathematical paths through the 2-D plane.',
   VERSION_FROM  => 'lib/Math/PlanePath/LCornerTree.pm',
   PREREQ_PM     => {
                     'constant' => '1.02', # 1.02 for leading underscore
                     # 'List::Util' => 0,

                     # v.106 for tree_num_children_minimum() calling to
                     # tree_num_children_list()
                     'Math::PlanePath' => 106,
                     'Math::PlanePath::Base::NSEW' => 116, # new in v.116
                     'Math::PlanePath::Base::Digits' => 119, # v.119 for round_up_pow()
                     'Math::PlanePath::Base::Generic' => 91,
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
     no_index    => { directory=>['devel','xt'] },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/math-planepath/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
   },
  );
