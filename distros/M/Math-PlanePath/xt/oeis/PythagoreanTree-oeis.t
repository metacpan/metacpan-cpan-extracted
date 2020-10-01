#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2016, 2018, 2019, 2020 Kevin Ryde

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
use List::Util 'min','max','sum';
use Math::BigInt try => 'GMP';
use Tie::Array::Sorted;
use Test;
plan tests => 54;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::PythagoreanTree;

use Math::PlanePath::GcdRationals;
*gcd = \&Math::PlanePath::GcdRationals::_gcd;

# uncomment this to run the ### lines
# use Smart::Comments;


# A024408  perimeters occurring more than once

#------------------------------------------------------------------------------
# Helpers

# GP-DEFINE  read("my-oeis.gp");

sub pq_acceptable {
  my ($p,$q) = @_;
  return ($p > $q
          && $q >= 1
          && ($p % 2) != ($q % 2)
          && gcd($p,$q) == 1);
}
{
  my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
  my $bad = 0;
  foreach my $p (-10, 30) {
    foreach my $q (-10, 30) {
      unless (pq_acceptable($p,$q) == $path->xy_is_visited($p,$q)) {
        $bad++;
      }
    }
  }
  ok ($bad, 0);
}

sub perimeter_of_pq {
  my ($p,$q) = @_;
  return 2*$p*($p+$q);
}
{
  my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
  my $path_AB = Math::PlanePath::PythagoreanTree->new (coordinates => 'AB');
  my $path_AC = Math::PlanePath::PythagoreanTree->new (coordinates => 'AC');
  my $bad = 0;
  foreach my $n ($path->n_start .. 50) {
    my ($p,$q) = $path->n_to_xy($n);
    my ($A,$B) = $path_AB->n_to_xy($n);
    my ($A_again,$C) = $path_AC->n_to_xy($n);
    unless (perimeter_of_pq($p,$q) == $A+$B+$C) {
      $bad++;
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# A009096 perimeters of all triples, with multiplicity

MyOEIS::compare_values
  (anum => 'A009096',
#   max_count => 66,
   func => sub {
     my ($count) = @_;
     my @primitives;
     my $aref = perimeterpqs_list_new();
     my $max_perimeter = 0;
     for (;;) {
       my $elem = perimeterpqs_list_next($aref);
       my ($perimeter,$p,$q) = @$elem;
       last if @primitives >= $count && $perimeter != $max_perimeter;
       $max_perimeter = $perimeter;
       push @primitives, [$p*$p-$q*$q, 2*$p*$q, $p*$p+$q*$q];
     }
     my @multiples;
     foreach my $triple (@primitives) {
       my ($A_primitive,$B_primitive,$C_primitive) = @$triple;
       for (my $i = 1; ; $i++) {
         my ($A,$B,$C) = ($i*$A_primitive, $i*$B_primitive, $i*$C_primitive);
         last if $A+$B+$C > $max_perimeter;
         push @multiples, [$A,$B,$C];
       }
     }
     @multiples = sort triple_cmp_by_perimeter_and_decreasing_area @multiples;
     my @got = map {sum(@$_)} @multiples;
     $#got = $count-1;
     return \@got;
   });


#------------------------------------------------------------------------------
# A103605 all triples, primitive and not,
#         ordered by increasing perimeter, then by decreasing area

# GP-DEFINE  A = (p^2 - q^2)*m;
# GP-DEFINE  B = 2*p*q*m;
# GP-DEFINE  C = (p^2 + q^2)*m;
# GP-DEFINE  A2 = (p2^2 - q2^2)*m2;
# GP-DEFINE  B2 = 2*p2*q2*m2;
# GP-DEFINE  C2 = (p2^2 + q2^2)*m2;
# GP-DEFINE  per  = A + B + C;
# GP-DEFINE  per2 = A2 + B2 + C2;
# GP-DEFINE  area = A*B;
# GP-DEFINE  area2 = A2*B2;
# GP-Test  A     == (p+q)*(p-q)*m
# GP-Test  A*B   == (p+q)*(p-q)  *m^2 * 2*p*q
# GP-Test  A2*B2 == (p2+q2)*(p2-q2)*m2^2 * 2*p2*q2
# (small-small2)*(A*B - A2*B2) >=0  ?
# so order by area same as order by A ?
# GP-Test  per == 2*m*p^2 + 2*m*p*q
# GP-Test  per == 2*m*p*(p+q)
# GP-Test  per == A * (2*p)/(p-q)
# GP-Test  per == B * (p+q)/q
# GP-Test  A == per * (p-q)/(2*p)
# GP-Test  A == per * 1/2*(1-q/p)
# GP-Test  B == per * q/(p+q)
# GP-Test  A*B == per^2 * (p-q)/(2*p) * q/(p+q)
# GP-Test  A*B == per^2 * 1/2 * q/p * (p-q)/(p+q)
# GP-Test  A*B == per^2 * 1/2 * (1-q/p)/(1 + p/q)

# GP-DEFINE  halfperimeter_to_mpq_list(h) = {
# GP-DEFINE    my(l=List([]));
# GP-DEFINE    fordiv(h,m,
# GP-DEFINE      my(M=h/m);
# GP-DEFINE      fordiv(M,p,
# GP-DEFINE        p>=2 || next;
# GP-DEFINE        my(p_plus_q = M/p,
# GP-DEFINE           q = p_plus_q - p);
# GP-DEFINE        q>=1 || next;
# GP-DEFINE        p>q || next;
# GP-DEFINE        if(gcd(p,q)==1,
# GP-DEFINE          listput(l,[m,p,q]))));
# GP-DEFINE    Vec(l);
# GP-DEFINE  }
# for(h=1,20, \
#   my(l=halfperimeter_to_mpq_list(h)); \
#   print(h"  "l); \
#   for(i=1,#l, \
#     my(m,p,q); [m,p,q]=l[i]; \
#     my(a=(p^2-q^2)*m, \
#        b=2*p*q*m, \
#        c=(p^2+q^2)*m); \
#     print("  "p","q" *"m"  "a","b","c); \
#     a^2 + b^2 == c^2 || error(); \
#     ))


sub triple_sans_gcd {
  my ($triple) = @_;
  my ($A,$B,$C) = @$triple;
  my $g = gcd($A,gcd($B,$C));
  return [$A/$g, $B/$g, $C/$g];
}

# $a and $b are arrayrefs [$A,$B,$C] legs of a triple
sub triple_cmp_by_perimeter_and_decreasing_area {
  # return sum(@$a) <=> sum(@$b)                # perimeter
  #   # || $a->[0]*$a->[1] <=> $b->[0]*$b->[1]    # area increasing
  #   # || $b->[0]*$b->[1] <=> $a->[0]*$a->[1]    # area decreasing
  #   || -($a->[0]*$a->[1]*$a->[2] <=> $b->[0]*$b->[1]*$b->[2] )
  #   || die "oops, same perimeter and area";

  if (my $order = sum(@$a) <=> sum(@$b)) {
    return $order;
  }
  return $b->[0]*$b->[2] <=> $a->[0]*$a->[2];

  # my $a = triple_sans_gcd($a);
  # my $b = triple_sans_gcd($b);
  # return $b->[0]*$b->[1] <=> $a->[0]*$a->[1];    # area decreasing
}
sub triple_cmp_by_perimeter_and_even {
  return sum(@$a) <=> sum(@$b)  # perimeter
    || $a->[1] <=> $b->[1]      # even member increasing
    || die "oops, same perimeter and area";
}

# 20,48,52, 24,45,51, 30,40,50  bfile
# 30,40,50, 24,45,51, 20,48,52

# ~/OEIS/b103605.txt
# 22 15
# 23 20
# 24 25
#
# 25 10
# 26 24
# 27 26
#
# GP-Test  15+20+25 == 60
# GP-Test  10+24+26 == 60
# GP-Test  15*20 == 300
# GP-Test  10*24 == 240
# GP-Test  gcd([15,20,25]) == 5
# GP-Test  gcd([10,24,26]) == 2
# GP-Test  [15,20,25]/5 == [3,4,5]
# GP-Test  [10,24,26]/2 == [5,12,13]


# ~/OEIS/b103605.txt
# /tmp/x.txt
# 58 20
# 59 48
# 60 52
#
# 61 24
# 62 45
# 63 51
#
# 64 30
# 65 40
# 66 50
#
# GP-Test  20+48+52 == 120
# GP-Test  24+45+51 == 120
# GP-Test  30+40+50 == 120
# GP-Test  20*48/2 == 480
# GP-Test  24*45/2 == 540
# GP-Test  30*40/2 == 600
# GP-Test  gcd([20,48,52]) == 4
# GP-Test  gcd([24,45,51]) == 3
# GP-Test  gcd([30,40,50]) == 10
# GP-Test  [20,48,52]/4 == [5,12,13]
# GP-Test  [24,45,51]/3 == [8,15,17]
# GP-Test  [30,40,50]/10 == [3,4,5]

# 3,4,5, 6,8,10, 5,12,13, 9,12,15, 8,15,17, 12,16,20, 7,24,25, 15,20,25,
# 10,24,26, 20,21,29, 18,24,30, 16,30,34, 21,28,35, 12,35,37, 15,36,39,
# 9,40,41, 24,32,40

MyOEIS::compare_values
  (anum => q{A103605},
   max_count => 3*100,
   name => 'all triples (primitive and not) by perimeter then something',
   func => sub {
     my ($count) = @_;
     my @primitives;
     my $aref = perimeterpqs_list_new();
     my $max_perimeter = 0;
     for (;;) {
       my $elem = perimeterpqs_list_next($aref);
       my ($perimeter,$p,$q) = @$elem;
       last if @primitives >= $count && $perimeter != $max_perimeter;
       $max_perimeter = $perimeter;
       push @primitives, [$p*$p-$q*$q, 2*$p*$q, $p*$p+$q*$q];
     }
     my @multiples;
     foreach my $triple (@primitives) {
       my ($A_primitive,$B_primitive,$C_primitive) = @$triple;
       for (my $i = 1; ; $i++) {
         my ($A,$B,$C) = ($i*$A_primitive, $i*$B_primitive, $i*$C_primitive);
         last if $A+$B+$C > $max_perimeter;
         push @multiples, [$A,$B,$C];
       }
     }
     @multiples = sort triple_cmp_by_perimeter_and_decreasing_area @multiples;
     # @multiples = sort triple_cmp_by_perimeter_and_even @multiples;
     my @got = map {sort {$a<=>$b} @$_} @multiples;
     $#got = $count-1;

     if (0) {
       open OUT, '> /tmp/x.txt' or die;
       foreach my $i (0 .. $#got) {
         print OUT $i+1," ",$got[$i],"\n" or die;
       }
       close OUT or die;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A024364 - ordered perimeter, with duplications

# $elem is an arrayref [$perimeter,$p,$q, ...].
# Return a corresponding [$perimeter,$p,$next_q, ...]
# which is the next bigger primitive p,q, and its corresponding perimeter.
sub perimeterpq_next_q {
  my ($elem) = @_;
  my ($perimeter,$p,$q) = @$elem;
  my $first = ($q==0);
  for ($q++; $q < $p; $q++) {
    if (pq_acceptable($p,$q)) {
      return [perimeter_of_pq($p,$q), $p, $q, $first];
    }
  }
  return ();
}
sub perimeterpq_cmp_perimeter_then_even {
  my ($a,$b) = @_;
  return $a->[0] <=> $b->[0]
    || $a->[1]*$a->[2] <=> $b->[1]*$b->[2]
    || die "oops, same perimeter and even";
}
sub perimeterpqs_list_new {
  my $p = 2;
  my $q = 1;
  tie my @pending, "Tie::Array::Sorted", \&perimeterpq_cmp_perimeter_then_even;
  push @pending, [perimeter_of_pq($p,$q), $p, $q, 1];
  return \@pending;
}
sub perimeterpqs_list_next {
  my ($aref) = @_;
  my $elem = shift @$aref;
  my ($perimeter,$p,$q,$first) = @$elem;
  push @$aref, perimeterpq_next_q($elem);
  if ($first) {
    ### push new: $p+1
    push @$aref, perimeterpq_next_q([0, $p+1, 0]);
  }
  return $elem;
}

MyOEIS::compare_values
  (anum => 'A024364',
   # max_count => 121,
   func => sub {
     my ($count) = @_;
     my @got;
     my $aref = perimeterpqs_list_new();
     while (@got < $count) {
       my $elem = perimeterpqs_list_next($aref);
       ### list elem: $elem
       my ($perimeter,$p,$q) = @$elem;
       push @got, $perimeter;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A070109 - how many primitives with perimeter n
# A078926 - how many primitives with perimeter 2n  (since always even)
#   includes factorizing for divisors as solutions

# Return a list of [$perimeter, $p, $q]
# of all perimeters <= $max_perimeter, in no particular order
sub perimeterpq_list {
  my ($max_perimeter) = @_;
  my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
  my @got;

  # perimeter = 2*p*(p+q) <= M
  #             2*p^2 < M
  #             p < sqrt(M/2)     limit for p
  # then
  #             p+q <= M/2/p
  #             q <= M/2/p - p
  foreach my $p (2 .. int(sqrt($max_perimeter/2))) {
    foreach my $q (1 .. $p) {
      my $perimeter = perimeter_of_pq($p,$q);
      last if $perimeter > $max_perimeter;
      if ($path->xy_is_visited($p,$q)) {
        push @got, [$perimeter,$p,$q];
      }
    }
  }
  return @got;
}

# Return a list of counts for P = 0 .. $max_perimeter where $counts[$P] is
# how many primitive Pythagorean triples have perimeter $P.
sub perimeters_counts_array {
  my ($max_perimeter) = @_;
  my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
  my @got;
  foreach my $elem (perimeterpq_list($max_perimeter)) {
    my ($perimeter,$p,$q) = @$elem;
    $got[$perimeter]++;
  }
  foreach my $i (0 .. $max_perimeter) { $got[$i] ||= 0; }
  return @got;

  # Tree descents don't really do much in terms of perimeter, may as well
  # loop over p and q directly.
  #
  # my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
  # my @pending = Math::BigInt->new($path->n_start);
  # while (defined (my $n = pop @pending)) {
  #   my ($p,$q) = $path->n_to_xy($n);
  #   my $perimeter = perimeter_of_pq($p,$q);
  #   if ($perimeter <= $max_perimeter) {
  #     $got[$perimeter]++;
  #   }
  #   my $C = $p*$p + $q*$q;
  #   if ($C < $max_perimeter) {
  #     push @pending, $path->tree_n_children($n);
  #   }
  # }
}

# A078926 - count of primtive triples with perimeter 2*n
# http://oeis.org/A078926/b078926.txt
# to n=158730 1.3mb
MyOEIS::compare_values
  (anum => q{A078926},
   # max_count => 1000,
   func => sub {
     my ($count) = @_;
     # its OFFSET=1 so 1..$count is perimeters 2..2*$count
     my @got = perimeters_counts_array(2*$count);
     @got = @got[map {2*$_} 1 .. $count];
     return \@got;
   });
MyOEIS::compare_values
  (anum => q{A078926},
   # max_count => 1000,
   func => sub {
     my ($count) = @_;
     my @got;
     my $aref = perimeterpqs_list_new();
     for (;;) {
       my $elem = perimeterpqs_list_next($aref);
       ### list elem: $elem
       my ($perimeter,$p,$q) = @$elem;
       $perimeter /= 2;
       last if $perimeter > $count;
       $got[$perimeter]++;
     }
     foreach my $i (0 .. $count) { $got[$i] ||= 0; }
     # its OFFSET=1 so 1..$count is perimeters 2..2*$count
     shift @got;
     return \@got;
   });

# A070109 - count of primtive triples with perimeter n
# ~/OEIS/b070109.txt  20000 entries, 150k
MyOEIS::compare_values
  (anum => q{A070109},
   # max_count => 1000,
   func => sub {
     my ($count) = @_;
     my @got = perimeters_counts_array($count);
     shift @got;  # no n=0
     return \@got;
   });
MyOEIS::compare_values
  (anum => q{A070109},
   # max_count => 1000,
   func => sub {
     my ($count) = @_;
     my @got;
     my $aref = perimeterpqs_list_new();
     for (;;) {
       my $elem = perimeterpqs_list_next($aref);
       ### list elem: $elem
       my ($perimeter,$p,$q) = @$elem;
       last if $perimeter > $count;
       $got[$perimeter]++;
     }
     foreach my $i (0 .. $count) { $got[$i] ||= 0; }
     # its OFFSET=1 so perimeters 1..$count
     shift @got;
     return \@got;
   });


#------------------------------------------------------------------------------
# A103606 - primitive triples by perimeter and then by even member

# As noted by Wolfdieter Lang in deciding the ordering of A103606, if two
# triples have the same perimeter and even member then they are equal.
# p^2 - q^2
# 2pq
# p^2 + q^2
# perimeter 2*p^2 + 2pq = 2*x^2 + 2xy
# and evens 2pq=2xy is 2*p^2=2*x^2 and so p=x and q=y
#
# perimeter = 2*p*(p+q)

MyOEIS::compare_values
  (anum => q{A103606},
   max_count => 500,
   name => 'primitive triples by perimeter then even member',
   func => sub {
     my ($count) = @_;
     my @got;
     my $aref = perimeterpqs_list_new();
     while (@got < $count) {
       my $elem = perimeterpqs_list_next($aref);
       my ($perimeter,$p,$q) = @$elem;
       push @got, sort {$a<=>$b} $p*$p-$q*$q, 2*$p*$q, $p*$p+$q*$q;
     }
     $#got = $count-1;
     return \@got;
   });

# This is not particularly efficient.  A loop for perimeter/2 = p*(p+q)
# based on factorizing is much better.  It helps a bit to truncate @pending
# so it doesn't keep more than the remaining wanted number of triples.
#
MyOEIS::compare_values
  (anum => q{A103606},
   max_count => 500,
   bfilename => '/tmp/b103606-mine.txt',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     tie my @pending, "Tie::Array::Sorted", \&by_perimeter_cmp;
     push @pending, by_perimeter_n_to_elem($path,
                                           Math::BigInt->new($path->n_start));
     my $want_more_triples = int($count/3) + 30;
     while (@got < $count) {
       # print scalar(@pending)," ",scalar(@got),"\r";
       ### @pending
       my $elem = shift @pending;
       my ($perimeter,$B,$triple,$n) = @$elem;

       # if (@got == 21147) {
       #   MyTestHelpers::diag(by_perimeter_str($elem));
       # }

       push @got, @$triple;
       $want_more_triples--;

       push @pending,
         map {by_perimeter_n_to_elem($path,$_)} $path->tree_n_children($n);
       if ($#pending > $want_more_triples) {
         $#pending = $want_more_triples;  # truncate
       }
     }
     $#got = $count-1;
     return \@got;
   });

sub by_perimeter_cmp {
  my ($a,$b) = @_;
  return $a->[0] <=> $b->[0]
    || $a->[1] <=> $b->[1]
    || die("oops, same perimeter and even:\n",
           by_perimeter_str($a),"\n",
           by_perimeter_str($b));
}
sub by_perimeter_str {
  my ($elem) = @_;
  my ($perimeter,$B,$triple,$n) = @$elem;
  return "$perimeter,$B,[".join(',',@$triple)."],$n (".ref($n)||'';
}
sub by_perimeter_n_to_elem {
  my ($path,$n) = @_;
  ref $n or die "not a ref: $n";
  my ($p,$q) = $path->n_to_xy($n);
  my $A = $p*$p - $q*$q;
  my $B = 2*$p*$q;
  my $C = $p*$p + $q*$q;
  my $perimeter = $A + $B + $C;
  return [ $perimeter,                     # sort perimeter
           $B,                             # then even term
           [min($A,$B), max($A,$B), $C],   # triple
           $n ];                           # n
  
  # max($A,$B),
}

# p^2-q^2 > pq
# p^2 > pq + q^2
# p^2 - pq > q^2
# p(p-q) > q^2

# GP-Test  for(n=1,5000, \
# GP-Test    my(d=divisors(n)); \
# GP-Test    if(#d%2, \
# GP-Test      my(m=d[(#d+1)/2]); \
# GP-Test      m^2==n || error(d); \
# GP-Test      , \
# GP-Test      d[#d/2]*d[#d/2+1]==n || error(d); \
# GP-Test      )); \
# GP-Test  1

# GP-Test  for(n=1,5000, \
# GP-Test    my(f=factor(n), \
# GP-Test       d=divisors(n)); \
# GP-Test    d=select(x->gcd(x,n/x)==1,d); \
# GP-Test    for(i=1,matsize(f)[1], f[i,1]=f[i,1]^f[i,2]; f[i,2]=1); \
# GP-Test    divisors(f) == d || error()); \
# GP-Test  1

# GP-DEFINE  A103606_vector(len) = {
# GP-DEFINE    my(debug=0);
# GP-DEFINE    my(ret=vector(len+(-len%3)),  \\ up to a multiple of 3
# GP-DEFINE       upto=0);                   \\ ready for pre-increment
# GP-DEFINE    for(H=6,oo,                   \\ half H=perimeter/2
# GP-DEFINE      my(d=factor(H),prev_B=0);
# GP-DEFINE      for(i=1,matsize(d)[1], d[i,1]=d[i,1]^d[i,2]; d[i,2]=1);
# GP-DEFINE      d=divisors(d);
# GP-DEFINE      if(debug,print(d));
# GP-DEFINE      for(i=(#d+3)\2,#d,      \\ ascending s
# GP-DEFINE        my(s=d[i],                \\ p smaller
# GP-DEFINE           p=d[#d-i+1],           \\ s bigger  p*s==H
# GP-DEFINE           q=s-p);
# GP-DEFINE
# GP-DEFINE        p*s==H || error();        \\ 2*p*(p+q) = perimeter
# GP-DEFINE        s>p || error();
# GP-DEFINE        q>=1 || error(d);
# GP-DEFINE        gcd(s,p)==1 || error();
# GP-DEFINE
# GP-DEFINE        \\ p decreasing, q=s-p increasing, so once p>q fails
# GP-DEFINE        \\ it fails for all the rest of this d
# GP-DEFINE        p>q || break;
# GP-DEFINE
# GP-DEFINE        s%2 || next;
# GP-DEFINE        \\ (s%2 && gcd(s,p)==1) || next;
# GP-DEFINE        if(debug,print("  "p" "q"  "d" "i));
# GP-DEFINE        my(P=sqr(p),Q=sqr(q), A=P-Q, B=2*p*q, C=P+Q);
# GP-DEFINE
# GP-DEFINE        (A>0 && B>0 && C>0) || error();
# GP-DEFINE        A^2+B^2==C^2 || error(A" "B" "C);
# GP-DEFINE        B > prev_B || error(d);
# GP-DEFINE        A+B+C == 2*H || error();
# GP-DEFINE        H == p*(p+q) || error();
# GP-DEFINE        B+2*p^2 == 2*H || error();
# GP-DEFINE        B == 2*(H - p^2) || error();
# GP-DEFINE
# GP-DEFINE        if(debug,print("  push "A" "B" "C"   "p" "q));
# GP-DEFINE        ret[upto++] = min(A,B);
# GP-DEFINE        ret[upto++] = max(A,B);
# GP-DEFINE        ret[upto++] = P+Q; if(upto>=len,break(2))));
# GP-DEFINE    Vec(ret,len);
# GP-DEFINE  }
# A103606_vector(27)
# OEIS_samples("A103606")
# GP-Test  vector(50,len, #A103606_vector(len)) == \
# GP-Test  vector(50,len, len)
# GP-Test  my(v=OEIS_samples("A103606")); A103606_vector(#v) == v
# my(g=OEIS_bfile_gf("A103606")); g==Polrev(A103606_vector(poldegree(g)))
# poldegree(OEIS_bfile_gf("A103606"))

# my(v=A103606_vector(30000)); \
# system("rm         /tmp/b103606-mine.txt"); \
# for(n=1,#v, write("/tmp/b103606-mine.txt",n," ",v[n])); \
# system("ls -l      /tmp/b103606-mine.txt");


# GP-DEFINE  \\ Though nice to generate in perimeter order, probably
# GP-DEFINE  \\ easier and faster to go all $p,$q like perimeterpq_list()
# GP-DEFINE  \\ and sort.
# GP-DEFINE  \\ Each column of q would be in ascending order of even leg,
# GP-DEFINE  \\ so can setunion() rather than full sort.
# GP-DEFINE  \\ Would have to keep going p until its smallest 2*p*(p+1)
# GP-DEFINE  \\ perimeter is bigger than the perimeter at the target len.
# GP-DEFINE
# GP-DEFINE  A103606_vector_compact(len) = {
# GP-DEFINE    my(ret=vector(len+(-len%3)),upto=0);
# GP-DEFINE    for(H=6,oo, my(f=factor(H));  \\ half perimeter
# GP-DEFINE      for(i=1,matsize(f)[1], f[i,1]=f[i,1]^f[i,2]; f[i,2]=1);
# GP-DEFINE      my(d=divisors(f));   \\ no split prime powers
# GP-DEFINE      for(i=(#d+3)\2,#d,   \\ ascending even leg "B"
# GP-DEFINE        my(s=d[i],p=d[#d-i+1],q=s-p);  \\ p*(p+q)==H
# GP-DEFINE        p>q || break; s%2 || next;
# GP-DEFINE        [ret[upto++],ret[upto++]] = vecsort([p^2-q^2, 2*p*q]);
# GP-DEFINE        ret[upto++] = p^2+q^2;
# GP-DEFINE        if(upto>=len,return(Vec(ret,len)))));
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A103606")); A103606_vector_compact(#v) == v
# GP-Test  vector(50,len, #A103606_vector_compact(len)) == \
# GP-Test  vector(50,len, len)
# GP-Test  A103606_vector_compact(30000) == \
# GP-Test  A103606_vector(30000)

# C = 2*L
# C = L+L+sqrt(2)*L
#   = (2+sqrt(2))*L
# L needs 2*L <= C <= (2+sqrt(2))*L
# perimeter = 2*C
# perimeter = (1 + 2*1/sqrt(2)) * C
# (1 + 2*1/sqrt(2)) = 2.41421

# C = p^2 + q^2 > p^2 + 1
# C = p^2 + q^2 < 2*p^2      C/2 < p^2 < C-1
# so given C, have p^2 > C/2
# given p, have perimeter = 2*p*(p+q) > 2*p^2 > C
#


#------------------------------------------------------------------------------
# A094194  C leg sorted on p

MyOEIS::compare_values
  (anum => 'A094194',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $p = 2; ; $p++) {
       for (my $q = 1; $q < $p; $q++) {
         if (pq_acceptable($p,$q)) {
           if (@got >= $count) { return \@got; }
           push @got, $p*$p + $q*$q;
         }
       }
     }
   });

# A120097 bigger leg sorted on p
MyOEIS::compare_values
  (anum => 'A120097',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $p = 2; ; $p++) {
       for (my $q = 1; $q < $p; $q++) {
         if (pq_acceptable($p,$q)) {
           if (@got >= $count) { return \@got; }
           my $A = $p*$p - $q*$q;
           my $B = 2*$p*$q;
           push @got, max($A,$B);
         }
       }
     }
   });

# A120098 smaller leg sorted on p
MyOEIS::compare_values
  (anum => 'A120098',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $p = 2; ; $p++) {
       for (my $q = 1; $q < $p; $q++) {
         if (pq_acceptable($p,$q)) {
           if (@got >= $count) { return \@got; }
           my $A = $p*$p - $q*$q;
           my $B = 2*$p*$q;
           push @got, min($A,$B);
         }
       }
     }
   });


#------------------------------------------------------------------------------
# A321782 - UAD p by rows

# for p (but not for others) HtoL and LtoH are the same sequence
foreach my $digit_order ('HtoL', 'LtoH') {
  MyOEIS::compare_values
      (anum => 'A321782',
       func => sub {
         my ($count) = @_;
         my @got;
         my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
         ### $path
         for (my $n = $path->n_start; @got < $count; $n++) {
           my ($x,$y) = $path->n_to_xy($n);
           push @got, $x;
         }
         return \@got;
       });
}

# A321783 - UAD q by rows
MyOEIS::compare_values
  (anum => 'A321783',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

# A321784 - UAD p+q by rows
MyOEIS::compare_values
  (anum => 'A321784',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x + $y;
     }
     return \@got;
   });

# A321785 - UAD p-q by rows
MyOEIS::compare_values
  (anum => 'A321785',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x - $y;
     }
     return \@got;
   });


