#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
plan tests => 7;

use lib 't','xt',              'devel/lib';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::LeastPrimitiveRoot;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------

{
  require Math::NumSeq::Totient;
  my $totient = Math::NumSeq::Totient->new;
  my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
  foreach (1 .. 100) {
    my ($modulus, $got_base) = $seq->next;
    my $totient = $totient->ith($modulus);
    my $order = multiplicative_order_by_search($got_base,$modulus);
    ok ($order, $totient, "order for modulus i=$modulus base=$got_base");

    my $want_least = least_primitive_root_by_search($modulus);
    ok ($got_base, $want_least, "modulus i=$modulus");
  }

  sub least_primitive_root_by_search {
    my ($modulus) = @_;
    my $target_order = $totient->ith($modulus);
    foreach my $base (2 .. $modulus-1) {
      if (multiplicative_order_by_search($base,$modulus) == $target_order) {
        return $base;
      }
    }
    return -123;
  }

sub multiplicative_order_by_search {
  my ($base, $modulus) = @_;
  if ($modulus < 2) { die "modulus $modulus" }
  if ($base < 2) { die "base $base" }
  my $power = $base;
  my $exponent = 1;
  while ($power != 1) {
    $power *= $base;
    $power %= $modulus;
    $exponent++;
    if ($exponent > $modulus) {
      # warn "oops, exponent past modulus base=$base modulus=$modulus";
      return -1;
    }
  }
  return $exponent;
}
}


#------------------------------------------------------------------------------
exit 0;
