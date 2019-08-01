#!/usr/bin/perl -w

# Copyright 2014, 2016 Kevin Ryde

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
use List::Util 'max';

use Test;
plan tests => 104;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::FibonacciRepresentations;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 73;
  ok ($Math::NumSeq::FibonacciRepresentations::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::FibonacciRepresentations->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::FibonacciRepresentations->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::FibonacciRepresentations->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Stern diatomic = Fibonacci diatomic at Zeck even 1s positions
# as per Marjorie Bicknell-Johnson

require Math::NumSeq::Fibbinary;
my $fibbinary = Math::NumSeq::Fibbinary->new;

# is_zeck_even_1s_positions($n) returns true if $n in Zeckendorf form has
# its 1 bits at even positions only, so 10101010 or 100010 etc.
#
sub is_zeck_even_1s_positions {
  my ($n) = @_;
  my $f = $fibbinary->ith($n);
  ### is_zeck_even_1s_positions(): sprintf "n=%d   f=%b", $n, $f
  while ($f) {
    if ($f & 1) {
      ### no ...
      return 0;
    }
    $f >>= 2;
  }
  ### yes ...
  return 1;
}

# is_zeck_even_1s_positions($n) returns true if $n in Zeckendorf form has
# its 1 bits at odd positions only, so 10101010 or 100010 etc.
#
sub is_zeck_odd_1s_positions {
  my ($n) = @_;
  my $f = $fibbinary->ith($n);
  ### is_zeck_even_1s_positions(): sprintf "n=%d   f=%b", $n, $f
  while ($f) {
    if ($f & 2) {
      ### no ...
      return 0;
    }
    $f >>= 2;
  }
  ### yes ...
  return 1;
}

{
  require Math::NumSeq::SternDiatomic;
  my $seq = Math::NumSeq::FibonacciRepresentations->new;
  my $stern = Math::NumSeq::SternDiatomic->new;
  $stern->next;

  foreach my $func (\&is_zeck_even_1s_positions,
                    # \&is_zeck_odd_1s_positions,
                   ) {
    foreach my $i (1 .. 100) {
      my ($stern_i,$stern_value) = $stern->next;
      my ($i,$value);
      do {
        ($i,$value) = $seq->next;
      } until (&$func($i));

      ### at: sprintf("i=$i f=%b    $value $stern_value", $fibbinary->ith($i))
      ok($value, $stern_value);
    }
  }
}


#------------------------------------------------------------------------------
exit 0;
