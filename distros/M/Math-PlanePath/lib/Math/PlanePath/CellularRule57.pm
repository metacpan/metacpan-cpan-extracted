# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.



package Math::PlanePath::CellularRule57;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'round_nearest';

use Math::PlanePath::CellularRule54;
*_rect_for_V = \&Math::PlanePath::CellularRule54::_rect_for_V;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

use constant parameter_info_array =>
  [ { name        => 'mirror',
      display     => 'Mirror',
      type        => 'boolean',
      default     => 0,
      description => 'Mirror to "rule 99" instead.',
    },
    Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + ($self->{'mirror'} ? 1 : 2);
}
use constant sumxy_minimum => 0;  # triangular X>=-Y so X+Y>=0
use constant diffxy_maximum => 0; # triangular X<=Y so X-Y<=0
use constant dx_maximum => 3;
use constant dy_minimum => 0;
use constant dy_maximum => 1;

sub absdx_minimum {
  my ($self) = @_;
  return ($self->{'mirror'} ? 0 : 1);
}
use constant dsumxy_maximum => 3;  # straight East dX=+3
use constant ddiffxy_maximum => 3; # straight East dX=+3
use constant dir_maximum_dxdy => (-1,0); # supremum, West and dY=+1 up


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

#            left
# even  y=3     5
#         5    12
#         7    23
#         9    38
# [1,2,3,4], [5,12,23,38]
#
# N = (2 d^2 + d + 2)
#   = (2*$d**2 + $d + 2)
#   = ((2*$d + 1)*$d + 2)
# d = -1/4 + sqrt(1/2 * $n + -15/16)
#   = (-1 + 4*sqrt(1/2 * $n + -15/16)) / 4
#   = (sqrt(8*$n-15)-1)/4
# with Y=2*d+1

# row 19, d=9
# N=173 to N=181 is 9 cells rem=0..8  is d-1
# 1/3 section 3 cells rem=0,1,2  floor((d-1)/3)
# 2/3 section 6 cells
# right solid N=191 to N=200 is 10 of is rem<d
#
# row 21, d=10
# 1/3 section 4 cells rem=0,1,2,3  floor((d-1)/3)
# 2/3 section 6 cells
#
# row 23, d=11
# 1/3 section 4 cells rem=0,1,2,3  floor((d-1)/3)
# 2/3 section 7 cells
#
# row 25, d=12
# 2/3 section 8 cells
#
# row 27, d=13
# 2/3 section 8 cells
#
# row 29, d=14
# 2/3 section 9 cells    floor(2d/3)
#
# row 31, d=15
# 2/3 section 10 cells   floor(2d/3)
#
#
# row 18 d=8
# odd 1/3 section   4 cells  (d+4)/3
#
# row 20 d=9
# odd 1/3 section   4 cells
#
# row 22 d=10
# odd 1/3 section   4 cells
#
# row 23 d=11
# odd 1/3 section   5 cells


