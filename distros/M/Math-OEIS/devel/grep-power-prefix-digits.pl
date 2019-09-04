#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde

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


# This is a simple grep for sequences of the form
#
#     a(n) = base * a(n-1) + digit
#
# so that a(n) written in "base" is its preceding a(n-1) and an extra low
# "digit".  Such digits might be negative, but the idea is that they are
# moderate in size, and preferably a finite set of them (though that of
# course is not be known just from OEIS sample values).
#
# Various simple forms like 2^n + (-1)^n show up here, but then more
# interesting ones like A061419 which is a(n) = ceil(3/2*a(n-1)) and the
# digit added is 0 or 1/2 for the ceil (per A205083).
#


use 5.004;
use strict;
use Encode ();
use Encode::Locale;
use PerlIO::encoding;;
use FindBin;
use List::Util 'sum';
use Math::BigRat;
use Math::OEIS::Names;
use Math::OEIS::Stripped;
use POSIX 'round';

# uncomment this to run the ### lines
# use Smart::Comments;

$PerlIO::encoding::fallback = Encode::PERLQQ();
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");
$|=1;

{
  my $fh = Math::OEIS::Stripped->fh;
 LINE: while (my $line = readline $fh) {
    my ($anum, $values) = Math::OEIS::Stripped->line_split_anum($line)
      or next;
    # $anum eq 'A061419' or next;

    my @values = Math::OEIS::Stripped->values_split($values)
      or next;
    ### @values

    while (@values && $values[0] == 0) {
      shift @values;
    }
    shift @values;
    shift @values;
    shift @values;
    @values >= 8 or next;
    next if grep {$_<=0} @values;
    ### @values

    my @ratios = map {$values[$_]/$values[$_-1]} 1 .. $#values;
    my $mean_ratio = sum(@ratios) / scalar(@ratios);
    ### $mean_ratio
    next unless $mean_ratio < 20;

    my $denominator = 6;
    my $s = $mean_ratio * $denominator;
    my $r = round($s);
    ### $s
    ### $r
    next if abs($s - $r) > .05;
    $r = Math::BigRat->new($r,$denominator);

    # my $numerator = $r->numerator;
    # $denominator = $r->denominator;
    my @steps;
    foreach my $i (1 .. $#values) {
      my $add = (Math::BigRat->new($values[$i])
                 - Math::BigRat->new($values[$i-1]) * $r)
        * $denominator;
      $add->is_int or next LINE;
      next LINE if $add < -5*$denominator || $add > 5*$denominator;
      push @steps, $add;
    }
    next unless grep {$_!=$steps[0]} @steps;

    foreach my $step(@steps) { $step /= $denominator; }

    $mean_ratio = sprintf '%.5f', $mean_ratio;
    print "$anum ",Math::OEIS::Names->anum_to_name($anum),"\n";
    print "  $r  $mean_ratio  ",join(', ',@steps),"\n";
  }
  exit 0;
}


