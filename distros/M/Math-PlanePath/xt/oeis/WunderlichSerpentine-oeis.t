#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

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
use List::Util 'max';
use Test;
plan tests => 8;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::WunderlichSerpentine;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh', 'digit_join_lowtohigh';
use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
use Math::NumSeq::PlanePathTurn;

# GP-DEFINE  read("my-oeis.gp");


#------------------------------------------------------------------------------
# A163343 - X=Y diagonal in all serpentine types

foreach my $type ('alternating',
                  'coil',
                  'Peano',
                  '100 000 001',
                  '000 111 000',
                  '000 111 111',
                 ) {
  MyOEIS::compare_values
      (anum => 'A163343',
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::WunderlichSerpentine->new
           (serpentine_type => $type);
         my @got;
         for (my $i = 0; @got < $count; $i++) {
           push @got, $path->xy_to_n($i,$i);
         }
         return \@got;
       });
}


#------------------------------------------------------------------------------
# A332380  alternating type, diagonals across, so segment replacement
# A332381

# GP-DEFINE  A332380 = OEIS_bfile_func("A332380");
# GP-DEFINE  A332381 = OEIS_bfile_func("A332381");
# plothraw(vector(3^6,n,n--; A332380(n)), \
#          vector(3^6,n,n--; A332381(n)), 1+8+16+32)
# poldegree(OEIS_bfile_gf("A332380"))
# poldegree(OEIS_bfile_gf("A332381"))

# midpoints
# GP-DEFINE  A332380mid(n) = (A332380(n+1) + A332380(n))/2;
# GP-DEFINE  A332381mid(n) = (A332381(n+1) + A332381(n))/2;
# plothraw(vector(3^6,n,n--; A332380mid(n)), \
#          vector(3^6,n,n--; A332381mid(n)), 1+8+16+32)
#
# rotated
# plothraw(vector(3^6,n,n--; A332380mid(n) - A332381mid(n)), \
#          vector(3^6,n,n--; A332380mid(n) + A332381mid(n)), 1+8+16+32)
#
# by func
# GP-DEFINE  A332380z(n) = A332380(n) + I*A332381(n);
# vector(18,n,n--; A332380z(n))
# GP-DEFINE  A332380zmid(n) = (A332380z(n+1) + A332380z(n))/2;
# my(v=vector(9^3,n,n--; (1+I)*A332380z(n))); \
# plothraw(real(v),imag(v),1+32);

# chamfered corners
# GP-DEFINE  A332380_dz(n) = A332380z(n+1) - A332380z(n);
# GP-DEFINE  A332380_midfrac(n,f) = A332380z(n) + A332380_dz(n)*f;
# my(l=List([])); \
# for(n=0,9^2-1, \
#   listput(l,A332380_midfrac(n,.1)); \
#   listput(l,A332380_midfrac(n,.9))); \
# l=Vec(l);\
# plothraw(real(l),imag(l),1+8+16+32);

# Remy Sigrist's directions code in A332380
# [R, U, L, D]=[0..3];
# p = [R, U, R, D, L, D, R, U, R];
# l=List([]); z=0; \
# for(n=0, 9^3, \
#   listput(l,z); z += I^vecsum(apply(d -> p[1+d], digits(n, #p))));
# l=Vec(l);
# l=vector(#l-1,n, (1+I) * (l[n+1]+l[n])/2);
# plothraw(real(l),imag(l),1+32);

# GP-DEFINE  alt_dir_table = [0,1,0,-1,-2,-1,0,1,0];
# GP-DEFINE  alt_dir(n) = {
# GP-DEFINE    my(v=digits(n,9));
# GP-DEFINE    sum(i=1,#v, alt_dir_table[v[i]+1]);
# GP-DEFINE  }
# vector(50,n,n--; alt_dir(n))
# A159195 abs values
# S_0 = [1]; morphism t -> |t-1|,t,t+1; sequence gives limiting value of S_{2n+1}
#
# vector(20,n,n--; alt_dir(n) % 4)
# not in OEIS: 0, 1, 0, 3, 2, 3, 0, 1, 0, 1, 2, 1, 0, 3, 0, 1, 2, 1, 0, 1

