# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


# math-image --path=DigitGroups --output=numbers_dash
# math-image --path=DigitGroups,radix=2 --all --output=numbers
#
# increment N+1 changes low 01111 to 10000
# X bits change 01111 to 000, no carry, decreasing by number of low 1s
# Y bits change 011 to 100, plain +1
#
# cf A084473 binary 0->0000
#    A088698 binary 1->11
#    A175047 binary 0000run->0
#
# G. Cantor, "Ein Beitrag zur Mannigfaltigkeitslehre", Journal für die reine
# und angewandte Mathematik (Crelle's Journal), Vol. 84, 242-258, 1878.
# http://www.digizeitschriften.de/dms/img/?PPN=PPN243919689_0084&DMDID=dmdlog15


package Math::PlanePath::DigitGroups;
use 5.004;
use strict;
#use List::Util 'max','min';
*max = \&Math::PlanePath::_max;
*min = \&Math::PlanePath::_min;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'parameter_info_array',    # "radix" parameter
  'round_down_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad1;
use constant absdx_minimum => 1;

sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->{'radix'} - 1;
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return $self->{'radix'};
}
sub _UNDOCUMENTED__turn_any_straight_at_n {
  my ($self) = @_;
  if ($self->{'radix'} == 2) { return 274; }
  return 1;
}

#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new(@_);

  my $radix = $self->{'radix'};
  if (! defined $radix || $radix <= 2) { $radix = 2; }
  $self->{'radix'} = $radix;

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### DigitGroups n_to_xy(): $n
  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  # what to do for fractions ?
  {
    my $int = int($n);
    ### $int
    if ($n != $int) {
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      ### $frac
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int; # BigFloat int() gives BigInt, use that
  }

  my $radix = $self->{'radix'};
  my (@x,@y); # digits low to high

  my @digits = digit_split_lowtohigh($n,$radix)
    or return (0,0);  # if $n==0

  DIGITS: for (;;) {
    my $digit;

    # from @digits to @x
    do {
      ### digit to x: $digits[0]
      $digit = shift @digits;  # $n digits low to high
      push @x, $digit;
      @digits || last DIGITS;
    } while ($digit);  # $digit==0 is separator

    # from @digits to @y
    do {
      $digit = shift @digits;  # low to high
      ### digit to y: $digit
      push @y, $digit;
      @digits || last DIGITS;
    } while ($digit);  # $digit==0 is separator
  }

  my $zero = $n * 0; # inherit bignum 0
  return (digit_join_lowtohigh (\@x, $radix, $zero),
          digit_join_lowtohigh (\@y, $radix, $zero));
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### DigitGroups xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if (is_infinite($x)) {
    return $x;
  }
  if (is_infinite($y)) {
    return $y;
  }
  if ($x < 0 || $y < 0) {
    return undef;
  }

  if ($x == 0 && $y == 0) {
    return 0;
  }

  my $radix = $self->{'radix'};
  my $zero = ($x * 0 * $y);  # inherit bignum 0
  my @n; # digits low to high

  my @x = digit_split_lowtohigh($x,$radix);
  my @y = digit_split_lowtohigh($y,$radix);

  while (@x || @y) {
    my $digit;
    do {
      $digit = shift @x || 0; # low to high
      ### digit from x: $digit
      push @n, $digit;
    } while ($digit);

    do {
      $digit = shift @y || 0; # low to high
      ### digit from y: $digit
      push @n, $digit;
    } while ($digit);
  }
  return digit_join_lowtohigh (\@n, $radix, $zero);
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### DigitGroups rect_to_n_range() ...

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }  # x1 smaller
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }  # y1 smaller

  if ($y2 < 0 || $x2 < 0) {
    return (1, 0); # rect all negative, no N
  }

  my $radix = $self->{'radix'};

  my ($power, $lo_level) = round_down_pow (min($x1,$y1), $radix);
  if (is_infinite($lo_level)) {
    return (0,$lo_level);
  }

  ($power, my $hi_level) = round_down_pow (max($x2,$y2), $radix);
  if (is_infinite($hi_level)) {
    return (0,$hi_level);
  }

  return ($lo_level == 0 ? 0
          : ($radix*$radix + 1) * $radix ** (2*$lo_level),

          ($radix-1)*$radix**(3*$hi_level+2)
          + $radix**($hi_level+1)
          - 1);
}

1;
__END__

=for stopwords Ryde Math-PlanePath undrawn Radix cardinality bijection radix OEIS KE<246>nig KE<246>nig's nig

=head1 NAME

Math::PlanePath::DigitGroups -- X,Y digits grouped by zeros

