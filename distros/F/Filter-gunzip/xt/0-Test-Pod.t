#!/usr/bin/perl -w

# 0-Test-Pod.t -- run Test::Pod if available

# Copyright 2009, 2010, 2011 Kevin Ryde

# 0-Test-Pod.t is shared by several distributions.
#
# 0-Test-Pod.t is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# 0-Test-Pod.t is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test::More;

# all_pod_files_ok() is new in Test::Pod 1.00
#
eval 'use Test::Pod 1.00; 1'
  or plan skip_all => "due to Test::Pod 1.00 not available -- $@";

Test::Pod::all_pod_files_ok();
exit 0;
