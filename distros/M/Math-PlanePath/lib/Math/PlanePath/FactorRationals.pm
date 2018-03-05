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


# Multiples of prime make grid.

# [13] L. S. Johnston, Denumerability of the rational number system, Amer. Math. Monthly, 55 (Feb.
#      1948), no. 2, 65-70.
# www.jstor.org/stable/2305738


# prime factors q1,..qk of n
# f(m/n) = m^2*n^2/ (q1q2...qk)

# Kevin McCrimmon, 1960
#
# integer prod p[i]^a[i] -> rational prod p[i]^b[i]
# b[i] = a[2i-1] if a[2i-1]!=0
#    b[1]=a[1], b[2]=a[3], b[3]=a[5]
# b[i] = -a[2k] if a[2i-1]=0 and is kth such
#
# b[i] = f(a[i]) where f(n) = (-1)^(n+1) * floor((n+1)/2)
#   f(0) =  0
#   f(1) =  1
#   f(2) = -1
#   f(3) =  2
#   f(4) = -2

# Gerald Freilich, 1965
#
# f(n) = n/2      if n even n>=0
#      = -(n+1)/2 if n odd n>0
# f(0)=0/2      =  0
# f(1)=-(1+1)/2 = -1
# f(2)=2/2      =  1
# f(3)=-(3+1)/2 = -2
# f(4)=4/2      =  2

# Yoram Sagher, "Counting the rationals", American Math Monthly, Nov 1989,
# page 823.  http://www.jstor.org/stable/2324846
#
# m = p1^e1.p2^e2...
# n = q1^f1.q2^f2...
# f(m/n) = p1^2e1.p2^2e2... . q1^(2f1-1).q2^(2f2-1)...
# so     0 -> 0              0 ->  0
#    num 1 -> 2              1 -> -1
#        2 -> 4              2 ->  1
# den -1 1 -> 2*1-1 = 1      3 -> -2
#     -2 2 -> 2*2-1 = 3      4 ->  2

# Umberto Cerruti, "Ordinare i razionali Gli alberi di Keplero e di
# Calkin-Wilf", following T.J. Heard
#   B(2k)=-k   even=negative and zero
#   B(2k-1)=k  odd=positive
#   which is Y/X invert
# B(0 =2*0)   =  0
# B(1 =2*1-1) =  1
# B(2 =2*1)   = -1
# B(3 =2*2-1) =  2
# B(4 =2*2)   = -2


package Math::PlanePath::FactorRationals;
use 5.004;
use strict;
use Carp 'croak';
use List::Util 'min';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'digit_join_lowtohigh';

use Math::PlanePath::CoprimeColumns;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;

# uncomment this to run the ### lines
# use Smart::Comments;


# Not yet.
use constant parameter_info_array =>
  [ { name      => 'factor_coding',
      display   => 'Sign Encoding',
      type      => 'enum',
      default   => 'even/odd',
      choices         => ['even/odd','odd/even',
                          'negabinary','revbinary',
                         ],
      choices_display => ['Even/Odd','Odd/Even',
                          'Negabinary','Revbinary',
                          ],
    },
  ];

use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant x_minimum => 1;
use constant y_minimum => 1;
use constant gcdxy_maximum => 1;  # no common factor
use constant absdy_minimum => 1;

# factor_coding=even/odd
# factor_coding=odd/even
#   dir_minimum_dxdy() suspect dir approaches 0.
#   Eg. N=5324   = 2^2.11^3     dx=3,dy=92   0.97925
#       N=642735 = 3^5.23^2     dX=45 dY=4    Dir4=0.05644
#         642736 = 2^4.17^2.139
#   dir_maximum_dxdy() suspect approaches 360 degrees
#   use constant dir_maximum_dxdy => (0,0);  # the default
#
# factor_coding=negabinary
#   dir_minimum_dxdy() = East 1,0 at N=1
#   dir_maximum_dxdy() believe approaches 360 degrees
#   Eg. N=40=2^3.5 X=5, Y=2
#       N=41=41    X=41, Y=1
#   N=multiple 8 and solitary primes, followed by N+1=prime is dX=big, dY=-1
#
# factor_coding=revbinary
#   dir_maximum_dxdy() approaches 360 degrees  dY=-1, dX=big
#   Eg. N=7208=2^3*17*53 X=17*53  Y=2
#       N=7209=3^4*89    X=3^4*89 Y=1
#                       dX=6308  dY=-1


#------------------------------------------------------------------------------
# even/odd

