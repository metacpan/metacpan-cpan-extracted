#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

# This file is part of HTML-FormatExternal.
#
# HTML-FormatExternal is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# HTML-FormatExternal is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with HTML-FormatExternal.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
                 'constant::defer' => 0,
                 'IPC::Run'   => 0,
                 'URI::file'  => 0.08, # version 0.08 for new_abs()

                 # Version 0.18 for overloaded eq() which File::Copy
                 # calls :-(.  Only actually needed for the "base" option
                 # with input from a file.
                 'File::Temp' => 0.18,

                 # Version 0.80 for File::Spec->devnull(), which came
                 # with Perl 5.6.0 already in fact.
                 'File::Spec' => 0.80,
                );
my %TEST_REQUIRES = (
                     # for the t/*.t tests
                     'Test::More' => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # fallback if ExtUtils::MakeMaker doesn't know TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME             => 'HTML::FormatExternal',
   ABSTRACT         => 'HTML to text formatting using external programs.',
   VERSION_FROM     => 'lib/HTML/FormatExternal.pm',
   MIN_PERL_VERSION => '5.006',
   PREREQ_PM        => \%PREREQ_PM,
   TEST_REQUIRES    => \%TEST_REQUIRES,

   AUTHOR           => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE          => 'gpl_3',
   SIGN             => 1,

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     no_index => { directory=>['devel','xt'] },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/html-formatexternal/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },

     prereqs =>
     { test =>
       { suggests =>
         { 'HTML::TreeBuilder' => 0,
           'Taint::Util' => 0,
         },
       },
     },
   },
  );
