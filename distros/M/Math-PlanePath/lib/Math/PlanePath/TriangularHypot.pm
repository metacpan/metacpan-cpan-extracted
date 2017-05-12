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


# math-image  --path=TriangularHypot

# A034017 - loeschian primatives xx+xy+yy, primes 3k+1 and a factor of 3
#           which is when x^2-x+1 mod n has a solution
#
# A092572 - all x^2+3*y^2
# A158937 - all x^2+3*y^2 with repetitions x>0,y>0
#
# A092572 - 6n+1 primes
# A055664 - norms of Eisenstein-Jacobi primes
# A008458 - hex coordination sequence, 1 and multiples of 6
#
# A2 centred at lattice point:
# A014201 - x*x+x*y+y*y solutions excluding 0,0
# A038589 - lattice sizes, =A014201+1
# A038590 - sizes, uniques of A038589
# A038591 - 3fold symmetry, union A038588 and A038590
#
# A2 centred at hole
# A038587 - centred deep hole
# A038588 - centred deep hole uniques of A038587
# A005882 - theta relative hole
#           3,3,6,0,6,3,6,0,3,6,6,0,6,0,6,0,9,6,0,0,6,3,6,0,6,6,6,0,0,0,12,
# A033685 - theta series of hexagonal lattice A_2 with respect to deep hole.
#           1/3 steps of norm, so extra zeros
#           0,3,0,0,3,0,0,6,0,0,0,0,0,6,0,0,3,0,0,6,0,0,0,0,0,3,0,0,6,0,0,6,
#
# A005929 Theta series of hexagonal net with respect to mid-point of edge.

#                          [27] [28] [31]
#                          [12] [13] [16] [21] [28]
#                 [7]  [4]  [3]  [4]  [7] [12] [19] [28]
# [25] [16]  [9]  [4]  [1]  [0]  [1]  [4]  [9] [16] [25] [36]
#                 [7]  [4]  [3]  [4]  [7]
#                          [12]
#                          [27]

# mirror across +60
#   (X,Y) = ((X+3Y)/2, (Y-X)/2);   # rotate -60
#   Y = -Y;  # mirror
#   (X,Y) = ((X-3Y)/2, (X+Y)/2);    # rotate +60
#
#   (X,Y) = ((X+3Y)/2, (Y-X)/2);   # rotate -60
#   (X,Y) = ((X+3Y)/2, (X-Y)/2);
#
#   (X,Y) = (((X+3Y)/2+3(Y-X)/2)/2, ((X+3Y)/2-(Y-X)/2)/2);
#         = (((X+3Y)+3(Y-X))/4, ((X+3Y)-(Y-X))/4);
#         = ((X + 3Y + 3Y - 3X)/4, (X + 3Y - Y + X)/4);
#         = ((-2X + 6Y)/4, (2X + 2Y)/4);
#         = ((-X + 3Y)/2, (X+Y)/2);
# # eg X=6,Y=0 -> X=-6/2=-3 Y=(6+0)/2=3


