#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2018, 2019, 2020 Kevin Ryde

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


# A168022 Non-composite numbers in the eastern ray of the Ulam spiral as oriented on the March 1964 cover of Scientific American.
# A168023 Non-composite numbers in the northern ray of the Ulam spiral as oriented on the March 1964 cover of Scientific American.
# A168024 Non-composite numbers in the northwestern ray of the Ulam spiral as oriented on the March 1964 cover of Scientific American.
# A168025 Non-composite numbers in the western ray of the Ulam spiral as oriented on the March 1964 cover of Scientific American.
# A168026 Non-composite numbers in the southwestern ray of the Ulam spiral as oriented on the March 1964 cover of Scientific American.
# A168027 Non-composite numbers in the southern ray of the Ulam spiral as oriented on the March 1964 cover of Scientific American.

# A217014 Permutation of natural numbers arising from applying the walk of a square spiral (e.g. A214526) to the data of triangular horizontal-last spiral (defined in A214226).

# A053823 Product of primes in n-th shell of prime spiral.
# A053997 Sum of primes in n-th shell of prime spiral.
# A053998 Smallest prime in n-th shell of prime spiral.
# A004652 maybe?

use 5.004;
use strict;
use Carp 'croak';
use Math::BigInt;
use Math::NumSeq::AllDigits;
use Math::NumSeq::AlmostPrimes;
use Math::NumSeq::PlanePathTurn;
use Math::Prime::XS 'is_prime';
use POSIX 'ceil';
use Test;
plan tests => 105;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use List::Util 'min','max','sum';
use Math::PlanePath::SquareSpiral;

# uncomment this to run the ### lines
# use Smart::Comments;


my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);

my @dir8_to_dx = (1,1, 0,-1, -1,-1, 0,1);
my @dir8_to_dy = (0,1, 1,1,  0,-1, -1,-1);

my $path = Math::PlanePath::SquareSpiral->new;  # n_start=1
my $path_n_start_0 = Math::PlanePath::SquareSpiral->new (n_start => 0);
ok ($path->n_start, 1);
ok ($path_n_start_0->n_start, 0);

# return 1,2,3,4
sub path_n_dir4_1 {
  my ($path, $n) = @_;
  my ($x,$y) = $path->n_to_xy($n);
  my ($next_x,$next_y) = $path->n_to_xy($n+1);
  return dxdy_to_dir4_1 ($next_x - $x,
                         $next_y - $y);
}
# return 1,2,3,4, with Y reckoned increasing upwards
sub dxdy_to_dir4_1 {
  my ($dx, $dy) = @_;
  if ($dx > 0) { return 1; }  # east
  if ($dx < 0) { return 3; }  # west
  if ($dy > 0) { return 2; }  # north
  if ($dy < 0) { return 4; }  # south
}

# GP-DEFINE  read("my-oeis.gp");



#------------------------------------------------------------------------------
# A320281 -- N values in pattern 4,5,5 on positive X axis

MyOEIS::compare_values
  (anum => 'A320281',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       my $n = $path_n_start_0->xy_to_n ($x, 0);
       push @got, ceil($n*2/3);
     }
     return \@got;
   });


# A143978 -- N values in pattern 4,5,5 on X=Y diagonal both ways
MyOEIS::compare_values
  (anum => 'A143978',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 1; @got < $count; $x++) {
       my $n = $path_n_start_0->xy_to_n ($x, $x);
       push @got, int($n*2/3);
       @got < $count or next;
       $n = $path_n_start_0->xy_to_n (-$x, -$x);
       push @got, int($n*2/3);
     }
     return \@got;
   });

# A301696 -- N values in pattern 4,5,5 on X=-Y diagonal both ways
MyOEIS::compare_values
  (anum => 'A301696',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       my $n = $path->xy_to_n ($x, -$x);
       push @got, ceil($n*2/3);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A054567 -- N values on negative X axis, n_start=1
MyOEIS::compare_values
  (anum => 'A054567',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       my $n = $path->xy_to_n (-$x, 0);
       push @got, $n;
     }
     return \@got;
   });

# A317186 X axis positive and negative, n_start=1
MyOEIS::compare_values
  (anum => 'A317186',
   func => sub {
     my ($count) = @_;
     my @got;
     my $x = 0;
     for (;;) {
       last unless @got < $count;
       push @got, $path->xy_to_n(-$x, 0);
       $x++;
       last unless @got < $count;
       push @got, $path->xy_to_n($x, 0);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A242601 -- X or Y of the turns

# A242601  0, 0, 1, 1, -1, -1, 2, 2, -2, -2
# 1,1,-1,-1,2,2,-2,-2,3,3,-3,-3,4,4,-4,-4,5,5,-5,-5,6,6,-6,-6
# A242601  Y of turns
# 0,1,1,-1,-1,2,2,-2,-2,3,3,-3,-3,4,4,-4,-4,5,5,-5,-5,6,6,-6,-6,7,7,-7,-7

# http://oeis.org/plot2a?name1=A242601&name2=A242601&tform1=untransformed&tform2=untransformed&shift=1&radiop1=xy&drawpoints=true&drawlines=true

# GP-DEFINE  A242601(n) = floor((n+2)/4)*(-1)^floor((n+2)/2)
# vector(20,n,n--; A242601(n))
# my(l=List([])); \
# for(n=0,10,listput(l,A242601(n+1));listput(l,A242601(n))); \
# Vec(l)
# not in OEIS: 0,0, 1,0, 1,1, -1,1, -1,-1, 2,-1, 2,2, -2,2, -2,-2, 3,-2, 3,3
# or transposed
# not in OEIS: 0,0, 0,1, 1,1, 1,-1, -1,-1, -1,2, 2,2, 2,-2, -2,-2, -2,3, 3,3
# only various absolute values

# my(x=vector(20,n,n--; A242601(n+1)), \
#    y=vector(20,n,n--; A242601(n))); \
# plothraw(x,y,1)

# A242601  X of turn corner
MyOEIS::compare_values
  (anum => 'A242601',
   func => sub {
     my ($count) = @_;
     my @got = (0,0);
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'SquareSpiral',
                                                 turn_type => 'Left');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value) {
         my ($x,$y) = $path->n_to_xy ($i);
         push @got, $x;
       }
     }
     return \@got;
   });

# A242601  Y of turn corner
MyOEIS::compare_values
  (anum => 'A242601',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'SquareSpiral',
                                                 turn_type => 'Left');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value) {
         my ($x,$y) = $path->n_to_xy ($i);
         push @got, $y;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A336336 -- squared distances (norms), all points
#
# cf A335298 norms of corner points in spread-out spiral, as if 2 arms

MyOEIS::compare_values
  (anum => 'A336336',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, $x*$x + $y*$y;
     }
     return \@got;
   });

# GP-DEFINE  A336336(n) = {
# GP-DEFINE    n>=1 || error();
# GP-DEFINE    n--; my(m=sqrtint(n),k=ceil(m/2));
# GP-DEFINE    \\ n -= 4*k^2;
# GP-DEFINE    \\ k^2 + if(n<0, if(abs(n)>m, (abs(n)-3*k)^2,
# GP-DEFINE    \\                             (abs(n)-k)^2),
# GP-DEFINE    \\               if(abs(n)>m,  (abs(n)-3*k)^2,
# GP-DEFINE    \\                             (abs(n)-k)^2));
# GP-DEFINE    \\ k^2 + if(abs(n)>m,  (abs(n)-3*k)^2,
# GP-DEFINE    \\                     (abs(n)-k)^2);
# GP-DEFINE    n=abs(n-4*k^2);
# GP-DEFINE    k^2 + (n-if(n>m,3,1)*k)^2;
# GP-DEFINE  }
# GP-Test-Last  vector(1024,n, A336336(n)) == \
# GP-Test-Last  vector(1024,n, X(n)^2 + Y(n)^2)
#
# GP-Test  my(v=OEIS_samples("A336336")); vector(#v,n, A336336(n)) == v  /* OFFSET=1 */
# GP-Test  my(g=OEIS_bfile_gf("A336336")); g==x*Polrev(vector(poldegree(g),n, A336336(n)))
# poldegree(OEIS_bfile_gf("A336336"))


