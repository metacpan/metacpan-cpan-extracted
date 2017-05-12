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


# '1side' without log2 on lower side, is lower quad of 3mid
# '1side_up' mirror image, is upper quad of 3mid
# '1side with log2 from X=3*2^k,Y=2^k down, and middle of 3side


package Math::PlanePath::OneOfEight;
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
use Math::PlanePath::Base::Digits 119 # v.119 for round_up_pow()
  'round_up_pow',
  'round_down_pow';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array =>
  [{ name            => 'parts',
     share_key       => 'parts_oneofeight',
     display         => 'Parts',
     type            => 'enum',
     default         => '4',
     choices         => ['4','1','octant','octant_up','wedge','3mid', '3side',
                         # 'side'
                        ],
     choices_display => ['4','1','Octant','Octant Up','Wedge','3 Mid','3 Side',
                         # 'Side'
                        ],
     description     => 'Which parts of the plane to fill.',
   },
  ];
use constant class_x_negative => 1;
use constant class_y_negative => 1;

{
  my %x_negative = (4         => 1,
                    1         => 0,
                    octant    => 0,
                    octant_up => 0,
                    wedge     => 1,
                    '3mid'    => 1,
                    '3side'   => 1,
                    side      => 0,
                   );
  sub x_negative {
    my ($self) = @_;
    return $x_negative{$self->{'parts'}};
  }
}
{
  my %y_negative = (4         => 1,
                    1         => 0,
                    octant    => 0,
                    octant_up => 0,
                    wedge     => 0,
                    '3mid'    => 1,
                    '3side'   => 1,
                    side      => 0,
                   );
  sub y_negative {
    my ($self) = @_;
    return $y_negative{$self->{'parts'}};
  }
}
{
  my %y_minimum = (# 4         => undef,
                   1         => 0,
                   octant    => 0,
                   octant_up => 0,
                   wedge     => 0,
                   # '3mid'    => undef,
                   # '3side'   => undef,
                   side      => 1,
                  );
  sub y_minimum {
    my ($self) = @_;
    return $y_minimum{$self->{'parts'}};
  }
}

{
  my %x_negative_at_n = (4         => 4,
                         1         => undef,
                         octant    => undef,
                         octant_up => undef,
                         wedge     => 3,
                         '3mid'    => 5,
                         '3side'   => 15,
                         side      => undef,
                        );
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n{$self->{'parts'}};
  }
}
{
  my %y_negative_at_n = (4         => 6,
                         1         => undef,
                         octant    => undef,
                         octant_up => undef,
                         wedge     => undef,
                         '3mid'    => 1,
                         '3side'   => 1,
                         side      => undef,
                        );
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n{$self->{'parts'}};
  }
}

{
  my %sumxy_minimum = (1         => 0,
                       octant    => 0,
                       octant_up => 0,
                       wedge     => 0,  # X>=-Y so X+Y>=0
                      );
  sub sumxy_minimum {
    my ($self) = @_;
    return $sumxy_minimum{$self->{'parts'}};
  }
}
{
  my %diffxy_minimum = (octant => 0,  # Y<=X so X-Y>=0
                       );
  sub diffxy_minimum {
    my ($self) = @_;
    return $diffxy_minimum{$self->{'parts'}};
  }
}
{
  my %diffxy_maximum = (octant_up => 0,  # X<=Y so X+Y<=0
                        wedge     => 0,  # X<=Y so X+Y<=0
                       );
  sub diffxy_maximum {
    my ($self) = @_;
    return $diffxy_maximum{$self->{'parts'}};
  }
}

{
  my %_UNDOCUMENTED__turn_any_right_at_n
    = (4         => 32,
       1         => 3,
       octant    => 2,
       octant_up => 2,
       wedge     => 3,
       '3mid'    => 29,
       '3side'   => 26,
      );
  sub _UNDOCUMENTED__turn_any_right_at_n {
    my ($self) = @_;
    return $_UNDOCUMENTED__turn_any_right_at_n{$self->{'parts'}};
  }
}

# parts=1,3mid dx=2*2^k-3 dy=-2^k, it seems
# parts=3side  dx=2*2^k-5 dy=-2^k-2, it seems
my %dir_maximum_dxdy
  = (4         => [0,-1], # South
     1         => [2,-1], # ESE, supremum
     octant    => [1,-1], # South-East
     octant_up => [0,-1], # N=12 South
     wedge     => [0,-1], # South
     '3mid'    => [2,-1], # ESE, supremum
     '3side'   => [2,-1], # ESE, supremum
    );
sub dir_maximum_dxdy {
  my ($self) = @_;
  return @{$dir_maximum_dxdy{$self->{'parts'}}};
}

{
  my %tree_num_children_list = (4         => [ 0, 1, 2, 3, 5, 8 ],
                                1         => [ 0, 1, 2, 3, 5    ],
                                octant    => [ 0, 1, 2, 3       ],
                                octant_up => [ 0, 1, 2, 3       ],
                                wedge     => [ 0, 1, 2, 3       ],
                                '3mid'    => [ 0, 1, 2, 3, 5    ],
                                '3side'   => [ 0,    2, 3       ],
                                side      => [ 0,    2, 3       ],
                               );
  sub tree_num_children_list {
    my ($self) = @_;
    return @{$tree_num_children_list{$self->{'parts'}}};
  }
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  my $parts = ($self->{'parts'} ||= '4');
  if (! exists $dir_maximum_dxdy{$parts}) {
    croak "Unrecognised parts: ",$parts;
  }
  return $self;
}


#------------------------------------------------------------------------------
# n_to_xy()

my %initial_n_to_xy
  = (4         => [ [0,0], [1,0], [1,1], [0,1],
                    [-1,1], [-1,0], [-1,-1], [0,-1], [1,-1] ],
     1         => [ [0,0], [1,0], [1,1], [0,1] ],
     octant    => [ [0,0], [1,0], [1,1] ],
     octant_up => [ [0,0], [1,1], [0,1] ],
     wedge     => [ [0,0], [1,1], [0,1], [-1,1] ],
     '3mid'    => [ [0,0], [1,-1], [1,0], [1,1],
                    [0,1], [-1,1] ],

     # for 3side table up to N=8 because cell X=1,Y=2 at N=7
     # is overlapped by two upper octants
     '3side'   => [ [0,0], [1,-1], [1,0], [1,1],
                    [1,-2], [2,-2], [2,2], [1,2], [0,2] ],

     side      => [ [0,0], [1,0], [1,1], [2,2], [1,2] ],
    );

#                     depth=0    1      2    3
my @octant_small_n_to_v = ([0], [0,1], [2], [1,2,3]);
my @octant_mid_n_to_v   = ([0], [-1,0,1]);

