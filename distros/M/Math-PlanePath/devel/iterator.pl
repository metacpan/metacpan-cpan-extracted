#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;


=over

=item C<($n, $x, $y) = $path-E<gt>next()>
=item C<($n, $x, $y) = $path-E<gt>next_nxy()>

=item C<($n, $x, $y) = $path-E<gt>peek()>

=item C<$path-E<gt>rewind()>

=item C<$path-E<gt>seek_to_n($n)>

=item C<$n = $path-E<gt>tell_n($n)>
=item C<($n,$x,$y) = $path-E<gt>tell_nxy($n)>

=back

=cut


use Math::PlanePath;

{
  package Math::PlanePath;
  no warnings 'redefine';
  sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self->rewind;
    return $self;
  }
  sub rewind {
    my ($self) = @_;
    $self->seek_to_n($self->n_start);
  }
  sub seek_to_n {
    my ($self, $n) = @_;
    $self->{'n'} = $n;
  }
  sub tell_n {
    my ($self, $n) = @_;
    return $self->{'n'};
  }
  sub next_nxy {
    my ($self) = @_;
    my $n = $self->{'n'}++;
    return ($n, $self->n_to_xy($n));
  }
  sub peek_nxy {
    my ($self) = @_;
    my $n = $self->{'n'};
    return ($n, $self->n_to_xy($n));
  }
}

{
  use Math::PlanePath::ZOrderCurve;
  package Math::PlanePath::ZOrderCurve;
  # sub seek_to_n {
  #   my ($self, $n) = @_;
  #   ($self->{'x'},$self->{'y'}) = $self->n_to_xy($self->{'n'} = $n);
  #   $self->{'bx'} = $x;
  #   $self->{'by'} = $y;
  #   $self->{'a'} = [ \$self->{'x'}, \$self->{'y'} ];
  #   $self->{'i'} = 1;
  #   ### ZOrderCurve seek_to_n(): $self
  # }
  # sub next_nxy {
  #   my ($self) = @_;
  #   $self->{'a'}->[($self->{'i'} ^= 1)]++;
  #   return (++$self->{'n'}, $self->{'x'}, $self->{'y'});
  # }
  # sub peek_nxy {
  #   my ($self) = @_;
  #   return ($self->{'n'} + 1,
  #           $self->{'x'} + !$self->{'i'},
  #           $self->{'y'} + $self->{'i'});
  # }
}

{
  use Math::PlanePath::Rows;
  package Math::PlanePath::Rows;
  sub seek_to_n {
    my ($self, $n) = @_;
    $self->{'n'} = --$n;
    my $width = $self->{'width'};
    $self->{'px'} = ($n % $width) - 1;
    $self->{'py'} = int ($n / $width);
    ### seek_to_n: $self
  }
  sub next_nxy {
    my ($self) = @_;
    my $x = ++$self->{'px'};
    if ($x >= $self->{'width'}) {
      $x = $self->{'px'} = 0;
      $self->{'py'}++;
    }
    return (++$self->{'n'}, $x, $self->{'py'});
  }
  sub peek_nxy {
    my ($self) = @_;
    if ((my $x = $self->{'px'} + 1) < $self->{'width'}) {
      return ($self->{'n'}+1, $x, $self->{'py'});
    } else {
      return ($self->{'n'}+1, 0, $self->{'py'}+1);
    }
  }
}
{
  use Math::PlanePath::Diagonals;
  package Math::PlanePath::Diagonals;
  # N = (1/2 d^2 + 1/2 d + 1)
  #   = (1/2*$d**2 + 1/2*$d + 1)
  #   = ((0.5*$d + 0.5)*$d + 1)
  # d = -1/2 + sqrt(2 * $n + -7/4)
  sub seek_to_n {
    my ($self, $n) = @_;
    $self->{'n'} = $n;
    my $d = $self->{'d'} = int (-.5 + sqrt(2*$n - 1.75));
    $n -= $d*($d+1)/2 + 1;
    $self->{'px'} = $n - 1;
    $self->{'py'} = $d - $n + 1;
    ### Diagonals seek_to_n(): $self
  }
  sub next_nxy {
    my ($self) = @_;
    my $x = ++$self->{'px'};
    my $y = --$self->{'py'};
    if ($y < 0) {
      $x = $self->{'px'} = 0;
      $y = $self->{'py'} = ++$self->{'d'};
    }
    return ($self->{'n'}++, $x, $y);
  }
  sub peek_nxy {
    my ($self) = @_;
    if (my $y = $self->{'py'}) {
      return ($self->{'n'}, $self->{'px'}+1, $y-1);
    } else {
      return ($self->{'n'}, 0, $self->{'d'}+1);
    }
  }
}

