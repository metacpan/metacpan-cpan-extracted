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


package Math::PlanePath::CfracDigits;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

use Math::PlanePath::RationalsTree;
*_xy_to_quotients = \&Math::PlanePath::RationalsTree::_xy_to_quotients;

use Math::PlanePath::CoprimeColumns;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant parameter_info_array =>
  [ { name      => 'radix',
      share_key => 'radix2_min1',
      display   => 'Radix',
      type      => 'integer',
      minimum   => 1,
      default   => 2,
      width     => 3,
    },
  ];

use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant x_minimum => 1;
use constant y_minimum => 2;
use constant diffxy_maximum => -1; # upper octant X<=Y-1 so X-Y<=-1
use constant gcdxy_maximum => 1;  # no common factor

# FIXME: believe this is right, but check N+1 always changes Y
sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'radix'} < 3 ? 0 : 1);
}

# radix=1 N=1       has dir4=0
# radix=2 N=5628    has dir4=0 dx=9,dy=0
# radix=3 N=1189140 has dir4=0 dx=1,dy=0
# radix=4 N=169405  has dir4=0 dx=2,dy=0
# always eventually 0 ?
# use constant dir_minimum_dxdy => (1,0);  # the default

# radix=1 N=4    dX=1,dY=-1 for dir4=3.5
# radix=2 N=4413 dX=9,dY=-1
# radix=3 N=9492 dX=3,dY=-1
# ENHANCE-ME: suspect believe approaches 360 degrees, eventually, but proof?
# use constant dir_maximum_dxdy => (0,0);  # the default

sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'radix'} != 1);  # radix=1 never straight
}

sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->{'radix'} + 1;
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return $self->{'radix'};
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  unless ($self->{'radix'} && $self->{'radix'} >= 1) {
    $self->{'radix'} = 2;
  }
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### CfracDigits n_to_xy(): "$n"

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  {
    my $int = int($n);
    if ($n != $int) {
      ### frac ...
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      ### x1,y1: "$x1, $y1"
      ### x2,y2: "$x2, $y2"
      ### dx,dy: "$dx, $dy"
      ### result: ($frac*$dx + $x1).', '.($frac*$dy + $y1)
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;
  }

  my $radix = $self->{'radix'};
  my $zero = ($n * 0);  # inherit bignum 0
  my $x = $zero;
  my $y = 1 + $zero;    # inherit bignum 1

  foreach my $q (_n_to_quotients_bottomtotop($n,$radix,$zero)) {  # bottom to top
    ### at: "$x,$y   q=$q"

    # 1/(q + X/Y) = 1/((qY+X)/Y)
    #             = Y/(qY+X)
    ($x,$y) = ($y, $q*$y + $x);
  }

  ### return: "$x,$y"
  return ($x,$y);
}

# Return a list of quotients bottom to top.  The base3 digits of N are split
# by "3" delimiters and the parts adjusted so the first bottom-most q>=2 and
# the rest q>=1.  The values are ready to be used as continued fraction
# terms.
#
sub _n_to_quotients_bottomtotop {
  my ($n, $radix, $zero) = @_;
  ### _n_to_quotients_bottomtotop(): $n

  my $radix_plus_1 = $radix + 1;
  my @ret;
  my @group;
  foreach my $digit (_digit_split_1toR_lowtohigh($n,$radix_plus_1)) {
    if ($digit == $radix_plus_1) {
      ### @group
      push @ret, _digit_join_1toR_destructive(\@group, $radix, $zero) + 1;
      @group = ();
    } else {
      push @group, $digit;
    }
  }
  ### final group: @group
  push @ret, _digit_join_1toR_destructive(\@group, $radix, $zero) + 1;

  $ret[0] += 1;  # bottom-most is +2 rather than +1

  ### _n_to_quotients_bottomtotop result: @ret
  return @ret;
}

# Return a list of digits 1 <= d <= R which is $n written in $radix, low to
# high digits.
sub _digit_split_1toR_lowtohigh {
  my ($n, $radix) = @_;
  ### assert: $radix >= 1
  ### assert: $n >= 0

  if ($radix == 1) {
    return (1) x $n;
  }
  my @digits = digit_split_lowtohigh($n,$radix);

  # mangle 0 -> R
  my $borrow = 0;
  foreach my $digit (@digits) {   # low to high
    if ($borrow = (($digit -= $borrow) <= 0)) {  # modify array contents
      $digit += $radix;
    }
  }
  if ($borrow) {
    ### assert: $digits[-1] == $radix
    pop @digits;
  }

  return @digits;
}

