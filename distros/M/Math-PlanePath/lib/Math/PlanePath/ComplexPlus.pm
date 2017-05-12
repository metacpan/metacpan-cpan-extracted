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



# math-image --path=ComplexPlus --all --scale=5
#
# math-image --path=ComplexPlus --expression='i<128?i:0' --output=numbers --size=132x40
#
# Realpart:
# math-image --path=ComplexPlus,realpart=2 --expression='i<50?i:0' --output=numbers --size=180
#
# Arms:
# math-image --path=ComplexPlus,arms=2 --expression='i<64?i:0' --output=numbers --size=79



package Math::PlanePath::ComplexPlus;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 124;

use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_up_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array =>
  [ { name      => 'realpart',
      display   => 'Real Part',
      type      => 'integer',
      default   => 1,
      minimum   => 1,
      width     => 2,
      description => 'Real part r in the i+r complex base.',
    },
    { name      => 'arms',
      share_key => 'arms_2',
      display   => 'Arms',
      type      => 'integer',
      minimum   => 1,
      maximum   => 2,
      default   => 1,
      width     => 1,
      description => 'Arms',
      when_name   => 'realpart',
      when_value  => '1',
    },
  ];

# b=i+r
# theta = atan(1/r)
sub x_negative_at_n {
  my ($self) = @_;
  if ($self->{'realpart'} == 1) { return 8; }
  return $self->{'norm'} ** _ceil((2*atan2(1,1)) / atan2(1,$self->{'realpart'}));
}
sub y_negative_at_n {
  my ($self) = @_;
  if ($self->{'realpart'} == 1) { return 32; }
  return $self->{'norm'} ** _ceil((4*atan2(1,1)) / atan2(1,$self->{'realpart'}));
}
sub _ceil {
  my ($x) = @_;
  my $int = int($x);
  return ($x > $int ? $int+1 : $int);
}

sub absdx_minimum {
  my ($self) = @_;
  return ($self->{'realpart'} == 1
          ? 0   # i+1 N=1 dX=0,dY=1
          : 1); # i+r otherwise always diff
}
# use constant dir_maximum_dxdy => (0,0);  # supremum, almost full way

sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'realpart'} != 1);  # realpart=1 never straight
}


