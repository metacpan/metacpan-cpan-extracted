#!/usr/bin/perl -w

# Copyright 2021 Kevin Ryde

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
plan tests => 10;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use FindBin;
use lib "$FindBin::Bin/../..";
use Math::PlanePath::CornerAlternating;
use Math::PlanePath::Diagonals;


# abs(X-Y) with wider=1, different from plain Corner
# not in OEIS: 0,0,1,2,1,0,1,2,1,0,1,2,3,4,3,2,1,0,1,2,3,4,3,2,1,0,1,2,3,4,5,6,5,4,3,2,1,0

# GP-DEFINE  read("my-oeis.gp");

#------------------------------------------------------------------------------
# A220603 -- X+1 coordinate
#
# cf A319289, A319290 as 0-based X,Y

MyOEIS::compare_values
  (anum => 'A220603',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::CornerAlternating->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x+1;
     }
     return \@got;
   });

# A220604 -- Y+1 coordinate
MyOEIS::compare_values
  (anum => 'A220604',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::CornerAlternating->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y+1;
     }
     return \@got;
   });

# GP-DEFINE  \\ following formulas by Boris Putievskiy in A220603, A220604
# GP-DEFINE  A220603(n) = {
# GP-DEFINE    my(t=sqrtint(n-1)+1);
# GP-DEFINE    (t%2)*min(t, n- (t - 1)^2) + ((t+1)%2)*min(t, t^2 - n + 1)
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A220603")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A220603(n)) == v
#
# GP-DEFINE  A220604(n) = {
# GP-DEFINE    my(t=sqrtint(n-1)+1);
# GP-DEFINE    (t%2)*min(t, t^2 - n + 1) + ((t+1)%2)*min(t, n - (t - 1)^2)
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A220604")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A220604(n)) == v

# GP-DEFINE  \\ following code by Peter Luschny in A319289, A319290
# GP-DEFINE  A319289(n) = {
# GP-DEFINE    my(m=sqrtint(n),
# GP-DEFINE       x = m,
# GP-DEFINE       y = n - x^2);
# GP-DEFINE    if(x <= y, [x, y] = [2*x - y, x]);
# GP-DEFINE    if(m%2,y,x);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A319289")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A319289(n)) == v
#
# GP-DEFINE  A319290(n) = {
# GP-DEFINE    my(m=sqrtint(n),
# GP-DEFINE       x = m,
# GP-DEFINE       y = n - x^2);
# GP-DEFINE    if(x <= y, [x, y] = [2*x - y, x]);
# GP-DEFINE    if(m%2,x,y);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A319290")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A319290(n)) == v

# GP-Test  vector(1000,n,n--; A319290(n)) == \
# GP-Test  vector(1000,n,n--; A220603(n+1)-1)

# GP-Test  vector(1000,n,n--; A319289(n)) == \
# GP-Test  vector(1000,n,n--; A220604(n+1)-1)


#------------------------------------------------------------------------------
# A002061 -- N on X=Y diagonal, extra initial 1

MyOEIS::compare_values
  (anum => 'A002061',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::CornerAlternating->new;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $path->xy_to_n ($i, $i);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A319514 - coordinate pairs Y,X

MyOEIS::compare_values
  (anum => 'A319514',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::CornerAlternating->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y,$x;
     }
     $#got = $count-1;
     return \@got;
   });


#------------------------------------------------------------------------------
# A027709 -- unit squares figure boundary,
# same as plain Corner (until wider param)

MyOEIS::compare_values
  (anum => 'A027709',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::CornerAlternating->new;
     my @got = (0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, $path->_NOTDOCUMENTED_n_to_figure_boundary($n);
     }
     return \@got;
   });

# A078633 -- grid sticks, same as plain Corner (until wider param)
{
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

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
}
MyOEIS::compare_values
  (anum => 'A078633',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::CornerAlternating->new;
     my @got;
     my $boundary = 0;
     for (my $n = $path->n_start; @got < $count; $n++) {
       $boundary += path_n_to_dsticks($path,$n);
       push @got, $boundary;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A081344 -- "maze" permutation, N by diagonals

{
  my $corner = Math::PlanePath::CornerAlternating->new;
  my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');

  MyOEIS::compare_values
      (anum => 'A081344',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $n = $diagonal->n_start; @got < $count; $n++) {
           my ($x,$y) = $diagonal->n_to_xy($n);
           push @got, $corner->xy_to_n ($x,$y);
         }
         return \@got;
       });

  # inverse
  MyOEIS::compare_values
      (anum => 'A194280',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $n = $diagonal->n_start; @got < $count; $n++) {
           my ($x,$y) = $corner->n_to_xy($n);
           push @got, $diagonal->xy_to_n ($x,$y);
         }
         return \@got;
       });
}
{
  # with n_start = 0

  my $corner = Math::PlanePath::CornerAlternating->new (n_start => 0);
  my $diagonal = Math::PlanePath::Diagonals->new (n_start => 0,
                                                  direction => 'up');
  MyOEIS::compare_values
      (anum => 'A220516',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $n = $diagonal->n_start; @got < $count; $n++) {
           my ($x,$y) = $diagonal->n_to_xy($n);
           push @got, $corner->xy_to_n ($x,$y);
         }
         return \@got;
       });

  # inverse
  # not in OEIS: 0,1,4,2,5,8,12,7,3,6,11,17,24
}

#------------------------------------------------------------------------------
# A093650 -- "maze" permutation, wider=1 N by diagonals

# example in A093650
#   1   6
#   |   |    but upwards anti-diagonals
#   2   5
#   |   |
#   3---4
# inverse
# not in OEIS: 1,2,4,8,5,3,6,9,13,18,12,7,11,17,24

{
  my $corner = Math::PlanePath::CornerAlternating->new (wider => 1);
  my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');

  MyOEIS::compare_values
      (anum => 'A093650',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $n = $diagonal->n_start; @got < $count; $n++) {
           my ($x,$y) = $diagonal->n_to_xy($n);
           push @got, $corner->xy_to_n ($x,$y);
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A081349 -- "maze" permutation, wider=2 N by diagonals

{
  my $corner = Math::PlanePath::CornerAlternating->new (wider => 2);
  my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');

  MyOEIS::compare_values
      (anum => 'A081349',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $n = $diagonal->n_start; @got < $count; $n++) {
           my ($x,$y) = $diagonal->n_to_xy($n);
           push @got, $corner->xy_to_n ($x,$y);
         }
         return \@got;
       });

  # inverse
  # not in OEIS: 1,2,4,7,12,8,5,3,6,9,13,18,24,17,11
}

#------------------------------------------------------------------------------
# A020703 -- permutation transpose Y,X

MyOEIS::compare_values
  (anum => 'A020703',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::CornerAlternating->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
