#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2018, 2019 Kevin Ryde

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
# A217015 Permutation of natural numbers arising from applying the walk of a square spiral (e.g. A214526) to the data of rotated-square spiral (defined in A215468).

# A053823 Product of primes in n-th shell of prime spiral.
# A053997 Sum of primes in n-th shell of prime spiral.
# A053998 Smallest prime in n-th shell of prime spiral.

# A113688 Isolated semiprimes in the semiprime spiral.
# A113689 Number of semiprimes in clumps of size >1 through n^2 in the semiprime spiral.
# A114254 Sum of all terms on the two principal diagonals of a 2n+1 X 2n+1 square spiral.


use 5.004;
use strict;
use Math::BigInt;
use Test;
plan tests => 65;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use List::Util 'min','max','sum';
use Math::PlanePath::SquareSpiral;

# uncomment this to run the ### lines
# use Smart::Comments;


my $path = Math::PlanePath::SquareSpiral->new;

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


#------------------------------------------------------------------------------
# A174344 X coordinate
MyOEIS::compare_values
  (anum => 'A174344',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SquareSpiral->new;
     my @got;
     my $y = 0;
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
     my $path = Math::PlanePath::SquareSpiral->new;
     my @got;
     my $y = 0;
     for (my $n=1; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A267682 Y axis positive and negative, n_start=1, origin twice
MyOEIS::compare_values
  (anum => 'A267682',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SquareSpiral->new;
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
     my $path = Math::PlanePath::SquareSpiral->new (n_start => 0);
     my @got = (0);
     for (my $y = 1; @got < $count; $y++) {
       push @got, $path->xy_to_n(0, $y);
       last unless @got < $count;
       push @got, $path->xy_to_n(0, -$y);
     }
     return \@got;
   });

# A317186 X axis positive and negative, n_start=0
MyOEIS::compare_values
  (anum => 'A317186',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SquareSpiral->new;
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
# A059924 Write the numbers from 1 to n^2 in a spiraling square; a(n) is the
# total of the sums of the two diagonals.

MyOEIS::compare_values
  (anum => 'A059924',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = 1; @got < $count; $n++) {
       push @got, my_A059924($n);
     }
     return \@got;
   });

