# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


# n_start=>0 to include N=0 at the origin, but that not a documented feature
# yet.

# http://algorithmicbotany.org/papers/#abop
#
# http://www.sciencedirect.com/science/article/pii/0025556479900804
# http://dx.doi.org/10.1016/0025-5564(79)90080-4 Helmut Vogel, "A Better Way
# to Construct the Sunflower Head", Volume 44, Issues 3-4, June 1979, Pages
# 179-189

# http://artemis.wszib.edu.pl/~sloot/2_1.html
#
# http://www.csse.monash.edu.au/publications/2003/tr-2003-149-full.pdf
#     on 3D surfaces of revolution or some such maybe
#     14 Mbytes (or preview with google)

# Count of Zeckendorf bits plotted on Vogel floret.
# Zeckendorf/Fibbinary with N bits makes radial spokes.  cf FibbinaryBitCount
# http://www.ms.unimelb.edu.au/~segerman/papers/sunflower_spiral_fibonacci_metric.pdf
# private copy ?

# closest two for phi are 1 and 4
#     n=1   r=sqrt(1) = 1
#           t=1/phi^2 = 0.381 around
#           x=-.72 y=.68
#     n=4   r=sqrt(4) = 2
#           t=4/phi^2 = 1.527 = .527 around
#           x=-1.97 y=-.337
#     diff angle=4/phi^2 - 1/phi^2 = 3/phi^2 = 3*(2-phi) = 1.14 = .14
#     diff dx=1.25 dy=1.017  hypot=1.61
#     dang = 2*PI()*(5-3*phi)
#     y = sin()
#     x = sin(2*PI()*(5-3*phi))

# Continued fraction
#               1
#     x = k + ------
#             k +  1
#                 ------
#                 k +  1
#                     ---
#                     k + ...
#
#     x = k + 1/x
#     (x-k/2)^2 = 1 + (k^2)/4
#
#         k + sqrt(4+k^2)
#     x = ---------------
#               2
#
#    k       x
#    1    (1+sqrt(5)) / 2
#    2    1 + sqrt(2)
#    3    (3+sqrt(13)) / 2
#    4    2 + sqrt(5)
#    5    (5 + sqrt(29)) / 2
#    6    3 + sqrt(10)
#   2e    e + sqrt(1+e^2)  even



package Math::PlanePath::VogelFloret;
use 5.004;
use strict;
use Carp 'croak';
use Math::Libm 'hypot';

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite';
use Math::PlanePath::SacksSpiral;

# uncomment this to run the ### lines
#use Smart::Comments '###';

use constant figure => 'circle';

use constant 1.02; # for leading underscore
use constant _PHI => (1 + sqrt(5)) / 2;
use constant _TWO_PI => 4*atan2(1,0);

# not documented yet ...
use constant rotation_types =>
  { phi   => { rotation_factor => 2 - _PHI(),
               radius_factor   => 0.624239116809924,
               # closest_Ns      => [ 1,4 ],
               # continued_frac  => [ 1,1,1,1,1,... ],
             },
    sqrt2 => { rotation_factor => sqrt(2)-1,
               radius_factor   => 0.679984167849259,
               # closest_Ns      => [ 3,8 ],
               # continued_frac  => [ 2,2,2,2,2,... ],
             },
    sqrt3 => { rotation_factor => sqrt(3)-1,
               radius_factor   => 0.755560810248419,
               # closest_Ns      => [ 3,7 ],
               # continued_frac  => [ 1,2,1,2,1,2,1,2,... ],
             },
    sqrt5 => { rotation_factor => sqrt(5)-2,
               radius_factor   => 0.853488207169303,
               # closest_Ns      => [ 4,8 ],
               # continued_frac  => [ 4,4,4,4,4,4,... ],
             },
  };

