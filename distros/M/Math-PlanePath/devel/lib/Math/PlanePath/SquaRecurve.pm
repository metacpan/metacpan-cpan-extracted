# Copyright 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


# https://books.google.com.au/books?id=-4W_5ZISxpsC&pg=PA49
#
# cf counting all 5x5 traversals
# 1,1,7,138,5960
# not in OEIS: 138,5960


package Math::PlanePath::SquaRecurve;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;
*_sqrtint = \&Math::PlanePath::_sqrtint;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_split_lowtohigh','digit_join_lowtohigh';

use Math::PlanePath::PeanoCurve;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;

use constant parameter_info_array =>
  [ { name      => 'k',
      display   => 'K',
      type      => 'integer',
      minimum   => 3,
      default   => 5,
      width     => 3,
      page_increment => 10,
      step_increment => 2,
    } ];

# ../../../squarecurve.pl
# ../../../run.pl

my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'k'} ||= 5;

  my $k = $self->{'k'} | 1;
  my $turns = $k >> 1;
  my $square = $k*$k;
  my @digit_to_x;
  my @digit_to_y;
  $self->{'digit_to_x'} = \@digit_to_x;
  $self->{'digit_to_y'} = \@digit_to_y;
  my @digit_to_dir;
  {
    my $x = 0;
    my $y = 0;
    my $dx = 0;
    my $dy = 1;
    my $dir = 1;
    my $n = 0;
    my $run = sub {
      my ($r) = @_;
      foreach my $i (1 .. $r) {
        $digit_to_x[$n] = $x;
        $digit_to_y[$n] = $y;
        $digit_to_dir[$n] = $dir & 3;
        $n++;
        $x += $dx;
        $y += $dy;
      }
    };
    my $spiral = sub {
      while (@_) {
        my $r = shift;
        $run->($r || 1);
        ($dx,$dy) = ($dy,-$dx); # rotate -90
        $dir--;
        last if $r == 0;
      }
      $dx = -$dx;
      $dy = -$dy;
      $dir += 2;
      while (@_) {
        my $r = shift;
        $run->($r);
        ($dx,$dy) = (-$dy,$dx); # rotate +90
        $dir++;
      }
    };
    # 7,9,  3,4
    my $first = (($turns-1) & 2);
    $spiral->(reverse(0 .. $turns),
              1 .. $turns-1,
              ($first
               ? ($turns-1)
               : ($turns, $turns-1)));

    ($dx,$dy) = (-$dx,-$dy); # rotate 180
    $dir += 2;
    if ($first) {
      $spiral->(0,1);
    }

    $spiral->(($first ? ($turns) : ()),
              reverse(0 .. $turns),
              1 .. $turns-1,
              $turns-2);

    ($dx,$dy) = (-$dx,-$dy); # rotate 180
    $dir += 2;

    $spiral->(reverse(0 .. $turns),
              1 .. $turns-2,
              ($first
               ? ($turns-1)
               : ($turns-2)));

    if ($first) {
    } else {
      ($dx,$dy) = (-$dx,-$dy); # rotate 180
      $dir += 2;
      $spiral->(0,1);
    }

    $spiral->(($first ? $turns-2 : $turns-1),
              reverse(0 .. $turns-1),
              1 .. $turns);
  }

  my @next_state;
  my @digit_to_sx;
  my @digit_to_sy;
  $self->{'next_state'} = \@next_state;
  $self->{'digit_to_sx'} = \@digit_to_sx;
  $self->{'digit_to_sy'} = \@digit_to_sy;
  my %xy_to_n;

  my $more = 1;
  while ($more) {
    $more = 0;
    my %xy_to_n_list;
    $more = 0;
    foreach my $n (0 .. $k*$k-1) {
      next if defined $digit_to_sx[$n];
      my $dir = $digit_to_dir[$n];
      my $x = $digit_to_x[$n];
      my $y = $digit_to_y[$n];
      my $dx = $dir4_to_dx[$dir];
      my $dy = $dir4_to_dy[$dir];
      my ($lx,$ly) = (-$dy,$dx); # rotate +90
      my $count = 0;
      my ($sx,$sy,$snext);
      foreach my $right (0, 4) {
        my $next_state = $dir ^ $right;
        my $cx = (2*$x + $dx + $lx - 1)/2;
        my $cy = (2*$y + $dy + $ly - 1)/2;
        ### consider: "$n right=$right is $cx,$cy"
        if ($cx >= 0 && $cy >= 0 && $cx < $k && $cy < $k) {
          push @{$xy_to_n_list{"$cx,$cy"}}, $n, $next_state;
          $count++;
          ($sx,$sy) = ($cx,$cy);
          $snext = $next_state;
        }
        ($lx,$ly) = (-$lx,-$ly);
      }
      if ($count==1) {
        die if defined $digit_to_sx[$n];
        ### store one side: "$n at $sx,$sy  next state $snext"
        $digit_to_sx[$n] = $sx;
        $digit_to_sy[$n] = $sy;
        $next_state[$n] = $snext;
        $more = 1;
        my $sxy = "$sx,$sy";
        if (defined $xy_to_n{$sxy} && $xy_to_n{$sxy} != $n) {
          die "already $xy_to_n{$sxy}";
        }
        $xy_to_n{$sxy} = $n;
      }
    }
    while (my ($cxy,$n_list) = each %xy_to_n_list) {
      ### cxy: "$cxy ".join(',',@$n_list)
      if (@$n_list == 2) {
        my $n = $n_list->[0];
        my ($sx,$sy) = split /,/, $cxy;
        my $sxy = "$sx,$sy";
        if (defined $xy_to_n{$sxy} && $xy_to_n{$sxy} != $n) {
          ### already $xy_to_n{$sxy}
          next;
        }
        $xy_to_n{$sxy} = $n;
        $digit_to_sx[$n] = $sx;
        $digit_to_sy[$n] = $sy;
        $next_state[$n] = $n_list->[1];
        $more = 1;
        ### store one choice: "$n at $sx,$sy  next state $next_state[$n]"
      }
    }
  }

  ### sx        : join(',',@digit_to_sx)
  ### sy        : join(',',@digit_to_sy)
  ### next state: join(',',@next_state)
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### SquaRecurve n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }


  my $int = int($n);
  $n -= $int;
  my $k = $self->{'k'} | 1;
  my $square = $k*$k;
  if ($n >= $square**3) { return; }

  my @digits = digit_split_lowtohigh($int,$square);
  while (@digits < 1) {
    push @digits, 0;
  }

  my $digit_to_sx = $self->{'digit_to_sx'};
  my $digit_to_sy = $self->{'digit_to_sy'};
  my $next_state = $self->{'next_state'};

  my @x;
  my @y;
  my $dir = 1;
  my $right = 4;
  my $fracdir = 1;
  foreach my $i (reverse 0 .. $#digits) {  # high to low
    my $digit = $digits[$i];
    ### at: "dir=$dir right=$right  digit=$digit"

    if ($digit != $square-1) {   # lowest non-24 digit
      $fracdir = $dir;
    }

    if ($right) {
      $digit = $square-1-$digit;
      ### reverse: "digit=$digit"
    }
    my $x = $digit_to_sx->[$digit];
    my $y = $digit_to_sy->[$digit];
    ### sxy: "$x,$y"
    # if ($right) {
    #   $x = $k-1-$x;
    #   $y = $k-1-$y;
    # }
    if (($dir ^ ($right>>1)) & 2) {
      $x = $k-1-$x;
      $y = $k-1-$y;
    }
    if ($dir & 1) {
      ($x,$y) = ($k-1-$y, $x);
    }
    ### rotate to: "$x,$y"
    $x[$i] = $x;
    $y[$i] = $y;

    my $next = $next_state->[$digit];
    # if ($right) {
    # } else {
    #   $dir += $next & 3;
    # }
    $dir += $next & 3;
    $right ^= $next & 4;
  }
  ### final: "dir=$dir right=$right"

  ### @x
  ### @y
  ### frac: $n
  my $zero = $int * 0;
  return ($n * 0 # ($digit_to_sx->[$dirstate+1] - $digit_to_sx->[$dirstate])
          + digit_join_lowtohigh(\@x, $k, $zero),

          $n * 0 # ($digit_to_sy->[$dirstate+1] - $digit_to_sy->[$dirstate])
          + digit_join_lowtohigh(\@y, $k, $zero));




  {
    my $digit_to_x = $self->{'digit_to_x'};
    if ($n > $#$digit_to_x) {
      return;
    }
    return ($self->{'digit_to_sx'}->[$n],
            $self->{'digit_to_sy'}->[$n]);

  }

  my $turns = $k >> 1;
  my $t1 = $turns + 1;
  my $rot = -$turns;
  my $x = 0;
  my $y = 0;
  my $qx = 0;
  my $qy = 0;

  my $midpoint = $turns*$t1/2 + 1;
  if (($n -= $midpoint) >= 0) {
    ### after middle ...
    return;
  } else {
    # $qx += $dir4_to_dx[(0*$turns+1)&3];
    # $qy += $dir4_to_dy[(0*$turns+1)&3];
    # $qx -= $dir4_to_dy[($turns+2)&3];
    # $qy += $dir4_to_dx[($turns+2)&3];
    # $qy += 1;
    # $x -= 1;
    if ($n += 1) {
      ### before middle ...
      $n = -$n;
      $rot += 2;
      # $y -= 1;
      # $x -= 1;
    } else {
      ### centre segment ...
      $rot += 1;
      # $qy -= $dir4_to_dx[(-$turns)&3];
    }
  }
  ### key n: $n


  my $q = ($turns*$turns-1)/4;
  ### $q

  # d: [ 0, 1,  2 ]
  # n: [ 0, 3, 10 ]
  # d = -1/4 + sqrt(1/2 * $n + 1/16)
  #   = (-1 + sqrt(8*$n + 1)) / 4
  # N = (2*$d + 1)*$d
  # rel = (2*$d + 1)*$d + 2*$d+1
  #     = (2*$d + 3)*$d + 1
  #
  my $d = int( (_sqrtint(8*$n+1) - 1)/4 );
  $n -= (2*$d+3)*$d + 1;
  ### $d
  ### key signed rem: $n

  if ($n < 0) {
    ### key horizontal ...
    $x += $n+$d + 1;
    $y += -$d;
    if ($d % 2) {
      ### key top ...
      $rot += 2;
      $y -= 1;
    } else {
      ### key bottom ...
    }
  } else {
    ### key vertical ...
    $x += -$d - 1;
    $y += $d - $n;
    $rot += 2;
    if ($d % 2) {
      ### key right ...
      $rot += 2;
      $y += 1;
    } else {
      ### key left ...
    }
  }
  ### kxy raw: "$x, $y"



  if ($rot & 2) {
    $x = -$x;
    $y = -$y;
  }
  if ($rot & 1) {
    ($x,$y) = ($y,-$x);
  }
  ### kxy rotated: "$x,$y"

  # if ($k%8==1 && !$before) {
  #   $y += 1;
  # }
  # if ($k%8==3 && !$before) {
  #   $x += 1;
  # }
  # if ($k%8==5 && $before) {
  #   $y += 1;
  # }
  # if ($k%8==7 && $before) {
  #   $x += 1;
  # }

  $x += $qx;
  $y += $qy;
  return ($x,$y);













  # my $q = ($k*$k-1)/4;
  ### $k
  ### $q
  ### $turns

  # if ($n > $q/2) { return (0,0); }

  my $before;

  # $qx += ($k >> 2);
  # $qy += ($k >> 2);

  if ($n > $q/2) {
    return;
  }
  if ($n >= $q+$turns) {
    $n -= $q+$turns;
    $qx += 1;
    $qy += ($k >> 1) + 1;
  }
  if ($n >= $q+$turns-2) {
    $n -= $q+$turns-2;
    $qx += ($k >> 1) + 10;
    $qy += 1;
    $rot++;
  }

  # $x -= $dir4_to_dx[$rot&3];
  # $y += $dir4_to_dy[$rot&3];

}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### SquaRecurve xy_to_n(): "$x, $y"

  return undef;

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

}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  return (0, 25**3);


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

  my $radix = $self->{'k'};

  my ($power, $level) = round_down_pow (max($x2,$y2), $radix);
  if (is_infinite($level)) {
    return (0, $level);
  }
  return (0, $radix*$radix*$power*$power - 1);
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords Ryde OEIS DekkingCurve

