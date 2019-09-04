#!/usr/bin/perl -w

# 0-Test-DistManifest.t -- run Test::DistManifest if available

# Copyright 2009, 2010, 2011 Kevin Ryde

# 0-Test-DistManifest.t is shared by several distributions.
#
# 0-Test-DistManifest.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-Test-DistManifest.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test::More;

# This is only an author test really and it only really does much in a
# working directory where newly added files will exist.  In a dist dir
# something would have to be badly wrong for the manifest to be off.

eval { require Test::DistManifest }
  or plan skip_all => "due to Test::DistManifest not available -- $@";

Test::DistManifest::manifest_ok();
exit 0;
