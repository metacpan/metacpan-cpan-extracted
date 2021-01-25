#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018, 2020 Kevin Ryde

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
use Test;
plan tests => 12;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::ZOrderCurve;
use Math::PlanePath::Diagonals;

# GP-DEFINE  read("my-oeis.gp");


#------------------------------------------------------------------------------
# Radix = 3

# GP-DEFINE  \\ A163325  ternary X
# GP-DEFINE  X3(n) = fromdigits(digits(n,9)%3,3);
# GP-DEFINE  A163325(n) = X3(n);
# GP-Test  my(v=OEIS_samples("A163325"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A163325(n)) == v
# GP-Test  my(g=OEIS_bfile_gf("A163325")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A163325(n)))
#
# GP-DEFINE  \\ A163326  ternary Y
# GP-DEFINE  Y3(n) = fromdigits(digits(n, 9)\3, 3);
# GP-DEFINE  A163326(n) = Y3(n);
# GP-Test  my(v=OEIS_samples("A163326"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A163326(n)) == v
# GP-Test  my(g=OEIS_bfile_gf("A163326")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A163326(n)))

# GP-DEFINE  \\ 00 01 02 above ternary
# GP-DEFINE  A037314(n) = fromdigits(digits(n,3), 9);
# GP-Test  my(v=OEIS_samples("A037314"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A037314(n)) == v
#
# GP-DEFINE  \\ 00 10 20 below ternary
# GP-DEFINE  A208665(n) = fromdigits(digits(n,3), 9) * 3;
# GP-Test  my(v=OEIS_samples("A208665"));  /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A208665(n)) == v
#
# GP-DEFINE  \\ 00 11 22 duplicate ternary digits
# GP-DEFINE  Dup3(n) = fromdigits(digits(n,3),9)<<2;
# GP-DEFINE  A338086(n) = Dup3(n);
# GP-Test  my(v=OEIS_samples("A338086"));  /* OFFSET=1 */ \
# GP-Test    vector(#v,n,n--; A338086(n)) == v
# GP-Test  vector(3^7,n,n--; X3(Dup3(n))) == \
# GP-Test  vector(3^7,n,n--; n)
# GP-Test  vector(3^7,n,n--; Y3(Dup3(n))) == \
# GP-Test  vector(3^7,n,n--; n)

# GP-Test  vector(3^7,n,n--; Dup3(n)) == \
# GP-Test  vector(3^7,n,n--; A037314(n) + A208665(n))
# GP-Test  vector(3^7,n,n--; Dup3(n)) == \
# GP-Test  vector(3^7,n,n--; 4*A037314(n))
# GP-Test  vector(3^7,n,n--; Dup3(n)) == \
# GP-Test  vector(3^7,n,n--; (4/3)*A208665(n))

# GP-DEFINE  to_ternary(n)=fromdigits(digits(n,3))*sign(n);
# GP-DEFINE  from_ternary(n)=fromdigits(digits(n),3);

# GP-Test  from_ternary(2201)  == 73
# GP-Test  from_ternary(22220011)  == 6484
# GP-Test  Dup3(73)                == 6484
# GP-Test  fromdigits([8,8,0,4],9) == 6484

# system("rm /tmp/b338086.txt"); \
# my(len=3^8); print("len "len" last "len-1); \
# for(n=0,len-1, write("/tmp/b338086.txt",n," ",A338086(n))); \
# system("ls -l /tmp/b338086.txt");
# GP-Test  my(g=OEIS_bfile_gf("A338086")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A338086(n)))
# poldegree(OEIS_bfile_gf("A338086"))
# 3^8-1

# poldegree(OEIS_bfile_gf("A163325"))
# poldegree(OEIS_bfile_gf("A163326"))
# poldegree(OEIS_bfile_gf("A037314"))
# poldegree(OEIS_bfile_gf("A208665"))
# poldegree(OEIS_bfile_gf("A163338"))
# poldegree(OEIS_bfile_gf("A163339"))  \\ Peano by diagonals 3^8


#------------------------------------------------------------------------------
# Radix = 10

