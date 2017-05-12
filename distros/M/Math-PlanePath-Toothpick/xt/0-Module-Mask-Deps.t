#!/usr/bin/perl -w

# 0-Module-Mask-Deps.t -- run Test::Pod if available

# Copyright 2010 Kevin Ryde

# 0-Module-Mask-Deps.t is shared by several distributions.
#
# 0-Module-Mask-Deps.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-Module-Mask-Deps.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More;

# 0.04 for sub-package deps, maybe
eval 'use Module::Mask::Deps 0.04; 1'
  or plan skip_all => "due to Module::Mask::Deps 0.04 not available -- $@";

if (defined $ENV{'PERL_HARNESS_SWITCHES'}) {
  $ENV{'PERL_HARNESS_SWITCHES'} .= ' -MModule::Mask::Deps';
} else {
  $ENV{'PERL_HARNESS_SWITCHES'} = '-MModule::Mask::Deps';
}

diag "Test with Module::Mask::Deps";
exec 'make', 'test';
die "Cannot exec \"make test\" -- $!";
exit 1;