# GP-DEFINE  \\ triplets 010 323   232 101
# GP-DEFINE  \\          121 030   303 212
# GP-DEFINE  { my(table=[[0,1,0, 3,2,3, 0,1,0],
# GP-DEFINE              [1,2,1, 0,3,0, 1,2,1],
# GP-DEFINE              [2,3,2, 1,0,1, 2,3,2],
# GP-DEFINE              [3,0,3, 2,1,2, 3,0,3]]);
# GP-DEFINE    alt_dir_morphism(k) =
# GP-DEFINE      my(v=[0]);
# GP-DEFINE      for(i=1,k, v=concat(apply(t->table[t+1], v)));
# GP-DEFINE      v;
# GP-DEFINE  }
# GP-Test  my(v=alt_dir_morphism(5)); \
# GP-Test  #v==9^5 && vector(#v,n,n--; alt_dir(n)%4) == v

# GP-DEFINE  \\ WRONG needs 8 states to make 8 different triplets
# GP-DEFINE  { my(table=[[0,1,0],
# GP-DEFINE              [3,2,3],
# GP-DEFINE              [0,3,0],
# GP-DEFINE              [1,2,1]]);
# GP-DEFINE    alt_dir_morphism3(k) =
# GP-DEFINE      my(v=[0]);
# GP-DEFINE      for(i=1,k, v=concat(apply(t->table[t+1], v)));
# GP-DEFINE      v;
# GP-DEFINE  }
# alt_dir_morphism3(4) - \
# vector(81,n,n--; alt_dir(n)%4)
# my(v=alt_dir_morphism3(4)); \
# #v==9^5; vector(#v,n,n--; alt_dir(n)%4) - v

# GP-DEFINE  my(table=[0,1,0,3,2,3,0,1,0]); \
# GP-DEFINE  alt_dir_plus(n) = vecsum(apply(d->table[1+d], digits(n,9)));
# vector(35,n,alt_dir_plus(n))
# not in OEIS: 1,0,3,2,3,0,1,0,1,2,1,4,3,4,1,2,1,0,1,0,3,2,3,0,1,0,3,4,3,6,5,6,3,4,3

# 1, -1,-1,-1, 1,1,1, -1
# GP-DEFINE  alt_turn(n) = {
# GP-DEFINE    n>=1 || error();
# GP-DEFINE    while(n%9==0, n/=9);
# GP-DEFINE    [1, -1,-1,-1, 1,1,1, -1][n%9];
# GP-DEFINE  }
# vector(35,n,alt_turn(n))
# vector(27,n,alt_turn(n)>0)
# vector(27,n,alt_turn(n)<0)
# not in OEIS: 1,-1,-1,-1,1,1,1,-1,1,1,-1,-1,-1,1,1,1,-1,-1,1,-1,-1,-1,1,1,1,-1,-1
# not A216430 parity num 2s
# not in OEIS: 1,0,0,0,1,1,1,0,1,1,0,0,0,1,1,1,0,0,1,0,0,0,1,1,1,0,0
# not in OEIS: 0,1,1,1,0,0,0,1,0,0,1,1,1,0,0,0,1,1,0,1,1,1,0,0,0,1,1

#--------------------
# A332380 code

