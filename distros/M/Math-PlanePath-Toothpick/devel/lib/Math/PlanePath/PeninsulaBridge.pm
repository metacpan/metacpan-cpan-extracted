# Copyright 2012, 2013, 2014, 2015 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


# numbering of surrounds?

# bridge cells children of two parent nodes
# graph_n_parent_list()

# A160117 peninsula and bridges surrounding
# A160411 added
#
# A160118 peninsula surrounding from single start cell
# A160415  added
# A160796 peninsula surrounding from single start cell, 3 quadrants
# A160797  added
#
# A188343 one neighbour, then all surrounding, ~/OEIS/a188343.png
#
# A165345 turn ON if 1 or 3 adjacent neighbours
#     http://www.math.vt.edu/people/layman/sequences/A165345.html
#

# 249 373 239 238 237 361 227 226 225 349 215 214 213 337 208
# 248     240 194 236     228 192 224     216 190 212     209
# 147 146 145 241 135 134 133 229 123 122 121 217 116 115 114
# 148 106 144     136 104 132     124 102 120     117 101 113
# 149 150  71  70  69 137  59  58  57 125  52  51  50 118 119
# 255      72  44  68      60  42  56      53  41  49     221
# 153 152  73  74  23  22  21  61  16  15  14  54  55 128 127
# 154 107 151      24  10  20      17   9  13     129 103 126
# 155 156  77  76  25  26   4   3   2  18  19  64  63 130 131
# 261      78  45  75       5   0   1      65  43  62     233
# 159 158  79  80  29  28   6   7   8  36  35  66  67 140 139
# 160 108 157      30  11  27      37  12  34     141 105 138
# 161 162  83  82  31  32  33  89  38  39  40  96  95 142 143
# 267      84  46  81      90  47  88      97  48  94     245
# 165 164  85  86  87 171  91  92  93 177  98  99 100 184 183
# 166 109 163     172 110 170     178 111 176     185 112 182
# 167 168 169 281 173 174 175 287 179 180 181 293 186 187 188
# 273     282 201 280     288 202 286     294 203 292     301
# 279 419 283 284 285 425 289 290 291 431 295 296 297 437 302
# 420 320 418     426 321 424     432 322 430     438 323 436


# ** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *
# ************************************************************
#  *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
# ************************************************************
# ** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *
# ************************************************************
#  *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
# ************************************************************
# ** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *
# ************************************************************
#  *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
# ************************************************************
# ** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *
# ************************************************************
#  *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
# ************************************************************
# ** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *
# ************************************************************
#  *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***

package Math::PlanePath::PeninsulaBridge;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow';
use Math::PlanePath::SquareSpiral;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;

use constant parameter_info_array =>
  [ { name      => 'start',
      share_key => 'start_peninsulabridge',
      display   => 'Start',
      type      => 'enum',
      default   => 'one',
      choices   => ['one',
                    # 'two','three','four'
                   ],
    },
  ];


sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'sq'} = Math::PlanePath::SquareSpiral->new (n_start => 0);

  my $start = ($self->{'start'} ||= 'one');
  my @n_to_x;
  my @n_to_y;
  my @endpoint_dirs;
  if ($start eq 'one') {
    @n_to_x = (0);
    @n_to_y = (0);
    @endpoint_dirs = (2);
  } elsif ($start eq 'two') {
    @n_to_x = (0, -2);
    @n_to_y = (0, 0);
    @endpoint_dirs = (2, 0);
  } elsif ($start eq 'three') {
    @n_to_x = (0, -1, -1);
    @n_to_y = (0, 0, -1);
    @endpoint_dirs = (2, 3, 0);
  } elsif ($start eq 'four') {
    @n_to_x = (0, -1, -1, 0);
    @n_to_y = (0, 0, -1, -1);
    @endpoint_dirs = (2, 3, 0, 1);
  } else {
    croak "Unrecognised start: ",$start;
  }
  $self->{'n_to_x'} = \@n_to_x;
  $self->{'n_to_y'} = \@n_to_y;
  $self->{'depth_to_n'} = [0];

  my @endpoints;
  my @xy_to_n;
  foreach my $n (0 .. $#n_to_x) {
    my $sn = $self->{'sq'}->xy_to_n($n_to_x[$n],$n_to_y[$n]);
    $xy_to_n[$sn] = $n;
    push @endpoints, $sn;
  }
  $self->{'endpoints'} = \@endpoints;
  $self->{'endpoint_dirs'} = \@endpoint_dirs;
  $self->{'xy_to_n'} = \@xy_to_n;
  $self->{'n_to_parent'} = [];
  $self->{'n_to_children'} = [];

  ### xy_to_n: $self->{'xy_to_n'}
  ### endpoints: $self->{'endpoints'}

  return $self;
}