#---
# MyOEIS::compare_values
#   (anum => 'A336336',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'SquareSpiral',
#                                                  turn_type => 'Left');
#      for (my $n = $path->n_start; @got < $count; $n++) {
#        if ($seq->ith($n)) {
#          my ($x,$y) = $path->n_to_xy ($n);
#          push @got, $x*$x + $y*$y;
#        }
#      }
#      return \@got;
#    });

# at left turns
# not in OEIS: 1,2,2,2,5,8,8,8,13,18,18,18,25,32,32,32,41,50,50,50,61,72,72,72,85,98,98,98,113,128,128,128,145,162,162,162,181,200,200,200,221,242,242,242,265,288,288,288,313,338,338
# Hugo Pfoertner notes the values without duplications are ceiling(n^2/2) = A000982

# vector(20,n, A242601(n)^2 + A242601(n+1)^2)
# vector(20,n, A242601(2*n)^2 + A242601(2*n+1)^2)

# X(n) = sum(i=1,n, if(i%2==0,i));
# Y(n) = sum(i=1,n, if(i%2==1,i));

# Vec((1+x^8)/((1-x)*(1-x^4)) + O(x^30))  \\ 1,1,1,1, 2,2,2,2, 4,4,4,4,
# vector(20,n,n--; A127365(n))
# A127365(n)^2 + A122461(n)^2
# vector(10,n, X(n))
# vector(10,n, Y(n))
# vector(10,n, X(n)^2 + Y(n)^2)
# vector(10,n, norm(Z(n)))

# Z(n) = sum(i=1,n, i*I^i);
# vector(30,n, real(Z(n)))     \\ A122461
# vector(30,n, imag(Z(n)))     \\ A127365
# OEIS_samples("A127365")
# vector(30,n,n--; -imag(Z(n)))

# spread corners norms A335298
# 0, 1, 5, 8,8, 13, 25, 32,32, 41, 61, 72,72, 85, 113, 128,128, 145, 181, 200,200, 221, 265, 288,288, 313, 365, 392,
#                392, 421, 481, 512, 512, 545, 613, 648, 648, 685, 761, 800,
#                800, 841, 925, 968, 968, 1013, 1105, 1152, 1152, 1201, 1301,
#                1352, 1352, 1405, 1513


#------------------------------------------------------------------------------
# A136626 -- count surrounding primes
# OFFSET=0 given, but values are for starting 1

{
  # example surrounding n=13 given in A136626 and A136627

  # math-image --path=SquareSpiral --all --output=numbers_dash --size=60x20
  #
  # 65-64-63-62-61-60-59-58-57 90
  #  |                       |  |
  # 66 37-36-35-34-33-32-31 56 89
  #  |  |                 |  |  |
  # 67 38 17-16-15-14-13 30 55 88
  #  |  |  |           |  |  |  |
  # 68 39 18  5--4--3 12 29 54 87
  #  |  |  |  |     |  |  |  |  |
  # 69 40 19  6  1--2 11 28 53 86
  #  |  |  |  |        |  |  |  |
  # 70 41 20  7--8--9-10 27 52 85
  #  |  |  |              |  |  |
  # 71 42 21-22-23-24-25-26 51 84
  #  |  |                    |  |
  # 72 43-44-45-46-47-48-49-50 83
  #  |                          |
  # 73-74-75-76-77-78-79-80-81-82
  #
  # GP-Test  /* around n=32 */ \
  # GP-Test  select(isprime,[14,13,30,31,58,59,60,33]) == [13, 31, 59]

  # around n=13
  my @want = (3, 12, 29, 30, 31, 32, 33, 14);
  my $n = 13;
  my ($x,$y) = $path->n_to_xy ($n);
  my $total = 0;
  foreach my $i (0 .. 7) {
    my $dir = ($i + 5)%8;  # start South-West dir=5
    my $sn = $path->xy_to_n ($x+$dir8_to_dx[$dir], $y+$dir8_to_dy[$dir]);
    ok ($sn, $want[$i]);
  }
}

MyOEIS::compare_values
  (anum => q{A136626},
   func => sub {
     my ($count) = @_;
     my $verbose = 0;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       if ($verbose) { print "n=$n  "; }
       my ($x,$y) = $path->n_to_xy ($n);
       my $total = 0;
       foreach my $dir (0 .. 7) {
         my $sn = $path->xy_to_n ($x+$dir8_to_dx[$dir], $y+$dir8_to_dy[$dir]);
         if (is_prime($sn)) {
           if ($verbose) { print " $sn"; }
           $total++;
         }
       }
       if ($verbose) { print "   total $total\n"; }
       push @got, $total;
     }
     return \@got;
   });

# A136627 -- count self and surrounding primes
MyOEIS::compare_values
  (anum => q{A136627},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       my $total = is_prime($n) ? 1 : 0;
       foreach my $dir (0 .. 7) {
         my $sn = $path->xy_to_n ($x+$dir8_to_dx[$dir], $y+$dir8_to_dy[$dir]);
         if (is_prime($sn)) {
           $total++;
         }
       }
       push @got, $total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A080037 -- N positions of straight ahead, and also 2

# 68 39 18  5--4--3 12 29 54 87
#  |  |  |  |     |  |  |  |  |
# 69 40 19  6  1--2 11 28 53 86
#  |  |  |  |        |  |  |  |
# 70 41 20  7--8--9-10 27 52 85

MyOEIS::compare_values
  (anum => 'A080037',
   func => sub {
     my ($count) = @_;
     my @got = (2);
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'SquareSpiral',
                                                 turn_type => 'Straight');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value) { push @got, $i; }
     }
     return \@got;
   });

sub A080037 {
  my ($n) = @_;
  return ($n==0 ? 2 : $n + int(sqrt(4*$n-3)) + 2);
}
MyOEIS::compare_values
  (anum => q{A080037},
   name => 'A080037 vs func',
   func => sub {
     my ($count) = @_;
     return [ map {A080037($_)} 0 .. $count-1 ];
   });


#------------------------------------------------------------------------------
# A033638 -- N positions of the turns
# quarter-squares + 1

MyOEIS::compare_values
  (anum => 'A033638',
   max_value => 100_000,     # bit slow by a naive search here
   func => sub {
     my ($count) = @_;
     my @got = (1,1);
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'SquareSpiral',
                                                 turn_type => 'LSR');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value != 0) {
         push @got, $i;
       }
     }
     return \@got;
   });

sub A033638 {
  my ($n) = @_;
  return ( (7+(-1)**$n)/2 + $n*$n )/4;  # formula in A033638
}
MyOEIS::compare_values
  (anum => q{A033638},
   name => 'A033638 vs func',
   func => sub {
     my ($count) = @_;
     return [ map {A033638($_)} 0 .. $count-1 ];
   });