sub _digit_join_1toR_destructive {
  my ($aref, $radix, $zero) = @_;
  ### assert: $radix >= 1

  if ($radix == 1) {
    return scalar(@$aref);
  }

  # mangle any digit==$radix down to digit=0
  my $carry = 0;
  foreach my $digit (@$aref) {   # low to high
    if ($carry = (($digit += $carry) >= $radix)) {  # modify array contents
      $digit -= $radix;
    }
  }
  if ($carry) {
    push @$aref, 1;
  }

  ### _digit_join_1toR_destructive() result: digit_join_lowtohigh($aref, $radix, $zero)
  return digit_join_lowtohigh($aref, $radix, $zero);
}

sub xy_is_visited {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  return (! ($x < 1 || $y < 2 || $x >= $y)
          && _coprime($x,$y));
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### CfracDigits xy_to_n(): "$x,$y"

  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }
  if ($x < 1 || $y < 2 || $x >= $y) {
    return undef;
  }

  my @quotients = _xy_to_quotients($x,$y)
    or return undef;  # $x,$y have a common factor
  ### @quotients

  # drop initial 0 integer part
  ### assert: $quotients[0] == 0
  shift @quotients;

  return _cfrac_join_toptobottom(\@quotients,
                                 $self->{'radix'},
                                 $x * 0 * $y);   # inherit bignum 0
}

# $aref is a list of continued fraction quotients from top-most to
# bottom-most.  There's no initial integer term in $aref.  Each quotient is
# q >= 1 except the bottom-most which q-1 and so also >=1.
#
sub _cfrac_join_toptobottom {
  my ($aref, $radix, $zero) = @_;
  ### _cfrac_join_toptobottom(): $aref

  my @digits;
  foreach my $q (reverse @$aref) {
    ### assert: $q >= 1
    push @digits, _digit_split_1toR_lowtohigh($q-1, $radix), $radix+1;
  }
  pop @digits;  # no high delimiter
  ### groups digits 1toR: @digits
  return _digit_join_1toR_destructive(\@digits, $radix+1, $zero);
}


# X/Y = F[k]/F[k+1] quotients all 1
# N = all delimiter digits R,R,...,R
#   = 1222...2221
#   = R^k + 2*(R^k+1)/(R-1) - 1
#   = (RR^k - R^k + 2R^k + 2 - R + 1) / (R-1)
#   = (RR^k + R^k - R + 3) / (R-1)
#   = ((R+1)R^k - R + 3) / (R-1)
# take high as "12" = R+2
# k = log(Y)/log(phi)
# N = (R+2) * R ** k
# N = Y ** (log(R)/log(phi))
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### rect_to_n_range()

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  ### $x2
  ### $y2

  #   |    /
  #   |   / x1
  #   |  /  +-----y2
  #   | /   |
  #   |/    +-----
  #
  if ($x2 < 1 || $y2 < 2 || $x1 >= $y2) {
    ### no values, rect outside upper octant ...
    return (1,0);
  }

  my $zero = ($x1 * 0 * $y1 * $x2 * $y2);  # inherit bignum
  my $radix = $self->{'radix'};

  return (0,
          ($radix+3)
          * ($radix+1 + $zero) ** ($radix == 1
                                   ? $y2
                                   : _log_phi_estimate($y2,$radix)));
}

# Return an estimate of log base phi of $x, that being log($x)/log(phi),
# where phi=(1+sqrt(5))/2 the golden ratio.
#
sub _log_phi_estimate {
  my ($x) = @_;
  my ($pow,$exp) = round_down_pow ($x, 2);
  return int ($exp * (log(2) / log((1+sqrt(5))/2)));
}

1;
__END__

=for stopwords eg Ryde OEIS ie Math-PlanePath coprime octant onwards decrement Shallit radix-1 Radix radix HCS 10www w's

=head1 NAME

Math::PlanePath::CfracDigits -- continued fraction terms encoded by digits