sub n_to_xy {
  my ($self, $n) = @_;
  ### OneOfEight n_to_xy(): $n

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
  my $zero = $n*0;

  my $parts = $self->{'parts'};
  {
    my $initial = $initial_n_to_xy{$parts};
    if ($n <= $#$initial) {
      ### initial_n_to_xy{}: $initial->[$n]
      return @{$initial->[$n]};
    }
  }

  (my $depth, $n) = _n0_to_depth_and_rem($self, $n);
  ### $depth
  ### remainder n: $n
  ### cf this depth n: $self->tree_depth_to_n($depth)
  ### cf next depth n: $self->tree_depth_to_n($depth+1)

  # $hdx,$hdy is the dx,dy offsets which is "horizontal".  Initially this is
  # hdx=1,hdy=0 so horizontal along the X axis, but subsequent blocks rotate
  # around or mirror to point other directions.
  #
  # $vdx,$vdy is similar dx,dy which is "vertical".  Initially vdx=0,vdy=1
  # so vertical along the Y axis.
  #
  # $mirror is true if in a "mirror image" such as upper octant 0<=X<=Y
  # portion of the pattern.  The difference is that $mirror false has points
  # numbered anti-clockwise "upwards" from the ragged edge towards the
  # diagonal, but when $mirror is true instead clockwise "down" from the
  # diagonal towards the ragged edge.
  #
  # When $mirror is true the octant generated is still reckoned as 0<=Y<=X,
  # but the $hdx,$hdy and $vdx,$vdy are suitably mangled so that this
  # logical first octant ends up in whatever target is desired.  For example
  # the 0<=X<=Y second octant of the pattern starts with hdx=0,hdy=1 and
  # vdx=1,vdy=0, so the "horizontal" is upwards and the "vertical" is to the
  # right.
  #
  # $log2_extras is true if the extra cell at the log2 positions
  # X=3,7,15,31,etc and Y=1 should be included in the pattern.  Initially
  # true, but later in the "lower" block there are no such extra cells.
  #
  # $top_no_extra_pow is a 2^k power if the top of the diagonal at
  # X=pow-1,Y=pow-1 should not be included in the pattern.  Or 0 if this
  # diagonal cell should be included.  Initially true, but later going
  # "lower" followed by "upper" it's the end of the diagonal is not wanted.
  # The first such is at X=8,Y=2 which should not be in the "upper"
  # (mirrored) diagonal coming from X=11,Y=5.  In general if $log2_extras is
  # false then $top_no_extra_pow excludes that log2 cell when going to the
  # "upper" block.
  #
  my $x = 0;
  my $y = 0;
  my $hdx = 1;
  my $hdy = 0;
  my $vdx = 0;
  my $vdy = 1;
  my $mirror = 0;        # plain
  my $log2_extras = 1;   # include cells X=3,7,15,31;Y=1 etc
  my $top_no_extra_pow = 0;

  if ($parts eq 'octant') {
    ### parts=octant ...

  } elsif ($parts eq 'octant_up') {
    ### parts=octant_up ...
    $hdx = 0;
    $hdy = 1;
    $vdx = 1;
    $vdy = 0;
    $mirror = 1;

  } elsif ($parts eq 'wedge') {
    ### parts=wedge ...
    my $add = _depth_to_octant_added([$depth],[1],$zero);
    if ($n < $add) {
      $hdx = 0;  # same as octant_up
      $hdy = 1;
      $vdx = 1;
      $vdy = 0;
      $mirror = 1;
    } else {
      $n -= $add;
      $hdx = 0;  # rotate +90
      $hdy = 1;
      $vdx = -1;
      $vdy = 0;
    }

  } elsif ($parts eq '1' || $parts eq '2' || $parts eq '4') {
    my $add = _depth_to_octant_added([$depth],[1],$zero);
    ### octant add: $add

    if ($parts eq '4') {
      # Half-plane is 4 octants, less 2 for duplicate diagonal.
      my $hadd = 4*$add-2;
      if ($n >= $hadd) {
        ### initial rotate 180 ...
        $n -= $hadd;
        $hdx = -1;
        $vdy = -1;
      }
    }
    if ($parts eq '2' || $parts eq '4') {
      # Each quadrant is 2 octants, less 1 for duplicate diagonal.
      my $qadd = 2*$add-1;
      if ($n >= $qadd) {
        ### initial rotate +90 ...
        $n -= $qadd;
        ($hdx,$hdy) = (-$hdy,$hdx);
        ($vdx,$vdy) = (-$vdy,$vdx);
      }
    }
    if ($n >= $add) {
      ### initial mirror ...
      $mirror = 1;
      ($hdx,$hdy, $vdx,$vdy)     # mirror by transpose
        = ($vdx,$vdy, $hdx,$hdy);
      $n -= $add;
      $n += 1; # excluding diagonal
    }

  } elsif ($parts eq '3mid') {
    my $add = _depth_to_octant_added([$depth+1],[1],$zero)
      - (_is_pow2($depth+2) ? 2 : 1);
    ### lower of side 1, excluding diagonal: "depth=".($depth+1)." add=".$add
    if ($n < $add) {
      ### lower of side 1 ...
      $hdx = 0; $hdy = -1; $vdx = 1; $vdy = 0;
      $log2_extras = 0;
      $depth += 1;
      $x = -1; $y = 1;
    } else {
      $n -= $add;
      ### past side 1 lower, not past diagonal: "n=$n"

      $add = _depth_to_octant_added([$depth],[1],$zero);
      if ($n < $add) {
        ### upper of side 1 ...
        $vdy = -1;
        $mirror = 1;
      } else {
        $n -= $add;

        if ($n < $add) {
          ### lower of centre ...
        } else {
          $n -= $add;
          $n += 1;  # past diagonal

          if ($n < $add) {
            ### upper of centre ...
            $hdx = 0;
            $hdy = 1;
            $vdx = 1;
            $vdy = 0;
            $mirror = 1;
          } else {
            $n -= $add;

            if ($n < $add) {
              ### upper of side 3 ...
              $hdx = 0;
              $hdy = 1;
              $vdx = -1;
              $vdy = 0;
            } else {
              $n -= $add;
              $n += 1;  # past diagonal

              ### lower of side 3 ...
              $hdx = -1;
              $depth += 1;
              $x = 1; $y = -1;
              $log2_extras = 0;
              $mirror =1;
            }
          }
        }
      }
    }

  } elsif ($parts eq '3side') {
    my $add = (_depth_to_octant_added([$depth+1],[1],$zero)
               - (_is_pow2($depth+2) ? 2 : 1));
    ### lower of side 1, excluding diagonal: "depth=".($depth+1)." add=".$add
    if ($n < $add) {
      ### lower of side 1 ...
      $hdx = 0;
      $hdy = -1;
      $vdx = 1;
      $vdy = 0;
      $log2_extras = 0;
      $depth += 1;
      $x = -1; $y = 1;
    } else {
      $n -= $add;

      $add = _depth_to_octant_added([$depth],[1],$zero);
      ### plain add, including diagonal: "add=$add  cf n=$n"
      if ($n < $add) {
        ### upper of side 1 ...
        $vdy = -1;
        $mirror = 1;
      } else {
        $n -= $add;
        ### not upper of side 1, leaving n: $n

        if ($n < $add) {
          ### lower of centre, including diagonal ...
        } else {
          $n -= $add;
          $n += 1;  # past diagonal
          ### not lower of centre, and past diagonal to n: $n

          $add = _depth_to_octant_added([$depth-1],[1],$zero);
          ### upper of centre, excluding diagonal: "depth=".($depth-1)." add-1=".$add
          if ($n < $add) {
            ### upper of centre ...
            $hdx = 0; $hdy = 1; $vdx = 1; $vdy = 0;
            $x = 1; $y = 1;
            $mirror = 1;
            $depth -= 1;
          } else {
            $n -= $add;
            ### not upper of centre, to n: $n

            if ($n < $add) {
              ### upper of side 3 ...
              $hdx = 0; $hdy = 1; $vdx = -1; $vdy = 0; # rotate -90
              $x = 1; $y = 1;
              $depth -= 1;
            } else {
              $n -= $add;
              $n += 1;  # past diagonal
              ### not upper of side 3, and past diagonal to n: $n

              ### lower of side 3 ...
              $hdx = -1;
              $x = 2;
              $log2_extras = 0;
              $mirror =1;
            }
          }
        }
      }
    }

  } elsif ($parts eq 'side') {
    my $add = _depth_to_octant_added([$depth],[1],$zero);
    ### first octant add: $add
    if ($n < $add) {
      ### first octant ...
    } else {
      ### second octant ...
      $n -= $add;
      $n += 1; # past diagonal
      $hdx = 0; $hdy = 1; $vdx = 1; $vdy = 0;
      $depth += 1;
      $log2_extras = 0;
      $mirror = 1;
      $x = -1; $y = -1;
    }
  }

  ### adjusted to octant style: "depth=$depth remainder n=$n"

  my ($pow,$exp) = round_down_pow ($depth+1, 2);
  ### initial exp: $exp
  ### initial pow: $pow

  for ( ; $exp >= 0; $pow/=2, $exp--) {
    ### at: "pow=$pow exp=$exp depth=$depth n=$n mirror=$mirror log2extras=$log2_extras topnopow=$top_no_extra_pow  xy=$x,$y  h=$hdx,$hdy v=$vdx,$vdy"
    ### assert: $depth >= 1
    ### assert: $mirror == 0 || $mirror == 1

    if ($depth < $pow) {
      ### block 0 ...
      $top_no_extra_pow = 0;
      next;
    }

    if ($depth <= 3) {
      if ($mirror) {
        ### mirror small depth ...
        if ($depth == $top_no_extra_pow-1) {
          $n += 1;
          ### inc n for top_no_extra_pow: "to n=$n"
        }
        ### assert: $n <= $#{$octant_small_n_to_v[$depth]}
        $n = -1-$n;  # perl negative index to read array in reverse
      } else {
        ### small depth ...
        if (! $log2_extras && $depth == 3) {
          $n += 1;
          ### inc n for no log2_extras: "to n=$n"
        }
        ### assert: $n <= $#{$octant_small_n_to_v[$depth]}
      }
      my $v = $octant_small_n_to_v[$depth][$n];
      ### hv: "h=$depth, v=$v"
      $x += $depth*$hdx + $v*$vdx;     # $depth is "$h" horizontal position
      $y += $depth*$hdy + $v*$vdy;
      last;
    }

    $x += $pow * ($hdx + $vdx);   # $pow along diagonal
    $y += $pow * ($hdy + $vdy);
    $depth -= $pow;
    ### diagonal to: "depth=$depth  xy=$x,$y"

    if ($depth <= 1) {
      ### mid two levels ...
      if ($mirror) {
        ### negative perl array index to reverse for mirror state ...
        $n = -1-$n;
      }
      my $v = $octant_mid_n_to_v[$depth][$n];
      ### hv: "h=$depth v=$v"
      $x += $depth*$hdx + $v*$vdx;   # $depth is "$h" horizontal position
      $y += $depth*$hdy + $v*$vdy;
      last;
    }

    if ($mirror == 0) { # plain

      # See if $n within lower.
      # Not at depth+1==pow since lower has already finished then.
      #
      if ($depth+1 < $pow) {
        my $add = _depth_to_octant_added([$depth+1],[1],$zero);
        if (_is_pow2($depth+2)) {
          ### add lower decreased for remaining depth+2 a power-of-2 ...
          $add -= 1;
        }
        $add -= 1;
        ### add in lower, excluding diagonal: $add
        if ($n < $add) {
          ### lower, rotate +90 ...
          $top_no_extra_pow = 0;
          $log2_extras = 0;
          $depth += 1;
          ### assert: $depth < $pow
          ($hdx,$hdy, $vdx,$vdy)    # rotate 90 in direction v toward h
            = (-$vdx,-$vdy, $hdx,$hdy);
          $x -= $hdx + $vdx;
          $y -= $hdy + $vdy;
          next;
        }
        $n -= $add;
      } else {
        ### skip lower at depth==pow-1 ...
      }

      # See if $n within upper.
      #
      my $add = _depth_to_octant_added([$depth],[1],$zero);
      if (! $log2_extras && $depth+1 == $pow) {
        ### add upper decreased for no log2_extras at depth=pow-1 ...
        $add -= 1;
      }
      ### add in upper, including diagonal: $add
      if ($n < $add) {
        ### upper, mirror ...
        $mirror = 1;
        $vdx = -$vdx;  # flip vertically
        $vdy = -$vdy;
        $top_no_extra_pow = ($log2_extras ? 0 : $pow);
        $log2_extras = 1;
        next;
      }
      $n -= $add;
      ### assert: $n < $add

      # Otherwise $n is within extend.
      #
      ### extend ...
      $top_no_extra_pow /= 2;
      $log2_extras = 1;

    } else {
      # $mirror == 1, mirrored

      # See if $n within extend.
      #
      my $eadd = my $add = _depth_to_octant_added([$depth],[1],$zero);
      $top_no_extra_pow /= 2;  # since after $depth+=$pow
      if ($depth == $top_no_extra_pow - 1) {
        ### add extend decreased for no top extra ...
        $eadd -= 1;
      }
      ### add in extend: $eadd
      if ($n < $eadd) {
        ### extend ...
        $log2_extras = 1;
        next;
      }
      $n -= $eadd;

      # See if $n within upper.
      #
      ### add in upper, including diagonal: "$add cf n=$n"
      if ($n < $add) {
        ### upper, unmirror ...
        $top_no_extra_pow = ($log2_extras ? 0 : $pow);
        $log2_extras = 1;
        $mirror = 0;
        $vdx = -$vdx;  # flip vertically
        $vdy = -$vdy;
        next;
      }
      $n -= $add;

      # Otherwise $n is within lower.
      #
      $n += 1; # past diagonal
      ### lower, rotate: "n=$n"
      ### assert: $n < _depth_to_octant_added([$depth+1],[1],$zero)
      $top_no_extra_pow = 0;
      $log2_extras = 0;
      $depth += 1;
      ### assert: $depth < $pow
      ($hdx,$hdy, $vdx,$vdy)    # rotate 90 in direction v toward h
        = (-$vdx,-$vdy, $hdx,$hdy);
      $x -= $hdx + $vdx;
      $y -= $vdx + $vdy;
    }
  }

  ### n_to_xy() return: "$x,$y  (depth=$depth n=$n)"
  return ($x,$y);
}

# ($depth, $nrem) = _n0_to_depth_and_rem($self,$n)
#
# _n0_to_depth_and_rem() finds the tree $depth level containing $n and
# returns that $depth and the offset of $n into that level, being
# $n - $self->tree_depth_to_n($depth).
#
# The current approach is a binary search for the bits of depth which have
# tree_depth_to_n($depth) <= $n.
#
# Ndepth grows as roughly depth*depth, so this is about log4(N) many bsearch
# compares.  Maybe for modest N a table of depth->N could be used for the
# search (and for tree_depth_to_n()).  It would cover up to about sqrt(N),
# so for large N would still need some searching code.
#
# quadrant(2^k) = (4*4^k + 6*k + 14) / 9
# N*9/4 = 4^k + 6/4*k + 14/4
# parts=1      N*9 to round up to next power
# parts=octant N*18
# parts=4      N*9/4 = N*3 as estimate
# parts=3      N*9/4 = N*3 too
#
my %parts_to_depth_multiplier = (4         => 3,
                                 1         => 9,
                                 octant    => 18,
                                 octant_up => 18,
                                 wedge     => 9,
                                 '3mid'    => 3,
                                 '3side'   => 3,
                                 side      => 9,
                                );
sub _n0_to_depth_and_rem {
  my ($self, $n) = @_;
  ### _n0_to_depth_and_rem(): "n=$n   parts=$self->{'parts'}"

  my ($pow,$exp) = round_down_pow
    ($n * $parts_to_depth_multiplier{$self->{'parts'}},
     4);
  if (is_infinite($exp)) {
    return ($exp,0);
  }
  ### $pow
  ### $exp

  my $depth = 0;
  my $n_depth = 0;
  $pow = 2 ** $exp;  # pow=2^exp down to 1, inclusive

  while ($exp-- >= 0) {
    my $try_depth = $depth + $pow;
    my $try_n_depth = $self->tree_depth_to_n($try_depth);

    ### $depth
    ### $pow
    ### $try_depth
    ### $try_n_depth

    if ($try_n_depth <= $n) {
      ### use this tried depth ...
      $depth = $try_depth;
      $n_depth = $try_n_depth;
    }
    $pow /= 2;
  }

  ### _n0_to_depth_and_rem() final ...
  ### $depth
  ### remainder: $n - $n_depth

  return ($depth, $n - $n_depth);
}

#------------------------------------------------------------------------------
# xy_to_n()

my @yxoct_to_n = ([     0, 1 ],   # Y=0
                  [ undef, 2 ]);  # Y=1
my @yxoctup_to_n = ([ 0, undef ], # Y=0
                    [ 2, 1 ]);    # Y=1
my @yxwedge_to_n = ([ 0, undef, undef ], # Y=0   X=0,1,-1
                    [ 2, 1, 3 ]);        # Y=1
my @yx1_to_n = ([ 0, 1 ],   # Y=0
                [ 3, 2 ]);  # Y=1
my @yx3_to_n = ([     0, 2, undef ],   # Y=0   X=0,1,-1
                [     4, 3,     5 ],   # Y=1
                [ undef, 1, undef ]);  # Y=-1
my @yx4_to_n = ([ 0, 1, 5 ],   # Y=0   X=0,1,-1
                [ 3, 2, 4 ],   # Y=1
                [ 7, 8, 6 ]);  # Y=-1