# A033638 and A080037 are complements
#      2,  4, 6, 8, 9,   11, 12, 14, 15, 16,   18, 19, 20, 22, 23, 24, 25, 27
#  1,1,2, 3, 5, 7,    10,   13,             17,           21,             26,
{
  my $bad = 0;
  my $i = 1;
  my $j = 3;      # two initial 1s in A033638
  ok (A080037($i), 4);
  ok (A033638($j), 3);
  foreach my $n (3 .. 10000) {
    my $by_i = (A080037($i)==$n);
    my $by_j = (A033638($j)==$n);
    if ($by_i && $by_j) {
      MyTestHelpers::diag ("duplicate $n");
      last if $bad++ > 10;
    }
    unless ($by_i || $by_j) {
      MyTestHelpers::diag ("neither for $n");
      last if $bad++ > 10;
    }
    if ($by_i) { $i++; }
    if ($by_j) { $j++; }
  }
  ok ($bad, 0,
     'A033638 complement A080037');
}
# foreach my $n (4 .. 50) { print A033638($n),","; } print "\n"; exit;


#------------------------------------------------------------------------------
# A172979 -- N positions of the turns, which are also primes

MyOEIS::compare_values
  (anum => 'A172979',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'SquareSpiral',
                                                 turn_type => 'LSR');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value != 0 && is_prime($i)) {
         push @got, $i;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A265410 - smallest 8 directions neighbour

MyOEIS::compare_values
  (anum => q{A265410},  # not shown in POD
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = $path->n_start + 2; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       my @lefts;
       foreach my $d (0..7) {
         my $left = $path->xy_to_n($x + $dir8_to_dx[$d],
                                   $y + $dir8_to_dy[$d]);
         if (defined $left && $left < $n) {
           push @lefts, $left;
         }
       }
       push @got, min(@lefts) || 0;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A141481 -- sum of existing eight surrounding values so far

# values so far kept in @got
MyOEIS::compare_values
  (anum => q{A141481},  # not shown in POD
   func => sub {
     my ($count) = @_;
     my $path = $path_n_start_0;
     my @got = (1);
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       my $sum = Math::BigInt->new(0);
       foreach my $i (0 .. $#dir8_to_dx) {
         my $sn = $path->xy_to_n ($x+$dir8_to_dx[$i], $y+$dir8_to_dy[$i]);
         if ($sn < $n) {
           $sum += $got[$sn]; # @got is 0-based
         }
       }
       push @got, $sum;
     }
     return \@got;
   });

# values so far kept in %plotted hash
MyOEIS::compare_values
  (anum => q{A141481},  # not shown in POD
   func => sub {
     my ($count) = @_;
     my @got;
     my %plotted;
     $plotted{0,0} = Math::BigInt->new(1);
     push @got, 1;

     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       my $value = (
                    ($plotted{$x+1,$y+1} || 0)
                    + ($plotted{$x+1,$y} || 0)
                    + ($plotted{$x+1,$y-1} || 0)

                    + ($plotted{$x-1,$y-1} || 0)
                    + ($plotted{$x-1,$y} || 0)
                    + ($plotted{$x-1,$y+1} || 0)

                    + ($plotted{$x,$y-1} || 0)
                    + ($plotted{$x,$y+1} || 0)
                   );
       $plotted{$x,$y} = $value;
       push @got, $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A055086 -- direction, net total turn
# OFFSET=0
# 0, 1, 2, 2, 3, 3, 4, 4, 4, 5, 5, 5, 6, ...

{
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                              turn_type => 'Left');
  ok ($seq->ith(1), undef);
  ok ($seq->ith(2), 1);
}
MyOEIS::compare_values
  (anum => 'A055086',
   name => 'direction',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my $dir = 0;
     while (@got < $count) {
       push @got, $dir;
       my ($i,$value) = $seq->next;
       $dir += $value;  # total lefts
     }
     return \@got;
   });

# A000267 -- direction + 1
# OFFSET=0
MyOEIS::compare_values
  (anum => 'A000267',
   name => 'direction + 1',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my $dir = 1;
     while (@got < $count) {
       push @got, $dir;
       my ($i,$value) = $seq->next;
       $dir += $value;  # total lefts
     }
     return \@got;
   });

# A063826 -- direction 1,2,3,4 = E,N,W,S
MyOEIS::compare_values
  (anum => 'A063826',
   name => 'direction 1 to 4',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, path_n_dir4_1($path,$n);
     }
     return \@got;
   });

# A248333 total straights among the first n points
# ~/OEIS/A248333.internal.txt
# OFFSET=0
# 0, 0, 0, 0, 1, 1, 2, 2, 3, 4, 4, 5, 6, 6, 7, 8, 9, 9, 10, 11, 12, 12,
# 0  1  2  3  4
#
#    5   4   3
#    1---1---0
#            |
#        0---0
#        1   2
MyOEIS::compare_values
  (anum => 'A248333',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Straight');
     my $straights = 0;
     my $n = 0;
     while (@got < $count) {
       push @got, $straights;  # up to and including n,
       $n++;                   # first test at n=1 (which is false)
       if ($seq->ith($n)) { $straights++; }
     }
     return \@got;
   });
# GP-DEFINE  A248333(n) = n - if(n,sqrtint(4*n-1));
# GP-Test  A248333(3) == 0
# GP-Test  A248333(4) == 1
# GP-Test  A248333(5) == 1
# GP-Test  A248333(6) == 2
# GP-Test  my(v=OEIS_samples("A248333")); vector(#v,n,n--; A248333(n)) == v  /* OFFSET=0 */
# GP-Test  my(g=OEIS_bfile_gf("A248333")); g==Polrev(vector(poldegree(g)+1,n,n--;A248333(n)))
# poldegree(OEIS_bfile_gf("A248333"))
# OEIS_samples("A248333")
# vector(20,n,n--; A248333(n))
# vector(50,n,n--; !(A248333(n+1) - A248333(n)))
# not in OEIS: 1,0,1,0,1,1,0,1,1,0,1,1,1,0,1,1,1,0,1,1,1,1,0,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,1
# complement of A240025 quarter squares predicate


# A083479 total non-turn points among the first n points
# origin n_start is a non-turn
# any LSR!=0 is a turn, and otherwise not
# (not the same as NotStraight since that is false at origin)
MyOEIS::compare_values
  (anum => 'A083479',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'LSR');
     my $nonturns = 0;
     my $n = 0;
     while (@got < $count) {
       push @got, $nonturns;
       $n++;
       if (! $seq->ith($n)) { $nonturns++; }
     }
     return \@got;
   });

# integers with A033638 inserted, so how many non-turns
sub A083479 {
  my ($n) = @_;
  # formula by Gregory R. Bryant in A083479
  $n >= 0 or croak "A083479() is for n>=0";
  return ($n==0 ? 0 : $n+2 - ceil(sqrt(4*$n)));
}
MyOEIS::compare_values
  (anum => q{A083479},
   name => 'A083479 vs func',
   func => sub {
     my ($count) = @_;
     return [ map {A083479($_)} 0 .. $count-1 ];
   });

# GP-DEFINE  sqrtint_ceil(n) = if(n==0,0, sqrtint(n-1)+1);
# GP-Test  vector(100,n,n--; sqrtint_ceil(n)) == \
# GP-Test  vector(100,n,n--; sqrtint(n) + !issquare(n))

# GP-DEFINE  A083479(n) = if(n==0,0, n+2 - sqrtint_ceil(4*n));
# GP-Test  my(v=OEIS_samples("A083479")); vector(#v,n,n--; A083479(n)) == v  /* OFFSET=0 */
# GP-Test  my(n=0); n+2 - sqrtint_ceil(4*n) == 2  /* whereas want 0 */


#------------------------------------------------------------------------------
# A240025 -- turn sequence, but it has extra initial 1
#
#   1--0--1
#   |     |
#   0  1--1
#   |
#   1--0--0--1