=head1 NAME

Math::PlanePath::SquaRecurve -- spiralling self-similar blocks

=head1 SYNOPSIS

 use Math::PlanePath::SquaRecurve;
 my $path = Math::PlanePath::SquaRecurve->new (k => 5);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is the SquaRecurve of

=over

Douglas M. McKenna, 1978, as described in "SquaRecurves, E-Tours, Eddies,
and Frenzies: Basic Families of Peano Curves on the Square Grid", in "The
Lighter Side of Mathematics: Proceedings of the Eugene Strens Memorial
Conference on Recreational Mathematics and its History", Mathematical
Association of America, 1994, pages 49-73, ISBN 0-88385-516-X.

=back

  Peano curve with segments going across unit squares.
Points N are opposite corners of these squares, so all are even points (X+Y
even).

=cut

# generated by:
# math-image --path=SquaRecurve --all --output=numbers --size=20x15

=pod

      9 |      61          63          65          79          81
      8 | 60       58,62       64,68       66,78       76,80
      7 |    55,59       57,69       67,71       73,77       75,87
      6 | 54       52,56       38,70       36,72       34,74
      5 |    49,53       39,51       37,41       31,35       33,129
      4 | 48       46,50       40,44       30,42       28,32
      3 |     7,47        9,45       11,43       25,29       27,135
      2 |  6        4,8        10,14       12,24       22,26
      1 |     1,5         3,15       13,17       19,23       21,141
    Y=0 |  0         2           16          18          20
        +----------------------------------------------------------
       X=0 1    2    3     4     5     6     7     8     9     10