use constant parameter_info_array =>
  [
   {
    name      => 'rotation_type',
    type      => 'enum',
    display   => 'Rotation Type',
    share_key => 'vogel_rotation_type',
    choices   => ['phi', 'sqrt2', 'sqrt3', 'sqrt5', 'custom'],
    default   => 'phi',
   },
   {
    name => 'rotation_factor',
    type => 'float',
    type_hint => 'expression',
    display   => 'Rotation Factor',
    description => 'Rotation factor.  If you have Math::Symbolic then this  can be an expression like pi+2*e-phi (constants phi,e,gam,pi), otherwise it should be a plain number.',
    default => - (1 + sqrt(5)) / 2,
    default_expression => '-phi',
    width => 10,
    when_name  => 'rotation_type',
    when_value => 'custom',
   },
   { name           => 'radius_factor',
     display        => 'Radius Factor',
     description    => 'Radius factor, spreading points out to make them non-overlapping.  0 means the default factor.',
     type           => 'float',
     minimum        => 0,
     maximum        => 999,
     page_increment => 1,
     step_increment => .1,
     decimals       => 2,
     default        => 1,
     when_name  => 'rotation_type',
     when_value => 'custom',
   },
  ];

sub x_negative_at_n {
  my ($self) = @_;
  return int(.25 / $self->{'rotation_factor'}) + 1;
}
sub y_negative_at_n {
  my ($self) = @_;
  return int(.5 / $self->{'rotation_factor'}) + 1;
}
sub sumabsxy_minimum {
  my ($self) = @_;
  my ($x,$y) = $self->n_to_xy($self->n_start);
  return abs($x)+abs($y);
}
sub rsquared_minimum {
  my ($self) = @_;
  # starting N=1 at R=radius_factor*sqrt(1), theta=something
  return $self->{'radius_factor'} ** 2;
}
use constant gcdxy_maximum => 0;

sub turn_any_left {  # always left if rot<=0.5
  my ($self) = @_;
  return ($self->{'rotation_factor'} <= 0.5);
}
sub turn_any_right {  # always left if rot<=0.5
  my ($self) = @_;
  return ($self->{'rotation_factor'} > 0.5);
}
use constant turn_any_straight => 0;  # never straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  ### $self

  my $rotation_type = ($self->{'rotation_type'} ||= 'phi');
  my $defaults = rotation_types()->{$rotation_type}
    || croak 'Unrecognised rotation_type: "',$rotation_type,'"';

  $self->{'radius_factor'} ||= ($self->{'rotation_factor'}
                                ? 1.0
                                : $defaults->{'radius_factor'});
  $self->{'rotation_factor'} ||= $defaults->{'rotation_factor'};
  return $self;
}

# R=radius_factor*sqrt($n)
# R^2 = radius_factor^2 * $n
# avoids sqrt and sin/cos in the main n_to_xy()
#
sub n_to_rsquared {
  my ($self, $n) = @_;
  ### VogelFloret RSquared: $i, $seq->{'planepath_object'}

  if ($n < 0) { return undef; }
  my $rf = $self->{'radius_factor'};
  $rf *= $rf;  # squared

  # don't round BigInt*flonum if radius_factor is not an integer, promote to
  # BigFloat instead
  if (ref $n && $n->isa('Math::BigInt') && $rf != int($rf)) {
    require Math::BigFloat;
    $n = Math::BigFloat->new($n);
  }
  return $n * $rf;
}


sub n_to_xy {
  my ($self, $n) = @_;
  if ($n < 0) { return; }

  my $two_pi = _TWO_PI();

  if (ref $n) {
    if ($n->isa('Math::BigInt')) {
      $n = Math::PlanePath::SacksSpiral::_bigfloat()->new($n);
    }
    if ($n->isa('Math::BigRat')) {
      $n = $n->as_float;
    }
    if ($n->isa('Math::BigFloat')) {
      $two_pi = 2 * Math::BigFloat->bpi;
    }
  }

  my $r = sqrt($n) * $self->{'radius_factor'};

  # take the frac part of 1==circle and then convert to radians, so as not
  # to lose precision in an fmod(...,2*pi)
  #
  my $theta = $n * $self->{'rotation_factor'};    # 1==full circle
  $theta = $two_pi * ($theta - int($theta));  # radians 0 to 2*pi
  return ($r * cos($theta),
          $r * sin($theta));

  # cylindrical_to_cartesian() is only perl code, so may as well sin/cos
  # here directly
  # return (Math::Trig::cylindrical_to_cartesian($r, $theta, 0))[0,1];
}