my @surround8_dx = (1, 1, 0, -1, -1, -1,  0,  1);
my @surround8_dy = (0, 1, 1,  1,  0, -1, -1, -1);

sub _extend {
  my ($self) = @_;
  ### _extend() ...

  my $sq = $self->{'sq'};
  my $endpoints = $self->{'endpoints'};
  my $xy_to_n = $self->{'xy_to_n'};
  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};
  my $n_to_parent = $self->{'n_to_parent'};
  my $n_to_children = $self->{'n_to_children'};

  my $depth = scalar(@{$self->{'depth_to_n'}});
  ### $depth
  ### endpoints count: scalar(@$endpoints)

  my @new_endpoints;
  my $n = scalar(@$n_to_x);
  push @{$self->{'depth_to_n'}}, $n;

 ENDPOINT: foreach my $endpoint_sn (@$endpoints) {
    my ($x,$y) = $sq->n_to_xy($endpoint_sn);
    ### endpoint: "$x,$y"

    if ($depth & 1) {
      ### consider all around previous: "$x,$y"
      foreach my $i (0 .. $#surround8_dx) {
        my $x = $x + $surround8_dx[$i];
        my $y = $y + $surround8_dy[$i];
        my $sn = $sq->xy_to_n($x,$y);
        if (! defined $xy_to_n->[$sn]) {
          ### add: "x=$x,y=$y"
          push @new_endpoints, $sn;
          $xy_to_n->[$sn] = $n;
          $n_to_x->[$n] = $x;
          $n_to_y->[$n] = $y;
          my $parent_n = $xy_to_n->[$endpoint_sn];
          $n_to_parent->[$n] = $parent_n;
          push @{$n_to_children->[$parent_n]}, $n;
          $n++;
        }
      }
    } else {
      # cells touching one or two existing
      foreach my $i (0 .. $#surround8_dx) {
        my $x = $x + $surround8_dx[$i];
        my $y = $y + $surround8_dy[$i];
        my $sn = $sq->xy_to_n($x,$y);
        next if defined $xy_to_n->[$sn];
        ### consider p or b surround: "$x,$y"
        if (_xy_is_peninsula($self,$x,$y) || _xy_is_bridge($self,$x,$y)) {
          push @new_endpoints, $sn;
          $xy_to_n->[$sn] = $n;
          $n_to_x->[$n] = $x;
          $n_to_y->[$n] = $y;
          my $parent_n = $xy_to_n->[$endpoint_sn];
          $n_to_parent->[$n] = $parent_n;
          push @{$n_to_children->[$parent_n]}, $n;
          $n++;
        }
      }
    }
  }

  $self->{'endpoints'} = \@new_endpoints;
}

sub _xy_is_peninsula {
  my ($self, $x,$y) = @_;
  my $sq = $self->{'sq'};
  my $xy_to_n = $self->{'xy_to_n'};
  my $count = 0;
  foreach my $j (0 .. $#surround8_dx) {
    my $x = $x + $surround8_dx[$j];
    my $y = $y + $surround8_dy[$j];
    my $sn = $sq->xy_to_n($x,$y);
    if (defined($xy_to_n->[$sn])) {
      if ($count++) {
        ### two or more surround ...
        return 0;
      }
    }
  }
  return 1;
}

