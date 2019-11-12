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
use Config;
use ExtUtils::MakeMaker;


my $MY_WITHOUT_XS = 0;
@ARGV = grep { /^MY_WITHOUT_XS/
                 ? do { $MY_WITHOUT_XS = 1; 0 }  # remember and remove
                 : 1 } @ARGV;

my $want_xs;
if ($MY_WITHOUT_XS) {
  print STDERR "XS skipped by request\n";
  $want_xs = 0;

} elsif (! $Config{'useperlio'}) {
  print STDERR "Config.pm useperlio is ",
    (defined $Config{'useperlio'} ? $Config{'useperlio'} : '[undef]'), "\n",
    "XS skipped since it is only useful with PerlIO.\n";
  $want_xs = 0;

} else {
  $want_xs = 1;
  print STDERR "XS enabled by default.
If you don't have a compiler or the .xs doesn't work or you don't want it
then forcibly disable with \"perl Makefile.PL MY_WITHOUT_XS=1\"
";
}

my %PREREQ_PM = ('Filter::Util::Call' => 0,
                 'Compress::Raw::Zlib' => 0,
                 ($want_xs ? ('PerlIO::gzip' => 0) : ()),
                );
my %TEST_REQUIRES = ('Test' => 0,
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

   # as of ExtUtils::MakeMaker 6.55_02 if you force XS then C is still
   # generated from scanned .xs files, so must force it too
   XS => ($want_xs ? { 'gunzip.xs' => 'gunzip.c' } : {}),
   C  => ($want_xs ? [ 'gunzip.c' ] : []),

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/filter-gunzip/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },
   },
  );
