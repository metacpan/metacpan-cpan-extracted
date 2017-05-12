#!/usr/bin/perl

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-Polynomial-Horner.
#
# Math-Polynomial-Horner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-Polynomial-Horner is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Polynomial-Horner.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Math::Polynomial::Horner',
   ABSTRACT     => 'Stringizing Math::Polyomial objects in Horner form.',
   VERSION_FROM => 'lib/Math/Polynomial/Horner.pm',
   PREREQ_PM    => {
                    'Math::Polynomial' => 1,
                    'Test::More' => 0,
                   },
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   # Math::Polynomial itself is 5.006
   MIN_PERL_VERSION => 5.006,

   META_MERGE =>
   { resources =>
     { homepage =>
       'http://user42.tuxfamily.org/math-polynomial-horner/index.html',
     },
     optional_features =>
     { maximum_devel =>
       { description => 'Stuff used variously for development.',
         requires => { 'Smart::Comments' => 0,
                       'Math::BigRat'    => 0,
                       'B::Concise'      => 0,
                     },
       },
     },
   },
  );
