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


# This is a grep for sequences which are entirely products of Jacobsthal numbers
#
#     A001045  0, 1, 1, 3, 5, 11, 21, 43, 85, 171, 341, 683, 1365, 2731

use 5.004;
use strict;
use Encode ();
use Encode::Locale;
use PerlIO::encoding;;
use FindBin;
use List::Util 'sum';
use Math::BigInt try => 'GMP';
use Math::OEIS::Names;
use Math::OEIS::Stripped;
use POSIX 'round';

# uncomment this to run the ### lines
# use Smart::Comments;

$PerlIO::encoding::fallback = Encode::PERLQQ();
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");
$|=1;

print "bigint decimals: ",Math::OEIS::Stripped::_IV_DECIMAL_DIGITS_MAX(),"\n";

sub J {
  my ($n) = @_;
  my $one = ($n < 50 ? 1 : Math::BigInt->new(1));
  return (($one << $n) - (-1)**$n ) / 3;
}
CHECK {
  foreach my $n (0 .. 6) { print J($n),", "; } print "\n";
  J(3) == 3 or die;
  J(4) == 5 or die;
  J(5) == 11 or die;
  ref J(60) or die "bignum";
}

my @J;
BEGIN {
  $J[0] = J(0);
}
sub is_product {
  my ($n) = @_;
  ### is_product(): "$n"
  $n = abs($n);
  if ($n == 0 || $n == 1) { return 1; }
  unless ($n & 1) {
    ### even ...
    return 0;
  }

  while ($J[-1] < $n) {
    my $i = scalar(@J);
    $J[$i] = J($i);
    ### extend: "$i is $J[$i] ".(ref $J[$i] // '')
  }

  foreach my $i (reverse 3 .. $#J) {
    # ### try: "i=$i J=$J[$i] rem ".($n % $J[$i])
    if ($n >= $J[$i]) {
      next if $n % $J[$i];
      ### recurse: $n / $J[$i]
      if (is_product ($n / $J[$i])) { return 1; }
    }
  }
  return 0;
}
CHECK {
  !is_product(2) or die;
  is_product(9) or die;
  is_product(33) or die;
}

my $prev_t = 0;
my $fh = Math::OEIS::Stripped->fh;
LINE: while (my $line = readline $fh) {
  my ($anum, $values) = Math::OEIS::Stripped->line_split_anum($line)
    or next;
  # $anum eq 'A071053' or next;
  # $anum eq 'A003846' or next;
  ### $anum

  {
    my $t = int(time()/3);
    if ($t != $prev_t) {
      print "$anum\r";
      # $prev_t = $t;
    }
  }

  my @values = Math::OEIS::Stripped->values_split($values)
    or next;
  ### @values
  ### refs: map {ref $_} @values

  foreach my $value (@values) {
    # if ($value > (1<<31)) {
    #   ref $value or die "$value";
    # }
    unless (is_product($value)) {
      next LINE;
    }
  }


  @values = grep {$_ != 0} @values;
  next unless @values;

  @values = map {abs} @values;
  next unless @values;

  @values = grep {$_ != 1} @values;
  next unless @values;

  print "$anum ",Math::OEIS::Names->anum_to_name($anum),"\n";
  print "  ",join(',',@values),"\n";
}
exit 0;
