#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2014, 2015, 2019 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use ExtUtils::MakeMaker;


my %PREREQ_PM = ('Filter::Util::Call' => 0,
                 'Compress::Raw::Zlib' => 0,
                 'PerlIO' => 0,
                 'PerlIO::gzip' => 0,
                );
my %TEST_REQUIRES = ('Test' => 0,
                     'Test::More' => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME         => 'Filter::gunzip',
   ABSTRACT     => 'Source filter uncompressing gzip files.',
   VERSION_FROM => 'lib/Filter/gunzip.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,

   # Filter::Util::Call is 5.006 because it uses warnings.pm
   # PerlIO::gzip is 5.008
   MIN_PERL_VERSION => '5.006',

   PREREQ_PM        => \%PREREQ_PM,
   TEST_REQUIRES    => \%TEST_REQUIRES,

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/filter-gunzip/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },
   },
  );