my @yx3mid_to_n = ([     0, 2, undef ],   # Y=0   X=0,1,-1
                   [     4, 3, 5     ],   # Y=1
                   [ undef, 1, undef ]);  # Y=-1
my @yx3side_to_n = ([     0, 2, undef ],   # Y=0   X=0,1,-1
                    [ undef, 3, undef ],   # Y=1
                    [     8, 7, 16    ],   # Y=2
                    [ undef, 4, undef ],   # Y=-2
                    [ undef, 1, undef ]);  # Y=-1
my @yxside_to_n = ([     0, 1 ],   # Y=0   X=0,1,-1
                   [ undef, 2 ]);   # Y=1

# N values relative to tree_depth_to_n() start of the depth level
my @yx_to_n = ([ [     0,     0,          ],  # plain
                 [ undef,     1, undef, 0 ],
                 [ undef, undef,     0, 1 ],
                 [ undef, undef, undef, 2 ] ],
               [ [     0,     1,          ],  # mirror
                 [ undef,     0, undef, 2 ],
                 [ undef, undef,     0, 1 ],
                 [ undef, undef, undef, 0 ] ]);

#use Smart::Comments;

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### OneOfEight xy_to_n(): "$x, $y"

  # {
  #   require Math::PlanePath::OneOfEightByCells;
  #   my $cells = ($self->{'cells'} ||= Math::PlanePath::OneOfEightByCells->new (parts => $self->{'parts'}));
  #   return $cells->xy_to_n($x,$y);
  # }

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if (is_infinite($x)) {
    return $x;
  }
  if (is_infinite($y)) {
    return $y;
  }

  my ($pow,$exp) = round_down_pow (max(abs($x),abs($y))+2, 2);
  ### initial pow: "exp=$exp  pow=$pow"
  ### from abs(x): abs($x)
  ### from abs(y): abs($y)
  ### from max: max(abs($x),abs($y))

  if (is_infinite($exp)) {
    return $exp;
  }

  my $zero = $x * 0 * $y;
  my @add_offset;
  my @add_mult;
  my @add_log2_extras;
  my @add_top_no_extra_pow;
  my $mirror = 0;
  my $log2_extras = 1;
  my $top_extra = 1;
  my $top_no_extra_pow = 0;
  my $depth = 0;
  my $n = $zero;

  my $parts = $self->{'parts'};
  if ($parts eq 'octant') {
    ### parts==octant ...
    if ($y < 0 || $y > $x) {
      return undef;
    }
    if ($x <= 1 && $y <= 1) {
      return $yxoct_to_n[$y][$x];
    }

  } elsif ($parts eq 'octant_up') {
    ### parts==octant_up ...
    if ($x < 0 || $x > $y) {
      ### outside upper octant ...
      return undef;
    }
    if ($x <= 1 && $y <= 1) {
      ### yxoctup_to_n[] table ...
      return $yxoctup_to_n[$y][$x];
    }
    # transpose and mirror
    ($x,$y) = ($y,$x);
    $mirror = 1;

  } elsif ($parts eq 'wedge') {
    ### parts==wedge ...
    if ($x > $y || $x < -$y) {
      return undef;
    }
    if (abs($x) <= 1 && $y <= 1) {
      return $yxwedge_to_n[$y][$x];
    }
    if ($x >= 0) {
      ($x,$y) = ($y,$x);   # transpose and mirror
      $mirror = 1;
    } else {
      ($x,$y) = ($y,-$x);  # rotate -90
      push @add_offset,           0;
      push @add_mult,             1;
      push @add_top_no_extra_pow, 0;
      push @add_log2_extras,      1;
    }

  } elsif ($parts eq '1' || $parts eq '4') {
    my $mult = 0;
    if ($parts eq '1') {
      ### parts==1 ...
      if ($x < 0 || $y < 0) {
        return undef;
      }
      if ($x <= 1 && $y <= 1) {
        return $yx1_to_n[$y][$x];
      }
    } else {
      ### parts==4 ...
      if (abs($x) <= 1 && abs($y) <= 1) {
        return $yx4_to_n[$y][$x];
      }
      if ($y < 0) {
        ### quad 3 or 4, rotate 180 ...
        $mult = 4;  # past first,second quads
        $n -= 2;    # unduplicate diagonals
        $x = -$x;  # rotate 180
        $y = -$y;
      }
      if ($x < 0) {
        ### quad 2 (or 4), rotate 90 ...
        $mult += 2;
        $n -= 1;  # unduplicate diagonal
        ($x,$y) = ($y,-$x);  # rotate -90
      }
    }

    ### now in first quadrant: "x=$x y=$y"
    if ($y > $x) {
      ### second octant, transpose and mirror ...
      ($x,$y) = ($y,$x);
      $mult++;
      $n -= 1;  # unduplicate diagonal
      $mirror = 1;
    }
    if ($mult) {
      push @add_offset,           0;
      push @add_mult,             $mult;
      push @add_top_no_extra_pow, 0;
      push @add_log2_extras,      1;
    }

  } elsif ($parts eq '3mid') {
    ### parts==3mid ...
    if (abs($x) <= 1 && abs($y) <= 1) {
      ### 3mid small: $yx3mid_to_n[$y][$x]
      return $yx3mid_to_n[$y][$x];
    }
    if ($y < 0) {
      if ($x < 0) {
        ### third quadrant, no such point ...
        return undef;
      }
      $y = -$y;
      if ($y >= $x) {
        ### block 0 lower ...
        $log2_extras = 0;
        ($x,$y) = ($y+1,$x+1);
        $depth = -1;
      } else {
        ### block 1 upper ...
        $mirror = 1;

        ### past block 0 lower, excluding diagonal ...
        push @add_offset,          -1;
        push @add_mult,             1;
        push @add_top_no_extra_pow, 0;
        push @add_log2_extras,      0;
        $n -= 1;  # excluding diagonal
      }
    } else {
      if ($x >= 0) {
        if ($y <= $x) {
          ### block 2 first octant ...

          ### past block 0 lower, excluding diagonal ...
          push @add_offset,          -1;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      0;
          $n -= 1;  # excluding diagonal

          ### past block 1 ...
          push @add_offset,           0;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;

        } else {
          ### block 3 second octant ...
          ($x,$y) = ($y,$x);
          $mirror = 1;

          ### past block 0 lower, excluding diagonal ...
          push @add_offset,          -1;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      0;
          $n -= 1;  # excluding diagonal

          ### past blocks 1,2, excluding leading diagonal ...
          push @add_offset,           0;
          push @add_mult,             2;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;
          $n -= 1;  # excluding leading diagonal
        }
      } else {
        ### second quadrant ...
        $x = -$x;
        if ($y >= $x) {
          ### block 4 third octant ...
          ($x,$y) = ($y,$x);

          ### past block 0 lower, excluding diagonal ...
          push @add_offset,          -1;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      0;
          $n -= 1;  # excluding diagonal

          ### past blocks 1,2,3 excluding leading diagonal ...
          push @add_offset,           0;
          push @add_mult,             3;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;
          $n -= 1;  # excluding leading diagonal

        } else {
          ### block 5 fourth octant ...
          $x += 1; $y += 1;
          $mirror = 1;
          $depth = -1;
          $log2_extras = 0;

          ### past block 0 lower, excluding diagonal ...
          push @add_offset,          -1;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      0;
          $n -= 1;  # excluding diagonal

          push @add_offset,           0;
          push @add_mult,             4;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;
          $n -= 2;  # unduplicate two diagonals
        }
      }
    }

  } elsif ($parts eq '3side') {
    ### parts==3side ...
    if (abs($x) <= 1 && abs($y) <= 2) {
      ### 3side small: $yx3side_to_n[$y][$x]
      return $yx3side_to_n[$y][$x];
    }
    if ($y < 0) {
      if ($x < 0) {
        ### third quadrant, no such point ...
        return undef;
      }
      $y = -$y;
      if ($y >= $x) {
        ### block 0 lower ...
        $log2_extras = 0;
        ($x,$y) = ($y+1,$x+1);
        $depth = -1;
      } else {
        ### block 1 upper ...
        $mirror = 1;

        ### past block 0 lower, excluding diagonal ...
        push @add_offset,          -1;
        push @add_mult,             1;
        push @add_top_no_extra_pow, 0;
        push @add_log2_extras,      0;
        $n -= 1;  # excluding diagonal
      }
    } else {
      if ($x > 0) {
        if ($y <= $x) {
          ### block 2 first octant ...

          ### past block 0 lower, excluding diagonal ...
          push @add_offset,          -1;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      0;
          $n -= 1;  # excluding diagonal

          ### past block 1 ...
          push @add_offset,           0;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;

        } else {
          ### block 3 second octant ...
          ($x,$y) = ($y-1,$x-1);
          $depth = 1;
          $mirror = 1;

          ### past block 0 lower, excluding diagonal ...
          push @add_offset,          -1;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      0;
          $n -= 1;  # excluding diagonal

          ### past block 1,2, excluding leading diagonal ...
          push @add_offset,           0;
          push @add_mult,             2;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;
          $n -= 1;  # excluding leading diagonal
        }
      } else {
        ### second quadrant ...
        $x = 2-$x;
        ### X mirror to: "x=$x y=$y"

        if ($y >= $x) {
          ### block 4 third octant ...
          ($x,$y) = ($y-1,$x-1);
          ### transpose to: "x=$x y=$y"
          $depth = 1;

          ### past block 0 lower, excluding diagonal ...
          push @add_offset,          -1;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      0;
          $n -= 1;  # excluding diagonal

          ### past block 1,2, excluding leading diagonal ...
          push @add_offset,           0;
          push @add_mult,             2;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;
          $n -= 1;  # excluding leading diagonal

          ### past block 3 ...
          push @add_offset,           1;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;

        } else {
          ### block 5 fourth octant ...
          $mirror = 1;
          $log2_extras = 0;

          ### past block 0 lower, excluding diagonal ...
          push @add_offset,          -1;
          push @add_mult,             1;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      0;
          $n -= 1;  # excluding diagonal

          ### past block 1,2, excluding leading diagonal ...
          push @add_offset,           0;
          push @add_mult,             2;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;
          $n -= 1;  # unduplicate leading diagonal

          ### past block 3,4 ...
          push @add_offset,           1;
          push @add_mult,             2;
          push @add_top_no_extra_pow, 0;
          push @add_log2_extras,      1;
          $n -= 1;  # excluding block4 diagonal
        }
      }
    }

  } elsif ($parts eq 'side') {
    ### parts==side ...
    if ($x < 0 || $y < 0) {
      return undef;
    }
    if ($x <= 1 && $y <= 1) {
      return $yxside_to_n[$y][$x];
    }

    if ($y > $x) {
      ### second octant ...
      ($x,$y) = ($y+1,$x+1);
      $depth = -1;
      $mirror = 1;
      $log2_extras = 0;
      $n -= 1;  # excluding diagonal

      ### past block 1 ...
      push @add_offset,           0;
      push @add_mult,             1;
      push @add_top_no_extra_pow, 0;
      push @add_log2_extras,      1;
    }


  } elsif ($parts eq '2') {
    ### parts==2 ...
    # if ($x == 0) {
    #   if ($y == 1) { return 0; }
    # }
    # if ($y == 1) {
    #   if ($x == 1) { return 1; }
    #   if ($x == -1) { return 2; }
    # }
    # if ($x < 0) {
    #   ### initial mirror second quadrant ...
    #   $x = -$x;
    #   $mirror = 1;
    #   push @add_offset, -1;
    #   push @add_mult, 1;
    # }
  }

  if ($x == 0 || $y == 0) {
    ### nothing on axes after origin ...
    return undef;
  }

  for (;;) {
    ### at: "x=$x,y=$y  n=$n  pow=$pow depth=$depth mirror=$mirror log2_extras=$log2_extras top_extra=$top_extra top_no_extra_pow=$top_no_extra_pow"
    ### assert: $x >= 0
    ### assert: $x < 2 * $pow
    ### assert: $y >= 0
    ### assert: $y <= $x

    if ($x <= 3) {
      ### loop small XY ...
      ### $top_no_extra_pow

      if ($x == 3) {
        if (! $log2_extras) {
          if ($y == 1) {
            ### no log2_extras ...
            return undef;
          }
          if (! $mirror) {
            ### no log2_extras, N decrement, (not mirrored) ...
            $n -= 1;
          }
        }
        if ($top_no_extra_pow == 4) {
          if ($y == 3) {
            ### no top extra, so no such point ...
            return undef;
          }
          ### top_no_extra_pow, N decrement by mirror: $mirror
          $n -= $mirror;
        }
      }

      my $nyx = $yx_to_n[$mirror][$y][$x];
      ### $nyx
      if (! defined $nyx) {
        ### no such point ...
        return undef;
      }
      $n += $nyx;
      $depth += $x;
      last;
    }

    if ($x == $pow) {
      if ($y == $pow) {
        ### mid X=pow,Y=pow, stop ...
        $depth += $pow;
        last;
      }
      ### X=pow no such point ...
      return undef;
    } elsif ($x == $pow+1) {
      if ($y == $pow-1) {
        ### mid X=pow+1,Y=pow-1, stop ...
        $depth += $pow+1;
        $n += ($mirror ? 2 : 0);
        last;
      }
      if ($y == $pow) {
        ### mid X=pow+1,Y=pow, stop ...
        $depth += $pow+1;
        $n += 1;
        last;
      }
      if ($y == $pow+1) {
        ### mid X=pow+1,Y=pow+1, stop ...
        $depth += $pow+1;
        $n += ($mirror ? 0 : 2);
        last;
      }
    }

    if ($x < $pow) {
      ### base block ...
      $top_no_extra_pow = 0;

    } else {
      $x -= $pow;
      $depth += $pow;
      if ($y < $pow) {
        $y = $pow-$y;
        ### Y flip to: $y

        if ($y > $x) {
          ### block lower, excluding diagonal ...
          ($x,$y) = ($y+1,$x+1);
          ### rotate to: "x=$x y=$y"
          ### assert: $y >= 0
          unless ($y && $x < $pow) {
            ### Y=0 or X>=pow, no such point ...
            return undef;
          }
          $top_no_extra_pow = 0;
          $log2_extras = 0;
          $depth -= 1;
          if ($mirror) {
            ### offset past extend,upper, undup diagonal, (mirrored) ...
            push @add_offset,           $depth+1;
            push @add_mult,             2;
            push @add_top_no_extra_pow, $top_no_extra_pow/2;
            push @add_log2_extras,      1;
            $n -= 1;  # duplicated diagonal upper,lower
          }

        } else {
          ### block upper ...
          if ($mirror) {
            ### offset past extend (mirrored) ...
            push @add_offset,           $depth;
            push @add_mult,             1;
            push @add_top_no_extra_pow, $top_no_extra_pow/2;
            push @add_log2_extras,      1;
          } else {
            if ($x < $pow-1) {
              ### offset past lower, unduplicate diagonal, (not mirrored) ...
              push @add_offset, $depth-1;
              push @add_mult, 1;
              push @add_top_no_extra_pow, 0;
              push @add_log2_extras, 0;
              $n -= 1;  # duplicated diagonal upper,lower
            }
          }
          $top_no_extra_pow = ($log2_extras ? 0 : $pow);
          $log2_extras = 1;
          $mirror ^= 1;
        }
      } else {
        ### extend, same ...
        unless ($x) {
          ### on X=0, past block3, no such point ...
          return undef;
        }
        if ($mirror) {
          ### no offset past lower at X=pow-1 ...
        } else {
          if ($x < $pow-1) {
            ### offset past lower (not mirrored) ...
            push @add_offset,           $depth-1;
            push @add_mult,             1;
            push @add_top_no_extra_pow, 0;
            push @add_log2_extras,      0;
            $n -= 1;  # duplicated diagonal
          }
          ### offset past upper (not mirrored) ...
          push @add_offset,           $depth;
          push @add_mult,             1;
          push @add_top_no_extra_pow, ($log2_extras ? 0 : $pow);
          push @add_log2_extras,      1;
          # if (! $log2_extras) {
          #   ### no log2_extras so N decrement ...
          #   $n -= 1;
          # }
        }
        $y -= $pow;
        $log2_extras = 1;
        $top_extra = 1;
        $top_no_extra_pow /= 2;
      }
    }

    if (--$exp < 0) {
      ### final xy: "$x,$y"
      if ($x == 1 && $y == 1) {
      } elsif ($x == 1 && $y == 2) {
        $depth += 1;
      } else {
        ### not in final position ...
        return undef;
      }
      last;
    }
    $pow /= 2;
  }


  ### final depth: $depth
  ### $n
  ### depth_to_n: $self->tree_depth_to_n($depth)
  ### add_offset: join(',',@add_offset)
  ### add_mult:   join(',',@add_mult)
  ### assert: scalar(@add_offset) == scalar(@add_mult)
  ### assert: scalar(@add_offset) == scalar(@add_log2_extras)
  ### assert: scalar(@add_offset) == scalar(@add_top_no_extra_pow)

  $n += $self->tree_depth_to_n($depth);

  if (@add_offset) {
    foreach my $i (0 .. $#add_offset) {
      my $d = $add_offset[$i] = $depth - $add_offset[$i];

      if ($d+1 == $add_top_no_extra_pow[$i]) {
        ### no top_extra, decrement applied: "d=$d"
        $n -= 1;
      }
      if (! $add_log2_extras[$i] && $d >= 3 &&  _is_pow2($d+1)) {
        ### no log2_extras, decrement applied: "depth d=$d"
        $n -= 1;
      }

      ### add: "depth=$add_offset[$i] is "._depth_to_octant_added([$add_offset[$i]],[1],$zero)." x $add_mult[$i]   log2_extras=$add_log2_extras[$i] top_no_extra_pow=$add_top_no_extra_pow[$i]"
    }

    ### total add: _depth_to_octant_added ([@add_offset], [@add_mult], $zero)
    $n += _depth_to_octant_added (\@add_offset, \@add_mult, $zero);
  }

  ### xy_to_n() return n: $n
  return $n;
}