=head1 SYNOPSIS

 use Math::PlanePath::CfracDigits;
 my $path = Math::PlanePath::CfracDigits->new (tree_type => 'Kepler');
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Shallit, Jeffrey>This path enumerates reduced fractions
S<0 E<lt> X/Y E<lt> 1> with X,Y no common factor using a method by Jeffrey
Shallit encoding continued fraction terms in digit strings, as per

=over

Jeffrey Shallit, "Number Theory and Formal Languages", part 3,
L<https://cs.uwaterloo.ca/~shallit/Papers/ntfl.ps>

=back

Fractions up to a given denominator are covered by roughly N=den^2.28.  This
is a much smaller N range than the run-length encoding in C<RationalsTree>
and C<FractionsTree> (but is more than C<GcdRationals>).

=cut

# math-image --path=CfracDigits --output=numbers_xy --all --size=78x17

=pod

    15  |    25  27      91          61 115         307     105 104
    14  |    23      48      65             119     111     103
    13  |    22  24  46  29  66  59 113 120 101 109  99  98
    12  |    17              60     114              97
    11  |    16  18  30  64  58 112 118 102  96  95
    10  |    14      28             100      94
     9  |    13  15      20  38      36  35
     8  |     8      21      39      34
     7  |     7   9  19  37  33  32
     6  |     5              31
     5  |     4   6  12  11
     4  |     2      10
     3  |     1   3
     2  |     0
     1  |
    Y=0 |
         ----------------------------------------------------------
        X=0   1   2   3   4   5   6   7   8   9  10  11  12  13  14

A fraction S<0 E<lt> X/Y E<lt> 1> has a finite continued fraction of the
form

                      1
    X/Y = 0 + ---------------------
                            1
              q[1] + -----------------
                                  1
                     q[2] + ------------
                         ....
                                      1
                            q[k-1] + ----
                                     q[k]

    where each  q[i] >= 1
    except last q[k] >= 2


The terms are collected up as a sequence of integers E<gt>=0 by subtracting
1 from each and 2 from the last.

    # each >= 0
    q[1]-1,  q[2]-1, ..., q[k-2]-1, q[k-1]-1, q[k]-2

These integers are written in base-2 using digits 1,2.  A digit 3 is written
between each term as a separator.

    base2(q[1]-1), 3, base2(q[2]-1), 3, ..., 3, base2(q[k]-2)

If a term q[i]-1 is zero then its base-2 form is empty and there's adjacent
3s in that case.  If the high q[1]-1 is zero then a bare high 3, and if the
last q[k]-2 is zero then a bare final 3.  If there's just a single term q[1]
and q[1]-2=0 then the string is completely empty.  This occurs for X/Y=1/2.

The resulting string of 1s,2s,3s is reckoned as a base-3 value with digits
1,2,3 and the result is N.  All possible strings of 1s,2s,3s occur
(including the empty string) and so all integers NE<gt>=0 correspond
one-to-one with an X/Y fraction with no common factor.

Digits 1,2 in base-2 means writing an integer in the form

    d[k]*2^k + d[k-1]*2^(k-1) + ... + d[2]*2^2 + d[1]*2 + d[0]
    where each digit d[i]=1 or 2

Similarly digits 1,2,3 in base-3 which is used for N,

    d[k]*3^k + d[k-1]*3^(k-1) + ... + d[2]*3^2 + d[1]*3 + d[0]
    where each digit d[i]=1, 2 or 3

This is not the same as the conventional binary and ternary radix
representations by digits 0,1 or 0,1,2 (ie. 0 to radix-1).  The effect of
digits 1 to R is to change any 0 digit to instead R and decrement the value
above that position to compensate.

=head2 Axis Values

N=0,1,2,4,5,7,etc in the X=1 column is integers with no digit 0s in ternary.
N=0 is considered no digits at all and so no digit 0.  These points are
fractions 1/Y which are a single term q[1]=Y-1 and hence no "3" separators,
only a run of digits 1,2.  These N values are also those which are the same
when written in digits 0,1,2 as when written in digits 1,2,3, since there's
no 0s or 3s.

N=0,3,10,11,31,etc along the diagonal Y=X+1 are integers which are ternary
"10www..." where the w's are digits 1 or 2, so no digit 0s except the
initial "10".  These points Y=X+1 points are X/(X+1) with continued fraction

                     1
    X/(X+1) =  0 + -------
                        1
                   1 + ---
                        X

