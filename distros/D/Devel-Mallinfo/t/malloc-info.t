#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
BEGIN {
  plan tests => 1;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Devel::Mallinfo;

my $have_malloc_info = defined(&Devel::Mallinfo::malloc_info);
if (! $have_malloc_info) {
  MyTestHelpers::diag ('malloc_info() not available');
}


#-----------------------------------------------------------------------------
# malloc_info() basic run

if ($have_malloc_info) {
  Devel::Mallinfo::malloc_info(0,\*STDERR);
}
ok (1, 1, 'malloc_info() ran successfully');


exit 0;
