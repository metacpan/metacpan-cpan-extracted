#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 6;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::ChampernowneBinary;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 86;
  ok ($Math::NumSeq::ChampernowneBinary::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::ChampernowneBinary->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::ChampernowneBinary->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::ChampernowneBinary->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# values

{
  my @want = (1, 2,  4,5, 6,   9,11, 12,13, 15,16,17);
  my $hi = $want[-1];
  my $values_obj = Math::NumSeq::ChampernowneBinary->new (lo => 1,
                                                                    hi => $hi);
  my @got;
  while (my ($i, $value) = $values_obj->next) {
    if ($value <= $hi) {
      push @got, $value;
    } else {
      last;
    }
  }
  my $got = join(',',@got);
  my $want = join(',',@want);
  ok ($got, $want,
      'ChampernowneBinary 1 to 17 iterator');
}

#------------------------------------------------------------------------------
# pred

{
  my $hi = 5000;
  my $values_obj = Math::NumSeq::ChampernowneBinary->new (hi => $hi);
  my $good = 1;

  my $prev = -1;
  while (my ($i, $next) = $values_obj->next) {
    foreach my $n ($prev+1 .. $next-1) {
      if ($values_obj->pred($n)) {
        MyTestHelpers::diag("ChampernowneBinary pred() vs seq: $n pred yes, seq no");
        $good = 0;
      }
    }
    if (! $values_obj->pred($next)) {
      MyTestHelpers::diag("ChampernowneBinary pred() vs seq: $next pred no, seq yes");
      $good = 0;
    }
    $prev = $next;

    last if $next > $hi;
  }
  ok ($good, 1, "pred() to $hi");
}

exit 0;