#------------------------------------------------------------------------------
# rect_to_n_range()

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### OneOfEight rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  my $parts = $self->{'parts'};

  my $extra = ($parts eq '3side' ? 2 : 0);
  my ($pow,$exp) = round_down_pow (max(1,
                                       abs($x1),
                                       abs($x2)+$extra,
                                       abs($y1),
                                       abs($y2)+$extra),
                                   2);

  if ($parts eq '1') {
    # (total(2^k)+3)/4 = ((16*4^k + 24*k - 7)/9 + 3)/4
    #                  = (16*4^k + 24*k - 7 + 27)/9/4
    #                  = (16*4^k + 24*k + 20)/9/4
    #                  = (4*4^k + 6*k + 5)/9
    # applied to k=exp+1 2*pow=2^k
    #                  = (4* 2*pow * 2*pow + 6*(exp+1) + 5)/9
    #                  = (16*pow*pow + 6*exp + 11)/9
    return (0, (16*$pow*$pow + 6*$exp + 11) / 9);
  }

  # $parts eq '4'
  # total(2^k) = (16*4^k + 24*k - 7)/9
  # applied to k=exp+1 2*pow=2^k
  #            = (16 * 2*pow * 2*pow + 24*(exp+1) - 7) / 9
  #            = (64*pow*pow + 24*exp + 24-7) / 9
  #            = (64*pow*pow + 24*exp + 17) / 9
  return (0, (64*$pow*$pow + 24*$exp + 17) / 9);
}

#------------------------------------------------------------------------------
# tree

use constant tree_num_roots => 1;

sub tree_n_to_depth {
  my ($self, $n) = @_;
  ### tree_n_to_depth(): "$n"

  if ($n < 0) {
    return undef;
  }
  my ($depth) = _n0_to_depth_and_rem($self, int($n));
  ### n0 depth: $depth
  return $depth;
}

my @surround8_dx = (1, 1, 0, -1, -1, -1,  0,  1);
my @surround8_dy = (0, 1, 1,  1,  0, -1, -1, -1);

sub tree_n_children {
  my ($self, $n) = @_;
  ### tree_n_children(): $n

  my ($x,$y) = $self->n_to_xy($n)
    or return;
  ### $x
  ### $y

  my $depth = $self->tree_n_to_depth($n) + 1;
  return
    sort {$a<=>$b}
      grep { $self->tree_n_to_depth($_) == $depth }
        map { $self->xy_to_n_list($x + $surround8_dx[$_],
                                  $y + $surround8_dy[$_]) }
          0 .. $#surround8_dx;
}
sub tree_n_parent {
  my ($self, $n) = @_;

  if ($n < 0) {
    return undef;
  }
  my ($x,$y) = $self->n_to_xy($n)
    or return undef;
  my $parent_depth = $self->tree_n_to_depth($n) - 1;

  foreach my $i (0 .. $#surround8_dx) {
    my $pn = $self->xy_to_n($x + $surround8_dx[$i],
                            $y + $surround8_dy[$i]);
    if (defined $pn && $self->tree_n_to_depth($pn) == $parent_depth) {
      return $pn;
    }
  }
  return undef;
}


#------------------------------------------------------------------------------
# tree_depth_to_n()

