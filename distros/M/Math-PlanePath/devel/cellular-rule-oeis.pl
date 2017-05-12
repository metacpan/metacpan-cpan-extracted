#!/usr/bin/perl -w

# Copyright 2012, 2015 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use HTML::Entities::Interpolate;
use List::Util;
use URI::Escape;
use Tie::IxHash;
use Math::BigInt;
use Math::PlanePath::CellularRule;

# uncomment this to run the ### lines
#use Smart::Comments;

{
  # greps
  my %done;
  tie %done, 'Tie::IxHash';
  foreach my $rule (0 .. 255) {
    my $path = Math::PlanePath::CellularRule->new(rule=>$rule);

    my @values;

    # {
    #   # 0/1 cells
    # Y01: foreach my $y (0 .. 10) {
    #     foreach my $x (-$y .. $y) {
    #       if (defined ($path->xy_to_n($x,$y))) {
    #         push @values, 1;
    #       } else {
    #         push @values, 0;
    #       }
    #       last Y01 if (@values > 100);
    #     }
    #   }
    # }

    {
      # bignum rows
      my $base = 10;  # 2 or 10
    Y01: foreach my $y (0 .. 20) {
        my $n = '';
        foreach my $x (-$y .. $y) {
          $n .= defined $path->xy_to_n($x,$y) ? '1' : '0';
        }
        $n =~ s/^0+//;
        if ($n eq '') { $n = 0; }
        if ($base == 10) {
          Math::BigInt->new("0b$n");
        }
        push @values, $n;
      }
    }

    my $values = join(',',@values);
    $done{$values} .= ",$rule";
  }
  foreach my $values (keys %done) {
    my $name = $done{$values};
    $name =~ s/^,//;
    $name = "rule=".$name;

    print "$name\n";
    print "values $values\n";
    my @values = split /,/, $values;
    require Math::OEIS::Grep;
    Math::OEIS::Grep->search(array => \@values,
                             name => $name,
                             verbose => 0,
                            );
  }
  exit 0;
}