MyOEIS::compare_values
  (anum => 'A240025',
   func => sub {
     my ($count) = @_;
     my @got = (1);     # extra initial 1 in A240025
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'SquareSpiral',
                                                 turn_type => 'Left');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

# GP-DEFINE  n_is_corner_0based(n) = issquare(n) || issquare(4*n+1);
# GP-DEFINE  n_is_corner_1based(n) = n_is_corner_0based(n-1);
# GP-DEFINE  A240025(n) = n_is_corner_0based(n);
# my(v=OEIS_samples("A240025")); vector(#v,n,n--; A240025(n)) == v  \\ OFFSET=0
# my(g=OEIS_bfile_gf("A240025")); g==Polrev(vector(poldegree(g)+1,n,n--; A240025(n)))
# poldegree(OEIS_bfile_gf("A240025"))


#------------------------------------------------------------------------------
# A174344 X coordinate
MyOEIS::compare_values
  (anum => 'A174344',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n=1; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x;
     }
     return \@got;
   });

# A274923 Y coordinate
MyOEIS::compare_values
  (anum => 'A274923',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n=1; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

# A268038  negative Y coordinate
MyOEIS::compare_values
  (anum => 'A268038',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n=1; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, -$y;
     }
     return \@got;
   });

# A296030 X,Y pairs
MyOEIS::compare_values
  (anum => 'A296030',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n=1; ; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       @got < $count or last;
       push @got, $x;
       @got < $count or last;
       push @got, $y;
     }
     return \@got;
   });

# GP-DEFINE  \\ X cooordinate, 1-based, my line in A174344
# GP-DEFINE  A174344(n) = {
# GP-DEFINE    n>=1 || error();
# GP-DEFINE    n--; my(m=sqrtint(n),k=ceil(m/2));
# GP-DEFINE    n -= 4*k^2;
# GP-DEFINE    if(n<0, if(n<-m, k, -k-n), if(n<m, -k, n-3*k));
# GP-DEFINE  }
# GP-DEFINE  X(n) = A174344(n);
#
# my(v=OEIS_samples("A174344")); vector(#v,n, A174344(n)) == v  /* OFFSET=1 */
# my(g=OEIS_bfile_gf("A174344")); g==x*Polrev(vector(poldegree(g),n, A174344(n)))
# poldegree(OEIS_bfile_gf("A174344"))

# GP-DEFINE  \\ Y cooordinate, 1-based, my line in A274923
# GP-DEFINE  A274923(n) = {
# GP-DEFINE    n>=1 || error();
# GP-DEFINE    n--; my(m=sqrtint(n), k=ceil(m/2));
# GP-DEFINE    n -= 4*k^2;
# GP-DEFINE    if(n<0, if(n<-m, 3*k+n, k), if(n<m, k-n, -k));
# GP-DEFINE  }
# GP-DEFINE  Y(n) = A274923(n);
#
# my(v=OEIS_samples("A274923")); vector(#v,n, A274923(n)) == v
# my(g=OEIS_bfile_gf("A274923")); g==x*Polrev(vector(poldegree(g),n, A274923(n)))
# poldegree(OEIS_bfile_gf("A274923"))


#------------------------------------------------------------------------------
# GP X,Y -> N

# GP-DEFINE  \\ a couple of different ways
# GP-DEFINE  XY_to_N0(x,y) = {
# GP-DEFINE    if(x>abs(y),      \\ right vertical
# GP-DEFINE       (4*x-2)*x - (x-y),
# GP-DEFINE       -x>abs(y),     \\ left vertical
# GP-DEFINE       (4*x-2)*x + (x-y),
# GP-DEFINE       y>0,
# GP-DEFINE       (4*y-2)*y - (x-y),   \\ top horizontal
# GP-DEFINE       (4*y-2)*y + (x-y)); \\ bottom horizontal
# GP-DEFINE  }
# GP-DEFINE  XY_to_N1(x,y) = XY_to_N0(x,y) + 1;
#
# GP-Test  /* XY_to_N1() vs back again X() and Y() */ \
# GP-Test  for(y=-1,20, \
# GP-Test    for(x=-1,20, \
# GP-Test      my(n=XY_to_N1(x,y), back_x=X(n),back_y=Y(n)); \
# GP-Test      (x==back_x && y==back_y) \
# GP-Test      || error("xy=",x,",",y," n="n" which is xy="back_x" "back_y))); \
# GP-Test  1


# GP-DEFINE  check_XY_to_N0_func(func) = {
# GP-DEFINE    if(0,  \\ view
# GP-DEFINE      forstep(y=4,-4,-1,
# GP-DEFINE        for(x=-4,4,
# GP-DEFINE          printf(" %4d", func(x,y)));
# GP-DEFINE          print()));
# GP-DEFINE
# GP-DEFINE    for(y=-20,20,
# GP-DEFINE      for(x=-20,20,
# GP-DEFINE        my(want=XY_to_N0(x,y),
# GP-DEFINE           got=func(x,y));
# GP-DEFINE        if(want!=got,
# GP-DEFINE           error("xy=",x,",",y," want=",want," got=",got))));
# GP-DEFINE    1;
# GP-DEFINE   }

# Per
#   Ronald L. Graham, Donald E. Knuth, Oren Patashnik, "Concrete Mathematics",
#   Addison-Wesley, 1989, chapter 3 "Integer Functions", exercise 40 page 99,
#   answer page 498.
# They spiral clockwise so y negated as compared to the form here.
# 
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    y = -y; \
# GP-Test    my(k=max(abs(x),abs(y))); \
# GP-Test    (2*k)^2 + if(x>y, -1, 1) * (2*k + x + y); \
# GP-Test  )

# Using x-y diag as offset NW,SE, like Graham, Knuth, Patashnik.
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    my(r=2*max(abs(x),abs(y))); \
# GP-Test    r^2 + if(x+y>0, -(x-y+r), x-y+r); \
# GP-Test  )


