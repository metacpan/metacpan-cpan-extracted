# Copyright 2013, 2014, 2015, 2016 Kevin Ryde

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


# cf A134562 base-3 Y=sum digits

# http://cut-the-knot.org/wiki-math/index.php?n=Probability.ComboPlayground
# combinations

# row
# Y=1  2^k
# Y=2  2-bit numbers

# column
# X=1  first with Y many bits is Zeck    11111
#      A027941 Fib(2n+1)-1
# X=2  second with Y many bits is Zeck  101111   high 1, low 1111
#      A005592 F(2n+1)+F(2n-1)-1
# X=3  third with Y many bits is  Zeck  110111
#      A005592 F(2n+1)+F(2n-1)-1
# X=4  fourth with Y many bits is Zeck  111011
#                                       111101
#                                       111110
# 1001111
# 1010111
# 1011011
# 1011101
# 1011110
# 1100111
# 1101011
# 1101101
# 1101110
# 1110011
# 1110101
# 1110110
# 1111001
# 1111010
# 1111100
# 15  binomial(6,4)=15
#
# binomial(a,b) = a! / (b! * (a-b!))
#
# binomial(X-1,X-1)   4,4
# binomial(X,  X-1)   5,4
# binomial(X+1,X-1)   5,4
# bin(a+1,b) = (a+1)!/(b! * (a+1-b)!)
# bin(a+1,b) = a!/(b! * (a-b)!)  * (a+1)/(a+1-b)
# bin(a+1,b) = bin(a,b)  * (a+1)/(a+1-b)
#
# bin(a,b+1) = (a)!/((b+1)! * (a-b-1)!)
# bin(a,b+1) = (a)!/(b! * (a-b)!) * (b+1)*(a-b)
# bin(a,b+1) = bin(a,b) * (b+1)*(a-b)
#
# bin(a-1,b) = (a-1)! / (b! * (a-1-b)!)
# bin(a-1,b) = a! / (b! * (a-b)!)  (  (a-b)/a
# bin(a-1,b) = bin(a,b) * (a-b)/a

# bin(a,b-1) = a!/((b-1)! * (a-b+1)!)
# bin(a,b-1) = a!/(b! * (a-b)!)  * b/(a-b+1)
# bin(a,b-1) = bin(a,b)  * b/(a-b+1)
#
#
#         1     2   3       4    5    6
# Y=2    11   101 110    1001 1010 1100
#         3     5   6       9   10   12
#         1    \------2   \-------------3

#         1      2    3    4    5    6
# Y=3   111   1011 1101 1110 
#         3     11   13   14
#         1    \-------------3  \-------------

#         1      2    3    4    5    6
# Y=4   111   1011 1101 1110 
#         3     11   13   14
#         1    \-------------3  \-------------



package Math::PlanePath::BinaryTerms;
use 5.004;
use strict;
use List::Util 'sum';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem = \&Math::PlanePath::_divrem;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [ Math::PlanePath::Base::Digits::parameter_info_radix2(),
  ];

use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant y_minimum => 1;
use constant x_minimum => 1;


#------------------------------------------------------------------------------

my $global_radix = 0;
my $next_n = 1;
my @n_to_x;
my @n_to_y;
my @yx_to_n;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'radix'} ||= 2;
  if ($global_radix != $self->{'radix'}) {
    $global_radix = $self->{'radix'};
    $next_n = 1;
    @n_to_x = ();
    @n_to_y = ();
    @yx_to_n = ();
  }
  return $self;
}