package Math::PlanePath::TriangularHypot;
use 5.004;
use strict;
use Carp 'croak';

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [ { name            => 'points',
      share_type      => 'points_eoahrc',
      display         => 'Points',
      type            => 'enum',
      default         => 'even',
      choices         => ['even','odd', 'all',
                          'hex','hex_rotated','hex_centred',
                         ],
      choices_display => ['Even','Odd', 'All',
                          'Hex','Hex Rotated','Hex Centred',
                         ],
      description     => 'Which X,Y points visit, either X+Y even or odd, or all points, or hexagonal grid points.',
    },
    Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

{
  my %x_negative_at_n = (even => 3,
                         odd  => 1,
                         all  => 2,
                         hex         => 2,
                         hex_rotated => 2,
                         hex_centred => 2,
                        );
  sub x_negative_at_n {
    my ($self) = @_;
    return $self->n_start + $x_negative_at_n{$self->{'points'}};
  }
}
{
  my %y_negative_at_n = (even => 5,
                         odd  => 3,
                         all  => 4,
                         hex         => 3,
                         hex_rotated => 3,
                         hex_centred => 4,
                        );
  sub y_negative_at_n {
    my ($self) = @_;
    return $self->n_start + $y_negative_at_n{$self->{'points'}};
  }
}
sub rsquared_minimum {
  my ($self) = @_;
  return ($self->{'points'} eq 'odd'           ? 1   # at X=1,Y=0
          : $self->{'points'} eq 'hex_centred' ? 2   # at X=1,Y=1
          : 0);   # even,all,hex,hex_rotated at X=0,Y=0
}
*sumabsxy_minimum = \&rsquared_minimum;

sub absdiffxy_minimum {
  my ($self) = @_;
  return ($self->{'points'} eq 'odd'
          ? 1     # odd, line X=Y not included
          : 0);   # even,all includes X=Y
}

{
  my %_UNDOCUMENTED__turn_any_left_at_n
    = (even        => 1, 
       odd         => 3,
       all         => 4,
       hex         => 1,
       hex_rotated => 1,
       hex_centred => 1,
      );
  sub _UNDOCUMENTED__turn_any_left_at_n {
    my ($self) = @_;
    my $n = $_UNDOCUMENTED__turn_any_left_at_n{$self->{'points'}};
    return (defined $n ? $self->n_start + $n : undef);
  }
}
{
  # even,hex, left or straight only
  # odd,all both left or right
  my %turn_any_right = (# even => 0,
                        odd  => 1,
                        all  => 1,
                        # hex         => 0,
                        #  hex_rotated => 0,
                        #  hex_centred => 0,
                       );
  sub turn_any_right {
    my ($self) = @_;
    return $turn_any_right{$self->{'points'}};
  }
}

sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'points'} eq 'hex'
          || $self->{'points'} eq 'odd' ? 0   # never straight
          : 1);
}
{
  my %_UNDOCUMENTED__turn_any_straight_at_n
    = (even        => 30, 
       # odd         => undef,  # never straight
       all         => 1,
       # hex         => undef,  # never straight
       hex_rotated => 57,
       hex_centred => 23,
      );
  sub _UNDOCUMENTED__turn_any_straight_at_n {
    my ($self) = @_;
    my $n = $_UNDOCUMENTED__turn_any_straight_at_n{$self->{'points'}};
    return (defined $n ? $self->n_start + $n : undef);
  }
}

#------------------------------------------------------------------------------

sub new {
  ### TriangularHypot new() ...
  my $self = shift->SUPER::new(@_);

  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }

  my $points = ($self->{'points'} ||= 'even');
  if ($points eq 'all') {
    $self->{'n_to_x'} = [0];
    $self->{'n_to_y'} = [0];
    $self->{'hypot_to_n'} = [0];  # N=0 at X=0,Y=0
    $self->{'y_next_x'} = [1-1];
    $self->{'y_next_hypot'} = [3*0**2 + 1**2];
    $self->{'x_inc'} = 1;
    $self->{'x_inc_factor'} = 2;  # ((x+1)^2 - x^2) = 2*x+1
    $self->{'x_inc_squared'} = 1;
    $self->{'symmetry'} = 4;

  } elsif ($points eq 'even') {
    $self->{'n_to_x'} = [0];
    $self->{'n_to_y'} = [0];
    $self->{'hypot_to_n'} = [0];  # N=0 at X=0,Y=0
    $self->{'y_next_x'} = [2-2];
    $self->{'y_next_hypot'} = [3*0**2 + 2**2];
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;  # ((x+2)^2 - x^2) = 4*x+4
    $self->{'x_inc_squared'} = 4;
    $self->{'skip_parity'} = 1;
    $self->{'symmetry'} = 12;

  } elsif ($points eq 'odd') {
    $self->{'n_to_x'} = [];
    $self->{'n_to_y'} = [];
    $self->{'hypot_to_n'} = [];
    $self->{'y_next_x'} = [1-2];
    $self->{'y_next_hypot'} = [1];
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;
    $self->{'x_inc_squared'} = 4;
    $self->{'skip_parity'} = 0;
    $self->{'symmetry'} = 4;

  } elsif ($points eq 'hex') {
    $self->{'n_to_x'} = [0];  # N=0 at X=0,Y=0
    $self->{'n_to_y'} = [0];
    $self->{'hypot_to_n'} = [0];  # N=0 at X=0,Y=0
    $self->{'y_next_x'} = [2-2];
    $self->{'y_next_hypot'} = [2**2 + 3*0**2]; # next at X=2,Y=0
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;  # ((x+2)^2 - x^2) = 4*x+4
    $self->{'x_inc_squared'} = 4;
    $self->{'skip_parity'} = 1;  # should be even
    $self->{'skip_hex'} = 4;     # x+3y==0,2 only
    $self->{'symmetry'} = 6;

  } elsif ($points eq 'hex_rotated') {
    $self->{'n_to_x'} = [0];  # N=0 at X=0,Y=0
    $self->{'n_to_y'} = [0];
    $self->{'hypot_to_n'} = [0];  # N=0 at X=0,Y=0
    $self->{'y_next_x'} = [4-2,
                           1-2];
    $self->{'y_next_hypot'} = [4**2 + 3*0**2, # next at X=4,Y=0
                               1**2 + 3*1**2]; # next at X=1,Y=1
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;  # ((x+2)^2 - x^2) = 4*x+4
    $self->{'x_inc_squared'} = 4;
    $self->{'skip_parity'} = 1;  # should be even
    $self->{'skip_hex'} = 2;     # x+3y==0,4 only
    $self->{'symmetry'} = 6;

  } elsif ($points eq 'hex_centred') {
    $self->{'n_to_x'} = [];
    $self->{'n_to_y'} = [];
    $self->{'hypot_to_n'} = [];
    $self->{'y_next_x'} = [2-2];  # for first at X=2
    $self->{'y_next_hypot'} = [2**2 + 3*0**2]; # at X=2,Y=0
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;  # ((x+2)^2 - x^2) = 4*x+4
    $self->{'x_inc_squared'} = 4;
    $self->{'skip_parity'} = 1;  # should be even
    $self->{'skip_hex'} = 0;     # x+3y==2,4 only
    $self->{'symmetry'} = 12;

  } else {
    croak "Unrecognised points option: ", $points;
  }

  ### $self
  ### assert: $self->{'y_next_hypot'}->[0] == (3 * 0**2 + ($self->{'y_next_x'}->[0]+$self->{'x_inc'})**2)

  return $self;
}

