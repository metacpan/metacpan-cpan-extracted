#!/usr/bin/perl -w

# 0-Test-Synopsis.t -- run Test::Synopsis if available

# Copyright 2009, 2010, 2011 Kevin Ryde

# 0-Test-Synopsis.t is shared by several distributions.
#
# 0-Test-Synopsis.t is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# 0-Test-Synopsis.t is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test::More;

eval 'use Test::Synopsis; 1'
  or plan skip_all => "due to Test::Synopsis not available -- $@";

## no critic (ProhibitCallsToUndeclaredSubs)
all_synopsis_ok();

exit 0;
