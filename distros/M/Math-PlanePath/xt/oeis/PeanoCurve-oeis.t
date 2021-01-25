#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2015, 2018, 2020 Kevin Ryde

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
plan tests => 23;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::PeanoCurve;
my $peano  = Math::PlanePath::PeanoCurve->new;

use Math::PlanePath::Diagonals;
use Math::PlanePath::ZOrderCurve;

# GP-DEFINE  read("my-oeis.gp");
# GP-DEFINE  to_ternary(n) = fromdigits(digits(n,3));
# GP-DEFINE  to_base9(n) = fromdigits(digits(n,9));


#------------------------------------------------------------------------------
# A163332 -- permutation Peano N at points in Z-Order radix=3 sequence

MyOEIS::compare_values
  (anum => 'A163332',
   func => sub {
     my ($count) = @_;
     my $zorder = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my @got;
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my ($x,$y) = $zorder->n_to_xy ($n);
       push @got, $peano->xy_to_n ($x,$y);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A163332},
   func => sub {
     my ($count) = @_;
     my $zorder = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x,$y) = $peano->n_to_xy ($n);   # other way around
       push @got, $zorder->xy_to_n ($x,$y);
     }
     return \@got;
   });

# GP-DEFINE  A163332(n) = {
# GP-DEFINE    my(v=digits(n,3),k=Mod([0,0],2));
# GP-DEFINE    for(i=1,#v, if(k[1],v[i]=2-v[i]); k[2]+=v[i]; k=Vecrev(k));
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A163332")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A163332(n)) == v
# my(g=OEIS_bfile_gf("A163332")); \
#   g==Polrev(vector(poldegree(g)+1,n,n--;A163332(n)))
# poldegree(OEIS_bfile_gf("A163332"))

# GP-DEFINE  A163332_by_pos(n) = {
# GP-DEFINE    my(v=digits(n,3),k=Mod([0,0],2),p=1);
# GP-DEFINE    for(i=1,#v, if(k[p],v[i]=2-v[i]); p=3-p; k[p]+=v[i]);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  vector(3^6,n,n--; A163332_by_pos(n)) == \
# GP-Test  vector(3^6,n,n--; A163332(n))

# GP-DEFINE  A163332_by_vars(n) = {
# GP-DEFINE    my(v=digits(n,3),x=Mod(0,2),y=x);
# GP-DEFINE    for(i=1,#v, if(x,v[i]=2-v[i]); [x,y]=[y+v[i],x]);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  vector(3^6,n,n--; A163332_by_vars(n)) == \
# GP-Test  vector(3^6,n,n--; A163332(n))

# GP-DEFINE  A163332_by_passes(n) = {
# GP-DEFINE    my(v=digits(n,3));
# GP-DEFINE    for(p=2,3, my(s=Mod(0,2));
# GP-DEFINE       forstep(i=p,#v,2, s+=v[i-1]; if(s,v[i]=2-v[i])));
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  vector(3^7,n,n--; A163332_by_passes(n)) == \
# GP-Test  vector(3^7,n,n--; A163332(n))

# GP-DEFINE  \\         none     opp    this    both
# GP-DEFINE  \\           1      4      7       10
# GP-DEFINE  { my(table =[1,7,1, 7,1,7, 4,10,4, 10,4,10]);
# GP-DEFINE  A163332_by_table(n) = 
# GP-DEFINE    my(v=digits(n,3),s=1);
# GP-DEFINE    for(i=1,#v, if(s>=7,v[i]=2-v[i]); s=table[s+v[i]]);
# GP-DEFINE      \\ print("i="i" s="s" digit "v[i]);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  vector(3^7,n,n--; A163332_by_table(n)) == \
# GP-Test  vector(3^7,n,n--; A163332(n))
#  A163332_by_table(39)
#  A163332(39)
# for(n=0,3^4, if(A163332_by_table(n) != A163332(n), print(n)));


#------------------------------------------------------------------------------
# A163334 -- N by diagonals same axis

