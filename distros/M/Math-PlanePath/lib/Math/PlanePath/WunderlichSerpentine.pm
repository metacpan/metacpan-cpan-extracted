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


# http://sodwana.uni-ak.ac.at/geom/mitarbeiter/wallner/wunderlich/pdf/125.pdf
# [8.5mb]
#
# Walter Wunderlich. Uber Peano-Kurven. Elemente der Mathematik, 28(1):1-10,
# 1973.
#
# Coil order 111 111 111
#
# math-image --path=WunderlichSerpentine --all --output=numbers_dash
# math-image --path=WunderlichSerpentine,radix=5 --all --output=numbers_dash
# math-image --path=WunderlichSerpentine,serpentine_type=170 --all --output=numbers_dash
#


package Math::PlanePath::WunderlichSerpentine;
use 5.004;
use strict;
use Carp 'croak';
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
  'round_down_pow',
  'digit_split_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad1;

use constant parameter_info_array =>
  [ { name      => 'serpentine_type',
      display   => 'Serpentine Type',
      type      => 'string',
      default   => '010 101 010',
      choices   => ['alternating','coil','Peano'],
      width     => 11,
      type_hint => 'bit_string',
      description => 'Serpentine type, as a bit string or one of the predefined choices.',
    },
    { name      => 'radix',
      share_key => 'radix_3',
      display   => 'Radix',
      type      => 'integer',
      minimum   => 2,
      default   => 3,
      width     => 3,
    },
  ];


# same as PeanoCurve
use Math::PlanePath::PeanoCurve;
*dx_minimum = Math::PlanePath::PeanoCurve->can('dx_minimum');
*dx_maximum = Math::PlanePath::PeanoCurve->can('dx_maximum');
*dy_minimum = Math::PlanePath::PeanoCurve->can('dy_minimum');
*dy_maximum = Math::PlanePath::PeanoCurve->can('dy_maximum');

*_UNDOCUMENTED__dxdy_list = Math::PlanePath::PeanoCurve->can('_UNDOCUMENTED__dxdy_list');  # same
#
#     bit=0           bit=1
#  *---  b^2-1 -- b^2 
#  |               |  
#  *-------        |
#          |       |
#  0 ----- b
#
#     bit=0           bit=0
#  *---  b^2-1 -- b^2 ---- b^2+b-1
#  |                          |
#  *-------
#          |   
#  0 ----- b
#
#  *--------
#  |
#  *-------*     bit=1
#          |
#  *---  b^2-1
#  |              
#  *-------      bit=1
#          |      
#  0 ----- b
#
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  my $radix = $self->{'radix'};
  my $n = $radix*$radix;
  if ($self->{'serpentine_array'}->[0]) {
    foreach my $i (1 .. $self->{'radix'}-1) {
      if ($self->{'serpentine_array'}->[$i] == 0) {
        return $n*$i + $radix;
      }
    }
    if ($self->{'serpentine_array'}->[$radix] == 0) {
      return $n*$radix;
    } else {
      return $n*$radix + $radix-1;
    }
  } else {
    if ($self->{'serpentine_array'}->[1]) {
      return $n;
    } else {
      return $n + $radix-1;
    }
  }
}

*dsumxy_minimum = \&dx_minimum;
*dsumxy_maximum = \&dx_maximum;
*ddiffxy_minimum = \&dy_minimum;
*ddiffxy_maximum = \&dy_maximum;

