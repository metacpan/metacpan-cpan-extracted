#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015 Kevin Ryde

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

use 5.004;
use strict;
use Test;
plan tests => 617;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::ToothpickTree;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 18;
  ok ($Math::PlanePath::ToothpickTree::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::ToothpickTree->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::ToothpickTree->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::ToothpickTree->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::ToothpickTree->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}



#------------------------------------------------------------------------------
# level_to_n_range()

foreach my $elem ([ '4',         [10,42         ], [3,7,15] ],
                  [ '3',         [ 8,32         ], [3,7,15] ],
                  [ '2',         [ 4,20         ], [2,6,14,30] ],
                  [ '1',         [ 1, 9, 41     ], [1,5,13,29] ],
                  [ 'octant',    [ 0, 6, 26     ], [0,4,12,28] ],
                  [ 'octant_up', [ 0, 6, 26     ], [0,4,12,28] ],
                  [ 'wedge',     [ 5,17, 57,201 ], [3,7,15,31] ],
                  [ 'two_horiz', [15,47,175     ], [3,7,15,31] ],
                 ) {
  my ($parts, $level_n_aref, $depth_aref) = @$elem;
  my $path = Math::PlanePath::ToothpickTree->new (parts => $parts);
  foreach my $level (0 .. $#$level_n_aref) {
    my $want_n_hi = $level_n_aref->[$level];
    # $level should run 0 to $want_n_hi inclusive

    my ($n_lo,$n_hi) = $path->level_to_n_range($level);
    ok ($n_lo, 0);
    ok ($n_hi, $want_n_hi, "parts=$parts level=$level");
    {
      my $got_level = $path->n_to_level($n_hi);
      ok ($level, $got_level);
    }
    {
      my $n = $n_hi+1;
      my $got_level = $path->n_to_level($n);
      ok ($got_level, $level+1,
         "parts=$parts level=$level n=$n got_level=$got_level");
    }
  }
  foreach my $level (0 .. $#$depth_aref) {
    my $depth = $depth_aref->[$level];
    my $n_end = $path->tree_depth_to_n_end($depth);
    my ($n_lo,$n_hi) = $path->level_to_n_range($level);
    ok ($n_hi, $n_end);
  }
}


#------------------------------------------------------------------------------
# oct() formulas

{
  my $path = Math::PlanePath::ToothpickTree->new (parts => 'octant');
  sub octant {
    my ($d) = @_;
    die "oops octant($d)" if $d < 2;
    return $path->tree_depth_to_n($d-2);
  }
}
{
  sub quadrant {
    my ($d) = @_;
    die "oops quadrant($d)" if $d < 2;
    if ($d == 2) { return 0; }
    return octant($d) + octant($d-1) - $d + 3;
  }
  my $path = Math::PlanePath::ToothpickTree->new (parts => '1');
  foreach my $d (2 .. 20) {
    my $p = $path->tree_depth_to_n($d-2);
    my $q = quadrant($d);
    ok ($p, $q);
  }
}
{
  sub half {
    my ($d) = @_;
    die "oops half($d)" if $d < 1;
    if ($d == 1) { return 0; }
    return 2*quadrant($d) + 1;
  }
  my $path = Math::PlanePath::ToothpickTree->new (parts => '2');
  foreach my $d (1 .. 20) {
    my $p = $path->tree_depth_to_n($d-1);
    my $h = half($d);
    ok ($p, $h);
  }
}
{
  sub full {
    my ($d) = @_;
    if ($d == 0) { return 0; }
    if ($d == 1) { return 1; }
    return 4*quadrant($d) + 3;
  }
  my $path = Math::PlanePath::ToothpickTree->new (parts => '4');
  foreach my $d (0 .. 20) {
    my $p = $path->tree_depth_to_n($d);
    my $f = full($d);
    ok ($p, $f);
  }
}
{
  sub corner3_a {
    my ($d) = @_;
    if ($d == 0) { return 0; }
    if ($d == 1) { return 1; }
    return quadrant($d+1) + 2*quadrant($d) + 2;
  }
  sub corner3_b {
    my ($d) = @_;
    if ($d == 0) { return 0; }
    if ($d == 1) { return 1; }
    if ($d == 2) { return 3; }
    return octant($d+1) + 3*octant($d) + 2*octant($d-1) - 3*$d + 10;
  }
  my $path = Math::PlanePath::ToothpickTree->new (parts => '3');
  foreach my $d (0 .. 20) {
    my $p = $path->tree_depth_to_n($d);
    my $c = corner3_a($d);
    ok ($p, $c);
    $c = corner3_b($d);
    ok ($p, $c);
  }
}
{
  sub wedge {
    my ($d) = @_;
    if ($d == 0) { return 0; }
    if ($d == 1) { return 1; }
    if ($d == 2) { return 2; }
    return 2*octant($d-1) + 4;
  }
  my $path = Math::PlanePath::ToothpickTree->new (parts => 'wedge');
  foreach my $d (0 .. 20) {
    my $p = $path->tree_depth_to_n($d);
    my $w = wedge($d);
    ok ($p, $w);
  }
}