# GP-DEFINE  \\ A332380 by rotate and position table
# GP-DEFINE  { my(table=[[1,0], [I,1], [1,1+I],
# GP-DEFINE              [-I,2+I], [-1,2], [-I,1],
# GP-DEFINE              [1,1-I], [I,2-I], [1,2]]);
# GP-DEFINE    table == vector(9,n, [table[n][1], sum(i=1,n-1, table[i][1])]) \
# GP-DEFINE      || error();
# GP-DEFINE  A332380_compact(n) =
# GP-DEFINE    my(v=digits(n,9),rot=1);
# GP-DEFINE    for(i=1,#v, [rot,v[i]] = rot*table[v[i]+1]);
# GP-DEFINE    fromdigits(real(v),3);
# GP-DEFINE  }
# GP-Test  my(g=OEIS_bfile_gf("A332380")); \
# GP-Test    g == Polrev(vector(poldegree(g)+1,n,n--;A332380_compact(n)))
#
# GP-DEFINE  { my(table=[[1,0], [I,1], [1,1+I],
# GP-DEFINE              [-I,2+I], [-1,2], [-I,1],
# GP-DEFINE              [1,1-I], [I,2-I], [1,2]]);
# GP-DEFINE  A332381_compact(n) =
# GP-DEFINE    my(v=digits(n,9),rot=1);
# GP-DEFINE    for(i=1,#v, [rot,v[i]] = rot*table[v[i]+1]);
# GP-DEFINE    fromdigits(imag(v),3);
# GP-DEFINE  }
# GP-Test  my(g=OEIS_bfile_gf("A332381")); \
# GP-Test    g == Polrev(vector(poldegree(g)+1,n,n--;A332381_compact(n)))



#------------------------------------------------------------------------------
# A332380,A332381 serpentine 010 101 010 - N on X=Y and X=-Y diagonals

# GP-DEFINE  \\ 9x, 9x+2 and 9x-6
# GP-DEFINE  alt_is_leadingdiag(n) = {
# GP-DEFINE    while(n, if(n%9==0, ,
# GP-DEFINE                n%9==2, n-=2,
# GP-DEFINE                n%9==3, n+=6,
# GP-DEFINE                return(0));
# GP-DEFINE             n%9==0 || error(); n/=9);
# GP-DEFINE    1;
# GP-DEFINE  }
# GP-Test  vector(9^5,n,n--; alt_is_leadingdiag(n)) == \
# GP-Test  vector(9^5,n,n--; A332380_compact(n) == A332381_compact(n))
# for(n=0,9^2, if(alt_is_leadingdiag(n) != (A332380(n)==A332381(n)), print(n)))

# GP-DEFINE  balanced_ternary_digits(n) = {
# GP-DEFINE    my(l=List([]));
# GP-DEFINE    while(n, my(a=n%3); if(a==2, a=-1); listput(l,a); n=(n-a)/3);
# GP-DEFINE    Vecrev(l);
# GP-DEFINE  }
# GP-Test  /* A072998 balanced ternary -1,0,1 coded as 0,1,2 decimal digits */ \
# GP-Test  /* but 0 as one 0 digit so 1, an exception to all starting 2 */ \
# GP-Test  my(want=OEIS_samples("A072998")); \
# GP-Test    vector(#want,n,n--; \
# GP-Test            if(n==0,1, \
# GP-Test               fromdigits(apply(n->n+1,balanced_ternary_digits(n))))) \
# GP-Test    == want

# GP-DEFINE  A072998_compact(n) = \
# GP-DEFINE    fromdigits(digits(n + (3^(1+if(n,logint(2*n,3))) - 1)/2, 3));
# GP-Test  my(want=OEIS_samples("A072998")); \
# GP-Test    vector(#want,n,n--; A072998_compact(n)) == want
# GP-Test  vector(3^7,n,n--; A072998_compact(n)) == \
# GP-Test  vector(3^7,n,n--; if(n==0,1, \
# GP-Test            fromdigits(apply(n->n+1,balanced_ternary_digits(n)))))

# GP-DEFINE  { my(table=[-6,0,2]);
# GP-DEFINE  alt_leadingdiag_by_balanced_ternary(n) =
# GP-DEFINE    my(v=balanced_ternary_digits(n));
# GP-DEFINE    fromdigits(apply(d->table[d+2],v), 9);
# GP-DEFINE  }
# GP-Test  my(v=select(alt_is_leadingdiag, [0..9^5])); \
# GP-Test  #v==122 && v == vector(#v,n,n--; alt_leadingdiag_by_balanced_ternary(n))

# GP-DEFINE  { my(table=[[1,0],[1,2],[2,-6],[2,0]]);
# GP-DEFINE  alt_leadingdiag_by_ternary(n) =
# GP-DEFINE    my(v=concat(0,digits(n,3)), c=1);
# GP-DEFINE    forstep(i=#v,1,-1, [c,v[i]]=table[c+v[i]]);
# GP-DEFINE    fromdigits(v,9);
# GP-DEFINE  }
# GP-Test  vector(3^8,n,n--; alt_leadingdiag_by_balanced_ternary(n)) == \
# GP-Test  vector(3^8,n,n--; alt_leadingdiag_by_ternary(n))

