#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Math-Aronson',
   ABSTRACT     => 'Generate Aronson\'s sequence.',
   VERSION_FROM => 'lib/Math/Aronson.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   PREREQ_PM    => {
                    'Lingua::EN::Numbers'  => '1.01', # incompatible rewrite
                    'Lingua::FR::Numbers'  => '0.04', # incompatible rewrite
                   },
   MIN_PERL_VERSION => '5.004',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/math-aronson/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },

     recommends => {
                    'Lingua::Any::Numbers' => '0.21', # maybe changed funcs?
                    'Unicode::Normalize' => 0,
                   },

     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::Weaken'            => '2.002',
                       'Test::Weaken::ExtraBits' => 1,
                     },
       },
     },
   },
  );

# maximum_devel =>
# { description => 'Stuff used variously for development.',
#   requires => { 'Smart::Comments'     => 0,
#                 'Lingua::ES::Numeros' => 0,
#                 'Unicode::CharName'   => 0,
#                 'Unicode::Normalize'  => 0,
#                 'PerlIO::locale'      => '0.06', # 5.10 fix
#               },
# },