Segments between the initial points can be illustrated,

      |         
      +---- 7,47 ---+---- 9,45 --
      |    ^ | \    |   ^  | \   
      |  /   |  \   |  /   |  v   
      | /    |   v  | /    |  ...
      6 -----+---- 4,8 ----+--
      | ^    |   /  | ^    |
      |   \  |  /   |   \  |
      |    \ | v    |    \ |
      +-----1,5 ----+---- 3,15    
      |   ^  | \    |   ^  |
      |  /   |  \   |  /   |      
      | /    |   v  | /    |      
    N=0------+------2------+--

Segment N=0 to N=1 goes from the origin X=0,Y=0 up to X=1,Y=1, then N=2 is
down again to X=2,Y=0, and so on.  This can be compared to the PeanoCurve
which goes between the middle of each square, so the midpoints of these
segments.

Peano's conception of a space-filling curve is ternary digits of a
fractional f which fills a unit square going from f=0 at X=0,Y=0 up to f=1
at X=1,Y=1.  The integer form here does this with digits above the ternary
point.

=head2 Even Radix

      , -----+--- 14, ---+----- 12, -
      | ^    |   /  | ^    |   /  |
      |   \  |  /   |   \  |  /   |
      |    \ | v    |    \ | v    |
      +---- 9,15 ---+--- 11,13 ---+--
      | ^    |   /  | ^    |   /  |
      |   \  |  /   |   \  |  /   |
      |    \ | v    |    \ | v    |
      +-----1,7 ----+---- 3,5 ----+-- 
      |    ^ | \    |   ^  | \    |              radix => 4
      |  /   |  \   |  /   |  \   |
      | /    |   v  | /    |   v  |
      8 -----+---- 6,10 ---+---- 4, -
      |   ^  | \    |   ^  | \    |
      |  /   |  \   |  /   |  \   |
      | /    |   v  | /    |   v  |
    N=0------+------2------+------+---

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::SquaRecurve-E<gt>new ()>

