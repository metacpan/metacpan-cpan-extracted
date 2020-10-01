# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


# cf. A164677 position of Gray bit change, +/- according to 0->1 or 1->0.
#     (a signed version of A001511)

package Math::PlanePath::GrayCode;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

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

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad1;

use constant parameter_info_array =>
  [
   { name            => 'apply_type',
     share_key       => 'apply_type_TsF',
     display         => 'Apply Type',
     type            => 'enum',
     default         => 'TsF',
     choices         => ['TsF','Ts','Fs','FsT','sT','sF'],
     choices_display => ['TsF','Ts','Fs','FsT','sT','sF'],
     description     => 'How to apply the Gray coding to/from and split.',
   },
   { name             => 'gray_type',
     display          => 'Gray Type',
     type             => 'enum',
     default          => 'reflected',
     choices          => ['reflected','modular'],
     choices_dispaly  => ['Reflected','Modular'],
     description      => 'The type of Gray code.',
   },
   { %{Math::PlanePath::Base::Digits::parameter_info_radix2()},
     description => 'Radix, for both the Gray code and splitting.',
   },
  ];

sub _is_peano {
  my ($self) = @_;
  return ($self->{'radix'} % 2 == 1
          && $self->{'gray_type'} eq 'reflected'
          && ($self->{'apply_type'} eq 'TsF'
              || $self->{'apply_type'} eq 'FsT'));
}
sub dx_minimum {
  my ($self) = @_;
  return (_is_peano($self) ? -1 : undef);
}
*dy_minimum = \&dx_minimum;

sub dx_maximum {
  my ($self) = @_;
  return (_is_peano($self) ? 1 : undef);
}
*dy_maximum = \&dx_maximum;

{
  # Ror sT and sF the split X coordinate changes from N to N+1 and so does
  # the to-gray or from-gray transformation, so X always changes.
  #
  my %absdx_minimum = (
                      reflected => {
                                    # TsF => 0,
                                    # FsT => 0,
                                    # Ts  => 0,
                                    # Fs  => 0,
                                    sT    => 1,
                                    sF    => 1,
                                   },
                      modular   => {
                                    # TsF => 0,
                                    # Ts  => 0,
                                    Fs    => 1,
                                    FsT   => 1,
                                    sT    => 1,
                                    sF    => 1,
                                   },
                     );
  sub absdx_minimum {
    my ($self) = @_;
    my $gray_type = ($self->{'radix'} == 2
                     ? 'reflected'
                     : $self->{'gray_type'});
    return ($absdx_minimum{$gray_type}->{$self->{'apply_type'}} || 0);
  }
}

*dsumxy_minimum = \&dx_minimum;
*dsumxy_maximum = \&dx_maximum;
*ddiffxy_minimum = \&dx_minimum;
*ddiffxy_maximum = \&dx_maximum;

{
  my %dir_maximum_supremum = (
                      # # radix==2 always "reflected"
                      # # TsF => 0,
                      # # FsT => 0,
                      # # Ts => 0,
                      # # Fs => 0,
                      # sT => 4,
                      # sF => 4,

                      reflected => {
                                    # TsF => 0,
                                    # FsT => 0,
                                    # Ts  => 0,
                                    # Fs  => 0,
                                    sT    => 4,
                                    sF    => 4,
                                   },
                      modular   => {
                                    # TsF => 0,
                                    # Ts  => 0,
                                    Fs    => 4,
                                    FsT   => 4,
                                    sT    => 4,
                                    sF    => 4,
                                   },
                     );
  sub dir_maximum_dxdy {
    my ($self) = @_;
    my $gray_type = ($self->{'radix'} == 2
                     ? 'reflected'
                     : $self->{'gray_type'});
    return ($dir_maximum_supremum{$gray_type}->{$self->{'apply_type'}}
            ? (0,0)    # supremum
            : (0,-1)); # South
  }
}

# radix=2 TsF==Fs is always straight or left
sub turn_any_right {
  my ($self) = @_;
  if ($self->{'radix'} == 2
      && ($self->{'apply_type'} eq 'TsF'
          || $self->{'apply_type'} eq 'Fs')) {
    return 0; # never right
  }
  return 1;
}
sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'radix'} == 2
          && ($self->{'apply_type'} eq 'sT' || $self->{'apply_type'} eq 'sF')
          ? 0   # never straight
          : 1);
}

sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->{'radix'} - 1;
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  if ($self->{'apply_type'} eq 'TsF' && $self->{'gray_type'} eq 'reflected'
      && $self->{'radix'} > 2) {
    return 2*$self->{'radix'} - 1;
  }
  return undef;
}