# $n>=0, return a positive if even or negative if odd
#   $n==0  return  0
#   $n==1  return -1
#   $n==2  return +1
#   $n==3  return -2
#   $n==4  return +2
sub _pos_to_pn__even_odd {
  my ($n) = @_;
  return ($n % 2 ? -1-$n : $n) / 2;
}

# # $n is positive or negative, return even for positive or odd for negative.
# #   $n==0   return 0
# #   $n==-1  return 1
# #   $n==+1  return 2
# #   $n==-2  return 3
# #   $n==+2  return 4
# sub _pn_to_pos__even_odd {
#   my ($n) = @_;
#   return ($n >= 0 ? 2*$n : -1-2*$n);
# }

#------------------------------------------------------------------------------
# odd/even

# $n>=0, return a positive if even or negative if odd
#   $n==0  return  0
#   $n==1  return +1
#   $n==2  return -1
#   $n==3  return +2
#   $n==4  return -2
sub _pos_to_pn__odd_even {
  my ($n) = @_;
  return ($n % 2 ? $n+1 : -$n) / 2;
}

# # $n is positive or negative, return odd for positive or even for negative.
# #   $n==0   return 0
# #   $n==+1  return 1
# #   $n==-1  return 2
# #   $n==+2  return 3
# #   $n==-2  return 4
# sub _pn_to_pos__odd_even {
#   my ($n) = @_;
#   return ($n <= 0 ? -2*$n : 2*$n-1);
# }

#------------------------------------------------------------------------------
# negabinary

sub _pn_to_pos__negabinary {
  my ($n) = @_;
  my @bits;
  while ($n) {
    my $bit = ($n % 2);
    push @bits, $bit;
    $n -= $bit;
    $n /= 2;
    $n = -$n;
  }
  return digit_join_lowtohigh(\@bits, 2,
                              $n); # zero
}
sub _pos_to_pn__negabinary {
  my ($n) = @_;
  return (($n & 0x55555555) - ($n & 0xAAAAAAAA));
}

#------------------------------------------------------------------------------
# revbinary
# A065620  pos -> pn
# A065621  pn(+ve) -> pos
# A048724  pn(-ve) -> pos        n XOR 2n
# A048725  A048724 twice
# cf
# A073122  minimizing by taking +/- powers  cf A072219 A072339

# rev = 2^e0 - 2^e1 + 2^e2 - 2^e3 + ... + (-1)^t*2^et
#       0 <= e0 < e1 < e2 ...
sub _pos_to_pn__revbinary {
  my ($n) = @_;
  my $sign = 1;
  my $ret = 0;
  for (my $bit = 1; $bit <= $n; $bit *= 2) {
    if ($n & $bit) {
      $ret += $bit*$sign;
      $sign = -$sign;
    }
  }
  return $ret;
}
sub _pn_to_pos__revbinary {
  my ($n) = @_;
  my @bits;
  while ($n) {
    my $bit = ($n % 2);
    push @bits, $bit;
    $n -= $bit;
    $n /= 2;
    if ($bit) {
      $n = -$n;
    }
  }
  return digit_join_lowtohigh(\@bits, 2,
                              $n); # zero
}

#------------------------------------------------------------------------------

my %factor_coding__pos_to_pn = ('even/odd' => \&_pos_to_pn__even_odd,
                                'odd/even' => \&_pos_to_pn__odd_even,
                                negabinary => \&_pos_to_pn__negabinary,
                                revbinary  => \&_pos_to_pn__revbinary,
                               );
my %factor_coding__pn_to_pos = (# 'even/odd' => \&_pn_to_pos__even_odd,
                                # 'odd/even' => \&_pn_to_pos__odd_even,
                                negabinary => \&_pn_to_pos__negabinary,
                                revbinary  => \&_pn_to_pos__revbinary,
                               );