#------------------------------------------------------------------------------
# n_to_xy()

{
  my @groups = (
                [ { parts => 3 },
                  [  0,  0,0 ],   # vert
                  [  1,  0,-1 ],  # horiz
                  [  2,  0,1 ],

                  [  3,  1,-1 ],  # vert
                  [  4,  1,1 ],
                  [  5, -1,1 ],

                  [  6,  1,-2 ],  # horiz
                  [  7,  1,2 ],
                  [  8, -1,2 ],

                  [  9,  0,-2 ],  # vert
                  [ 10,  2,-2 ],
                  [ 11,  2,2 ],
                  [ 12, -2,2 ],

                  [ 13,  0,-3 ],  # horiz
                  [ 14,  2,-3 ],
                  [ 15,  2,-1 ],
                  [ 16,  2,1 ],
                  [ 17,  2,3 ], # -2,1
                  [ 18, -2,3 ],
                  [ 19, -2,1 ],
                  
                  # [  2,  3 ],   #
                  # [  3,  6 ],   #
                  # [  4,  9 ],   #
                  # [  5,  13 ],  #
                  # [  6,  20 ],  #
                  # [  7,  28 ],  #
                  # [  8,  33 ],  #
                  # [  9,  37 ],  #
                  # [ 10,  44 ],  #
                  # [ 11,  53 ],  #
                  # [ 12,  63 ],  #
                  # [ 13,  78 ],  #
                  # [ 14, 100 ],  #
                  # [ 15, 120 ],  #
                  # [ 16, 129 ],  #
                ],

                [ { parts => 1 },
                  [  0,  1,1 ],
                  [  1,  1,2 ],
                  [  2,  2,2 ], # A
                  [  3,  2,1 ], # other
                  [  4,  2,3 ], # B

                  [  5,  3,1 ], #
                  [  6,  3,3 ], #
                  [  7,  1,3 ], #

                  [  8,  3,4 ], #
                  [  9,  1,4 ], #

                  [ 10,  4,4 ], # A
                  [ 11,  4,3 ], # other
                  [ 12,  4,5 ], # B

                  [ 13,  5,3 ],
                  [ 14,  5,5 ],
                  [ 15,  3,5 ],

                  [ 16,  5,2 ],
                  [ 17,  5,6 ],
                  [ 18,  3,6 ],

                  [ 19,  4,2 ],
                  [ 20,  6,2 ],
                  [ 21,  6,6 ],
                  [ 22,  2,6 ],

                  [ 23,  4,1 ],
                  [ 24,  6,1 ],
                  [ 25,  6,3 ],
                  [ 26,  6,5 ],
                  [ 27,  6,7 ],
                  [ 28,  2,7 ],
                  [ 29,  2,5 ],
                ],

                [ { parts => 4 },

                  [ 0,  0,0  ], # origin
                  [ 1,  0,1  ], # up
                  [ 2,  0,-1 ], # down

                  [ 3,  1,1  ],
                  [ 4, -1,1  ],
                  [ 5, -1,-1 ],
                  [ 6,  1,-1 ],

                  [ 7,  1,2  ],
                  [ 8, -1,2  ],
                  [ 9, -1,-2 ],
                  [10,  1,-2 ],

                  [11,  2,2  ],
                  [12, -2,2  ],
                  [13, -2,-2 ],
                  [14,  2,-2 ],

                  [15,  2,1  ],
                  [16,  2,3  ],
                  [17, -2,3  ],
                  [18, -2,1  ],
                  [19, -2,-1 ],
                  [20, -2,-3 ],
                  [21,  2,-3 ],
                  [22,  2,-1 ],

                  [23,  3,1  ],
                  [24,  3,3  ],
                  [25,  1,3  ],
                  #
                  [26,  -1,3  ],
                  [27,  -3,3  ],
                  [28,  -3,1  ],
                  #
                  [29,  -3,-1 ],
                  [30,  -3,-3 ],
                  [31,  -1,-3 ],
                  #
                  [32,  1,-3  ],
                  [33,  3,-3  ],
                  [34,  3,-1  ],

                  [35,  3,4 ],
                  [36,  1,4 ],
                  [37, -1,4 ],
                  [38, -3,4 ],
                  [39, -3,-4 ],
                  [40, -1,-4 ],
                  [41,  1,-4 ],
                  [42,  3,-4 ],

                  [ 100,  2,7 ],
                  [ 101,  2,5 ],
                  #
                  [ 102, -2,5 ],
                  [ 103, -2,7 ],

                  [171, 8,8 ],
                ],

                [ { parts => 2 },
                  [  0,  0,1 ],
                  [  1,  1,1 ],
                  [  2, -1,1 ],

                  [  3,  1,2 ],
                  [  4, -1,2 ],

                  [  5,  2,2 ], # A
                  [  6, -2,2 ], # A

                  [  7,  2,1 ], # other
                  [  8,  2,3 ], # B
                  [  9, -2,3 ], # B
                  [ 10, -2,1 ], # other

                  [ 11,  3,1 ], #
                  [ 12,  3,3 ], #
                  [ 13,  1,3 ], #
                  [ 14, -1,3 ], #
                  [ 15, -3,3 ], #
                  [ 16, -3,1 ], #
                ],

                # [ { parts => 2 },
                #   [ 0,  0 ],
                #   [ 1,  1 ],
                #   [ 2,  3 ],
                #   [ 3,  5 ],
                #   [ 4,  7 ],
                #   [ 5, 11 ],
                #   [ 6, 17 ],
                #   [ 7, 21 ],
                #   [ 8, 23 ],
                #   [ 9, 27 ],
                #   [10, 33 ],
                #   [11, 39 ],
                #   [12, 47 ],
                #   [13, 61 ],
                #   [14, 77 ],
                #   [15, 85 ],
                #   [16, 87 ],
                # ],
                #
               );
  foreach my $group (@groups) {
    my ($options, @data) = @$group;
    my $path = Math::PlanePath::ToothpickTree->new (%$options);
    foreach my $elem (@data) {
      my ($n, $x,$y) = @$elem;

      if ($path->{'parts'} == 4) {
        my $got_n = $path->xy_to_n($x,$y);
        ok ($got_n, $n,
            "xy_to_n($x,$y) got_n=$got_n want_n=$n  ".join(',',%$options));
      }
      {
        my ($got_x,$got_y) = $path->n_to_xy($n);
        ok ($got_x, $x,
            "n_to_xy($n) X got=$got_x,$got_y want=$x,$y  ".join(',',%$options));
        ok ($got_y, $y,
            "n_to_xy($n) X got=$got_x,$got_y want=$x,$y  ".join(',',%$options));
      }
    }
  }
}