# GP-DEFINE  X10(n) = fromdigits(digits(n,100)%10,10);
# GP-DEFINE  Y10(n) = fromdigits(digits(n,100)\10,10);

# GP-DEFINE  \\ 00 01 02 zero digit above each decimal
# GP-DEFINE  A051022(n) = fromdigits(digits(n),100);
# GP-Test  my(v=OEIS_samples("A051022"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A051022(n)) == v
# GP-Test  my(g=OEIS_bfile_gf("A051022")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A051022(n)))
# poldegree(OEIS_bfile_gf("A051022"))
# ~/OEIS/b051022.txt
#
# GP-Test  /* Reinhard Zumkeller in A051022 */ \
# GP-Test  vector(20000,n,n--; A051022(n)) == \
# GP-Test  vector(20000,n,n--; if(n<10,n, A051022(floor(n/10))*100 + n%10))
# Past n<=10 was wrong at n=10
# vector(20,n,n--; A051022(n))
# vector(20,n,n--; if(n<=10,n, A051022(floor(n/10))*100 + n%10))

# GP-Test  /* A092908 = primes in A051022, every second digit 0 */ \
# GP-Test  my(v=OEIS_samples("A092908"));  /* OFFSET=0 */ \
# GP-Test  my(limit=v[#v], got=List([])); \
# GP-Test  for(n=0,oo, my(t=A051022(n)); if(t>limit,break); \
# GP-Test    if(isprime(t), listput(got,t))); \
# GP-Test  Vec(got) == v

# GP-Test  /* A092909 = A051022(primes), indices with 0 digits */ \
# GP-Test  my(v=OEIS_samples("A092909"));  /* OFFSET=0 */ \
# GP-Test    apply(A051022,primes(#v)) == v

#------
# GP-DEFINE  \\ 00 11 22 duplicate digits decimal
# GP-DEFINE  A338754(n) = fromdigits(digits(n),100)*11;
# GP-Test  my(v=OEIS_samples("A338754"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A338754(n)) == v
# GP-Test  my(g=OEIS_bfile_gf("A338754")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A338754(n)))
# poldegree(OEIS_bfile_gf("A338754"))
# GP-Test  my(a=A338754); a(5517) == 55551177

# size match A051022
# system("rm /tmp/b338754.txt"); \
# my(len=10^4+1); print("len "len" last "len-1); \
# for(n=0,len-1, write("/tmp/b338754.txt",n," ",A338754(n))); \
# system("ls -l /tmp/b338754.txt");
# GP-Test  my(g=OEIS_bfile_gf("A338754")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A338754(n)))
# poldegree(OEIS_bfile_gf("A338754"))
# 3^8-1

# GP-Test  vector(10000,n,n--; A051022(n)) == \
# GP-Test  vector(10000,n,n--; A338754(n)/11)
#
# GP-Test  vector(10000,n,n--; A338754(n)) == \
# GP-Test  vector(10000,n,n--; 11*A051022(n))


#------------------------------------------------------------------------------
# A044836 decimal more even length runs than odd length runs
#
# not the same as A338754 only even length runs

# GP-DEFINE  vector_run_lengths(v) = {
# GP-DEFINE    if(#v==0,return([]));
# GP-DEFINE    my(l=List([]),run=1);
# GP-DEFINE    for(i=2,#v, if(v[i]==v[i-1],run++, listput(l,run);run=1));
# GP-DEFINE    listput(l,run);
# GP-DEFINE    Vec(l);
# GP-DEFINE  }
# GP-Test  vector_run_lengths([]) == []
# GP-Test  vector_run_lengths([99]) == [1]
# GP-Test  vector_run_lengths([99,99,99]) == [3]
# GP-Test  vector_run_lengths([99,7,7,99]) == [1,2,1]