#------------------------------------------------------------------------------
my %funcbase = (T  => '_digits_to_gray',
                F  => '_digits_from_gray',
                '' => '_noop');
my %inv = (T  => 'F',
           F  => 'T',
           '' => '');

sub new {
  my $self = shift->SUPER::new(@_);

  if (! $self->{'radix'} || $self->{'radix'} < 2) {
    $self->{'radix'} = 2;
  }

  my $apply_type = ($self->{'apply_type'} ||= 'TsF');
  my $gray_type = ($self->{'gray_type'} ||= 'reflected');

  unless ($apply_type =~ /^([TF]?)s([TF]?)$/) {
    croak "Unrecognised apply_type \"$apply_type\"";
  }
  my $nf = $1;  # "T" or "F" or ""
  my $xyf = $2;

  $self->{'n_func'} = $self->can("$funcbase{$nf}_$gray_type")
    || croak "Unrecognised gray_type \"$self->{'gray_type'}\"";
  $self->{'xy_func'} = $self->can("$funcbase{$xyf}_$gray_type");

  $nf = $inv{$nf};
  $xyf = $inv{$xyf};

  $self->{'inverse_n_func'} = $self->can("$funcbase{$nf}_$gray_type");
  $self->{'inverse_xy_func'} = $self->can("$funcbase{$xyf}_$gray_type");

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### GrayCode n_to_xy(): $n

  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  {
    # ENHANCE-ME: N and N+1 differ by not much ...
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
  my @digits = digit_split_lowtohigh($n,$radix);
  $self->{'n_func'}->(\@digits, $radix);

  my @xdigits;
  my @ydigits;
  while (@digits) {
    push @xdigits, shift @digits;        # low to high
    push @ydigits, shift @digits || 0;
  }
  my $xdigits = \@xdigits;
  my $ydigits = \@ydigits;
  $self->{'xy_func'}->($xdigits,$radix);
  $self->{'xy_func'}->($ydigits,$radix);

  return (digit_join_lowtohigh($xdigits,$radix),
          digit_join_lowtohigh($ydigits,$radix));
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### GrayCode xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) {
    return undef;
  }
  if (is_infinite($x)) {
    return $x;
  }
  if (is_infinite($y)) {
    return $y;
  }

  my $radix = $self->{'radix'};
  my @xdigits = digit_split_lowtohigh ($x, $radix);
  my @ydigits = digit_split_lowtohigh ($y, $radix);

  $self->{'inverse_xy_func'}->(\@xdigits, $radix);
  $self->{'inverse_xy_func'}->(\@ydigits, $radix);

  my @digits;
  for (;;) {
    (@xdigits || @ydigits) or last;
    push @digits, shift @xdigits || 0;
    (@xdigits || @ydigits) or last;
    push @digits, shift @ydigits || 0;
  }

  my $digits = \@digits;
  $self->{'inverse_n_func'}->($digits,$radix);

  return digit_join_lowtohigh($digits,$radix);
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = round_nearest($x1);
  $y1 = round_nearest($y1);
  $x2 = round_nearest($x2);
  $y2 = round_nearest($y2);

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }  # x1 smaller
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }  # y1 smaller

  if ($y2 < 0 || $x2 < 0) {
    return (1, 0); # rect all negative, no N
  }

  my $radix = $self->{'radix'};
  my ($pow_max) = round_down_pow (max($x2,$y2), $radix);
  $pow_max *= $radix;
  return (0, $pow_max*$pow_max - 1);
}

#------------------------------------------------------------------------------

use constant 1.02 _noop_reflected => undef;
use constant 1.02 _noop_modular   => undef;

# $aref->[0] low digit
sub _digits_to_gray_reflected {
  my ($aref, $radix) = @_;
  ### _digits_to_gray(): $aref
  $radix -= 1;
  my $reverse = 0;
  foreach my $digit (reverse @$aref) {  # high to low
    if ($reverse & 1) {
      $digit = $radix - $digit;  # radix-1 - digit
    }
    $reverse ^= $digit;
  }
}
# $aref->[0] low digit
sub _digits_to_gray_modular {
  my ($aref, $radix) = @_;
  my $prev = 0;
  foreach my $digit (reverse @$aref) {  # high to low
    ($digit,$prev) = (($digit - $prev) % $radix,   # mutate $aref->[i]
                      $digit);
  }
}

