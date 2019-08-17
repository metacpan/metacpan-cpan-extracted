#!/usr/bin/perl -w

# 0-Test-ConsistentVersion.t -- run Test::ConsistentVersion if available

# Copyright 2011 Kevin Ryde

# 0-Test-ConsistentVersion.t is shared by several distributions.
#
# 0-Test-ConsistentVersion.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-Test-ConsistentVersion.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test::More;

eval { require Test::ConsistentVersion }
  or plan skip_all => "due to Test::ConsistentVersion not available -- $@";

Test::ConsistentVersion::check_consistent_versions
  (no_readme => 1, # no version number in my READMEs
   no_pod    => 1, # no version number in my docs, at the moment
  );

# ! -e 'README');

exit 0;