MyOEIS::compare_values
  (anum => 'A163334',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $peano->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163335 -- N by diagonals same axis, inverse
MyOEIS::compare_values
  (anum => 'A163335',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x, $y) = $peano->n_to_xy ($n);
       push @got, $diagonal->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163336 -- diagonals opposite axis
MyOEIS::compare_values
  (anum => 'A163336',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $peano->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163337 -- diagonals opposite axis, inverse
MyOEIS::compare_values
  (anum => 'A163337',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x, $y) = $peano->n_to_xy ($n);
       push @got, $diagonal->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163338 -- diagonals same axis, 1-based
MyOEIS::compare_values
  (anum => 'A163338',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $peano->xy_to_n ($x, $y) + 1;
     }
     return \@got;
   });

# A163339 -- diagonals same axis, 1-based, inverse
MyOEIS::compare_values
  (anum => 'A163339',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x, $y) = $peano->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163340 -- diagonals same axis, 1 based
MyOEIS::compare_values
  (anum => 'A163340',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $peano->xy_to_n($x,$y) + 1;
     }
     return \@got;
   });

# A163341 -- diagonals same axis, 1-based, inverse
MyOEIS::compare_values
  (anum => 'A163341',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x, $y) = $peano->n_to_xy ($n);
       push @got, $diagonal->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163342 -- diagonal sums
# no b-file as of Jan 2020
MyOEIS::compare_values
  (anum => 'A163342',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $d = 0; @got < $count; $d++) {
       my $sum = 0;
       foreach my $x (0 .. $d) {
         my $y = $d - $x;
         $sum += $peano->xy_to_n ($x, $y);
       }
       push @got, $sum;
     }
     return \@got;
   });

