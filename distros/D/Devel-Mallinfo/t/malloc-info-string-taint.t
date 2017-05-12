#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Devel::Mallinfo;

my $test_count = (tests => 1)[1];
plan tests => $test_count;

my $have_malloc_info_string = Devel::Mallinfo->can('malloc_info_string');
if (! $have_malloc_info_string) {
  MyTestHelpers::diag ('malloc_info_string() not available');
  foreach (1 .. $test_count) {
    skip ('malloc_info_string() not available', 1, 1);
  }
  exit 0;
}

if (! eval { require Taint::Util; 1 }) {
  MyTestHelpers::diag ("Taint::Util not available -- ",$@);
  foreach (1 .. $test_count) {
    skip ('due to Taint::Util not available', 1, 1);
  }
  exit 0;
}

#-----------------------------------------------------------------------------
# malloc_info_string() untainted

my $str = Devel::Mallinfo::malloc_info_string(0);
my $got_taint = Taint::Util::tainted($str);
ok (! $got_taint, 1, "malloc_info_string() untainted");

exit 0;