#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new(@_);

  my $realpart = $self->{'realpart'};
  if (! defined $realpart || $realpart < 1) {
    $self->{'realpart'} = $realpart = 1;
  }
  $self->{'norm'} = $realpart*$realpart + 1;

  my $arms = $self->{'arms'};
  if (! defined $arms || $arms <= 0 || $realpart != 1) { $arms = 1; }
  elsif ($arms > 2) { $arms = 2; }
  $self->{'arms'} = $arms;

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### ComplexPlus n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  {
    my $int = int($n);
    ### $int
    ### $n
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+$self->{'arms'});
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;       # BigFloat int() gives BigInt, use that
  }

  my $realpart = $self->{'realpart'};
  my $norm = $self->{'norm'};
  ### $norm
  ### $realpart

  # for i+1,  arm=0 start X=0,Y=0,  arm=1 start X=0,Y=1
  my $x = 0;
  my $y = _divrem_mutate ($n, $self->{'arms'});

  # for i+1,  arm=0 start dX=1,dY=0,  arm=1 start dX=-1,dY=0
  my $dy = ($n * 0);              # 0, inheriting bignum from $n
  my $dx = ($y ? -1 : 1) + $dy;   #    inheriting bignum from $n

  foreach my $digit (digit_split_lowtohigh($n,$norm)) {
    ### at: "$x,$y  digit=$digit  dxdy=$dx,$dy"

    $x += $dx * $digit;
    $y += $dy * $digit;

    # multiply i+r, ie. (dx,dy) = (dx + i*dy)*(i+$realpart)
    ($dx,$dy) = ($realpart*$dx - $dy, $dx + $realpart*$dy);
  }

  ### final: "$x,$y"
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ComplexPlus xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my $realpart = $self->{'realpart'};
  {
    my $rx = $realpart*$x;
    my $ry = $realpart*$y;
    foreach my $overflow ($rx+$ry, $rx-$ry) {
      if (is_infinite($overflow)) { return $overflow; }
    }
  }

  my $orig_x = $x;
  my $orig_y = $y;

  my $norm = $self->{'norm'};
  my $zero = ($x * 0 * $y);  # inherit bignum 0
  my @n; # digits low to high

  my $prev_x = 0;
  my $prev_y = 0;
  while ($x || $y) {
    my $neg_y = $x - $y*$realpart;
    my $digit = $neg_y % $norm;
    ### at: "$x,$y  n=$n  digit $digit"

    push @n, $digit;
    $x -= $digit;
    $neg_y -= $digit;

    ### assert: ($neg_y % $norm) == 0
    ### assert: (($x * $realpart + $y) % $norm) == 0

    # divide i+r = mul (i-r)/(i^2 - r^2)
    #            = mul (i-r)/-norm
    # is (i*y + x) * (i-realpart)/-norm
    #  x = [ x*-realpart - y ] / -norm
    #    = [ x*realpart + y ] / norm
    #  y = [ y*-realpart + x ] / -norm
    #    = [ y*realpart - x ] / norm
    #
    ($x,$y) = (($x*$realpart+$y)/$norm, -$neg_y/$norm);

    if ($x == $prev_x && $y == $prev_y) {
      last;
    }
    $prev_x = $x;
    $prev_y = $y;
  }

  ### final: "$x,$y n=$n cf arms $self->{'arms'}"

  if ($y) {
    if ($self->{'arms'} > 1) {
      ### not on first arm, re-run as: -$orig_x, 1-$orig_y
      local $self->{'arms'} = 1;
      my $n = $self->xy_to_n(-$orig_x,1-$orig_y);
      if (defined $n) {
        return 1 + 2*$n; # 180 degrees
      }
    }
    ### X,Y not visited
    return undef;
  }

  my $n = digit_join_lowtohigh (\@n, $norm, $zero);
  if ($self->{'arms'} > 1) {
    $n *= 2;
  }
  return $n;
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ComplexPlus rect_to_n_range(): "$x1,$y1  $x2,$y2"

  my $xm = max(abs($x1),abs($x2));
  my $ym = max(abs($y1),abs($y2));
  my $n_hi = ($xm*$xm + $ym*$ym) * $self->{'arms'};
  if ($self->{'realpart'} == 1) {
    $n_hi *= 16;  # 2**4
  }
  return (0, int($n_hi));
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  $self->{'norm'}**$level * $self->{'arms'} - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n+1, $self->{'norm'});
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath ie Nstart Nlevel

=head1 NAME

Math::PlanePath::ComplexPlus -- points in complex base i+r

=head1 SYNOPSIS

 use Math::PlanePath::ComplexPlus;
 my $path = Math::PlanePath::ComplexPlus->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path traverses points by a complex number base i+r for integer
rE<gt>=1.  The default is base i+1

                         30  31          14  15                 5
                     28  29          12  13                     4
                         26  27  22  23  10  11   6   7         3
                     24  25  20  21   8   9   4   5             2
         62  63          46  47  18  19           2   3         1
     60  61          44  45  16  17           0   1         <- Y=0
         58  59  54  55  42  43  38  39                        -1
     56  57  52  53  40  41  36  37                            -2
                 50  51  94  95  34  35  78  79                -3
             48  49  92  93  32  33  76  77                    -4
                         90  91  86  87  74  75  70  71        -5
                     88  89  84  85  72  73  68  69            -6
        126 127         110 111  82  83          66  67        -7
    124 125         108 109  80  81          64  65            -8
        122 123 118 119 106 107 102 103                        -9
    120 121 116 117 104 105 100 101                           -10
                114 115          98  99                       -11
            112 113          96  97                           -12

      ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^
    -10  -9  -8  -7  -6  -5  -4  -3  -2  -1  X=0  1   2