sub _extend {
  my ($self) = @_;
  ### _extend() ...

  my $n_to_x       = $self->{'n_to_x'};
  my $n_to_y       = $self->{'n_to_y'};
  my $hypot_to_n   = $self->{'hypot_to_n'};
  my $y_next_x     = $self->{'y_next_x'};
  my $y_next_hypot = $self->{'y_next_hypot'};

  ### $y_next_x
  ### $y_next_hypot

  # set @y to the Y with the smallest $y_next_hypot->[$y], and if there's some
  # Y's with equal smallest hypot then all those Y's in ascending order
  my @y = (0);
  my $hypot = $y_next_hypot->[0];
  for (my $i = 1; $i < @$y_next_x; $i++) {
    if ($hypot == $y_next_hypot->[$i]) {
      push @y, $i;
    } elsif ($hypot > $y_next_hypot->[$i]) {
      @y = ($i);
      $hypot = $y_next_hypot->[$i];
    }
  }

  ### chosen y list: @y

  # if the endmost of the @$y_next_x, @y_next_hypot arrays are used then
  # extend them by one
  if ($y[-1] == $#$y_next_x) {
    my $y = scalar(@$y_next_x);  # new Y value

    ### highest y: $y[-1]
    ### so grow y: $y

    my $points = $self->{'points'};
    if ($points eq 'even') {
      # h = (3 * $y**2 + $x**2)
      #   = (3 * $y**2 + ($3*y)**2)
      #   = (3*$y*$y + 9*$y*$y)
      #   = (12*$y*$y)
      $y_next_x->[$y] = 3*$y - $self->{'x_inc'};      # X=3*Y, so X-2=3*Y-2
      $y_next_hypot->[$y] = 12*$y*$y;

    } elsif ($points eq 'odd') {
      my $odd = ! ($y%2);
      $y_next_x->[$y] = $odd - $self->{'x_inc'};
      $y_next_hypot->[$y] = 3*$y*$y + $odd;

    } elsif ($points eq 'hex') {
      my $x = $y_next_x->[$y] = (($y % 3) == 1 ? $y : $y-2);
      $x += 2;
      $y_next_hypot->[$y] = $x*$x + 3*$y*$y;
      ### assert: (($x+$y*3) % 6 == 0 || ($x+$y*3) % 6 == 2)

    } elsif ($points eq 'hex_rotated') {
      my $x = $y_next_x->[$y] = (($y % 3) == 2 ? $y : $y-2);
      $x += 2;
      $y_next_hypot->[$y] = $x*$x + 3*$y*$y;
      ### assert: (($x+$y*3) % 6 == 4 || ($x+$y*3) % 6 == 0)

    } elsif ($points eq 'hex_centred') {
      my $x = $y_next_x->[$y] = 3*$y;
      $x += 2;
      $y_next_hypot->[$y] = $x*$x + 3*$y*$y;
      ### assert: (($x+$y*3) % 6 == 2 || ($x+$y*3) % 6 == 4)

    } else {
      ### assert: $points eq 'all'
      $y_next_x->[$y] = - $self->{'x_inc'};      # X=0, so X-1=0
      $y_next_hypot->[$y] = 3*$y*$y;
    }

    ### new y_next_x (with adjustment): $y_next_x->[$y]+$self->{'x_inc'}
    ### new y_next_hypot: $y_next_hypot->[$y]

    ### assert: ($points ne 'even' || (($y ^ ($y_next_x->[$y]+$self->{'x_inc'})) & 1) == 0)
    ### assert: $y_next_hypot->[$y] == (3 * $y**2 + ($y_next_x->[$y]+$self->{'x_inc'})**2)
  }

  # @x is the $y_next_x->[$y] for each of the @y smallests, and step those
  # selected elements next X and hypot for that new X,Y
  my @x = map {
    ### assert: (3 * $_**2 + ($y_next_x->[$_]+$self->{'x_inc'})**2) == $y_next_hypot->[$_]

    my $x = ($y_next_x->[$_] += $self->{'x_inc'});
    ### map y _: $_
    ### map inc x to: $x
    if (defined $self->{'skip_hex'}
         && ($x+2 + 3*$_) % 6 == $self->{'skip_hex'}) {
      ### extra inc for hex ...
      $y_next_x->[$_] += 2;
      $y_next_hypot->[$_] += 8*$x+16;   # (X+4)^2-X^2 = 8X+16
    } else {
      $y_next_hypot->[$_]
        += $self->{'x_inc_factor'}*$x + $self->{'x_inc_squared'};
    }

    ### $x
    ### y_next_x (including adjust): $y_next_x->[$_]+$self->{'x_inc'}
    ### y_next_hypot[]: $y_next_hypot->[$_]

    ### assert: $y_next_hypot->[$_] == (3 * $_**2 + ($y_next_x->[$_]+$self->{'x_inc'})**2)
    ### assert: $self->{'points'} ne 'hex' || (($x+3*$_) % 6 == 0 || ($x+3*$_) % 6 == 2)
    ### assert: $self->{'points'} ne 'hex_rotated' || (($x+$_*3) % 6 == 4 || ($x+$_*3) % 6 == 0)
    ### assert: $self->{'points'} ne 'hex_centred' || (($x+$_*3) % 6 == 2 || ($x+$_*3) % 6 == 4)

    $x
  } @y;
  ### $hypot

  my $p2;
  if ($self->{'symmetry'} == 12) {
    ### base twelvth: join(' ',map{"$x[$_],$y[$_]"} 0 .. $#x)
    my $p1 = scalar(@y);
    my @base_x = @x;
    my @base_y = @y;
    unless ($y[0]) { # no mirror of x,0
      shift @base_x;
      shift @base_y;
    }
    if ($x[-1] == 3*$y[-1]) { # no mirror of x=3*y line
      pop @base_x;
      pop @base_y;
    }
    $#x = $#y = ($p1+scalar(@base_x))*6-1;  # pre-extend arrays
    for (my $i = $#base_x; $i >= 0; $i--) {
      $x[$p1]   = ($base_x[$i] + 3*$base_y[$i]) / 2;
      $y[$p1++] = ($base_x[$i] - $base_y[$i]) / 2;
    }
    ### with mirror 30: join(' ',map{"$x[$_],$y[$_]"} 0 .. $p1-1)

    $p2 = 2*$p1;
    foreach my $i (0 .. $p1-1) {
      $x[$p1]   = ($x[$i] - 3*$y[$i])/2;   # rotate +60
      $y[$p1++] = ($x[$i] + $y[$i])/2;

      $x[$p2]   = ($x[$i] + 3*$y[$i])/-2;  # rotate +120
      $y[$p2++] = ($x[$i] - $y[$i])/2;
    }
    ### with rotates 60,120: join(' ',map{"$x[$_],$y[$_]"} 0 .. $p2-1)

    foreach my $i (0 .. $p2-1) {
      $x[$p2]   = -$x[$i];        # rotate 180
      $y[$p2++] = -$y[$i];
    }
    ### with rotate 180: join(' ',map{"$x[$_],$y[$_]"} 0 .. $#x)

  } elsif ($self->{'symmetry'} == 6) {
    my $p1 = scalar(@x);
    my @base_x = @x;
    my @base_y = @y;
    unless ($y[0]) { # no mirror of x,0
      shift @base_x;
      shift @base_y;
    }
    if ($x[-1] == $y[-1]) { # no mirror of X=Y line
      pop @base_x;
      pop @base_y;
    }
    ### base xy: join(' ',map{"$base_x[$_],$base_y[$_]"} 0 .. $#base_x)

    for (my $i = $#base_x; $i >= 0; $i--) {
      $x[$p1]   = ($base_x[$i] - 3*$base_y[$i]) / -2;   # mirror +60
      $y[$p1++] = ($base_x[$i] + $base_y[$i]) / 2;
    }
    ### with mirror 60: join(' ',map{"$x[$_],$y[$_]"} 0 .. $p1-1)

    $p2 = 2*$p1;
    foreach my $i (0 .. $#x) {
      $x[$p1]   = ($x[$i] + 3*$y[$i])/-2;  # rotate +120
      $y[$p1++] = ($x[$i] - $y[$i])/2;

      $x[$p2]   = ($x[$i] - 3*$y[$i])/-2;  # rotate +240 == -120
      $y[$p2++] = ($x[$i] + $y[$i])/-2;

      # should be on correct grid
      # ### assert: (($x[$p1-1]+$y[$p1-1]*3) % 6 == 0 || ($x[$p1-1]+$y[$p1-1]*3) % 6 == 2)
      # ### assert: (($x[$p2-1]+$y[$p2-1]*3) % 6 == 0 || ($x[$p2-1]+$y[$p2-1]*3) % 6 == 2)
    }
    ### with rotates 120,240: join(' ',map{"$x[$_],$y[$_]"} 0 .. $p2-1)

  } else {
    ### assert: $self->{'symmetry'} == 4
    ### base quarter: join(' ',map{"$x[$_],$y[$_]"} 0 .. $#x)
    my $p1 = $#x;
    push @y, reverse @y;
    push @x, map {-$_} reverse @x;
    if ($x[$p1] == 0) {
      splice @x, $p1, 1;  # don't duplicate X=0 in mirror
      splice @y, $p1, 1;
    }
    if ($y[-1] == 0) {
      pop @y;  # omit final Y=0 ready for rotate
      pop @x;
    }
    $p2 = scalar(@y);
    ### with mirror +90: join(' ',map{"$x[$_],$y[$_]"} 0 .. $p2-1)

    foreach my $i (0 .. $p2-1) {
      $x[$p2]   = -$x[$i];        # rotate 180
      $y[$p2++] = -$y[$i];
    }
    ### with rotate 180: join(' ',map{"$x[$_],$y[$_]"} 0 .. $#x)
  }

  ### store: join(' ',map{"$x[$_],$y[$_]"} 0 .. $#x)
  ### at n: scalar(@$n_to_x)
  ### hypot_to_n: "h=$hypot n=".scalar(@$n_to_x)
  $hypot_to_n->[$hypot] = scalar(@$n_to_x);
  push @$n_to_x, @x;
  push @$n_to_y, @y;

  # ### hypot_to_n now: join(' ',map {defined($hypot_to_n->[$_]) && "h=$_,n=$hypot_to_n->[$_]"} 0 .. $#hypot_to_n)
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### TriangularHypot n_to_xy(): $n

  $n = $n - $self->{'n_start'};  # starting $n==0, warn if $n==undef
  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $int = int($n);
  $n -= $int;  # fraction part

  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};

  while ($int >= $#$n_to_x) {
    _extend($self);
  }

  my $x = $n_to_x->[$int];
  my $y = $n_to_y->[$int];
  return ($x + $n * ($n_to_x->[$int+1] - $x),
          $y + $n * ($n_to_y->[$int+1] - $y));
}