#    1        1  1
#    2        9  1001
#    4       33  100001
#    8      121  1111001
#   16      465  111010001
#   32     1833  11100101001
#   64     7297  1110010000001
#  128    29145  111000111011001
#  256   116529  11100011100110001
#  512   466057  1110001110010001001
# 1024  1864161  111000111000111100001
#
# before 1  2 3  4 5  6  7  8  9 10 11 12 13  14  15   16
# side = 0, 1,3, 6,9,14,21, 27,30,35,43,52,63,80,100, 112
#                              3,5,8,9,11,17,20,12
#
# side(5)  = side(4) + side(2) + 2*side(1) + 2
#          = 6 + 1 + 2*0 + 2 = 9
# side(9)  = side(8) + side(1) + 2
# side(10) = side(8) + side(3) + 2*side(2) + 3 = 27 + 3 + 2*1 + 3 = 35
# side(11) = side(8) + side(4) + 2*side(3) + log2(4/4) + 3 = 27+6+2*3+1+3 = 42
#
# side(2^k) = 4*side(2^(k-1)) -1   block 1 missing one in corner
#                             + k-2  block 2 extra lower
#                             + 3    centre A,B,C
#           = 4*side(2^(k-1)) + k
#   = k + (k-1)*4^1 + (k-2)*4^2 + ... + 2*4^(k-1) + 4^k
# eg. k=3  3+2*4+1*16 = 27
#          = 1 + 1+4 + 1+4+16 = 1 + 5 + 21
#    sum 1+4+...+4^(k-1) = (4^k-1)/3
# side(2^k) = (4^k-1)/3 + (4^(k-1)-1)/3 + ... + (4^1-1)/3
#           = (4^k - 1 + 4^(k-1) - 1 + ... + 4^1 - 1)/3    # k terms 4^k to 4^1
#           = (4^k + 4^(k-1) + ... + 4^1 - k)/3
#           = (4^k + 4^(k-1) + ... + 4^1 + 4^0 - 1 - k)/3
#           = ((4^(k+1)-1)/3 - 1 - k)/3
#           = (4^(k+1)-1 - 3*k - 3)/9
#           = (4*4^k - 3*k - 4)/9
#
# side(2^1=2) = 1
# side(2^2=4) = 1 + 1-1 + 1+0 + 1 + 3 = 6 = 4*1 + 2 = 4^1 + 2
# side(2^3=8) = 6 + 6-1 + 6+1 + 6 + 3 = 27 = 4*6 + 3 = 4^2 + 4*2+3
# side(2^4=16) = 27+27-1 +27+2 +27 + 3 = 112 = 4*27 + 4 = 4^3 + 16*2+4*3+4
#
#
#
#  centre(2^k) = 2*side(2^(k-1)) + 2*centre(2^(k-1))
#  centre(1) = 1
#  centre(2) = 4
#  centre(4) = 2*side(2) + 2*centre(2)
#            = 2*side(2) + 2*4
#            = 2*1 + 2*4 = 10
#  centre(8) = 2*side(4) + 2*centre(4)  = 2*6+2*10 = 32
#            = 2*side(4) + 2*(2*side(2) + 2*4)
#            = 2*side(4) + 4*side(2) + 4*4
#            = 2*6 + 4*1 + 4*4 = 32
#  centre(16) = 2*side(4) + 2*centre(4) = 2*6+2*10 = 32
#            = 2*side(8) + 4**side(4) + 8*side(2) + 8
#            = 2*27 + 4*6 + 8*1 + 8 = 94
#
# 4parts = 4*centre - 7
# 4parts(4) = 4*10-7 = 33
# 4parts(8) = 4*32-7 = 121
#
# 3side total 0,1, 4, 9,17
#              +1 +3 +5 +8
#
# centre(2^k)
#   = 2*side(2^(k-1)) + 2*centre(2^(k-1))
#   = 2*side(2^(k-1) + 2^2*side(2^(k-1) + ... + 2^(k-1)*side(2^1) + 2^(k-1)*4
#   k-1 many terms, and constant at end
# side(2^k) = (4*4^k - 3*k - 4)/9
#
# constant part
# 2 + 4 + ... + 2^(k-1)
#   = 2^k - 2
# eg. k=2 2
# eg. k=3 2 + 4 = 6
# eg. k=4 2 + 4 + 8 = 14
#
# linear part
# 2*(k-1) + 4*(k-2) + ... + 2^(k-1)*(1) + 2^k*(0)
#   = 2^(k-1)-1 + 2^(k-2)-1 + ... + 2-1
#   = 2*2^k - 2*k - 2
# eg. k=2 2*1 = 2
# eg. k=3 2*2 + 4*1 = 8
# eg. k=4 2*3 + 4*2 + 8*1 =  22
# eg. k=5 2*4 + 4*3 + 8*2 + 16*1 = 52
#
# exponential part
# 2*4^(k-1) + 4*4^(k-2) + 8*4^(k-3) + ... + 2^(k-1)*4^1
#   = 2^(2k-2+1) + 2^(2k-4+2) + 2^(2k-6+3) + ... + 2^(k+1)
#   = 2^(2k-1) + 2^(2k-2) + 2^(2k-3) + ... + 2^(k+1)
#   = 2^(k+1) * [ 2^(k-2) + 2^(k-3) + 2^(k-4) + ... + 2^(0) ]
#   = 2^(k+1) * (2^(k-1) - 1)
#   = 2^k * (2^k - 2)
# eg. k=2 2*4^1 = 8
# eg. k=3 2*4^2 + 4*4^1 = 48
# eg. k=4 2*4^3 + 4*4^2 + 8*4^1 = 224
# eg. k=5 2*4^4 + 4*4^3 + 8*4^2 + 16*4^1 = 960
#
# centre(2^k) = (4*(2^k * (2^k - 2)) - 3*(2*2^k-2*k-2) - 4*(2^k-2)) / 9 + 2*2^k
# eg. k=2  sidepart = 2*1 = 1  plus
# eg. k=3  sidepart = 2*6 + 4*1 = 16
# eg. k=4  sidepart = 2*27 + 4*6 + 8*1 = 86
#   = (4*(2^k * (2^k - 2)) - 3*(2*2^k-2*k-2) - 4*(2^k-2)) / 9 + 2*2^k
#   = (4*2^k*(2^k - 2) - 6*2^k + 3*2*k + 6 - 4*2^k + 8 + 18*2^k) / 9
#   = (4*2^k*2^k - 8*2^k - 6*2^k + 3*2*k - 4*2^k + 18*2^k + 14) / 9
#   = (4*2^k*2^k + 6*k + 14) / 9
#   = (4*depth^2 + 6*k + 14) / 9
#
# centre(2^k) = (4*4^k + 6*k + 14) / 9
# side(2^k)   = (4*4^k - 3*k - 4) / 9
# diff = (9k+18)/9 = k+2
# double centre(2^(k+1)) - 4*centre(2^k)
#   = (4*4^(k+1) + 6*(k+1) + 14 - 4*(4*4^k + 6*k + 14)) / 9
#   = (4*4*4^k + 6*k + 6 + 14 - 4*4*4^k - 4*6*k - 4*14) / 9
#   = (6*k - 4*6*k + 6 + 14 - 4*14) / 9
#   = (-18*k - 36) / 9
#   = -2*k - 4
# smaller than 4* on each doubling
# 6k+14 term only adds extra 6, doesn't go 4*(6k+14)
#
# side(pow+rem) = side(pow) + side(rem+1)   -1 if rem+1=pow
#                           + side(rem)
#                           + side(rem) + log2(rem+1) + 2
# except rem==1 is side(pow)+3
# eg side(5) = side(4) + 3
#            = 6       + 3 = 9
# eg side(6) = side(4) + side(3) + 2*side(2) + log2(3)+2
#            = 6       + 3       + 2*1         +1   + 2 = 14
#
# centre(pow+rem) = centre(pow) + centre(rem) + 2*side(rem)
#                 = 2*side(pow/2) + 4*side(pow/4) + ...
#                   + centre(rem) + 2*side(rem)

# d = p1+p2+p3+p4
# C(d) = C(p1) + 2*S(p2+p3+p4) + C(p2+p3+p4)
#      = C(p1) + 2*S(p2+p3+p4) + C(p2) + 2*S(p3+p4) + C(p3+p4)
#      = C(p1) + C(p2) + 2*S(p2+p3+p4) + 2*S(p3+p4) + C(p3) + C(p4) + 2*S(p4)
#      = C(p1) + C(p2) + C(p3) + C(p4) + 2*S(p2+p3+p4) + 2*S(p3+p4) + 2*S(p4)
# eg. C(4+1) = C(4) + C(1) + 2*S(1)
#            =  10  +  1   + 2*0 = 11
# eg. C(4+1) = C(4) + C(2) + 2*S(2)
#            =  10  +   4  + 2*1  = 18
# eg. C(8+1) = C(8) + C(1) + 2*S(1)
#            =  32  +   1  + 2*0 = 35
# eg. C(8+2) = C(8) + C(2) + 2*S(2)
#            =  32  +   4  + 2*1 = 38
# eg. C(8+4) = C(8) + C(4) + 2*S(4)
#            =  32  +  10  + 2*6 = 54
# eg. C(8+4+1) = C(8) + C(4) + C(1) + 2*S(4+1) + 2*S(1)
#              =  32  +  10  +   1  + 2*9 + 2*0 = 61
# eg. C(8+4+2) = C(8) + C(4) + C(2) + 2*S(4+2) + 2*S(2)
#              =  32  +  10  +   4  + 2*14     + 2*1 = 76
#
# A151735
# before     1 2 3   4  5  6  7   8  9 10 11 12 13  14  15   16
# centre = 0,1,4,5, 10,11,16,21, 32,33,38,43,54,61  76  95  118
#
# before 1  2 3  4 5  6  7  8  9 10 11 12 13  14  15   16
# side = 0, 1,3, 6,9,14,21, 27,30,35,43,52,63,80,100, 112
#
# A151725 total cells 0,1,9,13, 33,37,57,77, 121,125,145,165,209,237,297,373,
#
#
# 15 |    15 15 15    15 15 15    15 15 15    15 15 15
# 14 |       14          14          14          14 15
# 13 |       14 13 13 13 14          14 13 13 13    15
# 12 |       14    12                      12 13
# 11 |             12 11 11 11    11 11 11    13    15
# 10 |       14    12    10          10 11    14 14 15
#  9 |       14 13 13    10  9  9  9    11          15
#  8 |                          8  9
#  7 |     7  7  7     7  7  7     9    11          15
#  6 |        6           6  7    10 10 11    14 14 15           19          18
#  5 |        6  5  5  5     7          11    13    15           20 15 14 13
#  4 |              4  5          13 12 12 12 13                       10 12
#  3 |     3  3  3     5     7    13          13    15         9  8  7    11
#  2 |        2  3     6  6  7    14 14    14 14 14 15            4  6    16 17
#  1 |  1  1     3           7                      15      3  2     5
#  0 |  0  1                                                0  1
#    +----------------------------------------------
#       0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
#
#       same mirror 1->9          same 1->9
#                                extra log(d) in Y=8 row
#
# 16 |                                                 16
# 15 |    15 15 15    15 15 15    15 15 15    15 15 15 16     k=4 depth=16
# 14 |       14          14          14          14    16
# 13 |       14 13 13 13 14          14 13 13 13 14
# 12 |       14    12                      12    14
# 11 |             12 11 11 11    11 11 11 12
# 10 |       14    12    10          10    12    14
#  9 |       14 13 13    10  9  9e 9d10    13 13 14
#  8 |                          8c   10          14
#  7 |     7  7  7     7  7  7  8b
#  6 |        6           6     8a   10          14      rotate -90  1->8
#  5 |        6  5  5  5  6     9  9 10    13 13 14      miss one in corner
#  4 |              4     6          10    12    14
#  3 |     3  3  3  4          12 11 11 11 12
#  2 |        2     4     6    12          12    14
#  1 |  1  1  2     5  5  6    13 13    13 13 13 14
#  0 |  0  .            ****                    ****
#    +---------------------------------------------------
#       0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
#
# Octant
#
# 16 |
# 15 |                                              15
# 14 |                                           14 15
# 13 |                                        13    15
# 12 |                                     12 13
# 11 |                                  11    13    15
# 10 |                               10 11    14 14 15
#  9 |                             9    11          15
#  8 |                          8  9
#  7 |                       7     9    11          15
#  6 |                    6  7    10 10 11    14 14 15
#  5 |                 5     7          11    13    15
#  4 |              4  5          13 12 12 12 13
#  3 |           3     5     7    13          13    15
#  2 |        2  3     6  6  7    14 14    14 14 14 15
#  1 |     1     3           7                      15
#  0 |  0  1
#    +---------------------------------------------------
#       0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
#
# oct(pow+rem) = oct(pow)
#                + oct(rem)    # extend
#                + oct(rem)    # upper
#                + oct(rem+1)  # lower
#                - rem         # undouble spine
#                + 2*floor(log2(rem+1))    # upper+extend log2_extras
#
# side(rem) = oct(rem) + oct(rem+1)
#             - rem                   # no double spine
#             + floor(log2(rem+1))    # upper log2_extras
#
# pow=2^k
# oct(2*pow) = 4*oct(pow) + 2*(k-2) - (pow-2)
# oct(2^0=1) = 0
# oct(2^1=2) = 1
# oct(2^2=4) = 4  = 4*1 - 0
# oct(2^3=8) = 16 = 4*4 - 0
# oct(2^4=16) = 16+7+4+7+3+4+5+4+3+3+3+2+1 = 62 = 4*16 - 2

# 3side
#
#  **** *** *** *** *** *** *** ***
#  * *   *   *   *   *   *   *   *
# ** *****   *****   *****   *****
#    * *       * *   * *       * *
# **   **** ****       **** ****
#  * * * *   * * *   * * *   * * *
# ** *** ***** ***   *** ***** ***
#    *   * *               * *   *      side                        side
# **       *888 888 888 888*                                        depth+1
#  * *   * * 7   7   7   7 * *   *            upper    |  upper
#    *** *** 76667   76667 *** ***            depth-1  |  depth-1
#  * * * *   7 5       5 7   * * *              \      |
# **   *****   5444 4445   *****                 \     |       /
#  * * *   * 7 5 3   3 5 7 *   * *         lower  \    |      /   lower
# ** **** ** 766 32223 667 ** ****         depth   \   |     /    depth
#                  1 3   7       *        ---------------------------
#                 01                                   |     \    upper
#                  1 3   7       *                     |      \   depth
#                  223 667 ** ****                     |       \
#                    3 5 7 *   * *                     | lower  \
#                  54445   *****                       | depth+1     side
#                  5   5 7   * * *
#                  66 6667 *** ***
#                        7 * *   *
#                  dcc 9888*
#                  d b 9   * *   *
#                    baaa **** ***
#                  e b       * * *
#                  dcccd   *****
#                  d   d   *   * *
#                  ee eee *** ****
#                                *

my @oct_to_n = (0, 1);

