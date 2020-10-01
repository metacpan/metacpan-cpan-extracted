# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


# Classic Sequences
# http://oeis.org/classic.html
#
# Clark Kimberling
# http://faculty.evansville.edu/ck6/integer/intersp.html
#
# cf A175004 similar to wythoff but rows recurrence
#            r(n-1)+r(n-2)+1 extra +1 in each step
#            floor(n*phi+2/phi)
#
# cf Stolarsky round_nearest(n*phi)
#    A035506 stolarsky by diagonals
#    A035507   inverse
#    A007067 stolarsky first column

# Maybe:
# my ($x,$y) = $path->pair_to_xy($a,$b);
# Return the $x,$y which has ($a,$b).
# Advance $a,$b if before start of row.

# Carlitz and Hoggatt "Fibonacci Representations", Fibonacci Quarterly,
# volume 10, number 1, January 1972
# http://www.fq.math.ca/10-1.html
# http://www.fq.math.ca/Scanned/10-1/carlitz1.pdf


package Math::PlanePath::WythoffArray;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'bit_split_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant parameter_info_array =>
  [ { name        => 'x_start',
      display     => 'X start',
      type        => 'integer',
      default     => 0,
      width       => 3,
      description => 'Starting X coordinate.',
    },
    { name        => 'y_start',
      display     => 'Y start',
      type        => 'integer',
      default     => 0,
      width       => 3,
      description => 'Starting Y coordinate.',
    },
  ];

use constant default_n_start => 1;
use constant class_x_negative => 0;
use constant class_y_negative => 0;

sub x_minimum {
  my ($self) = @_;
  return $self->{'x_start'};
}
sub y_minimum {
  my ($self) = @_;
  return $self->{'y_start'};
}
use constant absdx_minimum => 1;
use constant dir_maximum_dxdy => (3,-1);  # N=4 to N=5 dX=3,dY=-1

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'x_start'} ||= 0;
  $self->{'y_start'} ||= 0;
  return $self;
}

sub xy_is_visited {
  my ($self, $x, $y) = @_;
  return ((round_nearest($x) >= $self->{'x_start'})
          && (round_nearest($y) >= $self->{'y_start'}));
}

#------------------------------------------------------------------------------
#   4  |  12   20   32   52   84  136  220  356  576  932 1508
#   3  |   9   15   24   39   63  102  165  267  432  699 1131
#   2  |   6   10   16   26   42   68  110  178  288  466  754
#   1  |   4    7   11   18   29   47   76  123  199  322  521
# Y=0  |   1    2    3    5    8   13   21   34   55   89  144
#      +-------------------------------------------------------
#        X=0    1    2    3    4    5    6    7    8    9   10
# 13,8,5,3,2,1
# 4 = 3+1     -> 1
# 6 = 5+1     -> 2
# 9 = 8+1     -> 3
# 12 = 8+3+1  -> 3+1=4
# 14 = 13+1   -> 5

