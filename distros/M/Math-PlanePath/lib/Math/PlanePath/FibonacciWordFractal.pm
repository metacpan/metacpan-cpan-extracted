# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


# http://alexis.monnerot-dumaine.neuf.fr/articles/fibonacci%20fractal.pdf
# [gone]
#
# math-image --path=FibonacciWordFractal --output=numbers_dash


package Math::PlanePath::FibonacciWordFractal;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;


#------------------------------------------------------------------------------

my @dir4_to_dx = (0,-1,0,1);
my @dir4_to_dy = (1,0,-1,0);

my $moffset = 0;

sub n_to_xy {
  my ($self, $n) = @_;
  ### FibonacciWordFractal n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  # my $frac;
  # {
  #   my $int = int($n);
  #   $frac = $n - $int;  # inherit possible BigFloat
  #   $n = $int;          # BigFloat int() gives BigInt, use that
  # }
  {
    my $int = int($n);
    ### $int
    ### $n
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;       # BigFloat int() gives BigInt, use that
  }

  my $zero = ($n * 0);  # inherit bignum 0
  my $one = $zero + 1;  # inherit bignum 0

  my @f = ($one, 2+$zero);
  my @xend = ($zero, $zero, $one);     # F3 N=2 X=1,Y=1
  my @yend = ($zero, $one, $one);
  my $level = 2;
  while ($f[-1] < $n) {
    push @f, $f[-1] + $f[-2];

    my ($x,$y);
    my $m = (($level+$moffset) % 6);
    if ($m == 1) {
      $x = $yend[-2];     # T
      $y = $xend[-2];
    } elsif ($m == 2) {
      $x = $yend[-2];     # -90
      $y = - $xend[-2];
    } elsif ($m == 3) {
      $x = $xend[-2];     # T -90
      $y = - $yend[-2];

    } elsif ($m == 4) {
      ### T ...
      $x = $yend[-2];     # T
      $y = $xend[-2];
    } elsif ($m == 5) {
      $x = - $yend[-2];   # +90
      $y = $xend[-2];
    } elsif ($m == 0) {
      $x = - $xend[-2];   # T +90
      $y = $yend[-2];
    }

    push @xend, $xend[-1] + $x;
    push @yend, $yend[-1] + $y;
    $level++;
    ### new: ($level%6)." add $x,$y for $xend[-1],$yend[-1]  for $f[-1]"
  }

  my $x = $zero;
  my $y = $zero;
  my $rot = 0;
  my $transpose = 0;

  while (@xend > 1) {
    ### at: "$x,$y  rot=$rot transpose=$transpose level=$level   n=$n consider f=$f[-1]"
    my $xo = pop @xend;
    my $yo = pop @yend;

    if ($n >= $f[-1]) {
      my $m = (($level+$moffset) % 6);
      $n -= $f[-1];
      ### offset: "$xo, $yo  for levelmod=$m"

      if ($transpose) {
        ($xo,$yo) = ($yo,$xo);
      }
      if ($rot & 2) {
        $xo = -$xo;
        $yo = -$yo;
      }
      if ($rot & 1) {
        ($xo,$yo) = (-$yo,$xo);
      }
      ### apply rot to offset: "$xo, $yo"

      $x += $xo;
      $y += $yo;
      if ($m == 1) {         # F7 N=13 etc
        $transpose ^= 3;  # T
      } elsif ($m == 2) {    # F8 N=21 etc
        # -90
        if ($transpose) {
          $rot++;
        } else {
          $rot--;   # -90
        }
      } elsif ($m == 3) {    # F3 N=2 etc
        # T -90
        if ($transpose) {
          $rot++;
        } else {
          $rot--;   # -90
        }
        $transpose ^= 3;

      } elsif ($m == 4) {    # F4 N=3 etc
        $transpose ^= 3;  # T
      } elsif ($m == 5) {    # F5 N=5 etc
        # +90
        if ($transpose) {
          $rot--;
        } else {
          $rot++;   # +90
        }
      } else {  # ($m == 0)  # F6 N=8 etc
        # T +90
        if ($transpose) {
          $rot--;
        } else {
          $rot++;   # +90
        }
        $transpose ^= 3;
      }
    }
    pop @f;
    $level--;
  }

  # mod 6 twist ?
  # ### final rot: "$rot  transpose=$transpose gives ".(($rot^$transpose)&3)
  # $rot = ($rot ^ $transpose) & 3;
  # $x = $frac * $dir4_to_dx[$rot] + $x;
  # $y = $frac * $dir4_to_dy[$rot] + $y;

  ### final with frac: "$x,$y"
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### FibonacciWordFractal xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  if (is_infinite($x)) {
    return $x;
  }

  $y = round_nearest($y);
  if (is_infinite($y)) {
    return $y;
  }

  my $zero = ($x * 0 * $y);  # inherit bignum 0
  my $one = $zero + 1;       # inherit bignum 0

  my @f = ($one, $zero+2);
  my @xend = ($zero, $one);  # F3 N=2 X=1,Y=1
  my @yend = ($one, $one);
  my $level = 3;

  for (;;) {
    my ($xo,$yo);
    my $m = ($level % 6);
    if ($m == 2) {
      $xo = $yend[-2];     # T
      $yo = $xend[-2];
    } elsif ($m == 3) {
      $xo = $yend[-2];      # -90
      $yo = - $xend[-2];
    } elsif ($m == 4) {
      $xo = $xend[-2];     # T -90
      $yo = - $yend[-2];

    } elsif ($m == 5) {
      ### T
      $xo = $yend[-2];     # T
      $yo = $xend[-2];
    } elsif ($m == 0) {
      $xo = - $yend[-2];     # +90
      $yo = $xend[-2];
    } elsif ($m == 1) {
      $xo = - $xend[-2];     # T +90
      $yo = $yend[-2];
    }

    $xo += $xend[-1];
    $yo += $yend[-1];
    last if ($xo > $x && $yo > $y);

    push @f, $f[-1] + $f[-2];
    push @xend, $xo;
    push @yend, $yo;
    $level++;
    ### new: "level=$level  $xend[-1],$yend[-1]  for N=$f[-1]"
  }

  my $n = 0;
  while ($level >= 2) {
    ### at: "$x,$y  n=$n level=$level consider $xend[-1],$yend[-1] for $f[-1]"

    my $m = (($level+$moffset) % 6);
    if ($m >= 3) {
      ### 3,4,5 X ...
      if ($x >= $xend[-1]) {
        $n += $f[-1];
        $x -= $xend[-1];
        $y -= $yend[-1];
        ### shift to: "$x,$y  levelmod ".$m

        if ($m == 3) {          # F3 N=2 etc
          ($x,$y) = (-$y,$x);  # +90
        } elsif ($m == 4) {     # F4 N=3 etc
          $y = -$y;            # +90 T
        } elsif ($m == 5) {     # F5 N=5 etc
          ($x,$y) = ($y,$x);   # T
        }
        ### rot to: "$x,$y"
        if ($x < 0 || $y < 0) {
          return undef;
        }
      }
    } else {
      ### 0,1,2 Y ...
      if ($y >= $yend[-1]) {
        $n += $f[-1];
        $x -= $xend[-1];
        $y -= $yend[-1];
        ### shift to: "$x,$y  levelmod ".$m

        if ($m == 0) {          # F6 N=8 etc
          ($x,$y) = ($y,-$x);  # -90
        } elsif ($m == 1) {     # F7 N=13 etc
          $x = -$x;            # -90 T
        } elsif ($m == 2) {     # F8 N=21 etc, incl F2 N=1
          ($x,$y) = ($y,$x);   # T
        }
        ### rot to: "$x,$y"
        if ($x < 0 || $y < 0) {
          return undef;
        }
      }
    }

    pop @f;
    pop @xend;
    pop @yend;
    $level--;
  }

  if ($x != 0 || $y != 0) {
    return undef;
  }
  return $n;
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### FibonacciWordFractal rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  ### rect_to_n_range(): "$x1,$y1 to $x2,$y2"

  if ($x2 < 0 || $y2 < 0) {
    return (1, 0);
  }
  foreach ($x1,$x2,$y1,$y2) {
    if (is_infinite($_)) { return (0, $_); }
  }

  my $zero = ($x1 * 0 * $y1 * $x2 * $y2);  # inherit bignum 0
  my $one = $zero + 1;                     # inherit bignum 0

  my $f0 = 1;
  my $f1 = 2;
  my $xend0 = $zero;
  my $xend1 = $one;
  my $yend0 = $one;
  my $yend1 = $one;
  my $level = 3;

  for (;;) {
    my ($xo,$yo);
    my $m = (($level+$moffset) % 6);
    if ($m == 3) {         # at F3 N=2 etc
      $xo = $yend0;     # -90
      $yo = - $xend0;
    } elsif ($m == 4) {    # at F4 N=3 etc
      $xo = $xend0;     # T -90
      $yo = - $yend0;

    } elsif ($m == 5) {    # at F5 N=5 etc
      $xo = $yend0;     # T
      $yo = $xend0;
    } elsif ($m == 0) {    # at F6 N=8 etc
      $xo = - $yend0;   # +90
      $yo = $xend0;
    } elsif ($m == 1) {    # at F7 N=13 etc
      $xo = - $xend0;   # T +90
      $yo = $yend0;
    } else {   #  if ($m == 2) {    # at F8 N=21 etc
      $xo = $yend0;     # T
      $yo = $xend0;
    }

    ($f1,$f0) = ($f1+$f0,$f1);
    ($xend1,$xend0) = ($xend1+$xo,$xend1);
    ($yend1,$yend0) = ($yend1+$yo,$yend1);
    $level++;

    ### consider: "f1=$f1  xy end $xend1,$yend1"
    if ($xend1 > $x2 && $yend1 > $y2) {
      return (0, $f1 - 1);
    }
  }
}

