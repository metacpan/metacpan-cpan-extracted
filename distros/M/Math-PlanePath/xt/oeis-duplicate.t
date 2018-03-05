#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Check that OEIS A-number sequences implemented by PlanePath modules aren't
# already supplied by the core NumSeq.
#


use 5.004;
use strict;
use Test;
plan tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }


use Math::NumSeq::OEIS::Catalogue::Plugin::BuiltinTable;
use Math::NumSeq::OEIS::Catalogue::Plugin::PlanePath;

my %builtin_anums;
foreach my $info (@{Math::NumSeq::OEIS::Catalogue::Plugin::BuiltinTable::info_arrayref()}) {
  $builtin_anums{$info->{'anum'}} = $info;
}

my $good = 1;
my $count = 0;
foreach my $info (@{Math::NumSeq::OEIS::Catalogue::Plugin::PlanePath::info_arrayref()}) {
  my $anum = $info->{'anum'};
  if ($builtin_anums{$anum}) {
    MyTestHelpers::diag ("$anum already a NumSeq builtin");
    $good = 0;
  }
  $count++;
}

ok ($good);
MyTestHelpers::diag ("total $count PlanePath A-numbers");

exit 0;