#------------------------------------------------------------------------------

# A321768 - UAD A leg
MyOEIS::compare_values
  (anum => 'A321768',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x;
     }
     return \@got;
   });

# A321769 - UAD A leg
MyOEIS::compare_values
  (anum => 'A321769',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

# A321770 - UAD C leg
MyOEIS::compare_values
  (anum => 'A321770',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AC');
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A002315 Pell(2k) - Pell(2k-1), is row P-Q     ("NSW" numbers)

MyOEIS::compare_values
  (anum => 'A002315',
   max_count => 11,
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = 0; @got < $count; $depth++) {
       my $total = 0;
       foreach my $n ($path->tree_depth_to_n($depth)
                      .. $path->tree_depth_to_n_end($depth)) {
         my ($x,$y) = $path->n_to_xy($n);
         $total += $x - $y;
       }
       push @got, $total;
     }
     return \@got;
   });

# A001541 is row P+Q   even Pell + odd Pell
#   = A001542 + A001653
# my(s=OEIS_samples("A001541")[^1], \
#    e=OEIS_samples("A001542")[^1], \
#    o=OEIS_samples("A001653"), \
#    len=vecmin([#s,#e,#o])); \
# e[1..len] + o[1..len] == s[1..len]
#
MyOEIS::compare_values
  (anum => 'A001541',
   max_count => 11,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = 0; @got < $count; $depth++) {
       my $x_total = 0;
       foreach my $n ($path->tree_depth_to_n($depth)
                      .. $path->tree_depth_to_n_end($depth)) {
         my ($x,$y) = $path->n_to_xy($n);
         $x_total += $x + $y;
       }
       push @got, $x_total;
     }
     return \@got;
   });