sub n_to_xy {
  my ($self, $n) = @_;
  ### WythoffArray n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n) || $n == 0) { return ($n,$n); }

  {
    # fractions on straight line between integer points
    my $int = int($n);
    if ($n != $int) {
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;
  }

  # f1+f0 > i
  # f0 > i-f1
  # check i-f1 as the stopping point, so that if i=UV_MAX then won't
  # overflow a UV trying to get to f1>=i
  #
  my @fibs;
  {
    my $f0 = ($n * 0);  # inherit bignum 0
    my $f1 = $f0 + 1;   # inherit bignum 1
    while ($f0 <= $n-$f1) {
      ($f1,$f0) = ($f1+$f0,$f1);
      push @fibs, $f1;      # starting $fibs[0]=1
    }
  }
  ### @fibs

  # indices into fib[] which are the Fibonaccis adding up to $n
  my @indices;
  for (my $i = $#fibs; $i >= 0; $i--) {
    ### at: "n=$n f=".$fibs[$i]
    if ($n >= $fibs[$i]) {
      push @indices, $i;
      $n -= $fibs[$i];
      ### sub: "$fibs[$i] to n=$n"
      --$i;
    }
  }
  ### @indices

  # X is low index, ie. how many low 0 bits in Zeckendorf form
  my $x = pop @indices;
  ### $x

  # Y is indices shifted down by $x and 2 more
  my $y = 0;
  my $shift = $x+2;
  foreach my $i (@indices) {
    ### y add: "ishift=".($i-$shift)." fib=".$fibs[$i-$shift]
    $y += $fibs[$i-$shift];
  }
  ### $shift
  ### $y

  return ($x+$self->{'x_start'},$y+$self->{'y_start'});
}

# phi = (sqrt(5)+1)/2
# (y+1)*phi = (y+1)*(sqrt(5)+1)/2
#           = ((y+1)*sqrt(5)+(y+1))/2
#           = (sqrt(5*(y+1)^2)+(y+1))/2
#
# from x=0,y=0
# N = floor((y+1)*Phi) * Fib(x+2) + y*Fib(x+1)
#
sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### WythoffArray xy_to_n(): "$x, $y"

  $x = round_nearest($x) - $self->{'x_start'};
  $y = round_nearest($y) - $self->{'y_start'};
  if ($x < 0 || $y < 0) {
    return undef;
  }

  my $zero = $x * 0 * $y;
  $x += 2;
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  my @bits = bit_split_lowtohigh($x);
  ### @bits
  pop @bits; # discard high 1-bit

  my $yplus1 = $zero + $y+1;   # inherit bigint from $x perhaps

  # spectrum(Y+1) so Y,Ybefore are notional two values at X=-2 and X=-1
  my $ybefore = int((_sqrtint(5*$yplus1*$yplus1) + $yplus1) / 2);
  ### $ybefore

  # k=1, Fk1=F[k-1]=0, Fk=F[k]=1
  my $Fk1 = $zero;
  my $Fk  = 1 + $zero;

  my $add = -2;
  while (@bits) {
    ### remaining bits: @bits
    ### Fk1: "$Fk1"
    ### Fk: "$Fk"

    # two squares and some adds
    # F[2k+1] = 4*F[k]^2 - F[k-1]^2 + 2*(-1)^k
    # F[2k-1] =   F[k]^2 + F[k-1]^2
    # F[2k] = F[2k+1] - F[2k-1]
    #
    $Fk *= $Fk;
    $Fk1 *= $Fk1;
    my $F2kplus1 = 4*$Fk - $Fk1 + $add;
    $Fk1 += $Fk; # F[2k-1]
    my $F2k = $F2kplus1 - $Fk1;

    if (pop @bits) {  # high to low
      $Fk1 = $F2k;     # F[2k]
      $Fk = $F2kplus1; # F[2k+1]
      $add = -2;
    } else {
      # $Fk1 is F[2k-1] already
      $Fk = $F2k;  # F[2k]
      $add = 2;
    }
  }

  ### final pair ...
  ### Fk1: "$Fk1"
  ### Fk: "$Fk"
  ### @bits

  return ($Fk*$ybefore + $Fk1*$y);
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### WythoffArray rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest($x1);
  $y1 = round_nearest($y1);
  $x2 = round_nearest($x2);
  $y2 = round_nearest($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  if ($x2 < $self->{'x_start'} || $y2 < $self->{'y_start'}) {
    ### all outside first quadrant ...
    return (1, 0);
  }

  # bottom left into first quadrant
  $x1 = max($x1, $self->{'x_start'});
  $y1 = max($y1, $self->{'y_start'});

  return ($self->xy_to_n($x1,$y1),    # bottom left
          $self->xy_to_n($x2,$y2));   # top right
}

1;
__END__

=for stopwords eg Ryde ie Math-PlanePath Wythoff Zeckendorf concecutive fibbinary bignum OEIS Stolarsky Morrison's Knott Generalising

=head1 NAME

Math::PlanePath::WythoffArray -- table of Fibonacci recurrences

=head1 SYNOPSIS

 use Math::PlanePath::WythoffArray;
 my $path = Math::PlanePath::WythoffArray->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Morrison, David R.>X<Wythoff array>This path is the Wythoff array by David
R. Morrison

=over

"A Stolarsky Array of Wythoff Pairs", in Collection of Manuscripts Related
to the Fibonacci Sequence, pages 134 to 136, The Fibonacci Association,
1980.  L<http://www.math.ucsb.edu/~drm/papers/stolarsky.pdf>

=back

It's an array of Fibonacci recurrences which positions each N according to
Zeckendorf base trailing zeros.

=cut

# math-image  --path=WythoffArray --output=numbers --all --size=60x16

=pod

     15  |  40   65  105  170  275  445  720 1165 1885 3050 4935
     14  |  38   62  100  162  262  424  686 1110 1796 2906 4702
     13  |  35   57   92  149  241  390  631 1021 1652 2673 4325
     12  |  33   54   87  141  228  369  597  966 1563 2529 4092
     11  |  30   49   79  128  207  335  542  877 1419 2296 3715
     10  |  27   44   71  115  186  301  487  788 1275 2063 3338
      9  |  25   41   66  107  173  280  453  733 1186 1919 3105
      8  |  22   36   58   94  152  246  398  644 1042 1686 2728
      7  |  19   31   50   81  131  212  343  555  898 1453 2351
      6  |  17   28   45   73  118  191  309  500  809 1309 2118
      5  |  14   23   37   60   97  157  254  411  665 1076 1741
      4  |  12   20   32   52   84  136  220  356  576  932 1508
      3  |   9   15   24   39   63  102  165  267  432  699 1131
      2  |   6   10   16   26   42   68  110  178  288  466  754
      1  |   4    7   11   18   29   47   76  123  199  322  521
    Y=0  |   1    2    3    5    8   13   21   34   55   89  144
         +-------------------------------------------------------
           X=0    1    2    3    4    5    6    7    8    9   10

All rows have the Fibonacci style recurrence

    W(X+1) = W(X) + W(X-1)
    eg. X=4,Y=2 is N=42=16+26, sum of the two values to its left

X<Fibonacci numbers>X axis N=1,2,3,5,8,etc is the Fibonacci numbers.
X<Lucas numbers>The row Y=1 above them N=4,7,11,18,etc is the Lucas numbers.

X<Golden Ratio>Y axis N=1,4,6,9,12,etc is the "spectrum" of the golden
ratio, meaning its multiples rounded down to an integer.

    phi = (sqrt(5)+1)/2
    spectrum(k) = floor(phi*k)
    N on Y axis = Y + spectrum(Y+1)

    Eg. Y=5  N=5+floor((5+1)*phi)=14

The recurrence in each row starts as if the row was preceded by two values
Y,spectrum(Y+1) which can be thought of adding to be Y+spectrum(Y+1) on the
Y axis, then Y+2*spectrum(Y+1) in the X=1 column, etc.

If the first two values in a row have a common factor then that factor
remains in all subsequent sums.  For example the Y=2 row starts with two
even numbers N=6,N=10 so all N values in the row are even.

Every N from 1 upwards occurs precisely once in the table.  The recurrence
means that in each row N grows roughly as a power phi^X, the same as the
Fibonacci numbers.  This means they become large quite quickly.

=head2 Zeckendorf Base

X<Zeckendorf Base>The N values are arranged according to trailing zero bits
when N is represented in the Zeckendorf base.  The Zeckendorf base expresses
N as a sum of Fibonacci numbers, choosing at each stage the largest possible
Fibonacci.  For example

    Fibonacci numbers F[0]=1, F[1]=2, F[2]=3, F[3]=5, etc

    45 = 34 + 8 + 3
       = F[7] + F[4] + F[2]
       = 10010100        1-bits at 7,4,2

The Wythoff array written in Zeckendorf base bits is

=cut

# This table printed by tools/wythoff-array-zeck.pl

=pod

      8 | 1000001 10000010 100000100 1000001000 10000010000
      7 |  101001  1010010  10100100  101001000  1010010000
      6 |  100101  1001010  10010100  100101000  1001010000
      5 |  100001  1000010  10000100  100001000  1000010000
      4 |   10101   101010   1010100   10101000   101010000
      3 |   10001   100010   1000100   10001000   100010000
      2 |    1001    10010    100100    1001000    10010000
      1 |     101     1010     10100     101000     1010000
    Y=0 |       1       10       100       1000       10000
        +---------------------------------------------------
              X=0        1         2          3           4

The X coordinate is the number of trailing zeros, or equivalently the index
of the lowest Fibonacci used in the sum.  For example in the X=3 column all
the N's there have F[3]=5 as their lowest term.

The Y coordinate is formed by removing the trailing "0100..00", ie. all
trailing zeros plus the "01" above them.  For example,

    N = 45 = Zeck 10010100
                      ^^^^ strip low zeros and "01" above them
    Y = Zeck(1001) = F[3]+F[0] = 5+1 = 6

The Zeckendorf form never has consecutive "11" bits, because after
subtracting an F[k] the remainder is smaller than the next lower F[k-1].
Numbers with no concecutive "11" bits are sometimes called the fibbinary
numbers (see L<Math::NumSeq::Fibbinary>).

Stripping low zeros is similar to what the C<PowerArray> does with low zero
digits in an ordinary base such as binary (see
L<Math::PlanePath::PowerArray>).  Doing it in the Zeckendorf base is like
taking out powers of the golden ratio phi=1.618.

=head2 Turn Sequence

The path turns

    straight     at N=2 and N=10
    right        N="...101" in Zeckendorf base
    left         otherwise

For example at N=12 the path turns to the right, since N=13 is on the right
hand side of the vector from N=11 to N=12.  It's almost 180-degrees around
and back, but on the right hand side.

      4  | 12
      3  | 
      2  | 
      1  |       11   
    Y=0  |                13
         +--------------------
          X=0  1  2  3  4  5  

This happens because N=12 is Zeckendorf "10101" which ends "..101".  For
such an ending N-1 is "..100" and N+1 is "..1000".  So N+1 has more trailing
zeros and hence bigger X smaller Y than N-1 has.  The way the curve grows in
a "concave" fashion means that therefore N+1 is on the right-hand side.

    | N                        N ending "..101"
    |  
    |                          N+1 bigger X smaller Y
    |      N-1                     than N-1
    |               N+1   
    +--------------------

Cases for N ending "..000", "..010" and "..100" can be worked through to see
that everything else turns left (or the initial N=2 and N=10 go straight
ahead).

On the Y axis all N values end "..01", with no trailing 0s.  As noted above
stripping that "01" from N gives the Y coordinate.  Those N ending "..101"
are therefore at Y coordinates which end "..1", meaning "odd" Y in
Zeckendorf base.

=head2 X,Y Start

Options C<x_start =E<gt> $x> and C<y_start =E<gt> $y> give a starting
position for the array.  For example to start at X=1,Y=1

      4  |    9  15  24  39  63         x_start => 1
      3  |    6  10  16  26  42         y_start => 1
      2  |    4   7  11  18  29 
      1  |    1   2   3   5   8 
    Y=0  | 
         +----------------------
         X=0  1   2   3   4   5

This can be helpful to work in rows and columns numbered from 1 instead of
from 0.  Numbering from X=1,Y=1 corresponds to the array in Morrison's paper
above.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::WythoffArray-E<gt>new ()>

=item C<$path = Math::PlanePath::WythoffArray-E<gt>new (x_start =E<gt> $x, y_start =E<gt> $y)>

Create and return a new path object.  The default C<x_start> and C<y_start>
are 0.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 1 and if C<$n E<lt> 1> then the return is an empty list.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the N point number at coordinates C<$x,$y>.  If C<$xE<lt>0> or
C<$yE<lt>0> (or the C<x_start> or C<y_start> options) then there's no N and
the return is C<undef>.

N values grow rapidly with C<$x>.  Pass in a bignum type such as
C<Math::BigInt> for full precision.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 FORMULAS

=head2 Rectangle to N Range

Within each row increasing X is increasing N, and in each column increasing
Y is increasing N.  So in any rectangle the minimum N is in the lower left
corner and the maximum N is in the upper right corner.

    |               N max
    |     ----------+
    |    |  ^       |
    |    |  |       |
    |    |   ---->  |
    |    +----------
    |   N min
    +-------------------

=head1 OEIS

The Wythoff array is in Sloane's Online Encyclopedia of Integer Sequences
in various forms,

=over

L<http://oeis.org/A035614> (etc)

=back

    x_start=0,y_start=0 (the defaults)
      A035614     X, column numbered from 0
      A191360     X-Y, the diagonal containing N
      A019586     Y, the row containing N
      A083398     max diagonal X+Y+1 for points 1 to N

    x_start=1,y_start=1
      A035612     X, column numbered from 1
      A003603     Y, vertical para-budding sequence

      A143299     Zeckendorf bit count in row Y
      A185735     left-justified row addition
      A186007     row subtraction
      A173028     row multiples
      A173027     row of n * Fibonacci numbers
      A220249     row of n * Lucas numbers

    A003622     N on Y axis, odd Zeckendorfs "..1"
    A020941     N on X=Y diagonal
    A139764     N dropped down to X axis, ie. N value on the X axis,
                  being lowest Fibonacci used in the Zeckendorf form

    A000045     N on X axis, Fibonacci numbers skipping initial 0,1
    A000204     N on Y=1 row, Lucas numbers skipping initial 1,3

    A001950     N+1 of N on Y axis, anti-spectrum of phi
    A022342     N not on Y axis, even Zeckendorfs "..0"
    A000201     N+1 of N not on Y axis, spectrum of phi
    A003849     bool 1,0 if N on Y axis or not, being the Fibonacci word

    A035336     N in second column
    A160997     total N along anti-diagonals X+Y=k

    A188436     turn 1=right,0=left or straight, skip initial five 0s
    A134860     N positions of right turns, Zeckendorf "..101"
    A003622     Y coordinate of right turns, Zeckendorf "..1"

    A114579     permutation N at transpose Y,X
    A083412     permutation N by Diagonals from Y axis downwards
    A035513     permutation N by Diagonals from X axis upwards
    A064274       inverse permutation

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PowerArray>,
L<Math::PlanePath::FibonacciWordFractal>

L<Math::NumSeq::Fibbinary>,
L<Math::NumSeq::Fibonacci>,
L<Math::NumSeq::LucasNumbers>,
L<Math::Fibonacci>,
L<Math::Fibonacci::Phi>

Ron Knott, "Generalising the Fibonacci Series",
L<http://www.maths.surrey.ac.uk/hosted-sites/R.Knott/Fibonacci/fibGen.html#wythoff>

OEIS Classic Sequences, "The Wythoff Array and The Para-Fibonacci Sequence",
L<http://oeis.org/classic.html>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
