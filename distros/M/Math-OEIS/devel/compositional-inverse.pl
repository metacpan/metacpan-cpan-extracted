#!/usr/bin/perl -w

# Copyright 2017, 2019 Kevin Ryde

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


# Grep the stripped file for pairs of sequences which as coefficients of
# generating functions (ordinary generating functions) are compositional
# inverses
#
#     g(h(x)) = h(g(x)) = x       coefficients mod 2
#

use 5.006;
use strict;
use List::Util 'min';
use Math::OEIS::Grep;
use Math::OEIS::Names;
use Math::OEIS::Stripped;

# uncomment this to run the ### lines
# use Smart::Comments;

$|=1;


#---------------
#     1,3
# 0  --->  1
#    <---
#      2
# 0 unchanged
#     
# 0->0,1,0,1
# 1->1,1,0,1
#
# GP-DEFINE  A285383_vector(n) = {
# GP-DEFINE    my(v=[0]);
# GP-DEFINE    while(#v<n,
# GP-DEFINE      v=concat(apply(x->if(x,[0,1],[1,1]), v));
# GP-DEFINE      v=concat(apply(x->if(x,[0,1],[1,1]), v)));
# GP-DEFINE    v[1..n];
# GP-DEFINE  }
# GP-DEFINE  A285383_samples = [0,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,1,0,1,1,1];
# GP-Test  A285383_vector(#A285383_samples) == A285383_samples
# GP-DEFINE  A285383(n) = {
# GP-DEFINE    while(n && n%4==0, n/=4);   \\ pairs 00
# GP-DEFINE    n%2;                        \\ low of pair
# GP-DEFINE  }
# GP-Test  vector(#A285383_samples,n,n--; A285383(n)) == A285383_samples

#---------------
# A036987 Fredholm-Rueppel sequence = Kempner-Mahler binary
#         subtract 1
# inverse periodic 0,1

#---------------
# some morphisms

#---------------


sub multiply_poly {
  my ($u,$v) = @_;
  my @ret;
  foreach my $i (0 .. min($#$u,$#$v)) {
    foreach my $j (0 .. $i) {
      $ret[$i] ^= $u->[$j] * $v->[$i-$j];
    }
  }
  return \@ret;
}
CHECK {
  # GP-Test  (Mod(1,2)*x+Mod(1,2)*x^3) * (Mod(1,2)*x+Mod(1,2)*x^4) == \
  # GP-Test    x^2 + x^4 + x^5 + x^7
  my $got = multiply_poly([0,1,0,1,0],[0,1,0,0,1]);
  ### $got
}

sub compositional_inverse {
  my ($p) = @_;
  ### p        : join('',@$p)

  $p->[0] == 0 || die;
  $p->[1] == 1 || die;
  my $power = $p;
  my @cancelled = @$p;
  my @inverse = (0,1);
  foreach my $i (2 .. $#$p) {
    $power = multiply_poly($power,$p);
    ### $i
    ### power    : join('',@$power)
    ### cancelled: join('',@cancelled)
    if ($cancelled[$i]) {
      $inverse[$i] = 1;
      foreach my $j (0 .. $#$p) { $cancelled[$j] ^= $power->[$j]; }
    } else {
      $inverse[$i] = 0;
    }
  }

  ### cancelled: join(',',@cancelled)
  ### inverse  : join(',',@inverse)
  foreach my $i (0 .. $#$p) {
    unless ($cancelled[$i]==($i==1)) {
      die "oops not cancelled at $i";
    }
  }
  return \@inverse;
}

sub vector_is_binary {
  my ($aref) = @_;
  foreach my $i (0 .. $#$aref) {
    unless ($aref->[$i] == 0 || $aref->[$i] == 1) {
      return 0;
    }
  }
  return 1;
}

sub try {
  my ($name,$aref) = @_;
  $name = join('',@{$aref}[0..20])."\n".$name;
  my $inverse = compositional_inverse($aref);
  Math::OEIS::Grep->search(array => $inverse,
                           name => $name,
                           values_min => 0, values_max => 1,
                           _EXPERIMENTAL_exact => 1,
                          );

  $inverse->[0] = 1;
  Math::OEIS::Grep->search(array => $inverse,
                           name => "plus1 $name",
                           values_min => 0, values_max => 1,
                           _EXPERIMENTAL_exact => 1,
                          );

  $inverse->[0] = 0;
  shift @$inverse;
  Math::OEIS::Grep->search(array => $inverse,
                           name => "unshift $name",
                           values_min => 0, values_max => 1,
                           _EXPERIMENTAL_exact => 1,
                          );
}

my $fh = Math::OEIS::Stripped->fh;
my $count = 0;
while (defined(my $line = readline $fh)) {
  my ($anum,$values_str) = Math::OEIS::Stripped->line_split_anum($line)
    or next;
  my @values = Math::OEIS::Stripped->values_split($values_str);
  next unless @values > 20;                 # minimum length
  next unless vector_is_binary(\@values);   # all 0,1
  $count++;
  my $name = $anum . ' ' . Math::OEIS::Names->anum_to_name($anum);
  # print "$anum $values_str\n";

  # next unless $anum eq 'A010060';  # Thue-Morse inverse A270803 sub 1

  # 0,1,... already
  if ($values[0] == 0 && $values[1] == 1) {
    try($name, \@values);
  }

  # 1,1,... subtract the first 1 so 0,1,...
  if ($values[0] == 1 && $values[1] == 1) {
    my @values = @values;
    $values[0] = 0;
    try("(sub 1) ".$name, \@values);
  }

  # 1,... shift up for extra initial 0 so 0,1,...
  if ($values[0] == 1) {
    my @values = (0,@values);
    try("(shift) ".$name, \@values);
  }
}
print "count $count\n";
exit 0;