# GP-DEFINE  isA044836(n) = {
# GP-DEFINE    my(v = vector_run_lengths(digits(n)) % 2,
# GP-DEFINE       num_odd = hammingweight(v),
# GP-DEFINE       num_even = #v - num_odd);
# GP-DEFINE    num_even > num_odd;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A044836")); \
# GP-Test    select(isA044836, [0..v[#v]]) == v
# GP-Test  my(v=Vecrev(OEIS_bfile_gf("A044836")/x)); /* OFFSET=1 */ \
# GP-Test    /* v=v[1..100]; */ \
# GP-Test    my(got=List([])); \
# GP-Test    for(n=0,v[#v], if(isA044836(n), listput(got,n))); \
# GP-Test    Vec(got)==v
# poldegree(OEIS_bfile_gf("A044836"))
# ~/OEIS/b044836.txt

# GP-Test  /* Remy Sigrist in A044836 */ \
# GP-Test  my(is=(n,base=10)-> my (v=0); while (n, my (d=n%base,w=0); \
# GP-Test       while (n%base==d, n\=base; w++); v+=(-1)^w); v>0); \
# GP-Test  vector(10000,n,n--; is(n)) == \
# GP-Test  vector(10000,n,n--; isA044836(n))

# GP-DEFINE  A044836(n) = {
# GP-DEFINE    n>=1||error();
# GP-DEFINE    my(ret=-1);
# GP-DEFINE    while(1,
# GP-DEFINE      until(isA044836(ret),ret++);
# GP-DEFINE      n--; if(n==0,return(ret)));
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A044836")); \
# GP-Test    vector(#v,n, A044836(n)) == v  /* OFFSET=1 */

# GP-Test  A044836(100) ==  10011
# GP-Test  A338754(100) == 110000  
# GP-Test  isA044836(110000) == 1
# vector(100,n, A338754(n)) - \
# vector(100,n, A044836(n))
# GP-Test  vector(99,n, A338754(n)) == \
# GP-Test  vector(99,n, A044836(n))

#--------
# GP-DEFINE  \\ count num even length runs
# GP-DEFINE  A044941(n) = {
# GP-DEFINE    my(v = vector_run_lengths(digits(n)) % 2,
# GP-DEFINE       num_odd = hammingweight(v));
# GP-DEFINE    #v - num_odd;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A044941")); \
# GP-Test    vector(#v,n, A044941(n)) == v  /* OFFSET=1 */
# GP-Test  my(g=OEIS_bfile_gf("A044941")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A044941(n)))
# poldegree(OEIS_bfile_gf("A044941"))
# ~/OEIS/b044941.txt
# GP-Test  A044941(1100) == 2
# GP-Test  A044941(11000) == 1
# GP-Test  A044941(110000) == 2
# GP-Test  A044941(11000011) == 3
# GP-Test  A044941(110000211) == 3
# GP-Test  A044941(1100002113) == 3
# GP-Test  A044941(11000021133333) == 3
# GP-Test  A044941(1000021133333) == 2

# GP-DEFINE  A044941_compact(n) = {
# GP-DEFINE    if(n==0,0, my(v=digits(n),p=1,ret=0); 
# GP-DEFINE      for(i=2,#v, if(v[i]!=v[i-1], ret+=(i-p+1)%2; p=i)); 
# GP-DEFINE      ret+(#v-p)%2);
# GP-DEFINE  }
# GP-DEFINE  \\ print("run p="p" to i="i);
# GP-DEFINE  \\ print("final p="p" to #v="#v);
# GP-Test  vector(10000,n,n--; A044941(n)) == \
# GP-Test  vector(10000,n,n--; A044941_compact(n))
# GP-Test  A044941_compact(0) == 0
# GP-Test  for(rep=1,1000, \
# GP-Test    my(runs=vector(random(20)+1,i, random(10)+1), \
# GP-Test       vecs=vector(#runs,i, vector(runs[i],j, i%9+1)), \
# GP-Test       n=fromdigits(if(#vecs==0,[],concat(vecs)))); \
# GP-Test    A044941_compact(n) == A044941(n) || error(n)); \
# GP-Test    1;
# my(c=0); for(n=0,1000000, if(A044941_compact(n) != A044941(n), print(n); if(c++>20,break)));
# A044941(11)
# A044941(111)
# A044941_compact(110011001100)
# A044941_compact(11000)
# vector(4,k,k++; sum(n=1,10^k-1, A044941(n)))
# vector(4,k,k++; sum(n=1,10^k, A044941(n)))
# 11, 1100, 110011, 11001100, 1100110011
# apply(A044941, [11, 1100, 110011, 11001100, 1100110011])
# A153435
# my(t=0); for(n=1,1000000, if(A044941(n)==t, print(t" "n); t++))