{
  use Math::PlanePath::SquareSpiral;
  package Math::PlanePath::SquareSpiral;

  sub next_nxy {
    my ($self) = @_;
    ### next(): $self
    my $x = ($self->{'x'} += $self->{'dx'});
    my $y = ($self->{'y'} += $self->{'dy'});

    unless ($self->{'side'}--) {
      ### turn
      ($self->{'dx'},$self->{'dy'}) = (-$self->{'dy'},$self->{'dx'}); # left
      $self->{'side'} = (($self->{'d'} += ($self->{'grow'} ^= 1)) - 1)
        + ($self->{'dx'} && $self->{'wider'});
      ### grow applied: $self->{'grow'}
      ### d now: $self->{'d'}
      ### side now: $self->{'side'}
      ### dx,dy now: "$self->{'dx'},$self->{'dy'}"
    }

    ### return: 'n='.$self->{'n'}.' '.($self->{'x'} + $self->{'dx'}).','.($self->{'y'} + $self->{'dy'})
    return ($self->{'n'}++, $x, $y);
  }
  sub peek_nxy {
    my ($self) = @_;
    # ### peek(): $self
    return ($self->{'n'},
            $self->{'x'} + $self->{'dx'},
            $self->{'y'} + $self->{'dy'});
  }

  # N = (1/2 d^2 + 1/2 d + 1)
  #   = (1/2*$d**2 + 1/2*$d + 1)
  #   = ((0.5*$d + 0.5)*$d + 1)
  # d = -1/2 + sqrt(2 * $n + -7/4)
  sub seek_to_n {
    my ($self, $n) = @_;
    ### SquareSpiral seek_to_n: $n
    $self->{'n'} = $n;

    my $d = $self->{'d'} = int (1/2 + sqrt(1 * $n + -3/4));
    $n -= (($d - 1)*$d + 1);
    ### $d
    ### half d: int($d/2)
    ### remainder: $n

    my $dx;
    my $dy;
    my $y = - int($d/2);
    my $x = $y + $n;
    if ($self->{'grow'} = ($n < $d)) {
      ### horizontal
      $dx = 1;
      $dy = 0;
    } else {
      ### vertical
      $n -= $d;
      $dx = 0;
      $dy = 1;
      ($x, $y) = ($y + $d,
                  $x - $d);
    }

    if ($d & 1) {
    } else {
      ### negate for even d from: "$x,$y"
      $dx = - $dx;
      $dy = - $dy;
      $x = -$x;
      $y = -$y;
    }

    $self->{'side'} = $d - $n;

    $self->{'dx'} = $dx;
    $self->{'dy'} = $dy;
    $self->{'x'} = $x - $dx;
    $self->{'y'} = $y - $dy;


    # if ($n == 3) {
    #   $self->{'side'} = 2;
    #   $self->{'grow'} = 1;
    #   $self->{'d'} = 2;
    #   $self->{'dx'} = -1;
    #   $self->{'dy'} = 0;
    #   $self->{'x'} = 2;
    #   $self->{'y'} = 1;
    #   return;
    # }
    #
    # $self->{'n'} = $n;
    # $self->{'side'} = 1;
    # $self->{'grow'} = 0;
    # $self->{'d'} = 0;
    # $self->{'dx'} = 1;
    # $self->{'dy'} = 0;
    # $self->{'x'} = -1;
    # $self->{'y'} = 0;
    ### SquareSpiral seek_to_n(): $self
  }
}

use Smart::Comments;

foreach my $class ('Math::PlanePath::SquareSpiral',
                   'Math::PlanePath::Diagonals',
                   'Math::PlanePath::Rows',
                  ) {
  my $path = $class->new (width => 5);
  foreach my $n_start_offset (0 .. 30) {
    my $want_n = $path->n_start;
    if ($n_start_offset) {
      $want_n += $n_start_offset;
      $path->seek_to_n ($want_n);
    }
    ### $class
    ### $n_start_offset
    foreach my $i (0 .. 100) {
      my ($peek_n, $peek_x, $peek_y) = $path->peek;
      my ($got_n, $got_x, $got_y) = $path->next;
      my ($want_x, $want_y) = $path->n_to_xy($want_n);

      if ($want_n != $got_n) {
        ### $want_n
        ### $got_n
        die "x";
      }
      if ($want_x != $got_x) {
        ### $want_n
        ### $want_x
        ### $got_x
        die "x";
      }
      if ($want_y != $got_y) {
        ### $want_n
        ### $want_y
        ### $got_y
        die "x";
      }

      if ($peek_n != $want_n) {
        ### $peek_n
        ### $want_n
        die "x";
      }
      if ($peek_x != $want_x) {
        ### $want_n
        ### $peek_x
        ### $want_x
        die "x";
      }
      if ($peek_y != $want_y) {
        ### $want_n
        ### $peek_y
        ### $want_y
        die "x";
      }

      $want_n++;
    }
  }
}