=head1 SYNOPSIS

 use Math::PlanePath::DigitGroups;

 my $path = Math::PlanePath::DigitGroups->new (radix => 2);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path splits an N into X,Y by digit groups separated by a 0.  The
default is binary so for example

    N = 110111001011

is split into groups with a leading high 0 bit, and those groups then go to
X and Y alternately,

    N = 11 0111 0 01 011
         X   Y  X  Y  X

    X = 11      0    011 = 110011
    Y =    0111   01     =  11101

The result is a one-to-one mapping between numbers NE<gt>=0 and pairs
XE<gt>=0,YE<gt>=0.

The default binary is

    11  |   38   77   86  155  166  173  182  311  550  333  342  347
    10  |   72  145  148  291  168  297  300  583  328  337  340  595
     9  |   66  133  138  267  162  277  282  535  322  325  330  555
     8  |  128  257  260  515  272  521  524 1031  320  545  548 1043
     7  |   14   29   46   59  142   93  110  119  526  285  302  187
     6  |   24   49   52   99   88  105  108  199  280  177  180  211
     5  |   18   37   42   75   82   85   90  151  274  165  170  171
     4  |   32   65   68  131   80  137  140  263  160  161  164  275
     3  |    6   13   22   27   70   45   54   55  262  141  150   91
     2  |    8   17   20   35   40   41   44   71  136   81   84   83
     1  |    2    5   10   11   34   21   26   23  130   69   74   43
    Y=0 |    0    1    4    3   16    9   12    7   64   33   36   19
        +-------------------------------------------------------------
           X=0    1    2    3    4    5    6    7    8    9   10   11

N=0,1,4,3,16,9,etc along the X axis is X with zero bits doubled.  For
example X=9 is binary 1001, double up the zero bits to 100001 for N=33 at
X=9,Y=0.  This is because in the digit groups Y=0 so when X is grouped by
its zero bits there's an extra 0 from Y in between each group.

Similarly N=0,2,8,6,32,etc along the Y axis is Y with zero bits doubled,
plus an extra zero bit at the low end coming from the first X=0 group.  For
example Y=9 is again binary 1001, doubled zeros to 100001, and an extra zero
at the low end 1000010 is N=66 at X=0,Y=9.

=head2 Radix

The C<radix =E<gt> $r> option selects a different base for the digit split.
For example radix 5 gives

    radix => 5

    12  |  60  301  302  303  304  685 1506 1507 1508 1509 1310 1511
    11  |  55  276  277  278  279  680 1381 1382 1383 1384 1305 1386
    10  | 250 1251 1252 1253 1254 1275 6256 6257 6258 6259 1300 6261
     9  |  45  226  227  228  229  670 1131 1132 1133 1134 1295 1136
     8  |  40  201  202  203  204  665 1006 1007 1008 1009 1290 1011
     7  |  35  176  177  178  179  660  881  882  883  884 1285  886
     6  |  30  151  152  153  154  655  756  757  758  759 1280  761
     5  | 125  626  627  628  629  650 3131 3132 3133 3134  675 3136
     4  |  20  101  102  103  104  145  506  507  508  509  270  511
     3  |  15   76   77   78   79  140  381  382  383  384  265  386
     2  |  10   51   52   53   54  135  256  257  258  259  260  261
     1  |   5   26   27   28   29  130  131  132  133  134  255  136
    Y=0 |   0    1    2    3    4   25    6    7    8    9   50   11
        +-----------------------------------------------------------
          X=0    1    2    3    4    5    6    7    8    9   10   11

=head2 Real Line and Plane

X<KE<246>nig, Julius>This split is inspired by the digit grouping in the
proof by Julius KE<246>nig that the real line is the same cardinality as the
plane.  (Cantor's original proof was a C<ZOrderCurve> style digit
interleaving.)

In KE<246>nig's proof a bijection between interval n=(0,1) and pairs
x=(0,1),y=(0,1) is made by taking groups of digits stopping at a non-zero.
Non-terminating fractions like 0.49999... are chosen over terminating
0.5000... so there's always infinitely many non-zero digits going downwards.
For the integer form here the groupings are digit going upwards and there's
infinitely many zero digits above the top, hence the grouping by zeros
instead of non-zeros.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::DigitGroups-E<gt>new ()>

=item C<$path = Math::PlanePath::DigitGroups-E<gt>new (radix =E<gt> $r)>

Create and return a new path object.  The optional C<radix> parameter gives
the base for digit splitting (the default is binary, radix 2).

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A084471> (etc)

=back

    radix=2 (the default)
      A084471    N on X axis, bit 0->00
      A084472    N on X axis, in binary
      A060142    N on X axis, sorted into ascending order

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ZOrderCurve>,
L<Math::PlanePath::PowerArray>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