sub _xy_is_bridge {
  my ($self, $x,$y) = @_;
  my $sq = $self->{'sq'};
  my $xy_to_n = $self->{'xy_to_n'};
  my $count = 0;
  my $last_j = undef;
  foreach my $j (0 .. $#surround8_dx) {
    my $x = $x + $surround8_dx[$j];
    my $y = $y + $surround8_dy[$j];
    my $sn = $sq->xy_to_n($x,$y);
    if (defined($xy_to_n->[$sn])) {
      $count++;
      if ($count == 1) {
        if (! ($j & 1)) {
          ### not diagonal ...
          return 0;
        }
        $last_j = $j;
      } elsif ($count == 2) {
        unless (($j - $last_j + 2) % 8 == 0 || ($j - $last_j - 2) % 8 == 0) {
          ### not consecutive vertices ...

          return 0;
        }
      } elsif ($count >= 3) {
        ### not bridge, three or more surround ...
        return 0;
      }
    }
  }
  ### yes p or b: "count=$count"
  return 1;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### PeninsulaBridge n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  {
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
    $n = $int;       # BigFloat int() gives BigInt, use that
  }

  while ($#{$self->{'n_to_x'}} < $n) {
    _extend($self);
  }

  ### x: $self->{'n_to_x'}->[$n]
  ### y: $self->{'n_to_y'}->[$n]
  return ($self->{'n_to_x'}->[$n],
          $self->{'n_to_y'}->[$n]);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### PeninsulaBridge xy_to_n(): "$x, $y"

  my ($depth,$exp) = round_down_pow (max($x,$y), 2);
  $depth *= 4;
  if (is_infinite($depth)) {
    return ($depth);
  }

  ### $depth
  for (;;) {
    {
      my $sn = $self->{'sq'}->xy_to_n($x,$y);
      if (defined (my $n = $self->{'xy_to_n'}->[$sn])) {
        return $n;
      }
    }
    if (scalar(@{$self->{'depth_to_n'}}) <= $depth) {
      _extend($self);
    } else {
      return undef;
    }
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### PeninsulaBridge rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  my $depth = 8 * max(1,
                      abs($x1),
                      abs($x2),
                      abs($y1),
                      abs($y2));
  return (0, $depth*$depth);
}

sub tree_depth_to_n {
  my ($self, $depth) = @_;
  if ($depth < 0) {
    return undef;
  }
  if (is_infinite($depth)) {
    return $depth;
  }
  my $depth_to_n = $self->{'depth_to_n'};
  while ($#$depth_to_n <= $depth) {
    _extend($self);
  }
  return $depth_to_n->[$depth];
}
sub tree_n_to_depth {
  my ($self, $n) = @_;

  if ($n < 0) {
    return undef;
  }
  if (is_infinite($n)) {
    return $n;
  }
  my $depth_to_n = $self->{'depth_to_n'};
  for (my $depth = 1; ; $depth++) {
    while ($depth > $#$depth_to_n) {
      _extend($self);
    }
    if ($n < $depth_to_n->[$depth]) {
      return $depth-1;
    }
  }
}

sub tree_n_children {
  my ($self, $n) = @_;
  ### tree_n_children(): $n
  if (is_infinite($n) || $n < 0) {
    return;
  }
  while ($#{$self->{'n_to_x'}} < $n+10) {
    _extend($self);
  }
  return @{$self->{'n_to_children'}->[$n] || []};
}
sub tree_n_parent {
  my ($self, $n) = @_;
  if ($n < 0) {
    return undef;
  }
  if (is_infinite($n)) {
    return $n;
  }
  while ($#{$self->{'n_to_x'}} < $n) {
    _extend($self);
  }
  return $self->{'n_to_parent'}->[$n];
}

1;
__END__