#------------------------------------------------------------------------------
# A057300 -- self-inverse permutation N at transpose Y,X, radix=2
# A163327 -- N at transpose Y,X, radix=3
# A126006 -- N at transpose Y,X, radix=4
# A217558 -- N at transpose Y,X, radix=16, conceived as 1-byte nibble swap

# more bases
# not in OEIS: 5,10,15,20,1,6,11,16,21,2,7,12,17
# not in OEIS: 6,12,18,24,30,1,7,13,19,25,31,2,8
# not in OEIS: 7,14,21,28,35,42,1,8,15,22,29,36
# not in OEIS: 8,16,24,32,40,48,56,1,9,17,25,33
# not in OEIS: 9,18,27,36,45,54,63,72,1,10,19,28
# not in OEIS: 10,20,30,40,50,60,70,80,90,1,11,21,31,41,51,61,71,81,91

foreach my $elem (['A057300', 2],
                  ['A163327', 3],
                  ['A126006', 4],
                  ['A217558', 16],
                 ) {
  my ($anum,$radix) = @$elem;

  MyOEIS::compare_values
      (anum => $anum,
       func => sub {
         my ($count) = @_;
         my @got;
         my $path = Math::PlanePath::ZOrderCurve->new (radix => $radix);
         for (my $n = $path->n_start; @got < $count; $n++) {
           my ($x, $y) = $path->n_to_xy ($n);
           ($x, $y) = ($y, $x);
           my $n = $path->xy_to_n ($x, $y);
           push @got, $n;
         }
         return \@got;
       });
}

# A126007 - base 4 low digit fixed, X <-> Y flips above there
MyOEIS::compare_values
  (anum => q{A126007},  # not much path interpretation
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new (radix => 4);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my $low = $n & 3;
       my ($x,$y) = $path->n_to_xy ($n >> 2);
       my $high = $path->xy_to_n ($y,$x);
       push @got, ($high << 2) + $low;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163325 -- radix=3 X coordinate

MyOEIS::compare_values
  (anum => q{A163325},  # catalogued too
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new (radix => 3);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $x;
     }
     return \@got;
   });

# A163326 -- radix=3 Y coordinate
MyOEIS::compare_values
  (anum => q{A163326},  # catalogued too
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ZOrderCurve->new (radix => 3);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $y;
     }
     return \@got;
   });

# GP-DEFINE  \\ extract ternary digit k of n
# GP-DEFINE  A030341(n,k) = (n\3^k)%3;
#
# GP-DEFINE  \\ powers of 3 alternating with 0s
# GP-DEFINE  A254006(n) = if(n%2==0, 3^(n/2), 0);
# GP-Test  my(v=OEIS_samples("A254006"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A254006(n)) == v
# GP-Test  my(g=OEIS_bfile_gf("A254006")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A254006(n)))
# poldegree(OEIS_bfile_gf("A254006"))
#
# GP-DEFINE  A163325(n) = fromdigits(digits(n, 9)%3, 3); \\ mine
#
# GP-Test  /* Philippe Deleham in A163325 */ \
# GP-Test  my(b=A254006); \
# GP-Test  vector(3^6,n,n--; A163325(n)) == \
# GP-Test  vector(3^6,n,n--; sum(k=0,if(n,logint(n,3)), A030341(n,k)*b(k)))


#------------------------------------------------------------------------------
# A163328 -- radix=3 zorder N of an x,y point in diagonals order, same axis

