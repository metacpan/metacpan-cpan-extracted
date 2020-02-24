# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# FIXME: These are values with at least one prime factor 3k+1 or some such.


package Math::NumSeq::SumXsq3Ysq;
use 5.004;
use strict;
use POSIX 'floor','ceil';
use List::Util 'max';
use List::MoreUtils;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');


# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Loeschian numbers x^2+3*y^2 for all x>=0 and y>=0.');
use constant characteristic_increasing => 2;
use constant i_start => 1;

#------------------------------------------------------------------------------
# cf A003136 - Loeschian x^2+3*y^2 with x>=0,y>=0 and opposite odd/even
#    A158937 - all x^2+3*y^2 with repetitions x>=0,y>=0
#    A092573 - number of solutions to x^2+3*y^2==n
#    A092575 - number of solutions to x^2+3*y^2==n with gcd(x,y)=1
#
#    A034017 loeschian primatives x^2+xy+y^2, primes 3k+1 and a factor of 3
#    A088534 - count x^2+xy+y^2 with 0<=x<=y
#         0 <= (Y-X)/2
#         0 <= Y-X
#         X <= Y
#         (Y-X)/2 <= (X+Y)/2
#         Y-X <= X+Y
#         -X <= X
#         0 <= 2X
#         X >= 0
#         so 0 <= X <= Y octant
#
#    A092572 values x^2+3*y^2 for all integer x,y
#    A092573 count occurrances of x^2+3*y^2
#    A158937 values x^2+3*y^2 with repetitions
#
#    A092574 values x^2+3*y^2 with gcd(x,y)=1
#    A092575 count occurrances of x^2+3*y^2 with gcd(x,y)=1
#
#    A020669 values x^2+5*y^2 for all integer x,y
#    A091727 norms of ideals in sqrt(-5)
#    A091728 num prime ideals of norm n in sqrt(-5)
#
use constant oeis_anum => 'A092572'; # all x^2+3*y^2 x>=1,y>=1

#          4, 7,    12, 13, 16, 19, 21, 28,         31, 36, 37, 39, 43, 48, 49, 52, 57, 61,     
# 0, 1, 3, 4, 7, 9, 12, 13, 16, 19, 21, 25, 27, 28, 31, 36, 37, 39, 43,     


#------------------------------------------------------------------------------
sub rewind {
  my ($self) = @_;
  ### SumXsq3Ysq rewind()
  $self->{'i'} = $self->i_start;
  $self->{'y_next_x'}     = [ undef, 1         ];
  $self->{'y_next_hypot'} = [ undef, 1*1+3*1*1 ];
  $self->{'prev_hypot'} = 1;
  ### assert: $self->{'y_next_hypot'}->[1] == 3*1**2 + $self->{'y_next_x'}->[1]**2
  ### $self
}
sub next {
  my ($self) = @_;
  my $prev_hypot = $self->{'prev_hypot'};
  my $y_next_x = $self->{'y_next_x'};
  my $y_next_hypot = $self->{'y_next_hypot'};
  my $found_hypot = 12 * $prev_hypot + 4;
  ### $prev_hypot
  for (my $y = 1; $y < @$y_next_x; $y++) {
    my $h = $y_next_hypot->[$y];
    ### consider y: $y
    ### $h
    if ($h <= $prev_hypot) {
      if ($y == $#$y_next_x) {
        my $next_y = $y + 1;
        ### extend to: $next_y
        push @$y_next_x, 1;  # x=1
        push @$y_next_hypot, 1 + 3*$next_y*$next_y;
        ### $y_next_x
        ### $y_next_hypot
        ### assert: $y_next_hypot->[$next_y] == 3*$next_y**2 + $y_next_x->[$next_y]**2
      }
      do {
        $h = ($y_next_hypot->[$y] += 2*($y_next_x->[$y]++)+1);
        ### step y: $y
        ### next x: $y_next_x->[$y]
        ### next hypot: $y_next_hypot->[$y]
        ### assert: $y_next_hypot->[$y] == 3*$y**2 + $y_next_x->[$y]**2
      } while ($h <= $prev_hypot);
    }
    ### $h
    if ($h < $found_hypot) {
      ### lower hypot: $y
      $found_hypot = $h;
    }
  }
  $self->{'prev_hypot'} = $found_hypot;
  ### return: $self->{'i'}, $found_hypot
  return ($self->{'i'}++, $found_hypot);
}

# ENHANCE-ME: check the factorization
sub pred {
  my ($self, $n) = @_;
  if ($n == $n-1) {
    return 0;
  }
  my $limit = int(sqrt(($n-($n>0))/3));
  ### $limit
  for (my $y = 1; $y <= $limit; $y++) {
    my $ysq = 3*$y*$y;
    my $x = int(sqrt($n - $ysq));
    if ($x*$x + $ysq == $n) {
      return 1;
    }
  }
  return 0;
}

1;
__END__