# GP-DEFINE  { my(table=[-6,0,2]);
# GP-DEFINE  alt_leadingdiag_by_offset(n) =
# GP-DEFINE    fromdigits(apply(d->table[d+1],
# GP-DEFINE      digits(n + (3^(1+if(n,logint(2*n,3))) - 1)/2, 3)), 9);
# GP-DEFINE  }
# GP-Test  vector(3^8,n,n--; alt_leadingdiag_by_offset(n)) == \
# GP-Test  vector(3^8,n,n--; alt_leadingdiag_by_ternary(n))




#------------------------------------------------------------------------------
# Coordinates - Alternating

# GP-DEFINE  want_AltX = [0,0,0,1,1,1,2,2,2,2,1,0,0,1,2,2,1,0,0,0,0,1,1,1,2,2,2,3,4,5,5,4,3,3,4,5,5,5,5,4,4,4,3,3,3,3,4,5,5,4,3,3,4,5,6,6,6,7,7,7,8,8,8,8,7,6,6,7,8,8,7,6,6,6,6,7,7,7,8,8,8,8,7,6,6,7,8,8,7,6,5,5,5,4,4,4,3,3,3,2,1,0,0,1,2,2,1,0,0,0,0,1,1,1,2,2,2,3,4,5,5,4,3,3,4,5,6,6,6,7,7,7,8,8,8,8,7,6,6,7,8,8,7,6,5,5,5,4,4,4,3,3,3,2,1,0,0,1,2,2,1,0,0,0,0,1,1,1,2,2,2,2,1,0,0,1,2,2,1,0,0,0,0,1,1,1,2,2,2,3,4,5,5,4,3,3,4,5,5,5,5,4,4,4,3,3,3,3,4,5,5,4,3,3,4,5,6,6,6,7,7,7,8,8,8,8,7,6,6,7,8,8,7,6,6,6,6,7,7,7,8,8,8,9,10,11,11,10,9,9,10,11,12,12,12,13,13,13,14,14,14,15,16,17,17,16,15,15,16,17,17,17,17,16,16,16,15,15,15,14,13,12,12,13,14,14,13,12,11,11,11,10,10,10,9,9,9,9,10,11,11,10,9,9,10,11,12,12,12,13,13,13,14,14,14,15,16,17,17,16,15,15,16,17,17,17,17,16,16,16,15,15,15,15,16,17,17,16,15,15,16,17,17,17,17,16,16,16,15,15,15,14,13,12,12,13,14,14,13,12,12,12,12,13,13,13,14,14,14,14,13,12,12,13,14,14,13,12,11,11,11,10,10,10,9,9,9,9,10,11,11,10,9,9,10,11,11,11,11,10,10,10,9,9,9,9,10,11,11,10,9,9,10,11,12,12,12,13,13,13,14,14,14,15,16,17,17,16,15,15,16,17,17,17,17,16,16,16,15,15,15,14,13,12,12,13,14,14,13,12,11,11,11,10,10,10,9,9,9,9,10,11,11,10,9,9,10,11,12,12,12,13,13,13,14,14,14,15,16,17,17,16,15,15,16,17,18,18,18,19,19,19,20,20,20,20,19,18,18,19,20,20,19,18,18,18,18,19,19,19,20,20,20,21,22,23,23,22,21,21,22,23,23,23,23,22,22,22,21,21,21,21,22,23,23,22,21,21,22,23,24,24,24,25,25,25,26,26,26,26,25,24,24,25,26,26,25,24,24,24,24,25,25,25,26,26,26,26,25,24,24,25,26,26,25,24,23,23,23,22,22,22,21,21,21,20,19,18,18,19,20,20,19,18,18,18,18,19,19,19,20,20,20,21,22,23,23,22,21,21,22,23,24,24,24,25,25,25,26,26,26,26,25,24,24,25,26,26,25,24,23,23,23,22,22,22,21,21,21,20,19,18,18,19,20,20,19,18,18,18,18,19,19,19,20,20,20,20,19,18,18,19,20,20,19,18,18,18,18,19,19,19,20,20,20,21,22,23,23,22,21,21,22,23,23,23,23,22,22,22,21,21,21,21,22,23,23,22,21,21,22,23,24,24,24,25,25,25,26,26,26,26,25,24,24,25,26,26,25,24,24,24,24,25,25,25,26,26,26,26];
# GP-DEFINE  want_AltY = [0,1,2,2,1,0,0,1,2,3,3,3,4,4,4,5,5,5,6,7,8,8,7,6,6,7,8,8,8,8,7,7,7,6,6,6,5,4,3,3,4,5,5,4,3,2,2,2,1,1,1,0,0,0,0,1,2,2,1,0,0,1,2,3,3,3,4,4,4,5,5,5,6,7,8,8,7,6,6,7,8,9,9,9,10,10,10,11,11,11,11,10,9,9,10,11,11,10,9,9,9,9,10,10,10,11,11,11,12,13,14,14,13,12,12,13,14,14,14,14,13,13,13,12,12,12,12,13,14,14,13,12,12,13,14,15,15,15,16,16,16,17,17,17,17,16,15,15,16,17,17,16,15,15,15,15,16,16,16,17,17,17,18,19,20,20,19,18,18,19,20,21,21,21,22,22,22,23,23,23,24,25,26,26,25,24,24,25,26,26,26,26,25,25,25,24,24,24,23,22,21,21,22,23,23,22,21,20,20,20,19,19,19,18,18,18,18,19,20,20,19,18,18,19,20,21,21,21,22,22,22,23,23,23,24,25,26,26,25,24,24,25,26,26,26,26,25,25,25,24,24,24,24,25,26,26,25,24,24,25,26,26,26,26,25,25,25,24,24,24,23,22,21,21,22,23,23,22,21,21,21,21,22,22,22,23,23,23,23,22,21,21,22,23,23,22,21,20,20,20,19,19,19,18,18,18,18,19,20,20,19,18,18,19,20,20,20,20,19,19,19,18,18,18,17,16,15,15,16,17,17,16,15,14,14,14,13,13,13,12,12,12,11,10,9,9,10,11,11,10,9,9,9,9,10,10,10,11,11,11,12,13,14,14,13,12,12,13,14,15,15,15,16,16,16,17,17,17,17,16,15,15,16,17,17,16,15,14,14,14,13,13,13,12,12,12,11,10,9,9,10,11,11,10,9,8,8,8,7,7,7,6,6,6,6,7,8,8,7,6,6,7,8,8,8,8,7,7,7,6,6,6,5,4,3,3,4,5,5,4,3,3,3,3,4,4,4,5,5,5,5,4,3,3,4,5,5,4,3,2,2,2,1,1,1,0,0,0,0,1,2,2,1,0,0,1,2,2,2,2,1,1,1,0,0,0,0,1,2,2,1,0,0,1,2,3,3,3,4,4,4,5,5,5,6,7,8,8,7,6,6,7,8,8,8,8,7,7,7,6,6,6,5,4,3,3,4,5,5,4,3,2,2,2,1,1,1,0,0,0,0,1,2,2,1,0,0,1,2,3,3,3,4,4,4,5,5,5,6,7,8,8,7,6,6,7,8,9,9,9,10,10,10,11,11,11,11,10,9,9,10,11,11,10,9,9,9,9,10,10,10,11,11,11,12,13,14,14,13,12,12,13,14,14,14,14,13,13,13,12,12,12,12,13,14,14,13,12,12,13,14,15,15,15,16,16,16,17,17,17,17,16,15,15,16,17,17,16,15,15,15,15,16,16,16,17,17,17,18,19,20,20,19,18,18,19,20,21,21,21,22,22,22,23,23,23,24,25,26,26,25,24,24,25,26,26,26,26,25,25,25,24,24,24,23,22,21,21,22,23,23,22,21,20,20,20,19,19,19,18,18,18,18,19,20,20,19,18,18,19,20,21,21,21,22,22,22,23,23,23,24,25,26,26,25,24,24,25,26,27];