# $aref->[0] low digit
sub _digits_from_gray_reflected {
  my ($aref, $radix) = @_;
  $radix -= 1;                   # radix-1
  my $reverse = 0;
  foreach my $digit (reverse @$aref) {  # high to low
    if ($reverse & 1) {
      $reverse ^= $digit;        # before this reversal
      $digit = $radix - $digit;  # radix-1 - digit, mutate array
    } else {
      $reverse ^= $digit;
    }
  }
}
# $aref->[0] low digit
sub _digits_from_gray_modular {
  my ($aref, $radix) = @_;
  ### _digits_from_gray_modular(): $aref

  my $offset = 0;
  foreach my $digit (reverse @$aref) {  # high to low
    $offset = ($digit = ($digit + $offset) % $radix); # mutate $aref->[i]
  }
}

#------------------------------------------------------------------------------
# levels

use Math::PlanePath::ZOrderCurve;
*level_to_n_range = \&Math::PlanePath::ZOrderCurve::level_to_n_range;
*n_to_level       = \&Math::PlanePath::ZOrderCurve::n_to_level;

#------------------------------------------------------------------------------
1;
__END__

=for stopwords Ryde Math-PlanePath eg Radix radix ie Christos Faloutsos Fs FsT sF pre TsF Peano radices Peano's xk yk OEIS PlanePath undoubled pre-determined TSE DOI

=head1 NAME

Math::PlanePath::GrayCode -- Gray code coordinates

=head1 SYNOPSIS

 use Math::PlanePath::GrayCode;

 my $path = Math::PlanePath::GrayCode->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Gray code>This path is a mapping of N to X,Y using Gray codes.

      7  |  63-62 57-56 39-38 33-32
         |      |  |        |  |
      6  |  60-61 58-59 36-37 34-35
         |
      5  |  51-50 53-52 43-42 45-44
         |      |  |        |  |
      4  |  48-49 54-55 40-41 46-47
         |
      3  |  15-14  9--8 23-22 17-16
         |      |  |        |  |
      2  |  12-13 10-11 20-21 18-19
         |
      1  |   3--2  5--4 27-26 29-28
         |      |  |        |  |
     Y=0 |   0--1  6--7 24-25 30-31
         |
         +-------------------------
           X=0  1  2  3  4  5  6  7

X<Faloutsos, Christos>The default is the form by Faloutsos which is an X,Y
split in binary reflected Gray code.

=over

Christos Faloutsos, "Gray Codes for Partial Match and Range Queries", IEEE
Transactions on Software Engineering (TSE), volume 14, number 10, October
1988, pages 1381-1393.  DOI 10.1109/32.6184

=back

N is converted to a Gray code, then split by bits to X,Y, and those X,Y
converted back from Gray to integer indices.  Stepping from N to N+1 changes
just one bit of the Gray code and therefore changes just one of X or Y each
time.

Y axis N=0,3,12,15,48,etc are values with only digits 0,3 in base 4.  X axis
N=0,1,6,7,24,25,etc are values 2k and 2k+1 where k uses only digits 0,3 in
base 4.

=head2 Radix

The default is binary.  Option C<radix =E<gt> $r> can select another radix.
This radix is used for both the Gray code and the digit splitting.  For
example C<radix =E<gt> 4>,

    radix => 4

      |
    127-126-125-124  99--98--97--96--95--94--93--92  67--66--65--64
                  |   |                           |   |
    120-121-122-123 100-101-102-103  88--89--90--91  68--69--70--71
      |                           |   |                           |
    119-118-117-116 107-106-105-104  87--86--85--84  75--74--73--72
                  |   |                           |   |
    112-113-114-115 108-109-110-111  80--81--82--83  76--77--78--79

     15--14--13--12  19--18--17--16  47--46--45--44  51--50--49--48
                  |   |                           |   |
      8-- 9--10--11  20--21--22--23  40--41--42--43  52--53--54--55
      |                           |   |                           |
      7-- 6-- 5-- 4  27--26--25--24  39--38--37--36  59--58--57--56
                  |   |                           |   |
      0-- 1-- 2-- 3  28--29--30--31--32--33--34--35  60--61--62--63

=head2 Apply Type

Option C<apply_type =E<gt> $str> controls how Gray codes are applied to N
and X,Y.  It can be one of

    "TsF"    to Gray, split, from Gray  (default)
    "Ts"     to Gray, split
    "Fs"     from Gray, split
    "FsT"    from Gray, split, to Gray
     "sT"    split, to Gray
     "sF"    split, from Gray

"T" means integer-to-Gray, "F" means integer-from-Gray, and omitted means no
transformation.  For example the following is "Ts" which means N to Gray
then split, leaving Gray coded values for X,Y.

=cut

# math-image --path=GrayCode,apply_type=Ts --all --output=numbers_dash

