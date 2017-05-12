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


package Math::PlanePath::WythoffTriangle;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant y_minimum => 1;
use constant xy_is_visited => 1;

use Math::PlanePath::WythoffPreliminaryTriangle;
my $preliminary = Math::PlanePath::WythoffPreliminaryTriangle->new;

sub n_to_xy {
  my ($self, $n) = @_;
  ### WythoffTriangle n_to_xy(): $n

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

  my ($x,$y) = $preliminary->n_to_xy($n) or return;
  $x = 0;
  foreach my $x2 (0 .. $y-1) {
    my $n2 = $preliminary->xy_to_n($x2,$y) or return;
    ### cf: "x2=$x2 n2=$n2"
    if ($n2 < $n) {
      ### is below ...
      $x++;
    }
  }
  return ($x, $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### WythoffTriangle xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($y < 1) { return undef; }
  if (is_infinite($y)) { return $y; }
  unless ($x >= 0 && $x < $y) { return undef; }

  my @n = sort {$a<=>$b}
    map { $preliminary->xy_to_n($_,$y) }
      0 .. $y-1;
  return $n[$x];
}

sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### WythoffTriangle rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  if ($x2 < 0 || $y2 < 1) {
    ### all outside first quadrant ...
    return (1, 0);
  }

  # bottom left into first quadrant
  if ($x1 < 0) { $x1 *= 0; }
  if ($y1 < 0) { $y1 *= 0; }

  return (1,
          $self->xy_to_n(0,2*$y2));
}

1;
__END__

