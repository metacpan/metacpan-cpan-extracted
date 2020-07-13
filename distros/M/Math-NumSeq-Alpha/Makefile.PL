#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2020 Kevin Ryde

# This file is part of Math-NumSeq-Alpha.
#
# Math-NumSeq-Alpha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq-Alpha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq-Alpha.  If not, see <http://www.gnu.org/licenses/>.


# Maybe:
# A008522 Numbers that contain the letter "t".
# A008553 Numbers that contain the letter "y".


use 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME          => 'Math::NumSeq::Alpha',
   ABSTRACT      => 'Alphabetical number sequences.',
   VERSION_FROM  => 'lib/Math/NumSeq/AlphabeticalLength.pm',
   PREREQ_PM     => {
                     'Math::NumSeq' => 0,
                     'Math::NumSeq::OEIS::Catalogue::Plugin' => 0,
                     # IterateIth documented in v.53, past versions ok too
                     'Math::NumSeq::Base::IterateIth' => 0,

                     'constant' => '1.02', # version 1.02 for leading underscore
                     'constant::defer' => 1,
                     'List::Util' => 0,

                     'Lingua::Any::Numbers' => 0,

                     # for the default sequence, and Lingua::Any::Numbers
                     # demands this too
                     'Lingua::EN::Numbers' => 0,
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
     { homepage => 'http://user42.tuxfamily.org/math-numseq/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },

     recommends =>
     {
      # depends is any version of Lingua::Any::Numbers, but:
      # version 0.44 fixes "CONLANG" in available() languages
      # version 0.45 works in -T taint mode
      'Lingua::Any::Numbers' => '0.45',
     },
     prereqs =>
     { test =>
       { suggests =>
         { 'Data::Float' => 0, }
       },
     },

     # Math::NumSeq::Alpha gets the dist name, no actual module of that name
     provides =>
     { 'Math::NumSeq::Alpha' => { file => 'META.yml',
                                  version => 4,
                                },
       'Math::NumSeq::AlphabeticalLength' =>
       { file => 'lib/Math/NumSeq/AlphabeticalLength.pm',
         version => 4,
       },
       'Math::NumSeq::AlphabeticalLengthSteps' =>
       { file => 'lib/Math/NumSeq/AlphabeticalLengthSteps.pm',
         version => 4,
       },
       'Math::NumSeq::SevenSegments' =>
       { file => 'lib/Math/NumSeq/SevenSegments.pm',
         version => 4,
       },
     },
   },
  );