sub _extend {
  my ($self) = @_;
  ### _extend() ...
  ### $next_n

  my $n = $next_n++;
  my @ndigits = digit_split_lowtohigh($n,$self->{'radix'});
  ### ndigits low to high: join(',',@ndigits)
  my $y = 0;
  foreach (@ndigits) {
    if ($_) { $y++; }
  }
  my $row = ($yx_to_n[$y] ||= []);
  my $x = scalar(@$row) || 1;

  $row->[$x] = $n;
  $n_to_x[$n] = $x;
  $n_to_y[$n] = $y;
  ### push: "x=$x y=$y n=$n"
  ### @yx_to_n
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### BinaryTerms n_to_xy(): "$n    radix=$self->{'radix'}"

  if ($n < 1) { return; }
  if (is_infinite($n) || $n == 0) { return ($n,$n); }

  {
    # fractions on straight line ?
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

  my $radix = $self->{'radix'};
  if ($radix > 2) {
    while ($next_n <= $n) {
      _extend($self);
    }
    return ($n_to_x[$n], $n_to_y[$n]);
  }

  {
    my @ndigits = digit_split_lowtohigh($n,$radix);
    pop @ndigits;  # drop high 1-bit
    my $ones = sum(0,@ndigits);
    my $y = $ones + 1;

    ### $y
    ### ndigits low to high: join(',',@ndigits)
    ### $ones

    my $binomial
      = my $x
        = $n * 0 + 1;  # inherit bignum 1

    for (my $len = $ones; $len <= $#ndigits; ) {
      ### block add to x: $binomial
      $x += $binomial * ($radix-1)**$ones;

      # bin(a+1,b) = bin(a,b) * (a+1)/(a+1-b)
      $len++;
      $binomial *= $len;
      ### assert: $binomial % ($len-$ones) == 0
      $binomial /= ($len-$ones);
      ### assert: $binomial == _binomial($len,$ones)
    }
    # here $binomial = binomial(len,ones)

    my $len = scalar(@ndigits);
    foreach my $digit (reverse @ndigits) {  # high to low
      ### digit: "$digit  len=$len ones=$ones binomial=$binomial  x=$x"

      if ($len == $ones || $ones == 0) {
        last;
      }

      # bin(a-1,b) = bin(a,b) * (a-b)/a
      $binomial *= ($len-$ones);
      ### assert: $binomial % $len == 0
      $binomial /= $len;
      $len--;
      ### decr len to: "len=$len ones=$ones  binomial=$binomial"
      ### assert: $binomial == _binomial($len,$ones)

      if ($digit) {
        ### add to x: $binomial
        $x += $binomial * $digit * ($radix-1)**$ones;

        # bin(a,b-1) = bin(a,b)  * b/(a-b+1)
        ### assert: ($binomial * $ones) % ($len-$ones+1) == 0
        $binomial *= $ones;
        $ones--;
        $binomial /= ($len-$ones);
        ### assert: $binomial == _binomial($len,$ones)
      }
    }
    ### result: "x=$x ones=$ones"
    return ($x, $y);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### BinaryTerms xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my $radix = $self->{'radix'};
  if ($radix > 2) {
    if ($x < 1 || $y < 1) { return undef; }
    if (is_infinite($x)) { return $x; }
    if (is_infinite($y)) { return $y; }

    for (;;) {
      if (defined (my $n = $yx_to_n[$y][$x])) {
        return $n;
      }
      _extend($self);
    }
  }

  {
    $x -= 1;
    if ($x < 0 || $y < 1) { return undef; }
    if (is_infinite($x)) { return $x; }
    if (is_infinite($y)) { return $y; }

    my $len = my $ones = $y-1;
    my $binomial = 1;
    while ($x >= $binomial * ($radix-1)**$ones) {
      ### subtract high from: "len=$len ones=$ones binomial=$binomial x=$x"
      $x -= $binomial;

      # bin(a+1,b) = bin(a,b) * (a+1)/(a+1-b)
      $len++;
      $binomial *= $len;
      ### assert: $binomial % ($len-$ones) == 0
      $binomial /= ($len-$ones);
      ### assert: $binomial == _binomial($len,$ones)
    }
    ### found high: "len=$len ones=$ones  binomial=$binomial  x=$x"

    my @ndigits = (1);  # high to low
    while ($len > 0) {
      ### at: "len=$len ones=$ones  binomial=$binomial  x=$x"
      ### assert: $len >= $ones

      if ($len == $ones) {
        push @ndigits, (1) x $ones;
        last;
      }
      if ($ones == 0) {
        push @ndigits, (0) x $len;
        last;
      }

      # bin(a-1,b) = bin(a,b) * (a-b)/a
      $binomial *= ($len-$ones);
      ### assert: $binomial % $len == 0
      $binomial /= $len;
      $len--;
      ### decr len to: "len=$len ones=$ones  binomial=$binomial"
      ### assert: $binomial == _binomial($len,$ones)

      my $bcmp = $binomial * ($radix-1)**$ones;
      ### compare: "x=$x bcmp=$bcmp"
      if ($x >= $bcmp) {
        ### yes, above, push digit ...
        # (my $digit, $x) = _divrem($x,$bcmp);
        # push @ndigits, $digit;
        # ### assert: $digit >= 1
        # ### assert: $digit < $radix
        $x -= $binomial * ($radix-1)**$ones;
        push @ndigits, 1;

        # bin(a,b-1) = bin(a,b)  * b/(a-b+1)
        $binomial *= $ones;
        $ones--;
        ### assert: ($binomial * $ones) % ($len-$ones) == 0
        $binomial /= $len-$ones;
        ### assert: $binomial == _binomial($len,$ones)

      } else {
        ### no, push 0 digit ...
        push @ndigits, 0;
      }
    }

    ### ndigits: join(',',@ndigits)
    @ndigits = reverse @ndigits;
    return digit_join_lowtohigh(\@ndigits,$radix, $x*0*$y);
  }
}

sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### BinaryTerms rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  if ($x2 < 1 || $y2 < 1) { return (1,0); }

  return (1, max($self->xy_to_n($x2,$y2),
                 $self->xy_to_n($x2,1)));
  return (1, 10000);
}

sub _binomial {
  my ($a,$b) = @_;
  $a >= $b or die "_binomial($a,$b)";
  my $ret = 1;
  foreach (2 .. $a) { $ret *= $_ }
  foreach (2 .. $b) { $ret /= $_ }
  foreach (2 .. $a-$b) { $ret /= $_ }
  ### _binomial: "a=$a b=$b  binomial=$ret"
  return $ret;
}
1;
__END__

=cut

# math-image  --path=BinaryTerms --output=numbers --all --size=60x14

=pod
