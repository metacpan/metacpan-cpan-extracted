#!/usr/bin/perl -w

# Copyright 2012, 2013, 2016, 2018, 2019, 2021 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
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
use Math::BaseCnv 'cnv';
use Math::BigInt try => 'GMP';   # for bignums in reverse-add steps
use Test;
plan tests => 27;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments '###';

use Math::PlanePath::ComplexMinus;
use Math::PlanePath::Diagonals;

my $path = Math::PlanePath::ComplexMinus->new;

# Cf catalogued NumSeq sequences
# A318438 X coordinate
# A318439 Y coordinate
# A318479 norm


#------------------------------------------------------------------------------
# A340566 - permutation N by diagonals +/-
#   in binary

# A001057 alternating pos and neg 0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5
sub A001057 {
  my ($n) = @_;
  return ($n&1 ? ($n>>1)+1 : -($n>>1));
}
MyOEIS::compare_values
  (anum => 'A001057',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, A001057($n);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A340566',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diag = Math::PlanePath::Diagonals->new;
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       $x = A001057($x);
       $y = A001057($y);
       my $n = $path->xy_to_n($x,$y);
       push @got, cnv($n,10,2);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A073791 - X axis X sorted by N, being base conversion 4 to -4
#   X axis points (+ and -) in the order visited by the path

MyOEIS::compare_values
  (anum => 'A073791',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       if ($y==0) { push @got, $x; }
     }
     return \@got;
   });

# A320283 - Y axis Y sorted by N
#   Y axis points (+ and -) in the order visited by the path
MyOEIS::compare_values
  (anum => 'A320283',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       if ($x==0) { push @got, $y; }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A256441    N on negative X axis, X<=0

MyOEIS::compare_values
  (anum => 'A256441',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       push @got, $path->xy_to_n (-$x,0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A066321    N on X axis, being the base i-1 positive reals
MyOEIS::compare_values
  (anum => 'A066321',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       push @got, $path->xy_to_n ($x,0);
     }
     return \@got;
   });
# and 2*A066321 on North-West diagonal by one expansion
MyOEIS::compare_values
  (anum => q{A066321},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $path->xy_to_n(-$i,$i) / 2;
     }
     return \@got;
   });

# A271472 - and in binary
MyOEIS::compare_values
  (anum => 'A271472',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       push @got, sprintf '%b', $path->xy_to_n ($x,0);
     }
     return \@got;
   });

# A066323 - N on X axis, count 1 bits
MyOEIS::compare_values
  (anum => 'A066323',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $x = 1; @got < $count; $x++) {
       my $n = $path->xy_to_n ($x,0);
       push @got, count_1_bits($n);
     }
     return \@got;
   });
sub count_1_bits {
  my ($n) = @_;
  my $count = 0;
  while ($n) {
    $count += ($n & 1);
    $n >>= 1;
  }
  return $count;
}


#------------------------------------------------------------------------------
sub is_string_palindrome {
  my ($str) = @_;
  return $str eq reverse($str);
}
ok (!! is_string_palindrome('acbca'), 1);
ok (!  is_string_palindrome('aab'), 1);

sub is_binary_palindrome {
  my ($n) = @_;
  return is_string_palindrome(sprintf '%b', $n);
}
ok (!! is_binary_palindrome(oct('0b1011101')), 1);
ok (!  is_binary_palindrome(oct('0b1011')), 1);

sub binary_reverse {
  my ($n) = @_;
  $n = substr(Math::BigInt->new($n)->as_bin, 2);
  $n = reverse $n;
  return Math::BigInt->from_bin($n);
}
### rev: binary_reverse(13).""
ok (binary_reverse(13) == 11, 1);

sub reverse_add_step {
  my ($n) = @_;
  my ($x1,$y1) = $path->n_to_xy ($n);
  my ($x2,$y2) = $path->n_to_xy (binary_reverse($n));
  return $path->xy_to_n ($x1+$x2, $y1+$y2);
}
sub reverse_add_palindrome_steps {
  my ($n) = @_;
  ### reverse_add_palindrome_steps(): "$n"
  my %seen;
  my $count = 0;
  my $limit = ($n*0+1) << 50;
  while ($n < $limit && !$seen{$n}++) {
    ### at: "$n ".$n->as_bin
    if (is_binary_palindrome($n)) {
      ### palindrome, count: $count
      return $count;
    }
    $n = reverse_add_step($n);
    $count++;
  }
  return -1;
}

sub reverse_subtract_step {
  my ($n, $order) = @_;
  my ($x1,$y1) = $path->n_to_xy ($n);
  my ($x2,$y2) = $path->n_to_xy (binary_reverse($n));
  if ($order) {
    ($x1,$y1, $x2,$y2) = ($x2,$y2, $x1,$y1);
  }
  return $path->xy_to_n ($x1-$x2, $y1-$y2);
}
sub reverse_subtract_palindrome_steps {
  my ($n, $order) = @_;
  ### reverse_subtract_palindrome_steps(): "$n"
  my %seen;
  my $count = 0;
  my $limit = ($n*0+1) << 50;
  while ($n < $limit && !$seen{$n}++) {
    ### at: "$n ".$n->as_bin
    if ($n==0) {
      ### zero, count: $count
      return $count;
    }
    $n = reverse_subtract_step($n,$order);
    $count++;
  }
  return -1;
}