my %tree_depth_to_n = (4       => [ 0, 1 ],
                       1       => [ 0, 1 ],
                       octant  => [ 0, 1 ],
                       wedge   => [ 0, 1, 4 ],
                       '3mid'  => [ 0, 1 ],
                       '3side' => [ 0, 1, 4 ],
                       side    => [ 0, 1 ]);
my %tree_depth_to_n_extra_depth_pow = (4         => 0,
                                       1         => 0,
                                       octant    => 0,
                                       octant_up => 0,
                                       wedge     => 0,
                                       '3mid'    => 1,
                                       '3side'   => 1,
                                       side      => 1);

sub tree_depth_to_n {
  my ($self, $depth) = @_;
  ### tree_depth_to_n(): "$depth  parts=$self->{'parts'}"

  $depth = int($depth);
  if ($depth < 0) {
    return undef;
  }

  my $parts = $self->{'parts'};
  {
    my $initial = $tree_depth_to_n{$parts};
    if ($depth <= $#$initial) {
      ### table %tree_depth_to_n{}: $initial->[$depth]
      return $initial->[$depth];
    }
  }

  my ($pow,$exp) = round_down_pow
    ($depth + $tree_depth_to_n_extra_depth_pow{$parts},
     2);
  if (is_infinite($exp)) {
    return $exp;
  }
  ### $pow
  ### $exp

  my $zero = $depth * 0;  # inherit bignum
  my $n = $zero;

  # @side is a list of depth values.
  # @mult is the multiple of T[depth] desired for that @side entry.
  #
  # @side is mostly high to low and growing by one more value at each
  # $exp level, but sometimes it's a bit more and some values not high to
  # low and possibly duplicated.
  #
  my @pending = ($depth);
  my @mult;

  if ($parts eq '4') {
    @mult = (8);
    $n -= 4*$depth + 7;

  } elsif ($parts eq '1') {
    @mult = (2);
    $n -= $depth;

  } elsif ($parts eq 'octant' || $parts eq 'octant_up') {
    @mult = (1);

  } elsif ($parts eq 'wedge') {
    push @mult, 2;
    $n -= 2;  # unduplicate centre two

  } elsif ($parts eq '3mid') {
    unshift @pending, $depth+1;
    @mult = (2, 4);
    # Duplicated diagonals, and no log2_extras on two outermost octants.
    # Each log2 at depth=2^k-2, so another log2 decrease when depth=2^k-1.
    # $exp == _log2_floor($depth+1) so at $depth==2*$pow-1 one less.
    $n -= 3*$depth + 2*$exp + 6;

  } elsif ($parts eq '3side') {
    @pending = ($depth+1, $depth, $depth-1);
    @mult = (1, 3, 2);
    # Duplicated diagonals, and no log2_extras on two outermost octants.
    # For plain depth each log2 at depth=2^k-2, so another log2 decrease
    # when depth=2^k-1.
    # For depth+1 block each log2 at depth=2^k-2, so another log2 decrease
    # when depth=2^k-2.
    # $exp == _log2_floor($depth+1) so at $depth==2*$pow-1 one less.
    $n -= 3*$depth + 2*$exp + ($depth == $pow-1 ? 3 : 4);

  } elsif ($parts eq 'side') {
    unshift @pending, $depth+1;
    @mult = (1, 1);
    # $exp == _log2_floor($depth+1)
    $n -= $depth + 1 + $exp;
  }

  while ($exp >= 0 && @pending) {
    ### at: "pow=$pow exp=$exp  n=$n"
    ### assert: $pow == 2 ** $exp
    ### pending: join(',',@pending)
    ### mult: join(',',@mult)

    my @new_pending;
    my @new_mult;
    my $oct_pow;
    foreach my $depth (@pending) {
      my $mult = shift @mult;
      ### assert: $depth >= 0

      if ($depth <= 1) {
        ### small depth: "depth=$depth mult=$mult * $oct_to_n[$depth]"
        $n += $mult * $depth;  # oct=0 at depth=0, oct=1 at depth=1
        next;
      }
      my $rem = $depth - $pow;
      if ($rem < 0) {
        push @new_pending, $depth;
        push @new_mult, $mult;
        next;
      }

      ### $depth
      ### $mult
      ### $rem
      ### assert: $rem >= 0 && $rem < $pow

      my $powmult = $mult;
      if ($rem <= 1) {
        if ($rem == 0) {
          ### rem=0, oct(pow) only ...
        } else { # $rem == 1
          ### rem=1, oct(pow)+1 ...
          $n += $mult;
        }
      } else {
        ### formula ...
        # oct(pow+rem) = oct(pow)
        #                + oct(rem+1)
        #                + 2*oct(rem)
        #                - floor(log2(rem+1))
        #                - rem - 3

        my $rem1 = $rem + 1;
        {
          my ($lpow,$lexp) = round_down_pow ($rem1, 2);
          $n -= ($lexp + $rem + 3)*$mult;
          ### sub also: ($lexp + $rem + 3). " *mult=$mult"
        }
        if ($rem1 == $pow) {
          ### rem+1 == pow, increase powmult ...
          $powmult *= 2;    # oct(pow)+oct(rem+1) is 2*oct(pow)
        } elsif (@new_pending && $new_pending[-1] == $rem1) {
          ### merge into previously pushed new_pending[] ...
          # print "rem+1=$rem1 ",join(',',@new_pending),"\n";
          $new_mult[-1] += $mult;
        } else {
          ### push: "depth=$rem1 mult=$mult"
          push @new_pending, $rem1;
          push @new_mult, $mult;
        }

        ### push: "depth=$rem mult=".2*$mult
        push @new_pending, $rem;
        push @new_mult, 2*$mult;
      }

      # oct(pow) = (2*pow*pow + 3*exp + 7)/9 + pow/2
      #          = ((4*pow+9)*pow + 6*exp + 14)/18
      #
      $oct_pow ||= ((4*$pow+9)*$pow + 6*$exp + 14)/18;
      $n += $oct_pow * $powmult;
      ### oct(pow): "pow=$pow is $oct_pow * powmult=$powmult"
    }
    @pending = @new_pending;
    @mult = @new_mult;

    $exp--;
    $pow /= 2;
  }

  ### return: $n
  return $n;
}


# _depth_to_octant_added() returns the number of cells added at a given
# $depth level in parts=octant.  This is the same as
#     $added = tree_depth_to_n(depth+1) - tree_depth_to_n(depth)
#
# @$depth_aref is a list of depth values.
# @$mult_aref is the multiple of oct(depth) desired for each @depth_aref.
#
# On input @$depth_aref must have $depth_aref->[0] as the highest value.
#
# Within the code the depth list is mostly high to low and growing by one
# extra depth value at each $exp level.  But sometimes it grows a bit more
# than that and sometimes the values are not high to low, and sometimes
# there's duplication.
#
my @_depth_to_octant_added = (1, 2, 1);  # depth=0to2 small values

sub _depth_to_octant_added {
  my ($depth_aref, $mult_aref, $zero) = @_;
  ### _depth_to_octant_added(): join(',',@$depth_aref)
  ### mult_aref: join(',',@$mult_aref)
  ### assert: scalar(@$depth_aref) == scalar(@$mult_aref)

  # $depth_aref->[0] must be the biggest depth, to make the $pow finding easy
  ### assert: scalar(@$depth_aref) >= 1
  ### assert: max(@$depth_aref) == $depth_aref->[0]

  my ($pow,$exp) = round_down_pow ($depth_aref->[0], 2);
  if (is_infinite($exp)) {
    return $exp;
  }
  ### $pow
  ### $exp

  my $added = $zero;

  # running $pow down to 2 (inclusive)
  while ($exp >= 0 && @$depth_aref) {
    ### at: "pow=$pow exp=$exp"
    ### assert: $pow == 2 ** $exp

    ### depth: join(',',@$depth_aref)
    ### mult: join(',',@$mult_aref)
    my @new_depth;
    my @new_mult;
    foreach my $depth (@$depth_aref) {
      my $mult = shift @$mult_aref;
      ### assert: $depth >= 0

      if ($depth <= $#_depth_to_octant_added) {
        ### small depth: "depth=$depth mult=$mult * $_depth_to_octant_added[$depth]"
        $added += $mult * $_depth_to_octant_added[$depth];
        next;
      }
      if ($depth < $pow) {
        push @new_depth, $depth;
        push @new_mult, $mult;
        next;
      }

      my $rem = $depth - $pow;

      ### $depth
      ### $mult
      ### $rem
      ### assert: $rem >= 0 && $rem < $pow

      if ($rem <= 1) {
        if ($rem == 0) {
          ### rem=0, grow 1 ...
          $added += $mult;
        } else {
          ### rem=1, grow 3 ...
          $added += 3 * $mult;
        }
      } else {
        my $rem1 = $rem + 1;
        if ($rem1 == $pow) {
          ### rem+1=pow, no lower part, 3/2 of pow ...
          $added += ($pow/2) * (3*$mult);
        } else {
          ### formula ...
          # oadd(pow+rem) = oadd(rem+1) + 2*oadd(rem)
          #                 + (is_pow2($rem+2) ? -2 : -1)

          # upper/lower diagonal overlap, and no log2_extras in lower
          $added -= (_is_pow2($rem+2) ? 2*$mult : $mult);

          if (@new_depth && $new_depth[-1] == $rem1) {
            ### merge into previously pushed new_depth ...
            # print "rem=$rem ",join(',',@new_depth),"\n";
            $new_mult[-1] += $mult;
          } else {
            ### push: "rem+1  depth=$rem1 mult=$mult"
            push @new_depth, $rem1;
            push @new_mult, $mult;
          }

          ### push: "rem    depth=$rem mult=".2*$mult
          push @new_depth, $rem;
          push @new_mult, 2*$mult;
        }
      }
    }
    $depth_aref = \@new_depth;
    $mult_aref = \@new_mult;

    $exp--;
    $pow /= 2;
  }

  ### return: $added
  return $added;
}


#------------------------------------------------------------------------------
# tree_n_to_subheight()

#use Smart::Comments;