sub xy_to_n {
  my ($self, $x, $y) = @_;

  # Slack approach just trying all the N values between r-.5 and r+.5.
  #
  # r = sqrt(n)*FACTOR
  # n = (r/FACTOR)^2
  #
  # The target N satisfies N = K * phi + epsilon for integer K.  What's an
  # easy way to find the first integer N >= (r-.5)**2 satisfying -small <= N
  # mod .318 <= +small ?
  #
  my $r = sqrt($x*$x + $y*$y);  # hypot
  my $factor = $self->{'radius_factor'};
  my $n_lo = int( (($r-.6)/$factor)**2 );
  if ($n_lo < 0) { $n_lo = 0; }
  my $n_hi = int( (($r+.6)/$factor)**2 + 1 );
  #### $r
  #### xy: "$x,$y"
  #### $n_lo
  #### $n_hi

  if (is_infinite($n_lo) || is_infinite($n_hi)) {
    ### infinite range, r inf or too big
    return undef;
  }

  # for(;;) loop since "reverse $n_lo..$n_hi" limited to IV range
  for (my $n = $n_hi; $n >= $n_lo; $n--) {
    my ($nx, $ny) = $self->n_to_xy($n);
    ### hypot: "$n ".hypot($nx-$x,$ny-$y)
    if (hypot($nx-$x,$ny-$y) <= 0.5) {
      #### found: $n
      return $n;
    }
  }
  return undef;

  # my $theta_frac = Math::PlanePath::MultipleRings::_xy_to_angle_frac($x,$y);
  # ### assert: 0 <= $frac && $frac < 1
  #
  #   # seeking integer k where (k+theta)*PHIPHI == $r*$r == $n or nearby
  #   my $k = $r*$r / (PHI*PHI) - $theta;
  #
  #   ### $x
  #   ### $y
  #   ### $r
  #   ### $theta
  #   ### $k
  #
  #   foreach my $ki (POSIX::floor($k), POSIX::ceil($k)) {
  #     my $n = int (($ki+$theta)*PHI*PHI + 0.5);
  #
  #     # look for within 0.5 radius
  #     my ($nx, $ny) = $self->n_to_xy($n);
  #     ### $ki
  #     ### n frac: ($ki+$theta)*PHI*PHI
  #     ### $n
  #     ### hypot: hypot($nx-$x,$ny-$y)
  #     if (hypot($nx-$x,$ny-$y) <= 0.5) {
  #       return $n;
  #     }
  #   }
  #   return;
}

# max corner at R
# R+0.5 = sqrt(N) * radius_factor
# sqrt(N) = (R+0.5)/rfactor
# N = (R+0.5)^2 / rfactor^2
#   = (R^2 + R + 1/4) / rfactor^2
#   <= (X^2+Y^2 + X+Y + 1/4) / rfactor^2
#   <= (X(X+1) + Y(Y+1) + 1) / rfactor^2
#
# min corner at R
# R-0.5 = sqrt(N) * radius_factor
# sqrt(N) = (R-0.5)/rfactor
# N = (R-0.5)^2 / rfactor^2
#   = (R^2 - R + 1/4) / rfactor^2
#   >= (X^2+Y^2 - (X+Y)) / rfactor^2      because x+y >= r
#   = (X(X-1) + Y(Y-1)) / rfactor^2

# not exact
sub rect_to_n_range {
  my $self = shift;
  ### VogelFloret rect_to_n_range(): @_
  my ($n_lo, $n_hi) = Math::PlanePath::SacksSpiral->rect_to_n_range(@_);

  my $rf = $self->{'radius_factor'};
  $rf *= $rf; # squared

  # avoid BigInt/flonum if radius_factor is not an integer, promote to
  # BigFloat instead
  if ($rf == int($rf)) {
    $n_hi += $rf-1; # division round upwards
  } else {
    if (ref $n_lo && $n_lo->isa('Math::BigInt')) {
      require Math::BigFloat;
      $n_lo = Math::BigFloat->new($n_lo);
    }
    if (ref $n_hi && $n_lo->isa('Math::BigInt')) {
      require Math::BigFloat;
      $n_hi = Math::BigFloat->new($n_hi);
    }
  }

  $n_lo = int($n_lo / $rf);
  if ($n_lo < 1) { $n_lo = 1; }

  $n_hi = _ceil($n_hi / $rf);

  return ($n_lo, $n_hi);
}

