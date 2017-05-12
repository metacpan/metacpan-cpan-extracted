#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014 Kevin Ryde

# This file is part of Devel-Mallinfo.
#
# Devel-Mallinfo is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Devel-Mallinfo is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use ExtUtils::MakeMaker;

# If WriteMakefile sees conftest.c file it'll add it to O_FILES, which we
# don't want.  In a clean dist conftest.c won't exist, but it can be left
# over if you're fiddling with multiple Makefile.PL runs and builds.
unlink ('conftest.c');

WriteMakefile
  (NAME         => 'Devel::Mallinfo',
   ABSTRACT     => 'Get mallinfo() malloc memory stats, and more.',
   VERSION_FROM => 'lib/Devel/Mallinfo.pm',
   PREREQ_PM    => {
                    'vars' => 0,

                    # for testing
                    'Test' => 0,
                    'lib' => 0,
                   },
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   # probably anything, dunno if can get a Test.pm going far enough back
   MIN_PERL_VERSION => '5',

   clean => { FILES =>
              "config.h"
              . " conftest.c conftest.i"
              . " conftest\$(OBJ_EXT) conftest\$(EXE_EXT) a.out" },
   H => [ 'config.h' ],

   # not sure mallinfo() does anything with Perl's malloc(), but try to
   # build Devel::Mallinfo at least ...
   PERL_MALLOC_OK => 1,

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/devel-mallinfo/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'] },

     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Scalar::Util' => 0,
                       'Test::Weaken' => 0,
                     },
       },
     },
   },
  );

#------------------------------------------------------------------------------
package MY;

sub postamble {
  my ($makemaker) = @_;
  return <<'HERE';

config.h: config.pl Makefile
	$(PERL) config.pl "$(MAKE)" "$(OBJ_EXT)" "$(EXE_EXT)"

# A reasonable "make" should already have a default rule for obj->exe, or at
# least for c->exe, but that's apparently not the case for dmake on msdos,
# and MakeMaker doesn't generate one, hence this rule for the config tests.
#
# This is only a phony target, generating either a.out or conftest.exe or
# whatever default output from $(LD).  Adding a "-o exename" doesn't work
# with microsoft cl.
#
# PERL_ARCHIVE is meant for a dynamic extension, which is what Mallinfo.xs
# will be, but not sure if it's correct in a plain .exe link.
#
conftest-link: conftest$(OBJ_EXT)
	$(LD) $(LDFLAGS) conftest$(OBJ_EXT) $(OTHERLDFLAGS) \
	  $(PERL_ARCHIVE) $(LDLOADLIBS) $(PERL_ARCHIVE_AFTER)

conftest-fallback-i:
	$(CCCMD) -E $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) conftest.c >conftest.i

HERE
}