{
  my %tree_n_to_subheight
    = do {
      my $depth0 = [ ]; # depth=0
      (wedge   => [ $depth0,
                    [ undef, 0 ], # depth=1
                  ],
       '3mid'  => [ $depth0,
                    [ undef, 0, undef, 0 ], # depth=1
                  ],
       '3side' => [ $depth0,
                    [ undef, 0, undef ],           # depth=1
                    [ 0, undef, undef, 0 ], # depth=2 N=4to8
                  ],
      )
    };

  sub tree_n_to_subheight {
    my ($self, $n) = @_;
    ### tree_n_to_subheight(): $n

    if ($n < 0)          { return undef; }
    if (is_infinite($n)) { return $n; }

    my $zero = $n * 0;
    (my $depth, $n) = _n0_to_depth_and_rem($self, int($n));
    ### $depth
    ### $n

    my $parts = $self->{'parts'};
    if (my $initial = $tree_n_to_subheight{$parts}->[$depth]) {
      ### $initial
      return $initial->[$n];
    }

    if ($parts eq 'octant') {
      my $add = _depth_to_octant_added ([$depth],[1], $zero);
      $n = $add-1 - $n;
      ### octant mirror numbering to n: $n

    } elsif ($parts eq 'octant_up') {

    } elsif ($parts eq 'wedge') {
      my $add = _depth_to_octant_added ([$depth],[1], $zero);
      ### assert: $n < 2*$add
      if ($n >= $add) {
        ### wedge second half ...
        $n = 2*$add-1 - $n;   # mirror
      }

    } elsif ($parts eq '3mid') {
      my $add = _depth_to_octant_added ([$depth+1],[1], $zero);
      if (_is_pow2($depth+2)) { $add -= 1; }
      ### $add

      $n -= $add-1;
      ### n decrease to: $n
      if ($n < 0) {
        ### 3mid first octant, mirror ...
        $n = - $n;
        $depth += 1;
      }

      $add = _depth_to_octant_added ([$depth],[1], $zero);
      my $end = 4*$add - 2;
      ### $add
      ### $end
      if ($n >= $end) {
        ### 3mid last octant ...
        $n -= $end;
        $depth += 1;
      } else {
        $n %= 2*$add-1;
        if ($n >= $add) {
          ### 3mid second half, mirror ...
          $n = 2*$add-1 - $n;
        }
      }

    } elsif ($parts eq '3side') {
      my $add = _depth_to_octant_added ([$depth+1],[1], $zero);
      if (_is_pow2($depth+2)) { $add -= 1; }
      ### $add

      $n -= $add-1;
      ### n decrease to: $n
      if ($n < 0) {
        ### 3side first octant, mirror ...
        $n = - $n;
        $depth += 1;
      }

      $add = _depth_to_octant_added ([$depth],[1], $zero);
      if ($n < 2*$add) {
        if ($n >= $add) {
          $n = 2*$add-1 - $n;
        }
      } else {
        $n -= 2*$add-1;

        $add = _depth_to_octant_added ([$depth-1],[1], $zero);
        if ($n < 2*$add) {
          $depth -= 1;
          if ($n >= $add) {
            $n = 2*$add-1 - $n;
          }
        } else {
          $n -= 2*$add-1;
        }
      }

    } else {
      ### assert: $parts eq '1' || $parts eq '4'
      if ($depth == 1) {
        return ($n % 2 ? undef : 0);
      }
      my $add = _depth_to_octant_added([$depth],[1], $zero);

      # quadrant rotate ...
      $n %= 2*$add-1;

      $n -= $add;
      if ($n < 0) {
        ### lower octant ...
        $n = -1-$n;   # mirror
      } else {
        ### upper octant ...
        $n += 1;  # undouble spine
      }
    }

    my $dbase;
    my ($pow,$exp) = round_down_pow ($depth, 2);

    for ( ; $exp-- >= 0; $pow /= 2) {
      ### at: "depth=$depth pow=$pow n=$n   dbase=".($dbase||'inf')
      ### assert: $n >= 0

      if ($n == 0) {
        ### n=0 on spine ...
        last;
      }
      next if $depth < $pow;

      if (defined $dbase) { $dbase = $pow; }
      $depth -= $pow;
      ### depth remaining: $depth

      if ($depth == 1) {
        ### assert: 1 <= $n && $n <= 2
        if ($n == 1) {
          ### depth=1 and n=1 remaining ...
          return 0;
        }
        $n += 1;
      }

      my $add = _depth_to_octant_added ([$depth],[1], $zero);
      ### $add

      if ($n < $add) {
        ### extend part, unchanged ...
      } else {
        $dbase = $pow;
        $n -= 2*$add;
        ### sub 2*add to: $n

        if ($n < 0) {
          ### upper part, mirror to n: -1 - $n
          $n = -1 - $n;   # mirror,  $n = $add-1 - $n = -($n-$add) - 1
        } else {
          ### lower part ...
          $depth += 1;
          $n += 1;  # undouble upper,lower spine
        }
      }

    }

    ### final ...
    ### $dbase
    ### $depth
    return (defined $dbase ? $dbase - $depth - 1 : undef);
  }
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  my $depth = 2**$level;
  unless ($self->{'parts'} eq '3side') { $depth -= 1; }
  return (0, $self->tree_depth_to_n_end($depth));
}
sub n_to_level {
  my ($self, $n) = @_;
  my $depth = $self->tree_n_to_depth($n);
  if (! defined $depth) { return undef; }
  unless ($self->{'parts'} eq '3side') { $depth += 1; }
  my ($pow, $exp) = round_up_pow ($depth, 2);
  return $exp;
}

#------------------------------------------------------------------------------