=item C<$path = Math::PlanePath::SquaRecurve-E<gt>new (radix =E<gt> $r)>

Create and return a new path object.

The optional C<radix> parameter gives the base for digit splitting.  The
default is ternary, C<radix =E<gt> 3>.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=back

=head1 FORMULAS

=head2 N to Turn

The curve turns left or right 90 degrees at each point N E<gt>= 1.  The turn
is 90 degrees 

    turn(N) = 90 degrees * (-1)^(N + number of low ternary 0s of N)
            = -1,1,1,1,-1,-1,-1,1,-1,1,-1,-1,-1,1,1,1,-1,1

=cut

# GP-DEFINE  turn(n) = (-1)^(n + valuation(n,3));
# GP-Test  vector(18,n, turn(n)) == \
# GP-Test    [-1,1, 1, 1,-1, -1, -1,1,-1,1,-1, -1, -1,1,1,1,-1,1]

# not in OEIS: -1,1,1,1,-1,-1,-1,1,-1,1,-1,-1,-1,1,1,1,-1,1
# not in OEIS: 1,-1,-1,-1,1,1,1,-1,1,-1,1,1,1,-1,-1,-1,1,-1  \\ negated
# not in OEIS: 0,1,1,1,0,0,0,1,0,1,0,0,0,1,1,1,0,1,0,1,1,1,0,0,0,1,1,1,0,0  \\  ones
# not in OEIS: 1,0,0,0,1,1,1,0,1,0,1,1,1,0,0,0,1,0  \\ zeros

