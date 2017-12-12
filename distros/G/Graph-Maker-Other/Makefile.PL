#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde

# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.


use 5.004;
use strict;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
                 'Graph::Maker'        => 0,
                 'Graph::Maker::Star'  => 0,
                 'Graph::Maker::Wheel' => 0,

                 # a sub-dependency of Graph::Maker but not here directly
                 # 'Class::Factory' => 0,
                );
my %TEST_REQUIRES = (
                     # for the t/*.t tests
                     'Test'  => 0,

                     # Don't have to use Graph.pm at runtime, can direct to
                     # something else.  The tests do use Graph.pm though.
                     # Dunno what version might be needed, maybe something
                     # moderately recent.
                     'Graph' => 0,

                     'Graph::Maker::Complete' => 0,
                     'Graph::Maker::Hypercube' => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME             => 'Graph::Maker::Other',
   ABSTRACT         => 'Create Graph.pm graph theory graphs of various kinds.',
   VERSION_FROM     => 'lib/Graph/Maker/BinomialTree.pm',
   MIN_PERL_VERSION => '5.004',
   PREREQ_PM        => \%PREREQ_PM,
   TEST_REQUIRES    => \%TEST_REQUIRES,

   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/graph-maker-other/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory => ['devel','xt'] },

     # Graph::Maker::Other gets the dist name, no actual module of that name
     provides =>
     { 'Graph::Maker::Other' => { file => 'META.yml',
                                  version => 10,
                                },
       'Graph::Maker::Beineke' =>
       { file => 'lib/Graph/Maker/Beineke.pm',
         version => 10,
       },
       'Graph::Maker::BinaryBeanstalk' =>
       { file => 'lib/Graph/Maker/BinaryBeanstalk.pm',
         version => 10,
       },
       'Graph::Maker::BinomialTree' =>
       { file => 'lib/Graph/Maker/BinomialTree.pm',
         version => 10,
       },
       'Graph::Maker::BiStar' =>
       { file => 'lib/Graph/Maker/BiStar.pm',
         version => 10,
       },
       'Graph::Maker::FibonacciTree' =>
       { file => 'lib/Graph/Maker/FibonacciTree.pm',
         version => 10,
       },
       'Graph::Maker::GosperIsland' =>
       { file => 'lib/Graph/Maker/GosperIsland.pm',
         version => 10,
       },
       'Graph::Maker::Hanoi' =>
       { file => 'lib/Graph/Maker/Hanoi.pm',
         version => 10,
       },
       'Graph::Maker::HexGrid' =>
       { file => 'lib/Graph/Maker/HexGrid.pm',
         version => 10,
       },
       'Graph::Maker::Johnson' =>
       { file => 'lib/Graph/Maker/Johnson.pm',
         version => 10,
       },
       'Graph::Maker::Keller' =>
       { file => 'lib/Graph/Maker/Keller.pm',
         version => 10,
       },
       'Graph::Maker::Kneser' =>
       { file => 'lib/Graph/Maker/Kneser.pm',
         version => 10,
       },
       'Graph::Maker::KnightGrid' =>
       { file => 'lib/Graph/Maker/KnightGrid.pm',
         version => 10,
       },
       'Graph::Maker::NoughtsAndCrosses' =>
       { file => 'lib/Graph/Maker/NoughtsAndCrosses.pm',
         version => 10,
       },
       'Graph::Maker::Petersen' =>
       { file => 'lib/Graph/Maker/Petersen.pm',
         version => 10,
       },
       'Graph::Maker::QuartetTree' =>
       { file => 'lib/Graph/Maker/QuartetTree.pm',
         version => 10,
       },
       'Graph::Maker::RookGrid' =>
       { file => 'lib/Graph/Maker/RookGrid.pm',
         version => 10,
       },
       'Graph::Maker::TwinAlternateAreaTree' =>
       { file => 'lib/Graph/Maker/TwinAlternateAreaTree.pm',
         version => 10,
       },
       'Graph::Maker::TwindragonAreaTree' =>
       { file => 'lib/Graph/Maker/TwindragonAreaTree.pm',
         version => 10,
       },
     },
   },
  );