# return true if $n is a power 2^k for k>=0
sub _is_pow2 {
  my ($n) = @_;
  my ($pow,$exp) = round_down_pow ($n, 2);
  return ($n == $pow);
}
sub _log2_floor {
  my ($n) = @_;
  if ($n < 2) { return 0; }
  my ($pow,$exp) = round_down_pow ($n, 2);
  return $exp;
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath-Toothpick Nstart Nend Applegate Automata Congressus Numerantium ie Octant octant octants oct Ie OEIS Ndepth

=head1 NAME

Math::PlanePath::OneOfEight -- automaton growing to cells with one of eight neighbours

=head1 SYNOPSIS

 use Math::PlanePath::OneOfEight;
 my $path = Math::PlanePath::OneOfEight->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Applegate, David>X<Pol, Omar E.>X<Sloane, Neil>This a cellular automaton
growing into cells which have just 1 of 8 neighbours already "on" as per
part 14 "Square Grid with Eight Neighbours" of

=over

David Applegate, Omar E. Pol, N.J.A. Sloane, "The Toothpick Sequence and
Other Sequences from Cellular Automata", Congressus Numerantium, volume 206,
2010, pages 157-191.  L<http://www.research.att.com/~njas/doc/tooth.pdf>

=back

Points are numbered by a breadth-first tree traversal and anti-clockwise at
each node.

=cut

# math-image --path=OneOfEight --output=numbers --all --size=75x16

=pod

                                                                121    8
     93  92  91      90  89  88      87  86  85      84  83  82        7
     94  64              63              60              59  81        6
     95      44  43  42  62              61  41  40  39      80        5
             45  34                              33  38                4
     96      46      20  19  18      17  16  15      37      79        3
     97  65  66      21  10               9  14      57  58  78        2
     98              22       4   3   2      13              77        1
                              5   0   1                           <- Y=0
     99              23       6   7   8      32             120       -1
    100  68  67      24  11              12  31      76  75 119       -2
    101      47      25  26  27      28  29  30      56     118       -3
             48  35                              36  55               -4
    102      49  50  51  71              72  52  53  54     117       -5
    103  69              70              73              74 116       -6
    104 105 106     107 108 109     110 111 112     113 114 115       -7

                                  ^
     -7  -6  -5  -4  -3  -2  -1  X=0  1   2   3   4   5   6   7


The start is N=0 at the origin X=0,Y=0.  Then each cell around it has just
one neighbour (that first N=0 cell) and so all are turned on.  The rule is
applied in a single atomic step, so adjacent prospective new cells don't
count towards the 1 of 8.

At the next level only the diagonal cells X=+/-2,Y=+/-2 have a single
neighbour, then at the next level five around each of them, and so on.

                                     10           9
                                       \         /
                     4  3  2             4  3  2
                      \ | /               \ | /
         0           5--0--1             5--0--1
                      / | \               / | \
                     6  7  8             6  7  8
                                       /         \
                                     11           12

The children of a given node are numbered anti-clockwise around relative to
the direction of the node's parent.  For example N=9 has it's parent
south-west and so points around N=9 are numbered anti-clockwise around from
the south-west to give N=13 through N=17.

=head2 Depth Ranges

The pattern always extends along the X=+/-Y diagonals and grows into the
sides in power-of-2 blocks.  So for example in the part shown above N=33 at
X=4,Y=4 is the only cell growing out of the 4x4 block X=0..3,Y=0..3 at the
origin, and likewise N=34,35,36 in the other quadrants.  Then N=121 at
X=8,Y=8 is the only growth out of the 8x8 block, etc.

In general the first N at a power-of-2 depth is

    depth=2^k  for k>=0
    Ndepth(2^k) = (16*4^k + 24*k - 7) / 9
                = (16*depth*depth + 24*k - 7) / 9
    eg. k=3 Ndepth=121

Because points are numbered from N=0 this Ndepth is how many cells are "on"
in the pattern up to this depth (and not including it).  The cells are
within -2^k E<lt> X,Y E<lt> 2^k and so the fraction of the plane covered is

    density = Ndepth(2^k) / (2*2^k - 1)^2
            = (16*4^k + 24*k - 7) / 9 / (2*2^k-1)^2
            -> 4/9 = 0.444...    as k -> infinity

This density is approached from above, ie. decreases towards 4/9.  The first
k=0 is the single origin point which is density=1/1, and k=2 is density=9/9
of the 3x3 at the origin.  Then for example k=2 7x7 square has
density=33/49=0.673, then k=3 121/225=0.5377, etc.

=head2 One Quadrant

Option C<parts =E<gt> 1> confines the pattern to the first quadrant.  This
is a single copy of the part repeated in each of the four quadrants of the
full pattern.

=cut

# math-image --path=OneOfEight,parts=1 --all --output=numbers --size=75x16

=pod

    parts => 1

     15 |    117 116 115     114 113 112     111 110 109     108 107 106
     14 |         90              89              86              85 105
     13 |         91  73  72  71  88              87  70  69  68     104
     12 |         92      58                              57  67
     11 |                 59  53  52  51      50  49  48      66     103
     10 |         93      60      41              40  47      83  84 102
      9 |         94  74  75      42  37  36  35      46             101
      8 |                                 32  34
      7 |     31  30  29      28  27  26      33      45             100
      6 |         19              18  25      38  39  44      82  81  99
      5 |         20  15  14  13      24              43      65      98
      4 |                 10  12              61  54  55  56  64
      3 |      9   8   7      11      23      62              63      97
      2 |          4   6      16  17  22      76  77      78  79  80  96
      1 |  3   2       5              21                              95
    Y=0 |  0   1
        +----------------------------------------------------------------
         X=0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15

=head2 One Octant

Option C<parts =E<gt> 'octant'> confines the pattern to the first eighth of
the plane 0E<lt>=YE<lt>=X.

=cut

# math-image --path=OneOfEight,parts=octant --all --output=numbers --size=75x16

=pod

    parts => "octant"

     15 |                                              66
     14 |                                           54 65
     13 |                                        44    64
     12 |                                     36 43
     11 |                                  32    42    63
     10 |                               26 31    52 53 62
      9 |                            23    30          61
      8 |                         20 22
      7 |                      19    21    29          60
      6 |                   13 18    24 25 28    51 50 59
      5 |                10    17          27    41    58
      4 |              7  9          37 33 34 35 40
      3 |           6     8    16    38          39    57
      2 |        3  5    11 12 15    45 46    47 48 49 56
      1 |     2     4          14                      55
    Y=0 |  0  1
        +-------------------------------------------------
         X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15

In this arrangement N=0,2,3,6,etc on the leading diagonal is the last N of
each row (C<tree_depth_to_n_end()>).

The full pattern is symmetric on each side of the four diagonals X=Y, X=-Y.
This octant is one of those eight symmetric parts.  It includes the diagonal
which is shared if two octants are combined to make a quadrant.

The octant is self similar in blocks

                              --|
                            --  |
                          --    |
                        --      |
                      -- extend |
                    --          |
          2^k,2^k --------------|
                --| --   upper  |
              --  |   --  flip  |
            --    |     --      |
          --      | lower --    |
        --  base  | depth+1 --  |
      --          | no pow2s  --|
    -----------------------------

"extend" is a direct copy of the "base" block.  "upper" likewise a direct
copy except flipped vertically.

"lower" is the base pattern rotated by +90 degrees and without the pow2
cells at Y=1 X=3,7,15,etc.  These absent cells are easier to see in a bigger
picture of the pattern.

The "lower" block is one depth level ahead too.  For example in the sample
above its last row is N=45,46,47,48 at depth=14 whereas the corresponding
end of the "extend" at N=61,62,63,64,65 is depth=15.

The diagonal between the lower and upper looks like a stair-step, but that's
not so.  It's the same as the X=Y leading diagonal of the whole octant but
because the lower block is one depth level ahead of the upper their branches
off the diagonal are offset by 1 position.  For example N=34,33,37 branching
into the lower corresponds to N=40,41,51 branching into the upper.

This offset on the upper/lower diagonal is easier to see by chopping off the
leaf nodes of the pattern (one level of leaf nodes).

=cut

# math-image --text --path=OneOfEight,parts=octant --values=PlanePathCoord,planepath=\"OneOfEight,parts=octant\",coordinate_type=IsNonLeaf --size=50x40

=pod

                  *       octant with leaf nodes pruned
                 *
                *
               *
              * *
             *   *
            *
           *
          * *
         *   *   *
        *     * *      <- upper,lower parts
       *     * *          branch off lower is 1 row sooner
      * *   *   *
     *   *       *
    *
   *

It may look at first as if the square side block comprising the "upper" and
"lower" blocks is entirely different from the central symmetric square
(L</One Quadrant> above), but that's not so, the only difference is the
offset branching from the diagonal which occurs in the "lower" part.

=head2 Upper Octant

Option C<parts =E<gt> 'octant_up'> confines the pattern to the upper octant
0E<lt>=XE<lt>=Y of the first quadrant.

=cut

# math-image --path=OneOfEight,parts=octant_up --all --output=numbers --size=75x16

=pod

    parts => "octant_up"

     15 |    66 65 64    63 62 61    60 59 58    57 56 55
     14 |       50          49          46          45   
     13 |       51 42 41 40 48          47 39 38 37      
     12 |       52    34                      33         
     11 |             35 32 31 30    29 28 27            
     10 |       53    36    25          24               
      9 |       54 43 44    26 23 22 21                  
      8 |                         20                     
      7 |    19 18 17    16 15 14                        
      6 |       12          11                           
      5 |       13 10  9  8                              
      4 |              7                                 
      3 |     6  5  4                                    
      2 |        3                                       
      1 |  2  1                                          
    Y=0 |  0                                             
        +-------------------------------------------------
         X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15

In this arrangement N=0,1,3,4,etc on the leading diagonal is the first N of
each row (C<tree_depth_to_n()>).

The pattern is a mirror image of parts=octant, mirrored across the X=Y
leading diagonal.  Points are still numbered anti-clockwise so the effect is
to reverse the order.  "octant" numbers from the ragged edge to the
diagonal, whereas "octant_up" numbers from the diagonal to the ragged edge.

=head2 Three Mid

Option C<parts =E<gt> "3mid"> is the "second corner sequence" of the
toothpick paper above.  This is the part of the full pattern starting at a
point X=2^k,Y=2^k in the full pattern, with the three square blocks there
each extended indefinitely.

=cut

# math-image --path=OneOfEight,parts=3mid --all --output=numbers --size=75x15

=pod

    parts => "3mid"

    85 84 83    82 81 80    79 78 77    76 75 74         7
       58          57          54          53 73         6
       59 41 40 39 56          55 38 37 36    72         5
       60    26                      25 35               4
             27 21 20 19    18 17 16    34    71         3
       61    28     9           8 15    51 52 70         2
       62 42 43    10  5  4  3    14          69         1
                          0  2                      <- Y=0
                             1    13          68        -1
                             6  7 12    50 49 67        -2
                                  11    33    66        -3
                            29 22 23 24 32              -4
                            30          31    65        -5
                            44 45    46 47 48 64        -6
                                              63        -7

                          ^
    -7 -5 -6 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

The first quadrant XE<gt>=0,YE<gt>=0 is the same as in the full pattern, but
the other quadrants are a "side" portion (branches off the diagonal offset
by 1 above and below).

This pattern can be generated from the 1 of 8 cell rule by starting from N=0
at X=0,Y=0 and then treating all points with XE<lt>0,YE<lt>0 as already
occupied.

                       ..       .. .. ..
                        9           8 ..
                       10  5  4  3    ..
                              0  2
              -------------+     1
    X<0,Y<0       *  *  *  |     6  7 ..
    considered    *  *  *  |
    all "on"      *  *  *  |

=head2 Three Side

Option C<parts =E<gt> "3side"> is the "first corner sequence" of the
toothpick paper above.  This is the part of the full pattern starting at a
point X=2^k+1,Y=3*2^k-1 and mirrored horizontally, and the three square
blocks there each extended indefinitely.

=cut

# math-image --path=OneOfEight,parts=3side --expression='i<=99?i:0' --output=numbers --size=120x25

=pod

    parts => "3side"

    .. 89 88 87    86 85 84    83 82 81    80 79 78 ..           8
          70          69          66          65                 7
          71 51 50 49 68          67 48 47 46 64                 6
          72    34                      33    63                 5
                35 25 24 23    22 21 20 32                       4
          73    36    15          14    31    62                 3
          74 52 53    16  8  7  6 13    44 45 61                 2
                             3    12          60                 1
                          0  2                              <- Y=0
                             1    11          59                -1
                             4  5 10    43 42 58                -2
                                   9    30    57                -3
                            26 17 18 19 29                      -4
                            27          28    56                -5
                            37 38    39 40 41 55                -6
                                              54                -7
                                        .. 75 76 77 ..          -8
                          ^
       -7 -6 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8

The two top quadrants YE<gt>=0 are mirror images across the vertical X=1.
The YE<lt>0 bottom quadrant is rotated -90 degrees and is one depth level
ahead of the other two, so for example its run N=54,55,56 corresponds to
N=78,79,80 in the first quadrant.

This pattern can be generated from the 1 of 8 rule by starting from N=0 at
X=0,Y=0 and then treating all points with XE<lt>0,YE<lt>=0 as already
occupied.  Notice parts=3mid above is YE<lt>0 occupied whereas here
parts=3side is YE<lt>=0.

                           .. 8  7  6 ..
                                 3
              -------------+  0  2
    X<0,Y<=0      *  *  *  |     1    11
    considered    *  *  *  |     4  5 10
    all "on"      *  *  *  |           9
                  *  *  *  |          ..

The 3side pattern is the same as the 3mid but with the portion above the X=Y
diagonal shifted up diagonally to X+1,Y+1 and therefore branching off the
diagonal 1 depth level later.  On that basis the two C<tree_depth_to_n()>
total cells are related by

   Ndepth3side(depth) = (Ndepth3mid(depth) + Ndepth3mid(depth-1) + 1) / 2

For example depth=4 begins at N=17 in 3side,

   Ndepth3side(4) = 17
   Ndepth3mid(4) = 22, Ndepth3mid(3) = 11
   (22 + 11 + 1)/2 = 17

=head2 Three Growth

The interest in the 3mid and 3side "corner" sequences is that a 3mid can be
doubled in size by adding a "3mid" and two "3side"s.

    +-------------+-------------+
    |             |             |       3mid doubled in size
    | new 3side   |  new 3mid   |       by adding two new 3sides
    |             |             |       and one new 3mid.
    |      +-------------+      |
    |      |             |      |
    |      |      3mid   |      |
    |      |             |      |
    +------+------+      |------+
                  |      |      |
                  |      |      |
                  |      |      |
                  +------+      |
                  |             |
                  |   new 3side |
                  |             |
                  +-------------+

=head2 Wedge

Option C<parts =E<gt> 'wedge'> confines the pattern to a V-shaped wedge
-YE<lt>=XE<lt>=Y.

=cut

# math-image --path=OneOfEight,parts=wedge --all --output=numbers --size=75x16

=pod

    parts => "wedge"

    37 36 35    34 33 32    31 30 29    28 27 26        7 
       25          24          21          20           6 
          19 18 17 23          22 16 15 14              5 
             13                      12                 4 
                11 10  9     8  7  6                    3 
                    5           4                       2 
                       3  2  1                          1 
                          0                         <- Y=0
    --------------------------------------------
    -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7 

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::OneOfEight-E<gt>new ()>

=item C<$path = Math::PlanePath::OneOfEight-E<gt>new (parts =E<gt> $str)>

Create and return a new path object.  The C<parts> option (a string) can be

    "4"           full pattern (the default)
    "1"           single quadrant
    "octant"      single eighth
    "octant_up"   single eighth upper
    "wedge"       V-shaped wedge
    "3mid"        three quadrants, middle symmetric style
    "3side"       three quadrants, side style

=back

=head2 Tree Methods

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the children of C<$n>, or an empty list if C<$n> has no children
(including when C<$n E<lt> 1>, ie. before the start of the path).  The way
points are numbered means the children are always consecutive N values.

=back

=head2 Tree Descriptive Methods

=over

=item C<@nums = $path-E<gt>tree_num_children_list()>

Return a list of the possible number of children at the nodes of C<$path>.
This is the set of possible return values from C<tree_n_num_children()>.
This varies with the C<parts> option,

    parts        tree_num_children_list()
    -----        ------------------------
      4              0, 1, 2, 3, 5, 8
      1              0, 1, 2, 3, 5
    octant           0, 1, 2, 3
    octant_up        0, 1, 2, 3
    wedge            0, 1, 2, 3
    3mid             0, 1, 2, 3, 5
    3side            0,    2, 3

For parts=4 there's 8 children at the initial N=0 and after that at most 5.

For parts=3side a 1 child never occurs.  There's 1 child only on the central
diagonal corner X=2^k,Y=2^k and for parts=3side there's no such corner.

parts=4,1,3mid have 5 children growing out of the 1-child of the X=2^k,Y=2^k
corner.  In an parts=octant, octant_up, and wedge there's only 3 children
around that point since that pattern doesn't go above the X=Y diagonal.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, tree_depth_to_n_end(2**$level - 1)>, or for parts=3side
C<tree_depth_to_n_end(2**$level)>.

parts=3side

=back

=head1 FORMULAS

=head2 Depth to N

The first point is N=0 so C<tree_depth_to_n($depth)> is the total number of
points up to and not including C<$depth>.  For the full pattern this
total(depth) follows a recurrence

    total(0)         = 0
    total(pow)       = (16*pow^2 + 24*exp - 7) / 9
    total(pow + rem) = total(pow) + 2*total(rem) + total(rem+1)
                         - 8*floor(log2(rem+1)) + 1
    where depth = pow + rem
      with pow=2^k the biggest power-of-2 <= depth
      and rem the remainder

For parts=octant the equivalent total points is

    oct(0)         = 0
    oct(pow)       = (4*pow^2 + 9*pow + 6*exp + 14) / 18
    oct(pow + rem) = oct(pow) + 2*oct(rem) + oct(rem+1)
                       - floor(log2(rem+1)) - rem - 3

The way this recurrence works can be seen from the self-similar pattern
described in L</One Octant> above.

    oct(pow)                # "base"
    + oct(rem)              # "extend"
    + oct(rem)              # "upper"
    + oct(rem+1)            # "lower"
    - floor(log2(rem+1))    # no pow2 points in lower
    - rem                   # unduplicate diagonal upper/lower
    - 3                     # unduplicate centre points

oct(rem)+oct(rem+1) of upper and lower would count their common diagonal
twice, hence "-rem" being the length of that diagonal.  The "centre" point
at X=pow,Y=pow is repeated by each of extend, upper, lower so "-2" to count
just once, and the X=pow+1,Y=pow point is repeated by extend and upper, so
"-1" to count it just once.

The 2*total(rem)+total(rem+1) in the formula is the same recurrence as the
toothpick pattern and the approach there can calculate it as a set of
pending depths and pow subtractions.  See
L<Math::PlanePath::ToothpickTree/Depth to N>.

The other patterns can be expressed as combinations of octants,

    parts=4 total   = 8*oct(n) - 4*n - 7
    parts=1 total   = 2*oct(n) - n
    3mid V2 total   = 2*oct(n+1) + 4*oct(n)
                        - 3n - 2*floor(log(n+1)) - 6
    3side V1 total  =   oct(n+1) + 3*oct(n) + 2*oct(n-1)
                        - 3n - floor(log(n+1)) - floor(log(n)) - 4

The depth offsets n,n+1,etc in these formulas become initial pending depth
for the toothpick style depth to N algorithm (and with respective initial
multipliers).

From the V1,V2 formulas it can be seen that V2(n)+V2(n+1) gives the same
combination of 1,3,2 times oct n-1,n,n+1 which is in V1, and that therefore
as noted in the Ndepth part of L</Three Side> above

    V1(n) = (V2(n) + V2(n-1) + 1) / 2

=head1 OEIS

This cellular automaton is in Sloane's Online Encyclopedia of Integer
Sequences as

=over

L<http://oeis.org/A151725> (etc)

=back

    parts=4 (the default)
      A151725   total cells "V", tree_depth_to_n()
      A151726   added cells "v"

    parts=1
      A151735   total cells, tree_depth_to_n()
      A151737   added cells

    parts=3mid
      A170880   total cells, tree_depth_to_n()
      A151728   added cells "v2"
      A151727   added cells "v2" * 4
      A151729   (added cells - 1) / 2

    parts=3side
      A170879   total cells, tree_depth_to_n()
      A151747   added cells "v1"

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ToothpickTree>,
L<Math::PlanePath::UlamWarburton>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015 Kevin Ryde

This file is part of Math-PlanePath-Toothpick.

Math-PlanePath-Toothpick is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Math-PlanePath-Toothpick is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

=cut