# GP-Test  vector(900,n, turn(3*n)) == \
# GP-Test  vector(900,n, -turn(n))
# GP-Test  vector(900,n, turn(3*n+1)) == \
# GP-Test  vector(900,n, -(-1)^n)
# GP-Test  vector(900,n, turn(3*n+2)) == \
# GP-Test  vector(900,n, (-1)^n)

# vector(25,n, (-1)^valuation(n,3))
# not in OEIS: 1,1,-1,1,1,-1,1,1,1,1,1,-1,1,1,-1,1,1,1,1,1,-1,1,1,-1,1,1,-1,1
# vector(100,n, valuation(n,3)%2)
# A182581 num ternary low 0s mod 2

=pod

The power of -1 means left or right flip for each low ternary 0 of N, and
flip again if N is odd.  Odd N is an odd number of ternary 1 digits.

This formula follows from the turns in a new low base-9 digit.  The start
and end of the base figure are in the same directions so the turns at 9*N
are unchanged.  Then 9*N+r goes as r in the base figure, but flipped
LE<lt>-E<gt>R when N odd since blocks are mirrored alternately.

    turn(9N)   = turn(N)
    turn(9N+r) = turn(r)*(-1)^N         for  1 <= r <= 8

=cut

# GP-Test  vector(900,n, turn(9*n)) == \
# GP-Test  vector(900,n, turn(n))
# GP-Test  matrix(90,8,n,r, turn(9*n+r)) == \
# GP-Test  matrix(90,8,n,r, turn(r)*(-1)^n)

=pod

Just in terms of base 3, a single new low ternary digit is a transpose of
what's above, and the base figure turns r=1,2 and LE<lt>-E<gt>R when N above
is odd again.

The same for any odd radix.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PeanoCurve>

=over

DOI 10.1007/BF01199438
http://www.springerlink.com/content/w232301n53960133/

=back

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2019, 2020 Kevin Ryde

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