# A163479 -- diagonal sums div 6
MyOEIS::compare_values
  (anum => 'A163479',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $d = 0; @got < $count; $d++) {
       my $sum = 0;
       foreach my $x (0 .. $d) {
         my $y = $d - $x;
         $sum += $peano->xy_to_n ($x, $y);
       }
       push @got, int($sum/6);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163534 -- absolute direction 0=east, 1=south, 2=west, 3=north
# Y coordinates reckoned down the page, so south is Y increasing

MyOEIS::compare_values
  (anum => 'A163534',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy ($n);
       push @got, MyOEIS::dxdy_to_direction ($dx,$dy);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163535 -- absolute direction transpose 0=east, 1=south, 2=west, 3=north

MyOEIS::compare_values
  (anum => 'A163535',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy ($n);
       push @got, MyOEIS::dxdy_to_direction ($dy,$dx);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A145204 -- N+1 of positions of vertical steps, dx=0

MyOEIS::compare_values
  (anum => 'A145204',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       if ($dx == 0) {
         push @got, $n+1;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A014578 -- abs(dX), 1=horizontal 0=vertical, extra initial 0
MyOEIS::compare_values
  (anum => 'A014578',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       push @got, abs($dx);
     }
     return \@got;
   });

# A182581 -- abs(dY), but OFFSET=1
MyOEIS::compare_values
  (anum => 'A182581',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       push @got, abs($dy);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A007417 -- N+1 positions of horizontal step, dY==0, abs(dX)=1
# N+1 has even num trailing ternary 0-digits

MyOEIS::compare_values
  (anum => 'A007417',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       if ($dy == 0) {
         push @got, $n+1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163532 -- dX  a(n)-a(n-1) so extra initial 0

MyOEIS::compare_values
  (anum => 'A163532',
   func => sub {
     my ($count) = @_;
     my @got = (0); # extra initial entry N=0 no change
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       push @got, $dx;
     }
     return \@got;
   });

# A163533 -- dY  a(n)-a(n-1)
MyOEIS::compare_values
  (anum => 'A163533',
   func => sub {
     my ($count) = @_;
     my @got = (0); # extra initial entry N=0 no change
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       push @got, $dy;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163333 -- Peano N <-> Z-Order radix=3, with digit swaps

MyOEIS::compare_values
  (anum => 'A163333',
   func => sub {
     my ($count) = @_;
     my $zorder = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my @got;
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my $nn = $n;
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         ($x,$y) = ($y,$x);
         $nn = $zorder->xy_to_n ($x,$y);
       }
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         $nn = $peano->xy_to_n ($x, $y);
       }
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         ($x,$y) = ($y,$x);
         $nn = $zorder->xy_to_n ($x,$y);
       }
       push @got, $nn;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A163333},
   func => sub {
     my ($count) = @_;
     my $zorder = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $nn = $n;
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         ($x,$y) = ($y,$x);
         $nn = $zorder->xy_to_n ($x,$y);
       }
       {
         my ($x,$y) = $peano->n_to_xy ($nn);   # other way around
         $nn = $zorder->xy_to_n ($x, $y);
       }
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         ($x,$y) = ($y,$x);
         $nn = $zorder->xy_to_n ($x,$y);
       }
       push @got, $nn;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163480 - N on X axis (in Math::NumSeq::PlanePathN)
# A163481 - N on Y axis (in Math::NumSeq::PlanePathN)

# Peano coordinates A163528, A163529
# Z-order coordinates A163325, A163326

# GP-DEFINE  \\ my code in A163325
# GP-DEFINE  ZorderX(n) = fromdigits(digits(n,9)%3, 3);
# GP-DEFINE  \\ my code in A163326
# GP-DEFINE  ZorderY(n) = fromdigits(digits(n,9)\3, 3);
#
# GP-DEFINE  ZorderXYtoN(x,y) = {
# GP-DEFINE    x=digits(x,3);
# GP-DEFINE    y=digits(y,3);
# GP-DEFINE    if(#x<#y, x=concat(vector(#y-#x),x));
# GP-DEFINE    if(#y<#x, y=concat(vector(#x-#y),y));
# GP-DEFINE    fromdigits(x+3*y,9);
# GP-DEFINE  }
# GP-Test  vector(9^5,n,n--; ZorderXYtoN(ZorderX(n),ZorderY(n))) == \
# GP-Test  vector(9^5,n,n--; n)
#
# GP-DEFINE  \\ ternary odd positions are 0, so base 9 digits 0,1,2 only
# GP-DEFINE  A037314(n) = fromdigits(digits(n,3),9);
# GP-Test  my(v=OEIS_samples("A037314"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A037314(n)) == v
# GP-Test  vector(3^5,n,n--; A037314(n)) == \
# GP-Test  vector(3^5,n,n--; ZorderXYtoN(n,0))
#
# GP-DEFINE  A208665(n) = 3*fromdigits(digits(n,3),9);
# GP-Test  my(v=OEIS_samples("A208665"));  /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A208665(n)) == v
# GP-Test  vector(3^5,n,n--; A208665(n)) == \
# GP-Test  vector(3^5,n,n--; ZorderXYtoN(0,n))

# GP-DEFINE  \\ Peano X -> N, on X axis
# GP-DEFINE  A163480(n) = A163332(A037314(n));
# GP-Test  my(v=OEIS_samples("A163480"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A163480(n)) == v
#
# GP-DEFINE  A163480_compact(n) = {
# GP-DEFINE    my(v=digits(n,3),s=Mod(0,2));
# GP-DEFINE    for(i=1,#v, if(s,v[i]+=6); s+=v[i]);
# GP-DEFINE    fromdigits(v,9);
# GP-DEFINE  }
# GP-Test  to_ternary(A163480(3))         == 120
# GP-Test  to_ternary(A163480_compact(3)) == 120
# GP-Test  vector(3^6,n,n--; A163480(n)) == \
# GP-Test  vector(3^6,n,n--; A163480_compact(n))

# GP-DEFINE  \\ Peano Y -> N, points on Y axis
# GP-DEFINE  A163481(n) = A163332(A208665(n));
# GP-Test  my(v=OEIS_samples("A163481"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A163481(n)) == v
#
# GP-Test  /* Y axis from X axis */ \
# GP-Test  vector(3^6,n,n--; A163481(n)) == \
# GP-Test  vector(3^6,n,n--; 3*A163480(n) + if(n%2,2))
#
# GP-DEFINE  A163481_compact(n) = {
# GP-DEFINE    my(v=digits(n,3),s=Mod(0,2));
# GP-DEFINE    for(i=1,#v, s+=v[i]; v[i]=3*v[i]+if(s,2));
# GP-DEFINE    fromdigits(v,9);
# GP-DEFINE  }
# GP-Test  vector(3^6,n,n--; A163481(n)) == \
# GP-Test  vector(3^6,n,n--; A163481_compact(n))


#------------------------------------------------------------------------------
# A163343 - N on diagonal (in Math::NumSeq::PlanePathN)
# = 4*A163344

# GP-DEFINE  \\ ternary reflected Gray code
# GP-DEFINE  Gray3(n) = {
# GP-DEFINE    my(v=digits(n,3),s=Mod(0,2));
# GP-DEFINE    for(i=1,#v, if(s,v[i]=2-v[i]); s+=v[i]);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-DEFINE  A128173(n) = Gray3(n);
# GP-Test  my(v=OEIS_samples("A128173"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A128173(n)) == v
# my(g=OEIS_bfile_gf("A128173")); \
#   g==Polrev(vector(poldegree(g)+1,n,n--;A128173(n)))
# poldegree(OEIS_bfile_gf("A128173"))
#
# GP-DEFINE  \\ 00 11 22 duplicate ternary digits
# GP-DEFINE  Dup3(n) = fromdigits(digits(n,3),9)<<2;
# GP-DEFINE  A338086(n) = Dup3(n);
# GP-Test  my(v=OEIS_samples("A338086"));  /* OFFSET=1 */ \
# GP-Test    vector(#v,n,n--; A338086(n)) == v
# my(g=OEIS_bfile_gf("A338086")); \
#   g==Polrev(vector(poldegree(g)+1,n,n--;A338086(n)))
# poldegree(OEIS_bfile_gf("A338086"))

# GP-DEFINE  \\ Peano d -> N, on diagonal
# GP-DEFINE  A163343(n) = A163332(Dup3(n));
# GP-Test  my(v=OEIS_samples("A163343"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A163343(n)) == v
# my(g=OEIS_bfile_gf("A163343")); \
#   g==Polrev(vector(poldegree(g)+1,n,n--;A163343(n)))
# poldegree(OEIS_bfile_gf("A163343"))
#
# GP-Test  /* diagonal by Z-order diagonal converted */ \
# GP-Test  vector(3^6,n,n--; A163343(n)) == \
# GP-Test  vector(3^6,n,n--; A163332(A338086(n)))
#
# GP-Test  /* diagonal by ternary reflected Gray then 3 -> 9 */ \
# GP-Test  vector(3^6,n,n--; A163343(n)) == \
# GP-Test  vector(3^6,n,n--; A338086(A128173(n)))
#
# GP-DEFINE  A163343_compact(n) = {
# GP-DEFINE    my(v=digits(n,3),s=Mod(0,2));
# GP-DEFINE    for(i=1,#v, if(s,v[i]=2-v[i]); s+=v[i]);
# GP-DEFINE    fromdigits(v,9)<<2;
# GP-DEFINE  }
# GP-Test  vector(3^6,n,n--; A163343(n)) == \
# GP-Test  vector(3^6,n,n--; A163343_compact(n))

#------------------------------------------------------------------------------
# A163344 -- N/4 on X=Y diagonal

MyOEIS::compare_values
  (anum => 'A163344',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       push @got, int($peano->xy_to_n($x,$x) / 4);
     }
     return \@got;
   });

# GP-DEFINE  A163344(n) = A163343(n)/4;
# GP-Test  my(v=OEIS_samples("A163344"));  /* OFFSET=1 */ \
# GP-Test    vector(#v,n,n--; A163344(n)) == v
# my(g=OEIS_bfile_gf("A163344")); \
#   g==Polrev(vector(poldegree(g)+1,n,n--;A163344(n)))
# poldegree(OEIS_bfile_gf("A163344"))


#------------------------------------------------------------------------------
exit 0;