# GP-DEFINE  AltY(n) = {
# GP-DEFINE    my(v=digits(n,9), t=Mod(0,2), k=Mod(0,2));
# GP-DEFINE    for(i=1,#v, my(d=v[i], y=if(t,d\3,d%3), c=d+y);
# GP-DEFINE      v[i]=if((k+=c)+t*c, 2-y, y); t+=d);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-DEFINE  AltY(n) = {
# GP-DEFINE    my(v=digits(n,9), t=Mod(0,2), k=Mod(0,2));
# GP-DEFINE    for(i=1,#v, my(p=divrem(v[i],3),y);
# GP-DEFINE      if(t, y=if(k, 2-p[1],p[1]); k+=p[2],
# GP-DEFINE            y=if(k+=p[1], 2-p[2],p[2]));
# GP-DEFINE      t+=v[i]; v[i]=y);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  vector(#want_AltY,n,n--; AltY(n)) == want_AltY
# vector(161,n,n--; AltY(n)) - want_AltY[1..161]
# vector(10,n,n--; AltY(n))
# AltY(90)
# AltY(10)
# want_AltY[10 +1]
# digits(90,9)
# divrem(1,3) == [0,1]~
# GP-Test  vector(9^3,n,n--; AltY(n)) == \
# GP-Test  vector(9^3,n,n--; \
# GP-Test    (A332380(n) + A332380(n+1) + A332381(n) + A332381(n+1) - 1)/2)
# GP-Test  vector(9^5,n,n--; AltY(n)) == \
# GP-Test  vector(9^5,n,n--; \
# GP-Test    (A332380_compact(n) + A332380_compact(n+1) \
# GP-Test     + A332381_compact(n) + A332381_compact(n+1) - 1)/2)