foreach my $parts (1 .. 4) {
  my $path = Math::PlanePath::ToothpickTree->new (parts => $parts);
  my $bad = 0;
  my %seen;
  foreach my $n (0 .. 50) {
    my ($x,$y) = $path->n_to_xy($n);
    if ($seen{"$x,$y"}++) {
      MyTestHelpers::diag ("n_to_xy($n)=$x,$y duplicate");
      last if $bad++ > 10;
    }
    my $rev_n = $path->xy_to_n($x,$y);
    if ($rev_n != $n) {
      MyTestHelpers::diag ("n_to_xy($n)=$x,$y reverse to $rev_n");
      last if $bad++ > 10;
    }
  }
}


#------------------------------------------------------------------------------
# _depth_to_octant_added()

{
  my $path = Math::PlanePath::ToothpickTree->new (parts => 'octant');

  my $bad = 0;
  my $depth = 0;
  foreach my $depth (2 .. 300) {
    my $n = $path->tree_depth_to_n($depth-2);
    my $next_n = $path->tree_depth_to_n($depth-1);
    my $want_add = $next_n - $n;
    my $got_add = Math::PlanePath::ToothpickTree::_depth_to_octant_added([$depth],[1],0);

    if ($got_add != $want_add) {
      MyTestHelpers::diag ("_depth_to_octant_added($depth) got $got_add want $want_add");
      last if $bad++ > 10;
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# tree_depth_to_n()

{
  my @groups = (
                # A153000 parts=1 total cells in level n
                [ { parts => 1 },
                  [  0,  0 ],   # +1                              [2]
                  [  1,  1 ],   # +1                              [3]
                  [  2,  2 ],   # +1 A                            [4]
                  [  3,  3 ],   # +2 B+other                      [5]
                  [  4,  5 ],   # +3                              [6]
                  [  5,  8 ],   # +2 2^k                          [7]
                  [  6,  10 ],  # +1 A                            [8]
                  [  7,  11 ],  # +2 B+other                      [9]
                  [  8,  13 ],  # +3 = add(1)+2*add(0) = 1+2*1=3  [10]=3,2
                  [  9,  16 ],  # +3 = add(2)+2*add(1) = 1+2*1=3  [11]
                  [ 10,  19 ],  # +4 = add(3)+2*add(2) = 2+2*1=4
                  [ 11,  23 ],  # +7 = add(4)+2*add(3) = 3+2*2=7
                  [ 12,  30 ],  # +8 = add(5)+2*add(4) = 2+2*3=8
                  [ 13,  38 ],  # +4 2^k
                  [ 14,  42 ],  # +1 A
                  [ 15,  43 ],  # +2 B+other
                  [ 16,  45 ],  # +3 add(1)+
                  [ 17,  48 ],  # +3 add(2)+
                  [ 18,  51 ],  # +4 add(3)+                      [20]
                  [ 19,  55 ],  # +7 add(4)+
                  [ 20,  62 ],  # +8 add(5)+
                  [ 21,  70 ],  # +5 = add(6)+2*add(5) = 1+2*2=5  [23]
                  [ 22,  75 ],
                  [ 23,  79 ],
                  [ 24,  86 ],
                  [ 25,  95 ],
                  [ 26, 105 ],
                  [ 27, 120 ],
                  [ 28, 142 ],  # +20 = add(13)+2*add(12) = 4+2*8=20
                  [ 29, 162 ],  # +8 2^k
                  [ 30, 170 ],  # +1 A
                  [ 31, 171 ],  # +2 B+other
                  [ 32, 173 ],
                ],

                # A152998 parts=2 total cells in level n
                [ { parts => 2 },
                  [ 0,  0 ],
                  [ 1,  1 ],
                  [ 2,  3 ],
                  [ 3,  5 ],
                  [ 4,  7 ],
                  [ 5, 11 ],
                  [ 6, 17 ],
                  [ 7, 21 ],
                  [ 8, 23 ],
                  [ 9, 27 ],
                  [10, 33 ],
                  [11, 39 ],
                  [12, 47 ],
                  [13, 61 ],
                  [14, 77 ],
                  [15, 85 ],
                  [16, 87 ],
                ],

                # A153006 parts=3 total cells in level n
                [ { parts => 3 },
                  [  0,  0 ],   #
                  [  1,  1 ],   #
                  [  2,  3 ],   #
                  [  3,  6 ],   #
                  [  4,  9 ],   #
                  [  5,  13 ],  #
                  [  6,  20 ],  #
                  [  7,  28 ],  #
                  [  8,  33 ],  #
                  [  9,  37 ],  #
                  [ 10,  44 ],  #
                  [ 11,  53 ],  #
                  [ 12,  63 ],  #
                  [ 13,  78 ],  #
                  [ 14, 100 ],  #
                  [ 15, 120 ],  #
                  [ 16, 129 ],  #
                ],

                # A139250 parts=4 total cells in level n
                [ { parts => 4 },
                  [ 0,  0 ], # +1  origin
                  [ 1,  1 ], # +2  up,down
                  [ 2,  3 ], # +4
                  [ 3,  7 ], # +4  2^k
                  [ 4, 11 ], # +4  A
                  [ 5, 15 ], # +8  B+other
                  [ 6, 23 ], # +12
                  [ 7, 35 ], # +8  2^k
                  [ 8, 43 ], # +4  1 A
                  [ 9, 47 ], # +8  2 B+other
                  [10, 55 ], # +12
                  [11, 67 ], # +12
                  [12, 79 ], # +16
                  [13, 95 ], # +28
                  [14,123 ],
                  [15,155 ], # +16 2^k
                  [16,171 ], # +4
                  [17,175 ], # +8
                  [18,183 ],
                ],
               );
  foreach my $group (@groups) {
    my ($options, @data) = @$group;
    my $path = Math::PlanePath::ToothpickTree->new (%$options);
    foreach my $elem (@data) {
      my ($depth, $want_n) = @$elem;
      my $got_n = $path->tree_depth_to_n ($depth);
      ok ($got_n, $want_n,
          "tree_depth_to_n() depth=$depth ".join(',',%$options));
    }
  }
}

#------------------------------------------------------------------------------
# tree_n_to_depth()

foreach my $parts (1 .. 4) {
  my $path = Math::PlanePath::ToothpickTree->new (parts => $parts);

  my $bad = 0;
  my $depth = 0;
  my $n = 0;
  my $next_n = 1;
 THIS_PART: while ($n < 200) {
    # MyTestHelpers::diag ("depth=$depth try n=$n to next_n=$next_n");
    for ( ; $n < $next_n; $n++) {
      my $got_depth = $path->tree_n_to_depth($n);
      if ($got_depth != $depth) {
        MyTestHelpers::diag ("parts=$parts n=$n got_depth=$got_depth want $depth (next_n=$next_n)");
        last THIS_PART if $bad++ > 10;
      }
    }
    $depth++;
    $next_n = $path->tree_depth_to_n($depth+1);
  }
  ok ($bad, 0);
}

exit 0;

#------------------------------------------------------------------------------
# tree_n_parent()
{
  my @data = ([ 1, undef ],

              [ 2,  1 ],
              [ 3,  1 ],
              [ 4,  1 ],
              [ 5,  1 ],

              [ 6,  2 ],
              [ 7,  3 ],
              [ 8,  4 ],
              [ 9,  5 ],

              [ 10,  6 ],
              [ 11,  6 ],
              [ 12,  6 ],
              [ 13,  7 ],
              [ 14,  7 ],
              [ 15,  7 ],
             );
  my $path = Math::PlanePath::ToothpickTree->new;
  foreach my $elem (@data) {
    my ($n, $want_n_parent) = @$elem;
    my $got_n_parent = $path->tree_n_parent ($n);
    ok ($got_n_parent, $want_n_parent);
  }
}

#------------------------------------------------------------------------------
# tree_n_children()
{
  my @data = ([ 1, '2,3,4,5' ],

              [ 2,  '6' ],
              [ 3,  '7' ],
              [ 4,  '8' ],
              [ 5,  '9' ],

              [ 6,  '10,11,12' ],
              [ 7,  '13,14,15' ],
              [ 8,  '16,17,18' ],
              [ 9,  '19,20,21' ],
             );
  my $path = Math::PlanePath::ToothpickTree->new;
  foreach my $elem (@data) {
    my ($n, $want_n_children) = @$elem;
    my $got_n_children = join(',',$path->tree_n_children($n));
    ok ($got_n_children, $want_n_children, "tree_n_children($n)");
  }
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::ToothpickTree->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}


#------------------------------------------------------------------------------
# parts=4 vs pointwise calculation

{
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  my @endpoints_x = (0);
  my @endpoints_y = (0);
  my @endpoints_dir = (2);
  my %xy_to_n = ('0,0' => 0);
  my $upto_depth = 1;
  my @n_to_x = (0);
  my @n_to_y = (0);
  my @n_to_depth = (0);

  sub extend {
    my @extend_x;
    my @extend_y;
    my @extend_dir;
    my %extend;
    foreach my $i (0 .. $#endpoints_x) {
      my $x = $endpoints_x[$i];
      my $y = $endpoints_y[$i];
      my $dir = ($endpoints_dir[$i] - 1) & 3;  # -90
      foreach (-1, 1) {
        my $x = $x + $dir4_to_dx[$dir];
        my $y = $y + $dir4_to_dy[$dir];
        my $key = "$x,$y";
        unless ($xy_to_n{$key}) {
          $extend{$key}++;
          push @extend_x, $x;
          push @extend_y, $y;
          push @extend_dir, $dir;
        }
        $dir ^= 2;  # +180
      }
    }
    @endpoints_x = ();
    @endpoints_y = ();
    @endpoints_dir = ();
    foreach my $i (0 .. $#extend_x) {
      my $x = $extend_x[$i];
      my $y = $extend_y[$i];
      my $key = "$x,$y";
      next if $extend{$key} > 1;
      push @endpoints_x, $x;
      push @endpoints_y, $y;
      push @endpoints_dir, $extend_dir[$i];
    }
    foreach my $i (0 .. $#endpoints_x) {
      my $x = $endpoints_x[$i];
      my $y = $endpoints_y[$i];
      push @n_to_x, $x;
      push @n_to_y, $y;
      push @n_to_depth, $upto_depth;
      $xy_to_n{"$x,$y"} = $#n_to_x;
    }
    $upto_depth++;
  }


  my $path = Math::PlanePath::ToothpickTree->new (parts => 4);
  my $n = 0;
  my $bad = 0;
  foreach (0 .. 20) {
    # MyTestHelpers::diag ("depth $_ to n=$#n_to_x");

    for ( ; $n < $#n_to_x; $n++) {
      {
        my ($path_x, $path_y) = $path->n_to_xy($n);
        my $calc_x = $n_to_x[$n];
        my $calc_y = $n_to_y[$n];
        if ($calc_x != $path_x || $calc_y != $path_y) {
          MyTestHelpers::diag ("calc n=$n path xy=$path_x,$path_y calc $calc_x,$calc_y");
          last if $bad++ > 10;
        }
      }

      {
        my $path_depth = $path->tree_n_to_depth($n);
        my $calc_depth = $n_to_depth[$n];
        unless ($path_depth == $calc_depth) {
          MyTestHelpers::diag ("calc n=$n path_depth=$path_depth calc $calc_depth");
          last if $bad++ > 10;
        }
      }
    }
    extend();
  }
  ok ($bad, 0);
}


#------------------------------------------------------------------------------
exit 0;