sub xy_is_visited {
  my ($self, $x, $y) = @_;

  if (defined $self->{'skip_parity'}) {
    $x = round_nearest ($x);
    $y = round_nearest ($y);
    if ((($x%2) ^ ($y%2)) == $self->{'skip_parity'}) {
      ### XY wrong parity, no point ...
      return 0;
    }
  }
  if (defined $self->{'skip_hex'}) {
    $x = round_nearest ($x);
    $y = round_nearest ($y);
    if ((($x%6) + 3*($y%6)) % 6 == $self->{'skip_hex'}) {
      ### XY wrong hex, no point ...
      return 0;
    }
  }
  return 1;
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### TriangularHypot xy_to_n(): "$x, $y    points=$self->{'points'}"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  ### parity xor: ($x%2) ^ ($y%2)
  ### hex modulo: (($x%6) + 3*($y%6)) % 6
  if (defined $self->{'skip_parity'}
      && (($x%2) ^ ($y%2)) == $self->{'skip_parity'}) {
    ### XY wrong parity, no point ...
    return undef;
  }
  if (defined $self->{'skip_hex'}
      && (($x%6) + 3*($y%6)) % 6 == $self->{'skip_hex'}) {
    ### XY wrong hex, no point ...
    return undef;
  }


  my $hypot = 3*$y*$y + $x*$x;
  if (is_infinite($hypot)) {
    # avoid infinite loop extending @hypot_to_n
    return undef;
  }
  ### $hypot

  my $hypot_to_n = $self->{'hypot_to_n'};
  my $n_to_x     = $self->{'n_to_x'};
  my $n_to_y     = $self->{'n_to_y'};

  while ($hypot > $#$hypot_to_n) {
    _extend($self);
  }
  my $n = $hypot_to_n->[$hypot];
  for (;;) {
    if ($x == $n_to_x->[$n] && $y == $n_to_y->[$n]) {
      return $n + $self->{'n_start'};
    }
    $n += 1;

    if ($n_to_x->[$n]**2 + 3*$n_to_y->[$n]**2 != $hypot) {
      ### oops, hypot_to_n no good ...
      return undef;
    }
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = abs (round_nearest ($x1));
  $y1 = abs (round_nearest ($y1));
  $x2 = abs (round_nearest ($x2));
  $y2 = abs (round_nearest ($y2));

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }

  # xyradius r^2 = 1/4 * $x2**2 + 3/4 * $y2**2
  # (r+1/2)^2 = r^2 + r + 1/4
  # circlearea = pi*(r+1/2)^2
  # each hexagon area outradius 1/2 is hexarea = sqrt(27/64)

  my $r2 = $x2*$x2 + 3*$y2*$y2;
  my $n = (3.15 / sqrt(27/64) / 4) * ($r2 + sqrt($r2))
    * (3 - $self->{'x_inc'});  # *2 for odd or even, *1 for all
  return ($self->{'n_start'},
          $self->{'n_start'} + int($n));
}

