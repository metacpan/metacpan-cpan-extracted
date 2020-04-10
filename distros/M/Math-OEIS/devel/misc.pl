#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

# This file is part of Math-OEIS.
#
# Math-OEIS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-OEIS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-OEIS.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use List::Util 'min';
use Math::OEIS::Grep;
use Math::OEIS::Names;
use Math::OEIS::Stripped;
use Math::BigInt try => 'GMP';
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  my $skip = 6;
  my @want_coeffs;

  # A293506  MinusNegA
  # recurrence 1,0,1,0,1
  # (but occurs also as a factor of a bigger charpoly)
  # found: A060961, A109543, A122115, A222122, A265070, A271970
  # index: A060961, A109543, A122115,          A265070, A271970
  # A222122 empirical
  #
  @want_coeffs = (reverse(1,0,1,0,1), -1);

  # A190872  G(k)
  # found: A147841, A190872
  @want_coeffs = (reverse(11,-9),  -1);

  my $fh = Math::OEIS::Stripped->fh;
  my $count = 0;
 LINE: while (defined(my $line = readline $fh)) {
    my ($anum,$values_str) = Math::OEIS::Stripped->line_split_anum($line)
      or next;
    if ($. % 1000 == 0) {
      print "$anum\r";
    }
    next unless length($values_str) >= 50; # char length, no short samples
    my @values = Math::OEIS::Stripped->values_split($values_str);
    next unless @values >= scalar(@want_coeffs);  # long enough

    # if ($anum eq 'A060961') {
    #   ### @values
    #   ### last: $values[-1]
    #   ### sum: $values[-2] + $values[-4] + $values[-6]
    #   ### last: $values[-2]
    #   ### sum $values[-3] + $values[-5] + $values[-7]
    # }

    my $last = $#values - scalar(@want_coeffs);
    my $start = min ($skip, $last);
    next LINE if $start < 0;
    foreach my $pos ($start .. $last) {
      my $total = 0;
      my $all_zeros = 1;
      foreach my $i (0 .. $#want_coeffs) {
        my $value = $values[$pos + $i];
        unless (ref $value) {
          $values[$pos + $i] = $value = Math::BigInt->new($value);
        }
        $total += $want_coeffs[$i] * $value;
        if ($value) { $all_zeros = 0; }
      }

      # if ($anum eq 'A060961') {
      #   ### at: "pos=$pos total $total"
      # }

      if ($total || $all_zeros) {
        next LINE;
      }
    }

    my $name = Math::OEIS::Names->anum_to_name($anum);
    print $anum,(defined $name ? " $name" : ""), "\n";
    print $values_str,"\n\n";
    $count++;
  }
  print "count $count\n";
  exit 0;
}
