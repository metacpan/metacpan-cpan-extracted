#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013, 2014 Kevin Ryde

# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;


# Crib: only print to STDERR so as not to upset "Makefile.PL PREREQ_PRINT=1"
#

my $want_xs = 1;
@ARGV = grep { /^MY_WITHOUT_XS/
                 ? do { $want_xs = 0; 0 }  # record and remove
                   : 1 } @ARGV;
if (! $want_xs) {
  print STDERR "XS skipped by request\n";
}
#
# SvRX() is new in perl 5.10.0 and ppport.h 3.19 doesn't offer an
# implementation for earlier perl
#
if ($want_xs && $] < 5.010) {
  print STDERR "XS skipped for perl $[ (believe need 5.010 for SvRX)\n";
  $want_xs = 0;
}
if ($want_xs) {
  print STDERR "XS enabled by default.
If you don't have a compiler or the .xs doesn't work then disable with
    perl Makefile.PL MY_WITHOUT_XS=1
";
}


my %file_map_optional
  = ('File::Map'=> '0.38',   # version 0.38 for taint
     'PerlIO::Layers' => 0,  # for FileMap bits, required by File::Map too
    );
my %file_map_deps
  = ('Scalar::Util' => 0, # for FileMap bits
    );

WriteMakefile
  (NAME         => 'File::Locate::Iterator',
   ABSTRACT     => 'Read "locate" database file with an iterator.',
   VERSION_FROM => 'lib/File/Locate/Iterator.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   PREREQ_PM    => { 'constant::defer' => 0,
                     'File::FnMatch'   => 0,
                     'Test::More'      => 0, # for tests only
                     %file_map_deps,
                   },
   MIN_PERL_VERSION => '5.006',

   # as of ExtUtils::MakeMaker 6.55_02 if you force XS then C is still
   # generated from scanned .xs files, so must force it too
   XS => ($want_xs ? { 'Iterator.xs' => 'Iterator.c' } : {}),
   C  => ($want_xs ? [ 'Iterator.c' ] : []),

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/file-locate-iterator/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'] },

     recommends =>
     { %file_map_optional,
       # version 0.06 fixes UNIVERSAL::isa() import
       'Iterator::Simple' => 0.06,
     },
     optional_features =>
     { maximum_examples =>
       { description => 'Be able to run all the examples programs.',
         requires => { 'Iterator' => 0,
                       'Iterator::Simple' => 0,
                       'MooseX::Iterator' => 0,
                     },
       },
       maximum_interoperation =>
       { description => 'Have maximum inter-operation with other modules (optional supported other stuff).',
         requires => { %file_map_optional,
                       'Iterator' => 0,
                       'Iterator::Simple' => 0,
                       'MooseX::Iterator' => 0,
                     },
       },
       maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Taint::Util' => 0,  # for taint testing
                       # version 3.002 for "tracked_types"
                       'Test::Weaken' => '3.002',
                     },
       },
     },
   },
  );

# maximum_devel =>
# { description => 'Stuff used variously for development.',
#   requires => { %file_map_optional,
#                 'Taint::Util'     => 0, # for FileMap bits
#                 'Devel::TimeThis' => 0,
#                 'File::Locate' => 0,
#                 'IO::String' => 0,
#                 'Perl6::Slurp' => 0,
#                 'Scalar::Util' => 0,
#                 'Text::Glob' => 0,
#                 'PerlIO' => 0,
#                 'Sys::Mmap' => 0,
#               },
# },

{
  package MY;
  sub MY::postamble {
    my ($makemaker) = @_;
    return <<'HERE';

t/samp.locatedb: t/samp.zeros
	/usr/lib/locate/frcode -0 <t/samp.zeros >t/samp.locatedb
HERE
  }
}
