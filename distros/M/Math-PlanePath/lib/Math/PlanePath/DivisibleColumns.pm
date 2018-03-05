# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# A006218 - cumulative count of divisors
#
#   Dirichlet:
#   n * (log(n) + 2*gamma - 1) + O(sqrt(n))  gamma=0.57721... Euler-Mascheroni
#
#   n * (log(n) + 2*gamma - 1) + O(log(n)*n^(1/3))
#
#   Chandrasekharan: bounds
#   n log(n) + (2 gamma - 1) n - 4 sqrt(n) - 1
#   <= a(n) <=
#   n log(n) + (2 gamma - 1) n + 4 sqrt(n)
#
# a(n)=2 * sum[ i=1 to floor(sqrt(n)) of floor(n/i) ] - floor(sqrt(n))^2
#
# cf A003988,A010766 - triangle with values floor(i/j)
#
# http://mathworld.wolfram.com/DirichletDivisorProblem.html
#
# compile-command: "math-image --path=DivisibleColumns --all"
#
# math-image --path=DivisibleColumns --output=numbers --all
#

package Math::PlanePath::DivisibleColumns;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;

use constant parameter_info_array =>
  [ { name      => 'divisor_type',
      share_key => 'divisor_type_allproper',
      display   => 'Divisor Type',
      type      => 'enum',
      choices   => ['all','proper'],
      default   => 'all',
      description => 'Divisor type, with "proper" meaning divisors d<X, so excluding d=X itself.',
    },
    # { name        => 'direction',
    #   share_key   => 'direction_updown',
    #   display     => 'Direction',
    #   type        => 'enum',
    #   default     => 'up',
    #   choices     => ['up','down'],
    #   choices_display => ['Down','Up'],
    #   description => 'Number points upwards or downwards in the columns.',
    # },
    Math::PlanePath::Base::Generic::parameter_info_nstart0(),
  ];

use constant default_n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

# X=2,Y=1 when proper
# X=1,Y=1 when not
sub x_minimum {
  my ($self) = @_;
  return ($self->{'proper'} ? 2 : 1);
}
use constant y_minimum => 1;

sub diffxy_minimum {
  my ($self) = @_;
  # octant Y<=X so X-Y>=0
  return ($self->{'proper'} ? 1 : 0);
}

use constant dx_minimum => 0;
use constant dx_maximum => 1;
use constant dir_maximum_dxdy => (1,-1); # South-East


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);

  my $divisor_type = ($self->{'divisor_type'} ||= 'all');
  $self->{'proper'} = ($divisor_type eq 'proper');  # bool

  $self->{'direction'} ||= 'up';

  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

my @x_to_n = (0,0,1);
sub _extend {
  ### _extend(): $#x_to_n
  my $x = $#x_to_n;
  push @x_to_n, $x_to_n[$x] + _count_divisors($x);

  # if ($x > 2) {
  #   if (($x & 3) == 2) {
  #     $x >>= 1;
  #     $next_n += $x_to_n[$x] - $x_to_n[$x-1];
  #   } else {
  #     $next_n +=
  #   }
  # }
  ### last x: $#x_to_n
  ### second last: $x_to_n[$#x_to_n-2]
  ### last: $x_to_n[$#x_to_n-1]
  ### diff: $x_to_n[$#x_to_n-1] - $x_to_n[$#x_to_n-2]
  ### divisors of: $#x_to_n - 2
  ### divisors: _count_divisors($#x_to_n-2)
  ### assert: $x_to_n[$#x_to_n-1] - $x_to_n[$#x_to_n-2] == _count_divisors($#x_to_n-2)
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### DivisibleColumns n_to_xy(): "$n"

  $n = $n - $self->{'n_start'}; # to N=0 basis, and warn on undef

  # $n<-0.5 works with Math::BigInt circa Perl 5.12, it seems
  if ($n < -0.5) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $frac;
  {
    my $int = int($n);
    if ($n == $int) {
      $frac = 0;
    } else {
      $frac = $n - $int; # -.5 <= $frac < 1
      $n = $int;         # BigFloat int() gives BigInt, use that
      if ($frac > .5) {
        $frac--;
        $n += 1;
        # now -.5 <= $frac < .5
      }
    }
    ### $n
    ### n: "$n"
    ### $frac
    ### assert: $frac >= -.5
    ### assert: $frac < .5
  }
  my $proper = $self->{'proper'} || 0;  # cannot add false '' to BigInt
  ### $proper

  my $x;
  if ($proper) {
    $x = 2;
    ### proper adjusted n: $n
  } else {
    $x = 1;
  }

  for (;;) {
    while ($x > $#x_to_n) {
      _extend();
    }
    $n += $proper;
    ### consider: "n=$n x=$x  x_to_n=".$x_to_n[$x]
    if ($x_to_n[$x] > $n) {
      $x--;
      last;
    }
    $x++;
  }
  $n -= $x_to_n[$x];
  $n -= $proper;
  ### $x
  ### x_to_n: $x_to_n[$x]
  ### x_to_n next: $x_to_n[$x+1]
  ### remainder: $n

  my $y = 1;
  for (;;) {
    unless ($x % $y) {
      if (--$n < 0) {
        return ($x, $frac + $y);
      }
    }
    if (++$y > $x) {
      ### oops, not enough in this column
      return;
    }
  }
}

