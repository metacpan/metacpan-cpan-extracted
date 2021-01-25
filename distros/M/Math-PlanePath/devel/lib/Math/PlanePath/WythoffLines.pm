# Copyright 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


# x=45,y=10 x=59,y=19  dx=14,dy=9 14/9=1.55
#
# x=42,y=8 x=113,y=52 dx=71,dy=44 71/44=1.613
#
# below
# 32,12 to 36,4 sqrt((32-36)^2+(12-4)^2) = 9
# 84,34 to 99,14 sqrt((84-99)^2+(34-14)^2) = 25
# 180,64 to 216,11 sqrt((180-216)^2+(64-11)^2) = 64
#
# above
# 14,20 to 5,32 sqrt((14-5)^2+(20-32)^2) = 15 = 9*1.618               3
# 34,50 to 14,85 sqrt((34-14)^2+(50-85)^2) = 40 = 25*1.618            5
# 132,158 to 77,247 sqrt((132-77)^2+(158-247)^2) = 104 = 64*1.618     8
# 8,525 to 133,280  sqrt((8-133)^2+(525-280)^2) = 275 = 169*1.618    13

package Math::PlanePath::WythoffLines;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'bit_split_lowtohigh';
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [ { name      => 'shift',
      display   => 'Shift',
      type      => 'integer',
      default   => 0,
      width     => 3,
    },
  ];

# shift  x_minimum() y_minimum()
#  -4       13           8
#  -3        8           5
#  -2        5           3
#  -1        3           2
#   1        2           1
#   0        2           1          ...
#   1        1           1         fib(1)
#   2        1     /---> 0  -----^ fib(0)
#   3        0 <--/      1    a
#   4        1          -1    b
#   5       -1           2    c
#   6        2          -4    d      -4=2*-1-2
#   7       -4           4    e       4=2*2-0
#   8        4         -12          -12=2*-4-4
#   9      -12           9            9=2*4-(-1)
#  10        9         -33
#  11      -33          22           22=3*9-4-1   a(n)=3a(n-2)-a(n-4)-1
#  12       22         -88          -88=2*-33-22     2*a(n-2)-a(n-1)
#  13      -88          56           56=2*22+12        2*a(n-2)-a(n-5)
#  14       56        -232         -232=2*-88-56     2*a(n-2)-a(n-1)
#  15     -232         145          145=2*56+33        2*a(n-2)-a(n-5)
#  16                 -609         -609=2*-232-145
#  17     -609         378          378=2*145-(-88)
#
# shift -4,-12,-33,-88,-232 = 1-Fib(2*s+1)
# shift 9,22,56,145,378,988
#       a(n)=3*a(n-1)-a(n-2)-1

# with $shift reckoned for y_minimum()
sub _calc_minimum {
  my ($shift) = @_;
  if ($shift <= 2) {
    return _fibonacci(2-$shift);
  }
  if ($shift & 1) {
    # shift odd >= 3, so (shift-1)/2 >= 1
    my $a = 1;
    my $b = 2;
    foreach (2 .. ($shift-1)/2) {
      ($a,$b) = ($b, 3*$b-$a-1);
    }
    return $a;
  } else {
    # shift even >= 4
    return 1 - _fibonacci($shift-1);
  }

  # $a = 1;
  # $b = -1;
  # my $c = 2;
  # my $d = -4;
  # my $e = 4;
  # for (my $i = 2; $i < $shift; $i++) {
  #   ($a,$b,$c,$d,$e) = ($b,$c,$d,$e, 2*$d-$e);
  #   $i++;
  #   last unless $i < $shift;
  #   ($a,$b,$c,$d,$e) = ($b,$c,$d,$e, 2*$d-$a);
  # }
  # return $a;
}
sub _fibonacci {
  my ($n) = @_;
  $a = 0;
  $b = 1;
  foreach (1 .. $n) {
    ($a,$b) = ($b,$a+$b);
  }
  return $a;
}
sub x_minimum {
  my ($self) = @_;
  return _calc_minimum($self->{'shift'}-1);
}
sub y_minimum {
  my ($self) = @_;
  return _calc_minimum($self->{'shift'});
}

#------------------------------------------------------------------------------

use Math::PlanePath::WythoffArray;
my $wythoff = Math::PlanePath::WythoffArray->new;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'shift'} ||= 0;
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### WythoffLines n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n) || $n == 0) { return ($n,$n); }

  {
    # fractions on straight line
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

  #   $n -= 1;
  #   my $y = $wythoff->xy_to_n(0,$n);
  #   my $x = $wythoff->xy_to_n(1,$n);



  # 1   2.000,  1.000     1  1_100000  5.000,3.000(5.831)
  # 2   7.000,  4.000     2  1_100000  3.000,2.000(3.606)
  # 3  10.000,  6.000     3  1_100000  5.000,3.000(5.831)
  # 4  15.000,  9.000     4  1_100000  5.000,3.000(5.831)
  # 5  20.000, 12.000     5  1_100000  3.000,2.000(3.606)
  # 6  23.000, 14.000     6  1_100000  5.000,3.000(5.831)
  # 7  28.000, 17.000     7  1_100000  3.000,2.000(3.606)

  my $zero = $n*0;
  # spectrum(Y+1) so Y,Ybefore are notional two values at X=-2 and X=-1
  my $y = $n-1;
  my $x = int((_sqrtint(5*$n*$n) + $n) / 2);
  # ($y,$x) = (1*$x + 1*$y,
  #            2*$x + 1*$y);

  # shift   s to -1
  #         1 to s
  # but forward by 2 extra
  #         s to -1+2=1
  #         1+2=3 to s
  foreach ($self->{'shift'} .. 1) {
    ($y,$x) = ($x,$x+$y);
  }
  foreach (3 .. $self->{'shift'}) {
    # prev+y=x
    # prev = x-y
    ($y,$x) = ($x-$y,$y);
  }
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### WythoffLines xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  # if (is_infinite($y)) { return $y; }

  # unshift
  # 
  foreach ($self->{'shift'} .. -1) {
    ($y,$x) = ($x-$y,$y);
  }
  foreach (1 .. $self->{'shift'}) {
    ($y,$x) = ($x,$x+$y);
  }
  ### unshifted to: "$x,$y"

  if (my ($cy,$ny) = $wythoff->n_to_xy($y)) {
    ### y: "cy=$cy ny=$ny"
    if ($cy == 0) {
      if (my ($cx,$nx) = $wythoff->n_to_xy($x)) {
        if ($cx == 1 && $nx == $ny) {
          return $nx+1;
        }
      }
    }
  }
  return undef;

  # my $y = $wythoff->xy_to_n(0,$n);
  # my $x = $wythoff->xy_to_n(1,$n);
}

sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### WythoffLines rect_to_n_range(): "$x1,$y1  $x2,$y2"

  my $zero = $x1 * 0 * $y1 * $x2 * $y2;
  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  # FIXME: probably not quite right
  my $phi = (1 + sqrt(5+$zero)) / 2;
  return (1,
          max (1,
               int($phi**($self->{'shift'}-2)
                   * max ($x1,$x2, max($y1,$y2)*$phi))));
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath Moore Wythoff Zeckendorf concecutive fibbinary OEIS

=head1 NAME

Math::PlanePath::WythoffLines -- table of Fibonacci recurrences

=head1 SYNOPSIS

 use Math::PlanePath::WythoffLines;
 my $path = Math::PlanePath::WythoffLines->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Kimberling, Clark>This path is the Wythoff preliminary triangle by Clark
Kimberling,

=cut

# math-image  --path=WythoffLines --output=numbers --all --size=60x14

=pod

     13  | 105 118 131 144  60  65  70  75  80  85  90  95 100
     12  |  97 110  47  52  57  62  67  72  77  82  87  92
     11  |  34  39  44  49  54  59  64  69  74  79  84
     10  |  31  36  41  46  51  56  61  66  71  76
      9  |  28  33  38  43  48  53  58  63  26
      8  |  25  30  35  40  45  50  55  23
      7  |  22  27  32  37  42  18  20
      6  |  19  24  29  13  15  17
      5  |  16  21  10  12  14
      4  |   5   7   9  11
      3  |   4   6   8
      2  |   3   2
      1  |   1
    Y=0  |
         +-----------------------------------------------------
           X=0   1   2   3   4   5   6   7   8   9  10  11  12

A coordinate pair Y and X are the start of a Fibonacci style recurrence,

    F[1]=Y, F[2]=X    F[i+i] = F[i] + F[i-1]

Any such sequence eventually becomes a row of the Wythoff array
(L<Math::PlanePath::WythoffArray>) after some number of initial iterations.
The N value at X,Y is the row number of the Wythoff array containing
sequence beginning Y and X.  Rows are numbered starting from 1.  Eg.

    Y=4,X=1 sequence:       4, 1, 5, 6, 11, 17, 28, 45, ...
    row 7 of WythoffArray:                  17, 28, 45, ...
    so N=7 at Y=4,X=1

Conversely a given N is positioned in the triangle according to where row
number N of the Wythoff array "precurses" by running the recurrence in
reverse,

    F[i-1] = F[i+i] - F[i]

It can be shown that such a precurse always reaches a pair Y and X with
YE<gt>=1 and 0E<lt>=XE<lt>Y, hence making the triangular X,Y arrangement
above.

    N=7 WythoffArray row 7 is 17,28,45,73,...
    go backwards from 17,28 by subtraction
       11 = 28 - 17
        6 = 17 - 11
        5 = 11 - 6
        1 = 6 - 5
        4 = 5 - 1
    stop on reaching 4,1 which is Y=4,X=1 satisfying Y>=1 and 0<=X<Y

=head2 Phi Slope Blocks

The effect of each step backwards is to move to successive blocks of values,
with slope golden ratio phi=(sqrt(5)+1)/2.

Suppose no backwards steps were applied, so Y,X were the first two values of
Wythoff row N.  In the example above that would be N=7 at Y=17,X=28.  The
first two values of the Wythoff array are

    Y = W[0,r] = r-1 + floor(r*phi)       # r = row numbered from 1
    X = W[1,r] = r-1 + 2*floor(r*phi)

So this would put N values on a line of slope Y/X = 1/phi = 0.618.  The
portion of that line which falls within 0E<lt>=XE<lt>Y

=cut

# (r-1 + floor(r*phi)) / (r-1 + 2*floor(r*phi))
#   ~= (r-1+r*phi)/(r-1+2*r*phi)
#    = (r*(phi+1) - 1) / (r*(2phi+1) - 1)
#   -> r*(phi+1) / r*(2*phi+1)
#    = (phi+1) / (2*phi+1)
#    = 1/phi = 0.618


=pod

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::WythoffLines-E<gt>new ()>

Create and return a new path object.

=back

=head1 OEIS

The Wythoff array is in Sloane's Online Encyclopedia of Integer Sequences
in various forms,

=over

L<http://oeis.org/A035614> (etc)

=back

    A165360     X
    A165359     Y
    A166309     N by rows

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::WythoffArray>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