so q0=1 and q1=X, giving N="3,X-1" in digits 1,2,3, which is N="1,0,X-1" in
normal ternary.  For example N=34 is ternary "1021" which is leading "10"
and then X-1=7 ternary "21".

=head2 Radix

The optional C<radix> parameter can select another base for the continued
fraction terms, and corresponding radix+1 for the resulting N.  The default
is radix=2 as described above.  Any integer radixE<gt>=1 can be selected.
For example,

=cut

# math-image --path=CfracDigits,radix=5 --output=numbers_xy --all --size=78x17

=pod

    radix => 5

    11  |    10   30  114  469   75  255 1549 1374  240  225
    10  |     9       109                1369       224
     9  |     8   24        74  254       234  223
     8  |     7        78       258        41
     7  |     5   18   73  253  228   40
     6  |     4                  39
     5  |     3   12   42   38
     4  |     2        37
     3  |     1    6
     2  |     0
     1  |
    Y=0 |
         ----------------------------------------------------
        X=0   1    2    3    4    5    6    7    8    9   10

The X=1 column is integers with no digit 0 in base radix+1, so in radix=5
means no 0 digit in base-6.

=head2 Radix 1

The radix=1 case encodes continued fraction terms using only digit 1, which
means runs of q many "1"s to add up to q, and then digit "2" as separator.

    N =  11111 2 1111 2 ... 2 1111 2 11111     base2 digits 1,2
         \---/   \--/         \--/   \---/
         q[1]-1  q[2]-1     q[k-1]-1 q[k]-2

which becomes in plain binary

    N = 100000  10000   ...  10000  011111     base2 digits 0,1
        \----/  \---/        \---/  \----/
         q[1]    q[2]       q[k-1]  q[k]-1

Each "2" becomes "0" in plain binary and carry +1 into the run of 1s above
it.  That carry propagates through those 1s, turning them into 0s, and stops
at the "0" above them (which had been a "2").  The low run of 1s from q[k]-2
has no "2" below it and is therefore unchanged.

=cut

# math-image --path=CfracDigits,radix=1 --output=numbers_xy --all --size=60x12

=pod

    radix => 1

    11  |   511  32  18  21  39  55  29  26  48 767
    10  |   255      17              25     383
     9  |   127  16      19  27      24 191
     8  |    63      10      14      95
     7  |    31   8   9  13  12  47
     6  |    15              23
     5  |     7   4   6  11
     4  |     3       5
     3  |     1   2
     2  |     0
     1  |
    Y=0 |
         -------------------------------------------
        X=0   1   2   3   4   5   6   7   8   9  10

The result is similar to L<Math::PlanePath::RationalsTree/HCS Continued
Fraction>.  But the lowest run is "0111" here, instead of "1000" as it is in
the HCS.  So N-1 here, and a flip (Y-X)/X to map from X/YE<lt>1 here to
instead all rationals for the HCS tree.  For example

    CfracDigits radix=1       RationalsTree tree_type=HCS

    X/Y = 5/6                 (Y-X)/X = 1/5
    is at                     is at
    N = 23 = 0b10111          N = 24 = 0b11000
                ^^^^                      ^^^^

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over

=item C<$path = Math::PlanePath::CfracDigits-E<gt>new ()>

=item C<$path = Math::PlanePath::CfracDigits-E<gt>new (radix =E<gt> $radix)>

Create and return a new path object.

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A032924> (etc)

=back

    radix=1
      A071766    X coordinate (numerator), except extra initial 1

    radix=2 (the default)
      A032924    N in X=1 column, ternary no digit 0 (but lacking N=0)

    radix=3
      A023705    N in X=1 column, base-4 no digit 0 (but lacking N=0)

    radix=4
      A023721    N in X=1 column, base-5 no digit 0 (but lacking N=0)

    radix=10
      A052382    N in X=1 column, decimal no digit 0 (but lacking N=0)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::FractionsTree>,
L<Math::PlanePath::CoprimeColumns>

L<Math::PlanePath::RationalsTree>,
L<Math::PlanePath::GcdRationals>,
L<Math::PlanePath::DiagonalRationals>

L<Math::ContinuedFraction>

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