sub _ceil {
  my ($x) = @_;
  my $int = int($x);
  return ($x > $int ? $int+1 : $int);
}

1;
__END__

=for stopwords Helmut Vogel fibonacci sqrt sqrt2 Ryde Math-PlanePath frac repdigits straightish Vogel's builtin repunit eg phi-ness radix Zeckendorf OEIS

=head1 NAME

Math::PlanePath::VogelFloret -- circular pattern like a sunflower

=head1 SYNOPSIS

 use Math::PlanePath::VogelFloret;
 my $path = Math::PlanePath::VogelFloret->new;
 my ($x, $y) = $path->n_to_xy (123);

 # other rotations
 $path = Math::PlanePath::VogelFloret->new
           (rotation_type => 'sqrt2');

=head1 DESCRIPTION

X<Vogel, Helmut>X<Golden Ratio>The is an implementation of Helmut Vogel's
model for the arrangement of seeds in the head of a sunflower.  Integer
points are on a spiral at multiples of the golden ratio phi = (1+sqrt(5))/2,

                27       19
                                  24

                14          11
          22                         16
                       6                   29

    30           9           3
                                   8
                       1                   21
          17              .
                    4
                                     13
       25                 2     5
             12
                    7                      26
                               10
                                     18
             20       15

                            23       31
                   28

The polar coordinates for a point N are

    R = sqrt(N) * radius_factor
    angle = N / (phi**2)        in revolutions, 1==full circle
          = N * -phi            modulo 1, with since 1/phi^2 = 2-phi
    theta = 2*pi * angle        in radians

Going from point N to N+1 adds an angle 0.382 revolutions around
(anti-clockwise, the usual spiralling direction), which means just over 1/3
of a circle.  Or equivalently it's -0.618 back (clockwise) which is
phi=1.618 ignoring the integer part since that's a full circle -- only the
fractional part determines the position.

C<radius_factor> is a scaling 0.6242 designed to put the closest points 1
apart.  The closest are N=1 and N=4.  See L</Packing> below.

=head2 Other Rotation Types

An optional C<rotation_type> parameter selects other possible floret forms.

    $path = Math::PlanePath::VogelFloret->new
               (rotation_type => 'sqrt2');

The current types are as follows.  The C<radius_factor> for each keeps
points at least 1 apart so unit circles don't overlap.

    rotation_type   rotation_factor   radius_factor
      "phi"        2-phi   = 0.3820     0.624
      "sqrt2"      sqrt(2) = 0.4142     0.680
      "sqrt3"      sqrt(3) = 0.7321     0.756
      "sqrt5"      sqrt(5) = 0.2361     0.853

The "sqrt2" floret is quite similar to phi, but doesn't pack as tightly.
Custom rotations can be made with C<rotation_factor> and C<rotation_factor>
parameters,

    # R  = sqrt(N) * radius_factor
    # angle = N * rotation_factor     in revolutions
    # theta = 2*pi * angle            in radians
    #
    $path = Math::PlanePath::VogelFloret->new
               (rotation_factor => sqrt(37),
                radius_factor   => 2.0);

Usually C<rotation_factor> should be an irrational number.  A rational like
P/Q merely results in Q many straight lines and doesn't spread the points
enough to suit R=sqrt(N).  Irrationals which are very close to simple
rationals behave that way too.  (Of course all floating point values are
implicitly rationals, but are fine within the limits of floating point
accuracy.)

The "noble numbers" (A+B*phi)/(C+D*phi) with A*D-B*C=1, AE<lt>B, CE<lt>D
behave similar to the basic phi.  Their continued fraction expansion begins
with some arbitrary values and then becomes a repeating "1" the same as phi.
The effect is some spiral arms near the origin then the phi-ness dominating
for large N.