=pod

    apply_type => "Ts"

     7  |  51--50  52--53  44--45  43--42
        |       |       |       |       |
     6  |  48--49  55--54  47--46  40--41
        |
     5  |  60--61  59--58  35--34  36--37  ...-66
        |       |       |       |       |       |
     4  |  63--62  56--57  32--33  39--38  64--65
        |
     3  |  12--13  11--10  19--18  20--21
        |       |       |       |       |
     2  |  15--14   8-- 9  16--17  23--22
        |
     1  |   3-- 2   4-- 5  28--29  27--26
        |       |       |       |       |
    Y=0 |   0-- 1   7-- 6  31--30  24--25
        |
        +---------------------------------
          X=0   1   2   3   4   5   6   7

This "Ts" is quite attractive because a step from N to N+1 changes just one
bit in X or Y alternately, giving 2-D single-bit changes.  For example N=19
at X=4 followed by N=20 at X=6 is a single bit change in X.

N=0,2,8,10,etc on the leading diagonal X=Y is numbers using only digits 0,2
in base 4.  N=0,3,15,12,etc on the Y axis is numbers using only digits 0,3
in base 4, but in a Gray code order.

The "Fs", "FsT" and "sF" forms effectively treat the input N as a Gray code
and convert from it to integers, either before or after split.  For "Fs" the
effect is little Z parts in various orientations.

    apply_type => "sF"

     7  |  32--33  37--36  52--53  49--48
        |    /       \       /       \
     6  |  34--35  39--38  54--55  51--50
        |
     5  |  42--43  47--46  62--63  59--58
        |    \       /       \       /
     4  |  40--41  45--44  60--61  57--56
        |
     3  |   8-- 9  13--12  28--29  25--24
        |    /       \       /       \
     2  |  10--11  15--14  30--31  27--26
        |
     1  |   2-- 3   7-- 6  22--23  19--18
        |    \       /       \       /
    Y=0 |   0-- 1   5-- 4  20--21  17--16
        |
        +---------------------------------
          X=0   1   2   3   4   5   6   7

=head2 Gray Type

The C<gray_type> option selects the type of Gray code.  The choices are

    "reflected"     increment to radix-1 then decrement (default)
    "modular"       increment to radix-1 then cycle back to 0

For example in decimal,

    integer       Gray         Gray
               "reflected"   "modular"
    -------    -----------   ---------
       0            0            0
       1            1            1
       2            2            2
     ...          ...          ...
       8            8            8
       9            9            9
      10           19           19
      11           18           10
      12           17           11
      13           16           12
      14           15           13
     ...          ...          ...
      17           12           16
      18           11           17
      19           10           18

Notice on reaching "19" the reflected type runs the least significant digit
back down from 9 to 0, which is a reverse or reflection of the preceding 0
to 9 upwards.  The modular form instead continues to increment that least
significant digit, wrapping around from 9 to 0.

In binary, the modular and reflected forms are the same (see L</Equivalent
Combinations> below).

There's various other systematic ways to make a Gray code changing a single
digit successively.  But many ways are implicitly based on a pre-determined
fixed number of bits or digits, which doesn't suit an unlimited path like
here.

=head2 Equivalent Combinations

Some option combinations are equivalent,

    condition                  equivalent
    ---------                  ----------
    radix=2                    modular==reflected
                               and TsF==Fs, Ts==FsT

    radix>2 odd, reflected     TsF==FsT, Ts==Fs, sT==sF
                               because T==F

    radix>2 even, reflected    TsF==Fs, Ts==FsT

In radix=2 binary, the "modular" and "reflected" Gray codes are the same
because there's only digits 0 and 1 so going forward or backward is the
same.

For odd radix and reflected Gray code, the "to Gray" and "from Gray"
operations are the same.  For example the following table is ternary
radix=3.  Notice how integer value 012 maps to Gray code 010, and in turn
integer 010 maps to Gray code 012.  All values are either pairs like that or
unchanged like 021.

    integer      Gray
              "reflected"       (written in ternary)
      000        000
      001        001
      002        002
      010        012
      011        011
      012        010
      020        020
      021        021
      022        022

