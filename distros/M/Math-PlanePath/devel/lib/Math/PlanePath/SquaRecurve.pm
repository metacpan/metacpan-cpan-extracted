# Copyright 2016, 2017 Kevin Ryde

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


package Math::PlanePath::SquaRecurve;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;
*_sqrtint = \&Math::PlanePath::_sqrtint;

use vars '$VERSION', '@ISA';
$VERSION = 125;
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

1;
__END__


# https://books.google.com.au/books?id=-4W_5ZISxpsC&pg=PA49
