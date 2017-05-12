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
plan tests => 234;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

# uncomment this to run the ### lines
# use Smart::Comments;

require Math::PlanePath::LCornerTree;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 18;
  ok ($Math::PlanePath::LCornerTree::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::LCornerTree->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::LCornerTree->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::LCornerTree->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::LCornerTree->new;
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

{
  my $path = Math::PlanePath::LCornerTree->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 3); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 15); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 63); }
}
{
  my $path = Math::PlanePath::LCornerTree->new (parts => 'octant');
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 0);
    ok ($n_hi, 0); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 0);
    ok ($n_hi, 2); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 0);
    ok ($n_hi, 9); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(3);
    ok ($n_lo, 0);
    ok ($n_hi, 35); }
}

#------------------------------------------------------------------------------
# tree_depth_to_n()

{
  my @groups = ([ [ parts => 'diagonal-1' ], # is parts=diagonal plus 2*depth
                  [ 7,  73 ],

                  [ 0,  0 ],
                  [ 1,  1 ],
                  [ 2,  4 ],
                  [ 3,  13 ],
                  [ 4,  22 ],
                  [ 5,  43 ],
                  [ 6,  52 ],
                  [ 7,  73 ],
                  [ 8,  94 ],
                ],
                [ [ parts => 'diagonal' ], # is parts=wedge plus parts=1
                  [ 0,  0 ],   # + 2+1 = 3
                  [ 1,  3 ],   # + 4+3 = 7
                  [ 2,  10 ],  # + 7
                  [ 3,  17 ],  # + 10+9 = 19
                  [ 4,  36 ],  # + 7
                  [ 5,  43 ],  # + 19
                  [ 6,  62 ],  # + 19
                  [ 7,  81 ],  # + 28+27 = 55
                  [ 8, 136 ],  #
                ],
                [ [ parts => 'wedge' ],
                  [ 0,  0 ],   # + 2
                  [ 1,  2 ],   # + 4
                  [ 2,  6 ],   # + 4
                  [ 3,  10 ],  # + 10
                  [ 4,  20 ],  # + 4
                  [ 5,  24 ],  # + 10
                  [ 6,  34 ],  # + 10
                  [ 7,  44 ],  # + 28
                  [ 8,  72 ],  #
                ],
                [ [ parts => 'octant' ],
                  [ 0,  0 ],   # + 1
                  [ 1,  1 ],   # + 2
                  [ 2,  3 ],   # + 2
                  [ 3,  5 ],   # + 5
                  [ 4,  10 ],  # + 2
                  [ 5,  12 ],  # + 5
                  [ 6,  17 ],  # + 5
                  [ 7,  22 ],  # + 14
                  [ 8,  36 ],  #
                ],
                [ [ parts => 1 ],
                  [ 0,  0 ],   # + 1
                  [ 1,  1 ],   # + 3
                  [ 2,  4 ],   # + 3
                  [ 3,  7 ],   # + 9
                  [ 4,  16 ],  # + 3
                  [ 5,  19 ],  # + 9
                  [ 6,  28 ],  # + 9
                  [ 7,  37 ],  # + 27
                  [ 8,  64 ],  #
                ],
                [ [ parts => 4 ],
                  [ 0,  0 ],   # + 4*1
                  [ 1,  4 ],   # + 4*3
                  [ 2,  16 ],  # + 4*3
                  [ 3,  28 ],  # + 4*9
                  [ 4,  64 ],  # + 4*3
                  [ 5,  76 ],
                  [ 6, 112 ],
                  [ 7, 148 ],
                  [ 8, 256 ],
                ]);
  foreach my $group (@groups) {
    my ($options, @data) = @$group;
    my $path = Math::PlanePath::LCornerTree->new (@$options);
    foreach my $elem (@data) {
      my ($depth, $n) = @$elem;
      {
        my $want_n = $n;
        my $got_n = $path->tree_depth_to_n ($depth);
        ok ($got_n, $want_n, "tree_depth_to_n() depth=$depth");
      }
      {
        my $want_depth = $depth;
        my $got_depth = $path->tree_n_to_depth ($n);
        ok ($got_depth, $want_depth, "@$options tree_n_to_depth() n=$n");
      }
      if ($depth > 0) {
        my $want_depth = $depth - 1;
        my $got_depth = $path->tree_n_to_depth ($n-1);
        ok ($got_depth, $want_depth, "@$options tree_n_to_depth() n=$n");
      }
    }
  }
}

#------------------------------------------------------------------------------
# tree_n_to_depth()

{
  my @groups = ([ { parts => 'wedge' },

                  [ 0,  0 ],
                  [ 1,  0 ],
                  [ 2,  1 ],
                  [ 3,  1 ],
                  [ 4,  1 ],
                  [ 5,  1 ],

                  [ 6,  2 ],
                  [ 7,  2 ],
                  [ 8,  2 ],
                  [ 9,  2 ],

                  [ 10, 3 ],
                  [ 11, 3 ],
                  [ 19, 3 ],

                  [ 20, 4 ],
                  [ 21, 4 ],
                ],

                [ { parts => 'octant' },

                  [ 0,  0 ],
                  [ 1,  1 ],
                  [ 2,  1 ],
                  [ 3,  2 ],
                  [ 4,  2 ],

                  [ 5,  3 ],
                  [ 6,  3 ],
                  [ 7,  3 ],
                  [ 8,  3 ],
                  [ 9,  3 ],

                  [ 10, 4 ],
                  [ 11, 4 ],
                  [ 12, 5 ],
                  [ 13, 5 ],
                  [ 14, 5 ],
                  [ 15, 5 ],
                  [ 16, 5 ],
                  [ 17, 6 ],
                ],
                [ { parts => 1 },
                  [ 0,  0 ],
                  [ 1,  1 ],
                  [ 2,  1 ],
                  [ 3,  1 ],
                  [ 4,  2 ],
                  [ 5,  2 ],
                  [ 6,  2 ],
                  [ 7,  3 ],
                  [ 8,  3 ],
                  [ 15, 3 ],

                  [ 16, 4 ],
                  [ 17, 4 ],
                  [ 18, 4 ],

                  [ 19, 5 ],
                ],
                [ { parts => 4 },
                  [ 0,  0 ],   # + 4*1
                  [ 1,  0 ],   # + 4*3
                  [ 2,  0 ],  # + 4*3
                  [ 3,  0 ],  # + 4*9
                  [ 4,  1 ],  # + 4*3
                  [ 5,  1 ],
                  [ 6,  1 ],,
                ]);
  foreach my $group (@groups) {
    my ($options, @data) = @$group;
    my $path = Math::PlanePath::LCornerTree->new (%$options);
    foreach my $elem (@data) {
      my ($depth, $want_n) = @$elem;
      my $got_n = $path->tree_n_to_depth ($depth);
      ok ($got_n, $want_n, "tree_n_to_depth() n=$depth ".join(',',%$options));
    }
  }
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
  my $path = Math::PlanePath::LCornerTree->new;
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
  my $path = Math::PlanePath::LCornerTree->new;
  foreach my $elem (@data) {
    my ($n, $want_n_children) = @$elem;
    my $got_n_children = join(',',$path->tree_n_children($n));
    ok ($got_n_children, $want_n_children, "tree_n_children($n)");
  }
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::LCornerTree->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}