=head2 Packing

Each point is at an increasing distance sqrt(N) from the origin.  This sqrt
based on how many unit figures will fit within that distance.  The area
within radius R is

    T = pi * R^2        area of circle R

so if N figures each of area A are packed into that space then the radius R
is proportional to sqrt(N),

    N*A = T = pi * R^2
    R = sqrt(N) * sqrt(A/pi)

The tightest possible packing for unit circles is a hexagonal honeycomb
grid, each of area A = sqrt(3)/2 = 0.866.  That would be factor sqrt(A/pi) =
0.525.  The phi floret packing is not as tight as that, needing radius
factor 0.624 as described above.

Generally the tightness of the packing depends on the fractions which
closely approximate the rotation factor.  If the terms of the continued
fraction expansion are large then there's large regions of spiral arcs with
gaps between.  The density in such regions is low and a big radius factor is
needed to keep the points apart.  If the continued fraction terms are ever
increasing then there may be no radius factor big enough to always keep the
points a minimum distance apart ... or something like that.

The terms of the continued fraction for phi are all 1 and is therefore, in
that sense, among all irrationals, the value least well approximated by
rationals.

                1
    phi = 1 + ------
              1 +  1
                  ------
              ^   1 +  1
              |       ---
              |   ^   1 + 1
              |   |      ----
              |   |   ^  ...
       terms -+---+---+

sqrt(3) is 1,2 repeating.  sqrt(13) is 3s repeating.

=head2 Fibonacci and Lucas Numbers

X<Fibonacci numbers>X<Lucas numbers>The Fibonacci numbers F(k) =
1,1,2,3,5,8,13,21, etc and Lucas number L(k) = 2,1,3,4,7,11,18, etc form
almost straight lines on the X axis of the phi floret.  This occurs because
N*-phi is close to an integer for those N.  For example N=13 has angle
13*-phi = -21.0344, the fractional part -0.0344 puts it just below the X
axis.

Both F(k) and L(k) grow exponentially (as phi^k) which soon outstrips the
sqrt in the R radial distance so they become widely spaced apart along the X
axis.

For interest, or for reference, the angle F(k)*phi is in fact roughly the
next Fibonacci number F(k+1), per the well-known limit F(k+1)/F(k) -> phi as
k->infinity,

    angle = F(k)*-phi
          = -F(k+1) + epsilon

The Lucas numbers similarly with L(k)*phi close to L(k+1).  The "epsilon"
approaches zero quickly enough in both cases that the resulting Y coordinate
approaches zero.  This can be calculated as follows, writing

    beta = -1/phi =-0.618

Since abs(beta)<1 the powers beta^k go to zero.

    F(k) = (phi^k - beta^k) / (phi - beta)    # an integer

    angle = F(k) * -phi
          = - (phi*phi^k - phi*beta^k) / (phi - beta)
          = - (phi^(k+1) - beta^(k+1)
                         + beta^(k+1) - phi*beta^k) / (phi - beta)
          = - F(k+1) - (phi-beta)*beta^k / (phi - beta)
          = - F(k+1) - beta^k

    frac(angle) = - beta^k = 1/(-phi)^k

The arc distance away from the X axis at radius R=sqrt(F(k)) is then as
follows, simplifying using phi*(-beta)=1 and S<phi - beta> = sqrt(5).  The Y
coordinate vertical distance is a little less than the arc distance.

    arcdist = 2*pi * R * frac(angle)
            = 2*pi * sqrt((phi^k - beta^k)/sqrt(5)) * 1/(-phi)^k
            = - (-1)^k * 2*pi * sqrt((1/phi^2k*phi^k - beta^3k)/sqrt(5))
            = - (-1)^k * 2*pi * sqrt((1/phi^k - 1/(-phi)^3k)/sqrt(5))
                -> 0 as k -> infinity

Essentially the radius increases as phi^(k/2) but the angle frac decreases
as (1/phi)^k so their product goes to zero.  The (-1)^k in the formula puts
the points alternately just above and just below the X axis.