sub new {
  my $self = shift->SUPER::new(@_);

  my $factor_coding = ($self->{'factor_coding'} ||= 'even/odd');
  $factor_coding__pos_to_pn{$factor_coding}
    or croak "Unrecognised factor_coding: ",$factor_coding;

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### FactorRationals n_to_xy(): "$n"

  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  # what to do for fractional $n?
  {
    my $int = int($n);
    if ($n != $int) {
      ### frac ...
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;
  }

  my $zero = $n * 0;

  my $pos_to_pn = $factor_coding__pos_to_pn{$self->{'factor_coding'}};
  my $x = my $y = ($n * 0) + 1;  # inherit bignum 1
  my ($limit,$overflow) = _limit($n);
  ### $limit
  my $divisor = 2;
  my $dstep = 1;
  while ($divisor <= $limit) {
    if (($n % $divisor) == 0) {
      my $count = 0;
      for (;;) {
        $count++;
        $n /= $divisor;
        if ($n % $divisor) {
          my $pn = &$pos_to_pn($count);
          ### $count
          ### $pn
          my $pow = ($divisor+$zero) ** abs($pn);
          if ($pn >= 0) {
            $x *= $pow;
          } else {
            $y *= $pow;
          }
          last;
        }
      }
      ($limit,$overflow) = _limit($n);
      ### $limit
    }
    $divisor += $dstep;
    $dstep = 2;
  }
  if ($overflow) {
    ### n too big ...
    return;
  }

  ### remaining $n is prime, count=1: "n=$n"
  my $pn = &$pos_to_pn(1);
  ### $pn
  my $pow = $n ** abs($pn);
  if ($pn >= 0) {
    $x *= $pow;
  } else {
    $y *= $pow;
  }

  ### result: "$x, $y"
  return ($x, $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### FactorRationals xy_to_n(): "x=$x y=$y"

  if ($x < 1 || $y < 1) {
    return undef;  # negatives and -infinity
  }
  if (is_infinite($x)) { return $x; } # +infinity or nan
  if (is_infinite($y)) { return $y; } # +infinity or nan

  if ($self->{'factor_coding'} eq 'negabinary'
      || $self->{'factor_coding'} eq 'revbinary') {
    ### negabinary or revbinary ...
    my $pn_to_pos = $factor_coding__pn_to_pos{$self->{'factor_coding'}};
    my $n = 1;
    my $zero = $x * 0 * $y;

    # Factorize both $x and $y and apply their pn_to_pos encoded powers to
    # make $n.  A common factor between $x and $y is noticed if $divisor
    # divides both.

    my ($limit,$overflow) = _limit(max($x,$y));
    my $dstep = 1;
    for (my $divisor = 2; $divisor <= $limit; $divisor += $dstep, $dstep=2) {
      my $count = 0;
      if ($x % $divisor == 0) {
        if ($y % $divisor == 0) {
          return undef;  # common factor
        }
        while ($x % $divisor == 0) {
          $count++;
          $x /= $divisor;  # mutate loop variable
        }
      } elsif ($y % $divisor == 0) {
        while ($y % $divisor == 0) {
          $count--;
          $y /= $divisor;  # mutate loop variable
        }
      } else {
        next;
      }

      # Here $count > 0 if from $x or $count < 0 if from $y.
      ### $count
      ### pn: &$pn_to_pos($count)

      $count = &$pn_to_pos($count);
      $n *= ($divisor+$zero) ** $count;

      # new search limit, perhaps smaller than before
      ($limit,$overflow) = _limit(max($x,$y));
    }

    if ($overflow) {
      ### x,y too big to find all primes ...
      return undef;
    }

    # Here $x and $y are primes.
    if ($x > 1 && $x == $y) {
      ### common factor final remaining prime x,y ...
      return undef;
    }

    # $x is power p^1 which is negabinary=1 or revbinary=1 so multiply into
    # $n.  $y is power p^-1 and -1 is negabinary=3 so cube and multiply into
    # $n.
    $n *= $x;
    $n *= $y*$y*$y;

    return $n;

  } else {
    ### assert: $self->{'factor_coding'} eq 'even/odd' || $self->{'factor_coding'} eq 'odd/even'
    if ($self->{'factor_coding'} eq 'odd/even') {
      ($x,$y) = ($y,$x);
    }

    # Factorize $y so as to make an odd power of its primes.  Only need to
    # divide out one copy of each prime, but by dividing out them all the
    # $limit to search up to is reduced, usually by a lot.
    #
    # $ymult is $y with one copy of each prime factor divided out.
    # $ychop is $y with all primes divided out as they're found.
    # $y itself is unchanged.
    #
    my $ychop = my $ymult = $y;

    my ($limit,$overflow) = _limit($ychop);
    my $dstep = 1;
    for (my $divisor = 2; $divisor <= $limit; $divisor += $dstep, $dstep=2) {
      next if $ychop % $divisor;

      if ($x % $divisor == 0) {
        ### common factor with X ...
        return undef;
      }
      $ymult /= $divisor;           # one of $divisor divided out
      do {
        $ychop /= $divisor;         # all of $divisor divided out
      } until ($ychop % $divisor);
      ($limit,$overflow) = _limit($ychop);  # new lower $limit, perhaps
    }

    if ($overflow) {
      return undef; # Y too big to find all primes
    }

    # remaining $ychop is a prime, or $ychop==1
    if ($ychop > 1) {
      if ($x % $ychop == 0) {
        ### common factor with X ...
        return undef;
      }
      $ymult /= $ychop;
    }

    return $x*$x * $y*$ymult;
  }
}

#------------------------------------------------------------------------------

# all rationals X,Y >= 1 with no common factor
use Math::PlanePath::DiagonalRationals;
*xy_is_visited = Math::PlanePath::DiagonalRationals->can('xy_is_visited');

#------------------------------------------------------------------------------

# even/odd
#   X=2^10 -> N=2^20 is X^2
#   Y=3 -> N=3
#   Y=3^2 -> N=3^3
#   Y=3^3 -> N=3^5
#   Y=3^4 -> N=3^7
#   Y*Y / distinct prime factors
#
# negabinary
#   X=prime^2 -> N=prime^6       is X^3
#   X=prime^6 -> N=prime^26      is X^4.33
#   maximum 101010...10110 -> 1101010...10 approaches factor 5
#   same for negatives
#
# revbinary
#   X=prime^k -> N=prime^(3k)    ix X^3

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### rect_to_n_range()

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  my $n = max($x1,$x2) * max($y1,$y2);
  my $n_squared = $n * $n;
  return (1,
          ($self->{'factor_coding'} eq 'negabinary'
           ? ($n_squared*$n_squared) * $n     # X^5*Y^5
           : $self->{'factor_coding'} eq 'revbinary'
           ? $n_squared * $n                  # X^3*Y^3
           # even/odd, odd/even
           : $n_squared));                    # X^2*Y^2
}


#------------------------------------------------------------------------------

# _limit() returns ($limit,$overflow).
#
# $limit is the biggest divisor to attempt trial division of $n.  If $n <
# 2^32 then $limit=sqrt($n) and that will find all primes.  If $n >= 2^32
# then $limit is smaller than sqrt($n), being calculated from the length of
# $n so as to make a roughly constant amount of time doing divisions.  But
# $limit is always at least 50 so as to divide by primes up to 50.
#
# $overflow is a boolean, true if $n is too big to search for all primes and
# $limit is something smaller than sqrt($n).  $overflow is false if $limit
# has not been capped and is enough to find all primes.
#
sub _limit {
  my ($n) = @_;
  my $limit = int(sqrt($n));
  my $cap = max (int(65536 * 10 / length($n)),
                 50);
  if ($limit > $cap) {
    return ($cap, 1);
  } else {
    return ($limit, 0);
  }
}

1;
__END__

=for stopwords eg Ryde OEIS ie Math-PlanePath Calkin-Wilf McCrimmon Freilich Yoram Sagher negabinary Denumerability revbinary Niven

=head1 NAME

Math::PlanePath::FactorRationals -- rationals by prime powers

=head1 SYNOPSIS

 use Math::PlanePath::FactorRationals;
 my $path = Math::PlanePath::FactorRationals->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<McCrimmon, Kevin>X<Freilich, Gerald>X<Sagher, Yoram>This path enumerates
rationals X/Y with no common factor, based on the prime powers in numerator
and denominator, as per

=over

Kevin McCrimmon, "Enumeration of the Positive Rationals", American
Math. Monthly, Nov 1960, page 868.
L<http://www.jstor.org/stable/2309448>

Gerald Freilich, "A Denumerability Formula for the Rationals", American
Math. Monthly, Nov 1965, pages 1013-1014.
L<http://www.jstor.org/stable/2313350>

Yoram Sagher, "Counting the rationals", American Math. Monthly, Nov 1989,
page 823.  L<http://www.jstor.org/stable/2324846>

=back

The result is

=cut

# math-image --path=FactorRationals,factor_coding=even/odd --all --output=numbers --size=58x16

=pod

    15  |      15   60       240            735  960           1815
    14  |      14       126       350                1134      1694
    13  |      13   52  117  208  325  468  637  832 1053 1300 1573
    12  |      24                 600      1176                2904
    11  |      11   44   99  176  275  396  539  704  891 1100
    10  |      10        90                 490       810      1210
     9  |      27  108       432  675      1323 1728      2700 3267
     8  |      32       288       800      1568      2592      3872
     7  |       7   28   63  112  175  252       448  567  700  847
     6  |       6                 150       294                 726
     5  |       5   20   45   80       180  245  320  405       605
     4  |       8        72       200       392       648       968
     3  |       3   12        48   75       147  192       300  363
     2  |       2        18        50        98       162       242
     1  |       1    4    9   16   25   36   49   64   81  100  121
    Y=0 |
         ----------------------------------------------------------
          X=0   1    2    3    4    5    6    7    8    9   10   11

A given fraction X/Y with no common factor has a prime factorization

    X/Y = p1^e1 * p2^e2 * ...

The exponents e[i] are positive, negative or zero, being positive when the
prime is in the numerator or negative when in the denominator.  Those
exponents are represented in an integer N by mapping the exponents to
non-negative,

    N = p1^f(e1) * p2^f(e2) * ...

    f(e) = 2*e      if e >= 0
         = 1-2*e    if e < 0

    f(e)      e
    ---      ---
     0        0
     1       -1
     2        1
     3       -2
     4        2

For example

    X/Y = 125/7 = 5^3 * 7^(-1)
    encoded as N = 5^(2*3) * 7^(1-2*(-1)) = 5^6 * 7^1 = 5359375

    N=3   ->  3^-1 = 1/3
    N=9   ->  3^1  = 3/1
    N=27  ->  3^-2 = 1/9
    N=81  ->  3^2  = 9/1

The effect is to distinguish prime factors of the numerator or denominator
by odd or even exponents of those primes in N.  Since X and Y have no common
factor a given prime appears in one and not the other.  The oddness or
evenness of the p^f() exponent in N can then encode which of the two X or Y
it came from.

The exponent f(e) in N has term 2*e in both cases, but the exponents from Y
are reduced by 1.  This can be expressed in the following form.  Going from
X,Y to N doesn't need to factorize X, only Y.

             X^2 * Y^2
    N = --------------------
        distinct primes in Y

N=1,2,3,8,5,6,etc in the column X=1 is integers with odd powers of prime
factors.  These are the fractions 1/Y so the exponents of the primes are all
negative and thus all exponents in N are odd.

X<Square numbers>N=1,4,9,16,etc in row Y=1 are the perfect squares.  That
row is the integers X/1 so the exponents are all positive and thus in N
become 2*e, giving simply N=X^2.

=head2 Odd/Even

Option C<factor_coding =E<gt> "odd/even"> changes the f() mapping to
numerator exponents as odd numbers and denominator exponents as even.

    f(e) = 2*e-1    if e > 0
         = -2*e     if e <= 0

The effect is simply to transpose XE<lt>-E<gt>Y.

"odd/even" is the form given by Kevin McCrimmon and Gerald Freilich.  The
default "even/odd" is the form given by Yoram Sagher.

=head2 Negabinary

X<Bradley, David M.>Option C<factor_coding =E<gt> "negabinary"> changes the
f() mapping to negabinary as suggested in

=over

David M. Bradley, "Counting the Positive Rationals: A Brief Survey",
L<http://arxiv.org/abs/math/0509025>

=back

=cut

# math-image --path=FactorRationals,factor_coding=negabinary --all --output=numbers_xy --size=70x14

=pod

This coding is not as compact as odd/even and tends to make bigger N values,

    13  |    2197   4394   6591 140608  10985  13182  15379 281216
    12  |     108                         540           756
    11  |    1331   2662   3993  85184   6655   7986   9317 170368
    10  |    1000          3000                        7000
     9  |       9     18           576     45            63   1152
     8  |    8192         24576         40960         57344
     7  |     343    686   1029  21952   1715   2058         43904
     6  |     216                        1080          1512
     5  |     125    250    375   8000           750    875  16000
     4  |       4            12            20            28
     3  |      27     54          1728    135           189   3456
     2  |       8            24            40            56
     1  |       1      2      3     64      5      6      7    128
    Y=0 |
         ----------------------------------------------------------
          X=0   1      2      3      4      5      6      7      8

=head2 Reversing Binary

Option C<factor_coding =E<gt> "revbinary"> changes the f() mapping to
"reversing binary" where a given integer is represented as a sum of powers
2^k with alternating signs

    e = 2^k1 - 2^k2 + 2^k3 - ...           0 <= k1 < k2 < k3

    f(e)      e
    ---      ---
     0        0
     1        1
     2        2
     3       -1
     4        4
     5       -3
     6       -2
     7        3

This representation is per Knuth volume 2 section 4.1 exercise 27.  The
exercise there is to show all integers can be represented this way.

=cut

# math-image --path=FactorRationals,factor_coding=revbinary --all --output=numbers --size=15x10

=pod

     9  |     729  1458        2916  3645        5103 93312        7290
     8  |      32          96         160         224         288
     7  |     343   686  1029  1372  1715  2058       43904  3087  3430
     6  |     216                    1080        1512
     5  |     125   250   375   500         750   875 16000  1125
     4  |      64         192         320         448         576
     3  |      27    54         108   135         189  3456         270
     2  |       8          24          40          56          72
     1  |       1     2     3     4     5     6     7   128     9    10
    Y=0 |
         ---------------------------------------------------------------
          X=0   1     2     3     4     5     6     7     8     9    10

The X axis begins with the integers 1 to 7 because f(1)=1 and f(2)=2 so N=X
until X has a prime p^3 or higher power.  The first such is X=8=2^3 which is
f(7)=3 so N=2^7=128.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over

=item C<$path = Math::PlanePath::FactorRationals-E<gt>new ()>

=item C<$path = Math::PlanePath::FactorRationals-E<gt>new (factor_coding =E<gt> $str)>

Create and return a new path object.  C<factor_coding> can be

    "even/odd"    (the default)
    "odd/even"
    "negabinary"
    "revbinary"

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return X,Y coordinates of point C<$n> on the path.  If there's no point
C<$n> then the return is an empty list.

This depends on factorizing C<$n> and in the current code there's a hard
limit on the amount of factorizing attempted.  If C<$n> is too big then the
return is an empty list.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the N point number for coordinates C<$x,$y>.  If there's nothing at
C<$x,$y>, such as when they have a common factor, then return C<undef>.

This depends on factorizing C<$y>, or factorizing both C<$x> and C<$y> for
negabinary or revbinary.  In the current code there's a hard limit on the
amount of factorizing attempted.  If the coordinates are too big then the
return is C<undef>.

=back

The current factorizing limits handle anything up to 2^32, and above that
numbers comprised of small factors.  But big numbers with big factors are
not handled.  Is this a good idea?  For large inputs there's no merit in
disappearing into a nearly-infinite loop.  Perhaps the limits could be
configurable and/or some advanced factoring modules attempted for a while
if/when available.

=head1 OEIS

This enumeration of the rationals is in Sloane's Online Encyclopedia of
Integer Sequences in the following forms

=over

L<http://oeis.org/A071974> (etc)

=back

    A071974   X coordinate, numerators
    A071975   Y coordinate, denominators
    A019554   X*Y product
    A102631   N in column X=1, n^2/squarefreekernel(n)
    A072345   X and Y at N=2^k, being alternately 1 and 2^k

    A011262   permutation N at transpose Y/X (exponents mangle odd<->even)

    A060837   permutation DiagonalRationals -> FactorRationals
    A071970   permutation RationalsTree CW -> FactorRationals

The last A071970 is rationals taken in order of the Stern diatomic sequence
stern[i]/stern[i+1] which is the Calkin-Wilf tree rows
(L<Math::PlanePath::RationalsTree/Calkin-Wilf Tree>).

The negabinary representation is

    A053985   index -> signed
    A005351   signed positives -> index
    A039724   signed positives -> index, in binary
    A005352   signed negatives -> index

The reversing binary representation is

    A065620   index -> signed
    A065621   signed positives -> index
    A048724   signed negatives -> index

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::GcdRationals>,
L<Math::PlanePath::RationalsTree>,
L<Math::PlanePath::CoprimeColumns>

=head2 Other Ways to Do It

Niven gives another prime factor based construction but encoding N by runs
of 1-bits,

=over

Ivan Niven, "Note on a paper by L. S. Johnston", American Math. Monthly,
volume 55, number 6, June-July 1948, page 358.
L<http://www.jstor.org/stable/2304962>

=back

N is written in binary each 0-bit is considered a separator.  The number of
1-bits between each

    N = 11 0 0 111 0 11  binary
           | |     |
         2  0   3    2   f(e) = run lengths of 1-bits
        -1  0  +2   -1   e exponent by "odd/even" style

    X/Y = 2^(-1) * 3^(+2) * 5^0 * 7^(-1)       

Kevin McCrimmon's note begins with a further possible encoding for N where
the prime powers from numerator are spread out to primes p[2i+1] and with 0
powers sending a p[2i] power to the denominator.  In this form the primes
from X and Y spread out to different primes rather than different exponents.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