#------------------------------------------------------------------------------
# A011658 - repeat 0,0,0,1,1 is turn NotStraight
#               N= 1 2 3 4 5 ...

MyOEIS::compare_values
  (anum => 'A011658',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new
       (planepath => 'ComplexMinus,realpart=2',
        turn_type => 'NotStraight');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });
{
  my @want = (1,0,0,0,1);
  my $seq = Math::NumSeq::PlanePathTurn->new
    (planepath => 'ComplexMinus,realpart=2',
     turn_type => 'NotStraight');
  for (1 .. 10_000) {
    my ($i,$value) = $seq->next;
    $value == $want[$i%5] or die "oops $i";
  }
  ok(1,1, 'Turn repeating');
}

#------------------------------------------------------------------------------
# A193306 reverse-subtract steps to 0 (plain-rev) in base i-1
# A193307 reverse-subtract steps to 0 (rev-plain) in base i-1

MyOEIS::compare_values
  (anum => 'A193306',
   max_count => 30,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = Math::BigInt->new(0); @got < $count; $n++) {
       push @got, reverse_subtract_palindrome_steps($n, 0);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A193307',
   max_count => 30,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = Math::BigInt->new(0); @got < $count; $n++) {
       push @got, reverse_subtract_palindrome_steps($n, 1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A193241 reverse-add trajectory of binary 10110, in binary
MyOEIS::compare_values
  (anum => 'A193241',
   func => sub {
     my ($count) = @_;
     my @got;
     my $n = Math::BigInt->new(20);
     while (@got < $count) {
       push @got, substr($n->as_bin, 2);
       $n = reverse_add_step($n);
     }
     return \@got;
   });

# A193240 reverse-add trajectory of binary 110, in binary
MyOEIS::compare_values
  (anum => 'A193240',
   func => sub {
     my ($count) = @_;
     my @got;
     my $n = Math::BigInt->new(6);
     while (@got < $count) {
       push @got, substr($n->as_bin, 2);
       $n = reverse_add_step($n);
     }
     return \@got;
   });

# A193239 reverse-add steps to palindrome
MyOEIS::compare_values
  (anum => 'A193239',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = Math::BigInt->new(0); @got < $count; $n++) {
       push @got, reverse_add_palindrome_steps($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A137426 - dX/2 at N=2^(k+2)-1, for k>=0

MyOEIS::compare_values
  (anum => 'A137426',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my ($dx,$dy) = $path->n_to_dxdy (Math::BigInt->new(2)**($k+2) - 1);
       push @got, $dx/2;
     }
     return \@got;
   });

# A137426 - dY at N=2^k-1, for k>=0

MyOEIS::compare_values
  (anum => 'A137426',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my ($dx,$dy) = $path->n_to_dxdy (Math::BigInt->new(2)**$k - 1);
       push @got, $dy;
     }
     return \@got;
   });

# GP-Test  my(k=0); 2^k-1 == 0
# GP-Test  my(k=1); 2^k-1 == 1
# GP-Test  my(k=2); 2^k-1 == 3


#------------------------------------------------------------------------------
# A052537 length A,B or C
# A003476 total boundary length / 2
# A203175 boundary length

MyOEIS::compare_values
  (anum => 'A203175',
   name => 'boundary length',
   func => sub {
     my ($count) = @_;
     my @got = (1,1,2);
     my $a = Math::BigInt->new(2);
     my $b = Math::BigInt->new(2);
     my $c = Math::BigInt->new(0);
     while (@got < $count) {
       push @got, ($a+$b+$c);
       ($a,$b,$c) = abc_step($a,$b,$c);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A003476',
   name => 'boundary length / 2',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $a = Math::BigInt->new(2);
     my $b = Math::BigInt->new(2);
     my $c = Math::BigInt->new(0);
     while (@got < $count) {
       push @got, ($a+$b+$c)/2;
       ($a,$b,$c) = abc_step($a,$b,$c);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A052537',
   func => sub {
     my ($count) = @_;
     my @got = (1,0);
     for (my $i = 0; @got < $count; $i++) {
       my ($a,$b,$c) = abc_by_pow($i);
       push @got, $c;
     }
     return \@got;
   });

sub abc_step {
  my ($a,$b,$c) = @_;
  return ($a + 2*$c,
          $a,
          $b);
}
sub abc_by_pow {
  my ($k) = @_;

  my $zero = $k*0;
  my $r = 1;
  my $a = $zero + 2*$r;
  my $b = $zero + 2;
  my $c = $zero + 2*(1-$r);

  foreach (1 .. $k) {
    ($a,$b,$c) = ((2*$r-1)*$a       + 0  + 2*$r*$c,
                  ($r*$r-2*$r+2)*$a + 0 + ($r-1)*($r-1)*$c,
                  0                 + $b);
  }
  return ($a,$b,$c);
}

#------------------------------------------------------------------------------
# A066322 - N on X axis, diffs at 16k+3,16k+4

MyOEIS::compare_values
  (anum => 'A066322',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       my $x = 16*$i+3;
       my $x_next = 16*$i+4;
       my $n = $path->xy_to_n ($x,0);
       my $n_next = $path->xy_to_n ($x_next,0);
       push @got, $n_next - $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