# real(('x+'y*I)/(1+I)) == 'x/2 + 'y/2

# GP-DEFINE  \\ arithmetic transposing
# GP-DEFINE  AltX(n) = {
# GP-DEFINE    my(v=digits(n,9), t=Mod(0,2), k=Mod(0,2));
# GP-DEFINE    for(i=1,#v, my(d=v[i], x=if(t,d%3,d\3), c=d+x);
# GP-DEFINE      v[i]=if(k+t*c, 2-x, x); k+=c; t+=d);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-DEFINE  \\ conditional transposing
# GP-DEFINE  AltX(n) = {
# GP-DEFINE    my(v=digits(n,9), t=Mod(1,2), k=Mod(0,2));
# GP-DEFINE    for(i=1,#v, my(p=divrem(v[i],3),x);
# GP-DEFINE      if(t, x=if(k, 2-p[1],p[1]); k+=p[2],
# GP-DEFINE            x=if(k+=p[1], 2-p[2],p[2]));
# GP-DEFINE      t+=v[i]; v[i]=x);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  vector(#want_AltX,n,n--; AltX(n)) == want_AltX
# vector(161,n,n--; AltX(n)) - want_AltX[1..161]
# vector(10,n,n--; AltX(n))
#
# GP-Test  vector(9^3,n,n--; AltX(n)) == \
# GP-Test  vector(9^3,n,n--; \
# GP-Test    (A332380(n) + A332380(n+1) - A332381(n) - A332381(n+1) - 1)/2)
# GP-Test  vector(9^5,n,n--; AltX(n)) == \
# GP-Test  vector(9^5,n,n--; \
# GP-Test    (A332380_compact(n) + A332380_compact(n+1) \
# GP-Test     - A332381_compact(n) - A332381_compact(n+1) - 1)/2)