1;
__END__

=for stopwords Ryde Math-PlanePath hypot ie OEIS

=head1 NAME

Math::PlanePath::TriangularHypot -- points of triangular lattice in order of hypotenuse distance

=head1 SYNOPSIS

 use Math::PlanePath::TriangularHypot;
 my $path = Math::PlanePath::TriangularHypot->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path visits X,Y points on a triangular "A2" lattice in order of their
distance from the origin 0,0 and anti-clockwise around from the X axis among
those of equal distance.

=cut

# math-image --all --output=numbers --path=TriangularHypot

=pod

             58    47    39    46    57                 4

          48    34    23    22    33    45              3

       40    24    16     9    15    21    38           2

    49    25    10     4     3     8    20    44        1

       35    17     5     1     2    14    32      <- Y=0

    50    26    11     6     7    13    31    55       -1

       41    27    18    12    19    30    43          -2

          51    36    28    29    37    54             -3

             60    52    42    53    61                -4

                          ^
    -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

The lattice is put on a square X,Y grid using every second point per
L<Math::PlanePath/Triangular Lattice>.  Scaling X/2,Y*sqrt(3)/2 gives
equilateral triangles of side length 1 making a distance from X,Y to the
origin

    dist^2 = (X/2^2 + (Y*sqrt(3)/2)^2
           = (X^2 + 3*Y^2) / 4

For example N=19 at X=2,Y=-2 is sqrt((2**2+3*-2**2)/4) = sqrt(4) from the
origin.  The next smallest after that is X=5,Y=1 at sqrt(7).  The key part
is X^2 + 3*Y^2 as the distance measure to order the points.

=head2 Equal Distances

Points with the same distance are taken in anti-clockwise order around from
the X axis.  For example N=14 at X=4,Y=0 is sqrt(4) from the origin, and so
are the rotated X=2,Y=2 and X=-2,Y=2 etc in other sixth segments, for a
total 6 points N=14 to N=19 all the same distance.

Symmetry means there's a set of 6 or 12 points with the same distance, so
the count of same-distance points is always a multiple of 6 or 12.  There
are 6 symmetric points when on the six radial lines X=0, X=Y or X=-Y, and on
the lines Y=0, X=3*Y or X=-3*Y which are midway between them.  There's 12
symmetric points for anything else, ie. anything in the twelve slices
between those twelve lines.  The first set of 12 equal is N=20 to N=31 all
at sqrt(28).

There can also be further ways for the same distance to arise, as multiple
solutions to X^2+3*Y^3=d^2, but the 6-way or 12-way symmetry means there's
always a multiple of 6 or 12 in total.

=head2 Odd Points

Option C<points =E<gt> "odd"> visits just the odd points, meaning sum X+Y
odd, which is X,Y one odd the other even.

=cut

# math-image --path=TriangularHypot,points=odd --output=numbers --expression='i<=70?i:0'

=pod

    points => "odd"
                         69                              5
          66    50    45    44    49    65               4
       58    40    28    25    27    39    57            3
    54    32    20    12    11    19    31    53         2
       36    16     6     3     5    15    35            1
    46    24    10     2     1     9    23    43    <- Y=0
       37    17     7     4     8    18    38           -1
    55    33    21    13    14    22    34    56        -2
       59    41    29    26    30    42    60           -3
          67    51    47    48    52    68              -4
                         70                             -5

                          ^
       -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6

=head2 All Points

Option C<points =E<gt> "all"> visits all integer X,Y points.

=cut

# math-image --path=TriangularHypot,points=all --output=numbers --expression='i<=71?i:0'

=pod

    points => "all"

                64 59 49 44 48 58 63                  3
          69 50 39 30 25 19 24 29 38 47 68            2
          51 35 20 13  8  4  7 12 18 34 46            1
       65 43 31 17  9  3  1  2  6 16 28 42 62    <- Y=0
          52 36 21 14 10  5 11 15 23 37 57           -1
          70 53 40 32 26 22 27 33 41 56 71           -2
                66 60 54 45 55 61 67                 -3

                          ^
       -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6

=head2 Hex Points

Option C<points =E<gt> "hex"> visits X,Y points making a hexagonal grid,

=cut

# math-image --path=TriangularHypot,points=hex --output=numbers --expression='i<=61?i:0' --size=150x20

=pod

    points => "hex"

                         50----42          49----59                    5
                        /        \        /        \
                51----39          27----33          48                 4
               /        \        /        \        /
             43          22----15          21----32                    3
               \        /        \        /        \
                28----16           6----11          26----41           2
               /        \        /        \        /        \
       52----34           7---- 3           5----14          47        1
      /        \        /        \        /        \        /
    60          23----12           1-----2          20----38      <- Y=0
      \        /        \        /        \        /        \
       53----35           8---- 4          10----19          58       -1
               \        /        \        /        \        /
                29----17           9----13          31----46          -2
               /        \        /        \        /
             44          24----18          25----37                   -3
               \        /        \        /        \
                54----40          30----36          57                -4
                        \        /        \        /
                         55----45          56----61                   -5

                                   ^
       -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

N=1 is at the origin X=0,Y=0, then N=2,3,4 are all at X^2+3Y^2=4 away from
the origin, etc.  The joining lines drawn above show the grid pattern but
points are in order of distance from the origin.

The points are all integer X,Y with X+3Y mod 6 == 0 or 2.  This is a subset
of the default "even" points in that X+Y is even but with 1 of each 3 points
skipped to make the hexagonal outline.

=head2 Hex Rotated Points

Option C<points =E<gt> "hex_rotated"> is the same hexagonal points but
rotated around so N=2 is at +60 degrees instead of on the X axis.

=cut

# math-image --path=TriangularHypot,points=hex_rotated --output=numbers --expression='i<=61?i:0' --size=150x20

=pod

    points => "hex_rotated"


                60----50          42----49                             5
               /        \        /        \
             51          33----27          38----48                    4
               \        /        \        /        \
                34----22          15----21          41                 3
               /        \        /        \        /
       43----28          12-----6          14----26                    2
      /        \        /        \        /        \
    52          16-----7           2-----5          32----47           1
      \        /        \        /        \        /        \
       39----23           3-----1          11----20          59   <- Y=0
      /        \        /        \        /        \        /
    53          17-----8           4----10          37----58          -1
      \        /        \        /        \        /
       44----29          13-----9          19----31                   -2
               \        /        \        /        \
                35----24          18----25          46                -3
               /        \        /        \        /
             54          36----30          40----57                   -4
               \        /        \        /
                61----55          45----56                            -5


                                ^
    -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

Points are still numbered from the X axis clockwise.  The sets of points at
equal hypotenuse distances are the same as plain "hex" but the numbering is
changed by the rotation.

The points visited are all integer X,Y with X+3Y mod 6 == 0 or 4.  This grid
can be viewed either as a +60 degree or a +180 degree rotation of the plain
hex.

=head2 Hex Centred Points

Option C<points =E<gt> "hex_centred"> is the same hexagonal grid as hex
above, but with the origin X=0,Y=0 in the centre of a hexagon,

=cut

# math-image --path=TriangularHypot,points=hex_centred --output=numbers --expression='i<=61?i:0' --size=150x20

=pod

    points => "hex_centred"

                         46----45                              5
                        /        \
                39----28          27----38                     4
               /        \        /        \
       47----29          16----15          26----44            3
      /        \        /        \        /        \
    48          17-----9           8----14          43         2
      \        /        \        /        \        /
       30----18           3-----2          13----25            1
      /        \        /        \        /        \
    40          10-----4     .     1-----7          37    <- Y=0
      \        /        \        /        \        /
       31----19           5-----6          24----36           -1
      /        \        /        \        /        \
    49          20----11          12----23          54        -2
      \        /        \        /        \        /
       50----32          21----22          35----53           -3
               \        /        \        /
                41----33          34----42                    -4
                        \        /
                         51----52                             -5

                             ^
    -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

N=1,2,3,4,5,6 are all at X^2+3Y^2=4 away from the origin, then
N=7,8,9,10,11,12, etc.  The points visited are all integer X,Y with X+3Y mod
6 == 2 or 4.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::TriangularHypot-E<gt>new ()>

=item C<$path = Math::PlanePath::TriangularHypot-E<gt>new (points =E<gt> $str)>

Create and return a new hypot path object.  The C<points> option can be

    "even"          only points with X+Y even (the default)
    "odd"           only points with X+Y odd
    "all"           all integer X,Y
    "hex"           hexagonal X+3Y==0,2 mod 6
    "hex_rotated"   hexagonal X+3Y==0,4 mod 6
    "hex_centred"   hexagonal X+3Y==2,4 mod 6

Create and return a new triangular hypot path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n E<lt> 1> the return is an empty list as the first point at X=0,Y=0
is N=1.

Currently it's unspecified what happens if C<$n> is not an integer.
Successive points are a fair way apart, so it may not make much sense to say
give an X,Y position in between the integer C<$n>.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return an integer point number for coordinates C<$x,$y>.  Each integer N is
considered the centre of a unit square and an C<$x,$y> within that square
returns N.

For "even" and "odd" options only every second square in the plane has an N
and if C<$x,$y> is a position not covered then the return is C<undef>.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include,

=over

L<http://oeis.org/A003136> (etc)

=back

    points="even" (the default)
      A003136  norms (X^2+3*Y^2)/4 which occur
      A004016  count of points of norm==n
      A035019    skipping zero counts
      A088534    counting only in the twelfth 0<=X<=Y

The counts in these sequences are expressed as norm = x^2+x*y+y^2.  That x,y
is related to the "even" X,Y on the path here by a -45 degree rotation,

    x = (Y-X)/2           X = 2*(x+y)
    y = (X+Y)/2           Y = 2*(y-x)

    norm = x^2+x*y+y^2
         = ((Y-X)/2)^2 + (Y-X)/2 * (X+Y)/2 + ((X+Y)/2)^2
         = (X^2 + 3*Y^2) / 4

The X^2+3*Y^2 is the dist^2 described above for equilateral triangles of
unit side.  The factor of /4 scales the distance but of course doesn't
change the sets of points of the same distance.

    points="all"
      A092572  norms X^2+3*Y^2 which occur
      A158937  norms X^2+3*Y^2 which occur, X>0,Y>0 with repeats
      A092573  count of points norm==n for X>0,Y>0

      A092574  norms X^2+3*Y^2 which occur for X>0,Y>0, gcd(X,Y)=1
      A092575  count of points norm==n for X>0,Y>0, gcd(X,Y)=1
                 ie. X,Y no common factor

=cut

# ((Y-X)/2)^2 + (Y-X)/2 * (X+Y)/2 + ((X+Y)/2)^2
#  = YY-2XY+XX + YY-XX + XX+2XY+YY   / 4
#  = 3YY + XX

=pod

    points="hex"
      A113062  count of points norm=X^2+3*Y^2=4*n (theta series)
      A113063   divided by 3

    points="hex_centred"
      A217219  count of points norm=X^2+3*Y^2=4*n (theta series)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::Hypot>,
L<Math::PlanePath::HypotOctant>,
L<Math::PlanePath::PixelRings>,
L<Math::PlanePath::HexSpiral>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