BEGIN {
  my $path = Math::PlanePath::SquareSpiral->new;

  # A059924 spirals inwards, use $square+1 - $t to reverse the path numbering
  sub my_A059924 {
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
}

#------------------------------------------------------------------------------
# A027709 -- unit squares figure boundary

MyOEIS::compare_values
  (anum => 'A027709',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SquareSpiral->new;
     my @got = (0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, $path->_NOTDOCUMENTED_n_to_figure_boundary($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A078633 -- grid sticks

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
     my $path = Math::PlanePath::SquareSpiral->new;
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

{
  my @surround4_dx = (1, 0, -1,  0);
  my @surround4_dy = (0, 1,  0, -1);

  MyOEIS::compare_values
      (anum => q{A094768},
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::SquareSpiral->new (n_start => 0);
         my $total = Math::BigInt->new(1);
         my @got = ($total);
         for (my $n = $path->n_start + 1; @got < $count; $n++) {
           my ($x, $y) = $path->n_to_xy ($n-1);
           foreach my $i (0 .. $#surround4_dx) {
             my $sn = $path->xy_to_n ($x+$surround4_dx[$i], $y+$surround4_dy[$i]);
             if ($sn < $n) {
               $total += $got[$sn];
             }
           }
           $got[$n] = $total;
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A094767 -- cumulative spiro-fibonacci total of 8 neighbours

my @surround8_dx = (1, 1, 0, -1, -1, -1,  0,  1);
my @surround8_dy = (0, 1, 1,  1,  0, -1, -1, -1);

MyOEIS::compare_values
  (anum => q{A094767},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SquareSpiral->new (n_start => 0);
     my $total = Math::BigInt->new(1);
     my @got = ($total);
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n-1);
       foreach my $i (0 .. $#surround8_dx) {
         my $sn = $path->xy_to_n ($x+$surround8_dx[$i], $y+$surround8_dy[$i]);
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
     my $path = Math::PlanePath::SquareSpiral->new (n_start => 0);
     my $total = Math::BigInt->new(1);
     my @got = (0, $total);
     for (my $n = $path->n_start + 2; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n-1);
       foreach my $i (0 .. $#surround8_dx) {
         my $sn = $path->xy_to_n ($x+$surround8_dx[$i], $y+$surround8_dy[$i]);
         if ($sn < $n) {
           $total += $got[$sn];
         }
       }
       $got[$n] = $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A136626 -- count surrounding primes
MyOEIS::compare_values
  (anum => q{A136626},
   fixup => sub {
     my ($bvalues) = @_;
     $bvalues->[31] = 3;  # DODGY-DATA: 3 primes 13,31,59 surrounding 32
   },
   func => sub {
     my ($count) = @_;
     require Math::Prime::XS;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, ((!! Math::Prime::XS::is_prime   ($path->xy_to_n($x+1,$y)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y+1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y-1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y+1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y-1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y+1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y-1)))
                  );
     }
     return \@got;
   });

# A136627 -- count self and surrounding primes
MyOEIS::compare_values
  (anum => q{A136627},
   fixup => sub {
     my ($bvalues) = @_;
     $bvalues->[31] = 3;  # DODGY-DATA: 3 primes 13,31,59 surrounding 32
   },
   func => sub {
     my ($count) = @_;
     require Math::Prime::XS;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, (Math::Prime::XS::is_prime($n)
                   + (!! Math::Prime::XS::is_prime   ($path->xy_to_n($x+1,$y)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y+1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y-1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y+1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y-1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y+1)))
                   + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y-1)))
                  );
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A078784 -- primes on any axis positive or negative

MyOEIS::compare_values
  (anum => 'A078784',
   func => sub {
     my ($count) = @_;
     require Math::Prime::XS;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless Math::Prime::XS::is_prime($n);
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
  (anum => 'A078765',
   func => sub {
     my ($count) = @_;
     require Math::Prime::XS;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless Math::Prime::XS::is_prime($n);
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
# A200975 -- all four diagonals

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

MyOEIS::compare_values
  (anum => 'A113688',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::AlmostPrimes;
     my $seq = Math::NumSeq::AlmostPrimes->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless $seq->pred($n);
       my ($x,$y) = $path->n_to_xy ($n);
       if (! $seq->pred    ($path->xy_to_n($x+1,$y))
           && ! $seq->pred ($path->xy_to_n($x-1,$y))
           && ! $seq->pred ($path->xy_to_n($x,$y+1))
           && ! $seq->pred ($path->xy_to_n($x,$y-1))
           && ! $seq->pred ($path->xy_to_n($x+1,$y+1))
           && ! $seq->pred ($path->xy_to_n($x-1,$y-1))
           && ! $seq->pred ($path->xy_to_n($x-1,$y+1))
           && ! $seq->pred ($path->xy_to_n($x+1,$y-1))
          ) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A215470 -- primes with >=4 prime neighbours in 8 surround

MyOEIS::compare_values
  (anum => 'A215470',
   func => sub {
     my ($count) = @_;
     require Math::Prime::XS;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless Math::Prime::XS::is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       my $num = ((!! Math::Prime::XS::is_prime   ($path->xy_to_n($x+1,$y)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y+1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y-1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y+1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y-1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y+1)))
                  + (!! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y-1)))
                 );
       if ($num >= 4) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A033638 -- N positions of the turns

MyOEIS::compare_values
  (anum => 'A033638',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my @got;
     push @got, 1,1;
     require Math::NumSeq::PlanePathTurn;
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

# A172979 -- N positions of the turns which are also primes
MyOEIS::compare_values
  (anum => 'A172979',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::NumSeq::PlanePathTurn;
     require Math::Prime::XS;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'SquareSpiral',
                                                 turn_type => 'LSR');
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value != 0 && Math::Prime::XS::is_prime($i)) {
         push @got, $i;
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
     require Math::NumSeq::PlanePathTurn;
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
# A141481 -- values as sum of eight surrounding

MyOEIS::compare_values
  (anum => q{A141481},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SquareSpiral->new (n_start => 0);
     my @got = (1);
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       my $sum = Math::BigInt->new(0);
       foreach my $sn ($path->xy_to_n($x+1,$y),
                       $path->xy_to_n($x-1,$y),
                       $path->xy_to_n($x,$y+1),
                       $path->xy_to_n($x,$y-1),
                       $path->xy_to_n($x+1,$y+1),
                       $path->xy_to_n($x-1,$y-1),
                       $path->xy_to_n($x-1,$y+1),
                       $path->xy_to_n($x+1,$y-1)) {
         if ($sn < $n) {
           $sum += $got[$sn]; # @got is 0-based
         }
       }
       push @got, $sum;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A172294 -- jewels, composite surrounded by 4 primes, starting N=0

MyOEIS::compare_values
  (anum => 'A172294',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::SquareSpiral->new (n_start => 0);
     require Math::Prime::XS;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next if Math::Prime::XS::is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       if (Math::Prime::XS::is_prime    ($path->xy_to_n($x+1,$y))
           && Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y))
           && Math::Prime::XS::is_prime ($path->xy_to_n($x,$y+1))
           && Math::Prime::XS::is_prime ($path->xy_to_n($x,$y-1))
          ) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A115258 -- isolated primes

MyOEIS::compare_values
  (anum => 'A115258',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::Prime::XS;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless Math::Prime::XS::is_prime($n);
       my ($x,$y) = $path->n_to_xy ($n);
       if (! Math::Prime::XS::is_prime    ($path->xy_to_n($x+1,$y))
           && ! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y))
           && ! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y+1))
           && ! Math::Prime::XS::is_prime ($path->xy_to_n($x,$y-1))
           && ! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y+1))
           && ! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y-1))
           && ! Math::Prime::XS::is_prime ($path->xy_to_n($x-1,$y+1))
           && ! Math::Prime::XS::is_prime ($path->xy_to_n($x+1,$y-1))
          ) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A214177 -- sum of 4 neighbours

MyOEIS::compare_values
  (anum => 'A214177',
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
  (anum => 'A214176',
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
     require Math::Prime::XS;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless Math::Prime::XS::is_prime($n);
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
     require Math::Prime::XS;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless Math::Prime::XS::is_prime($n);
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
     require Math::Prime::XS;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless Math::Prime::XS::is_prime($n);
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
     require Math::Prime::XS;
     for (my $n = $path->n_start; @got < $count; $n++) {
       next unless Math::Prime::XS::is_prime($n);
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
# A063826 -- direction 1,2,3,4 = E,N,W,S

MyOEIS::compare_values
  (anum => 'A063826',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, path_n_dir4_1($path,$n);
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
# A141481 -- plot sum of existing eight surrounding values entered

MyOEIS::compare_values
  (anum => q{A141481},  # not in POD
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
     require Math::NumSeq::AllDigits;
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
     require Math::NumSeq::AllDigits;
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
     require Math::NumSeq::AllDigits;
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
     require Math::NumSeq::AllDigits;
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
     require Math::NumSeq::AllDigits;
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
# A054567 -- N values on negative X axis

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