# GP-DEFINE  dAltX(n) = AltX(n+1) - AltX(n);
# GP-DEFINE  dAltY(n) = AltY(n+1) - AltY(n);
#
# GP-Test  /* divining diagonal direction from dx,dy and parity */ \
# GP-Test  vector(9^3,n,n--; A332380(n)) == \
# GP-Test  vector(9^3,n,n--; real( (AltX(n) + AltY(n)*I)/(1+I) - (n%2)/2) \
# GP-Test       + if(n%2==1 && dAltY(n)==1, 1, \
# GP-Test            n%2==1 && dAltY(n)==-1, 1, \
# GP-Test            n%2==0 && dAltY(n)==1, 0, \
# GP-Test            n%2==0 && dAltY(n)==-1, 1, \
# GP-Test            n%2==1 && dAltX(n)==1, 1, \
# GP-Test            n%2==1 && dAltX(n)==-1, 1, \
# GP-Test            n%2==0 && dAltX(n)==1, 0, \
# GP-Test            n%2==0 && dAltX(n)==-1, 1, \
# GP-Test            'x))


#------------------------------------------------------------------------------
# A323258 -- X coordinate,  Robert Dickau's variation.
# A323259 -- Y coordinate
#
# Wunderlich serpentine "alternating", but the least significant digit of N
# which 9 points in 3x3 has a transpose along its diagonal.
#
# Occurs since the base figure is an S orientation but then it and
# subsequent bigger 3^k x 3^k blocks are assembled in N orientation.
# In all cases rotations to make the ends join up.
#
# So in an "even" block which is leading diagonal, transpose lowest ternary
# digit of x,y.  Or in odd block which is opposite diagonal, complement
# 2-y,2-x.

sub xy_low_transpose {
  my ($x,$y) = @_;
  my $xr = _divrem_mutate($x,3);
  my $yr = _divrem_mutate($y,3);
  if (($x+$y)&1) {
    ($xr,$yr) = (2-$yr,2-$xr);
  } else {
    ($xr,$yr) = ($yr,$xr);
  }
  return (3*$x+$xr, 3*$y+$yr);
}

MyOEIS::compare_values
  (anum => 'A323258',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WunderlichSerpentine->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       ($x,$y) = xy_low_transpose($x,$y);
       push @got, $y;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A323259',
   func => sub {
     my ($count) = @_;
     my $path  = Math::PlanePath::WunderlichSerpentine->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       ($x,$y) = xy_low_transpose($x,$y);
       push @got, $x;
     }
     return \@got;
   });

# without low transpose:
# not in OEIS: 0,1,2,2,1,0,0,1,2,3,3,3,4,4,4,5,5,5,6,7,8,8,7,6,6,7,8,8,8,8,7,7,7,6,6,6,5,4,3
# not in OEIS: 0,0,0,1,1,1,2,2,2,2,1,0,0,1,2,2,1,0,0,0,0,1,1,1,2,2,2,3,4,5,5,4,3,3,4,5,5,5,5,4,4,4,3,3,3,3,4,5,5,4,3

# ~/OEIS/a323258.png
# ~/OEIS/b323258.txt
# http://robertdickau.com/wunderlich.html
# my(g=OEIS_bfile_gf("A323258")); x(n) = polcoeff(g,n);
# my(g=OEIS_bfile_gf("A323259")); y(n) = polcoeff(g,n);
# plothraw(vector(9^3+10,n,n--; x(n)), \
#          vector(9^3+10,n,n--; y(n)), 1+8+16+32)
# plothraw(vector(9^4+1,n,n--; x(n)), \
#          vector(9^4+1,n,n--; y(n)), 1+8+16+32)
# plothraw(vector(9^3,n, y(9*n-4)), \
#          vector(9^3,n, x(9*n-4)), 1+8+16+32)


#------------------------------------------------------------------------------
exit 0;



__END__

# my $xr = $x % 3;
# my $yr = $y % 3;
# return ($x - $xr + $yr,
#         $y - $yr + $xr);
# sub xy_high_transpose {
#   my ($x,$y) = @_;
#   my @x = digit_split_lowtohigh($x,3);
#   my @y = digit_split_lowtohigh($y,3);
#   my $max = max($#x,$#y);
#   if ($max >= 0) {
#     push @x, (0) x ($max - $#x);
#     push @y, (0) x ($max - $#y);
#     ($x[$max],$y[$max]) = ($y[$max],$x[$max]);
#   }
#   return (digit_join_lowtohigh(\@y,3),
#           digit_join_lowtohigh(\@x,3));
# }