# radix=2 0101 is straight NSEW parts, other evens are diagonal
sub dir_maximum_dxdy {
  my ($self) = @_;
  return (($self->{'radix'} % 2)
          || join('',@{$self->{'serpentine_array'}}) eq '0101'
          ? (0,-1)   # odd, South
          : (0,0));  # even, supremum
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  my $radix = $self->{'radix'};
  if (! $self->{'radix'} || $self->{'radix'} < 2) {
    $radix = $self->{'radix'} = 3;
  }

  my @serpentine_array;

  my $serpentine_type = $self->{'serpentine_type'};
  if (! defined $serpentine_type) {
    $serpentine_type = 'alternating';
  }
  $serpentine_type = lc($serpentine_type);
  ### $serpentine_type

  if ($serpentine_type eq 'alternating') {
    @serpentine_array = map {$_&1} 0 .. $radix*$radix - 1;

  } elsif ($serpentine_type eq 'coil') {
    @serpentine_array = (1) x ($radix*$radix);

  } elsif (lc($serpentine_type) eq 'peano') {
    @serpentine_array = (0) x ($radix*$radix);

  } elsif ($serpentine_type =~ /^([01_,.]|\s)*$/) {
    # bits 010,101,010 etc
    $serpentine_type =~ tr/01//cd;  # keep only 0,1 chars
    @serpentine_array
      = map {$_+0} # numize for xor
        split //, $serpentine_type;  # each char, 0,1
    push @serpentine_array,
      (0) x max(0,$radix*$radix-scalar(@serpentine_array));

    # foreach my $char  {
    #   if ($char eq '0' || $char eq '1') {
    #     push , $char;
    #   }
    #     my @parts = split /[^01]+/, $serpentine_type;
    #     ### @parts
    #     @parts = grep {$_ ne ''} @parts; # no empty parts
    #     foreach my $part (@parts) {
    #       my @bits = split //, $part;
    #       push @bits, (0) x max(0,scalar(@bits)-$radix);
    #       $#bits = $radix-1;
    #       push @serpentine_array, @bits;  # radix many row
    #     }

  } else {
    croak "Unrecognised serpentine_type \"$serpentine_type\"";
  }

  ### @serpentine_array
  $self->{'serpentine_array'} = \@serpentine_array;

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### WunderlichSerpentine n_to_xy(): $n

  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  {
    # ENHANCE-ME: for odd radix the ends join and the direction can be had
    # without a full N+1 calculation
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
    $n = $int; # BigFloat int() gives BigInt, use that
  }

  # high to low
  my $radix = $self->{'radix'};
  my $rsquared = $radix * $radix;
  my $radix_minus_1 = $radix - 1;
  my $serpentine_array = $self->{'serpentine_array'};

  my @digits = digit_split_lowtohigh($n,$rsquared);
  my $x = 0;
  my $y = 0;

  my $transpose = ($#digits & 1) && $serpentine_array->[0];
  my $xk = my $yk = 0;
  while (@digits) {
    my $ndigit = pop @digits;      # high to low
    my ($highdigit, $lowdigit) = _divrem ($ndigit, $radix);

    ### $lowdigit
    ### $highdigit

    if ($transpose) {
      $yk ^= $highdigit;
      $x *= $radix;
      $x += ($xk & 1 ? $radix_minus_1-$highdigit : $highdigit);

      $xk ^= $lowdigit;
      $y *= $radix;
      $y += ($yk & 1 ? $radix_minus_1-$lowdigit : $lowdigit);
    } else {
      $xk ^= $highdigit;
      $y *= $radix;
      $y += ($yk & 1 ? $radix_minus_1-$highdigit : $highdigit);

      $yk ^= $lowdigit;
      $x *= $radix;
      $x += ($xk & 1 ? $radix_minus_1-$lowdigit : $lowdigit);
    }
    ### $serpentine_array
    ### $ndigit
    $transpose ^= $serpentine_array->[$ndigit];
  }
  return ($x, $y);




  #   my $x = 0;
  #   my $y = 0;
  #   my $power = $x + 1;      # inherit bignum 1
  #   my $odd = 1;
  #   my $transpose = 0;
  #   while ($n) {
  #     $odd ^= 1;
  #     ### $n
  #     ### $power
  #
  #     my $xdigit = $n % $radix;
  #     $n = int($n/$radix);
  #     my $ydigit = $n % $radix;
  #     $n = int($n/$radix);
  #
  #     if ($transpose) {
  #       ($xdigit,$ydigit) = ($ydigit,$xdigit);
  #     }
  #     $transpose ^= $serpentine_array->[$xdigit + $radix*$ydigit];
  #
  #     ### $xdigit
  #     ### $ydigit
  #
  #     if ($xdigit & 1) {
  #       $y = $power-1 - $y;   # 99..99 - Y
  #     }
  #     $x += $power * $xdigit;
  #
  #     $y += $power * $ydigit;
  #     $power *= $radix;
  #     if ($ydigit & 1) {
  #       $x = $power-1 - $x;
  #     }
  #   }
  #
  # #
  #   # if ($odd) {
  #   #   ($x,$y) = ($y,$x);
  #   #   ### final transpose to: "$x,$y"
  #   # }
  #
  #   return ($x, $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### WunderlichSerpentine xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0
      || is_infinite($x)
      || is_infinite($y)) {
    return undef;
  }

  my $radix = $self->{'radix'};
  my $radix_minus_1 = $radix - 1;

  my @xdigits = digit_split_lowtohigh($x,$radix);
  my @ydigits = digit_split_lowtohigh($y,$radix);
  ### @xdigits
  ### @ydigits

  my $serpentine_array = $self->{'serpentine_array'};
  my $xk = 0;
  my $yk = 0;
  my $highpos = max($#xdigits,$#ydigits);
  my $transpose = $serpentine_array->[0] && ($highpos & 1);

  my $n = ($x * 0 * $y);  # inherit bignum 0

  foreach my $i (reverse 0 .. $highpos) {  # high to low
    my $xdigit = $xdigits[$i] || 0;
    my $ydigit = $ydigits[$i] || 0;
    my $ndigit;

    ### $n
    ### $xk
    ### $yk
    ### $transpose
    ### $xdigit
    ### $ydigit

    if ($transpose) {
      if ($xk & 1) { $xdigit = $radix_minus_1 - $xdigit; }
      $n *= $radix;
      $n += $xdigit;
      $yk ^= $xdigit;

      if ($yk & 1) { $ydigit = $radix_minus_1 - $ydigit; }
      $n *= $radix;
      $n += $ydigit;
      $xk ^= $ydigit;

      $ndigit = $radix*$xdigit + $ydigit;

    } else {
      if ($yk & 1) { $ydigit = $radix_minus_1 - $ydigit; }
      $n *= $radix;
      $n += $ydigit;
      $xk ^= $ydigit;

      if ($xk & 1) { $xdigit = $radix_minus_1 - $xdigit; }
      $n *= $radix;
      $n += $xdigit;
      $yk ^= $xdigit;

      $ndigit = $radix*$ydigit + $xdigit;
    }

    ### ndigits: "$ydigit, $xdigit"
    $transpose ^= $serpentine_array->[$ndigit];
  }
  return $n;


  # my $n = 0;
  # while (@x) {
  #   if (($xk ^ $yk) & 1) {
  #     {
  #       my $digit = pop @x;
  #       if ($xk & 1) {
  #         $digit = $radix_minus_1 - $digit;
  #       }
  #       $n = ($n * $radix) + $digit;
  #       $yk ^= $digit;
  #     }
  #     {
  #       my $digit = pop @y;
  #       if ($yk & 1) {
  #         $digit = $radix_minus_1 - $digit;
  #       }
  #       $n = ($n * $radix) + $digit;
  #       $xk ^= $digit;
  #     }
  #   } else {
  #     {
  #       my $digit = pop @y;
  #       if ($yk & 1) {
  #         $digit = $radix_minus_1 - $digit;
  #       }
  #       $n = ($n * $radix) + $digit;
  #       $xk ^= $digit;
  #     }
  #     {
  #       my $digit = pop @x;
  #       if ($xk & 1) {
  #         $digit = $radix_minus_1 - $digit;
  #       }
  #       $n = ($n * $radix) + $digit;
  #       $yk ^= $digit;
  #     }
  #   }
  # }
  #
  # return $n;

  # return $n;
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

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

  my $radix = $self->{'radix'};

  my ($pow, $level) = round_down_pow (max($x2,$y2), $radix);
  if (is_infinite($level)) {
    return (0, $level);
  }

  $pow *= $radix;
  return (0, $pow*$pow - 1);





  # my $n_power = $power * $power;
  # my $max_x = 0;
  # my $max_y = 0;
  # my $max_n = 0;
  # my $max_xk = 0;
  # my $max_yk = 0;
  #
  # my $min_x = 0;
  # my $min_y = 0;
  # my $min_n = 0;
  # my $min_xk = 0;
  # my $min_yk = 0;
  #
  # my $serpentine_array = $self->{'serpentine_array'};
  # if ($serpentine_array->[0] && ($level&1)) {
  #   $max_xk = $max_yk = $min_xk = $min_yk = 1;
  # }
  #
  #
  # # l<=c<h doesn't overlap c1<=c<=c2 if
  # #     l>c2 or h-1<c1
  # #     l>c2 or h<=c1
  # # so does overlap if
  # #     l<=c2 and h>c1
  # #
  # my $radix_minus_1 = $radix - 1;
  # my $overlap = sub {
  #   my ($c,$ck,$digit, $c1,$c2) = @_;
  #   if ($ck & 1) {
  #     $digit = $radix_minus_1 - $digit;
  #   }
  #   ### overlap consider: "inv@{[$ck&1]}digit=$digit ".($c+$digit*$power)."<=c<".($c+($digit+1)*$power)." cf $c1 to $c2 incl"
  #   return ($c + $digit*$power <= $c2
  #           && $c + ($digit+1)*$power > $c1);
  # };
  #
  # while ($power > 1) {
  #   $power = int($power/$radix);
  #   $n_power = int($n_power/$radix);
  #
  #   my $min_transpose = ($min_xk ^ $min_yk) & 1;
  #   my $max_transpose = ($min_xk ^ $min_yk) & 1;
  #
  #   ### $power
  #   ### $n_power
  #   ### $max_n
  #   ### $min_n
  #   if ($max_transpose) {
  #     my $digit;
  #     for ($digit = $radix_minus_1; $digit > 0; $digit--) {
  #       last if &$overlap ($max_x,$max_xk,$digit, $x1,$x2);
  #     }
  #     $max_n += $n_power * $digit;
  #     $max_yk ^= $digit;
  #     if ($max_xk&1) { $digit = $radix_minus_1 - $digit; }
  #     $max_x += $power * $digit;
  #   } else {
  #     my $digit;
  #     for ($digit = $radix_minus_1; $digit > 0; $digit--) {
  #       last if &$overlap ($max_y,$max_yk,$digit, $y1,$y2);
  #     }
  #     $max_n += $n_power * $digit;
  #     $max_xk ^= $digit;
  #     if ($max_yk&1) { $digit = $radix_minus_1 - $digit; }
  #     $max_y += $power * $digit;
  #   }
  #
  #   if ($min_transpose) {
  #     my $digit;
  #     for ($digit = 0; $digit < $radix_minus_1; $digit++) {
  #       last if &$overlap ($min_x,$min_xk,$digit, $x1,$x2);
  #     }
  #     $min_n += $n_power * $digit;
  #     $min_yk ^= $digit;
  #     if ($min_xk&1) { $digit = $radix_minus_1 - $digit; }
  #     $min_x += $power * $digit;
  #   } else {
  #     my $digit;
  #     for ($digit = 0; $digit < $radix_minus_1; $digit++) {
  #       last if &$overlap ($min_y,$min_yk,$digit, $y1,$y2);
  #     }
  #     $min_n += $n_power * $digit;
  #     $min_xk ^= $digit;
  #     if ($min_yk&1) { $digit = $radix_minus_1 - $digit; }
  #     $min_y += $power * $digit;
  #   }
  #
  #   $n_power = int($n_power/$radix);
  #   if ($max_transpose) {
  #     my $digit;
  #     for ($digit = $radix_minus_1; $digit > 0; $digit--) {
  #       last if &$overlap ($max_y,$max_yk,$digit, $y1,$y2);
  #     }
  #     $max_n += $n_power * $digit;
  #     $max_xk ^= $digit;
  #     if ($max_yk&1) { $digit = $radix_minus_1 - $digit; }
  #     $max_y += $power * $digit;
  #   } else {
  #     my $digit;
  #     for ($digit = $radix_minus_1; $digit > 0; $digit--) {
  #       last if &$overlap ($max_x,$max_xk,$digit, $x1,$x2);
  #     }
  #     $max_n += $n_power * $digit;
  #     $max_yk ^= $digit;
  #     if ($max_xk&1) { $digit = $radix_minus_1 - $digit; }
  #     $max_x += $power * $digit;
  #   }
  #
  #   if ($min_transpose) {
  #     my $digit;
  #     for ($digit = 0; $digit < $radix_minus_1; $digit++) {
  #       last if &$overlap ($min_y,$min_yk,$digit, $y1,$y2);
  #     }
  #     $min_n += $n_power * $digit;
  #     $min_xk ^= $digit;
  #     if ($min_yk&1) { $digit = $radix_minus_1 - $digit; }
  #     $min_y += $power * $digit;
  #   } else {
  #     my $digit;
  #     for ($digit = 0; $digit < $radix_minus_1; $digit++) {
  #       last if &$overlap ($min_x,$min_xk,$digit, $x1,$x2);
  #     }
  #     $min_n += $n_power * $digit;
  #     $min_yk ^= $digit;
  #     if ($min_xk&1) { $digit = $radix_minus_1 - $digit; }
  #     $min_x += $power * $digit;
  #   }
  # }
  # ### is: "$min_n at $min_x,$min_y  to  $max_n at $max_x,$max_y"
  # return ($min_n, $max_n);
}

#------------------------------------------------------------------------------
# levels

use Math::PlanePath::ZOrderCurve;
*level_to_n_range = \&Math::PlanePath::ZOrderCurve::level_to_n_range;
*n_to_level       = \&Math::PlanePath::ZOrderCurve::n_to_level;


#-----------------------------------------------------------------------------
1;
__END__

=for stopwords Walter Wunderlich Wunderlich's there'll eg Ryde OEIS trit-twiddling ie bignums prepending trit Math-PlanePath versa Online radix Uber Peano-Kurven Elemente der Mathematik Peano

=head1 NAME

Math::PlanePath::WunderlichSerpentine -- transpose parts of Peano curve, including coil order

=head1 SYNOPSIS

 use Math::PlanePath::WunderlichSerpentine;
 my $path = Math::PlanePath::WunderlichSerpentine->new (serpentine_type => '111_000_111');
 my ($x, $y) = $path->n_to_xy (123);

 # or another radix digits ...
 my $path5 = Math::PlanePath::WunderlichSerpentine->new (radix => 5);

=head1 DESCRIPTION

X<Wunderlich, Walter>This is an integer version of Walter Wunderlich's
variations on the C<PeanoCurve>.  A "serpentine type" controls transposing
of selected 3x3 sub-parts.  The default is "alternating" 010,101,010 which
transposes every second sub-part,

       8  | 60--61--62--63  68--69  78--79--80--81
          |  |           |   |   |   |           |
       7  | 59--58--57  64  67  70  77--76--75  ...
          |          |   |   |   |           |
       6  | 54--55--56  65--66  71--72--73--74
          |  |
       5  | 53  48--47  38--37--36--35  30--29
          |  |   |   |   |           |   |   |
       4  | 52  49  46  39--40--41  34  31  28
          |  |   |   |           |   |   |   |
       3  | 51--50  45--44--43--42  33--32  27
          |                                  |
       2  |  6-- 7-- 8-- 9  14--15  24--25--26
          |  |           |   |   |   |
       1  |  5-- 4-- 3  10  13  16  23--22--21
          |          |   |   |   |           |
      Y=0 |  0-- 1-- 2  11--12  17--18--19--20
          |
          +-------------------------------------
            X=0  1   2   3   4   5   6   7   8

C<serpentine_type> can be a string of 0s and 1s, with optional space, comma
or _ separators at each group of 3,

    "011111011"         0/1 string
    "011,111,011"
    "011_111_011"
    "011 111 011"

or special values

    "alternating"       01010101.. the default
    "coil"              11111... all 1s described below
    "Peano"             00000... all 0s, gives PeanoCurve

Each "1" sub-part is transposed.  The string is applied in order of the N
parts, irrespective of what net reversals and transposes are in force on a
particular part.

When no parts are transposed, which is a string of all 0s, the result is the
same as the C<PeanoCurve>.  The special C<serpentine_type =E<gt> "Peano">
gives that.

=head2 Coil Order

C<serpentine_type =E<gt> "coil"> means "111 111 111" to transpose all parts.
The result is like a coil viewed side-on,

     8      24--25--26--27--28--29  78--79--80--81--...
             |                   |   |
     7      23--22--21  32--31--30  77--76--75
                     |   |                   |
     6      18--19--20  33--34--35  72--73--74
             |                   |   |
     5      17--16--15  38--37--36  71--70--69
                     |   |                   |
     4      12--13--14  39--40--41  66--67--68
             |                   |   |
     3      11--10-- 9  44--43--42  65--64--63
                     |   |                   |
     2       6-- 7-- 8  45--46--47  60--61--62
             |                   |   |
     1       5-- 4-- 3  50--49--48  59--58--57
                     |   |                   |
    Y=0      0-- 1-- 2  51--52--53--54--55--56

           X=0   1   2   3   4   5   6   7   8

Whenever C<serpentine_type> begins with a "1" the initial sub-part is
transposed at each level.  The first step N=0 to N=1 is kept fixed along the
X axis, then the higher levels are transposed.  For example in the coil
above The N=9 to N=17 part is upwards, and then the N=81 to N=161 part is to
the right, and so on.

=head2 Radix

The optional C<radix> parameter gives the size of the sub-parts, similar to
the C<PeanoCurve> C<radix> parameter (see
L<Math::PlanePath::PeanoCurve/Radix>).  For example radix 5 gives

     radix => 5

     4  | 20-21-22-23-24-25 34-35 44-45 70-71-72-73-74-75 84-85
        |  |              |  |  |  |  |  |              |  |  |
     3  | 19-18-17-16-15 26 33 36 43 46 69-68-67-66-65 76 83 86
        |              |  |  |  |  |  |              |  |  |  |
     2  | 10-11-12-13-14 27 32 37 42 47 60-61-62-63-64 77 82 87
        |  |              |  |  |  |  |  |              |  |  |
     1  |  9--8--7--6--5 28 31 38 41 48 59-58-57-56-55 78 81 88
        |              |  |  |  |  |  |              |  |  |  |
    Y=0 |  0--1--2--3--4 29-30 39-40 49-50-51-52-53-54 79-80 89-..
        +---------------------------------------------------------
         X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17

Like the C<PeanoCurve> if the radix is even then the ends of each sub-part
don't join up.  For example in radix 4 N=15 isn't next to N=16, nor N=31 to
N=32, etc.

        |                                                              |
     3  | 15--14--13--12  16  23--24  31  47--46--45--44  48  55--56  63
        |              |   |   |   |   |               |   |   |   |   |
     2  |  8-- 9--10--11  17  22  25  30  40--41--42--43  49  54  57  62
        |  |               |   |   |   |   |               |   |   |   |
     1  |  7-- 6-- 5-- 4  18  21  26  29  39--38--37--36  50  53  58  61
        |              |   |   |   |   |               |   |   |   |   |
    Y=0 |  0-- 1-- 2-- 3  19--20  27--28  32--33--34--35  51--52  59--60
        +----------------------------------------------------------------
          X=0  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15

In the C<serpentine_type> 0,1 form, any space, comma, etc, separators should
group C<radix> many values, so for example

    serpentine_type => "00000_11111_00000_00000_11111"

The intention is to do something friendly if the separators are not on such
boundaries, so that say 000_111_000 can have a sensible meaning in a radix
higher than 3.  But exactly what is not settled, so always give a full
string of desired 0,1 for now.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::WunderlichSerpentine-E<gt>new ()>

=item C<$path = Math::PlanePath::WunderlichSerpentine-E<gt>new (serpentine_type =E<gt> $str, radix =E<gt> $r)>

Create and return a new path object.

The optional C<radix> parameter gives the base for digit splitting.  The
default is ternary, radix 3.  The radix should be an odd number, 3, 5, 7, 9
etc.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PeanoCurve>

Walter Wunderlich "Uber Peano-Kurven", Elemente der Mathematik, 28(1):1-10,
1973.  L<http://sodwana.uni-ak.ac.at/geom/mitarbeiter/wallner/wunderlich/>Z<>
L<http://sodwana.uni-ak.ac.at/geom/mitarbeiter/wallner/wunderlich/pdf/125.pdf>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