For even radix and reflected Gray code, "TsF" is equivalent to "Fs", and
also "Ts" equivalent to "FsT".  This arises from the way the reversing
behaves when split across digits of two X,Y values.  (In higher dimensions
such as a split to 3-D X,Y,Z it's not the same.)

The net effect for distinct paths is

    condition         distinct combinations
    ---------         ---------------------
    radix=2           four TsF==Fs, Ts==FsT, sT, sF
    radix>2 odd       / three reflected TsF==FsT, Ts==Fs, sT==sF
                      \ six modular TsF, Ts, Fs, FsT, sT, sF
    radix>2 even      / four reflected TsF==Fs, Ts==FsT, sT, sF
                      \ six modular TsF, Ts, Fs, FsT, sT, sF

=head2 Peano Curve

In C<radix =E<gt> 3> and other odd radices, the "reflected" Gray type gives
the Peano curve (see L<Math::PlanePath::PeanoCurve>).  This is since the
"reflected" encoding is equivalent to Peano's "xk" and "yk" complementing.

=cut

# math-image --path=GrayCode,radix=3,gray_type=reflected --all --output=numbers_dash

=pod

    radix => 3, gray_type => "reflected"

     |
    53--52--51  38--37--36--35--34--33
             |   |                   |
    48--49--50  39--40--41  30--31--32
     |                   |   |
    47--46--45--44--43--42  29--28--27
                                     |
     6-- 7-- 8-- 9--10--11  24--25--26
     |                   |   |
     5-- 4-- 3  14--13--12  23--22--21
             |   |                   |
     0-- 1-- 2  15--16--17--18--19--20

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::GrayCode-E<gt>new ()>

=item C<$path = Math::PlanePath::GrayCode-E<gt>new (radix =E<gt> $r, apply_type =E<gt> $str, gray_type =E<gt> $str)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=item C<$n = $path-E<gt>n_start ()>

Return the first N on the path, which is 0.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, $radix**(2*$level) - 1)>.

=back

=head1 FORMULAS

=head2 Turn

The turns in the default binary TsF curve are either to the left +90 or a
reverse 180.  For example at N=2 the curve turns left, then at N=3 it
reverses back 180 to go to N=4.  The turn is given by the low zero bits of
(N+1)/2,

    count_low_0_bits(floor((N+1)/2))
      if even then turn 90 left
      if odd  then turn 180 reverse

Or equivalently

    floor((N+1)/2) lowest non-zero digit in base 4,
      1 or 3 = turn 90 left
      2      = turn 180 reverse

The 180 degree reversals are all horizontal.  They occur because at those N
the three N-1,N,N+1 converted to Gray code have the same bits at odd
positions and therefore the same Y coordinate.

See L<Math::PlanePath::KochCurve/N to Turn> for similar turns based on low
zero bits (but by +60 and -120 degrees).

=head1 OEIS

This path is in Sloane's Online Encyclopedia of Integer Sequences in a few
forms,

=over

L<http://oeis.org/A163233> (etc)

=back

    apply_type="TsF" (="Fs"), radix=2  (the defaults)
      A059905    X xor Y
      A039963    turn sequence, 1=+90 left, 0=180 reverse
      A035263    turn undoubled, at N=2n and N=2n+1
      A065882    base4 lowest non-zero,
                   turn undoubled 1,3=left 2=180rev at N=2n,2n+1
      A003159    (N+1)/2 of positions of Left turns,
                   being n with even number of low 0 bits
      A036554    (N+1)/2 of positions of Right turns
                   being n with odd number of low 0 bits

TsF turn sequence goes in pairs, so N=1 and N=2 left then N=3 and N=4
reverse.  A039963 includes that repetition, A035263 is just one copy of each
and so is the turn at each pair N=2k and N=2k+1.  There's many sequences
like A065882 which when taken mod2 equal the "count low 0-bits odd/even"
which is the same undoubled turn sequence.

    apply_type="Ts", radix=2
      A309952    X coordinate (XOR bit pairs)

    apply_type="sF", radix=2
      A163233    N values by diagonals, same axis start
      A163234     inverse permutation
      A163235    N values by diagonals, opp axis start
      A163236     inverse permutation
      A163242    N sums along diagonals
      A163478     those sums divided by 3

      A163237    N values by diagonals, same axis, flip digits 2,3
      A163238     inverse permutation
      A163239    N values by diagonals, opp axis, flip digits 2,3
      A163240     inverse permutation

      A099896    N values by PeanoCurve radix=2 order
      A100280     inverse permutation

    apply_type="FsT", radix=3, gray_type=modular
      A208665    N values on X=Y diagonal, base 9 digits 0,3,6

Gray code conversions themselves (not directly offered by the PlanePath code
here) are variously

    A003188  binary
    A014550  binary written in binary
    A055975    increments
    A006068    inverse, Gray->integer
    A128173  ternary reflected (its own inverse)
    A105530  ternary modular
    A105529    inverse, Gray->integer
    A003100  decimal reflected
    A174025    inverse, Gray->integer
    A098488  decimal modular
    A226134    inverse, Gray->integer

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ZOrderCurve>,
L<Math::PlanePath::PeanoCurve>,
L<Math::PlanePath::CornerReplicate>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