# GP-Test  /* transpose to go to x as radial distance */ \
# GP-Test  /* then x-y diagonal as offset */ \
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    my(s = if(abs(x)>abs(y), -sign(x), [x,y]=[y,x];sign(x))); \
# GP-Test    (4*x-2)*x + s*(x-y); \
# GP-Test  )
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    my(s = if(abs(x)>abs(y), -sign(x), [x,y]=[y,x];sign(x))); \
# GP-Test    4*x^2 - 2*x + s*x - s*y; \
# GP-Test  )
#
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    if(abs(x)>abs(y), \
# GP-Test       (4*x-2)*x - sign(x)*(x-y), \
# GP-Test       (4*y-2)*y - sign(y)*(x-y)); \
# GP-Test  )
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    if(abs(x)>abs(y), \
# GP-Test       4*x*x - abs(x) + sign(x)*(y - 2*abs(x)), \
# GP-Test       (4*y-2)*y - sign(y)*(x-y)); \
# GP-Test  )
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    my(s = if(abs(x)>abs(y), -sign(x), [x,y]=[y,x];sign(x))); \
# GP-Test    my(t=x+y,d=x-y); \
# GP-Test    t^2 + 2*d*t + d^2 - t - d + s*d; \
# GP-Test  )
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    my(swap=abs(x)>abs(y)); \
# GP-Test    my(s); \
# GP-Test    my(t=x+y); \
# GP-Test    my(d=x-y); \
# GP-Test    swap == (abs(t+d)>abs(t-d)) || error(); \
# GP-Test    swap == (sign(t)*sign(d) > 0) || error(); \
# GP-Test    /* d *= (-1)^!swap; */ \
# GP-Test    d *= (-1)^(sign(t)*sign(d) <= 0); \
# GP-Test    /* d = abs(d)*if(sign(t)>0,-1,1); */ \
# GP-Test    if(swap, s=-sign(t+d), s=sign(t+d)); \
# GP-Test    t^2 + 2*d*t + d^2 - t - d + s*d; \
# GP-Test  )
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    my(t=x+y); \
# GP-Test    my(d=x-y); \
# GP-Test    my(r=max(abs(x),abs(y))); \
# GP-Test    if(t>0, 4*r^2 - 2*r - d, \
# GP-Test            4*r^2 + 2*r + d); \
# GP-Test  )
# GP-Test  check_XY_to_N0_func((x,y)-> \
# GP-Test    my(t=x+y); \
# GP-Test    my(d=x-y); \
# GP-Test    my(r=2*max(abs(x),abs(y))); \
# GP-Test    if(t>0, r^2 - (r+d), \
# GP-Test            r^2 + (r+d)); \
# GP-Test  )

# GP-DEFINE  N1_to_left(n) = {
# GP-DEFINE    my(x=X(n),y=Y(n),ret=0);
# GP-DEFINE    for(d=0,3,
# GP-DEFINE      my(dz=I^d, dx=real(dz), dy=imag(dz),
# GP-DEFINE         left=XY_to_N1(x+dx,y+dy));
# GP-DEFINE      if(left>=n-1,next);
# GP-DEFINE      if(ret,error("n="n" dxdy="dx","dy"  left="left" already ret="ret));
# GP-DEFINE      ret=left);
# GP-DEFINE    ret;
# GP-DEFINE  }
# vector(30,n, N1_to_left(n))

# forstep(y=4,-4,-1, \
#   for(x=-4,4, \
#     printf(" %4d", XY_to_N0(x,y))); \
#   print());


#------------------------------------------------------------------------------
# A180714  X+Y coordinate sum, OFFSET=0

MyOEIS::compare_values
  (anum => 'A180714',
   func => sub {
     my ($count) = @_;
     my $path = $path_n_start_0;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x + $y;
     }
     return \@got;
   });

# GP-DEFINE  \\ coordinate sum X+Y, 0-based
# GP-DEFINE  A180714(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    n++;
# GP-DEFINE    X(n) + Y(n);
# GP-DEFINE  }
# GP-Test  /* compact */ \
# GP-Test  vector(1000,n,n--; A180714(n)) == \
# GP-Test  vector(1000,n,n--; my(s=ceil(sqrtint(4*n)/2)); \
# GP-Test                     (s^2 - (s%2) - n)*(-1)^s )
#
# GP-Test  vector(1000,n,n--; A180714(n)) == \
# GP-Test  vector(1000,n,n--; my(s=if(n,ceil(sqrtint(4*n-3)/2))); \
# GP-Test                     (s^2 - (s%2) - n)*(-1)^s )
#
# GP-Test  /* round-to-nearest */ \
# GP-Test  vector(1000,n,n--; A180714(n)) == \
# GP-Test  vector(1000,n,n--; my(s=round(sqrt(n))); \
# GP-Test                     (s^2 - (s%2) - n)*(-1)^s )
# (7/2)^2 == 49/4
# integer n is never half way
#
# GP-Test  /* sqrtint need to push half way */ \
# GP-Test  vector(1000,n,n--; A180714(n)) == \
# GP-Test  vector(1000,n,n--; my(s=sqrtint(n)); \
# GP-Test                     (abs(n-s*(s+1)) - s)*(-1)^s + (s%2) )
# GP-Test  vector(1000,n,n--; A180714(n)) == \
# GP-Test  vector(1000,n,n--; my(s=sqrtint(n),r=n-s*(s+1)); \
# GP-Test                     (abs(r)-s)*(-1)^s + (s%2) )
#
# GP-Test  /* more or less the X,Y cases */ \
# GP-Test  vector(1000,n,n--; A180714(n)) == \
# GP-Test  vector(1000,n,n--; my(s=sqrtint(n),r=n-s*(s+1)); \
# GP-Test                     if(s%2==1, if(r<=0, -abs(r) +s, -abs(r) +s), \
# GP-Test                                if(r<=0,  abs(r) -s,  abs(r) -s) ) \
# GP-Test                     + (s%2) )
# GP-Test  vector(1000,n,n--; A180714(n)) == \
# GP-Test  vector(1000,n,n--; my(m=sqrtint(n),k=ceil(m/2)); \
# GP-Test                     n -= 4*k^2; \
# GP-Test                     if(n<-m,    4*k+n, \
# GP-Test                        n>=m,  -(4*k-n), \
# GP-Test                        n<0 && n>=-m, -n, \
# GP-Test                        n>=0 && n<m, -n, \
# GP-Test                        error()))
#
# my(v=OEIS_samples("A180714")); vector(#v,n,n--; A180714(n)) - v  \\ OFFSET=0
# my(g=OEIS_bfile_gf("A180714")); g==Polrev(vector(poldegree(g)+1,n,n--; A180714(n)))
# poldegree(OEIS_bfile_gf("A180714"))
# vector(40,n,n--; A180714(n))
# select(n->A180714(n)==0,[1..300])
# select(n->n>=2 && A180714(n-1)==A180714(n+1),[1..300])
#
#     16-15-14-13-12 ...
#      |           |  |
#     17  4--3--2 11 28          0-based
#      |  |     |  |  |          even squares X+Y=0
#     18  5  0--1 10 27
#      |  |        |  |
#     19  6--7--8--9 26
#      |              |
#     20-21-22-23-24-25

# A180714 increments mentioned in A180714
# vector(30,n,n--; A180714(n+1) - A180714(n))
# not in OEIS: 1, 1, -1, -1, -1, -1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

# X+Y at corners, as mentioned in A180714
# Vec(-x*(1+x)/((x-1)*(x^2+1)^2) + O(x^20))
# not in OEIS: 1, 2, 0, -2, 1, 4, 0, -4, 1, 6, 0, -6, 1, 8, 0, -8, 1, 10, 0


#------------------------------------------------------------------------------
# A265400  left side neighbour, n_start=1

sub A265400 {
  my ($n) = @_;
  $n >= 1 or die "A265400 is for n>=1";
  my ($x,$y) = $path->n_to_xy ($n);
  $path->n_start == 1 or die;
  return max(0, map { my $n2 = $path->xy_to_n($x + $dir4_to_dx[$_],
                                              $y + $dir4_to_dy[$_]);
                      defined $n2 && $n2 < $n-1 ? ($n2) : () } 0 .. 3);
}
MyOEIS::compare_values
  (anum => 'A265400',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, A265400($n);
     }
     return \@got;
   });

{
  # A265400() vs formula like the GP form below
  my $bad = 0;
  foreach my $n (1 .. 10000) {
    my $want = A265400($n);
    my $got;
    if (issquare($n-1) || issquare(4*$n-3)) { $got = 0; }
    else { $got = $n - 2*int(sqrt(4*$n - 3)) + 3; }
    unless ($got == $want) {
      $bad++;
    }
  }
  ok ($bad, 0, 'A265400 formula vs path');
}

# cf Antti Karttunen Scheme code ~/OEIS/a260643.txt
#
# GP-DEFINE  A265400(n) = {
# GP-DEFINE    n>=1 || error("A265400() is for n>=1");
# GP-DEFINE    \\ if(n>1, n - 2*sqrtint(4*n-1) - 3);
# GP-DEFINE    \\ 2*sqrtint(4*n-1)-3;
# GP-DEFINE    if(issquare(n-1) || issquare(4*n-3), 0, n+3 - 2*sqrtint(4*n-3));
# GP-DEFINE  }
# forstep(y=5,-5,-1, \
#   for(x=-5,5, \
#     my(n=XY_to_N1(x,y)); \
#     printf(" %4d/%-2d", n, A265400(n))); \
#   print());

# my(v=OEIS_samples("A265400")); vector(#v,n, A265400(n)) == v  /* OFFSET=1 */
# my(g=OEIS_bfile_gf("A265400")); g==x*Polrev(vector(poldegree(g),n, A265400(n)))
# poldegree(OEIS_bfile_gf("A265400"))
# vector(40,n, A265400(n))