# A001653 odd Pells, is row Q total
MyOEIS::compare_values
  (anum => 'A001653',
   max_count => 11,
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = 0; @got < $count; $depth++) {
       my $x_total = 0;
       foreach my $n ($path->tree_depth_to_n($depth)
                      .. $path->tree_depth_to_n_end($depth)) {
         my ($x,$y) = $path->n_to_xy($n);
         $x_total += $y;
       }
       push @got, $x_total;
     }
     return \@got;
   });

# A001542 even Pell, is row P total
MyOEIS::compare_values
  (anum => 'A001542',
   max_count => 11,
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = 0; @got < $count; $depth++) {
       my $x_total = 0;
       foreach my $n ($path->tree_depth_to_n($depth)
                      .. $path->tree_depth_to_n_end($depth)) {
         my ($x,$y) = $path->n_to_xy($n);
         $x_total += $x;
       }
       push @got, $x_total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A000244 = 3^n is N of A repeatedly in middle of row

MyOEIS::compare_values
  (anum => 'A000244',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new;
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       push @got, ($path->tree_depth_to_n_end($depth)
                   + $path->tree_depth_to_n($depth) + 1) / 2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A052940  matrix T repeatedly coordinate P, binary 101111111111 = 3*2^n-1
MyOEIS::compare_values
  (anum => 'A052940',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(1); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });
# A055010  same
MyOEIS::compare_values
  (anum => 'A055010',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });
# A083329  same
MyOEIS::compare_values
  (anum => 'A083329',
   max_count => 200,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });
# A153893  same
MyOEIS::compare_values
  (anum => 'A153893',
   max_count => 200,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });

# A093357  matrix T repeatedly coordinate B, binary 10111..111000..000
MyOEIS::compare_values
  (anum => 'A093357',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $y;
     }
     return \@got;
   });

# A134057  matrix T repeatedly coordinate A, binomial(2^n-1,2)
#   binary 111..11101000..0001
MyOEIS::compare_values
  (anum => 'A134057',
   func => sub {
     my ($count) = @_;
     my @got = (0,0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A106624  matrix K3 repeatedly P,Q pairs 2^k-1,2^k

MyOEIS::compare_values
  (anum => 'A106624',
   max_count => 200,    # touch slow to 5000 values
   func => sub {
     my ($count) = @_;
     my @got = (1,0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054881  matrix K2 repeatedly "B" coordinate
MyOEIS::compare_values
  (anum => 'A054881',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     my @got = (1,0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $y;
     }
     return \@got;
   });

# A015249  matrix K2 repeatedly "A" coordinate
MyOEIS::compare_values
  (anum => 'A015249',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });
# A084152 same
MyOEIS::compare_values
  (anum => 'A084152',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     my @got = (0,0,1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });
# A084175 same
MyOEIS::compare_values
  (anum => 'A084175',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     my @got = (0,1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A085601 = matrix K1 repeatedly "C" coordinate, binary 10010001
MyOEIS::compare_values
  (anum => 'A085601',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AC');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });

# A028403 = matrix K1 repeatedly "B" coordinate, binary 10010000
MyOEIS::compare_values
  (anum => 'A028403',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });
# A007582 = matrix K1 repeatedly "B/4" coordinate, binary 1001000
MyOEIS::compare_values
  (anum => 'A007582',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y/4;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A084159  matrix A repeatedly "A" coordinate, Pell oblongs
MyOEIS::compare_values
  (anum => 'A084159',
   max_count => 200,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });
# A046727  matrix A repeatedly "A" coordinate
MyOEIS::compare_values
  (anum => 'A046727',
   max_count => 200,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });

# A046729  matrix A repeatedly "B" coordinate
MyOEIS::compare_values
  (anum => 'A046729',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $y;
     }
     return \@got;
   });

# A001653  matrix A repeatedly "C" coordinate
MyOEIS::compare_values
  (anum => 'A001653',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AC');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $y;
     }
     return \@got;
   });

# A001652  matrix A repeatedly "S" smaller coordinate
MyOEIS::compare_values
  (anum => 'A001652',
   # max_count => 50,
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'SM');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });

# A046090  matrix A repeatedly "M" coordinate
MyOEIS::compare_values
  (anum => 'A046090',
   max_count => 200,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'SM');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $y;
     }
     return \@got;
   });

# A000129  matrix A repeatedly "P" coordinate
MyOEIS::compare_values
  (anum => 'A000129',
   max_count => 200,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got = (0,1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A099776 = matrix U repeatedly "C" coordinate
MyOEIS::compare_values
  (anum => 'A099776',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AC');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });
# A001844 centred squares same
MyOEIS::compare_values
  (anum => 'A001844',
   max_count => 200,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AC');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });

# A046092  matrix U repeatedly "B" coordinate = 4*triangular
MyOEIS::compare_values
  (anum => 'A046092',
   max_count => 200,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000466 matrix D repeatedly "A" coordinate = 4n^2-1

MyOEIS::compare_values
  (anum => 'A000466',
   max_count => 200,   # touch slow
   func => sub {
     my ($count) = @_;
     my @got = (-1);
     my $path = Math::PlanePath::PythagoreanTree->new;
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A058529 - all prime factors == +/-1 mod 8
#   is differences mid-small legs

MyOEIS::compare_values
  (anum => 'A058529',
   max_count => 35,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'SM');
     my %seen;
     for (my $n = $path->n_start; $n < 100000; $n++) {
       my ($s,$m) = $path->n_to_xy($n);
       my $diff = $m - $s;
       $seen{$diff} = 1;
     }
     my @got = sort {$a<=>$b} keys %seen;
     $#got = $count-1;
     return \@got;
   });

#------------------------------------------------------------------------------
# A003462 = (3^n-1)/2 is tree_depth_to_n_end()

MyOEIS::compare_values
  (anum => 'A003462',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new;
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n_end($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