The calculation for the Lucas numbers is very similar, with term +(beta^k)
instead of -(beta^k) and an extra factor sqrt(5).

    L(k) = phi^k + beta^k

    angle = L(k) * -phi
          = -phi*phi^k - phi*beta^k
          = -phi^(k+1) - beta^(k+1) + beta^(k+1) - phi*beta^k
          = -L(k) + beta^k * (beta - phi)
          = -L(k) - sqrt(5) * beta^k

    frac(angle) = -sqrt(5) * beta^k = -sqrt(5) / (-phi)^k

    arcdist = 2*pi * R * frac(angle)
            = 2*pi * sqrt(L(k)) * sqrt(5)*beta^k
            = 2*pi * sqrt(phi^k + 1/(-phi)^k) * sqrt(5)*beta^k
            = (-1)*k * 2*pi * sqrt(5) * sqrt((-beta)^2k * phi^k + beta^3k)
            = (-1)*k * 2*pi * sqrt(5) * sqrt((-beta)^k + beta^3k)

=head2 Spectrum

The spectrum of a real number is its multiples, each rounded down to an
integer.  For example the spectrum of phi is

    floor(phi), floor(2*phi), floor(3*phi), floor(4*phi), ...
    1,          3,            4,            6, ...

When plotted on the Vogel floret these integers are all in the first 1/phi =
0.618 of the circle.


=cut

# math-image --oeis=A000201 --output=numbers   # but better scaled in vogel.pl
# A001950    floor(N*phi^2) spectrum of 1+1/phi
# A000201    floor(N*phi)   spectrum of phi

=pod

                   61    53
             69       40       45    58
                48          32          71
          56       27                37
             35          19    24       50
          43       14       11             63
    64          22     6          16 29
          30                 3          42
       51           9  1        8    21
    72       17     4     .                55
          38
    59       25 12

          46 33

       67

This occurs because

    angle = N * 1/phi^2
          = N * (1-1/phi)
          = N * -1/phi                   # modulo 1
          = floor(int*phi) * -1/phi      # N=spectrum
          = (int*phi - frac) * -1/phi    # 0<frac<1
          = int + frac*1/phi
          = frac * 1/phi                 # modulo 1

So the angle is a fraction from 0 to 1/phi=0.618 of a revolution.  In
general for a C<rotation_factor=t> with 0E<lt>tE<lt>1 the spectrum of 1/t
falls within the first 0 to t angle.

=head2 Fibonacci Word

The Fibonacci word 0,1,0,0,1,0,1,0,0,1,etc is the least significant bit of
the Zeckendorf base representation of i, starting from i=0.  Plotted at N=i
on the C<VogelFloret> gives

              1       0
          1     1 1   0   0            Fibonacci word
        1   1 1     0       0
          1       1   0   0 0
    1   1   1 1 1   0   0 0   0
      1 1     1 1   0 0     0
    1   1 1   1   .       0 0 0
    1     1 1     0   0 0       0
        1       0   0   0 0   0
      1   1 0     0       0   0
        0   0 0   0 0   0 0   0
            0   0     0 0
                0   0

This pattern occurs because the Fibonacci word, among its various possible
definitions, is 0 or 1 according to whether i+1 occurs in the spectrum of
phi (1,3,4,6,8,etc) or not.  So for example at i=5 the value is 0 because
i+1=6 is in the spectrum of phi, then at i=6 the value is 1 because i+1=7 is
not.

The "+1" for i to spectrum has the effect of rotating the spectrum pattern
described above by -0.381 (one rotation factor back).  So the Fibonacci word
"0"s are from angle -0.381 to -0.381+0.618=0.236 and the rest "1"s.  0.236
is close to 1/4, hence the "0"s to "1"s line just before the Y axis.

=cut

# math-image--path=VogelFloret --values=FibonacciWord --output=numbers

# 1*phi = 1.61  1   1       0
#               2   0       1
# 2*phi = 3.23  3   1       0
# 3*phi = 4.85  4   1       0
#                   0       1
# 4*phi = 6.47  6   1       0
#                   0       1
# 5*phi = 8.09      1       0
# 6*phi = 9.70      1       0