#------------------------------------------------------------------------------

# ENHANCE-ME: is this good?
#
# Points which are on alternate X and Y axes
# n=0    
#  0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144
#        ^        ^          ^           ^
#        0        4         20          88
# F(2+3*level)
# or F(2+6*level) to go X axis each time
#
# sub level_to_n_range {
#   my ($self, $level) = @_;
#   return (0, F(2+3*$level)-1);
# }

1;
__END__

=for stopwords eg Ryde Math-PlanePath Monnerot-Dumaine OEIS

=head1 NAME

Math::PlanePath::FibonacciWordFractal -- turns by Fibonacci word bits

=head1 SYNOPSIS

 use Math::PlanePath::FibonacciWordFractal;
 my $path = Math::PlanePath::FibonacciWordFractal->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Monnerot-Dumaine, Alexis>X<Fibonacci Word>This is an integer version of
the Fibonacci word fractal

=over

Alexis Monnerot-Dumaine, "The Fibonacci Word Fractal", February 2009.
L<http://hal.archives-ouvertes.fr/hal-00367972_v1/>
L<http://hal.archives-ouvertes.fr/docs/00/36/79/72/PDF/The_Fibonacci_word_fractal.pdf>

=back

It makes turns controlled by the "Fibonacci word" sequence, sometimes called
the "golden string".

    11  | 27-28-29    33-34-35          53-54-55    59-60-61
        |  |     |     |     |           |     |     |     |
    10  | 26    30-31-32    36          52    56-57-58    62
        |  |                 |           |                 |
     9  | 25-24          38-37          51-50          64-63
        |     |           |                 |           |
     8  |    23          39    43-44-45    49          65
        |     |           |     |     |     |           |
     7  | 21-22          40-41-42    46-47-48          66-67
        |  |                                               |
     6  | 20    16-15-14                      74-73-72    68
        |  |     |     |                       |     |     |
     5  | 19-18-17    13                      75    71-70-69
        |              |                       |
     4  |          11-12                      76-77         
        |           |                             |         
     3  |          10                            78         
        |           |                             |         
     2  |           9--8                      80-79         
        |              |                       |                
     1  |  1--2--3     7                      81    85-86-87    
        |  |     |     |                       |     |     |    
    Y=0 |  0     4--5--6                      82-83-84    88-89-...
        +-------------------------------------------------------
          X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 