# Feturn a count of the number of integers dividing $x, including 1 and $x
# itself.   Cf Math::Factor::XS maybe.
sub _count_divisors {
  my ($x) = @_;
  my $ret = 1;
  unless ($x % 2) {
    my $count = 1;
    do {
      $x /= 2;
      $count++;
    } until ($x % 2);
    $ret *= $count;
  }
  my $limit = _sqrtint($x);
  for (my $d = 3; $d <= $limit; $d+=2) {
    unless ($x % $d) {
      my $count = 1;
      do {
        $x /= $d;
        $count++;
      } until ($x % $d);
      $limit = sqrt($x);
      $ret *= $count;
    }
  }
  if ($x > 1) {
    $ret *= 2;
  }
  return $ret;
}

sub xy_is_visited {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  return ($y >= 1
          && ($self->{'proper'}
              ? $x >= 2 && $y <= int($x/2)
              : $x >= 1 && $y <= $x)
          && ($x%$y) == 0);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### DivisibleColumns xy_to_n(): "$x,$y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  my $proper = $self->{'proper'};
  if ($proper) {
    if ($x < 2
        || $y < 1
        || $y > int($x/2)
        || ($x%$y)) {
      return undef;
    }
  } else {
    if ($x < 1
        || $y < 1
        || $y > $x
        || ($x%$y)) {
      return undef;
    }
  }

  while ($#x_to_n < $x) {
    _extend();
  }
  ### x_to_n: $x_to_n[$x]

  my $n = $x_to_n[$x] - ($proper ? $x-1 : 1);
  ### base n: $n

  for (my $i = 1+$proper; $i <= $y; $i++) {
    unless ($x % $i) {
      $n += 1;
    }
  }
  return $n + $self->{'n_start'};
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### DivisibleColumns rect_to_n_range(): "$x1,$y1 $x2,$y2"

  $x1 = round_nearest($x1);
  $y1 = round_nearest($y1);
  $x2 = round_nearest($x2);
  $y2 = round_nearest($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  ### rounded ...
  ### $x2
  ### $y2

  if ($self->{'proper'}) {
    if ($x2 < 2            # rect all negative
        || $y2 < 1         # rect all negative
        || 2*$y1 > $x2) {  # rect all above X=2Y octant
      ### outside proper divisors ...
      return (1, 0);
    }
    if ($x1 < 2) { $x1 = 2; }
  } else {
    if ($x2 < 1           # rect all negative
        || $y2 < 1        # rect all negative
        || $y1 > $x2) {   # rect all above X=Y diagonal
      ### outside all divisors ...
      return (1, 0);
    }
    if ($x1 < 1) { $x1 = 1; }
  }
  if (is_infinite($x2)) {
    return ($self->{'n_start'}, $x2);
  }

  my ($n_lo, $n_hi);
  if ($x1 <= $#x_to_n) {
    $n_lo = $x_to_n[$x1];
  } else {
    $n_lo = _count_divisors_cumulative($x1-1);
  }
  if ($x2 < $#x_to_n) {
    $n_hi = $x_to_n[$x2+1];
  } else {
    $n_hi = _count_divisors_cumulative($x2);
  }
  $n_hi -= 1;

  ### rect at: "x=".($x2+1)." x_to_n=".($x_to_n[$x2+1]||'none')

  if ($self->{'proper'}) {
    $n_lo -= $x1-1;
    $n_hi -= $x2;
  }
  return ($n_lo + $self->{'n_start'},
          $n_hi + $self->{'n_start'});
}

# Return a total count of all the divisors of all the integers 1 to $x
# inclusive.
sub _count_divisors_cumulative {
  my ($x) = @_;
  my $total = 0;
  my $limit = _sqrtint($x);
  foreach my $i (1 .. $limit) {
    $total += int($x/$i);
  }
  return 2*$total - $limit*$limit;
}

1;
__END__

=for stopwords Ryde Math-PlanePath sqrt OEIS

=head1 NAME

Math::PlanePath::DivisibleColumns -- X divisible by Y in columns

=head1 SYNOPSIS

 use Math::PlanePath::DivisibleColumns;
 my $path = Math::PlanePath::DivisibleColumns->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path visits points X,Y where X is divisible by Y going by columns from
Y=1 to YE<lt>=X.

    18 |                                                      57
    17 |                                                   51
    16 |                                                49
    15 |                                             44
    14 |                                          40
    13 |                                       36
    12 |                                    34
    11 |                                 28
    10 |                              26
     9 |                           22                         56
     8 |                        19                      48
     7 |                     15                   39
     6 |                  13                33                55
     5 |                9             25             43
     4 |             7          18          32          47
     3 |          4       12       21       31       42       54
     2 |       2     6    11    17    24    30    38    46    53
     1 |    0  1  3  5  8 10 14 16 20 23 27 29 35 37 41 45 50 52
    Y=0|
       +---------------------------------------------------------
       X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18

Starting N=0 at X=1,Y=1 means the values 1,3,5,8,etc horizontally on Y=1 are
the sums

     i=K
    sum   numdivisors(i)
     i=1

The current implementation is fairly slack and is slow on medium to large N.

=head1 Proper Divisors

C<divisor_type =E<gt> 'proper'> gives only proper divisors of X, meaning
that Y=X itself is excluded.

=cut

# math-image --path=DivisibleColumns,divisor_type=proper --output=numbers --all --size=134

=pod

     9 |                                                      39
     8 |                                                33
     7 |                                          26
     6 |                                    22                38
     5 |                              16             29
     4 |                        11          21          32
     3 |                   7       13       20       28       37
     2 |             3     6    10    15    19    25    31    36
     1 |       0  1  2  4  5  8  9 12 14 17 18 23 24 27 30 34 35
    Y=0|
       +---------------------------------------------------------
       X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18

The pattern is the same, but the X=Y line skipped.  The high line going up
is at Y=X/2, when X is even, that being the highest proper divisor.

=head2 N Start

The default is to number points starting N=0 as shown above.  An optional
C<n_start> can give a different start with the same shape,  For example
to start at 1,

=cut

# math-image --path=DivisibleColumns,n_start=1 --all --output=numbers --size=50x16

=pod

    n_start => 1

     9 |                           23
     8 |                        20
     7 |                     16
     6 |                  14
     5 |               10
     4 |             8          19
     3 |          5       13       22
     2 |       3     7    12    18
     1 |    1  2  4  6  9 11 15 17 21
    Y=0|
       +------------------------------
       X=0  1  2  3  4  5  6  7  8  9

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::DivisibleColumns-E<gt>new ()>

=item C<$path = Math::PlanePath::DivisibleColumns-E<gt>new (divisor_type =E<gt> $str, n_start =E<gt> $n)>

Create and return a new path object.  C<divisor_type> (a string) can be

    "all"       (the default)
    "proper"

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head1 FORMULAS

=head2 Rectangle to N Range

The cumulative divisor count up to and including a given X column can be
calculated from the fairly well-known sqrt formula, a sum from 1 to sqrt(X).

    S = floor(sqrt(X))
                              /   i=S             \
    numdivs cumulative = 2 * |   sum  floor(X/i)   | - S^2
                              \   i=1             /

This means the N range for 0 to X can be calculated without working out all
each column count up to X.  In the current code if column counts have been
worked out then they're used, otherwise this formula.

=head1 OEIS

This pattern is in Sloane's Online Encyclopedia of Integer Sequences in the
following forms,

=over

L<http://oeis.org/A061017> (etc)

=back

    n_start=0 (the default)
      A006218    N on Y=1 row, cumulative count of divisors
      A077597    N on X=Y diagonal, cumulative count divisors - 1

    n_start=1
      A061017    X coord, each n appears countdivisors(n) times
      A027750    Y coord, list divisors of successive k
      A056538    X/Y, divisors high to low

    divisor_type=proper (and default n_start=0)
      A027751    Y coord divisor_type=proper, divisors of successive n
                   (extra initial 1)

    divisor_type=proper, n_start=2
      A208460    X-Y, being X subtract each proper divisor

A208460 has "offset" 2, hence C<n_start=2> to match that.  The same with
all divisors would simply insert an extra 0 for the difference at X=Y.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::CoprimeColumns>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