sub n_to_xy {
  my ($self, $n) = @_;
  ### CellularRule57 n_to_xy(): $n

  $n = $n - $self->{'n_start'} + 1; # to N=1 basis, and warn if $n undef
  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int;
    $n = $int;       # BigFloat int() gives BigInt, use that
    if (2*$frac >= 1) {
      $frac -= 1;
      $n += 1;
    }
    # -0.5 <= $frac < 0.5
    ### assert: 2*$frac >= -1
    ### assert: 2*$frac < 1
  }

  if ($n <= 1) {
    if ($n == 1) {
      return (0,0);
    } else {
      return;
    }
  }

  # d is the two-row group number, y=2*d+1, where n belongs
  #
  my $d = int( (_sqrtint(8*$n-15)-1)/4 );
  $n -= ((2*$d + 1)*$d + 2);   # remainder
  ### $d
  ### remainder: $n

  if ($self->{'mirror'}) {
    if ($n <= $d) {
      ### right solid: $n
      return ($frac + $n - 2*$d - 1,
              2*$d+1);
    }
    $n -= $d+1;

    if ($n < int(2*$d/3)) {
      ### right 2/3: $n
      return ($frac + int(3*$n/2) - $d + 1,
              2*$d+1);
    }
    $n -= int(2*$d/3);

    if ($n < int(($d+2)/3)) {
      ### left 1/3: $n
      return ($frac + 3*$n + ((2+$d)%3),
              2*$d+1);
    }
    $n -= int(($d+2)/3);

    if ($n < $d) {
      ### left solid: $n
      return ($frac + $n + $d+2,
              2*$d+1);
    }
    $n -= $d;

    if ($n < int((2*$d+5)/3)) {
      ### odd 2/3: $n
      return ($frac + int((3*$n)/2) - $d +  - 1,
              2*$d+2);
    }
    $n -= int((2*$d+5)/3);

    ### odd 1/3: $n
    return ($frac + 3*$n + ($d%3) + 1,
            2*$d+2);

  } else {
    if ($n < $d) {
      ### left solid: $n
      return ($frac + $n - 2*$d - 1,
              2*$d+1);
    }
    $n -= $d;

    if ($n < int(($d+2)/3)) {
      ### left 1/3: $n
      return ($frac + 3*$n - $d + 1,
              2*$d+1);
    }
    $n -= int(($d+2)/3);

    if ($n < int(2*$d/3)) {
      ### right 2/3: $n
      return ($frac + $n + int(($n+(-$d%3))/2) + 1,
              2*$d+1);
    }
    $n -= int(2*$d/3);

    if ($n <= $d) {
      ### right solid: $n
      return ($frac + $d + $n + 1,
              2*$d+1);
    }
    $n -= $d+1;

    if ($n < int(($d+4)/3)) {
      ### odd 1/3: $n
      return ($frac + 3*$n - $d - 1,
              2*$d+2);
    }
    $n -= int(($d+4)/3);

    ### odd 2/3: $n
    return ($frac + $n + int(($n+((1-$d)%3))/2) + 1,
            2*$d+2);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### CellularRule57 xy_to_n(): "$x,$y"

  if ($y < 0
      || $x < -$y
      || $x > $y) {
    ### outside pyramid region ...
    return undef;
  }

  if ($self->{'mirror'}) {
    # mirrored, rule 99

    if ($y % 2) {
      my $d = ($y+1)/2;
      ### odd row, solids, d: $d

      if ($x < -$d) {
        return ($y+1)*$y/2 + $x + 1 + $self->{'n_start'};
      }
      if ($x < 0) {
        ### mirror left 2 of 3 ...
        if (($x += $d+2) % 3) {
          return ($y+1)*$y/2 + $x-int($x/3) - $d + $self->{'n_start'} - 1;
        }
      } elsif ($x > $d) {
        return ($y+1)*$y/2 + $x - $d + $self->{'n_start'};
      } else {
        ### mirror right 1 of 3 ...
        $x += 2-$d;
        unless ($x % 3) {
          return ($y+1)*$y/2 + $x/3 + $self->{'n_start'};
        }
      }

    } else {
      ### even row, sparse ...
      my $d = $y/2;
      if ($x >= 0) {
        ### mirror sparse right 1 of 3 ...
        if ($x <= $d  # only to half way
            && (($x -= $d) % 3) == 0) {
          return ($y+1)*$y/2 + $x/3 + $self->{'n_start'};
        }
      } else { # $x < 0
        ### mirror sparse left 2 of 3 ...
        if ($x >= -$d  # only to half way
            && (($x += $d+1) % 3)) {
          return ($y+1)*$y/2 + $x-int($x/3) - $d + $self->{'n_start'} - 1;
        }
      }
    }
  } else {
    # unmirrored, rule 57

    if ($y % 2) {
      my $d = ($y+1)/2;
      ### odd row, solids, d: $d

      if ($x <= -$d) {
        ### solid left ...
        if ($x < -$d) {  # always skip the -$d cell
          return ($y+1)*$y/2 + $x + 1 + $self->{'n_start'};
        }
      } elsif ($x <= 0) {
        ### 1 of 3 ...
        unless (($x += $d+1) % 3) {
          return ($y+1)*$y/2 + $x/3 - $d + $self->{'n_start'};
        }
      } elsif ($x >= $d) {
        ### solid right ...
        return ($y+1)*$y/2 + $x - $d + $self->{'n_start'};
      } else {
        ### 2 of 3 ...
        $x += 1-$d;
        if ($x % 3) {
          return ($y+1)*$y/2 + $x-int($x/3) + $self->{'n_start'};
        }
      }

    } else {
      ### even row, sparse ...

      my $d = $y/2;
      if ($x > 0) {
        ### right 2 of 3 ...
        if ($x <= $d  # goes to half way only
            && (($x -= $d+1) % 3)) {
          return ($y+1)*$y/2 + $x-int($x/3) + 1 + $self->{'n_start'};
        }
      } else { # $x <= 0
        ### left 1 of 3 ...
        if (($x += $d) >= 0   # goes to half way only
            && ! ($x % 3)) {
          return ($y+1)*$y/2 + $x/3 - $d + $self->{'n_start'};
        }
      }
    }
  }
  return undef;
}

# left edge ((2*$d + 1)*$d + 2)
# where y=2*d+1
#       d=floor((y-1)/2)
# left N = (2*floor((y-1)/2) + 1)*floor((y-1)/2) + 2
#        = (yodd + 1)*yodd/2 + 2


# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### CellularRule57 rect_to_n_range(): "$x1,$y1, $x2,$y2"

  ($x1,$y1, $x2,$y2) = _rect_for_V ($x1,$y1, $x2,$y2)
    or return (1,0); # rect outside pyramid

  my $zero = ($x1 * 0 * $y1 * $x2 * $y2);  # inherit bignum

  $y1 -= ! ($y1 % 2);
  $y2 -= ! ($y2 % 2);
  return ($zero + ($y1 < 1
                   ? $self->{'n_start'}
                   : ($y1-1)*$y1/2 + 1 + $self->{'n_start'}),
          $zero + ($y2+2)*($y2+1)/2 + $self->{'n_start'});
}

1;
__END__

=for stopwords straight-ish Ryde Math-PlanePath ie hexagonals 18-gonal Xmax-Xmin Nleft Nright OEIS

=head1 NAME

Math::PlanePath::CellularRule57 -- cellular automaton 57 and 99 points

=head1 SYNOPSIS

 use Math::PlanePath::CellularRule57;
 my $path = Math::PlanePath::CellularRule57->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Wolfram, Stephen>This is the pattern of Stephen Wolfram's "rule 57"
cellular automaton

=over

L<http://mathworld.wolfram.com/ElementaryCellularAutomaton.html>

=back

arranged as rows

=cut

# math-image --path=CellularRule57 --all --output=numbers --size=132x50

=pod

                51       52       53 54    55 56                 10
    38 39 40 41       42       43    44 45    46 47 48 49 50      9
                   33       34    35    36 37                     8
          23 24 25       26       27 28    29 30 31 32            7
                      19       20    21 22                        6
                12 13       14    15    16 17 18                  5
                          9       10 11                           4
                       5        6     7  8                        3
                             3     4                              2
                                   2                              1
                                1                             <- Y=0

    -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

X<Triangular numbers>The triangular numbers N=10,15,21,28,etc, k*(k+1)/2,
make a 1/2 sloping diagonal upwards.

On rows with odd Y there's a solid block at either end then 1 of 3 cells to
the left and 2 of 3 to the right of the centre.  On even Y rows there's
similar 1 of 3 and 2 of 3 middle parts, but without the solid ends.  Those 1
of 3 and 2 of 3 are successively offset so as to make lines going up towards
the centre as can be seen in the following plot.

=cut

# math-image --text --path=CellularRule57 --all

=pod

    ***********  *  *  *  * * ** ** ** ************
                *  *  *  *  ** ** ** **
      **********  *  *  *  * ** ** ** ***********
                 *  *  *  * * ** ** **
        *********  *  *  *  ** ** ** **********
                  *  *  *  * ** ** **
          ********  *  *  * * ** ** *********
                   *  *  *  ** ** **
            *******  *  *  * ** ** ********
                    *  *  * * ** **
              ******  *  *  ** ** *******
                     *  *  * ** **
                *****  *  * * ** ******
                      *  *  ** **
                  ****  *  * ** *****
                       *  * * **
                    ***  *  ** ****
                        *  * **
                      **  * * ***
                         *  **
                        *  * **
                          * *
                            *
                           *

=head2 Mirror

The C<mirror =E<gt> 1> option gives the mirror image pattern which is "rule
99".  The point numbering shifts but the total points on each row is the
same.

=cut

# math-image --path=CellularRule57,mirror=1 --all --output=numbers --size=132x50

=pod

                51 52    53 54       55       56                  10
    38 39 40 41 42    43 44    45       46       47 48 49 50       9 
                   33 34    35    36       37                      8 
          23 24 25 26    27 28       29       30 31 32             7 
                      19 20    21       22                         6 
                12 13 14    15    16       17 18                   5 
                          9 10       11                            4 
                       5  6     7        8                         3 
                             3     4                               2 
                             2                                     1 
                                1                              <- Y=0

    -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=CellularRule57,n_start=0 --all --output=numbers --size=75x8
# math-image --path=CellularRule57,n_start=0,mirror=1 --all --output=numbers --size=75x8

=pod

    n_start => 0

    22 23 24       25       26 27    28 29 30 31
                18       19    20 21            
          11 12       13    14    15 16 17      
                    8        9 10               
                 4        5     6  7            
                       2     3                  
                             1                  
                          0                     

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::CellularRule57-E<gt>new ()>

=item C<$path = Math::PlanePath::CellularRule57-E<gt>new (mirror =E<gt> $bool, n_start =E<gt> $n)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are each
rounded to the nearest integer, which has the effect of treating each cell
as a square of side 1.  If C<$x,$y> is outside the pyramid or on a skipped
cell the return is C<undef>.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::CellularRule>,
L<Math::PlanePath::CellularRule54>,
L<Math::PlanePath::CellularRule190>,
L<Math::PlanePath::PyramidRows>

L<http://mathworld.wolfram.com/ElementaryCellularAutomaton.html>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

This file is part of Math-PlanePath.

Math-PlanePath is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-PlanePath is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

=cut