MyOEIS::compare_values
  (anum => 'A163328',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $zorder->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163329 -- radix=3 diagonals N of an x,y point in zorder
# inverse perm of A163328
MyOEIS::compare_values
  (anum => 'A163329',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my ($x, $y) = $zorder->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

# GP-DEFINE  \\ diagonal locations, Z-order N
# GP-DEFINE  A163328(n) = {
# GP-DEFINE     my(d=(sqrtint(8*n+1)-1)\2); n -= d*(d+1)/2;
# GP-DEFINE     subst(Pol(3*digits(n,3)) + Pol(digits(d-n,3)),'x,9);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A163328"));  /* OFFSET=0 */ \
# GP-Test    v == vector(#v,n,n--; A163328(n))
# GP-Test  my(g=OEIS_bfile_gf("A163328")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A163328(n)))
# poldegree(OEIS_bfile_gf("A163328"))
# vector(20,n,n--; A163328(n))
# OEIS_samples("A163328")

# GP-Test  my(x,y); vector(9,n,n--; [y,x]=divrem(n,3); x+y) == \
# GP-Test           [0,1,2, 1,2,3, 2,3,4]
# GP-Test  my(x,y); vector(9,n,n--; [y,x]=divrem(n,3); x+3*y) == \
# GP-Test           [0..8]
# GP-DEFINE  \\ Z-order locations, diagonal N
# GP-DEFINE  { my(table=[0,1,2, 1,2,3, 2,3,4]);
# GP-DEFINE    A163329(n) = my(v=digits(n,9)); 
# GP-DEFINE     ( fromdigits(apply(d->table[d+1],v),3)^2
# GP-DEFINE     + fromdigits(v,3) )/2;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A163329"));  /* OFFSET=0 */ \
# GP-Test    v == vector(#v,n,n--; A163329(n))
# GP-Test  my(g=OEIS_bfile_gf("A163329")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A163329(n)))
# poldegree(OEIS_bfile_gf("A163329"))
# vector(20,n,n--; A163329(n))


#------------------------------------------------------------------------------
# A163330 -- radix=3 diagonals opposite axis

MyOEIS::compare_values
  (anum => 'A163330',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $zorder->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163331 -- radix=3 diagonals same axis, inverse
MyOEIS::compare_values
  (anum => 'A163331',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my ($x, $y) = $zorder->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

# GP-DEFINE  A163330(n) = {
# GP-DEFINE     my(d=(sqrtint(8*n+1)-1)\2); n -= d*(d+1)/2;
# GP-DEFINE     subst(Pol(digits(n,3)) + Pol(3*digits(d-n,3)),'x,9);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A163330"));  /* OFFSET=0 */ \
# GP-Test    v == vector(#v,n,n--; A163330(n))
# GP-Test  my(g=OEIS_bfile_gf("A163330")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A163330(n)))
# poldegree(OEIS_bfile_gf("A163330"))
# vector(20,n,n--; A163330(n))
# OEIS_samples("A163330")

# GP-Test  my(x,y); vector(9,n,n--; [y,x]=divrem(n,3); x+y) == \
# GP-Test           [0,1,2, 1,2,3, 2,3,4]
# GP-Test  my(x,y); vector(9,n,n--; [y,x]=divrem(n,3); 3*x+y) == \
# GP-Test           [0,3,6, 1,4,7, 2,5,8]
# GP-DEFINE  { my(table1=[0,1,2, 1,2,3, 2,3,4],
# GP-DEFINE       table2=[0,3,6, 1,4,7, 2,5,8]);
# GP-DEFINE    A163331(n) = my(v=digits(n,9)); 
# GP-DEFINE     ( fromdigits([table1[d+1]|d<-v],3)^2
# GP-DEFINE     + fromdigits([table2[d+1]|d<-v],3) )/2;
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A163331"));  /* OFFSET=0 */ \
# GP-Test    v == vector(#v,n,n--; A163331(n))
# GP-Test  my(g=OEIS_bfile_gf("A163331")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A163331(n)))
# poldegree(OEIS_bfile_gf("A163331"))
# vector(20,n,n--; A163331(n))


#------------------------------------------------------------------------------
# A054238 -- permutation, binary, diagonals same axis

MyOEIS::compare_values
  (anum => 'A054238',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $zorder->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A054239 -- diagonals same axis, binary, inverse
MyOEIS::compare_values
  (anum => 'A054239',
   func => sub {
     my ($count) = @_;
     my @got;
     my $zorder   = Math::PlanePath::ZOrderCurve->new;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my ($x, $y) = $zorder->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------

exit 0;
