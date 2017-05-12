#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014 Kevin Ryde

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
plan tests => 11;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::HofstadterFigure;

# uncomment this to run the ### lines
#use Smart::Comments;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::HofstadterFigure::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::HofstadterFigure->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::HofstadterFigure->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::HofstadterFigure->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# characteristic()

{
  my $seq = Math::NumSeq::HofstadterFigure->new;
  ok (! $seq->characteristic('smaller'), 1, 'characteristic(smaller)');
  ok ($seq->characteristic('integer'), 1, 'characteristic(integer)');

  ok ($seq->characteristic('increasing'), 1,
      'characteristic(increasing)');
  ok ($seq->characteristic('non_decreasing'), 1,
      'characteristic(non_decreasing)');
  ok ($seq->characteristic('increasing_from_i'), $seq->i_start,
      'characteristic(increasing_from_i)');
  ok ($seq->characteristic('non_decreasing_from_i'), $seq->i_start,
      'characteristic(non_decreasing_from_i)');
}


#------------------------------------------------------------------------------
# seq and first diffs

{
  my $bad = 0;
  my $max_diff = 0;

  foreach my $start (1 .. 30) {
    my $seq = Math::NumSeq::HofstadterFigure->new (start => $start);

    for (my $rewind = 0; $rewind < 2; $rewind++, $seq->rewind) {

      my @seen;
      if ($start > 0) {
        $seen[0] = 1;
      }
      my $prev_i = 0;
      my $prev_value;
      my $diff;

      foreach (1 .. 500) {
        my ($i, $value) = $seq->next;

        if ($i != $prev_i+1) {
          MyTestHelpers::diag("oops i=$i, prev_i=$prev_i");
          $bad++;
        }

        if ($value < 0) {
          MyTestHelpers::diag("oops negative value=$value");
          $bad++;
        }
        if ($seen[$value]) {
          MyTestHelpers::diag("start=$start value $value already seen");
          $bad++;
        }
        if ($value < 1100) {
          $seen[$value] = 1;
        }

        if (defined $prev_value) {
          $diff = $value - $prev_value;
          if ($seen[$diff]) {
            MyTestHelpers::diag("start=$start diff $diff at i=$i value=$value already seen");
            $bad++;
          }
          $seen[$diff] = 1;
        }

      $prev_i = $i;
        $prev_value = $value;
      }
      foreach my $i (0 .. $diff) {
        if (! $seen[$i]) {
          MyTestHelpers::diag("start=$start value or diff $i not seeny");
          $bad++;
        }
      }
      if ($diff > $max_diff) {
        $max_diff = $diff;
      }

    }
  }

  ok ($bad, 0);
  MyTestHelpers::diag("max_diff=$max_diff");
}

exit 0;