=pod


=cut

# angle = N * t
# N = s*i - frac    spectrum of s
# angle = t*(s*i-frac)
#       = t*s*i - t*frac
# s=1/t is spectrum s>1

=pod

=head2 Repdigits in Decimal

Some of the decimal repdigits 11, 22, ..., 99, 111, ..., 999, etc make
nearly straight radial lines on the phi floret.  For example 11, 66, 333,
888 make a line upwards to the right.

11 and 66 are at the same polar angle because the difference is 55 and
55*phi = 88.9919 is nearly an integer meaning the angle is nearly unchanged
when added.  Similarly 66 to 333 difference 267 has 267*phi = 432.015, or
333 to 888 difference 555 has 555*phi = 898.009.  The 55 is a Fibonacci
number, the 123 between 99 and 222 is a Lucas number, and 267 = 144+123 =
F(12)+L(10).

The differences 55 and 555 apply to pairs 22 and 77, 33 and 88, 666 and
1111, etc, making four straightish arms.  55 and 555 themselves are near the
X axis.

A separate spiral arm arises from 11111 falling moderately close to the X
axis since 11111*-phi = -17977.9756, or about 0.024 of a circle upwards.
The subsequent 22222, 33333, 44444, etc make a little arc of nine values
going upwards that much each time for a total about a quarter turn 9*0.024 =
0.219.

=head2 Repdigits in Other Bases

By choosing a radix so that "11" (or similar repunit) in that radix is close
to the X axis, spirals like the decimal 11111 above can be created.  This
includes when "11" in the base is a Fibonacci number or Lucas number, such
as base 12 so "11" base 12 is 13.  If "11" is near the negative X axis then
there's two spiral arms, one going out on the X negative side and one X
positive, eg. base 16 has 0x11=17 which is near the negative X axis.
A four-arm shape can be formed similarly if "11" is near the Y axis,
eg. base 107.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::VogelFloret-E<gt>new ()>

=item C<$path = Math::PlanePath::VogelFloret-E<gt>new (key =E<gt> value, ...)>

Create and return a new path object.

The default is Vogel's phi floret.  Optional parameters can vary the
pattern,

    rotation_type   => string, choices above
    rotation_factor => number
    radius_factor   => number

The available C<rotation_type> values are listed above (see L</Other
Rotation Types>).  C<radius_factor> can be given together with
C<rotation_type> to have its rotation, but scale the radius differently.

If a C<rotation_factor> is given then the default C<radius_factor> is not
specified yet.  Currently it's 1.0, but perhaps something suiting at least
the first few N positions would be better.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

C<$n> can be any value C<$n E<gt>= 0> and fractions give positions on the
spiral in between the integer points, though the principle interest for the
floret is where the integers fall.

For C<$n < 0> the return is an empty list, it being considered there are no
negative points in the spiral.

=item C<$rsquared = $path-E<gt>n_to_rsquared ($n)>

Return the radial distance R^2 of point C<$n>, or C<undef> if there's no
point C<$n>.  As per the formulas above this is simply

    $n * $radius_factor**2

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return an integer point number for coordinates C<$x,$y>.  Each integer N
is considered the centre of a circle of diameter 1 and an C<$x,$y> within
that circle returns N.

The builtin C<rotation_type> choices are scaled so no two points are closer
than 1 apart so the circles don't overlap, but they also don't cover the
plane and if C<$x,$y> is not within one of those circles then the return is
C<undef>.

With C<rotation_factor> and C<radius_factor> parameters it's possible for
unit circles to overlap.  In the current code the return is the largest N
covering C<$x,$y>, but perhaps that will change.

=item C<$str = $path-E<gt>figure ()>

Return "circle".

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A000201> (etc)

=back

    A000201    spectrum of phi, N in first 0.618 of circle
    A003849    Fibonacci word, values 0,1

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SacksSpiral>,
L<Math::PlanePath::TheodorusSpiral>

L<Math::NumSeq::FibonacciWord>,
L<Math::NumSeq::Fibbinary>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
