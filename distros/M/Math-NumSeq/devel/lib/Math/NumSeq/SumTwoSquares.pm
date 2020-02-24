# multiplicity ?


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


# ENHANCE-ME: check the factorization, or a least a few smallish 4n+3 primes


package Math::NumSeq::SumTwoSquares;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Sum of Two Squares');
use constant description => Math::NumSeq::__('Sum of two squares, ie. all numbers which occur as x^2+y^2 for x>=1 and y>=1.');
use constant characteristic_increasing => 1;
use constant i_start => 1;

use constant parameter_info_array =>
  [ {
     name        => 'distinct',
      type        => 'boolean',
      display     => Math::NumSeq::__('Distinct'),
      default     => 0,
      description => Math::NumSeq::__('Distinct x,y squares, meaning 2*(x^2) is excluded.'),
    },
    {
     name        => 'including_zero',
     type        => 'boolean',
     display     => Math::NumSeq::__('Inc Zero'),
     default     => 0,
     description => Math::NumSeq::__('Including x,y=0, so all plain squares x^2 are included (not just the Pythagorean ones like 5^2=3^2+4^2.'),
    },
  ];

sub values_min {
  my ($self) = @_;
  if ($self->{'distinct'}) {
    if ($self->{'including_zero'}) {
      return 1;
    } else {
      return 5;
    }
  } else {
    if ($self->{'including_zero'}) {
      return 0;
    } else {
      return 2;
    }
  }
}

#------------------------------------------------------------------------------
# cf A024507 x,y>0, x!=y
#    A024509 x^2+y^2 with repetitions for different ways each can occur
#    A025284 x^2+y^2 occurring in exactly one way
#    A001844 2n(n+1)+1 is those hypots with Y=H-1 in X^2+Y^2=H^2
#    A057653 odd numbers x^2+y^2
#    A057961 hypot count as radius increases
#    A014198 count x^2+y^2 <= n excluding 0,0

sub oeis_anum {
  my ($self) = @_;
  if ($self->{'distinct'}) {
    if ($self->{'including_zero'}) {
      return undef;
      # return 'A143575';  # x,y=0, x!=y
      # # OEIS-Catalogue: A143575 distinct=1 including_zero=1
    } else {
      return 'A004431'; # x,y!=0, and x!=y
      # OEIS-Catalogue: A004431 distinct=1
    }
  } else {
    if ($self->{'including_zero'}) {
      return 'A001481'; # x,y=0, x==y, so includes plain squares
      # OEIS-Catalogue: A001481 including_zero=1
    } else {
      return 'A000404'; # x,y!=0, x==y
      # OEIS-Catalogue: A000404
    }
  }
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  ### SumTwoSquares rewind() ...
  $self->{'i'} = $self->i_start;
  $self->{'prev_hypot'} = 1;
  if ($self->{'distinct'}) {
    if ($self->{'including_zero'}) {
      #                            y=0  y=1
      $self->{'y_next_x'}     = [   0,        ];
      $self->{'y_next_hypot'} = [   0*0+1*1,  ];
    } else {
      #                                  y=1      y=2
      $self->{'y_next_x'}     = [ undef,  2,       3 ];
      $self->{'y_next_hypot'} = [ undef,  2*2+1*1, 2*2+3*3 ];
    }
  } else {
    if ($self->{'including_zero'}) {
      #                            y=0  y=1
      $self->{'y_next_x'}     = [   0,        ];
      $self->{'y_next_hypot'} = [   0*0+0*0,  ];
      $self->{'prev_hypot'} = -1;
    } else {
      #                                  y=1       y=2
      $self->{'y_next_x'}     = [ undef,  1,        2 ];
      $self->{'y_next_hypot'} = [ undef,  1*1+1*1,  2*2+2*2 ];
    }
  }
  ### $self
}
sub next {
  my ($self) = @_;
  my $prev_hypot = $self->{'prev_hypot'};
  my $y_next_x = $self->{'y_next_x'};
  my $y_next_hypot = $self->{'y_next_hypot'};
  my $found_hypot = 4 * $prev_hypot + 4;
  ### $prev_hypot
  for (my $y = $self->{'including_zero'} ? 0 : 1; $y < @$y_next_x; $y++) {
    my $h = $y_next_hypot->[$y];
    ### consider y: $y
    ### $h
    if ($h <= $prev_hypot) {
      if ($y == $#$y_next_x) {
        my $next_y = $y + 1;
        ### extend to: $next_y
        my $x = ($self->{'distinct'} ? $next_y+1 : $next_y);
        push @$y_next_x, $x;
        push @$y_next_hypot, $x*$x + $next_y*$next_y;
        ### $y_next_x
        ### $y_next_hypot
        ### assert: $y_next_hypot->[$next_y] == $next_y*$next_y + $y_next_x->[$next_y]*$y_next_x->[$next_y]
      }
      do {
        $h = $y_next_hypot->[$y] += 2*($y_next_x->[$y]++)+1;
        ### step y: $y
        ### next x: $y_next_x->[$y]
        ### next hypot: $y_next_hypot->[$y]
        ### assert: $y_next_hypot->[$y] == $y*$y + $y_next_x->[$y]*$y_next_x->[$y]
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

sub pred {
  my ($self, $value) = @_;
  if (_is_infinite($value) || $value != int($value)) {
    return 0;  # don't loop forever if $value is +infinity
  }

  if ($self->{'including_zero'}) {
    my $sqrt = int(sqrt($value));
    if ($value == $sqrt*$sqrt) {
      return 1;
    }
  }

  my $limit = int(sqrt(2*$value)/2);
  for (my $x = 1; $x <= $limit; $x++) {
    my $y = int(sqrt($value - $x*$x));
    if ($x*$x + $y*$y == $value) {
      unless ($self->{'distinct'} && $y == $x) {
        return 1;
      }
    }
  }
  return 0;
}

1;
__END__