A current direction up,down,left,right is maintained, starting in the up
direction.  The path moves in the current direction and then may turn or go
straight according to the Fibonacci word,

    Fib word
    --------
       0      turn left if even index, right if odd index
       1      straight ahead

The Fibonacci word is reckoned as starting from index=1, so for example at
N=0 draw a line upwards to N=1 and the first Fibonacci word value is 0 and
its position index=1 is odd so turn to the right.

     N     Fibonacci word
    ---    --------------
     1       0    turn right
     2       1    
     3       0    turn right
     4       0    turn left
     5       1
     6       0    turn left
     7       1

The result is self-similar blocks within the first quadrant
XE<gt>=0,YE<gt>=0.  New blocks extend at N values which are Fibonacci
numbers.  For example N=21 a new block begins above, then N=34 a new block
across, N=55 down, N=89 across again, etc.

The new blocks are a copy of the shape starting N=0 but rotated and/or
transposed according to the replication level mod 6,

    level mod 6      new block
    -----------      ---------
         0           transpose
         1                         rotate -90
         2           transpose and rotate -90
         3           transpose
         4                         rotate +90
         5           transpose and rotate +90

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::FibonacciWordFractal-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=cut

# Knott form would overlap, if do that in this same module.
#
# =item C<$n = $path-E<gt>xy_to_n ($x,$y)>
# 
# Return the point number for coordinates C<$x,$y>.  If there's nothing at
# C<$x,$y> then return C<undef>.
# 
# The curve visits an C<$x,$y> twice for various points (all the "inside"
# points).  In the current code the smaller of the two N values is returned.
# Is that the best way?

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include,

=over

L<http://oeis.org/A156596> (etc)

=back

    A156596  - turn sequence, 0=straight,1=right,2=left
    A171587  - abs(dX), so 1=horizontal,0=vertical

    A003849  - Fibonacci word with values 0,1
    A005614  - Fibonacci word with values 1,0
    A003842  - Fibonacci word with values 1,2
    A014675  - Fibonacci word with values 2,1

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DragonCurve>,
L<Math::PlanePath::WythoffArray>

L<Math::NumSeq::FibonacciWord>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