# GP-DEFINE  ceil_sqrt(n) = my(s); if(issquare(n,&s), s, sqrtint(n)+1);
# GP-Test  vector(1000,n, my(s=ceil_sqrt(n)); (s-1)^2 < n && n <= s^2) == \
# GP-Test  vector(1000,n, 1)

# GP-Test  /* formula */ \
# GP-Test  vector(1000,n, A265400(n)) == \
# GP-Test  vector(1000,n, if(issquare(n-1) || issquare(4*n-3), 0, \
# GP-Test                    n+5 - 2*ceil_sqrt(4*n) ))

# runs of offset to the left cell
# vector(40,n, if(n_is_corner_1based(n),0, n - A265400(n)))
# not in OEIS: 3, 0, 5, 0, 7, 7, 0, 9, 9, 0, 11, 11, 11, 0, 13, 13, 13, 0, 15, 15, 15, 15, 0, 17, 17, 17, 17, 0, 19, 19, 19, 19, 19, 0, 21, 21, 21


#------------------------------------------------------------------------------
# A010052 - issquare() helper

sub issquare {
  my ($n) = @_;
  return int(sqrt($n))**2 == $n;
}
MyOEIS::compare_values
  (anum => q{A010052}, # not shown in POD
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, issquare($n) ? 1 : 0;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A267682 Y axis positive and negative, n_start=1, origin twice
MyOEIS::compare_values
  (anum => 'A267682',
   func => sub {
     my ($count) = @_;
     my @got;
     my $y = 0;
     for (;;) {
       push @got, $path->xy_to_n(0, $y);
       last unless @got < $count;
       push @got, $path->xy_to_n(0, -$y);
       last unless @got < $count;
       $y++;
     }
     return \@got;
   });

# A156859 Y axis positive and negative, n_start=0
MyOEIS::compare_values
  (anum => 'A156859',
   func => sub {
     my ($count) = @_;
     my $path = $path_n_start_0;
     my @got = (0);
     for (my $y = 1; @got < $count; $y++) {
       push @got, $path->xy_to_n(0, $y);
       last unless @got < $count;
       push @got, $path->xy_to_n(0, -$y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A059924 Write the numbers from 1 to n^2 in a spiralling square; a(n) is the
# total of the sums of the two diagonals.

MyOEIS::compare_values
  (anum => q{A059924},  # not shown in pod
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = 1; @got < $count; $n++) {
### A059924 ...
       push @got, A059924($n);
     }
     return \@got;
   });

# A059924 spirals inwards, use $square+1 - $t to reverse the path numbering
sub A059924 {
  my ($n) = @_;
  ### A059924(): $n
  my $square = $n*$n;
  ### $square
  my $total = 0;
  my ($x,$y) = $path->n_to_xy($square);
  my $dx = ($x <= 0 ? 1 : -1);
  my $dy = ($y <= 0 ? 1 : -1);
  ### diagonal: "$x,$y dir $dx,$dy"
  for (;;) {
    my $t = $path->xy_to_n($x,$y);
    ### $t
    last if $t > $square;
    $total += $square+1 - $t;
    $x += $dx;
    $y += $dy;
  }
  $x -= $dx;
  $y -= $dy * $n;
  $dx = - $dx;
  ### diagonal: "$x,$y dir $dx,$dy"
  for (;;) {
    my $t = $path->xy_to_n($x,$y);
    ### $t
    last if $t > $square;
    $total += $square+1 - $t;
    $x += $dx;
    $y += $dy;
  }
  ### $total
  return $total;
}

#------------------------------------------------------------------------------
# A027709 -- unit squares figure boundary

MyOEIS::compare_values
  (anum => 'A027709',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, $path->_NOTDOCUMENTED_n_to_figure_boundary($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A078633 -- grid sticks

sub path_n_to_dsticks {
  my ($path, $n) = @_;
  my ($x,$y) = $path->n_to_xy($n);
  my $dsticks = 4;
  foreach my $i (0 .. $#dir4_to_dx) {
    my $an = $path->xy_to_n($x+$dir4_to_dx[$i], $y+$dir4_to_dy[$i]);
    $dsticks -= (defined $an && $an < $n);
  }
  return $dsticks;
}

MyOEIS::compare_values
  (anum => 'A078633',
   func => sub {
     my ($count) = @_;
     my @got;
     my $boundary = 0;
     for (my $n = $path->n_start; @got < $count; $n++) {
       $boundary += path_n_to_dsticks($path,$n);
       push @got, $boundary;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A094768 -- cumulative spiro-fibonacci total of 4 neighbours

MyOEIS::compare_values
  (anum => q{A094768},
   func => sub {
     my ($count) = @_;
     my $path = $path_n_start_0;
     my $total = Math::BigInt->new(1);
     my @got = ($total);
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n-1);
       foreach my $i (0 .. $#dir4_to_dx) {
         my $sn = $path->xy_to_n ($x+$dir4_to_dx[$i], $y+$dir4_to_dy[$i]);
         if ($sn < $n) {
           $total += $got[$sn];
         }
       }
       $got[$n] = $total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A094767 -- cumulative spiro-fibonacci total of 8 neighbours

MyOEIS::compare_values
  (anum => q{A094767},
   func => sub {
     my ($count) = @_;
     my $path = $path_n_start_0;
     my $total = Math::BigInt->new(1);
     my @got = ($total);
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n-1);
       foreach my $i (0 .. $#dir8_to_dx) {
         my $sn = $path->xy_to_n ($x+$dir8_to_dx[$i], $y+$dir8_to_dy[$i]);
         if ($sn < $n) {
           $total += $got[$sn];
         }
       }
       $got[$n] = $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A094769 -- cumulative spiro-fibonacci total of 8 neighbours starting 0,1

MyOEIS::compare_values
  (anum => q{A094769},
   func => sub {
     my ($count) = @_;
     my $path = $path_n_start_0;
     my $total = Math::BigInt->new(1);
     my @got = (0, $total);
     for (my $n = $path->n_start + 2; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n-1);
       foreach my $i (0 .. $#dir8_to_dx) {
         my $sn = $path->xy_to_n ($x+$dir8_to_dx[$i], $y+$dir8_to_dy[$i]);
         if ($sn < $n) {
           $total += $got[$sn];
         }
       }
       $got[$n] = $total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A078784 -- primes on any axis positive or negative

MyOEIS::compare_values
  (anum => q{A078784},   # not shown in POD
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       if ($x == 0 || $y == 0) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A090925 -- permutation rotate +90

MyOEIS::compare_values
  (anum => 'A090925',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x,$y) = (-$y,$x);  # rotate +90
       push @got, $path->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A090928 -- permutation rotate +180
MyOEIS::compare_values
  (anum => 'A090928',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x,$y) = (-$x,-$y);  # rotate +180
       push @got, $path->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A090929 -- permutation rotate +270
MyOEIS::compare_values
  (anum => 'A090929',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x,$y) = ($y,-$x);  # rotate -90
       push @got, $path->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A090861 -- permutation rotate +180, opp direction
MyOEIS::compare_values
  (anum => 'A090861',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       $y = -$y; # opp direction
       ($x,$y) = (-$x,-$y);  # rotate 180
       push @got, $path->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A090915 -- permutation rotate +270, opp direction
MyOEIS::compare_values
  (anum => 'A090915',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       $y = -$y; # opp direction
       ($x,$y) = ($y,-$x);  # rotate -90
       push @got, $path->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A090930 -- permutation opp direction
MyOEIS::compare_values
  (anum => 'A090930',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       $y = -$y; # opp direction
       push @got, $path->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A185413 -- rotate 180, offset X+1,Y
MyOEIS::compare_values
  (anum => 'A185413',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       $x = 1 - $x;
       push @got, $path->xy_to_n ($x, $y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A078765 -- primes at integer radix sqrt(x^2+y^2), and not on axis

MyOEIS::compare_values
  (anum => q{A078765},   # not shown in POD
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       if ($x != 0 && $y != 0 && is_perfect_square($x*$x+$y*$y)) {
         push @got, $n;
       }
     }
     return \@got;
   });

sub is_perfect_square {
  my ($n) = @_;
  my $sqrt = int(sqrt($n));
  return ($sqrt*$sqrt == $n);
}

#------------------------------------------------------------------------------
# A200975 -- N on all four diagonals

MyOEIS::compare_values
  (anum => 'A200975',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $i = 1; @got < $count; $i++) {
       push @got, $path->xy_to_n($i,$i);
       last unless @got < $count;

       push @got, $path->xy_to_n(-$i,$i);
       last unless @got < $count;

       push @got, $path->xy_to_n(-$i,-$i);
       last unless @got < $count;

       push @got, $path->xy_to_n($i,-$i);
       last unless @got < $count;
     }
     return \@got;
   });

# #------------------------------------------------------------------------------
# # A195060 -- N on axis or diagonal  ???
# # vertices generalized pentagonal 0,1,2,5,7,12,15,22,...
# # union A001318, A032528, A045943
#
# MyOEIS::compare_values
#   (anum => 'A195060',
#    func => sub {
#      my ($count) = @_;
#      my @got = (0);
#      for (my $n = $path->n_start; @got < $count; $n++) {
#        my ($x,$y) = $path->n_to_xy ($n);
#        if ($x == $y || $x == -$y || $x == 0 || $y == 0) {
#          push @got, $n;
#        }
#      }
#      return \@got;
#    });

# #------------------------------------------------------------------------------
# # A137932 -- count points not on diagonals up to nxn
#
# MyOEIS::compare_values
#   (anum => 'A137932',
#    max_value => 1000,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $k = 0; @got < $count; $k++) {
#        my $num = 0;
#        my ($cx,$cy) = $path->n_to_xy ($k*$k);
#        foreach my $n (1 .. $k*$k) {
#          my ($x,$y) = $path->n_to_xy ($n);
#          $num += (abs($x) != abs($y));
#        }
#        push @got, $num;
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A113688 -- isolated semi-primes

# cf
# A113689 Number of semiprimes in clumps of size >1 through n^2 in the semiprime spiral.

MyOEIS::compare_values
  (anum => q{A113688},   # not shown in POD
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::AlmostPrimes->new;
     my @got;
   N: for (my $n = $path->n_start; @got < $count; $n++) {
       next unless $seq->pred($n);  # want n a semiprime
       my ($x,$y) = $path->n_to_xy ($n);
       foreach my $i (0 .. $#dir8_to_dx) {
         my $sn = $path->xy_to_n ($x+$dir8_to_dx[$i], $y+$dir8_to_dy[$i]);
         if ($seq->pred($sn)) {
           next N;   # has a semiprime neighbour, skip
         }
       }
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A215470 -- primes with >=4 prime neighbours in 8 surround

MyOEIS::compare_values
  (anum => 'A215470',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       my $num = 0;
       foreach my $i (0 .. $#dir8_to_dx) {
         my $sn = $path->xy_to_n ($x+$dir8_to_dx[$i], $y+$dir8_to_dy[$i]);
         if (is_prime($sn)) { $num++; }
       }
       if ($num >= 4) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A137930 sum leading and anti diagonal of nxn square

MyOEIS::compare_values
  (anum => q{A137930},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, diagonals_total($path,$k);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A137931},  # 2n x 2n
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k+=2) {
       push @got, diagonals_total($path,$k);
     }
     return \@got;
   });

# A114254 Sum of all terms on the two principal diagonals of a 2n+1 X 2n+1 square spiral.
MyOEIS::compare_values
  (anum => q{A114254},  # 2n+1 x 2n+1
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 1; @got < $count; $k+=2) {
       push @got, diagonals_total($path,$k);
     }
     return \@got;
   });

sub diagonals_total {
  my ($path, $k) = @_;
  ### diagonals_total(): $k

  if ($k == 0) {
    return 0;
  }
  my ($x,$y) = $path->n_to_xy ($k*$k); # corner
  my $dx = ($x > 0 ? -1 : 1);
  my $dy = ($y > 0 ? -1 : 1);
  ### corner: "$x,$y  dx=$dx,dy=$dy"

  my %n;
  foreach my $i (0 .. $k-1) {
    my $n = $path->xy_to_n($x,$y);
    $n{$n} = 1;
    $x += $dx;
    $y += $dy;
  }

  $x -= $k*$dx;
  $dy = -$dy;
  $y += $dy;
  ### opposite: "$x,$y  dx=$dx,dy=$dy"

  foreach my $i (0 .. $k-1) {
    my $n = $path->xy_to_n($x,$y);
    $n{$n} = 1;
    $x += $dx;
    $y += $dy;
  }
  ### n values: keys %n

  return sum(keys %n);
}

#------------------------------------------------------------------------------
# A059428 -- Prime[N] for N=corner

MyOEIS::compare_values
  (anum => q{A059428},
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'LSR');
     my @got = (2);
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value) {
         push @got, MyOEIS::ith_prime($i); # i=2 as first turn giving prime=3
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A123663 -- count total shared edges

MyOEIS::compare_values
  (anum => q{A123663},
   func => sub {
     my ($count) = @_;
     my @got;
     my $edges = 0;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       foreach my $sn ($path->xy_to_n($x+1,$y),
                       $path->xy_to_n($x-1,$y),
                       $path->xy_to_n($x,$y+1),
                       $path->xy_to_n($x,$y-1)) {
         if ($sn < $n) {
           $edges++;
         }
       }
       push @got, $edges;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A172294 -- jewels, composite surrounded by 4 primes NSEW, n_start = 0
#
# Parity of loops mean n even has NSEW neighbours odd, and vice versa

MyOEIS::compare_values
  (anum => q{A172294},   # not shown in POD
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = $path_n_start_0;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next if is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       if (is_prime    ($path->xy_to_n($x+1,$y))
           && is_prime ($path->xy_to_n($x-1,$y))
           && is_prime ($path->xy_to_n($x,$y+1))
           && is_prime ($path->xy_to_n($x,$y-1))
          ) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A115258 -- isolated primes, 8 neighbours

MyOEIS::compare_values
  (anum => q{A115258},   # not shown in POD
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       if (! is_prime    ($path->xy_to_n($x+1,$y))
           && ! is_prime ($path->xy_to_n($x-1,$y))
           && ! is_prime ($path->xy_to_n($x,$y+1))
           && ! is_prime ($path->xy_to_n($x,$y-1))
           && ! is_prime ($path->xy_to_n($x+1,$y+1))
           && ! is_prime ($path->xy_to_n($x-1,$y-1))
           && ! is_prime ($path->xy_to_n($x-1,$y+1))
           && ! is_prime ($path->xy_to_n($x+1,$y-1))
          ) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A214177 -- sum of 4 neighbours

MyOEIS::compare_values
  (anum => q{A214177},   # not shown in POD
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, ($path->xy_to_n($x+1,$y)
                   + $path->xy_to_n($x-1,$y)
                   + $path->xy_to_n($x,$y+1)
                   + $path->xy_to_n($x,$y-1)
                  );
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A214176 -- sum of 8 neighbours

MyOEIS::compare_values
  (anum => q{A214176},   # not shown in POD
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, ($path->xy_to_n($x+1,$y)
                   + $path->xy_to_n($x-1,$y)
                   + $path->xy_to_n($x,$y+1)
                   + $path->xy_to_n($x,$y-1)
                   + $path->xy_to_n($x+1,$y+1)
                   + $path->xy_to_n($x-1,$y-1)
                   + $path->xy_to_n($x-1,$y+1)
                   + $path->xy_to_n($x+1,$y-1)
                  );
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A214664 -- X coord of prime N

MyOEIS::compare_values
  (anum => 'A214664',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, $x;
     }
     return \@got;
   });

# A214665 -- Y coord of prime N
MyOEIS::compare_values
  (anum => 'A214665',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, $y;
     }
     return \@got;
   });

# A214666 -- X coord of prime N, first to west
MyOEIS::compare_values
  (anum => 'A214666',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, -$x;
     }
     return \@got;
   });

# A214667 -- Y coord of prime N, first to west
MyOEIS::compare_values
  (anum => 'A214667',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, -$y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A143856 -- N values ENE slope=2

MyOEIS::compare_values
  (anum => 'A143856',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $path->xy_to_n (2*$i, $i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A143861 -- N values NNE slope=2

MyOEIS::compare_values
  (anum => 'A143861',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $path->xy_to_n ($i, 2*$i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A062410 -- a(n) is sum of existing numbers in row of a(n-1)

MyOEIS::compare_values
  (anum => 'A062410',
   func => sub {
     my ($count) = @_;
     my @got;
     my %plotted;
     $plotted{0,0} = Math::BigInt->new(1);
     my $xmin = 0;
     my $ymin = 0;
     my $xmax = 0;
     my $ymax = 0;
     push @got, 1;

     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($prev_x, $prev_y) = $path->n_to_xy ($n-1);
       my ($x, $y) = $path->n_to_xy ($n);
       my $total = 0;
       if ($y == $prev_y) {
         ### column: "$ymin .. $ymax at x=$prev_x"
         foreach my $y ($ymin .. $ymax) {
           $total += $plotted{$prev_x,$y} || 0;
         }
       } else {
         ### row: "$xmin .. $xmax at y=$prev_y"
         foreach my $x ($xmin .. $xmax) {
           $total += $plotted{$x,$prev_y} || 0;
         }
       }
       ### total: "$total"

       $plotted{$x,$y} = $total;
       $xmin = min($xmin,$x);
       $xmax = max($xmax,$x);
       $ymin = min($ymin,$y);
       $ymax = max($ymax,$y);
       push @got, $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A020703 -- permutation read clockwise, ie. transpose Y,X
#       also permutation rotate +90, opp direction

MyOEIS::compare_values
  (anum => 'A020703',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A121496 -- run lengths of consecutive N in A068225 N at X+1,Y

MyOEIS::compare_values
  (anum => 'A121496',
   func => sub {
     my ($count) = @_;
     my @got;
     my $num = 0;
     my $prev_right_n = A068225(1) - 1;  # make first value look like a run
     for (my $n = $path->n_start; @got < $count; $n++) {
       my $right_n = A068225($n);
       if ($right_n == $prev_right_n + 1) {
         $num++;
       } else {
         push @got, $num;
         $num = 1;
       }
       $prev_right_n = $right_n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054551 -- plot Nth prime at each N, values are those primes on X axis

MyOEIS::compare_values
  (anum => 'A054551',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       my $n = $path->xy_to_n($x,0);
       push @got, MyOEIS::ith_prime($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054553 -- plot Nth prime at each N, values are those primes on X=Y diagonal

MyOEIS::compare_values
  (anum => 'A054553',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       my $n = $path->xy_to_n($x,$x);
       push @got, MyOEIS::ith_prime($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054555 -- plot Nth prime at each N, values are those primes on Y axis

MyOEIS::compare_values
  (anum => 'A054555',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       my $n = $path->xy_to_n(0,$y);
       push @got, MyOEIS::ith_prime($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A053999 -- plot Nth prime at each N, values are those primes on South-East

MyOEIS::compare_values
  (anum => 'A053999',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       my $n = $path->xy_to_n($x,-$x);
       push @got, MyOEIS::ith_prime($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054564 -- plot Nth prime at each N, values are those primes on North-West

MyOEIS::compare_values
  (anum => 'A054564',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x--) {
       my $n = $path->xy_to_n($x,-$x);
       push @got, MyOEIS::ith_prime($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054566 -- plot Nth prime at each N, values are those primes on negative X

MyOEIS::compare_values
  (anum => 'A054566',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x--) {
       my $n = $path->xy_to_n($x,0);
       push @got, MyOEIS::ith_prime($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A137928 -- N values on diagonal X=1-Y positive and negative

MyOEIS::compare_values
  (anum => 'A137928',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n(1-$y,$y);
       last unless @got < $count;
       if ($y != 0) {
         push @got, $path->xy_to_n(1-(-$y),-$y);
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002061 -- central polygonal numbers, N values on diagonal X=Y pos and neg

MyOEIS::compare_values
  (anum => 'A002061',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n($y,$y);
       last unless @got < $count;
       push @got, $path->xy_to_n(-$y,-$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A016814 -- N values (4n+1)^2 on SE diagonal every second square

MyOEIS::compare_values
  (anum => 'A016814',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $i = 0; @got < $count; $i+=2) {
       push @got, $path->xy_to_n($i,-$i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A033952 -- AllDigits on negative Y axis

MyOEIS::compare_values
  (anum => 'A033952',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::AllDigits->new;
     for (my $y = 0; @got < $count; $y--) {
       my $n = $path->xy_to_n (0, $y);
       push @got, $seq->ith($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A033953 -- AllDigits starting 0, on negative Y axis

MyOEIS::compare_values
  (anum => 'A033953',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::AllDigits->new;
     for (my $y = 0; @got < $count; $y--) {
       my $n = $path->xy_to_n (0, $y);
       push @got, $seq->ith($n-1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A033988 -- AllDigits starting 0, on negative X axis

MyOEIS::compare_values
  (anum => 'A033988',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::AllDigits->new;
     for (my $x = 0; @got < $count; $x--) {
       my $n = $path->xy_to_n ($x, 0);
       push @got, $seq->ith($n-1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A033989 -- AllDigits starting 0, on positive Y axis

MyOEIS::compare_values
  (anum => 'A033989',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::AllDigits->new;
     for (my $y = 0; @got < $count; $y++) {
       my $n = $path->xy_to_n (0, $y);
       push @got, $seq->ith($n-1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A033990 -- AllDigits starting 0, on positive X axis

MyOEIS::compare_values
  (anum => 'A033990',
   func => sub {
     my ($count) = @_;
     my @got;
     my $seq = Math::NumSeq::AllDigits->new;
     for (my $x = 0; @got < $count; $x++) {
       my $n = $path->xy_to_n ($x, 0);
       push @got, $seq->ith($n-1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054556 -- N values on Y axis (but OFFSET=1)

MyOEIS::compare_values
  (anum => 'A054556',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A054554 -- N values on X=Y diagonal

MyOEIS::compare_values
  (anum => 'A054554',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $path->xy_to_n($i,$i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054569 -- N values on negative X=Y diagonal, but OFFSET=1

MyOEIS::compare_values
  (anum => 'A054569',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $path->xy_to_n(-$i,-$i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A068225 -- permutation N at X+1,Y

MyOEIS::compare_values
  (anum => 'A068225',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, A068225($n);
     }
     return \@got;
   });

# starting n=1
sub A068225 {
  my ($n) = @_;
  my ($x, $y) = $path->n_to_xy ($n);
  return $path->xy_to_n ($x+1,$y);
}

#------------------------------------------------------------------------------
# A068226 -- permutation N at X-1,Y

MyOEIS::compare_values
  (anum => 'A068226',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($x-1,$y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
