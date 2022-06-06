#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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
plan tests => 23;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Pell;

# uncomment this to run the ### lines
# use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 75;
  ok ($Math::NumSeq::Pell::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Pell->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Pell->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Pell->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# negative ith()

{
  my $seq = Math::NumSeq::Pell->new;

  ok($seq->ith(1),    1);
  ok($seq->ith(0),    0);
  ok($seq->ith(-1),   1);  # so   1 + 2*0  == 1
  ok($seq->ith(-2),  -2);  # so  -2 + 2*1  == 0
  ok($seq->ith(-3),   5);  # so   5 + 2*-2 == 1
  ok($seq->ith(-4), -12);  # so -12 + 2*5  == -2


  my $i = 3;
  my $f1 = $seq->ith($i+2);
  my $f0 = $seq->ith($i+1);
  for ( ; $i > -10; $i--) {
    my $f = $seq->ith($i);

    # expect $f + 2*$f0 == $f1
    # per   P[i] + 2*P[i+1] == P[i+2]
    # MyTestHelpers::diag ("i=$i  f=$f f0=$f0 f1=$f1");
    
    my $got = $f + 2*$f0;
    ok ($got, $f1, "i=$i  f=$f f0=$f0 f1=$f1   $f+2*$f0=$got != f1");
    $f1 = $f0;
    $f0 = $f;
  }
}

#------------------------------------------------------------------------------
exit 0;