The shape of these points N=0 to N=2^k-1 inclusive is equivalent to the
twindragon turned 135 degrees.  Each complex base point corresponds to a
unit square inside the twindragon curve (two DragonCurve back-to-back).

=head2 Real Part

Option C<realpart =E<gt> $r> selects another r for complex base b=i+r.  For
example

    realpart => 2
                                     45 46 47 48 49      8
                               40 41 42 43 44            7
                         35 36 37 38 39                  6
                   30 31 32 33 34                        5
             25 26 27 28 29 20 21 22 23 24               4
                      15 16 17 18 19                     3
                10 11 12 13 14                           2
           5  6  7  8  9                                 1
     0  1  2  3  4                                   <- Y=0

     ^
    X=0 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15

N is broken into digits of a base norm=r*r+1, ie. digits 0 to r*r inclusive.

    norm = r*r + 1
    Nstart = 0
    Nlevel = norm^level - 1

The low digit of N makes horizontal runs of r*r+1 many points, such as N=0
to N=4, then N=5 to N=9, etc shown above.  In the default r=1 these runs are
2 long.  For r=2 shown above they're 2*2+1=5 long, or r=3 would be 3*3+1=10,
etc.

The offset for each successive run is i+r, ie. Y=1,X=r such as at N=5 shown
above.  Then the offset for the next level is (i+r)^2 = (2r*i + r^2-1) so
N=25 begins at Y=2*r=4, X=r*r-1=3.  In general each level adds an angle

    angle = atan(1/r)
    Nlevel_angle = level * angle

So the points spiral around anti-clockwise.  For r=1 the angle is
atan(1/1)=45 degrees, so that for example level=4 is angle 4*45=180 degrees,
putting N=2^4=16 on the negative X axis as shown in the first sample above.

As r becomes bigger the angle becomes smaller, making it spiral more slowly.
The points never fill the plane, but the set of points N=0 to Nlevel are all
touching.

=head2 Arms

For C<realpart =E<gt> 1>, an optional C<arms =E<gt> 2> adds a second copy of
the curve rotated 180 degrees and starting from X=0,Y=1.  It meshes
perfectly to fill the plane.  Each arm advances successively so N=0,2,4,etc
is the plain path and N=1,3,5,7,etc is the copy

    arms=>2

        60  62          28  30                                 5
    56  58          24  26                                     4
        52  54  44  46  20  22  12  14                         3
    48  50  40  42  16  18   8  10                             2
                36  38   3   1   4   6  35  33                 1
            32  34   7   5   0   2  39  37                 <- Y=0
                        11   9  19  17  43  41  51  49        -1
                    15  13  23  21  47  45  55  53            -2
                                27  25          59  57        -3
                            31  29          63  61            -4

                             ^   
    -6  -5  -4  -3  -2  -1  X=0  1   2   3   4   5   6

There's no C<arms> parameter for other C<realpart> values as yet, only for
i+1.  Is there a good rotated arrangement for others?  Do "norm" many copies
fill the plane in general?

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ComplexPlus-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 2**$level - 1)>, or for 2 arms return C<(0, 2 * 2**$level -
1)>.  With the C<realpart> option return C<(0, $norm**$level - 1)> where
norm=realpart^2+1.

=back

=head1 FORMULAS

Various formulas and pictures etc for the i+1 case can be found in the
author's long mathematical write-up (section "Complex Base i+1")

=over

L<http://user42.tuxfamily.org/dragon/index.html>

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A146559> (etc)

=back

    realpart=1 (i+1, the default)
      A146559    dX at N=2^k-1 (step to next replication level)
      A077950,A077870
               location of ComplexMinus origin in ComplexPlus
               (mirror horizontal even level, vertical odd level)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ComplexMinus>,
L<Math::PlanePath::ComplexRevolving>,
L<Math::PlanePath::DragonCurve>

=over

L<http://user42.tuxfamily.org/dragon/index.html>

=back

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
