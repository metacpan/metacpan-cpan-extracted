#!/usr/bin/perl -w

# Copyright 2018, 2019 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 39825;

# uncomment this to run the ### lines
# use Smart::Comments;

require Graph::Maker::Catalans;


#------------------------------------------------------------------------------
{
  my $want_version = 15;
  ok ($Graph::Maker::Catalans::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Catalans->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Catalans->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Catalans->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Helpers

# A000108         n = 0  1  2  3   4   5    6    7     8
my @Catalan_number = (1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, 16796, 58786,
                      208012, 742900);

# A001006
my @Motzkin_number = (1, 1, 2, 4, 9, 21, 51, 127, 323, 835, 2188, 5798, 15511,
                      41835, 113634);

# $graph is a directed Graph.pm.
# Return the number of pairs of comparable elements $u,$v, meaning pairs
# where there is a path from $u to $v.  The count includes $u,$u empty path.
# For a lattice graph, this is the number of "intervals" in the lattice.
#
sub num_intervals {
  my ($graph) = @_;
  my $ret = 0;
  foreach my $v ($graph->vertices) {
    $ret += 1 + $graph->all_successors($v);
  }
  return $ret;
}

sub factorial {
  my ($n) = @_;
  my $ret = 1;
  foreach my $i (2 .. $n) {
    $ret *= $i;
  }
  return $ret;
}

sub binomial {
  my ($n,$k) = @_;
  if ($n < 0 || $k < 0) { return 0; }
  my $ret = 1;
  foreach my $i (1 .. $k) {
    $ret *= $n-$k+$i;
    ### assert: $ret % $i == 0
    $ret /= $i;
  }
  return $ret;
}
foreach my $n (0 .. 6) {
  foreach my $k (0 .. $n) {
    ok (binomial($n,$k), factorial($n)/factorial($n-$k)/factorial($k),
       "binomial $n,$k");
  }
}
ok (binomial(-1,-1), 0);

# Return a list of arrayrefs which are all balanced binary arrays of length
# 2*$n, so all in graph N = $n.
sub balanced_list {
  my ($n) = @_;
  my @ret;
  my @array = (1,0) x $n;
  do {
    push @ret, [@array];
  } while (Graph::Maker::Catalans::_balanced_next(\@array));
  return @ret;
}

# $aref is an arrayref of integers 0 or 1.
# Return the number of occurrences of 1,1 in the array.
sub array_count_11 {
  my ($aref) = @_;
  my $ret = 0;
  foreach my $i (0 .. $#$aref-1) {
    $ret += ($aref->[$i] && $aref->[$i+1]);
  }
  return $ret;
}

sub vpar_num_siblings_sets {
  my ($vpar) = @_;
  my %hash; @hash{@$vpar} = ();  # hash slice
  scalar(keys %hash);
}
ok(vpar_num_siblings_sets([0,0]), 1);
ok(vpar_num_siblings_sets([0,1]), 2);
ok(vpar_num_siblings_sets([0,0,0,0]), 1);
ok(vpar_num_siblings_sets([0,1,1,0]), 2);
ok(vpar_num_siblings_sets([0,1,2,3]), 4);

sub vpar_siblings_setsizes {
  my ($vpar) = @_;
  my @num_children;
  foreach my $p (@$vpar) {
    $num_children[$p]++;
  }
  return sort grep {$_} @num_children;
}
ok(join(',',vpar_siblings_setsizes([0,0])), '2');
ok(join(',',vpar_siblings_setsizes([0,1])), '1,1');
ok(join(',',vpar_siblings_setsizes([0,1,1])), '1,2');


#------------------------------------------------------------------------------
# Binary Trees
#
# Binary trees here are hashref with fields 'left' and 'right' for the
# subtrees, or undef for an empty tree or absent subtree.
#
#    { left => $binary_tree, right => $binary_tree }
#    undef

# $aref is a preorder balanced binary coding like [1,0,1,0].
# Return $binary_tree of that.
#
sub balanced_to_binary_tree {
  my ($aref) = @_;
  ### balanced_to_binary_tree(): join('',@$aref)

  # coding: 1, left, 0, right
  my $pos = 0;
  my $recurse;
  $recurse = sub {
    if ($pos > $#$aref || $aref->[$pos] == 0) {
      return undef;
    } else {
      $aref->[$pos++] == 1 || die "oops, expected 1";
      my $left = $recurse->();
      $aref->[$pos++] == 0 || die "oops, expected 0";
      my $right = $recurse->();
      return { left => $left, right => $right }
    }
  };
  $recurse->();
}
{
  my $aref = [1,0];
  my $binary_tree = balanced_to_binary_tree($aref);
  ok (defined $binary_tree, 1);
  ok (! defined $binary_tree->{left}, 1);
  ok (! defined $binary_tree->{right}, 1);
}

sub balanced_str_to_binary_tree {
  my ($str) = @_;
  return balanced_to_binary_tree([split //, $str]);
}

sub balanced_postorder_to_binary_tree {
  my ($aref) = @_;
  # coding: left 1 right 0
  my $pos = $#$aref;
  my $recurse;
  $recurse = sub {
    if ($pos < 0 || $aref->[$pos]==1) {
      return undef;
    } else {
      $aref->[$pos--] == 0 || die "oops, expected 0";
      my $right = $recurse->();
      $aref->[$pos--] == 1 || die "oops, expected 1";
      my $left = $recurse->();
      return { left => $left, right => $right }
    }
  };
  $recurse->();
}

{
  my @array = (1,0,1,0);
  my $array = join('',@array);
  my $binary_tree = balanced_to_binary_tree(\@array);
  ok (defined $binary_tree, 1);
  ok (! defined $binary_tree->{left}, 1);
  ok (defined $binary_tree->{right}, 1);
  ok (! defined $binary_tree->{right}->{left}, 1);
  ok (! defined $binary_tree->{right}->{right}, 1);

  my @again = binary_tree_to_preorder_balanced($binary_tree);
  ok (join('',@again), $array,
      "binary_tree_to_preorder_balanced() again 1010");

  my @postorder_again = binary_tree_to_balanced_postorder($binary_tree);
  ok (join('',@postorder_again), '1100',
      "binary_tree_to_balanced_postorder() again on array=1010");
}

sub binary_tree_to_parens {
  my ($binary_tree) = @_;
  if (defined $binary_tree) {
    return '(' . binary_tree_to_parens($binary_tree->{left})
      . ',' . binary_tree_to_parens($binary_tree->{right}) . ')';
  } else {
    return 'e';
  }
}

# $type = 'B','L','R'
# $order = 'pre','post','in'
sub binary_tree_to_depths {
  my ($binary_tree,$order,$type) = @_;
  my $dl = 0;
  my $dr = 0;
  if ($type eq 'B') {
    $dl = $dr = 1;
  } elsif ($type eq 'L') {
    $dl = 1;
  } elsif ($type eq 'R') {
    $dr = 1;
  } else {
    die "binary_tree_to_depths() unrecognised type: ",$type;
  }

  my $recurse;
  $recurse = sub {
    my ($binary_tree, $d) = @_;
    if (! defined $binary_tree) {
      return ();
    }
    my @l = $recurse->($binary_tree->{left},  $d + $dl);
    my @r = $recurse->($binary_tree->{right}, $d + $dr);
    if ($order eq 'pre') {
      return $d, @l, @r;
    } elsif ($order eq 'in') {
      return @l, $d, @r;
    } elsif ($order eq 'post') {
      return @l, @r, $d;
    } else {
      die "binary_tree_to_depths() unrecognised order: ",$order;
    }
  };
  return $recurse->($binary_tree,0);
}

# $type = 'B','L','R'
# $order = 'pre','post','in'
sub binary_tree_to_heights {
  my ($binary_tree,$order,$type) = @_;
  my $recurse;
  $recurse = sub {
    my ($binary_tree, $d) = @_;
    if (! defined $binary_tree) {
      return (-1);
    }
    my ($Lheight, @l) = $recurse->($binary_tree->{'left'});
    my ($Rheight, @r) = $recurse->($binary_tree->{'right'});
    my $h;
    if ($type eq 'L') {
      $h = $Lheight + 1;
    } elsif ($type eq 'R') {
      $h = $Rheight + 1;
    } else {
      die "binary_tree_to_heights() unrecognised type: ",$type;
    }

    if ($order eq 'pre') {
      return $h,  $h, @l, @r;
    } elsif ($order eq 'in') {
      return $h,  @l, $h, @r;
    } elsif ($order eq 'post') {
      return $h,  @l, @r, $h;
    } else {
      die "binary_tree_to_heights() unrecognised order: ",$order;
    }
  };
  my ($h, @ret) = $recurse->($binary_tree);
  return @ret;
}
{
  my $binary_tree = { left => undef, right => undef };
  foreach my $order ('pre','in','post') {
    foreach my $LR ('L','R') {
      ok (join(',',binary_tree_to_heights($binary_tree,$order,$LR)),
          '0');
    }
  }
}
{
  #        1
  #       /
  #      2
  #       \
  #        3
  #       /
  #      4
  my @array = (1,1,0,1,1,0,0,0);
  my $binary_tree = balanced_to_binary_tree(\@array);
  ok (join(',',binary_tree_to_heights($binary_tree,'pre','L')),
      '1,0,1,0');
}

{
  # subtree heights vectors not distinct
  my $N = 4;
  my %seen;
  foreach my $aref (balanced_list($N)) {
    my $binary_tree = balanced_to_binary_tree($aref);
    foreach my $order ('pre','in','post') {
      foreach my $LR ('L','R') {
        my $str = join(',',binary_tree_to_heights($binary_tree,$order,$LR));
        # print "$str\n";
        $seen{$order}->{$LR}->{$str}++;
      }
    }
  }
  my %want = (pre  => { L => 8,
                        R => 10 },      # short
              in   => { L => 10,
                        R => 10 },
              post => { L => 10,        # short
                        R => 8 });     # short
  foreach my $order ('pre','in','post') {
    foreach my $LR ('L','R') {
      my $href = $seen{$order}->{$LR};
      ok (scalar(keys %$href),
          $want{$order}->{$LR},
          "N=$N count distinct $order $LR");
    }
  }
}

# Set each $binary_tree->{'size'} to number of vertices at and below.
sub binary_tree_sizes {
  my ($binary_tree) = @_;
  if (defined $binary_tree) {
    return ($binary_tree->{'size'}
            = binary_tree_sizes($binary_tree->{'left'})
            + binary_tree_sizes($binary_tree->{'right'})
            + 1);
  } else {
    return 0;
  }
}


#------------------------------------------------------------------------------
# Canopy

sub binary_tree_to_canopy {
  my ($binary_tree) = @_;
  return (($binary_tree->{left} ? binary_tree_to_canopy($binary_tree->{left})
           : 'L'),
          ($binary_tree->{right} ? binary_tree_to_canopy($binary_tree->{right})
           : 'R'));
}
{
  # Canopy vectors 2^(N-1) distinct.
  #
  foreach my $N (0 .. 6) {
    my @arrays = balanced_list($N);
    my %seen;
    my $any_duplicate = 0;
    foreach my $i (0 .. $#arrays) {
      my $aref = $arrays[$i];
      my $binary_tree = balanced_to_binary_tree($aref);
      my @canopy = binary_tree_to_canopy($binary_tree);
      my $canopy = join('',@canopy);
      if ($seen{$canopy}++) {
        $any_duplicate = 1;
        # print join('',@$aref)," canopy $canopy\n";
      }
    }
    ok ($any_duplicate,
        ($N>=3 ? 1 : 0),
        "N=$N canopy duplicates when N>=3");
    # print scalar(keys %seen),"\n";
    ok (scalar(keys %seen),
        $N==0 ? 1 : 2**($N-1));
  }
}


#------------------------------------------------------------------------------
# _balanced_end()

{
  #            ( ( ( ( ) ) ( ) ) ( ) )  ( ( ( ) ) ( ) )
  my $aref = [ 1,1,1,1,0,0,1,0,0,1,0,0, 1,1,1,0,0,1,0,0 ];

  ok (Graph::Maker::Catalans::_balanced_end($aref, 0), 11);
  ok (Graph::Maker::Catalans::_balanced_end($aref, 1), 8);
  ok (Graph::Maker::Catalans::_balanced_end($aref, 2), 5);
  ok (Graph::Maker::Catalans::_balanced_end($aref, 3), 4);
  ok (Graph::Maker::Catalans::_balanced_end($aref, 6), 7);
}


#------------------------------------------------------------------------------
# dexter

# Chapoton section 6 theorem 6.1.
sub dexter_num_intervals {
  my ($n) = @_;
  return $n==0 ? 1 :  3 * 2**($n-1) * binomial(2*$n,$n) / ($n+1) / ($n+2);
}
# print join(',',map{dexter_num_intervals($_)} 1..10);
# 1,3,12,56,288,1584,9152,54912,339456,2149888
# A000257

# Return true if all right edges in $binary_tree are underneath a left child.
#            *
#           /
#          x               right edge x--y
#         / \              x is a left child
#            y
#           / \
sub binary_tree_all_right_are_under_left_child {
  # $is_left when top of $binary_tree is a left child
  my ($binary_tree, $is_left) = @_;
  ### binary_tree_all_right_are_under_left_child(): $is_left

  if (! defined $binary_tree) {
    return 1;
  }
  if ($binary_tree->{'right'} && ! $is_left) {
    return 0;
  }
  return binary_tree_all_right_are_under_left_child($binary_tree->{'left'}, 1)
    &&   binary_tree_all_right_are_under_left_child($binary_tree->{'right'});
}
sub dexter_predecessors {
  my ($aref) = @_;
  my @ret;
  foreach my $i (0 .. $#$aref-1) {
    if ($aref->[$i] && $aref->[$i+1]) {
      my $p = $i;
      while ($p > 0 && $aref->[$p-1]) { $p--; }   # preceding 1s
      my $j = Graph::Maker::Catalans::_balanced_end ($aref, $i+1);

      #  [0 or start] 1...1 1aaaa0
      #               p   i      j
      #               1aaaa0 11 ... 1
      ### predecessor: join('',@$aref)."  p=$p i=$i j=$j"
      push @ret, [ @{$aref}[0..$p-1],
                   @{$aref}[$i+1..$j],
                   @{$aref}[$p..$i],
                   @{$aref}[$j+1..$#$aref] ];
    }
  }
  return @ret;
}

{
  # directed
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'dexter',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    # A002054
    ok (scalar($graph->edges), binomial(2*$N-1,$N-2));
    ok (scalar($graph->edges), rotate_num_edges($N));

    ok (num_intervals($graph), dexter_num_intervals($N),
        "dexter num_intervals N=$N");

    # Chapoton proposition 1.4
    ok (scalar($graph->successorless_vertices),
        $N==0 ? 1 : $Motzkin_number[$N-1]);

    foreach my $v ($graph->vertices) {
      my $aref = [split //, $v];
      my $binary_tree = balanced_to_binary_tree($aref);
      ### $binary_tree
      ok ($graph->successors($v) == 0,
          !! binary_tree_all_right_are_under_left_child($binary_tree));

      my @predecessors = $graph->predecessors($v);
      ok (scalar(@predecessors), array_count_11($aref));
      my @by11 = dexter_predecessors($aref);
      ### @by11
      @by11 = map {join('',@$_)} @by11;
      ok (join(' ',sort @predecessors),
          join(' ',sort @by11));
    }

    # {
    #   # not in OEIS: 51,51,66,76,81,72,32
    #   my @count_by_out_degree;
    #   foreach my $v ($graph->vertices) {
    #     $count_by_out_degree[$graph->out_degree($v)]++;
    #   }
    #   foreach my $i (0 .. $#count_by_out_degree) {
    #     print " ",$count_by_out_degree[$i] || 0;
    #   }
    #   print "\n";
    # }
    # {
    #   # not in OEIS: 5,72,100,99,81,46,19,6,1
    #   my @count_by_degree;
    #   foreach my $v ($graph->vertices) {
    #     $count_by_degree[$graph->out_degree($v) + $graph->in_degree($v)]++;
    #   }
    #   foreach my $i (0 .. $#count_by_degree) {
    #     print " ",$count_by_degree[$i] || 0;
    #   }
    #   print "\n";
    # }
  }
}
# No, "modern" intervals.
# {
#   # directed, balanced_postorder
#   foreach my $N (4) {
#     my $graph = Graph::Maker->new('Catalans', N => $N,
#                                   rel_type => 'dexter',
#                                   vertex_name_type => 'balanced_postorder');
#     ok (scalar($graph->vertices), $Catalan_number[$N]);
#
#     foreach my $v ($graph->vertices) {
#       $v =~ /0*$/;
#       my $right_vertices = length($&);
#       my $all_successors = $graph->all_successors($v);
#       print "$v  $right_vertices  $all_successors\n";
#     }
#   }
# }


#------------------------------------------------------------------------------
# _vertex_name_type_run0s()

{
  foreach my $N (0 .. 8) {
    my @arrays = balanced_list($N);
    foreach my $i (0 .. $#arrays) {
      my $aref = $arrays[$i];
      my @run0s = Graph::Maker::Catalans::_vertex_name_type_run0s($aref);

      {
        # Shown in the POD:
        #   run0s[i] = Ldepths[i] + 1 - Ldepths[i+1]
        my @Ldepths = (Graph::Maker::Catalans::_vertex_name_type_Ldepths($aref),
                       0);
        my @diffs = map {$Ldepths[$_]+1 - $Ldepths[$_+1]}
          0 .. $N-1;
        ok (join(',',@run0s), join(',',@diffs),
            '_vertex_name_type_run0s() vs _vertex_name_type_Ldepths() diffs');
      }
    }
  }
}


#------------------------------------------------------------------------------
# _vertex_name_type_run1s()

# Return a list of number of left edges above each external vertex, going
# left to right (in-order).
# A right-child external has 0 left edges above.
sub binary_tree_to_left_edges_above {
  my ($binary_tree) = @_;
  my $recurse;
  $recurse = sub {
    my ($binary_tree, $above) = @_;
    if (defined $binary_tree) {
      return ($recurse->($binary_tree->{'left'},  $above+1),
              $recurse->($binary_tree->{'right'}, 0));
    } else {
      return ($above);
    }
  };
  return $recurse->($binary_tree, 0);
}

{
  foreach my $N (0 .. 8) {
    my $i = 0;
    my @arrays = balanced_list($N);
    foreach my $i (0 .. $#arrays) {
      my $aref = $arrays[$i];
      my @run1s = Graph::Maker::Catalans::_vertex_name_type_run1s($aref);

      {
        # Per POD, run1s sum-k = Ldepths_inorder
        my @Ldepths_inorder
          = Graph::Maker::Catalans::_vertex_name_type_Ldepths_inorder($aref);
        my @by_sum;
        my $total = 0;
        foreach my $i (0 .. $#run1s) {
          $total += $run1s[$i];
          $by_sum[$i] = $total - $i - 1;  # 1-based i
        }
        ok (join(',',@by_sum), join(',',@Ldepths_inorder),
            '_vertex_name_type_run1s() sum vs _vertex_name_type_Ldepths_inorder()');
      }
      my $binary_tree = balanced_to_binary_tree($aref);
      {
        # Per POD, runs1s num left edges above
        my @left_edges_above = binary_tree_to_left_edges_above($binary_tree);
        ok (@left_edges_above >= 1, 1);
        pop @left_edges_above;
        ok (join(',',@run1s), join(',',@left_edges_above),
            '_vertex_name_type_run1s() sum vs binary_tree_to_left_edges_above()');
      }
    }
  }
}


#------------------------------------------------------------------------------
# E. Makinen, "A Survey on Binary Tree Codings", The Computer Journal,
# volume 34, number 5, 1991.

{
  # Figure 1.
  #            6
  #         /     \       in-order
  #       4        10
  #      / \      /
  #     2   5    8
  #    / \      / \
  #   1   3    7   9

  # Section 4.2 Zak's Sequences
  #            ( ( ( ( ) ) ( ) ) ( ) )  ( ( ( ) ) ( ) )
  my @array = (1,1,1,1,0,0,1,0,0,1,0,0, 1,1,1,0,0,1,0,0);

  # Section 4.1 Level Sequences
  ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Bdepths_inorder(\@array)),
      '3,2,3,1,2,0,3,2,3,1');

  # Section 4.3 P-Sequence
  # at each 0 num 1s preceding
  # '4,4,5,5,6,6,9,9,10,10'

  # Section 4.5.1 L-Sequences
  # '6,4,2,1,1,1,4,2,1,1'
  # Inorder labelled Lweights, maybe?

  # Section 5 Codings Based on Rotation
  # d(ui)
  ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rdepths_inorder(\@array)),
      '0,0,1,0,1,0,1,1,2,1');

  # Section 5 Codings Based on Rotation
  # Zerling 0,0,1,0,1,0,1,0,2,1

  # 0,0,1                 0,0,1, 0,1
  #     3        2              5          4
  #    /  ->    / \            /   ->     / \
  #   2        1   3          4          2   5
  #  /                       /          / \
  # 1                       2          1   3
  # 111000     110010      / \
  #                       1   3         1 110010 010
  #                       11 110010 00

  # 0,0,1, 0,1, 0,1, 0,2
  #             9
  #            /
  #           8                   8
  #          /                   / \
  #         6                   6   9              6
  #        / \                 / \                /  \
  #       4   7               4   7              4     8
  #      / \                 / \                / \   /  \
  #     2   5               2   5              2   5  7   9
  #    / \                 / \                / \
  #   1   3               1   3              1   3
  # 11 11110010010010 00                    111100100100 110010
  #                     1 11110010010010 010
  #                       (((())())())

  # 1 2 3  4 5  6 7  8 9 10
  # 0,0,1, 0,1, 0,1, 0,2, 1
  #           10
  #           /
  #          6                        6
  #         /  \                    /   \
  #        4     8                4      10    (1)
  #       / \   /  \             / \     /
  #      2   5  7   9           2   5   8     (0)
  #     / \                    / \     /  \
  #    1   3                  1   3   7    9
  #                                  (1)  (2)
  #
}

#------------------------------------------------------------------------------
# Joan Lucas, Dominique Roelants van Baronaigien, Frank Ruskey, "On
# Rotations and the Generation of Binary Trees", Journal of Algorithms,
# volume 15, 1993, pages 343-366.
# http://webhome.cs.uvic.ca/~ruskey/Publications/Rotation/Rotation.html

{
  #          *          Figure 7.
  #        /   \
  #      *      *       Weights  1,2,1,2,3,6,1,1,2,1  = Lweights
  #     / \      \      Distance 0,0,1,1,1,0,1,2,2,3  = Rdepths_inorder
  #    *   *      *
  #       /      / \    Zerling  00 111 00 103
  #      *      *   *
  #     /
  #    *

  #            ( ( ( ) ) ( ( ( ) ) ) )  ( ) ( ( ) ) ( )
  my @array = (1,1,1,0,0,1,1,1,0,0,0,0, 1,0,1,1,0,0,1,0);

  ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Lweights(\@array)),
      '1,2,1,2,3,6,1,1,2,1');

  # Makinen, at i number of proper ancestors in T[1..i]
  ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rdepths_inorder(\@array)),
      '0,0,1,1,1,0,1,2,2,3');

  my @unrotate = @array;
  my @Z = (0,0, 1,1,1, 0,0, 1,0,3);
  ok (scalar(@Z), scalar(@array)/2);
  # my $pos = $#unrotate;
  # foreach my $z (reverse 0 .. $#Z) {
  #   while ($unrotate[$pos]==0) { $pos--; }
  #   Graph::Maker::Catalans::_rotate_at( ... );
  # }
}
{
  # Table 1 Equivalences

  # Bitstring RP preorder of extended tree, 1 for internal, 0 for external.

  my @table = (['0000', '1111', '0123', '11110000'],
               ['0001', '1112', '0122', '11101000'],
               ['0002', '1113', '0121', '11100100'],
               ['0003', '1114', '0120', '11100010'],
               ['0010', '1121', '0112', '11011000'],
               ['0011', '1123', '0111', '11010100'],
               ['0012', '1124', '0110', '11010010'],
               ['0020', '1131', '0101', '11001100'],
               ['0021', '1134', '0100', '11001010'],
               ['0100', '1211', '0012', '10111000'],
               ['0101', '1212', '0011', '10110100'],
               ['0102', '1214', '0010', '10110010'],
               ['0110', '1231', '0001', '10101100'],
               ['0111', '1234', '0000', '10101010']);
  ok (scalar(@table), 14);


  # No, the table is not correspondences, just the possible strings in their
  # own lex order.

  # foreach my $elem (@table) {
  #   my ($Z,$P,$M,$RP) = @$elem;
  #   my @RP = split //, $RP;
  #
  #   # ok (join('',Graph::Maker::Catalans::_vertex_name_type_...(\@RP)),
  #   #     $Z);
  #
  #   ok (join('',Graph::Maker::Catalans::_vertex_name_type_Rweights(\@RP)),
  #       $P,
  #       "table P of RP=$RP");
  #   ok (join('',Graph::Maker::Catalans::_vertex_name_type_Ldepths_inorder(\@RP)),
  #       $M,
  #       "table M of RP=$RP");
  # }
}


#------------------------------------------------------------------------------
# rotate_Bempty = Central Rotate

{
  # POD example
  #       ---> 101100               N => 3
  #      /                          rel_type => "rotate_Bempty"
  # 101010 --> 110010 --> 111000
  #                       ^
  #            110100 ---/

  my $graph = Graph::Maker->new('Catalans', N => 3,
                                rel_type=>'rotate_Bempty');
  my $example = Graph->new;
  $example->add_edges(['101010','101100'],
                      ['101010','110010'],

                      ['110010','111000'],
                      ['110100','111000']);
  ok ("$graph","$example");
}

{
  # Pallo figure 8 example
  #
  #              1111
  #            /   |   \
  #  1113  1121  1112  1211   1131           1114
  #    \    /       \  /   \  /   \         /    \
  #     1123        1212   1231   1134   1214    1124
  #                            \    |   /
  #                               1234

  my $graph = Graph::Maker->new('Catalans', N => 4,
                                rel_type=>'rotate_Bempty',
                                vertex_name_type => 'Lweights',
                                comma => '');
  my $example = Graph->new;
  $example->add_edges(['1111','1121'],
                      ['1111','1112'],
                      ['1111','1211'],

                      ['1113','1123'],
                      ['1121','1123'],

                      ['1112','1212'],
                      ['1211','1212'],
                      ['1211','1231'],
                      ['1131','1231'],
                      ['1131','1134'],

                      ['1114','1214'],
                      ['1114','1124'],

                      ['1231','1234'],
                      ['1134','1234'],
                      ['1214','1234'],
                     );
  ok ("$graph","$example");
}

{
  # directed
  foreach my $N (0 .. 6) {
    my $graph = Graph::Maker->new('Catalans',
                                  N => $N,
                                  rel_type => 'rotate_Bempty',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    # edge reversal mirror image
    foreach my $edge ($graph->edges) {
      ok (!! $graph->has_edge(reverse map {balanced_str_transpose($_)} @$edge),
          1);
    }
  }
}
{
  # directed
  foreach my $N (0 .. 6) {
    my $graph = Graph::Maker->new('Catalans',
                                  N => $N,
                                  rel_type => 'rotate_Bempty',
                                  vertex_name_type=>'Lweights',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    # num edges 0, 0, 1, 4, 15, 56, 210 = A001791
    ok (scalar($graph->edges), binomial(2*$N-2, $N-2));

    my $num_predecessorless = $graph->predecessorless_vertices;
    ok ($num_predecessorless,
        $N==0 ? 1 : $Motzkin_number[$N-1]);
    ok ($num_predecessorless,
        scalar($graph->successorless_vertices));

    ok (scalar($graph->predecessorful_vertices),
        scalar($graph->successorful_vertices));

    foreach my $edge ($graph->edges) {
      my ($from,$to) = @$edge;
      my @from = split /,/, $from;
      my @to   = split /,/, $to;

      # Per Pallo, edges are where a 1 increases.
      my $num_diffs = 0;
      my $diff_at;
      foreach my $i (0 .. $N-1) {
        if ($from[$i] != $to[$i]) {
          $num_diffs++;
          $diff_at = $i;
        }
      }
      ok ($num_diffs, 1);
      ok ($from[$diff_at], 1);
      ok ($to[$diff_at] != 0,  1);
    }
  }
}


#------------------------------------------------------------------------------
# _vertex_name_type_balanced_postorder()

{
  my $aref = [1, 1,1,0,0, 0, 1,1,0,0];
  my @postorder = Graph::Maker::Catalans::_vertex_name_type_balanced_postorder($aref);
  ok (join('',@postorder), '1010110100');
}
{
  my $aref = [1,0,1,0,1,0,1,0];
  my @postorder = Graph::Maker::Catalans::_vertex_name_type_balanced_postorder($aref);
  ok (join('',@postorder), '11110000');
}
{
  my $aref = [1,0,1,0];
  my @postorder = Graph::Maker::Catalans::_vertex_name_type_balanced_postorder($aref);
  ok (join('',@postorder), '1100');
}
{
  #          1
  #         / \
  #        2   e     preorder   110100_0
  #       / \        postorder  0_001101
  #      e   3                  1_110010
  #         / \
  #        e   e
  #              left       empty right
  my $aref = [1, 1,0,1,0, 0 ];
  my $binary_tree = balanced_to_binary_tree($aref);
  ok (  defined $binary_tree->{left}, 1);
  ok (! defined $binary_tree->{right}, 1);
  ok (! defined $binary_tree->{left}->{left}, 1);
  ok (  defined $binary_tree->{left}->{right}, 1);
  ok (! defined $binary_tree->{left}->{right}->{left}, 1);
  ok (! defined $binary_tree->{left}->{right}->{right}, 1);

  ok (join('',binary_tree_to_preorder_balanced($binary_tree->{left})), '1010');
  ok (join('',binary_tree_to_balanced_postorder($binary_tree->{left})), '1100');
  ok (join('',binary_tree_to_preorder_balanced($binary_tree->{right})), '');
  ok (join('',binary_tree_to_balanced_postorder($binary_tree->{right})), '');

  ok (join('',binary_tree_to_preorder_balanced($binary_tree)), '110100');
  ok (join('',binary_tree_to_balanced_postorder($binary_tree)), '110010');

  my $want_postorder = '110010';
  my @postorder = vertex_name_type_balanced_postorder_by_tree($aref);
  ok (join('',@postorder), $want_postorder);
  @postorder = Graph::Maker::Catalans::_vertex_name_type_balanced_postorder($aref);
  ok (join('',@postorder), $want_postorder);
}
{
  #            e   right
  my $aref = [1,0, 1, 1,0,1,0, 0];
  my @postorder = Graph::Maker::Catalans::_vertex_name_type_balanced_postorder($aref);
  ok (join('',@postorder), '11100100');
}
#Graph::Maker::Catalans::_vertex_name_type_balanced_postorder([1,0,1,0]);
#Graph::Maker::Catalans::_vertex_name_type_balanced_postorder([1,1,0,0]);

# like _vertex_name_type_balanced_postorder() but done by binary tree
sub vertex_name_type_balanced_postorder_by_tree {
  my ($aref) = @_;
  my $binary_tree = balanced_to_binary_tree($aref);
  return binary_tree_to_balanced_postorder($binary_tree);
}

{
  foreach my $N (0 .. 6) {
    my $i = 0;
    my @arrays = balanced_list($N);
    foreach my $i (0 .. $#arrays) {
      my $aref = $arrays[$i];
      my $binary_tree = balanced_to_binary_tree($aref);
      my @preorder_by_tree = binary_tree_to_preorder_balanced($binary_tree);
      ok(join('',@preorder_by_tree), join('',@$aref));

      my @postorder_by_tree = binary_tree_to_balanced_postorder($binary_tree);
      my @postorder_by_func = Graph::Maker::Catalans::_vertex_name_type_balanced_postorder($arrays[$i]);
      ok(join('',@postorder_by_tree), join('',@postorder_by_func));

      # print "a ",join('',@array),"\n";
      # print "t ",join('',@preorder_by_tree),"\n";
      # print "  ",join('',@postorder_by_tree),"\n";
      # print "  ",join('',@postorder_by_func),"\n";
      # print "\n";
    }
  }
}


#------------------------------------------------------------------------------
# _vertex_name_type_bracketing()

{
  {
    my @ret = Graph::Maker::Catalans::_vertex_name_type_bracketing([]);
    ok(join('',@ret), '1');
  }
  {
    my @ret = Graph::Maker::Catalans::_vertex_name_type_bracketing([1,0]);
    ok(join('',@ret), '(12)');
    ok(join(',',@ret), '(1,2)');
  }
  {
    #       *
    #      / \             balanced 1010
    #     1   *            balanced_postorder 1100
    #        / \
    #       2   3
    my $aref = [1,0,1,0];
    my @ret = Graph::Maker::Catalans::_vertex_name_type_bracketing($aref);
    ok(join('',@ret), '(1(23))');
    ok(join(',',@ret), '(1(2,3))');
  }
  {
    #         *
    #        / \
    #       *   3          balanced 1100
    #      / \             balanced_postorder 1010
    #     1   2
    my $aref = [1,1,0,0];
    my @ret = Graph::Maker::Catalans::_vertex_name_type_bracketing($aref);
    ok(join('',@ret), '((12)3)');
    ok(join(',',@ret), '((1,2)3)');
    ok (join('', Graph::Maker::Catalans::_vertex_name_type_balanced_postorder($aref)),
        '1010');;
  }

  #            *
  #          /   \                balanced 11100100
  #         *      5
  #       /   \
  #      *      *
  #     / \    / \
  #    1   2  3   4
  #             (  ( ( ) ) ( ) )
  my @array = ( 1, 1,1,0,0,1,0,0 );
  {
    my @ret = Graph::Maker::Catalans::_vertex_name_type_bracketing(\@array);
    ok(join('',@ret), '(((12)(34))5)');
    ok(join(',',@ret), '(((1,2)(3,4))5)');
  }
  {
    my @ret = Graph::Maker::Catalans::_vertex_name_type_bracketing_reduced(\@array);
    ok(join('',@ret), '((12)(34))5');
    ok(join(',',@ret), '((1,2)(3,4))5');
  }
}

# No, bracketings with externals omitted is not unique.
# {
#   foreach my $N (0 .. 8) {
#     my $i = 0;
#     my @arrays = balanced_list($N);
#     my %seen;
#     foreach my $i (0 .. $#arrays) {
#       my $aref = $arrays[$i];
#       my @bracketing
#         = Graph::Maker::Catalans::_vertex_name_type_bracketing($aref);
#       my $bracketing = join('',@bracketing);
#       $bracketing =~ tr/0-9//d;
#       $bracketing =~ tr/()/10/;
#       print "$bracketing  from ",join('',@$aref),"\n";
#
#       ok (!$seen{$bracketing}++, 1, $bracketing);
#       # my @balanced_postorder
#       #   = Graph::Maker::Catalans::_vertex_name_type_balanced($aref);
#       # my $balanced_postorder = join('', @balanced_postorder);
#       # ok ($bracketing, $balanced_postorder,
#       #    join(',',@bracketing));
#     }
#   }
# }


#------------------------------------------------------------------------------
# rotate_first

sub rotate_first_pos {
  my ($aref) = @_;
  ### rotate_first_pos(): join(',',@$aref)

  # Jean Marcel Pallo, "Rotational Tree Structures on Binary Trees and
  # Triangulations", Acta Cybernetica, volume 17, 2006, pages 799-810.
  # Section 3 conditions for T -> T'.

  foreach my $i (1 .. $#$aref) {
    if ($aref->[$i] == 1) {

      foreach my $k (0 .. $i-1) {
        ok ($aref->[$k], $k+1,
            "i=$i initial k=$k of ".join(',',@$aref));
      }

      ### $i
      foreach my $j (reverse $i .. $#$aref) {
        ### try: "j=$j is $aref->[$j] diff ".($j - $aref->[$j])
        if ($j - $aref->[$j] + 1 == $i) {
          return $j;
        }
      }
      die "oops no j found ",join(',',@$aref);;
    }
  }
  return undef;
}
sub rotate_first_Lweights {
  my ($aref) = @_;
  my $pos = rotate_first_pos($aref);
  if (! defined $pos) { return undef; }

  my @new_array = @$aref;
  $new_array[$pos] = $pos+1;
  return \@new_array;
}

{
  foreach my $N (0 .. 4) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_first',
                                  vertex_name_type=>'Lweights');
    ok (scalar($graph->vertices), $Catalan_number[$N]);
    ok (scalar($graph->edges),    $Catalan_number[$N] - 1);

    if ($N <= 4) {
      # LW change in first possible element
      foreach my $from ($graph->vertices) {
        ok ($graph->out_degree($from) <= 1, 1);
        my @successors = $graph->successors($from);
        ok (@successors <= 1, 1);
        my $got_to = $successors[0];

        my @from = split /,/, $from;
        {
          my $pos = rotate_first_pos(\@from);
          my $to_aref = rotate_first_Lweights(\@from);
          my $to;
          if ($to_aref) {
            $to = join(',',@$to_aref);
            ok (!! $graph->has_vertex($to), 1);
          }
          ok ($got_to, $to, "first rotate RW edge from $from");
        }

        # {
        # POS: foreach my $pos (0 .. $#from) {
        #     foreach my $offset (1 .. $N) {
        #       my @to = @from;
        #       $to[$pos] += $offset;
        #       my $to = join(',',@to);
        #       if ($graph->has_vertex($to)) {
        #         ok ($got_to, $to, "first rotate RW edge from $from");
        #         last POS;
        #       }
        #     }
        #   }
        # }
      }
    }
  }
}

{
  # Jean Marcel Pallo, "Rotational Tree Structures on Binary Trees and
  # Triangulations", Acta Cybernetica, volume 17, 2006, pages 799-810.
  # Figure 4.

  my $graph = Graph->new;
  $graph->add_path('1121', '1131', '1231', '1234');
  $graph->add_path('1111', '1211', '1231');
  $graph->add_path('1123', '1124', '1134', '1234');
  $graph->add_path('1112', '1212', '1214', '1234');
  $graph->add_path('1113', '1114', '1214');
  ok (scalar($graph->vertices), 14);

  my $catalans = Graph::Maker->new('Catalans', N => 4,
                                   rel_type => 'rotate_first',
                                   vertex_name_type => 'Lweights',
                                   comma => '');
  ok ("$graph", "$catalans");
}
{
  # Jean Marcel Pallo, "Rotational Tree Structures on Binary Trees and
  # Triangulations", Acta Cybernetica, volume 17, 2006, pages 799-810.
  # Figure 5.

  my $graph = Graph->new;
  $graph->add_path('11231', '11241', '11341', '12341', '12345');
  $graph->add_path('11131', '11141', '12141', '12341');
  $graph->add_path('11121', '12121', '12141');
  $graph->add_path('11211', '11311', '12311', '12341');
  $graph->add_path('11111', '12111', '12311');

  $graph->add_path('11134', '11135', '11145', '12145', '12345');
  $graph->add_path('11123', '12123', '12125', '12145');
  $graph->add_path('11124', '11125', '12125');

  $graph->add_path('11234', '11235', '11245', '11345', '12345');

  $graph->add_path('11112', '12112', '12312', '12315', '12345');
  $graph->add_path('11212', '11312', '12312');
  $graph->add_path('11113', '12113', '12115', '12315');
  $graph->add_path('11114', '11115', '12115');
  $graph->add_path('11214', '11215', '11315', '12315');
  ok (scalar($graph->vertices), 42);

  my $catalans = Graph::Maker->new('Catalans', N => 5,
                                   rel_type => 'rotate_first',
                                   vertex_name_type => 'Lweights',
                                   comma => '');
  ok ("$graph", "$catalans");
}


#------------------------------------------------------------------------------
# rotate = Tamari

# F. Chapoton. "Sur le Nombre d'Intervalles Dans Les Treillis De Tamari",
# Sem. Lothar. Combin., 55, 2006.  As given in Bernardi and Bonichon.
# A000260  3,13,68,399,2530,16965,118668,857956,6369883,
#
# C. Germain and J. Pallo, "The Number of Coverings In Four Catalan
# Lattices", Intern. J. Computer Math., volume 61, 1996, pages 19-28.
#
sub rotate_num_intervals {
  my ($n) = @_;
  return 2 * factorial(4*$n+1)
    / factorial($n+1) / factorial(3*$n+2);
}
# foreach my $n (2..10) { print rotate_num_intervals($n),","; }
# print "\n";

sub rotate_num_intervals_by_binomial {
  my ($n) = @_;
  return binomial(4*$n+3,$n+1) * 2 / (4*$n+3) / (4*$n+2);
}
sub rotate_num_intervals_by_binomial2 {
  my ($n) = @_;
  return binomial(4*$n+1,$n+1) * 2 / (3*$n+1) / (3*$n+2);
}
sub rotate_num_edges {
  my ($n) = @_;
  return $n==0 ? 0 : ($n-1)/2*$Catalan_number[$n];
}

{
  # directed
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    # A002054
    ok (scalar($graph->edges), binomial(2*$N-1,$N-2));
    ok (scalar($graph->edges), rotate_num_edges($N));

    ok (num_intervals($graph), rotate_num_intervals($N),
        "rotate num_intervals N=$N");
    ok (rotate_num_intervals_by_binomial($N), rotate_num_intervals($N),
        "rotate_num_intervals_by_binomial N=$N");
    ok (rotate_num_intervals_by_binomial2($N), rotate_num_intervals($N),
        "rotate_num_intervals_by_binomial2 N=$N");

    my $first = '10'x$N;
    my $last  = ('1'x$N) . ('0'x$N);
    ok (!!$graph->has_vertex($first), 1);
    ok (!!$graph->has_vertex($last), 1);
    if ($N <= 5) {  # Graph.pm bit slow for big N
      ok ($graph->path_length($first,$last), ($N==0 ? 0 : $N-1),
          "rotate N=$N, path length first to last");
    }

    foreach my $v ($graph->vertices) {
      my @array = split //, $v;
      ok (scalar($graph->predecessors($v)),
          array_count_11(\@array));
    }
  }
}

{
  # D. D. Sleator, R. E.Tarjan, W. P. Thurston, "Rotation Distance,
  # Triangulations, and Hyperbolic Geometry", Journal of the American
  # Mathematical Society, volume 1, number 3, 1988, pages 647-681.
  #
  # And slides: # Danny Sleator, Bob Tarjan, "Our Work With Bill on Lengths
  # of Graph Transformations"
  #
  # Computer search d(n).
  #           n =   3             10                      18
  #           N = 0 1 2 3 4 5 6 7
  my @diameter = (0,0,1,2,4,5,7,9,11,12,14,16,18,20,22,24,26);
  #                                  |--->  2n-10
  # d(n) <= 2n-10 for all n>12.  Improving Culik and Wood 2n-6.
  # d(n) = 2n-10 for all n > some unknown point.
  #
  # their n=4 is diam=1 path-2 here N=2
  # for n>12 have diam <=2n-10 so here <=2N-6 for N>10
  # vector(8,n,n--; 2*n-6)
  #
  # Tamari diameter = 2N-6 for


  # undirected
  foreach my $N (2 .. 6) {
    my $graph = Graph::Maker->new('Catalans', N => $N, undirected=>1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    # N-1 regular
    ok (scalar($graph->edges), ($N-1)/2*$Catalan_number[$N]);
    foreach my $v ($graph->vertices) {
      ok ($graph->degree($v), $N-1, "rotate degree N=$N");
    }

    ok ($graph->diameter || 0, $diameter[$N], "rotate diameter N=$N");
  }
}

{
  # directed postorder sizes one change in one element,
  # by adding its preceding
  foreach my $N (0 .. 6) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  vertex_name_type=>'Lweights',
                                  countedged => 1);

    my $num_edges = 0;
    foreach my $from ($graph->vertices) {
      my @from = split /,/, $from;
      foreach my $pos (0 .. $#from) {
        foreach my $sign (1) {
          foreach my $offset (1 .. $N) {
            my @to = @from;
            $to[$pos] += $sign*$offset;
            my $to = join(',',@to);
            if ($graph->has_vertex($to)) {
              ok ($offset, $from[$pos-$from[$pos]],
                  "postorder sizes offset by adding preceding sibling");
              ok (!! $graph->has_edge($from,$to), 1,
                  "postorder sizes edge $from to $to");
              $num_edges++;
              last;
            }
          }
        }
      }
    }
    ok ($num_edges, scalar($graph->edges));
  }
}


#------------------------------------------------------------------------------
# Samuel W. Bent, "Ranking Trees Generated by Rotations"

sub is_balanced {
  my ($aref) = @_;
  my $d = 0;
  foreach my $bit (@$aref) {
    $d += ($bit ? 1 : -1);
    if ($d < 0) { return 0; }
  }
  $d == 0;
}
{
  #            6 5 1    3 2     4       12 8 7     11 10 9         13
  my @array = (1,1,1,0, 1,1,0,0,1,0,0,0, 1,1,1,0,0, 1, 1,1,0,0,0,0, 1,0);
  ok (is_balanced(\@array), 1);

  # ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rweights(\@array)),
  #     'xxxx');
}


#------------------------------------------------------------------------------
# split = Kreweras

{
  # 10110100       10110100
  # 11100100       10111000
  # ^^^^              ^^^
  my @array = (1,0,1,1,0,1,0,0);
  my @ret = Graph::Maker::Catalans::_rel_type_split(\@array);
  ok (scalar(@ret), 2);
  ok (join('',@{$ret[0]}), '11100100');
  ok (join('',@{$ret[1]}), '10111000');
}

# G. Kreweras, "Sur les Partitions Non-Croisees d'Un Cycle", Discrete
# Mathematics, volume 1, number 4, 1972, pages 333-350.
# As given in Bernardi and Bonichon ...
# A001764
sub split_num_intervals {
  my ($n) = @_;
  return binomial(3*$n,$n) / (2*$n+1);
}
# foreach my $n (2..10) { print split_num_intervals($n),","; }
# print "\n";exit;

{
  # directed
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'split',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    # A002694 binomial(2n,n-2)
    # vector(10,n, binomial(2*n,n-2))
    ok (scalar($graph->edges), binomial(2*$N, $N-2),
        "split num edges N=$N");

    ok (num_intervals($graph), split_num_intervals($N),
        "split num_intervals N=$N");

    my $first = '10'x$N;
    my $last  = ('1'x$N) . ('0'x$N);
    ok (!!$graph->has_vertex($first), 1);
    ok (!!$graph->has_vertex($last), 1);
    if ($N <= 5) {
      ok ($graph->path_length($first,$last), ($N==0 ? 0 : $N-1),
          "split N=$N, path length first to last");
    }
  }
}
sub setsize_to_num_noncrossing_splits {
  my ($setsize) = @_;
  return $setsize*($setsize-1)/2;
}
ok (setsize_to_num_noncrossing_splits(2), 1);
ok (setsize_to_num_noncrossing_splits(3), 3);  # 1,2 1_1_1 2,1

sub setsizes_to_num_noncrossing_splits {
  my ($setsizes) = @_;
  my $total = 0;
  foreach my $setsize (@$setsizes) {
    $total += setsize_to_num_noncrossing_splits($setsize);
  }
  return $total;
}
ok (setsizes_to_num_noncrossing_splits([2,3]), 1+3);

{
  # directed vpar
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'split',
                                  vertex_name_type => 'vpar',
                                  countedged => 1);
    foreach my $v ($graph->vertices) {
      my @vpar = split /,/, $v;
      my @setsizes = vpar_siblings_setsizes(\@vpar);
      ok (setsizes_to_num_noncrossing_splits(\@setsizes),
          scalar($graph->successors($v)));

      # if ($N>0 && vpar_num_siblings_sets(\@vpar)-1 != scalar($graph->predecessors($v))) {
      #   print "$v  num ",vpar_num_siblings_sets(\@vpar),"\n";
      #   foreach my $p ($graph->predecessors($v)) {
      #     print " from $p\n";
      #   }
      #   print vpar_num_siblings_sets(\@vpar)-1," ",scalar($graph->predecessors($v)),"\n";
      #   print "top ",Graph_lattice_highest($graph),"\n";
      #   exit;
      # }
    }
  }
}
{
  # undirected
  # A002694 binomial(2n,n-2)
  my @want_edges = (0,0, 1,6,28,120,495,2002,8008,31824,125970,497420);

  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'split',
                                  undirected => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);
    ok (scalar($graph->edges), $want_edges[$N]);
  }
}

# $vpar = arrayref, entries 0..N-1 representing 1..N.
# Return a list of arrayrefs of sibling sets.
sub vpar_siblings_sets {
  my ($vpar) = @_;
  my @sets;
  foreach my $v (0 .. $#$vpar) {
    push @{$sets[$vpar->[$v]]}, $v+1;
  }
  @sets = grep {defined $_} @sets;  # non-empties
  return sort {$a->[0] <=> $b->[0]} @sets;
}

# $sets is an arrayref of arrayrefs, being a partition of 1..N.
# Return 1 if it is a non-crossing partition.
sub sets_is_noncrossing {
  my ($sets) = @_;
  my @limits = (999999);
  my $prev_start = -1;
  foreach my $set (@$sets) {
    if ($set->[0] <= $prev_start) {
      die "oops, sets not ascending order";
    }
    while ($set->[0] > $limits[-1]) {
      pop @limits;
    }
    if ($set->[-1] > $limits[-1]) {
      return 0;
    }
    push @limits, $set->[-1];
  }
  return 1;
}
ok (sets_is_noncrossing([[1,4],[2,3]]), 1);
ok (sets_is_noncrossing([[1,3],[2,4]]), 0);
ok (sets_is_noncrossing([[1,2,3,5],[4,6,7,8]]), 0);
ok (sets_is_noncrossing([[1,2,3,4],[5,6,7,8]]), 1);
ok (sets_is_noncrossing([[1,8],[2,7],[3,6],[4,5]]), 1);

{
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'split',
                                  vertex_name_type => 'vpar');
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    foreach my $from ($graph->vertices) {
      my @from_vpar = split /,/,$from;
      my @from_sets = vpar_siblings_sets(\@from_vpar);
      ok(scalar(@from_sets), vpar_num_siblings_sets(\@from_vpar));
      ok(sets_is_noncrossing(\@from_sets), 1);
      foreach my $to ($graph->successors($from)) {
        my @to_vpar = split /,/,$to;
        my @to_sets = vpar_siblings_sets(\@to_vpar);
        ok(scalar(@from_sets) + 1,  scalar(@to_sets),
           "split siblings sets $from to $to");
      }
    }
  }
}


#------------------------------------------------------------------------------
# rotate_leftarm

{
  my @array = (1,0,1,0,1,0);
  my @ret = Graph::Maker::Catalans::_rel_type_rotate_leftarm(\@array);
  ok (scalar(@ret), 1);
  # ### @ret
}
{
  #            0   2     5
  my @array = (1,1,0,1,0,0,1,0);
  my @ret = Graph::Maker::Catalans::_rel_type_rotate_leftarm(\@array);
  ok (scalar(@ret), 2);
  # ### @ret
}

{
  # directed
  foreach my $N (0 .. 4) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_leftarm',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);
    ok (scalar($graph->edges), rotate_rightarm_num_edges($N),
        "rotate_leftarm num edges N=$N");

    # foreach my $from (sort $graph->vertices) {
    #   print "$from\n";
    #   foreach my $to (sort $graph->successors($from)) {
    #     print "  $to\n";
    #   }
    # }
  }
}

foreach my $N (0 .. 7) {
  my $rightarm = Graph::Maker->new('Catalans', N => $N,
                                   rel_type => 'rotate_rightarm');
  my $leftarm = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_leftarm',
                                  rel_direction => 'down');
  foreach my $edge ($leftarm->edges) {
    my @mirrored = map{balanced_str_transpose($_)} @$edge;
    ok (!!$rightarm->has_edge(@mirrored), 1);
  }
  # foreach my $edge ($rightarm->edges) {
  #   my @mirrored = map{balanced_str_transpose($_)} @$edge;
  #   ok (!!$leftarm->has_edge(@mirrored), 1);
  # }
}


#------------------------------------------------------------------------------
# rotate_rightarm

# rotate_rightarm_num_edges() returns the number of edges in rotate_rightarm
# graph.
# A002057 (different offset)
# Recurrence R(n) = sum(k=1,n-1, (R(k)+C(k))*R(n-k-1)) where C(n)=Catalan number.
#
sub rotate_rightarm_num_edges {
  my ($n) = @_;
  return binomial(2*$n-1, $n-2) * 4/($n+2);
}

{
  # directed

  my @A127632_samples   # OFFSET=0,  intervals
    = (1, 1, 3, 11, 44, 185, 804, 3579, 16229, 74690, 347984, 1638169);

  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_rightarm',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    # 0,0,1,4,14,48,165,572
    ok (scalar($graph->edges), rotate_rightarm_num_edges($N),
        "rotate_rightarm num edges N=$N");

    my @predecessorless_vertices = $graph->predecessorless_vertices;
    ok (scalar(@predecessorless_vertices), 1,
        'rotate_rightarm predecessorless_vertices count');
    ok ($predecessorless_vertices[0], '10'x$N,
        'rotate_rightarm predecessorless_vertices is 10101010');

    my @successorless_vertices = $graph->successorless_vertices;
    ok (scalar(@successorless_vertices),
        $N==0 ? 1 : $Catalan_number[$N-1],
        'rotate_rightarm successorless_vertices count');

    # A127632 c(x*c(x)), where c(x) = Catalans gf
    # 11, 44, 185, 804, 3579
    # ENHANCE-ME: Some binomial formula ?
    ok (num_intervals($graph), $A127632_samples[$N],
        "rotate_rightarm num_intervals N=$N");
    #
    # David Callan, "A Combinatorial Interpretation of the Catalan Transform
    # of the Catalan Numbers", http://arxiv.org/abs/1111.0996

  }
}
{
  # undirected
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_rightarm',
                                  undirected => 1,
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);
    ok (!!$graph->is_cyclic,  $N>=4);
  }
}


#---------------------------------
# rotate_rightarm
#
# Sebastian A. Csar, Rik Sengupta, Warut Suksompong, "On a Subposet of the
# Tamari Lattice", Information Processing Letters, volume 87, number 4,
# August 2003, pages 173-177
# https://arxiv.org/abs/1108.5690
# https://hal.archives-ouvertes.fr/hal-01283111
# http://dx.doi.org/10.1007/s11083-013-9305-5

{
  # Figure 2 tree.
  #        *                       (1 ( ((23)4) ((56)7)))
  #       /  \            reduced   1   ((23)4)  (56)7
  #      1     *
  #         /    \        reduced by deleting parens enclosing last
  #        *        *
  #       / \      / \
  #      *   4    *   7
  #     / \      / \
  #    2   3    5   6
  my @array = (1,0, 1,1,1,0,0,0, 1,1,0,0);
  {
    my @ret = Graph::Maker::Catalans::_vertex_name_type_bracketing(\@array);
    ok(join('',@ret), '(1(((23)4)((56)7)))');
    ok(join(',',@ret), '(1(((2,3)4)((5,6)7)))');
  }
  {
    my @ret = Graph::Maker::Catalans::_vertex_name_type_bracketing_reduced(\@array);
    ok(join('',@ret), '1((23)4)(56)7');
    ok(join(',',@ret), '1((2,3)4)(5,6)7');
  }
}
{
  # Figure 3, C5

  my $graph = Graph->new;
  $graph->add_edges(['12345', '(12)345'],
                    ['12345', '1(23)45'],
                    ['12345', '12(34)5'],

                    ['(12)345', '((12)3)45'],
                    ['(12)345', '(12)(34)5'],
                    ['1(23)45', '(1(23))45'],
                    ['1(23)45', '1((23)4)5'],
                    ['12(34)5', '(12)(34)5'],
                    ['12(34)5', '1(2(34))5'],

                    ['((12)3)45', '(((12)3)4)5'],
                    ['(1(23))45', '((1(23))4)5'],
                    ['(12)(34)5', '((12)(34))5'],
                    ['1((23)4)5', '(1((23)4))5'],
                    ['1(2(34))5', '(1(2(34)))5'],
                   );
  # print "$graph\n";
  my $catalans = Graph::Maker->new('Catalans', N => 4,
                                   rel_type => 'rotate_rightarm',
                                   vertex_name_type => 'bracketing_reduced',
                                   comma => '');
  ok (scalar($catalans->vertices), 14);
  ok (scalar($graph->vertices), 14);
  foreach my $v ($graph->vertices) {
    ok ($catalans->has_vertex($v), 1, "has_vertex  $v  ");
  }
  ok (scalar($graph->edges), 14);
  ok (scalar($catalans->edges), 14);
  foreach my $edge ($graph->edges) {
    ok ($catalans->has_edge(@$edge), 1,
        'has_edge  '.join('  ',@$edge).'  ');
  }
  ok ("$graph", "$catalans");
}


#---------------------------------
# rotate_rightarm

{
  # Rik Sengupta and Warut Suksompong, "The Comb Poset and the Parsewords
  # Function".
  # http://www-users.math.umn.edu/~reiner/REU/SenguptaSuksompong2010.pdf


  my %num_to_bracketing = (0  => '123456',

                           1  => '1(23)456',
                           2  => '123(45)6',
                           3  => '(12)3456',
                           4  => '12(34)56',

                           5  => '1((23)4)56',
                           6  => '(1(23))456',
                           7  => '1(23)(45)6',
                           8  => '12(3(45))6',
                           9  => '(12)3(45)6',
                           10 => '((12)3)456',
                           11 => '(12)(34)56',
                           12 => '12((34)5)6',
                           13 => '1(2(34))56',

                           14 => '(1((23)4))56',
                           15 => '1(((23)4)5)6',
                           16 => '((1(23))4)56',
                           17 => '(1(23))(45)6',
                           18 => '1((23)(45))6',
                           19 => '1(2(3(45)))6',
                           20 => '(12)(3(45))6',
                           21 => '((12)3)(45)6',
                           22 => '(((12)3)4)56',
                           23 => '((12)(34))56',
                           24 => '(12)((34)5)6',
                           25 => '1(2((34)5))6',
                           26 => '(1(2(34)))56',
                           27 => '1((2(34))5)6',

                           28 => '((1((23)4))5)6',
                           29 => '(1(((23)4)5))6',
                           30 => '(((1(23))4)5)6',
                           31 => '((1(23))(45))6',
                           32 => '(1((23)(45)))6',
                           33 => '(1(2(3(45))))6',
                           34 => '((12)(3(45)))6',
                           35 => '(((12)3)(45))6',
                           36 => '((((12)3)4)5)6',
                           37 => '(((12)(34))5)6',
                           38 => '((12)((34)5))6',
                           39 => '(1(2((34)5)))6',
                           40 => '((1(2(34)))5)6',
                           41 => '(1((2(34))5))6');
  ok (scalar(keys %num_to_bracketing), 42);

  my %bracketing_to_num = reverse %num_to_bracketing;
  ok (scalar(keys %bracketing_to_num), 42);
  # foreach my $i (0 .. 41) {
  #   foreach my $j ($i+1 .. 41) {
  #     if ($numbering{$i} eq $numbering{$j}) {
  #       die "duplicate $i $j";
  #     }
  #   }
  # }

  my @paths = ([0,1,5,14,28],
               [5,15,29],
               [1,6,16,30],
               [6,17,31],
               [1,7,17],

               [0,2,7,18,32],
               [2,8,19,33],
               [8,20,34],
               [2,9,20],

               [0,3,9,21,35],
               [3,10,21],
               [10,22,36],
               [3,11,23,37],

               [0,4,11,24,38],
               [4,12,24],
               [12,25,39],
               [4,13,26,40],
               [13,27,41]);

  my $graph = Graph->new (multiedged => 1);  # multiedged to catch duplication
  my $total_paths = 0;  # total edges resulting from paths
  foreach my $path (@paths) {
    $graph->add_path(map {$num_to_bracketing{$_}} @$path);
    $total_paths += $#$path;
  }
  ok (scalar($graph->vertices), 42);
  my $want_num_edges = rotate_rightarm_num_edges(5);
  ok (scalar($graph->edges), $want_num_edges);
  ok ($total_paths, $want_num_edges);

  # print "$graph\n";
  my $catalans = Graph::Maker->new('Catalans', N => 5,
                                   rel_type => 'rotate_rightarm',
                                   vertex_name_type => 'bracketing_reduced',
                                   comma => '');
  foreach my $v ($graph->vertices) {
    ok ($catalans->has_vertex($v), 1, "has_vertex  $v  ");
  }
  foreach my $edge ($graph->edges) {
    ok ($catalans->has_edge(@$edge), 1, 'has_edge  '.join('  ',@$edge).'  ');
  }
  foreach my $edge ($catalans->edges) {
    ok ($graph->has_edge(@$edge), 1,
        'has_edge  '.join('  ',@$edge).'  '
        . join(',',map{$bracketing_to_num{$_}}@$edge));
  }
  ok ("$graph", "$catalans");
}



#------------------------------------------------------------------------------
# _vertex_name_type_Lweights()
# _vertex_name_type_Rweights()

#    1      2  in-order          1       1  pre-order
#     \    /                      \     /
#      2  1                        2   2
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Lweights([1,0,1,0])), '1,1');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Lweights([1,1,0,0])), '1,2');

ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rweights([1,0,1,0])), '2,1');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rweights([1,1,0,0])), '1,1');

ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rweights([1,0,1,0,1,0])), '3,2,1');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rweights([1,1,1,0,0,0])), '1,1,1');

#       1
#      / \
#     0   1
#        /
#       1
#      / \
#     0   0
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rweights([1,0,1,1,0,0])), '3,1,1');

#         1
#       /   \       111000 111000 111000
#     1      1      1,1,6, 1,1,3, 1,1,1
#    / 0   /   \
#   1     1     1
#  0 0   / 0   / x
#       1     1
#      0 0   / 0
#           1
#          0 0
#
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rweights
         ([1,1,1,0,0,0, 1,1,1,0,0,0, 1,1,1,0,0,0])),
    '1,1,7,1,1,4,1,1,1');

#       1
#     /   \       1,1,0,0,1,0
#    1     1
#   0 0   0 x
#
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Lweights([1,1,0,0,1,0])),
    '1,2,1');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rweights([1,1,0,0,1,0])),
    '1,2,1');

# $side = string "left" or "right"
# Weight at a vertex is the vertex itself plus size of its $side subtree.
# Weights returned are in-order traversal of the vertices.
sub binary_tree_to_weights {
  my ($binary_tree, $side) = @_;
  binary_tree_sizes($binary_tree);
  my @ret;
  my $recurse;
  $recurse = sub {
    my ($binary_tree) = @_;
    if (defined $binary_tree) {
      $recurse->($binary_tree->{'left'});
      ### $binary_tree
      push @ret, 1 + (defined $binary_tree->{$side}
                      && $binary_tree->{$side}->{'size'});
      $recurse->($binary_tree->{'right'});
    }
  };
  $recurse->($binary_tree);
  return @ret;
}

# Lweights is subtree sizes of postorder labelled forest.
sub Lweights_by_vpar_postorder {
  my ($aref) = @_;
  my @vpar = Graph::Maker::Catalans::_vertex_name_type_vpar_postorder($aref);
  my @sizes = (1) x scalar(@vpar);
  foreach my $i (0 .. $#vpar-1) {
    if (my $p = $vpar[$i]) {
      $sizes[$p-1] += $sizes[$i];
    }
  }
  return @sizes;
}

# Return a copy of $binary_tree with left and right subtrees swapped at each
# vertex.
sub binary_tree_transpose {
  my ($binary_tree) = @_;
  if (defined $binary_tree) {
    return { left  => binary_tree_transpose($binary_tree->{'right'}),
             right => binary_tree_transpose($binary_tree->{'left'})
           };
  } else {
    return undef;
  }
}
sub balanced_str_transpose {
  my ($str) = @_;
  my @array = split //, $str;
  my $binary_tree = balanced_to_binary_tree(\@array);
  $binary_tree = binary_tree_transpose($binary_tree);
  @array = binary_tree_to_preorder_balanced($binary_tree);
  return join('',@array);
}

# Rweights is Lweights of transpose, with weights reversed so left to right.
sub Rweights_by_transpose {
  my ($binary_tree) = @_;
  return reverse binary_tree_to_weights(binary_tree_transpose($binary_tree),
                                        'left');
}

# Ro-Yu Wu, Jou-Ming Chang, Yue-Li Wang, "A Linear Time Algorithm for Binary
# Tree Sequences Transformation Using Left-arm and Right-arm Rotations".
# Algorithm LW-sequence-to-RW-sequence.
sub Lweights_to_Rweights {
  my ($Lweights) = @_;
  my $n = scalar(@$Lweights);
  my @Lweights = (undef, @$Lweights);   # 1-based to match published algorithm
  my @Rweights = (undef, (0) x $n);
  foreach my $i (reverse 1 .. $n) {
    if (! $Rweights[$i]) {
      $Rweights[$i] = 1;
    }
    my $p = $i - $Lweights[$i];
    if ($p > 0 && $Rweights[$p]==0) {
      $Rweights[$p] = $Lweights[$i] + $Rweights[$i];
    }
  }
  return @Rweights[1..$n];
}

{
  foreach my $N (0 .. 8) {
    my $i = 0;
    my @arrays = balanced_list($N);
    foreach my $i (0 .. $#arrays) {
      my $aref = $arrays[$i];
      my $binary_tree = balanced_to_binary_tree($aref);

      my @Lweights_by_binary_tree
        = binary_tree_to_weights($binary_tree, 'left');
      {
        my @by_vpar = Lweights_by_vpar_postorder($aref);
        ok (join(',',@by_vpar), join(',',@Lweights_by_binary_tree),
            'Lweights_by_vpar_postorder() vs binary_tree_to_weights()');

        my @by_func = Graph::Maker::Catalans::_vertex_name_type_Lweights($aref);
        ok (join(',',@by_func), join(',',@Lweights_by_binary_tree),
            '_vertex_name_type_Lweights() vs binary_tree_to_weights()');
      }

      my @Rweights_by_binary_tree
        = binary_tree_to_weights($binary_tree, 'right');
      {
        # print join('',@array),"\n";
        my @by_transpose = Rweights_by_transpose($binary_tree);
        ok (join(',',@by_transpose), join(',',@Rweights_by_binary_tree),
            'Rweights_by_transpose() vs binary_tree_to_weights()');

        my @by_func = Graph::Maker::Catalans::_vertex_name_type_Rweights($aref);
        ok (join(',',@by_func), join(',',@Rweights_by_binary_tree),
            '_vertex_name_type_Rweights() vs binary_tree_to_weights()');

        my @by_convert = Lweights_to_Rweights(\@Lweights_by_binary_tree);
        ok (join(',',@by_convert), join(',',@Rweights_by_binary_tree),
            'Lweights_to_Rweights()');
      }
    }
  }
}


#------------------------------------------------------------------------------
# flip = Stanley

sub diff_one_entry_by_one {
  my ($from,$to) = @_;
  my $diffs = 0;
  foreach my $i (0 .. $#$from) {
    if ($from->[$i] == $to->[$i]) {
      # good
    } elsif ($from->[$i] + 1 == $to->[$i]) {
      $diffs++;
    } else {
      return 0;
    }
  }
  return $diffs==1;
}

{
  # A002054 binomial(2n+1,n-1)
  my @want_edges = (0,0, 1,5,21,84,330,1287,5005,19448,75582,293930,1144066);

  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'flip',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);
    ok (scalar($graph->edges), $want_edges[$N]);
  }
}

{
  # directed
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'flip',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    # A002054
    ok (scalar($graph->edges), binomial(2*$N-1,$N-2));

    ok (scalar($graph->predecessorless_vertices), 1);

    my $start = '10'x$N;
    my $end   = ('1'x$N) . ('0'x$N);
    ok (!!$graph->has_vertex($start), 1);
    ok (!!$graph->has_vertex($end), 1);
    if ($N <= 5) {
      ok ($graph->path_length($start,$end), $N*($N-1)/2,
          "flip N=$N, path length start to end");
    }
  }
}

{
  # directed
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'flip',
                                  vertex_name_type => 'Ldepths',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    foreach my $from ($graph->vertices) {
      my @from = split /,/,$from;

      # all successors are one pos depth +1
      foreach my $to ($graph->successors($from)) {
        my @to = split /,/,$to;
        ok(diff_one_entry_by_one(\@from,\@to), 1,
           "flip change $from to $to");
      }

      # each possible pos depth +1
      foreach my $pos (1 .. $#from) {
        if ($from[$pos] <= $from[$pos-1]) {
          my @to = @from;
          $to[$pos]++;
          my $to = join(',',@to);
          ok($graph->has_edge($from,$to), 1,
             "flip edge $from to $to");
        }
      }
    }
  }
}

{
  # Knuth fasc4a section 7.2.1.6 exercise 28 figure 41 Stanley lattice order 4
  # in preorder Ldepths.
  my $graph = Graph->new;
  $graph->add_edges(['0000', '0001'],
                    ['0000', '0010'],
                    ['0000', '0100'],

                    ['0001', '0011'],
                    ['0001', '0101'],
                    #
                    ['0010', '0011'],
                    ['0010', '0110'],
                    #
                    ['0100', '0101'],
                    ['0100', '0110'],

                    ['0011', '0012'],
                    ['0011', '0111'],
                    #
                    ['0101', '0111'],
                    #
                    ['0110', '0111'],
                    ['0110', '0120'],

                    ['0012', '0112'],
                    #
                    ['0111', '0112'],
                    ['0111', '0121'],
                    #
                    ['0120', '0121'],

                    ['0112', '0122'],
                    ['0121', '0122'],

                    ['0122', '0123'],
                   );

  my $catalans = Graph::Maker->new('Catalans', N => 4,
                                   rel_type => 'flip',
                                   vertex_name_type => 'Ldepths',
                                   comma => '');
  ok (scalar($graph->vertices), 14);
  ok ($graph eq $catalans, 1);
}


#------------------------------------------------------------------------------
# rotate_last

{
  # directed
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_last',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);
    ok (scalar($graph->edges),    $Catalan_number[$N] - 1);

    # goes to a common end
    my @successorless_vertices = $graph->successorless_vertices;
    ok (scalar(@successorless_vertices), 1,
       'rotate_last successorless_vertices count');
    ok ($successorless_vertices[0], ('1'x$N).('0'x$N),
       'rotate_last successorless_vertices is 10101010');
  }
}


#------------------------------------------------------------------------------
# rotate_Aempty

sub is_edge_subgraph {
  my ($graph, $subgraph) = @_;
  foreach my $edge ($subgraph->edges) {
    $graph->has_edge(@$edge) or return 0;
  }
  return 1;
}
sub set_is_equal {
  my ($aref1, $aref2) = @_;
  return join($;, sort @$aref1) eq join($;, sort @$aref2);
}
ok(  set_is_equal(['a','b'], ['b','a']), 1);
ok(! set_is_equal(['a'],     ['b','a']), 1);

sub set_intersection {
  my %hash;
  @hash{@{(shift)}} = ();   # hash slice from aref
  foreach my $aref (@_) {
    my %new_hash;
    @new_hash{grep {exists $hash{$_}} @$aref} = ();
    %hash = %new_hash;
  }
  return [ keys %hash ];
}
{
  my $intersect = set_intersection(['a','b'], ['b','c']);
  ok(join(',',@$intersect), 'b');
}

{
  # directed

  my @want_successorless = (1, 1,1,2,4,9,21,51);  # Motzkin A001006 of n-1

  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_Aempty',
                                  countedged => 1);
    ok (scalar($graph->vertices), $Catalan_number[$N]);

    my @predecessorless_vertices = $graph->predecessorless_vertices;
    ok (scalar(@predecessorless_vertices), 1,
        'rotate_Aempty predecessorless_vertices count');
    ok ($predecessorless_vertices[0], '10'x$N,
        'rotate_Aempty predecessorless_vertices is 10101010');

    my @successorless_vertices = $graph->successorless_vertices;
    ok (scalar(@successorless_vertices), $want_successorless[$N],
        'rotate_Aempty successorless_vertices count');

    {
      # rotate_Aempty is edge subgraph of rotate
      my $rotate = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate');
      ok(is_edge_subgraph($rotate,$graph));

      # rotate_Aempty is edge subgraph of flip
      my $flip = Graph::Maker->new('Catalans', N => $N,
                                   rel_type => 'flip');
      ok(is_edge_subgraph($flip,$graph));

      # rotate_Aempty is edge intersection of rotate and flip
      foreach my $v ($graph->vertices) {
        my @successors = $graph->successors($v);
        my $intersect = set_intersection([$rotate->successors($v)],
                                         [$flip->successors($v)]);
        ok(set_is_equal(\@successors, $intersect), 1);
      }
    }
  }
}
{
  # N=3 directed equal to rotate_last
  my $Cempty = Graph::Maker->new('Catalans', N => 3,
                                 rel_type => 'rotate_Cempty');
  my $last   = Graph::Maker->new('Catalans', N => 3,
                                 rel_type => 'rotate_last');
  ok("$Cempty", "$last");
}


#------------------------------------------------------------------------------
# _vertex_name_type_Ldepths()
# _vertex_name_type_Ldepths_inorder()
# _vertex_name_type_Rdepths_inorder()
# _vertex_name_type_Bdepths_inorder()
# _vertex_name_type_Rdepths_postorder()


ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Ldepths([])), '');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Ldepths([1,0])), '0');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Ldepths([1,0,1,0])), '0,0');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Ldepths([1,1,0,0])), '0,1');

ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rdepths_inorder([])), '');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rdepths_inorder([1,0])), '0');

#    1        2      in-order
#     \      /
#      2    1
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rdepths_inorder([1,0,1,0])), '0,1');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rdepths_inorder([1,1,0,0])), '0,0');

ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Bdepths_inorder([])), '');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Bdepths_inorder([1,0])), '0');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Bdepths_inorder([1,0,1,0])), '0,1');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Bdepths_inorder([1,1,0,0])), '1,0');

#
#     1      post-order
#    / \
#   e   2
#      / \
#     3   e
#    / \
#   e   e
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rdepths_postorder([1,0,1,1,0,0])), '1,1,0');
#
#    2        2     post-order
#     \      /
#      1    1
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rdepths_postorder([1,0,1,0])), '1,0');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_Rdepths_postorder([1,1,0,0])), '0,0');

# Same as _vertex_name_type_Ldepths() but calculated from positions of 1s.
sub Ldepths_by_pos1s {
  my ($aref) = @_;

  # $i position of 1-bit
  # scalar(@ret) many preceding 1s
  # $i - scalar(@ret) many preceding 0s
  # net depth = scalar(@ret) - ($i - scalar(@ret))
  my @ret;
  foreach my $i (0 .. $#$aref) {
    if ($aref->[$i]) {
      push @ret, 2*scalar(@ret) - $i;
    }
  }
  return @ret;
}

{
  foreach my $N (0 .. 4) {
    my @arrays = balanced_list($N);
    foreach my $i (0 .. $#arrays) {
      my $aref = $arrays[$i];
      my $binary_tree = balanced_to_binary_tree($aref);
      {
        my @by_binary_tree = binary_tree_to_depths($binary_tree,'pre','L');
        my @by_pos1s = Ldepths_by_pos1s($aref);
        my @by_func = Graph::Maker::Catalans::_vertex_name_type_Ldepths($aref);
        ok (join(',',@by_func),
            join(',',@by_binary_tree),
            '_vertex_name_type_Ldepths() vs binary_tree_to_depths()');
        ok (join(',',@by_func),
            join(',',@by_pos1s),
            '_vertex_name_type_Ldepths() vs Ldepths_by_pos1s()');
      }

      {
        my @by_binary_tree = binary_tree_to_depths($binary_tree,'in','L');
        my @by_func = Graph::Maker::Catalans::_vertex_name_type_Ldepths_inorder($aref);
        ok (join(',',@by_func), join(',',@by_binary_tree),
            '_vertex_name_type_Ldepths_inorder() vs binary_tree_to_depths()');
      }
      {
        my @by_binary_tree = binary_tree_to_depths($binary_tree,'in','R');
        my @by_func = Graph::Maker::Catalans::_vertex_name_type_Rdepths_inorder($aref);
        ok (join(',',@by_func),
            join(',',@by_binary_tree),
            '_vertex_name_type_Rdepths_inorder() vs binary_tree_to_depths()');
      }
      {
        my @by_binary_tree = binary_tree_to_depths($binary_tree,'in','B');
        my @by_func = Graph::Maker::Catalans::_vertex_name_type_Bdepths_inorder($aref);
        ok (join(',',@by_func),
            join(',',@by_binary_tree),
            '_vertex_name_type_Bdepths_inorder() vs binary_tree_to_depths()');
      }

      {
        my @by_binary_tree = binary_tree_to_depths($binary_tree,'post','R');
        my @by_func = Graph::Maker::Catalans::_vertex_name_type_Rdepths_postorder($aref);
        ok (join(',',@by_func),
            join(',',@by_binary_tree),
            '_vertex_name_type_Rdepths_postorder() vs binary_tree_to_depths()');
      }
    }
  }
}

{
  # L/R/B depths only 5 combinations distinct for all trees, per POD

  my $N = 4;
  my %seen;
  foreach my $aref (balanced_list($N)) {
    my $binary_tree = balanced_to_binary_tree($aref);
    foreach my $order ('pre','in','post') {
      foreach my $LRB ('L','R','B') {
        my $str = join(',',binary_tree_to_depths($binary_tree,$order,$LRB));
        $seen{$order}->{$LRB}->{$str}++;
      }
    }
  }
  my %want = (pre  => { L => 14,
                        R => 8,        # short
                        B => 4 },      # short
              in   => { L => 14,
                        R => 14,
                        B => 14 },
              post => { L => 8,        # short
                        R => 14,
                        B => 4 });     # short
  foreach my $order ('pre','in','post') {
    foreach my $LRB ('L','R','B') {
      my $href = $seen{$order}->{$LRB};
      ok (scalar(keys %$href),
          $want{$order}->{$LRB},
          "N=$N count distinct $order $LRB");
    }
  }
}


#------------------------------------------------------------------------------
# filling

# A. Sapounakis, I. Tasoulas, P. Tsikouras, "On the Dominance Partial
# Ordering of Dyck Paths", Journal of Integer Sequences, volume 9, 2006,
# article 06.2.5.
# https://cs.uwaterloo.ca/journals/JIS/VOL9/Tsikouras/tsikouras67.html
#
# Dominance sequence = run length of 1s before each 0 in pre-order balanced
# binary.
# Filling = turn up every valley, so 01 -> 10 everywhere.
#     1100110100
#     1101011000
#        ^^ ^^

{
  # Section 2 run1s example.
  my @array = (1,1,0,0,1,0,1,1,0,1,0,0);
  ok (scalar(@array), 12);
  my @run1s = Graph::Maker::Catalans::_vertex_name_type_run1s(\@array);
  ok (scalar(@run1s), 6);
  ok (join(',',@run1s), '2,0,1,2,1,0');
}
{
  # Section 4 example filling.
  my @array = (1,1,0,0,1,1,0,1,0,0);
  my @fillings = Graph::Maker::Catalans::_rel_type_filling(\@array);
  ok (scalar(@fillings), 1);
  my @filling = @{$fillings[0]};
  ok (join('',@filling), '1101011000');
}

# balanced string is "indecomposable" if its only return to zero is at its end,
# so "1 balanced 0"
sub balanced_str_is_indecomposable {
  my ($str) = @_;
  my $d = 0;
  my $zeros = 0;
  my @bits = split //, $str;
  foreach my $i (0 .. $#bits) {
    $d += ($bits[$i] ? 1 : -1);
    if ($d==0 && $i < $#bits) { return 0; }
  }
  return 1;
}
ok (  balanced_str_is_indecomposable(''), 1);
ok (  balanced_str_is_indecomposable('10'), 1);
ok (  balanced_str_is_indecomposable('1100'), 1);
ok (! balanced_str_is_indecomposable('1010'), 1);

# Sapounakis, Tasoulas, Tsikouras, proposition 4.3 formula for num which are
# fillings, for $n >= 2.
# A086581 num Dyck words without 0011.
sub filling_num_predecessorful {
  my ($n) = @_;
  my $ret = 0;
  foreach my $k (int($n/2) .. $n) {
    $ret += (-1)**($n-$k) * binomial($k,$n-$k) * binomial(3*$k-$n, $k-1) / $k;
  }
  return $ret;
}
# foreach my $n (2 .. 10) { print filling_num_predecessorful($n),','; }
# print "\n";


{
  # directed
  # Sapounakis, Tasoulas, Tsikouras, proposition 4.2 balanced str is a
  # filling (has a predecessor) if and only if str is indecomposable and
  # does not contain 0011.
  foreach my $N (2 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'filling',
                                  countedged => 1);
    ok (scalar($graph->edges), $Catalan_number[$N] - 1);

    ok (scalar($graph->predecessorful_vertices),
        filling_num_predecessorful($N));

    my $end = ('1'x$N) . ('0'x$N);
    my @successorless_vertices = $graph->successorless_vertices;
    ok (scalar(@successorless_vertices), 1);
    ok ($successorless_vertices[0], $end);

    foreach my $v ($graph->vertices) {
      # print "$v predecessors ",join(' ',$graph->predecessors($v)),"\n";
      ok (scalar($graph->predecessors($v)) ? 1 : 0,
          balanced_str_is_indecomposable($v) && $v !~ /0011/ ? 1 : 0,
          'Sapounakis et al balanced binary is a filling');

      # WRONG, not graded by num initial 1s.
      #    012 3
      #    111 0 0 0
      # my $initial_1s = index($v,'0');
      # if ($initial_1s < 0) { $initial_1s = 0; }  # for $v empty string ""
      # ok ($graph->path_length($v,$end), $N-$initial_1s);
    }
  }
}
{
  # filling Ldepths successor is +1 at everywhere can increase
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'filling',
                                  vertex_name_type => 'Ldepths');
    foreach my $from ($graph->vertices) {
      my @successors = $graph->successors($from);
      my @from = split /,/, $from;
      my @to = @from;
      my $any = 0;
      foreach my $i (1 .. $#from) {
        if ($from[$i] <= $from[$i-1]) {
          $to[$i]++;
          $any = 1;
        }
      }
      my $to = join(',',@to);
      ok (scalar(@successors), $any);
      if ($any) {
        ok ($successors[0], join(',',@to));
      }
    }
  }
}
{
  # N=5 indecomposable containing 0011
  #   1 11 0011 000
  my $N = 5;
  my $graph = Graph::Maker->new('Catalans', N => $N,
                                rel_type => 'filling');
  my $count = 0;
  foreach my $v ($graph->vertices) {
    next unless balanced_str_is_indecomposable($v);
    if ($v =~ /0011/) {
      ok ($v, '1110011000');
      ok (scalar($graph->predecessors($v)), 0,
          "N=$N filling no predecessor of indecomposable with 0011");
      $count++;
    }
  }
  ok ($count, 1);
}

{
  # Figure 2, D4 = Stanley lattice
  my $graph = Graph->new;
  $graph->add_edges(['1,1,1,1', '2,0,1,1'],
                    ['1,1,1,1', '1,2,0,1'],
                    ['1,1,1,1', '1,1,2,0'],

                    ['2,0,1,1', '2,1,0,1'],
                    ['2,0,1,1', '2,0,2,0'],
                    #
                    ['1,2,0,1', '2,1,0,1'],
                    ['1,2,0,1', '1,2,1,0'],
                    #
                    ['1,1,2,0', '2,0,2,0'],
                    ['1,1,2,0', '1,2,1,0'],

                    ['2,1,0,1', '3,0,0,1'],
                    ['2,1,0,1', '2,1,1,0'],
                    #
                    ['2,0,2,0', '2,1,1,0'],
                    #
                    ['1,2,1,0', '2,1,1,0'],
                    ['1,2,1,0', '1,3,0,0'],

                    ['3,0,0,1', '3,0,1,0'],
                    #
                    ['2,1,1,0', '3,0,1,0'],
                    ['2,1,1,0', '2,2,0,0'],
                    #
                    ['1,3,0,0', '2,2,0,0'],

                    ['3,0,1,0', '3,1,0,0'],
                    ['2,2,0,0', '3,1,0,0'],

                    ['3,1,0,0', '4,0,0,0'],
                   );

  my $catalans = Graph::Maker->new('Catalans', N => 4,
                                   rel_type => 'flip',
                                   vertex_name_type => 'run1s');
  ok (scalar($graph->vertices), 14);
  ok ($graph eq $catalans, 1);
}


#------------------------------------------------------------------------------

#    1010[0]      1100[0]          preorder
#    0101[0]      0101[0]          inorder  always 01010... alternating
#    [0]0011      [0]0101          postorder
#     *             *
#    / \           / \
#   e   *         *   e
#      / \       / \
#     e   e     e   e
sub binary_tree_to_preorder_balanced {
  my ($binary_tree) = @_;
  if (defined $binary_tree) {
    return (1, binary_tree_to_preorder_balanced($binary_tree->{left}),
            0, binary_tree_to_preorder_balanced($binary_tree->{right}));
  } else {
    return ();
  }
}
sub binary_tree_to_preorder_recursive {
  my ($binary_tree) = @_;
  if (defined $binary_tree) {
    return (1,
            binary_tree_to_preorder_recursive($binary_tree->{left}),
            binary_tree_to_preorder_recursive($binary_tree->{right}));
  } else {
    return (0);
  }
}
sub binary_tree_to_balanced_postorder {
  my ($binary_tree) = @_;
  if (defined $binary_tree) {
    return (binary_tree_to_balanced_postorder($binary_tree->{left}),  1,
            binary_tree_to_balanced_postorder($binary_tree->{right}), 0);
  } else {
    return ();
  }
}
sub binary_tree_to_postorder_recursive {
  my ($binary_tree) = @_;
  my @ret;
  if (defined $binary_tree) {
    return (binary_tree_to_balanced_postorder($binary_tree->{left}),
            binary_tree_to_balanced_postorder($binary_tree->{right}),
            0);
  } else {
    return (1);
  }
}
sub binary_tree_to_inorder_recursive {
  my ($binary_tree) = @_;
  if (defined $binary_tree) {
    return (binary_tree_to_inorder_recursive($binary_tree->{left}),
            1,
            binary_tree_to_inorder_recursive($binary_tree->{right}));
  } else {
    return (0);
  }
}

foreach my $n (0 .. 5) {
  my @arrays = balanced_list($n);
  foreach my $i (0 .. $#arrays) {
    my $aref = $arrays[$i];
    my $array = join('',@$aref);
    my $binary_tree = balanced_to_binary_tree($aref);
    {
      my @again = binary_tree_to_preorder_balanced($binary_tree);
      ok (join('',@again), $array,
          "binary_tree_to_preorder_balanced() again");
    }
    {
      my @again = binary_tree_to_preorder_recursive($binary_tree);
      ok (join('',@again), $array.'0',
          "binary_tree_to_preorder_recursive() again");
    }
    {
      my @inorder_again = binary_tree_to_inorder_recursive($binary_tree);
      ok (join('',@inorder_again), ('01'x$n).'0',
          "binary_tree_to_inorder_recursive()");
    }

    # not right
    # my @postorder_array = Graph::Maker::Catalans::_vertex_name_type_reverse_balanced($arrays[$#arrays - $i]);
    # my @postorder_again = binary_tree_to_balanced_postorder($binary_tree);
    # ok (join('',@postorder_again),
    #     join('',@postorder_array),
    #     "binary_tree_to_balanced_postorder() on array=$array");
  }
}


#------------------------------------------------------------------------------
# Olivier Bernardi and Nicolas Bonichon, "Catalan's Intervals and Realizers
# of Triangulations", arxiv:0704.3731

{
  # Bernardi and Bonichon figure 2(a) Stanley
  my $graph = Graph->new;
  $graph->add_edge('101010', '101100');
  $graph->add_edge('101010', '110010');

  $graph->add_edge('101100', '110100');
  $graph->add_edge('110010', '110100');

  $graph->add_edge('110100', '111000');

  my $got = Graph::Maker->new('Catalans', N => 3,
                              rel_type => 'flip');
  ok($got eq $graph, 1);
}
sub f {
  my ($str) = @_;
  $str =~ tr/01/10/;
  return scalar(reverse($str));
}
{
  # Bernardi and Bonichon Figure 2(b) Tamari
  my $graph = Graph->new;
  $graph->add_edge(f('101010'), f('101100'));
  $graph->add_edge(f('101010'), f('110010'));

  $graph->add_edge(f('101100'), f('111000'));
  $graph->add_edge(f('110010'), f('110100'));

  $graph->add_edge(f('110100'), f('111000'));

  my $got = Graph::Maker->new('Catalans', N => 3,
                              rel_type => 'rotate');
  ok($got eq $graph, 1);
}
# {
#   # Bernardi and Bonichon figure 2(b) Tamari
#   my $graph = Graph->new;
#   $graph->add_edge('101010', '101100');
#   $graph->add_edge('101010', '110010');
#
#   $graph->add_edge('101100', '111000');
#   $graph->add_edge('110010', '110100');
#
#   $graph->add_edge('110100', '111000');
#
#   my $got = Graph::Maker->new('Catalans', N => 3,
#                               rel_type => 'postorder_rotate',
#                               vertex_name_type => 'reverse_balanced');
#   ok($got eq $graph, 1);
#
#   # require MyGraphs;
#   # MyGraphs::Graph_view($graph);
#   # MyGraphs::Graph_view($got);
# }
{
  # Bernardi and Bonichon figure 2(c) Kreweras
  my $graph = Graph->new;
  $graph->add_edge('101010', '101100');
  $graph->add_edge('101010', '110010');
  $graph->add_edge('101010', '110100');

  $graph->add_edge('101100', '111000');
  $graph->add_edge('110010', '111000');
  $graph->add_edge('110100', '111000');

  my $got = Graph::Maker->new('Catalans', N => 3,
                              rel_type => 'split');
  ok($got eq $graph, 1);
}

{
  # Bernardi and Bonichon figure 5
  #                1
  #            /       \
  #          2           6
  #        /   \        / \
  #      3       4     e   7
  #     / \     / \       / \
  #    e   e   5   e     e   e
  #           / \
  #          e   e
  #
  my $b3 = { left => undef, right => undef };
  my $b5 = { left => undef, right => undef };
  my $b4 = { left => $b5,   right => undef };
  my $b2 = { left => $b3,   right => $b4 };
  my $b7 = { left => undef, right => undef };
  my $b6 = { left => undef, right => $b7 };
  my $b1 = { left => $b2,   right => $b6 };

  ok (binary_tree_to_parens($b1), '(((e,e),((e,e),e)),(e,(e,e)))');

  {
    my @again = binary_tree_to_preorder_balanced($b1);
    ok (join('',@again), '11100110001010');  # following diagram
  }
  {
    # figure 5 mountain range in Bernardi and Bonichon
    my @again = binary_tree_to_balanced_postorder($b1);
    ok (join('',@again), '10110100111000');
  }
}

sub balanced_postorder_str_to_preorder_str_by_tree {
  my ($str) = @_;
  my $binary_tree = balanced_postorder_to_binary_tree([split //, $str]);
  return join('', binary_tree_to_preorder_balanced($binary_tree));
}
{
  # Bernardi and Bonichon figure 6 Tamari N=4

  # in postorder balanced
  my @edges = (['10101010','10110010'],  # start to right
               ['10101010','10101100'],  # start up
               ['10101010','11001010'],

               ['11001010','11001100'],  # left
               ['11001010','11010010'],

               ['11010010','11010100'],  # left 2
               ['11010010','11100010'],

               ['10110010','11100010'],  # diag 2 right
               ['10110010','10110100'],

               ['10101100','10111000'],
               ['10101100','11001100'],

               ['11001100','11011000'],

               ['11010100','11100100'],
               ['11010100','11011000'],

               ['11100010','11100100'],  # diag 3 right

               ['10110100','11101000'],
               ['10110100','10111000'],

               ['10111000','11110000'],

               ['11011000','11110000'],

               ['11100100','11101000'],  # top diag

               ['11101000','11110000']);

  my $p = sub {   # convert postorder $str to preorder
    my ($str) = @_;
    return
  };
  my $graph_preorder = Graph->new;
  foreach my $edge (@edges) {
    $graph_preorder->add_edge
      (map {balanced_postorder_str_to_preorder_str_by_tree($_)} @$edge);
  }
  my $got_preorder = Graph::Maker->new('Catalans', N => 4,
                                       vertex_name_type => 'balanced',
                                       rel_direction   => 'down');
  # print "$got_preorder";
  # print "$graph_preorder\n";
  ok($got_preorder eq $graph_preorder, 1);

  my $graph_postorder = Graph->new;
  foreach my $edge (@edges) {
    $graph_postorder->add_edge($edge->[0], $edge->[1]);
  }
  my $got_postorder =Graph::Maker->new('Catalans', N => 4,
                                       vertex_name_type => 'balanced_postorder',
                                       rel_direction    => 'down');
  # print "$got_postorder\n";
  # print "$graph_postorder\n";
  ok($got_postorder eq $graph_postorder, 1);
}


#------------------------------------------------------------------------------
# _vertex_name_type_vpar()
# _vertex_name_type_vpar_postorder()

ok (join(',',Graph::Maker::Catalans::_vertex_name_type_vpar([])), '');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_vpar([1,0])), '0');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_vpar([1,0,1,0])), '0,0');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_vpar([1,1,0,0])), '0,1');

ok (join(',',Graph::Maker::Catalans::_vertex_name_type_vpar_postorder([1,0,1,0])), '0,0');
ok (join(',',Graph::Maker::Catalans::_vertex_name_type_vpar_postorder([1,1,0,0])), '2,0');

#------------------------------------------------------------------------------
# _rel_type_flip()

# {
#   my @array = (1,1,0,0,1,0);
#   # my @got = Graph::Maker::Catalans::_rel_type_flip(\@array);
#   my @got = Graph::Maker::Catalans::_rel_type_rotate(\@array);
#   ### @got
# }


#------------------------------------------------------------------------------
# _balanced_next()

ok (Graph::Maker::Catalans::_balanced_next([]), 0);
ok (Graph::Maker::Catalans::_balanced_next([1,0]), 0);
{
  my @array = (1,0,1,0);
  ok (Graph::Maker::Catalans::_balanced_next(\@array), 1);
  ok (join('',@array), '1100');
  ok (Graph::Maker::Catalans::_balanced_next(\@array), 0);
}

foreach my $n (0 .. 8) {
  my @array = (1,0) x $n;
  my $count = 0;
  do { $count++; } while (Graph::Maker::Catalans::_balanced_next(\@array));
  ok ($count, $Catalan_number[$n]);
}

#------------------------------------------------------------------------------
# Lattice Refinement

sub hash_is_subset {
  my ($href, $sub_href) = @_;
  foreach my $key (keys %$sub_href) {
    unless (exists $href->{$key}) { return 0; }
  }
  return 1;
}

{
  foreach my $N (0 .. 6) {
    my @rel_types = ('split','rotate','flip','filling',
                     'dexter','rotate_rightarm');
    my %graphs;
    my %successors;
    my %all_successors;
    my %predecessors;
    my %all_predecessors;
    foreach my $rel_type (@rel_types) {
      my $graph =  Graph::Maker->new('Catalans', N => $N,
                                     rel_type => $rel_type);
      $graphs{$rel_type} = $graph;
      foreach my $v ($graph->vertices) {
        { my %hash; @hash{$graph->successors($v)} = (); # hash slice
          $successors{$rel_type}->{$v} = \%hash;
        }
        { my %hash; @hash{$graph->all_successors($v)} = (); # hash slice
          $all_successors{$rel_type}->{$v} = \%hash;
        }
        { my %hash; @hash{$graph->predecessors($v)} = (); # hash slice
          $predecessors{$rel_type}->{$v} = \%hash;
        }
        { my %hash; @hash{$graph->all_predecessors($v)} = (); # hash slice
          $all_predecessors{$rel_type}->{$v} = \%hash;
        }
      }
    }
    foreach my $v ($graphs{'split'}->vertices) {
      # split is refinement of rotate,
      # all_successors of rotate eventually reach all of split
      ok (hash_is_subset($all_successors{'rotate'}->{$v},
                         $all_successors{'split'}->{$v}),  1);
      ok (hash_is_subset($all_predecessors{'rotate'}->{$v},
                         $all_predecessors{'split'}->{$v}),  1);

      # rotate is refinement of flip,
      ok (hash_is_subset($all_successors{'flip'}->{$v},
                         $all_successors{'rotate'}->{$v}),  1);
      ok (hash_is_subset($all_predecessors{'flip'}->{$v},
                         $all_predecessors{'rotate'}->{$v}),  1);

      # dexter is refinement of flip,
      ok (hash_is_subset($all_successors{'flip'}->{$v},
                         $all_successors{'dexter'}->{$v}),
          1);

      # dexter destinations are rotate_rightarm and various more, per
      # Chapoton and noted in the POD
      ok (hash_is_subset($successors{'dexter'}->{$v},
                         $successors{'rotate_rightarm'}->{$v}),
          1);

      # filling is semilattice refinement of flip
      # all_successors of flip reaches all of filling eventually
      ok (hash_is_subset($all_successors{'flip'}->{$v},
                         $all_successors{'filling'}->{$v}),  1);
    }

    # print "$v\n";
    # foreach my $i (0 .. $#graphs) {
    #   print " g$i  ",join(' ',sort keys %{$successors[$i]}),"\n";
    # }
    # foreach my $i (0 .. $#graphs) {
    #   print " g$i  ",join(' ',sort keys %{$all_successors[$i]}),"\n";
    # }
  }
}


#------------------------------------------------------------------------------

{
  my @data =
    (
     # generated by Catalans-vpar.gp
     [  # count 1
      { balanced=>'',
          balanced_postorder=>'',
        Ldepths=>'', Rdepths_postorder=>'',
        Bdepths_inorder=>'', Ldepths_inorder=>'',
          Rdepths_inorder=>'',
        vpar=>'', vpar_postorder=>'',
        Lweights=>'', Rweights=>'',
      },
     ],
     [  # count 1
      { balanced=>'1,0',
          balanced_postorder=>'1,0',
        Ldepths=>'0', Rdepths_postorder=>'0',
        Bdepths_inorder=>'0', Ldepths_inorder=>'0',
          Rdepths_inorder=>'0',
        vpar=>'0', vpar_postorder=>'0',
        Lweights=>'1', Rweights=>'1',
      },
     ],
     [  # count 2
      { balanced=>'1,0,1,0',
          balanced_postorder=>'1,1,0,0',
        Ldepths=>'0,0', Rdepths_postorder=>'1,0',
        Bdepths_inorder=>'0,1', Ldepths_inorder=>'0,0',
          Rdepths_inorder=>'0,1',
        vpar=>'0,0', vpar_postorder=>'0,0',
        Lweights=>'1,1', Rweights=>'2,1',
      },
      { balanced=>'1,1,0,0',
          balanced_postorder=>'1,0,1,0',
        Ldepths=>'0,1', Rdepths_postorder=>'0,0',
        Bdepths_inorder=>'1,0', Ldepths_inorder=>'1,0',
          Rdepths_inorder=>'0,0',
        vpar=>'0,1', vpar_postorder=>'2,0',
        Lweights=>'1,2', Rweights=>'1,1',
      },
     ],
     [  # count 5
      { balanced=>'1,0,1,0,1,0',
          balanced_postorder=>'1,1,1,0,0,0',
        Ldepths=>'0,0,0', Rdepths_postorder=>'2,1,0',
        Bdepths_inorder=>'0,1,2', Ldepths_inorder=>'0,0,0',
          Rdepths_inorder=>'0,1,2',
        vpar=>'0,0,0', vpar_postorder=>'0,0,0',
        Lweights=>'1,1,1', Rweights=>'3,2,1',
      },
      { balanced=>'1,0,1,1,0,0',
          balanced_postorder=>'1,1,0,1,0,0',
        Ldepths=>'0,0,1', Rdepths_postorder=>'1,1,0',
        Bdepths_inorder=>'0,2,1', Ldepths_inorder=>'0,1,0',
          Rdepths_inorder=>'0,1,1',
        vpar=>'0,0,2', vpar_postorder=>'0,3,0',
        Lweights=>'1,1,2', Rweights=>'3,1,1',
      },
      { balanced=>'1,1,0,0,1,0',
          balanced_postorder=>'1,0,1,1,0,0',
        Ldepths=>'0,1,0', Rdepths_postorder=>'0,1,0',
        Bdepths_inorder=>'1,0,1', Ldepths_inorder=>'1,0,0',
          Rdepths_inorder=>'0,0,1',
        vpar=>'0,1,0', vpar_postorder=>'2,0,0',
        Lweights=>'1,2,1', Rweights=>'1,2,1',
      },
      { balanced=>'1,1,0,1,0,0',
          balanced_postorder=>'1,1,0,0,1,0',
        Ldepths=>'0,1,1', Rdepths_postorder=>'1,0,0',
        Bdepths_inorder=>'1,2,0', Ldepths_inorder=>'1,1,0',
          Rdepths_inorder=>'0,1,0',
        vpar=>'0,1,1', vpar_postorder=>'3,3,0',
        Lweights=>'1,1,3', Rweights=>'2,1,1',
      },
      { balanced=>'1,1,1,0,0,0',
          balanced_postorder=>'1,0,1,0,1,0',
        Ldepths=>'0,1,2', Rdepths_postorder=>'0,0,0',
        Bdepths_inorder=>'2,1,0', Ldepths_inorder=>'2,1,0',
          Rdepths_inorder=>'0,0,0',
        vpar=>'0,1,2', vpar_postorder=>'2,3,0',
        Lweights=>'1,2,3', Rweights=>'1,1,1',
      },
     ],
     [  # count 14
      { balanced=>'1,0,1,0,1,0,1,0',
          balanced_postorder=>'1,1,1,1,0,0,0,0',
        Ldepths=>'0,0,0,0', Rdepths_postorder=>'3,2,1,0',
        Bdepths_inorder=>'0,1,2,3', Ldepths_inorder=>'0,0,0,0',
          Rdepths_inorder=>'0,1,2,3',
        vpar=>'0,0,0,0', vpar_postorder=>'0,0,0,0',
        Lweights=>'1,1,1,1', Rweights=>'4,3,2,1',
      },
      { balanced=>'1,0,1,0,1,1,0,0',
          balanced_postorder=>'1,1,1,0,1,0,0,0',
        Ldepths=>'0,0,0,1', Rdepths_postorder=>'2,2,1,0',
        Bdepths_inorder=>'0,1,3,2', Ldepths_inorder=>'0,0,1,0',
          Rdepths_inorder=>'0,1,2,2',
        vpar=>'0,0,0,3', vpar_postorder=>'0,0,4,0',
        Lweights=>'1,1,1,2', Rweights=>'4,3,1,1',
      },
      { balanced=>'1,0,1,1,0,0,1,0',
          balanced_postorder=>'1,1,0,1,1,0,0,0',
        Ldepths=>'0,0,1,0', Rdepths_postorder=>'1,2,1,0',
        Bdepths_inorder=>'0,2,1,2', Ldepths_inorder=>'0,1,0,0',
          Rdepths_inorder=>'0,1,1,2',
        vpar=>'0,0,2,0', vpar_postorder=>'0,3,0,0',
        Lweights=>'1,1,2,1', Rweights=>'4,1,2,1',
      },
      { balanced=>'1,0,1,1,0,1,0,0',
          balanced_postorder=>'1,1,1,0,0,1,0,0',
        Ldepths=>'0,0,1,1', Rdepths_postorder=>'2,1,1,0',
        Bdepths_inorder=>'0,2,3,1', Ldepths_inorder=>'0,1,1,0',
          Rdepths_inorder=>'0,1,2,1',
        vpar=>'0,0,2,2', vpar_postorder=>'0,4,4,0',
        Lweights=>'1,1,1,3', Rweights=>'4,2,1,1',
      },
      { balanced=>'1,0,1,1,1,0,0,0',
          balanced_postorder=>'1,1,0,1,0,1,0,0',
        Ldepths=>'0,0,1,2', Rdepths_postorder=>'1,1,1,0',
        Bdepths_inorder=>'0,3,2,1', Ldepths_inorder=>'0,2,1,0',
          Rdepths_inorder=>'0,1,1,1',
        vpar=>'0,0,2,3', vpar_postorder=>'0,3,4,0',
        Lweights=>'1,1,2,3', Rweights=>'4,1,1,1',
      },
      { balanced=>'1,1,0,0,1,0,1,0',
          balanced_postorder=>'1,0,1,1,1,0,0,0',
        Ldepths=>'0,1,0,0', Rdepths_postorder=>'0,2,1,0',
        Bdepths_inorder=>'1,0,1,2', Ldepths_inorder=>'1,0,0,0',
          Rdepths_inorder=>'0,0,1,2',
        vpar=>'0,1,0,0', vpar_postorder=>'2,0,0,0',
        Lweights=>'1,2,1,1', Rweights=>'1,3,2,1',
      },
      { balanced=>'1,1,0,0,1,1,0,0',
          balanced_postorder=>'1,0,1,1,0,1,0,0',
        Ldepths=>'0,1,0,1', Rdepths_postorder=>'0,1,1,0',
        Bdepths_inorder=>'1,0,2,1', Ldepths_inorder=>'1,0,1,0',
          Rdepths_inorder=>'0,0,1,1',
        vpar=>'0,1,0,3', vpar_postorder=>'2,0,4,0',
        Lweights=>'1,2,1,2', Rweights=>'1,3,1,1',
      },
      { balanced=>'1,1,0,1,0,0,1,0',
          balanced_postorder=>'1,1,0,0,1,1,0,0',
        Ldepths=>'0,1,1,0', Rdepths_postorder=>'1,0,1,0',
        Bdepths_inorder=>'1,2,0,1', Ldepths_inorder=>'1,1,0,0',
          Rdepths_inorder=>'0,1,0,1',
        vpar=>'0,1,1,0', vpar_postorder=>'3,3,0,0',
        Lweights=>'1,1,3,1', Rweights=>'2,1,2,1',
      },
      { balanced=>'1,1,0,1,0,1,0,0',
          balanced_postorder=>'1,1,1,0,0,0,1,0',
        Ldepths=>'0,1,1,1', Rdepths_postorder=>'2,1,0,0',
        Bdepths_inorder=>'1,2,3,0', Ldepths_inorder=>'1,1,1,0',
          Rdepths_inorder=>'0,1,2,0',
        vpar=>'0,1,1,1', vpar_postorder=>'4,4,4,0',
        Lweights=>'1,1,1,4', Rweights=>'3,2,1,1',
      },
      { balanced=>'1,1,0,1,1,0,0,0',
          balanced_postorder=>'1,1,0,1,0,0,1,0',
        Ldepths=>'0,1,1,2', Rdepths_postorder=>'1,1,0,0',
        Bdepths_inorder=>'1,3,2,0', Ldepths_inorder=>'1,2,1,0',
          Rdepths_inorder=>'0,1,1,0',
        vpar=>'0,1,1,3', vpar_postorder=>'4,3,4,0',
        Lweights=>'1,1,2,4', Rweights=>'3,1,1,1',
      },
      { balanced=>'1,1,1,0,0,0,1,0',
          balanced_postorder=>'1,0,1,0,1,1,0,0',
        Ldepths=>'0,1,2,0', Rdepths_postorder=>'0,0,1,0',
        Bdepths_inorder=>'2,1,0,1', Ldepths_inorder=>'2,1,0,0',
          Rdepths_inorder=>'0,0,0,1',
        vpar=>'0,1,2,0', vpar_postorder=>'2,3,0,0',
        Lweights=>'1,2,3,1', Rweights=>'1,1,2,1',
      },
      { balanced=>'1,1,1,0,0,1,0,0',
          balanced_postorder=>'1,0,1,1,0,0,1,0',
        Ldepths=>'0,1,2,1', Rdepths_postorder=>'0,1,0,0',
        Bdepths_inorder=>'2,1,2,0', Ldepths_inorder=>'2,1,1,0',
          Rdepths_inorder=>'0,0,1,0',
        vpar=>'0,1,2,1', vpar_postorder=>'2,4,4,0',
        Lweights=>'1,2,1,4', Rweights=>'1,2,1,1',
      },
      { balanced=>'1,1,1,0,1,0,0,0',
          balanced_postorder=>'1,1,0,0,1,0,1,0',
        Ldepths=>'0,1,2,2', Rdepths_postorder=>'1,0,0,0',
        Bdepths_inorder=>'2,3,1,0', Ldepths_inorder=>'2,2,1,0',
          Rdepths_inorder=>'0,1,0,0',
        vpar=>'0,1,2,2', vpar_postorder=>'3,3,4,0',
        Lweights=>'1,1,3,4', Rweights=>'2,1,1,1',
      },
      { balanced=>'1,1,1,1,0,0,0,0',
          balanced_postorder=>'1,0,1,0,1,0,1,0',
        Ldepths=>'0,1,2,3', Rdepths_postorder=>'0,0,0,0',
        Bdepths_inorder=>'3,2,1,0', Ldepths_inorder=>'3,2,1,0',
          Rdepths_inorder=>'0,0,0,0',
        vpar=>'0,1,2,3', vpar_postorder=>'2,3,4,0',
        Lweights=>'1,2,3,4', Rweights=>'1,1,1,1',
      },
     ],
     [  # count 42
      { balanced=>'1,0,1,0,1,0,1,0,1,0',
          balanced_postorder=>'1,1,1,1,1,0,0,0,0,0',
        Ldepths=>'0,0,0,0,0', Rdepths_postorder=>'4,3,2,1,0',
        Bdepths_inorder=>'0,1,2,3,4', Ldepths_inorder=>'0,0,0,0,0',
          Rdepths_inorder=>'0,1,2,3,4',
        vpar=>'0,0,0,0,0', vpar_postorder=>'0,0,0,0,0',
        Lweights=>'1,1,1,1,1', Rweights=>'5,4,3,2,1',
      },
      { balanced=>'1,0,1,0,1,0,1,1,0,0',
          balanced_postorder=>'1,1,1,1,0,1,0,0,0,0',
        Ldepths=>'0,0,0,0,1', Rdepths_postorder=>'3,3,2,1,0',
        Bdepths_inorder=>'0,1,2,4,3', Ldepths_inorder=>'0,0,0,1,0',
          Rdepths_inorder=>'0,1,2,3,3',
        vpar=>'0,0,0,0,4', vpar_postorder=>'0,0,0,5,0',
        Lweights=>'1,1,1,1,2', Rweights=>'5,4,3,1,1',
      },
      { balanced=>'1,0,1,0,1,1,0,0,1,0',
          balanced_postorder=>'1,1,1,0,1,1,0,0,0,0',
        Ldepths=>'0,0,0,1,0', Rdepths_postorder=>'2,3,2,1,0',
        Bdepths_inorder=>'0,1,3,2,3', Ldepths_inorder=>'0,0,1,0,0',
          Rdepths_inorder=>'0,1,2,2,3',
        vpar=>'0,0,0,3,0', vpar_postorder=>'0,0,4,0,0',
        Lweights=>'1,1,1,2,1', Rweights=>'5,4,1,2,1',
      },
      { balanced=>'1,0,1,0,1,1,0,1,0,0',
          balanced_postorder=>'1,1,1,1,0,0,1,0,0,0',
        Ldepths=>'0,0,0,1,1', Rdepths_postorder=>'3,2,2,1,0',
        Bdepths_inorder=>'0,1,3,4,2', Ldepths_inorder=>'0,0,1,1,0',
          Rdepths_inorder=>'0,1,2,3,2',
        vpar=>'0,0,0,3,3', vpar_postorder=>'0,0,5,5,0',
        Lweights=>'1,1,1,1,3', Rweights=>'5,4,2,1,1',
      },
      { balanced=>'1,0,1,0,1,1,1,0,0,0',
          balanced_postorder=>'1,1,1,0,1,0,1,0,0,0',
        Ldepths=>'0,0,0,1,2', Rdepths_postorder=>'2,2,2,1,0',
        Bdepths_inorder=>'0,1,4,3,2', Ldepths_inorder=>'0,0,2,1,0',
          Rdepths_inorder=>'0,1,2,2,2',
        vpar=>'0,0,0,3,4', vpar_postorder=>'0,0,4,5,0',
        Lweights=>'1,1,1,2,3', Rweights=>'5,4,1,1,1',
      },
      { balanced=>'1,0,1,1,0,0,1,0,1,0',
          balanced_postorder=>'1,1,0,1,1,1,0,0,0,0',
        Ldepths=>'0,0,1,0,0', Rdepths_postorder=>'1,3,2,1,0',
        Bdepths_inorder=>'0,2,1,2,3', Ldepths_inorder=>'0,1,0,0,0',
          Rdepths_inorder=>'0,1,1,2,3',
        vpar=>'0,0,2,0,0', vpar_postorder=>'0,3,0,0,0',
        Lweights=>'1,1,2,1,1', Rweights=>'5,1,3,2,1',
      },
      { balanced=>'1,0,1,1,0,0,1,1,0,0',
          balanced_postorder=>'1,1,0,1,1,0,1,0,0,0',
        Ldepths=>'0,0,1,0,1', Rdepths_postorder=>'1,2,2,1,0',
        Bdepths_inorder=>'0,2,1,3,2', Ldepths_inorder=>'0,1,0,1,0',
          Rdepths_inorder=>'0,1,1,2,2',
        vpar=>'0,0,2,0,4', vpar_postorder=>'0,3,0,5,0',
        Lweights=>'1,1,2,1,2', Rweights=>'5,1,3,1,1',
      },
      { balanced=>'1,0,1,1,0,1,0,0,1,0',
          balanced_postorder=>'1,1,1,0,0,1,1,0,0,0',
        Ldepths=>'0,0,1,1,0', Rdepths_postorder=>'2,1,2,1,0',
        Bdepths_inorder=>'0,2,3,1,2', Ldepths_inorder=>'0,1,1,0,0',
          Rdepths_inorder=>'0,1,2,1,2',
        vpar=>'0,0,2,2,0', vpar_postorder=>'0,4,4,0,0',
        Lweights=>'1,1,1,3,1', Rweights=>'5,2,1,2,1',
      },
      { balanced=>'1,0,1,1,0,1,0,1,0,0',
          balanced_postorder=>'1,1,1,1,0,0,0,1,0,0',
        Ldepths=>'0,0,1,1,1', Rdepths_postorder=>'3,2,1,1,0',
        Bdepths_inorder=>'0,2,3,4,1', Ldepths_inorder=>'0,1,1,1,0',
          Rdepths_inorder=>'0,1,2,3,1',
        vpar=>'0,0,2,2,2', vpar_postorder=>'0,5,5,5,0',
        Lweights=>'1,1,1,1,4', Rweights=>'5,3,2,1,1',
      },
      { balanced=>'1,0,1,1,0,1,1,0,0,0',
          balanced_postorder=>'1,1,1,0,1,0,0,1,0,0',
        Ldepths=>'0,0,1,1,2', Rdepths_postorder=>'2,2,1,1,0',
        Bdepths_inorder=>'0,2,4,3,1', Ldepths_inorder=>'0,1,2,1,0',
          Rdepths_inorder=>'0,1,2,2,1',
        vpar=>'0,0,2,2,4', vpar_postorder=>'0,5,4,5,0',
        Lweights=>'1,1,1,2,4', Rweights=>'5,3,1,1,1',
      },
      { balanced=>'1,0,1,1,1,0,0,0,1,0',
          balanced_postorder=>'1,1,0,1,0,1,1,0,0,0',
        Ldepths=>'0,0,1,2,0', Rdepths_postorder=>'1,1,2,1,0',
        Bdepths_inorder=>'0,3,2,1,2', Ldepths_inorder=>'0,2,1,0,0',
          Rdepths_inorder=>'0,1,1,1,2',
        vpar=>'0,0,2,3,0', vpar_postorder=>'0,3,4,0,0',
        Lweights=>'1,1,2,3,1', Rweights=>'5,1,1,2,1',
      },
      { balanced=>'1,0,1,1,1,0,0,1,0,0',
          balanced_postorder=>'1,1,0,1,1,0,0,1,0,0',
        Ldepths=>'0,0,1,2,1', Rdepths_postorder=>'1,2,1,1,0',
        Bdepths_inorder=>'0,3,2,3,1', Ldepths_inorder=>'0,2,1,1,0',
          Rdepths_inorder=>'0,1,1,2,1',
        vpar=>'0,0,2,3,2', vpar_postorder=>'0,3,5,5,0',
        Lweights=>'1,1,2,1,4', Rweights=>'5,1,2,1,1',
      },
      { balanced=>'1,0,1,1,1,0,1,0,0,0',
          balanced_postorder=>'1,1,1,0,0,1,0,1,0,0',
        Ldepths=>'0,0,1,2,2', Rdepths_postorder=>'2,1,1,1,0',
        Bdepths_inorder=>'0,3,4,2,1', Ldepths_inorder=>'0,2,2,1,0',
          Rdepths_inorder=>'0,1,2,1,1',
        vpar=>'0,0,2,3,3', vpar_postorder=>'0,4,4,5,0',
        Lweights=>'1,1,1,3,4', Rweights=>'5,2,1,1,1',
      },
      { balanced=>'1,0,1,1,1,1,0,0,0,0',
          balanced_postorder=>'1,1,0,1,0,1,0,1,0,0',
        Ldepths=>'0,0,1,2,3', Rdepths_postorder=>'1,1,1,1,0',
        Bdepths_inorder=>'0,4,3,2,1', Ldepths_inorder=>'0,3,2,1,0',
          Rdepths_inorder=>'0,1,1,1,1',
        vpar=>'0,0,2,3,4', vpar_postorder=>'0,3,4,5,0',
        Lweights=>'1,1,2,3,4', Rweights=>'5,1,1,1,1',
      },
      { balanced=>'1,1,0,0,1,0,1,0,1,0',
          balanced_postorder=>'1,0,1,1,1,1,0,0,0,0',
        Ldepths=>'0,1,0,0,0', Rdepths_postorder=>'0,3,2,1,0',
        Bdepths_inorder=>'1,0,1,2,3', Ldepths_inorder=>'1,0,0,0,0',
          Rdepths_inorder=>'0,0,1,2,3',
        vpar=>'0,1,0,0,0', vpar_postorder=>'2,0,0,0,0',
        Lweights=>'1,2,1,1,1', Rweights=>'1,4,3,2,1',
      },
      { balanced=>'1,1,0,0,1,0,1,1,0,0',
          balanced_postorder=>'1,0,1,1,1,0,1,0,0,0',
        Ldepths=>'0,1,0,0,1', Rdepths_postorder=>'0,2,2,1,0',
        Bdepths_inorder=>'1,0,1,3,2', Ldepths_inorder=>'1,0,0,1,0',
          Rdepths_inorder=>'0,0,1,2,2',
        vpar=>'0,1,0,0,4', vpar_postorder=>'2,0,0,5,0',
        Lweights=>'1,2,1,1,2', Rweights=>'1,4,3,1,1',
      },
      { balanced=>'1,1,0,0,1,1,0,0,1,0',
          balanced_postorder=>'1,0,1,1,0,1,1,0,0,0',
        Ldepths=>'0,1,0,1,0', Rdepths_postorder=>'0,1,2,1,0',
        Bdepths_inorder=>'1,0,2,1,2', Ldepths_inorder=>'1,0,1,0,0',
          Rdepths_inorder=>'0,0,1,1,2',
        vpar=>'0,1,0,3,0', vpar_postorder=>'2,0,4,0,0',
        Lweights=>'1,2,1,2,1', Rweights=>'1,4,1,2,1',
      },
      { balanced=>'1,1,0,0,1,1,0,1,0,0',
          balanced_postorder=>'1,0,1,1,1,0,0,1,0,0',
        Ldepths=>'0,1,0,1,1', Rdepths_postorder=>'0,2,1,1,0',
        Bdepths_inorder=>'1,0,2,3,1', Ldepths_inorder=>'1,0,1,1,0',
          Rdepths_inorder=>'0,0,1,2,1',
        vpar=>'0,1,0,3,3', vpar_postorder=>'2,0,5,5,0',
        Lweights=>'1,2,1,1,3', Rweights=>'1,4,2,1,1',
      },
      { balanced=>'1,1,0,0,1,1,1,0,0,0',
          balanced_postorder=>'1,0,1,1,0,1,0,1,0,0',
        Ldepths=>'0,1,0,1,2', Rdepths_postorder=>'0,1,1,1,0',
        Bdepths_inorder=>'1,0,3,2,1', Ldepths_inorder=>'1,0,2,1,0',
          Rdepths_inorder=>'0,0,1,1,1',
        vpar=>'0,1,0,3,4', vpar_postorder=>'2,0,4,5,0',
        Lweights=>'1,2,1,2,3', Rweights=>'1,4,1,1,1',
      },
      { balanced=>'1,1,0,1,0,0,1,0,1,0',
          balanced_postorder=>'1,1,0,0,1,1,1,0,0,0',
        Ldepths=>'0,1,1,0,0', Rdepths_postorder=>'1,0,2,1,0',
        Bdepths_inorder=>'1,2,0,1,2', Ldepths_inorder=>'1,1,0,0,0',
          Rdepths_inorder=>'0,1,0,1,2',
        vpar=>'0,1,1,0,0', vpar_postorder=>'3,3,0,0,0',
        Lweights=>'1,1,3,1,1', Rweights=>'2,1,3,2,1',
      },
      { balanced=>'1,1,0,1,0,0,1,1,0,0',
          balanced_postorder=>'1,1,0,0,1,1,0,1,0,0',
        Ldepths=>'0,1,1,0,1', Rdepths_postorder=>'1,0,1,1,0',
        Bdepths_inorder=>'1,2,0,2,1', Ldepths_inorder=>'1,1,0,1,0',
          Rdepths_inorder=>'0,1,0,1,1',
        vpar=>'0,1,1,0,4', vpar_postorder=>'3,3,0,5,0',
        Lweights=>'1,1,3,1,2', Rweights=>'2,1,3,1,1',
      },
      { balanced=>'1,1,0,1,0,1,0,0,1,0',
          balanced_postorder=>'1,1,1,0,0,0,1,1,0,0',
        Ldepths=>'0,1,1,1,0', Rdepths_postorder=>'2,1,0,1,0',
        Bdepths_inorder=>'1,2,3,0,1', Ldepths_inorder=>'1,1,1,0,0',
          Rdepths_inorder=>'0,1,2,0,1',
        vpar=>'0,1,1,1,0', vpar_postorder=>'4,4,4,0,0',
        Lweights=>'1,1,1,4,1', Rweights=>'3,2,1,2,1',
      },
      { balanced=>'1,1,0,1,0,1,0,1,0,0',
          balanced_postorder=>'1,1,1,1,0,0,0,0,1,0',
        Ldepths=>'0,1,1,1,1', Rdepths_postorder=>'3,2,1,0,0',
        Bdepths_inorder=>'1,2,3,4,0', Ldepths_inorder=>'1,1,1,1,0',
          Rdepths_inorder=>'0,1,2,3,0',
        vpar=>'0,1,1,1,1', vpar_postorder=>'5,5,5,5,0',
        Lweights=>'1,1,1,1,5', Rweights=>'4,3,2,1,1',
      },
      { balanced=>'1,1,0,1,0,1,1,0,0,0',
          balanced_postorder=>'1,1,1,0,1,0,0,0,1,0',
        Ldepths=>'0,1,1,1,2', Rdepths_postorder=>'2,2,1,0,0',
        Bdepths_inorder=>'1,2,4,3,0', Ldepths_inorder=>'1,1,2,1,0',
          Rdepths_inorder=>'0,1,2,2,0',
        vpar=>'0,1,1,1,4', vpar_postorder=>'5,5,4,5,0',
        Lweights=>'1,1,1,2,5', Rweights=>'4,3,1,1,1',
      },
      { balanced=>'1,1,0,1,1,0,0,0,1,0',
          balanced_postorder=>'1,1,0,1,0,0,1,1,0,0',
        Ldepths=>'0,1,1,2,0', Rdepths_postorder=>'1,1,0,1,0',
        Bdepths_inorder=>'1,3,2,0,1', Ldepths_inorder=>'1,2,1,0,0',
          Rdepths_inorder=>'0,1,1,0,1',
        vpar=>'0,1,1,3,0', vpar_postorder=>'4,3,4,0,0',
        Lweights=>'1,1,2,4,1', Rweights=>'3,1,1,2,1',
      },
      { balanced=>'1,1,0,1,1,0,0,1,0,0',
          balanced_postorder=>'1,1,0,1,1,0,0,0,1,0',
        Ldepths=>'0,1,1,2,1', Rdepths_postorder=>'1,2,1,0,0',
        Bdepths_inorder=>'1,3,2,3,0', Ldepths_inorder=>'1,2,1,1,0',
          Rdepths_inorder=>'0,1,1,2,0',
        vpar=>'0,1,1,3,1', vpar_postorder=>'5,3,5,5,0',
        Lweights=>'1,1,2,1,5', Rweights=>'4,1,2,1,1',
      },
      { balanced=>'1,1,0,1,1,0,1,0,0,0',
          balanced_postorder=>'1,1,1,0,0,1,0,0,1,0',
        Ldepths=>'0,1,1,2,2', Rdepths_postorder=>'2,1,1,0,0',
        Bdepths_inorder=>'1,3,4,2,0', Ldepths_inorder=>'1,2,2,1,0',
          Rdepths_inorder=>'0,1,2,1,0',
        vpar=>'0,1,1,3,3', vpar_postorder=>'5,4,4,5,0',
        Lweights=>'1,1,1,3,5', Rweights=>'4,2,1,1,1',
      },
      { balanced=>'1,1,0,1,1,1,0,0,0,0',
          balanced_postorder=>'1,1,0,1,0,1,0,0,1,0',
        Ldepths=>'0,1,1,2,3', Rdepths_postorder=>'1,1,1,0,0',
        Bdepths_inorder=>'1,4,3,2,0', Ldepths_inorder=>'1,3,2,1,0',
          Rdepths_inorder=>'0,1,1,1,0',
        vpar=>'0,1,1,3,4', vpar_postorder=>'5,3,4,5,0',
        Lweights=>'1,1,2,3,5', Rweights=>'4,1,1,1,1',
      },
      { balanced=>'1,1,1,0,0,0,1,0,1,0',
          balanced_postorder=>'1,0,1,0,1,1,1,0,0,0',
        Ldepths=>'0,1,2,0,0', Rdepths_postorder=>'0,0,2,1,0',
        Bdepths_inorder=>'2,1,0,1,2', Ldepths_inorder=>'2,1,0,0,0',
          Rdepths_inorder=>'0,0,0,1,2',
        vpar=>'0,1,2,0,0', vpar_postorder=>'2,3,0,0,0',
        Lweights=>'1,2,3,1,1', Rweights=>'1,1,3,2,1',
      },
      { balanced=>'1,1,1,0,0,0,1,1,0,0',
          balanced_postorder=>'1,0,1,0,1,1,0,1,0,0',
        Ldepths=>'0,1,2,0,1', Rdepths_postorder=>'0,0,1,1,0',
        Bdepths_inorder=>'2,1,0,2,1', Ldepths_inorder=>'2,1,0,1,0',
          Rdepths_inorder=>'0,0,0,1,1',
        vpar=>'0,1,2,0,4', vpar_postorder=>'2,3,0,5,0',
        Lweights=>'1,2,3,1,2', Rweights=>'1,1,3,1,1',
      },
      { balanced=>'1,1,1,0,0,1,0,0,1,0',
          balanced_postorder=>'1,0,1,1,0,0,1,1,0,0',
        Ldepths=>'0,1,2,1,0', Rdepths_postorder=>'0,1,0,1,0',
        Bdepths_inorder=>'2,1,2,0,1', Ldepths_inorder=>'2,1,1,0,0',
          Rdepths_inorder=>'0,0,1,0,1',
        vpar=>'0,1,2,1,0', vpar_postorder=>'2,4,4,0,0',
        Lweights=>'1,2,1,4,1', Rweights=>'1,2,1,2,1',
      },
      { balanced=>'1,1,1,0,0,1,0,1,0,0',
          balanced_postorder=>'1,0,1,1,1,0,0,0,1,0',
        Ldepths=>'0,1,2,1,1', Rdepths_postorder=>'0,2,1,0,0',
        Bdepths_inorder=>'2,1,2,3,0', Ldepths_inorder=>'2,1,1,1,0',
          Rdepths_inorder=>'0,0,1,2,0',
        vpar=>'0,1,2,1,1', vpar_postorder=>'2,5,5,5,0',
        Lweights=>'1,2,1,1,5', Rweights=>'1,3,2,1,1',
      },
      { balanced=>'1,1,1,0,0,1,1,0,0,0',
          balanced_postorder=>'1,0,1,1,0,1,0,0,1,0',
        Ldepths=>'0,1,2,1,2', Rdepths_postorder=>'0,1,1,0,0',
        Bdepths_inorder=>'2,1,3,2,0', Ldepths_inorder=>'2,1,2,1,0',
          Rdepths_inorder=>'0,0,1,1,0',
        vpar=>'0,1,2,1,4', vpar_postorder=>'2,5,4,5,0',
        Lweights=>'1,2,1,2,5', Rweights=>'1,3,1,1,1',
      },
      { balanced=>'1,1,1,0,1,0,0,0,1,0',
          balanced_postorder=>'1,1,0,0,1,0,1,1,0,0',
        Ldepths=>'0,1,2,2,0', Rdepths_postorder=>'1,0,0,1,0',
        Bdepths_inorder=>'2,3,1,0,1', Ldepths_inorder=>'2,2,1,0,0',
          Rdepths_inorder=>'0,1,0,0,1',
        vpar=>'0,1,2,2,0', vpar_postorder=>'3,3,4,0,0',
        Lweights=>'1,1,3,4,1', Rweights=>'2,1,1,2,1',
      },
      { balanced=>'1,1,1,0,1,0,0,1,0,0',
          balanced_postorder=>'1,1,0,0,1,1,0,0,1,0',
        Ldepths=>'0,1,2,2,1', Rdepths_postorder=>'1,0,1,0,0',
        Bdepths_inorder=>'2,3,1,2,0', Ldepths_inorder=>'2,2,1,1,0',
          Rdepths_inorder=>'0,1,0,1,0',
        vpar=>'0,1,2,2,1', vpar_postorder=>'3,3,5,5,0',
        Lweights=>'1,1,3,1,5', Rweights=>'2,1,2,1,1',
      },
      { balanced=>'1,1,1,0,1,0,1,0,0,0',
          balanced_postorder=>'1,1,1,0,0,0,1,0,1,0',
        Ldepths=>'0,1,2,2,2', Rdepths_postorder=>'2,1,0,0,0',
        Bdepths_inorder=>'2,3,4,1,0', Ldepths_inorder=>'2,2,2,1,0',
          Rdepths_inorder=>'0,1,2,0,0',
        vpar=>'0,1,2,2,2', vpar_postorder=>'4,4,4,5,0',
        Lweights=>'1,1,1,4,5', Rweights=>'3,2,1,1,1',
      },
      { balanced=>'1,1,1,0,1,1,0,0,0,0',
          balanced_postorder=>'1,1,0,1,0,0,1,0,1,0',
        Ldepths=>'0,1,2,2,3', Rdepths_postorder=>'1,1,0,0,0',
        Bdepths_inorder=>'2,4,3,1,0', Ldepths_inorder=>'2,3,2,1,0',
          Rdepths_inorder=>'0,1,1,0,0',
        vpar=>'0,1,2,2,4', vpar_postorder=>'4,3,4,5,0',
        Lweights=>'1,1,2,4,5', Rweights=>'3,1,1,1,1',
      },
      { balanced=>'1,1,1,1,0,0,0,0,1,0',
          balanced_postorder=>'1,0,1,0,1,0,1,1,0,0',
        Ldepths=>'0,1,2,3,0', Rdepths_postorder=>'0,0,0,1,0',
        Bdepths_inorder=>'3,2,1,0,1', Ldepths_inorder=>'3,2,1,0,0',
          Rdepths_inorder=>'0,0,0,0,1',
        vpar=>'0,1,2,3,0', vpar_postorder=>'2,3,4,0,0',
        Lweights=>'1,2,3,4,1', Rweights=>'1,1,1,2,1',
      },
      { balanced=>'1,1,1,1,0,0,0,1,0,0',
          balanced_postorder=>'1,0,1,0,1,1,0,0,1,0',
        Ldepths=>'0,1,2,3,1', Rdepths_postorder=>'0,0,1,0,0',
        Bdepths_inorder=>'3,2,1,2,0', Ldepths_inorder=>'3,2,1,1,0',
          Rdepths_inorder=>'0,0,0,1,0',
        vpar=>'0,1,2,3,1', vpar_postorder=>'2,3,5,5,0',
        Lweights=>'1,2,3,1,5', Rweights=>'1,1,2,1,1',
      },
      { balanced=>'1,1,1,1,0,0,1,0,0,0',
          balanced_postorder=>'1,0,1,1,0,0,1,0,1,0',
        Ldepths=>'0,1,2,3,2', Rdepths_postorder=>'0,1,0,0,0',
        Bdepths_inorder=>'3,2,3,1,0', Ldepths_inorder=>'3,2,2,1,0',
          Rdepths_inorder=>'0,0,1,0,0',
        vpar=>'0,1,2,3,2', vpar_postorder=>'2,4,4,5,0',
        Lweights=>'1,2,1,4,5', Rweights=>'1,2,1,1,1',
      },
      { balanced=>'1,1,1,1,0,1,0,0,0,0',
          balanced_postorder=>'1,1,0,0,1,0,1,0,1,0',
        Ldepths=>'0,1,2,3,3', Rdepths_postorder=>'1,0,0,0,0',
        Bdepths_inorder=>'3,4,2,1,0', Ldepths_inorder=>'3,3,2,1,0',
          Rdepths_inorder=>'0,1,0,0,0',
        vpar=>'0,1,2,3,3', vpar_postorder=>'3,3,4,5,0',
        Lweights=>'1,1,3,4,5', Rweights=>'2,1,1,1,1',
      },
      { balanced=>'1,1,1,1,1,0,0,0,0,0',
          balanced_postorder=>'1,0,1,0,1,0,1,0,1,0',
        Ldepths=>'0,1,2,3,4', Rdepths_postorder=>'0,0,0,0,0',
        Bdepths_inorder=>'4,3,2,1,0', Ldepths_inorder=>'4,3,2,1,0',
          Rdepths_inorder=>'0,0,0,0,0',
        vpar=>'0,1,2,3,4', vpar_postorder=>'2,3,4,5,0',
        Lweights=>'1,2,3,4,5', Rweights=>'1,1,1,1,1',
      },
     ],
     [  # count 132
      { balanced=>'1,0,1,0,1,0,1,0,1,0,1,0',
          balanced_postorder=>'1,1,1,1,1,1,0,0,0,0,0,0',
        Ldepths=>'0,0,0,0,0,0', Rdepths_postorder=>'5,4,3,2,1,0',
        Bdepths_inorder=>'0,1,2,3,4,5', Ldepths_inorder=>'0,0,0,0,0,0',
          Rdepths_inorder=>'0,1,2,3,4,5',
        vpar=>'0,0,0,0,0,0', vpar_postorder=>'0,0,0,0,0,0',
        Lweights=>'1,1,1,1,1,1', Rweights=>'6,5,4,3,2,1',
      },
      { balanced=>'1,0,1,0,1,0,1,0,1,1,0,0',
          balanced_postorder=>'1,1,1,1,1,0,1,0,0,0,0,0',
        Ldepths=>'0,0,0,0,0,1', Rdepths_postorder=>'4,4,3,2,1,0',
        Bdepths_inorder=>'0,1,2,3,5,4', Ldepths_inorder=>'0,0,0,0,1,0',
          Rdepths_inorder=>'0,1,2,3,4,4',
        vpar=>'0,0,0,0,0,5', vpar_postorder=>'0,0,0,0,6,0',
        Lweights=>'1,1,1,1,1,2', Rweights=>'6,5,4,3,1,1',
      },
      { balanced=>'1,0,1,0,1,0,1,1,0,0,1,0',
          balanced_postorder=>'1,1,1,1,0,1,1,0,0,0,0,0',
        Ldepths=>'0,0,0,0,1,0', Rdepths_postorder=>'3,4,3,2,1,0',
        Bdepths_inorder=>'0,1,2,4,3,4', Ldepths_inorder=>'0,0,0,1,0,0',
          Rdepths_inorder=>'0,1,2,3,3,4',
        vpar=>'0,0,0,0,4,0', vpar_postorder=>'0,0,0,5,0,0',
        Lweights=>'1,1,1,1,2,1', Rweights=>'6,5,4,1,2,1',
      },
      { balanced=>'1,0,1,0,1,0,1,1,0,1,0,0',
          balanced_postorder=>'1,1,1,1,1,0,0,1,0,0,0,0',
        Ldepths=>'0,0,0,0,1,1', Rdepths_postorder=>'4,3,3,2,1,0',
        Bdepths_inorder=>'0,1,2,4,5,3', Ldepths_inorder=>'0,0,0,1,1,0',
          Rdepths_inorder=>'0,1,2,3,4,3',
        vpar=>'0,0,0,0,4,4', vpar_postorder=>'0,0,0,6,6,0',
        Lweights=>'1,1,1,1,1,3', Rweights=>'6,5,4,2,1,1',
      },
      { balanced=>'1,0,1,0,1,0,1,1,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,1,0,1,0,0,0,0',
        Ldepths=>'0,0,0,0,1,2', Rdepths_postorder=>'3,3,3,2,1,0',
        Bdepths_inorder=>'0,1,2,5,4,3', Ldepths_inorder=>'0,0,0,2,1,0',
          Rdepths_inorder=>'0,1,2,3,3,3',
        vpar=>'0,0,0,0,4,5', vpar_postorder=>'0,0,0,5,6,0',
        Lweights=>'1,1,1,1,2,3', Rweights=>'6,5,4,1,1,1',
      },
      { balanced=>'1,0,1,0,1,1,0,0,1,0,1,0',
          balanced_postorder=>'1,1,1,0,1,1,1,0,0,0,0,0',
        Ldepths=>'0,0,0,1,0,0', Rdepths_postorder=>'2,4,3,2,1,0',
        Bdepths_inorder=>'0,1,3,2,3,4', Ldepths_inorder=>'0,0,1,0,0,0',
          Rdepths_inorder=>'0,1,2,2,3,4',
        vpar=>'0,0,0,3,0,0', vpar_postorder=>'0,0,4,0,0,0',
        Lweights=>'1,1,1,2,1,1', Rweights=>'6,5,1,3,2,1',
      },
      { balanced=>'1,0,1,0,1,1,0,0,1,1,0,0',
          balanced_postorder=>'1,1,1,0,1,1,0,1,0,0,0,0',
        Ldepths=>'0,0,0,1,0,1', Rdepths_postorder=>'2,3,3,2,1,0',
        Bdepths_inorder=>'0,1,3,2,4,3', Ldepths_inorder=>'0,0,1,0,1,0',
          Rdepths_inorder=>'0,1,2,2,3,3',
        vpar=>'0,0,0,3,0,5', vpar_postorder=>'0,0,4,0,6,0',
        Lweights=>'1,1,1,2,1,2', Rweights=>'6,5,1,3,1,1',
      },
      { balanced=>'1,0,1,0,1,1,0,1,0,0,1,0',
          balanced_postorder=>'1,1,1,1,0,0,1,1,0,0,0,0',
        Ldepths=>'0,0,0,1,1,0', Rdepths_postorder=>'3,2,3,2,1,0',
        Bdepths_inorder=>'0,1,3,4,2,3', Ldepths_inorder=>'0,0,1,1,0,0',
          Rdepths_inorder=>'0,1,2,3,2,3',
        vpar=>'0,0,0,3,3,0', vpar_postorder=>'0,0,5,5,0,0',
        Lweights=>'1,1,1,1,3,1', Rweights=>'6,5,2,1,2,1',
      },
      { balanced=>'1,0,1,0,1,1,0,1,0,1,0,0',
          balanced_postorder=>'1,1,1,1,1,0,0,0,1,0,0,0',
        Ldepths=>'0,0,0,1,1,1', Rdepths_postorder=>'4,3,2,2,1,0',
        Bdepths_inorder=>'0,1,3,4,5,2', Ldepths_inorder=>'0,0,1,1,1,0',
          Rdepths_inorder=>'0,1,2,3,4,2',
        vpar=>'0,0,0,3,3,3', vpar_postorder=>'0,0,6,6,6,0',
        Lweights=>'1,1,1,1,1,4', Rweights=>'6,5,3,2,1,1',
      },
      { balanced=>'1,0,1,0,1,1,0,1,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,1,0,0,1,0,0,0',
        Ldepths=>'0,0,0,1,1,2', Rdepths_postorder=>'3,3,2,2,1,0',
        Bdepths_inorder=>'0,1,3,5,4,2', Ldepths_inorder=>'0,0,1,2,1,0',
          Rdepths_inorder=>'0,1,2,3,3,2',
        vpar=>'0,0,0,3,3,5', vpar_postorder=>'0,0,6,5,6,0',
        Lweights=>'1,1,1,1,2,4', Rweights=>'6,5,3,1,1,1',
      },
      { balanced=>'1,0,1,0,1,1,1,0,0,0,1,0',
          balanced_postorder=>'1,1,1,0,1,0,1,1,0,0,0,0',
        Ldepths=>'0,0,0,1,2,0', Rdepths_postorder=>'2,2,3,2,1,0',
        Bdepths_inorder=>'0,1,4,3,2,3', Ldepths_inorder=>'0,0,2,1,0,0',
          Rdepths_inorder=>'0,1,2,2,2,3',
        vpar=>'0,0,0,3,4,0', vpar_postorder=>'0,0,4,5,0,0',
        Lweights=>'1,1,1,2,3,1', Rweights=>'6,5,1,1,2,1',
      },
      { balanced=>'1,0,1,0,1,1,1,0,0,1,0,0',
          balanced_postorder=>'1,1,1,0,1,1,0,0,1,0,0,0',
        Ldepths=>'0,0,0,1,2,1', Rdepths_postorder=>'2,3,2,2,1,0',
        Bdepths_inorder=>'0,1,4,3,4,2', Ldepths_inorder=>'0,0,2,1,1,0',
          Rdepths_inorder=>'0,1,2,2,3,2',
        vpar=>'0,0,0,3,4,3', vpar_postorder=>'0,0,4,6,6,0',
        Lweights=>'1,1,1,2,1,4', Rweights=>'6,5,1,2,1,1',
      },
      { balanced=>'1,0,1,0,1,1,1,0,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,0,1,0,1,0,0,0',
        Ldepths=>'0,0,0,1,2,2', Rdepths_postorder=>'3,2,2,2,1,0',
        Bdepths_inorder=>'0,1,4,5,3,2', Ldepths_inorder=>'0,0,2,2,1,0',
          Rdepths_inorder=>'0,1,2,3,2,2',
        vpar=>'0,0,0,3,4,4', vpar_postorder=>'0,0,5,5,6,0',
        Lweights=>'1,1,1,1,3,4', Rweights=>'6,5,2,1,1,1',
      },
      { balanced=>'1,0,1,0,1,1,1,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,1,0,1,0,1,0,0,0',
        Ldepths=>'0,0,0,1,2,3', Rdepths_postorder=>'2,2,2,2,1,0',
        Bdepths_inorder=>'0,1,5,4,3,2', Ldepths_inorder=>'0,0,3,2,1,0',
          Rdepths_inorder=>'0,1,2,2,2,2',
        vpar=>'0,0,0,3,4,5', vpar_postorder=>'0,0,4,5,6,0',
        Lweights=>'1,1,1,2,3,4', Rweights=>'6,5,1,1,1,1',
      },
      { balanced=>'1,0,1,1,0,0,1,0,1,0,1,0',
          balanced_postorder=>'1,1,0,1,1,1,1,0,0,0,0,0',
        Ldepths=>'0,0,1,0,0,0', Rdepths_postorder=>'1,4,3,2,1,0',
        Bdepths_inorder=>'0,2,1,2,3,4', Ldepths_inorder=>'0,1,0,0,0,0',
          Rdepths_inorder=>'0,1,1,2,3,4',
        vpar=>'0,0,2,0,0,0', vpar_postorder=>'0,3,0,0,0,0',
        Lweights=>'1,1,2,1,1,1', Rweights=>'6,1,4,3,2,1',
      },
      { balanced=>'1,0,1,1,0,0,1,0,1,1,0,0',
          balanced_postorder=>'1,1,0,1,1,1,0,1,0,0,0,0',
        Ldepths=>'0,0,1,0,0,1', Rdepths_postorder=>'1,3,3,2,1,0',
        Bdepths_inorder=>'0,2,1,2,4,3', Ldepths_inorder=>'0,1,0,0,1,0',
          Rdepths_inorder=>'0,1,1,2,3,3',
        vpar=>'0,0,2,0,0,5', vpar_postorder=>'0,3,0,0,6,0',
        Lweights=>'1,1,2,1,1,2', Rweights=>'6,1,4,3,1,1',
      },
      { balanced=>'1,0,1,1,0,0,1,1,0,0,1,0',
          balanced_postorder=>'1,1,0,1,1,0,1,1,0,0,0,0',
        Ldepths=>'0,0,1,0,1,0', Rdepths_postorder=>'1,2,3,2,1,0',
        Bdepths_inorder=>'0,2,1,3,2,3', Ldepths_inorder=>'0,1,0,1,0,0',
          Rdepths_inorder=>'0,1,1,2,2,3',
        vpar=>'0,0,2,0,4,0', vpar_postorder=>'0,3,0,5,0,0',
        Lweights=>'1,1,2,1,2,1', Rweights=>'6,1,4,1,2,1',
      },
      { balanced=>'1,0,1,1,0,0,1,1,0,1,0,0',
          balanced_postorder=>'1,1,0,1,1,1,0,0,1,0,0,0',
        Ldepths=>'0,0,1,0,1,1', Rdepths_postorder=>'1,3,2,2,1,0',
        Bdepths_inorder=>'0,2,1,3,4,2', Ldepths_inorder=>'0,1,0,1,1,0',
          Rdepths_inorder=>'0,1,1,2,3,2',
        vpar=>'0,0,2,0,4,4', vpar_postorder=>'0,3,0,6,6,0',
        Lweights=>'1,1,2,1,1,3', Rweights=>'6,1,4,2,1,1',
      },
      { balanced=>'1,0,1,1,0,0,1,1,1,0,0,0',
          balanced_postorder=>'1,1,0,1,1,0,1,0,1,0,0,0',
        Ldepths=>'0,0,1,0,1,2', Rdepths_postorder=>'1,2,2,2,1,0',
        Bdepths_inorder=>'0,2,1,4,3,2', Ldepths_inorder=>'0,1,0,2,1,0',
          Rdepths_inorder=>'0,1,1,2,2,2',
        vpar=>'0,0,2,0,4,5', vpar_postorder=>'0,3,0,5,6,0',
        Lweights=>'1,1,2,1,2,3', Rweights=>'6,1,4,1,1,1',
      },
      { balanced=>'1,0,1,1,0,1,0,0,1,0,1,0',
          balanced_postorder=>'1,1,1,0,0,1,1,1,0,0,0,0',
        Ldepths=>'0,0,1,1,0,0', Rdepths_postorder=>'2,1,3,2,1,0',
        Bdepths_inorder=>'0,2,3,1,2,3', Ldepths_inorder=>'0,1,1,0,0,0',
          Rdepths_inorder=>'0,1,2,1,2,3',
        vpar=>'0,0,2,2,0,0', vpar_postorder=>'0,4,4,0,0,0',
        Lweights=>'1,1,1,3,1,1', Rweights=>'6,2,1,3,2,1',
      },
      { balanced=>'1,0,1,1,0,1,0,0,1,1,0,0',
          balanced_postorder=>'1,1,1,0,0,1,1,0,1,0,0,0',
        Ldepths=>'0,0,1,1,0,1', Rdepths_postorder=>'2,1,2,2,1,0',
        Bdepths_inorder=>'0,2,3,1,3,2', Ldepths_inorder=>'0,1,1,0,1,0',
          Rdepths_inorder=>'0,1,2,1,2,2',
        vpar=>'0,0,2,2,0,5', vpar_postorder=>'0,4,4,0,6,0',
        Lweights=>'1,1,1,3,1,2', Rweights=>'6,2,1,3,1,1',
      },
      { balanced=>'1,0,1,1,0,1,0,1,0,0,1,0',
          balanced_postorder=>'1,1,1,1,0,0,0,1,1,0,0,0',
        Ldepths=>'0,0,1,1,1,0', Rdepths_postorder=>'3,2,1,2,1,0',
        Bdepths_inorder=>'0,2,3,4,1,2', Ldepths_inorder=>'0,1,1,1,0,0',
          Rdepths_inorder=>'0,1,2,3,1,2',
        vpar=>'0,0,2,2,2,0', vpar_postorder=>'0,5,5,5,0,0',
        Lweights=>'1,1,1,1,4,1', Rweights=>'6,3,2,1,2,1',
      },
      { balanced=>'1,0,1,1,0,1,0,1,0,1,0,0',
          balanced_postorder=>'1,1,1,1,1,0,0,0,0,1,0,0',
        Ldepths=>'0,0,1,1,1,1', Rdepths_postorder=>'4,3,2,1,1,0',
        Bdepths_inorder=>'0,2,3,4,5,1', Ldepths_inorder=>'0,1,1,1,1,0',
          Rdepths_inorder=>'0,1,2,3,4,1',
        vpar=>'0,0,2,2,2,2', vpar_postorder=>'0,6,6,6,6,0',
        Lweights=>'1,1,1,1,1,5', Rweights=>'6,4,3,2,1,1',
      },
      { balanced=>'1,0,1,1,0,1,0,1,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,1,0,0,0,1,0,0',
        Ldepths=>'0,0,1,1,1,2', Rdepths_postorder=>'3,3,2,1,1,0',
        Bdepths_inorder=>'0,2,3,5,4,1', Ldepths_inorder=>'0,1,1,2,1,0',
          Rdepths_inorder=>'0,1,2,3,3,1',
        vpar=>'0,0,2,2,2,5', vpar_postorder=>'0,6,6,5,6,0',
        Lweights=>'1,1,1,1,2,5', Rweights=>'6,4,3,1,1,1',
      },
      { balanced=>'1,0,1,1,0,1,1,0,0,0,1,0',
          balanced_postorder=>'1,1,1,0,1,0,0,1,1,0,0,0',
        Ldepths=>'0,0,1,1,2,0', Rdepths_postorder=>'2,2,1,2,1,0',
        Bdepths_inorder=>'0,2,4,3,1,2', Ldepths_inorder=>'0,1,2,1,0,0',
          Rdepths_inorder=>'0,1,2,2,1,2',
        vpar=>'0,0,2,2,4,0', vpar_postorder=>'0,5,4,5,0,0',
        Lweights=>'1,1,1,2,4,1', Rweights=>'6,3,1,1,2,1',
      },
      { balanced=>'1,0,1,1,0,1,1,0,0,1,0,0',
          balanced_postorder=>'1,1,1,0,1,1,0,0,0,1,0,0',
        Ldepths=>'0,0,1,1,2,1', Rdepths_postorder=>'2,3,2,1,1,0',
        Bdepths_inorder=>'0,2,4,3,4,1', Ldepths_inorder=>'0,1,2,1,1,0',
          Rdepths_inorder=>'0,1,2,2,3,1',
        vpar=>'0,0,2,2,4,2', vpar_postorder=>'0,6,4,6,6,0',
        Lweights=>'1,1,1,2,1,5', Rweights=>'6,4,1,2,1,1',
      },
      { balanced=>'1,0,1,1,0,1,1,0,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,0,1,0,0,1,0,0',
        Ldepths=>'0,0,1,1,2,2', Rdepths_postorder=>'3,2,2,1,1,0',
        Bdepths_inorder=>'0,2,4,5,3,1', Ldepths_inorder=>'0,1,2,2,1,0',
          Rdepths_inorder=>'0,1,2,3,2,1',
        vpar=>'0,0,2,2,4,4', vpar_postorder=>'0,6,5,5,6,0',
        Lweights=>'1,1,1,1,3,5', Rweights=>'6,4,2,1,1,1',
      },
      { balanced=>'1,0,1,1,0,1,1,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,1,0,1,0,0,1,0,0',
        Ldepths=>'0,0,1,1,2,3', Rdepths_postorder=>'2,2,2,1,1,0',
        Bdepths_inorder=>'0,2,5,4,3,1', Ldepths_inorder=>'0,1,3,2,1,0',
          Rdepths_inorder=>'0,1,2,2,2,1',
        vpar=>'0,0,2,2,4,5', vpar_postorder=>'0,6,4,5,6,0',
        Lweights=>'1,1,1,2,3,5', Rweights=>'6,4,1,1,1,1',
      },
      { balanced=>'1,0,1,1,1,0,0,0,1,0,1,0',
          balanced_postorder=>'1,1,0,1,0,1,1,1,0,0,0,0',
        Ldepths=>'0,0,1,2,0,0', Rdepths_postorder=>'1,1,3,2,1,0',
        Bdepths_inorder=>'0,3,2,1,2,3', Ldepths_inorder=>'0,2,1,0,0,0',
          Rdepths_inorder=>'0,1,1,1,2,3',
        vpar=>'0,0,2,3,0,0', vpar_postorder=>'0,3,4,0,0,0',
        Lweights=>'1,1,2,3,1,1', Rweights=>'6,1,1,3,2,1',
      },
      { balanced=>'1,0,1,1,1,0,0,0,1,1,0,0',
          balanced_postorder=>'1,1,0,1,0,1,1,0,1,0,0,0',
        Ldepths=>'0,0,1,2,0,1', Rdepths_postorder=>'1,1,2,2,1,0',
        Bdepths_inorder=>'0,3,2,1,3,2', Ldepths_inorder=>'0,2,1,0,1,0',
          Rdepths_inorder=>'0,1,1,1,2,2',
        vpar=>'0,0,2,3,0,5', vpar_postorder=>'0,3,4,0,6,0',
        Lweights=>'1,1,2,3,1,2', Rweights=>'6,1,1,3,1,1',
      },
      { balanced=>'1,0,1,1,1,0,0,1,0,0,1,0',
          balanced_postorder=>'1,1,0,1,1,0,0,1,1,0,0,0',
        Ldepths=>'0,0,1,2,1,0', Rdepths_postorder=>'1,2,1,2,1,0',
        Bdepths_inorder=>'0,3,2,3,1,2', Ldepths_inorder=>'0,2,1,1,0,0',
          Rdepths_inorder=>'0,1,1,2,1,2',
        vpar=>'0,0,2,3,2,0', vpar_postorder=>'0,3,5,5,0,0',
        Lweights=>'1,1,2,1,4,1', Rweights=>'6,1,2,1,2,1',
      },
      { balanced=>'1,0,1,1,1,0,0,1,0,1,0,0',
          balanced_postorder=>'1,1,0,1,1,1,0,0,0,1,0,0',
        Ldepths=>'0,0,1,2,1,1', Rdepths_postorder=>'1,3,2,1,1,0',
        Bdepths_inorder=>'0,3,2,3,4,1', Ldepths_inorder=>'0,2,1,1,1,0',
          Rdepths_inorder=>'0,1,1,2,3,1',
        vpar=>'0,0,2,3,2,2', vpar_postorder=>'0,3,6,6,6,0',
        Lweights=>'1,1,2,1,1,5', Rweights=>'6,1,3,2,1,1',
      },
      { balanced=>'1,0,1,1,1,0,0,1,1,0,0,0',
          balanced_postorder=>'1,1,0,1,1,0,1,0,0,1,0,0',
        Ldepths=>'0,0,1,2,1,2', Rdepths_postorder=>'1,2,2,1,1,0',
        Bdepths_inorder=>'0,3,2,4,3,1', Ldepths_inorder=>'0,2,1,2,1,0',
          Rdepths_inorder=>'0,1,1,2,2,1',
        vpar=>'0,0,2,3,2,5', vpar_postorder=>'0,3,6,5,6,0',
        Lweights=>'1,1,2,1,2,5', Rweights=>'6,1,3,1,1,1',
      },
      { balanced=>'1,0,1,1,1,0,1,0,0,0,1,0',
          balanced_postorder=>'1,1,1,0,0,1,0,1,1,0,0,0',
        Ldepths=>'0,0,1,2,2,0', Rdepths_postorder=>'2,1,1,2,1,0',
        Bdepths_inorder=>'0,3,4,2,1,2', Ldepths_inorder=>'0,2,2,1,0,0',
          Rdepths_inorder=>'0,1,2,1,1,2',
        vpar=>'0,0,2,3,3,0', vpar_postorder=>'0,4,4,5,0,0',
        Lweights=>'1,1,1,3,4,1', Rweights=>'6,2,1,1,2,1',
      },
      { balanced=>'1,0,1,1,1,0,1,0,0,1,0,0',
          balanced_postorder=>'1,1,1,0,0,1,1,0,0,1,0,0',
        Ldepths=>'0,0,1,2,2,1', Rdepths_postorder=>'2,1,2,1,1,0',
        Bdepths_inorder=>'0,3,4,2,3,1', Ldepths_inorder=>'0,2,2,1,1,0',
          Rdepths_inorder=>'0,1,2,1,2,1',
        vpar=>'0,0,2,3,3,2', vpar_postorder=>'0,4,4,6,6,0',
        Lweights=>'1,1,1,3,1,5', Rweights=>'6,2,1,2,1,1',
      },
      { balanced=>'1,0,1,1,1,0,1,0,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,0,0,1,0,1,0,0',
        Ldepths=>'0,0,1,2,2,2', Rdepths_postorder=>'3,2,1,1,1,0',
        Bdepths_inorder=>'0,3,4,5,2,1', Ldepths_inorder=>'0,2,2,2,1,0',
          Rdepths_inorder=>'0,1,2,3,1,1',
        vpar=>'0,0,2,3,3,3', vpar_postorder=>'0,5,5,5,6,0',
        Lweights=>'1,1,1,1,4,5', Rweights=>'6,3,2,1,1,1',
      },
      { balanced=>'1,0,1,1,1,0,1,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,1,0,0,1,0,1,0,0',
        Ldepths=>'0,0,1,2,2,3', Rdepths_postorder=>'2,2,1,1,1,0',
        Bdepths_inorder=>'0,3,5,4,2,1', Ldepths_inorder=>'0,2,3,2,1,0',
          Rdepths_inorder=>'0,1,2,2,1,1',
        vpar=>'0,0,2,3,3,5', vpar_postorder=>'0,5,4,5,6,0',
        Lweights=>'1,1,1,2,4,5', Rweights=>'6,3,1,1,1,1',
      },
      { balanced=>'1,0,1,1,1,1,0,0,0,0,1,0',
          balanced_postorder=>'1,1,0,1,0,1,0,1,1,0,0,0',
        Ldepths=>'0,0,1,2,3,0', Rdepths_postorder=>'1,1,1,2,1,0',
        Bdepths_inorder=>'0,4,3,2,1,2', Ldepths_inorder=>'0,3,2,1,0,0',
          Rdepths_inorder=>'0,1,1,1,1,2',
        vpar=>'0,0,2,3,4,0', vpar_postorder=>'0,3,4,5,0,0',
        Lweights=>'1,1,2,3,4,1', Rweights=>'6,1,1,1,2,1',
      },
      { balanced=>'1,0,1,1,1,1,0,0,0,1,0,0',
          balanced_postorder=>'1,1,0,1,0,1,1,0,0,1,0,0',
        Ldepths=>'0,0,1,2,3,1', Rdepths_postorder=>'1,1,2,1,1,0',
        Bdepths_inorder=>'0,4,3,2,3,1', Ldepths_inorder=>'0,3,2,1,1,0',
          Rdepths_inorder=>'0,1,1,1,2,1',
        vpar=>'0,0,2,3,4,2', vpar_postorder=>'0,3,4,6,6,0',
        Lweights=>'1,1,2,3,1,5', Rweights=>'6,1,1,2,1,1',
      },
      { balanced=>'1,0,1,1,1,1,0,0,1,0,0,0',
          balanced_postorder=>'1,1,0,1,1,0,0,1,0,1,0,0',
        Ldepths=>'0,0,1,2,3,2', Rdepths_postorder=>'1,2,1,1,1,0',
        Bdepths_inorder=>'0,4,3,4,2,1', Ldepths_inorder=>'0,3,2,2,1,0',
          Rdepths_inorder=>'0,1,1,2,1,1',
        vpar=>'0,0,2,3,4,3', vpar_postorder=>'0,3,5,5,6,0',
        Lweights=>'1,1,2,1,4,5', Rweights=>'6,1,2,1,1,1',
      },
      { balanced=>'1,0,1,1,1,1,0,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,0,1,0,1,0,1,0,0',
        Ldepths=>'0,0,1,2,3,3', Rdepths_postorder=>'2,1,1,1,1,0',
        Bdepths_inorder=>'0,4,5,3,2,1', Ldepths_inorder=>'0,3,3,2,1,0',
          Rdepths_inorder=>'0,1,2,1,1,1',
        vpar=>'0,0,2,3,4,4', vpar_postorder=>'0,4,4,5,6,0',
        Lweights=>'1,1,1,3,4,5', Rweights=>'6,2,1,1,1,1',
      },
      { balanced=>'1,0,1,1,1,1,1,0,0,0,0,0',
          balanced_postorder=>'1,1,0,1,0,1,0,1,0,1,0,0',
        Ldepths=>'0,0,1,2,3,4', Rdepths_postorder=>'1,1,1,1,1,0',
        Bdepths_inorder=>'0,5,4,3,2,1', Ldepths_inorder=>'0,4,3,2,1,0',
          Rdepths_inorder=>'0,1,1,1,1,1',
        vpar=>'0,0,2,3,4,5', vpar_postorder=>'0,3,4,5,6,0',
        Lweights=>'1,1,2,3,4,5', Rweights=>'6,1,1,1,1,1',
      },
      { balanced=>'1,1,0,0,1,0,1,0,1,0,1,0',
          balanced_postorder=>'1,0,1,1,1,1,1,0,0,0,0,0',
        Ldepths=>'0,1,0,0,0,0', Rdepths_postorder=>'0,4,3,2,1,0',
        Bdepths_inorder=>'1,0,1,2,3,4', Ldepths_inorder=>'1,0,0,0,0,0',
          Rdepths_inorder=>'0,0,1,2,3,4',
        vpar=>'0,1,0,0,0,0', vpar_postorder=>'2,0,0,0,0,0',
        Lweights=>'1,2,1,1,1,1', Rweights=>'1,5,4,3,2,1',
      },
      { balanced=>'1,1,0,0,1,0,1,0,1,1,0,0',
          balanced_postorder=>'1,0,1,1,1,1,0,1,0,0,0,0',
        Ldepths=>'0,1,0,0,0,1', Rdepths_postorder=>'0,3,3,2,1,0',
        Bdepths_inorder=>'1,0,1,2,4,3', Ldepths_inorder=>'1,0,0,0,1,0',
          Rdepths_inorder=>'0,0,1,2,3,3',
        vpar=>'0,1,0,0,0,5', vpar_postorder=>'2,0,0,0,6,0',
        Lweights=>'1,2,1,1,1,2', Rweights=>'1,5,4,3,1,1',
      },
      { balanced=>'1,1,0,0,1,0,1,1,0,0,1,0',
          balanced_postorder=>'1,0,1,1,1,0,1,1,0,0,0,0',
        Ldepths=>'0,1,0,0,1,0', Rdepths_postorder=>'0,2,3,2,1,0',
        Bdepths_inorder=>'1,0,1,3,2,3', Ldepths_inorder=>'1,0,0,1,0,0',
          Rdepths_inorder=>'0,0,1,2,2,3',
        vpar=>'0,1,0,0,4,0', vpar_postorder=>'2,0,0,5,0,0',
        Lweights=>'1,2,1,1,2,1', Rweights=>'1,5,4,1,2,1',
      },
      { balanced=>'1,1,0,0,1,0,1,1,0,1,0,0',
          balanced_postorder=>'1,0,1,1,1,1,0,0,1,0,0,0',
        Ldepths=>'0,1,0,0,1,1', Rdepths_postorder=>'0,3,2,2,1,0',
        Bdepths_inorder=>'1,0,1,3,4,2', Ldepths_inorder=>'1,0,0,1,1,0',
          Rdepths_inorder=>'0,0,1,2,3,2',
        vpar=>'0,1,0,0,4,4', vpar_postorder=>'2,0,0,6,6,0',
        Lweights=>'1,2,1,1,1,3', Rweights=>'1,5,4,2,1,1',
      },
      { balanced=>'1,1,0,0,1,0,1,1,1,0,0,0',
          balanced_postorder=>'1,0,1,1,1,0,1,0,1,0,0,0',
        Ldepths=>'0,1,0,0,1,2', Rdepths_postorder=>'0,2,2,2,1,0',
        Bdepths_inorder=>'1,0,1,4,3,2', Ldepths_inorder=>'1,0,0,2,1,0',
          Rdepths_inorder=>'0,0,1,2,2,2',
        vpar=>'0,1,0,0,4,5', vpar_postorder=>'2,0,0,5,6,0',
        Lweights=>'1,2,1,1,2,3', Rweights=>'1,5,4,1,1,1',
      },
      { balanced=>'1,1,0,0,1,1,0,0,1,0,1,0',
          balanced_postorder=>'1,0,1,1,0,1,1,1,0,0,0,0',
        Ldepths=>'0,1,0,1,0,0', Rdepths_postorder=>'0,1,3,2,1,0',
        Bdepths_inorder=>'1,0,2,1,2,3', Ldepths_inorder=>'1,0,1,0,0,0',
          Rdepths_inorder=>'0,0,1,1,2,3',
        vpar=>'0,1,0,3,0,0', vpar_postorder=>'2,0,4,0,0,0',
        Lweights=>'1,2,1,2,1,1', Rweights=>'1,5,1,3,2,1',
      },
      { balanced=>'1,1,0,0,1,1,0,0,1,1,0,0',
          balanced_postorder=>'1,0,1,1,0,1,1,0,1,0,0,0',
        Ldepths=>'0,1,0,1,0,1', Rdepths_postorder=>'0,1,2,2,1,0',
        Bdepths_inorder=>'1,0,2,1,3,2', Ldepths_inorder=>'1,0,1,0,1,0',
          Rdepths_inorder=>'0,0,1,1,2,2',
        vpar=>'0,1,0,3,0,5', vpar_postorder=>'2,0,4,0,6,0',
        Lweights=>'1,2,1,2,1,2', Rweights=>'1,5,1,3,1,1',
      },
      { balanced=>'1,1,0,0,1,1,0,1,0,0,1,0',
          balanced_postorder=>'1,0,1,1,1,0,0,1,1,0,0,0',
        Ldepths=>'0,1,0,1,1,0', Rdepths_postorder=>'0,2,1,2,1,0',
        Bdepths_inorder=>'1,0,2,3,1,2', Ldepths_inorder=>'1,0,1,1,0,0',
          Rdepths_inorder=>'0,0,1,2,1,2',
        vpar=>'0,1,0,3,3,0', vpar_postorder=>'2,0,5,5,0,0',
        Lweights=>'1,2,1,1,3,1', Rweights=>'1,5,2,1,2,1',
      },
      { balanced=>'1,1,0,0,1,1,0,1,0,1,0,0',
          balanced_postorder=>'1,0,1,1,1,1,0,0,0,1,0,0',
        Ldepths=>'0,1,0,1,1,1', Rdepths_postorder=>'0,3,2,1,1,0',
        Bdepths_inorder=>'1,0,2,3,4,1', Ldepths_inorder=>'1,0,1,1,1,0',
          Rdepths_inorder=>'0,0,1,2,3,1',
        vpar=>'0,1,0,3,3,3', vpar_postorder=>'2,0,6,6,6,0',
        Lweights=>'1,2,1,1,1,4', Rweights=>'1,5,3,2,1,1',
      },
      { balanced=>'1,1,0,0,1,1,0,1,1,0,0,0',
          balanced_postorder=>'1,0,1,1,1,0,1,0,0,1,0,0',
        Ldepths=>'0,1,0,1,1,2', Rdepths_postorder=>'0,2,2,1,1,0',
        Bdepths_inorder=>'1,0,2,4,3,1', Ldepths_inorder=>'1,0,1,2,1,0',
          Rdepths_inorder=>'0,0,1,2,2,1',
        vpar=>'0,1,0,3,3,5', vpar_postorder=>'2,0,6,5,6,0',
        Lweights=>'1,2,1,1,2,4', Rweights=>'1,5,3,1,1,1',
      },
      { balanced=>'1,1,0,0,1,1,1,0,0,0,1,0',
          balanced_postorder=>'1,0,1,1,0,1,0,1,1,0,0,0',
        Ldepths=>'0,1,0,1,2,0', Rdepths_postorder=>'0,1,1,2,1,0',
        Bdepths_inorder=>'1,0,3,2,1,2', Ldepths_inorder=>'1,0,2,1,0,0',
          Rdepths_inorder=>'0,0,1,1,1,2',
        vpar=>'0,1,0,3,4,0', vpar_postorder=>'2,0,4,5,0,0',
        Lweights=>'1,2,1,2,3,1', Rweights=>'1,5,1,1,2,1',
      },
      { balanced=>'1,1,0,0,1,1,1,0,0,1,0,0',
          balanced_postorder=>'1,0,1,1,0,1,1,0,0,1,0,0',
        Ldepths=>'0,1,0,1,2,1', Rdepths_postorder=>'0,1,2,1,1,0',
        Bdepths_inorder=>'1,0,3,2,3,1', Ldepths_inorder=>'1,0,2,1,1,0',
          Rdepths_inorder=>'0,0,1,1,2,1',
        vpar=>'0,1,0,3,4,3', vpar_postorder=>'2,0,4,6,6,0',
        Lweights=>'1,2,1,2,1,4', Rweights=>'1,5,1,2,1,1',
      },
      { balanced=>'1,1,0,0,1,1,1,0,1,0,0,0',
          balanced_postorder=>'1,0,1,1,1,0,0,1,0,1,0,0',
        Ldepths=>'0,1,0,1,2,2', Rdepths_postorder=>'0,2,1,1,1,0',
        Bdepths_inorder=>'1,0,3,4,2,1', Ldepths_inorder=>'1,0,2,2,1,0',
          Rdepths_inorder=>'0,0,1,2,1,1',
        vpar=>'0,1,0,3,4,4', vpar_postorder=>'2,0,5,5,6,0',
        Lweights=>'1,2,1,1,3,4', Rweights=>'1,5,2,1,1,1',
      },
      { balanced=>'1,1,0,0,1,1,1,1,0,0,0,0',
          balanced_postorder=>'1,0,1,1,0,1,0,1,0,1,0,0',
        Ldepths=>'0,1,0,1,2,3', Rdepths_postorder=>'0,1,1,1,1,0',
        Bdepths_inorder=>'1,0,4,3,2,1', Ldepths_inorder=>'1,0,3,2,1,0',
          Rdepths_inorder=>'0,0,1,1,1,1',
        vpar=>'0,1,0,3,4,5', vpar_postorder=>'2,0,4,5,6,0',
        Lweights=>'1,2,1,2,3,4', Rweights=>'1,5,1,1,1,1',
      },
      { balanced=>'1,1,0,1,0,0,1,0,1,0,1,0',
          balanced_postorder=>'1,1,0,0,1,1,1,1,0,0,0,0',
        Ldepths=>'0,1,1,0,0,0', Rdepths_postorder=>'1,0,3,2,1,0',
        Bdepths_inorder=>'1,2,0,1,2,3', Ldepths_inorder=>'1,1,0,0,0,0',
          Rdepths_inorder=>'0,1,0,1,2,3',
        vpar=>'0,1,1,0,0,0', vpar_postorder=>'3,3,0,0,0,0',
        Lweights=>'1,1,3,1,1,1', Rweights=>'2,1,4,3,2,1',
      },
      { balanced=>'1,1,0,1,0,0,1,0,1,1,0,0',
          balanced_postorder=>'1,1,0,0,1,1,1,0,1,0,0,0',
        Ldepths=>'0,1,1,0,0,1', Rdepths_postorder=>'1,0,2,2,1,0',
        Bdepths_inorder=>'1,2,0,1,3,2', Ldepths_inorder=>'1,1,0,0,1,0',
          Rdepths_inorder=>'0,1,0,1,2,2',
        vpar=>'0,1,1,0,0,5', vpar_postorder=>'3,3,0,0,6,0',
        Lweights=>'1,1,3,1,1,2', Rweights=>'2,1,4,3,1,1',
      },
      { balanced=>'1,1,0,1,0,0,1,1,0,0,1,0',
          balanced_postorder=>'1,1,0,0,1,1,0,1,1,0,0,0',
        Ldepths=>'0,1,1,0,1,0', Rdepths_postorder=>'1,0,1,2,1,0',
        Bdepths_inorder=>'1,2,0,2,1,2', Ldepths_inorder=>'1,1,0,1,0,0',
          Rdepths_inorder=>'0,1,0,1,1,2',
        vpar=>'0,1,1,0,4,0', vpar_postorder=>'3,3,0,5,0,0',
        Lweights=>'1,1,3,1,2,1', Rweights=>'2,1,4,1,2,1',
      },
      { balanced=>'1,1,0,1,0,0,1,1,0,1,0,0',
          balanced_postorder=>'1,1,0,0,1,1,1,0,0,1,0,0',
        Ldepths=>'0,1,1,0,1,1', Rdepths_postorder=>'1,0,2,1,1,0',
        Bdepths_inorder=>'1,2,0,2,3,1', Ldepths_inorder=>'1,1,0,1,1,0',
          Rdepths_inorder=>'0,1,0,1,2,1',
        vpar=>'0,1,1,0,4,4', vpar_postorder=>'3,3,0,6,6,0',
        Lweights=>'1,1,3,1,1,3', Rweights=>'2,1,4,2,1,1',
      },
      { balanced=>'1,1,0,1,0,0,1,1,1,0,0,0',
          balanced_postorder=>'1,1,0,0,1,1,0,1,0,1,0,0',
        Ldepths=>'0,1,1,0,1,2', Rdepths_postorder=>'1,0,1,1,1,0',
        Bdepths_inorder=>'1,2,0,3,2,1', Ldepths_inorder=>'1,1,0,2,1,0',
          Rdepths_inorder=>'0,1,0,1,1,1',
        vpar=>'0,1,1,0,4,5', vpar_postorder=>'3,3,0,5,6,0',
        Lweights=>'1,1,3,1,2,3', Rweights=>'2,1,4,1,1,1',
      },
      { balanced=>'1,1,0,1,0,1,0,0,1,0,1,0',
          balanced_postorder=>'1,1,1,0,0,0,1,1,1,0,0,0',
        Ldepths=>'0,1,1,1,0,0', Rdepths_postorder=>'2,1,0,2,1,0',
        Bdepths_inorder=>'1,2,3,0,1,2', Ldepths_inorder=>'1,1,1,0,0,0',
          Rdepths_inorder=>'0,1,2,0,1,2',
        vpar=>'0,1,1,1,0,0', vpar_postorder=>'4,4,4,0,0,0',
        Lweights=>'1,1,1,4,1,1', Rweights=>'3,2,1,3,2,1',
      },
      { balanced=>'1,1,0,1,0,1,0,0,1,1,0,0',
          balanced_postorder=>'1,1,1,0,0,0,1,1,0,1,0,0',
        Ldepths=>'0,1,1,1,0,1', Rdepths_postorder=>'2,1,0,1,1,0',
        Bdepths_inorder=>'1,2,3,0,2,1', Ldepths_inorder=>'1,1,1,0,1,0',
          Rdepths_inorder=>'0,1,2,0,1,1',
        vpar=>'0,1,1,1,0,5', vpar_postorder=>'4,4,4,0,6,0',
        Lweights=>'1,1,1,4,1,2', Rweights=>'3,2,1,3,1,1',
      },
      { balanced=>'1,1,0,1,0,1,0,1,0,0,1,0',
          balanced_postorder=>'1,1,1,1,0,0,0,0,1,1,0,0',
        Ldepths=>'0,1,1,1,1,0', Rdepths_postorder=>'3,2,1,0,1,0',
        Bdepths_inorder=>'1,2,3,4,0,1', Ldepths_inorder=>'1,1,1,1,0,0',
          Rdepths_inorder=>'0,1,2,3,0,1',
        vpar=>'0,1,1,1,1,0', vpar_postorder=>'5,5,5,5,0,0',
        Lweights=>'1,1,1,1,5,1', Rweights=>'4,3,2,1,2,1',
      },
      { balanced=>'1,1,0,1,0,1,0,1,0,1,0,0',
          balanced_postorder=>'1,1,1,1,1,0,0,0,0,0,1,0',
        Ldepths=>'0,1,1,1,1,1', Rdepths_postorder=>'4,3,2,1,0,0',
        Bdepths_inorder=>'1,2,3,4,5,0', Ldepths_inorder=>'1,1,1,1,1,0',
          Rdepths_inorder=>'0,1,2,3,4,0',
        vpar=>'0,1,1,1,1,1', vpar_postorder=>'6,6,6,6,6,0',
        Lweights=>'1,1,1,1,1,6', Rweights=>'5,4,3,2,1,1',
      },
      { balanced=>'1,1,0,1,0,1,0,1,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,1,0,0,0,0,1,0',
        Ldepths=>'0,1,1,1,1,2', Rdepths_postorder=>'3,3,2,1,0,0',
        Bdepths_inorder=>'1,2,3,5,4,0', Ldepths_inorder=>'1,1,1,2,1,0',
          Rdepths_inorder=>'0,1,2,3,3,0',
        vpar=>'0,1,1,1,1,5', vpar_postorder=>'6,6,6,5,6,0',
        Lweights=>'1,1,1,1,2,6', Rweights=>'5,4,3,1,1,1',
      },
      { balanced=>'1,1,0,1,0,1,1,0,0,0,1,0',
          balanced_postorder=>'1,1,1,0,1,0,0,0,1,1,0,0',
        Ldepths=>'0,1,1,1,2,0', Rdepths_postorder=>'2,2,1,0,1,0',
        Bdepths_inorder=>'1,2,4,3,0,1', Ldepths_inorder=>'1,1,2,1,0,0',
          Rdepths_inorder=>'0,1,2,2,0,1',
        vpar=>'0,1,1,1,4,0', vpar_postorder=>'5,5,4,5,0,0',
        Lweights=>'1,1,1,2,5,1', Rweights=>'4,3,1,1,2,1',
      },
      { balanced=>'1,1,0,1,0,1,1,0,0,1,0,0',
          balanced_postorder=>'1,1,1,0,1,1,0,0,0,0,1,0',
        Ldepths=>'0,1,1,1,2,1', Rdepths_postorder=>'2,3,2,1,0,0',
        Bdepths_inorder=>'1,2,4,3,4,0', Ldepths_inorder=>'1,1,2,1,1,0',
          Rdepths_inorder=>'0,1,2,2,3,0',
        vpar=>'0,1,1,1,4,1', vpar_postorder=>'6,6,4,6,6,0',
        Lweights=>'1,1,1,2,1,6', Rweights=>'5,4,1,2,1,1',
      },
      { balanced=>'1,1,0,1,0,1,1,0,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,0,1,0,0,0,1,0',
        Ldepths=>'0,1,1,1,2,2', Rdepths_postorder=>'3,2,2,1,0,0',
        Bdepths_inorder=>'1,2,4,5,3,0', Ldepths_inorder=>'1,1,2,2,1,0',
          Rdepths_inorder=>'0,1,2,3,2,0',
        vpar=>'0,1,1,1,4,4', vpar_postorder=>'6,6,5,5,6,0',
        Lweights=>'1,1,1,1,3,6', Rweights=>'5,4,2,1,1,1',
      },
      { balanced=>'1,1,0,1,0,1,1,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,1,0,1,0,0,0,1,0',
        Ldepths=>'0,1,1,1,2,3', Rdepths_postorder=>'2,2,2,1,0,0',
        Bdepths_inorder=>'1,2,5,4,3,0', Ldepths_inorder=>'1,1,3,2,1,0',
          Rdepths_inorder=>'0,1,2,2,2,0',
        vpar=>'0,1,1,1,4,5', vpar_postorder=>'6,6,4,5,6,0',
        Lweights=>'1,1,1,2,3,6', Rweights=>'5,4,1,1,1,1',
      },
      { balanced=>'1,1,0,1,1,0,0,0,1,0,1,0',
          balanced_postorder=>'1,1,0,1,0,0,1,1,1,0,0,0',
        Ldepths=>'0,1,1,2,0,0', Rdepths_postorder=>'1,1,0,2,1,0',
        Bdepths_inorder=>'1,3,2,0,1,2', Ldepths_inorder=>'1,2,1,0,0,0',
          Rdepths_inorder=>'0,1,1,0,1,2',
        vpar=>'0,1,1,3,0,0', vpar_postorder=>'4,3,4,0,0,0',
        Lweights=>'1,1,2,4,1,1', Rweights=>'3,1,1,3,2,1',
      },
      { balanced=>'1,1,0,1,1,0,0,0,1,1,0,0',
          balanced_postorder=>'1,1,0,1,0,0,1,1,0,1,0,0',
        Ldepths=>'0,1,1,2,0,1', Rdepths_postorder=>'1,1,0,1,1,0',
        Bdepths_inorder=>'1,3,2,0,2,1', Ldepths_inorder=>'1,2,1,0,1,0',
          Rdepths_inorder=>'0,1,1,0,1,1',
        vpar=>'0,1,1,3,0,5', vpar_postorder=>'4,3,4,0,6,0',
        Lweights=>'1,1,2,4,1,2', Rweights=>'3,1,1,3,1,1',
      },
      { balanced=>'1,1,0,1,1,0,0,1,0,0,1,0',
          balanced_postorder=>'1,1,0,1,1,0,0,0,1,1,0,0',
        Ldepths=>'0,1,1,2,1,0', Rdepths_postorder=>'1,2,1,0,1,0',
        Bdepths_inorder=>'1,3,2,3,0,1', Ldepths_inorder=>'1,2,1,1,0,0',
          Rdepths_inorder=>'0,1,1,2,0,1',
        vpar=>'0,1,1,3,1,0', vpar_postorder=>'5,3,5,5,0,0',
        Lweights=>'1,1,2,1,5,1', Rweights=>'4,1,2,1,2,1',
      },
      { balanced=>'1,1,0,1,1,0,0,1,0,1,0,0',
          balanced_postorder=>'1,1,0,1,1,1,0,0,0,0,1,0',
        Ldepths=>'0,1,1,2,1,1', Rdepths_postorder=>'1,3,2,1,0,0',
        Bdepths_inorder=>'1,3,2,3,4,0', Ldepths_inorder=>'1,2,1,1,1,0',
          Rdepths_inorder=>'0,1,1,2,3,0',
        vpar=>'0,1,1,3,1,1', vpar_postorder=>'6,3,6,6,6,0',
        Lweights=>'1,1,2,1,1,6', Rweights=>'5,1,3,2,1,1',
      },
      { balanced=>'1,1,0,1,1,0,0,1,1,0,0,0',
          balanced_postorder=>'1,1,0,1,1,0,1,0,0,0,1,0',
        Ldepths=>'0,1,1,2,1,2', Rdepths_postorder=>'1,2,2,1,0,0',
        Bdepths_inorder=>'1,3,2,4,3,0', Ldepths_inorder=>'1,2,1,2,1,0',
          Rdepths_inorder=>'0,1,1,2,2,0',
        vpar=>'0,1,1,3,1,5', vpar_postorder=>'6,3,6,5,6,0',
        Lweights=>'1,1,2,1,2,6', Rweights=>'5,1,3,1,1,1',
      },
      { balanced=>'1,1,0,1,1,0,1,0,0,0,1,0',
          balanced_postorder=>'1,1,1,0,0,1,0,0,1,1,0,0',
        Ldepths=>'0,1,1,2,2,0', Rdepths_postorder=>'2,1,1,0,1,0',
        Bdepths_inorder=>'1,3,4,2,0,1', Ldepths_inorder=>'1,2,2,1,0,0',
          Rdepths_inorder=>'0,1,2,1,0,1',
        vpar=>'0,1,1,3,3,0', vpar_postorder=>'5,4,4,5,0,0',
        Lweights=>'1,1,1,3,5,1', Rweights=>'4,2,1,1,2,1',
      },
      { balanced=>'1,1,0,1,1,0,1,0,0,1,0,0',
          balanced_postorder=>'1,1,1,0,0,1,1,0,0,0,1,0',
        Ldepths=>'0,1,1,2,2,1', Rdepths_postorder=>'2,1,2,1,0,0',
        Bdepths_inorder=>'1,3,4,2,3,0', Ldepths_inorder=>'1,2,2,1,1,0',
          Rdepths_inorder=>'0,1,2,1,2,0',
        vpar=>'0,1,1,3,3,1', vpar_postorder=>'6,4,4,6,6,0',
        Lweights=>'1,1,1,3,1,6', Rweights=>'5,2,1,2,1,1',
      },
      { balanced=>'1,1,0,1,1,0,1,0,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,0,0,1,0,0,1,0',
        Ldepths=>'0,1,1,2,2,2', Rdepths_postorder=>'3,2,1,1,0,0',
        Bdepths_inorder=>'1,3,4,5,2,0', Ldepths_inorder=>'1,2,2,2,1,0',
          Rdepths_inorder=>'0,1,2,3,1,0',
        vpar=>'0,1,1,3,3,3', vpar_postorder=>'6,5,5,5,6,0',
        Lweights=>'1,1,1,1,4,6', Rweights=>'5,3,2,1,1,1',
      },
      { balanced=>'1,1,0,1,1,0,1,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,1,0,0,1,0,0,1,0',
        Ldepths=>'0,1,1,2,2,3', Rdepths_postorder=>'2,2,1,1,0,0',
        Bdepths_inorder=>'1,3,5,4,2,0', Ldepths_inorder=>'1,2,3,2,1,0',
          Rdepths_inorder=>'0,1,2,2,1,0',
        vpar=>'0,1,1,3,3,5', vpar_postorder=>'6,5,4,5,6,0',
        Lweights=>'1,1,1,2,4,6', Rweights=>'5,3,1,1,1,1',
      },
      { balanced=>'1,1,0,1,1,1,0,0,0,0,1,0',
          balanced_postorder=>'1,1,0,1,0,1,0,0,1,1,0,0',
        Ldepths=>'0,1,1,2,3,0', Rdepths_postorder=>'1,1,1,0,1,0',
        Bdepths_inorder=>'1,4,3,2,0,1', Ldepths_inorder=>'1,3,2,1,0,0',
          Rdepths_inorder=>'0,1,1,1,0,1',
        vpar=>'0,1,1,3,4,0', vpar_postorder=>'5,3,4,5,0,0',
        Lweights=>'1,1,2,3,5,1', Rweights=>'4,1,1,1,2,1',
      },
      { balanced=>'1,1,0,1,1,1,0,0,0,1,0,0',
          balanced_postorder=>'1,1,0,1,0,1,1,0,0,0,1,0',
        Ldepths=>'0,1,1,2,3,1', Rdepths_postorder=>'1,1,2,1,0,0',
        Bdepths_inorder=>'1,4,3,2,3,0', Ldepths_inorder=>'1,3,2,1,1,0',
          Rdepths_inorder=>'0,1,1,1,2,0',
        vpar=>'0,1,1,3,4,1', vpar_postorder=>'6,3,4,6,6,0',
        Lweights=>'1,1,2,3,1,6', Rweights=>'5,1,1,2,1,1',
      },
      { balanced=>'1,1,0,1,1,1,0,0,1,0,0,0',
          balanced_postorder=>'1,1,0,1,1,0,0,1,0,0,1,0',
        Ldepths=>'0,1,1,2,3,2', Rdepths_postorder=>'1,2,1,1,0,0',
        Bdepths_inorder=>'1,4,3,4,2,0', Ldepths_inorder=>'1,3,2,2,1,0',
          Rdepths_inorder=>'0,1,1,2,1,0',
        vpar=>'0,1,1,3,4,3', vpar_postorder=>'6,3,5,5,6,0',
        Lweights=>'1,1,2,1,4,6', Rweights=>'5,1,2,1,1,1',
      },
      { balanced=>'1,1,0,1,1,1,0,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,0,1,0,1,0,0,1,0',
        Ldepths=>'0,1,1,2,3,3', Rdepths_postorder=>'2,1,1,1,0,0',
        Bdepths_inorder=>'1,4,5,3,2,0', Ldepths_inorder=>'1,3,3,2,1,0',
          Rdepths_inorder=>'0,1,2,1,1,0',
        vpar=>'0,1,1,3,4,4', vpar_postorder=>'6,4,4,5,6,0',
        Lweights=>'1,1,1,3,4,6', Rweights=>'5,2,1,1,1,1',
      },
      { balanced=>'1,1,0,1,1,1,1,0,0,0,0,0',
          balanced_postorder=>'1,1,0,1,0,1,0,1,0,0,1,0',
        Ldepths=>'0,1,1,2,3,4', Rdepths_postorder=>'1,1,1,1,0,0',
        Bdepths_inorder=>'1,5,4,3,2,0', Ldepths_inorder=>'1,4,3,2,1,0',
          Rdepths_inorder=>'0,1,1,1,1,0',
        vpar=>'0,1,1,3,4,5', vpar_postorder=>'6,3,4,5,6,0',
        Lweights=>'1,1,2,3,4,6', Rweights=>'5,1,1,1,1,1',
      },
      { balanced=>'1,1,1,0,0,0,1,0,1,0,1,0',
          balanced_postorder=>'1,0,1,0,1,1,1,1,0,0,0,0',
        Ldepths=>'0,1,2,0,0,0', Rdepths_postorder=>'0,0,3,2,1,0',
        Bdepths_inorder=>'2,1,0,1,2,3', Ldepths_inorder=>'2,1,0,0,0,0',
          Rdepths_inorder=>'0,0,0,1,2,3',
        vpar=>'0,1,2,0,0,0', vpar_postorder=>'2,3,0,0,0,0',
        Lweights=>'1,2,3,1,1,1', Rweights=>'1,1,4,3,2,1',
      },
      { balanced=>'1,1,1,0,0,0,1,0,1,1,0,0',
          balanced_postorder=>'1,0,1,0,1,1,1,0,1,0,0,0',
        Ldepths=>'0,1,2,0,0,1', Rdepths_postorder=>'0,0,2,2,1,0',
        Bdepths_inorder=>'2,1,0,1,3,2', Ldepths_inorder=>'2,1,0,0,1,0',
          Rdepths_inorder=>'0,0,0,1,2,2',
        vpar=>'0,1,2,0,0,5', vpar_postorder=>'2,3,0,0,6,0',
        Lweights=>'1,2,3,1,1,2', Rweights=>'1,1,4,3,1,1',
      },
      { balanced=>'1,1,1,0,0,0,1,1,0,0,1,0',
          balanced_postorder=>'1,0,1,0,1,1,0,1,1,0,0,0',
        Ldepths=>'0,1,2,0,1,0', Rdepths_postorder=>'0,0,1,2,1,0',
        Bdepths_inorder=>'2,1,0,2,1,2', Ldepths_inorder=>'2,1,0,1,0,0',
          Rdepths_inorder=>'0,0,0,1,1,2',
        vpar=>'0,1,2,0,4,0', vpar_postorder=>'2,3,0,5,0,0',
        Lweights=>'1,2,3,1,2,1', Rweights=>'1,1,4,1,2,1',
      },
      { balanced=>'1,1,1,0,0,0,1,1,0,1,0,0',
          balanced_postorder=>'1,0,1,0,1,1,1,0,0,1,0,0',
        Ldepths=>'0,1,2,0,1,1', Rdepths_postorder=>'0,0,2,1,1,0',
        Bdepths_inorder=>'2,1,0,2,3,1', Ldepths_inorder=>'2,1,0,1,1,0',
          Rdepths_inorder=>'0,0,0,1,2,1',
        vpar=>'0,1,2,0,4,4', vpar_postorder=>'2,3,0,6,6,0',
        Lweights=>'1,2,3,1,1,3', Rweights=>'1,1,4,2,1,1',
      },
      { balanced=>'1,1,1,0,0,0,1,1,1,0,0,0',
          balanced_postorder=>'1,0,1,0,1,1,0,1,0,1,0,0',
        Ldepths=>'0,1,2,0,1,2', Rdepths_postorder=>'0,0,1,1,1,0',
        Bdepths_inorder=>'2,1,0,3,2,1', Ldepths_inorder=>'2,1,0,2,1,0',
          Rdepths_inorder=>'0,0,0,1,1,1',
        vpar=>'0,1,2,0,4,5', vpar_postorder=>'2,3,0,5,6,0',
        Lweights=>'1,2,3,1,2,3', Rweights=>'1,1,4,1,1,1',
      },
      { balanced=>'1,1,1,0,0,1,0,0,1,0,1,0',
          balanced_postorder=>'1,0,1,1,0,0,1,1,1,0,0,0',
        Ldepths=>'0,1,2,1,0,0', Rdepths_postorder=>'0,1,0,2,1,0',
        Bdepths_inorder=>'2,1,2,0,1,2', Ldepths_inorder=>'2,1,1,0,0,0',
          Rdepths_inorder=>'0,0,1,0,1,2',
        vpar=>'0,1,2,1,0,0', vpar_postorder=>'2,4,4,0,0,0',
        Lweights=>'1,2,1,4,1,1', Rweights=>'1,2,1,3,2,1',
      },
      { balanced=>'1,1,1,0,0,1,0,0,1,1,0,0',
          balanced_postorder=>'1,0,1,1,0,0,1,1,0,1,0,0',
        Ldepths=>'0,1,2,1,0,1', Rdepths_postorder=>'0,1,0,1,1,0',
        Bdepths_inorder=>'2,1,2,0,2,1', Ldepths_inorder=>'2,1,1,0,1,0',
          Rdepths_inorder=>'0,0,1,0,1,1',
        vpar=>'0,1,2,1,0,5', vpar_postorder=>'2,4,4,0,6,0',
        Lweights=>'1,2,1,4,1,2', Rweights=>'1,2,1,3,1,1',
      },
      { balanced=>'1,1,1,0,0,1,0,1,0,0,1,0',
          balanced_postorder=>'1,0,1,1,1,0,0,0,1,1,0,0',
        Ldepths=>'0,1,2,1,1,0', Rdepths_postorder=>'0,2,1,0,1,0',
        Bdepths_inorder=>'2,1,2,3,0,1', Ldepths_inorder=>'2,1,1,1,0,0',
          Rdepths_inorder=>'0,0,1,2,0,1',
        vpar=>'0,1,2,1,1,0', vpar_postorder=>'2,5,5,5,0,0',
        Lweights=>'1,2,1,1,5,1', Rweights=>'1,3,2,1,2,1',
      },
      { balanced=>'1,1,1,0,0,1,0,1,0,1,0,0',
          balanced_postorder=>'1,0,1,1,1,1,0,0,0,0,1,0',
        Ldepths=>'0,1,2,1,1,1', Rdepths_postorder=>'0,3,2,1,0,0',
        Bdepths_inorder=>'2,1,2,3,4,0', Ldepths_inorder=>'2,1,1,1,1,0',
          Rdepths_inorder=>'0,0,1,2,3,0',
        vpar=>'0,1,2,1,1,1', vpar_postorder=>'2,6,6,6,6,0',
        Lweights=>'1,2,1,1,1,6', Rweights=>'1,4,3,2,1,1',
      },
      { balanced=>'1,1,1,0,0,1,0,1,1,0,0,0',
          balanced_postorder=>'1,0,1,1,1,0,1,0,0,0,1,0',
        Ldepths=>'0,1,2,1,1,2', Rdepths_postorder=>'0,2,2,1,0,0',
        Bdepths_inorder=>'2,1,2,4,3,0', Ldepths_inorder=>'2,1,1,2,1,0',
          Rdepths_inorder=>'0,0,1,2,2,0',
        vpar=>'0,1,2,1,1,5', vpar_postorder=>'2,6,6,5,6,0',
        Lweights=>'1,2,1,1,2,6', Rweights=>'1,4,3,1,1,1',
      },
      { balanced=>'1,1,1,0,0,1,1,0,0,0,1,0',
          balanced_postorder=>'1,0,1,1,0,1,0,0,1,1,0,0',
        Ldepths=>'0,1,2,1,2,0', Rdepths_postorder=>'0,1,1,0,1,0',
        Bdepths_inorder=>'2,1,3,2,0,1', Ldepths_inorder=>'2,1,2,1,0,0',
          Rdepths_inorder=>'0,0,1,1,0,1',
        vpar=>'0,1,2,1,4,0', vpar_postorder=>'2,5,4,5,0,0',
        Lweights=>'1,2,1,2,5,1', Rweights=>'1,3,1,1,2,1',
      },
      { balanced=>'1,1,1,0,0,1,1,0,0,1,0,0',
          balanced_postorder=>'1,0,1,1,0,1,1,0,0,0,1,0',
        Ldepths=>'0,1,2,1,2,1', Rdepths_postorder=>'0,1,2,1,0,0',
        Bdepths_inorder=>'2,1,3,2,3,0', Ldepths_inorder=>'2,1,2,1,1,0',
          Rdepths_inorder=>'0,0,1,1,2,0',
        vpar=>'0,1,2,1,4,1', vpar_postorder=>'2,6,4,6,6,0',
        Lweights=>'1,2,1,2,1,6', Rweights=>'1,4,1,2,1,1',
      },
      { balanced=>'1,1,1,0,0,1,1,0,1,0,0,0',
          balanced_postorder=>'1,0,1,1,1,0,0,1,0,0,1,0',
        Ldepths=>'0,1,2,1,2,2', Rdepths_postorder=>'0,2,1,1,0,0',
        Bdepths_inorder=>'2,1,3,4,2,0', Ldepths_inorder=>'2,1,2,2,1,0',
          Rdepths_inorder=>'0,0,1,2,1,0',
        vpar=>'0,1,2,1,4,4', vpar_postorder=>'2,6,5,5,6,0',
        Lweights=>'1,2,1,1,3,6', Rweights=>'1,4,2,1,1,1',
      },
      { balanced=>'1,1,1,0,0,1,1,1,0,0,0,0',
          balanced_postorder=>'1,0,1,1,0,1,0,1,0,0,1,0',
        Ldepths=>'0,1,2,1,2,3', Rdepths_postorder=>'0,1,1,1,0,0',
        Bdepths_inorder=>'2,1,4,3,2,0', Ldepths_inorder=>'2,1,3,2,1,0',
          Rdepths_inorder=>'0,0,1,1,1,0',
        vpar=>'0,1,2,1,4,5', vpar_postorder=>'2,6,4,5,6,0',
        Lweights=>'1,2,1,2,3,6', Rweights=>'1,4,1,1,1,1',
      },
      { balanced=>'1,1,1,0,1,0,0,0,1,0,1,0',
          balanced_postorder=>'1,1,0,0,1,0,1,1,1,0,0,0',
        Ldepths=>'0,1,2,2,0,0', Rdepths_postorder=>'1,0,0,2,1,0',
        Bdepths_inorder=>'2,3,1,0,1,2', Ldepths_inorder=>'2,2,1,0,0,0',
          Rdepths_inorder=>'0,1,0,0,1,2',
        vpar=>'0,1,2,2,0,0', vpar_postorder=>'3,3,4,0,0,0',
        Lweights=>'1,1,3,4,1,1', Rweights=>'2,1,1,3,2,1',
      },
      { balanced=>'1,1,1,0,1,0,0,0,1,1,0,0',
          balanced_postorder=>'1,1,0,0,1,0,1,1,0,1,0,0',
        Ldepths=>'0,1,2,2,0,1', Rdepths_postorder=>'1,0,0,1,1,0',
        Bdepths_inorder=>'2,3,1,0,2,1', Ldepths_inorder=>'2,2,1,0,1,0',
          Rdepths_inorder=>'0,1,0,0,1,1',
        vpar=>'0,1,2,2,0,5', vpar_postorder=>'3,3,4,0,6,0',
        Lweights=>'1,1,3,4,1,2', Rweights=>'2,1,1,3,1,1',
      },
      { balanced=>'1,1,1,0,1,0,0,1,0,0,1,0',
          balanced_postorder=>'1,1,0,0,1,1,0,0,1,1,0,0',
        Ldepths=>'0,1,2,2,1,0', Rdepths_postorder=>'1,0,1,0,1,0',
        Bdepths_inorder=>'2,3,1,2,0,1', Ldepths_inorder=>'2,2,1,1,0,0',
          Rdepths_inorder=>'0,1,0,1,0,1',
        vpar=>'0,1,2,2,1,0', vpar_postorder=>'3,3,5,5,0,0',
        Lweights=>'1,1,3,1,5,1', Rweights=>'2,1,2,1,2,1',
      },
      { balanced=>'1,1,1,0,1,0,0,1,0,1,0,0',
          balanced_postorder=>'1,1,0,0,1,1,1,0,0,0,1,0',
        Ldepths=>'0,1,2,2,1,1', Rdepths_postorder=>'1,0,2,1,0,0',
        Bdepths_inorder=>'2,3,1,2,3,0', Ldepths_inorder=>'2,2,1,1,1,0',
          Rdepths_inorder=>'0,1,0,1,2,0',
        vpar=>'0,1,2,2,1,1', vpar_postorder=>'3,3,6,6,6,0',
        Lweights=>'1,1,3,1,1,6', Rweights=>'2,1,3,2,1,1',
      },
      { balanced=>'1,1,1,0,1,0,0,1,1,0,0,0',
          balanced_postorder=>'1,1,0,0,1,1,0,1,0,0,1,0',
        Ldepths=>'0,1,2,2,1,2', Rdepths_postorder=>'1,0,1,1,0,0',
        Bdepths_inorder=>'2,3,1,3,2,0', Ldepths_inorder=>'2,2,1,2,1,0',
          Rdepths_inorder=>'0,1,0,1,1,0',
        vpar=>'0,1,2,2,1,5', vpar_postorder=>'3,3,6,5,6,0',
        Lweights=>'1,1,3,1,2,6', Rweights=>'2,1,3,1,1,1',
      },
      { balanced=>'1,1,1,0,1,0,1,0,0,0,1,0',
          balanced_postorder=>'1,1,1,0,0,0,1,0,1,1,0,0',
        Ldepths=>'0,1,2,2,2,0', Rdepths_postorder=>'2,1,0,0,1,0',
        Bdepths_inorder=>'2,3,4,1,0,1', Ldepths_inorder=>'2,2,2,1,0,0',
          Rdepths_inorder=>'0,1,2,0,0,1',
        vpar=>'0,1,2,2,2,0', vpar_postorder=>'4,4,4,5,0,0',
        Lweights=>'1,1,1,4,5,1', Rweights=>'3,2,1,1,2,1',
      },
      { balanced=>'1,1,1,0,1,0,1,0,0,1,0,0',
          balanced_postorder=>'1,1,1,0,0,0,1,1,0,0,1,0',
        Ldepths=>'0,1,2,2,2,1', Rdepths_postorder=>'2,1,0,1,0,0',
        Bdepths_inorder=>'2,3,4,1,2,0', Ldepths_inorder=>'2,2,2,1,1,0',
          Rdepths_inorder=>'0,1,2,0,1,0',
        vpar=>'0,1,2,2,2,1', vpar_postorder=>'4,4,4,6,6,0',
        Lweights=>'1,1,1,4,1,6', Rweights=>'3,2,1,2,1,1',
      },
      { balanced=>'1,1,1,0,1,0,1,0,1,0,0,0',
          balanced_postorder=>'1,1,1,1,0,0,0,0,1,0,1,0',
        Ldepths=>'0,1,2,2,2,2', Rdepths_postorder=>'3,2,1,0,0,0',
        Bdepths_inorder=>'2,3,4,5,1,0', Ldepths_inorder=>'2,2,2,2,1,0',
          Rdepths_inorder=>'0,1,2,3,0,0',
        vpar=>'0,1,2,2,2,2', vpar_postorder=>'5,5,5,5,6,0',
        Lweights=>'1,1,1,1,5,6', Rweights=>'4,3,2,1,1,1',
      },
      { balanced=>'1,1,1,0,1,0,1,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,1,0,0,0,1,0,1,0',
        Ldepths=>'0,1,2,2,2,3', Rdepths_postorder=>'2,2,1,0,0,0',
        Bdepths_inorder=>'2,3,5,4,1,0', Ldepths_inorder=>'2,2,3,2,1,0',
          Rdepths_inorder=>'0,1,2,2,0,0',
        vpar=>'0,1,2,2,2,5', vpar_postorder=>'5,5,4,5,6,0',
        Lweights=>'1,1,1,2,5,6', Rweights=>'4,3,1,1,1,1',
      },
      { balanced=>'1,1,1,0,1,1,0,0,0,0,1,0',
          balanced_postorder=>'1,1,0,1,0,0,1,0,1,1,0,0',
        Ldepths=>'0,1,2,2,3,0', Rdepths_postorder=>'1,1,0,0,1,0',
        Bdepths_inorder=>'2,4,3,1,0,1', Ldepths_inorder=>'2,3,2,1,0,0',
          Rdepths_inorder=>'0,1,1,0,0,1',
        vpar=>'0,1,2,2,4,0', vpar_postorder=>'4,3,4,5,0,0',
        Lweights=>'1,1,2,4,5,1', Rweights=>'3,1,1,1,2,1',
      },
      { balanced=>'1,1,1,0,1,1,0,0,0,1,0,0',
          balanced_postorder=>'1,1,0,1,0,0,1,1,0,0,1,0',
        Ldepths=>'0,1,2,2,3,1', Rdepths_postorder=>'1,1,0,1,0,0',
        Bdepths_inorder=>'2,4,3,1,2,0', Ldepths_inorder=>'2,3,2,1,1,0',
          Rdepths_inorder=>'0,1,1,0,1,0',
        vpar=>'0,1,2,2,4,1', vpar_postorder=>'4,3,4,6,6,0',
        Lweights=>'1,1,2,4,1,6', Rweights=>'3,1,1,2,1,1',
      },
      { balanced=>'1,1,1,0,1,1,0,0,1,0,0,0',
          balanced_postorder=>'1,1,0,1,1,0,0,0,1,0,1,0',
        Ldepths=>'0,1,2,2,3,2', Rdepths_postorder=>'1,2,1,0,0,0',
        Bdepths_inorder=>'2,4,3,4,1,0', Ldepths_inorder=>'2,3,2,2,1,0',
          Rdepths_inorder=>'0,1,1,2,0,0',
        vpar=>'0,1,2,2,4,2', vpar_postorder=>'5,3,5,5,6,0',
        Lweights=>'1,1,2,1,5,6', Rweights=>'4,1,2,1,1,1',
      },
      { balanced=>'1,1,1,0,1,1,0,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,0,1,0,0,1,0,1,0',
        Ldepths=>'0,1,2,2,3,3', Rdepths_postorder=>'2,1,1,0,0,0',
        Bdepths_inorder=>'2,4,5,3,1,0', Ldepths_inorder=>'2,3,3,2,1,0',
          Rdepths_inorder=>'0,1,2,1,0,0',
        vpar=>'0,1,2,2,4,4', vpar_postorder=>'5,4,4,5,6,0',
        Lweights=>'1,1,1,3,5,6', Rweights=>'4,2,1,1,1,1',
      },
      { balanced=>'1,1,1,0,1,1,1,0,0,0,0,0',
          balanced_postorder=>'1,1,0,1,0,1,0,0,1,0,1,0',
        Ldepths=>'0,1,2,2,3,4', Rdepths_postorder=>'1,1,1,0,0,0',
        Bdepths_inorder=>'2,5,4,3,1,0', Ldepths_inorder=>'2,4,3,2,1,0',
          Rdepths_inorder=>'0,1,1,1,0,0',
        vpar=>'0,1,2,2,4,5', vpar_postorder=>'5,3,4,5,6,0',
        Lweights=>'1,1,2,3,5,6', Rweights=>'4,1,1,1,1,1',
      },
      { balanced=>'1,1,1,1,0,0,0,0,1,0,1,0',
          balanced_postorder=>'1,0,1,0,1,0,1,1,1,0,0,0',
        Ldepths=>'0,1,2,3,0,0', Rdepths_postorder=>'0,0,0,2,1,0',
        Bdepths_inorder=>'3,2,1,0,1,2', Ldepths_inorder=>'3,2,1,0,0,0',
          Rdepths_inorder=>'0,0,0,0,1,2',
        vpar=>'0,1,2,3,0,0', vpar_postorder=>'2,3,4,0,0,0',
        Lweights=>'1,2,3,4,1,1', Rweights=>'1,1,1,3,2,1',
      },
      { balanced=>'1,1,1,1,0,0,0,0,1,1,0,0',
          balanced_postorder=>'1,0,1,0,1,0,1,1,0,1,0,0',
        Ldepths=>'0,1,2,3,0,1', Rdepths_postorder=>'0,0,0,1,1,0',
        Bdepths_inorder=>'3,2,1,0,2,1', Ldepths_inorder=>'3,2,1,0,1,0',
          Rdepths_inorder=>'0,0,0,0,1,1',
        vpar=>'0,1,2,3,0,5', vpar_postorder=>'2,3,4,0,6,0',
        Lweights=>'1,2,3,4,1,2', Rweights=>'1,1,1,3,1,1',
      },
      { balanced=>'1,1,1,1,0,0,0,1,0,0,1,0',
          balanced_postorder=>'1,0,1,0,1,1,0,0,1,1,0,0',
        Ldepths=>'0,1,2,3,1,0', Rdepths_postorder=>'0,0,1,0,1,0',
        Bdepths_inorder=>'3,2,1,2,0,1', Ldepths_inorder=>'3,2,1,1,0,0',
          Rdepths_inorder=>'0,0,0,1,0,1',
        vpar=>'0,1,2,3,1,0', vpar_postorder=>'2,3,5,5,0,0',
        Lweights=>'1,2,3,1,5,1', Rweights=>'1,1,2,1,2,1',
      },
      { balanced=>'1,1,1,1,0,0,0,1,0,1,0,0',
          balanced_postorder=>'1,0,1,0,1,1,1,0,0,0,1,0',
        Ldepths=>'0,1,2,3,1,1', Rdepths_postorder=>'0,0,2,1,0,0',
        Bdepths_inorder=>'3,2,1,2,3,0', Ldepths_inorder=>'3,2,1,1,1,0',
          Rdepths_inorder=>'0,0,0,1,2,0',
        vpar=>'0,1,2,3,1,1', vpar_postorder=>'2,3,6,6,6,0',
        Lweights=>'1,2,3,1,1,6', Rweights=>'1,1,3,2,1,1',
      },
      { balanced=>'1,1,1,1,0,0,0,1,1,0,0,0',
          balanced_postorder=>'1,0,1,0,1,1,0,1,0,0,1,0',
        Ldepths=>'0,1,2,3,1,2', Rdepths_postorder=>'0,0,1,1,0,0',
        Bdepths_inorder=>'3,2,1,3,2,0', Ldepths_inorder=>'3,2,1,2,1,0',
          Rdepths_inorder=>'0,0,0,1,1,0',
        vpar=>'0,1,2,3,1,5', vpar_postorder=>'2,3,6,5,6,0',
        Lweights=>'1,2,3,1,2,6', Rweights=>'1,1,3,1,1,1',
      },
      { balanced=>'1,1,1,1,0,0,1,0,0,0,1,0',
          balanced_postorder=>'1,0,1,1,0,0,1,0,1,1,0,0',
        Ldepths=>'0,1,2,3,2,0', Rdepths_postorder=>'0,1,0,0,1,0',
        Bdepths_inorder=>'3,2,3,1,0,1', Ldepths_inorder=>'3,2,2,1,0,0',
          Rdepths_inorder=>'0,0,1,0,0,1',
        vpar=>'0,1,2,3,2,0', vpar_postorder=>'2,4,4,5,0,0',
        Lweights=>'1,2,1,4,5,1', Rweights=>'1,2,1,1,2,1',
      },
      { balanced=>'1,1,1,1,0,0,1,0,0,1,0,0',
          balanced_postorder=>'1,0,1,1,0,0,1,1,0,0,1,0',
        Ldepths=>'0,1,2,3,2,1', Rdepths_postorder=>'0,1,0,1,0,0',
        Bdepths_inorder=>'3,2,3,1,2,0', Ldepths_inorder=>'3,2,2,1,1,0',
          Rdepths_inorder=>'0,0,1,0,1,0',
        vpar=>'0,1,2,3,2,1', vpar_postorder=>'2,4,4,6,6,0',
        Lweights=>'1,2,1,4,1,6', Rweights=>'1,2,1,2,1,1',
      },
      { balanced=>'1,1,1,1,0,0,1,0,1,0,0,0',
          balanced_postorder=>'1,0,1,1,1,0,0,0,1,0,1,0',
        Ldepths=>'0,1,2,3,2,2', Rdepths_postorder=>'0,2,1,0,0,0',
        Bdepths_inorder=>'3,2,3,4,1,0', Ldepths_inorder=>'3,2,2,2,1,0',
          Rdepths_inorder=>'0,0,1,2,0,0',
        vpar=>'0,1,2,3,2,2', vpar_postorder=>'2,5,5,5,6,0',
        Lweights=>'1,2,1,1,5,6', Rweights=>'1,3,2,1,1,1',
      },
      { balanced=>'1,1,1,1,0,0,1,1,0,0,0,0',
          balanced_postorder=>'1,0,1,1,0,1,0,0,1,0,1,0',
        Ldepths=>'0,1,2,3,2,3', Rdepths_postorder=>'0,1,1,0,0,0',
        Bdepths_inorder=>'3,2,4,3,1,0', Ldepths_inorder=>'3,2,3,2,1,0',
          Rdepths_inorder=>'0,0,1,1,0,0',
        vpar=>'0,1,2,3,2,5', vpar_postorder=>'2,5,4,5,6,0',
        Lweights=>'1,2,1,2,5,6', Rweights=>'1,3,1,1,1,1',
      },
      { balanced=>'1,1,1,1,0,1,0,0,0,0,1,0',
          balanced_postorder=>'1,1,0,0,1,0,1,0,1,1,0,0',
        Ldepths=>'0,1,2,3,3,0', Rdepths_postorder=>'1,0,0,0,1,0',
        Bdepths_inorder=>'3,4,2,1,0,1', Ldepths_inorder=>'3,3,2,1,0,0',
          Rdepths_inorder=>'0,1,0,0,0,1',
        vpar=>'0,1,2,3,3,0', vpar_postorder=>'3,3,4,5,0,0',
        Lweights=>'1,1,3,4,5,1', Rweights=>'2,1,1,1,2,1',
      },
      { balanced=>'1,1,1,1,0,1,0,0,0,1,0,0',
          balanced_postorder=>'1,1,0,0,1,0,1,1,0,0,1,0',
        Ldepths=>'0,1,2,3,3,1', Rdepths_postorder=>'1,0,0,1,0,0',
        Bdepths_inorder=>'3,4,2,1,2,0', Ldepths_inorder=>'3,3,2,1,1,0',
          Rdepths_inorder=>'0,1,0,0,1,0',
        vpar=>'0,1,2,3,3,1', vpar_postorder=>'3,3,4,6,6,0',
        Lweights=>'1,1,3,4,1,6', Rweights=>'2,1,1,2,1,1',
      },
      { balanced=>'1,1,1,1,0,1,0,0,1,0,0,0',
          balanced_postorder=>'1,1,0,0,1,1,0,0,1,0,1,0',
        Ldepths=>'0,1,2,3,3,2', Rdepths_postorder=>'1,0,1,0,0,0',
        Bdepths_inorder=>'3,4,2,3,1,0', Ldepths_inorder=>'3,3,2,2,1,0',
          Rdepths_inorder=>'0,1,0,1,0,0',
        vpar=>'0,1,2,3,3,2', vpar_postorder=>'3,3,5,5,6,0',
        Lweights=>'1,1,3,1,5,6', Rweights=>'2,1,2,1,1,1',
      },
      { balanced=>'1,1,1,1,0,1,0,1,0,0,0,0',
          balanced_postorder=>'1,1,1,0,0,0,1,0,1,0,1,0',
        Ldepths=>'0,1,2,3,3,3', Rdepths_postorder=>'2,1,0,0,0,0',
        Bdepths_inorder=>'3,4,5,2,1,0', Ldepths_inorder=>'3,3,3,2,1,0',
          Rdepths_inorder=>'0,1,2,0,0,0',
        vpar=>'0,1,2,3,3,3', vpar_postorder=>'4,4,4,5,6,0',
        Lweights=>'1,1,1,4,5,6', Rweights=>'3,2,1,1,1,1',
      },
      { balanced=>'1,1,1,1,0,1,1,0,0,0,0,0',
          balanced_postorder=>'1,1,0,1,0,0,1,0,1,0,1,0',
        Ldepths=>'0,1,2,3,3,4', Rdepths_postorder=>'1,1,0,0,0,0',
        Bdepths_inorder=>'3,5,4,2,1,0', Ldepths_inorder=>'3,4,3,2,1,0',
          Rdepths_inorder=>'0,1,1,0,0,0',
        vpar=>'0,1,2,3,3,5', vpar_postorder=>'4,3,4,5,6,0',
        Lweights=>'1,1,2,4,5,6', Rweights=>'3,1,1,1,1,1',
      },
      { balanced=>'1,1,1,1,1,0,0,0,0,0,1,0',
          balanced_postorder=>'1,0,1,0,1,0,1,0,1,1,0,0',
        Ldepths=>'0,1,2,3,4,0', Rdepths_postorder=>'0,0,0,0,1,0',
        Bdepths_inorder=>'4,3,2,1,0,1', Ldepths_inorder=>'4,3,2,1,0,0',
          Rdepths_inorder=>'0,0,0,0,0,1',
        vpar=>'0,1,2,3,4,0', vpar_postorder=>'2,3,4,5,0,0',
        Lweights=>'1,2,3,4,5,1', Rweights=>'1,1,1,1,2,1',
      },
      { balanced=>'1,1,1,1,1,0,0,0,0,1,0,0',
          balanced_postorder=>'1,0,1,0,1,0,1,1,0,0,1,0',
        Ldepths=>'0,1,2,3,4,1', Rdepths_postorder=>'0,0,0,1,0,0',
        Bdepths_inorder=>'4,3,2,1,2,0', Ldepths_inorder=>'4,3,2,1,1,0',
          Rdepths_inorder=>'0,0,0,0,1,0',
        vpar=>'0,1,2,3,4,1', vpar_postorder=>'2,3,4,6,6,0',
        Lweights=>'1,2,3,4,1,6', Rweights=>'1,1,1,2,1,1',
      },
      { balanced=>'1,1,1,1,1,0,0,0,1,0,0,0',
          balanced_postorder=>'1,0,1,0,1,1,0,0,1,0,1,0',
        Ldepths=>'0,1,2,3,4,2', Rdepths_postorder=>'0,0,1,0,0,0',
        Bdepths_inorder=>'4,3,2,3,1,0', Ldepths_inorder=>'4,3,2,2,1,0',
          Rdepths_inorder=>'0,0,0,1,0,0',
        vpar=>'0,1,2,3,4,2', vpar_postorder=>'2,3,5,5,6,0',
        Lweights=>'1,2,3,1,5,6', Rweights=>'1,1,2,1,1,1',
      },
      { balanced=>'1,1,1,1,1,0,0,1,0,0,0,0',
          balanced_postorder=>'1,0,1,1,0,0,1,0,1,0,1,0',
        Ldepths=>'0,1,2,3,4,3', Rdepths_postorder=>'0,1,0,0,0,0',
        Bdepths_inorder=>'4,3,4,2,1,0', Ldepths_inorder=>'4,3,3,2,1,0',
          Rdepths_inorder=>'0,0,1,0,0,0',
        vpar=>'0,1,2,3,4,3', vpar_postorder=>'2,4,4,5,6,0',
        Lweights=>'1,2,1,4,5,6', Rweights=>'1,2,1,1,1,1',
      },
      { balanced=>'1,1,1,1,1,0,1,0,0,0,0,0',
          balanced_postorder=>'1,1,0,0,1,0,1,0,1,0,1,0',
        Ldepths=>'0,1,2,3,4,4', Rdepths_postorder=>'1,0,0,0,0,0',
        Bdepths_inorder=>'4,5,3,2,1,0', Ldepths_inorder=>'4,4,3,2,1,0',
          Rdepths_inorder=>'0,1,0,0,0,0',
        vpar=>'0,1,2,3,4,4', vpar_postorder=>'3,3,4,5,6,0',
        Lweights=>'1,1,3,4,5,6', Rweights=>'2,1,1,1,1,1',
      },
      { balanced=>'1,1,1,1,1,1,0,0,0,0,0,0',
          balanced_postorder=>'1,0,1,0,1,0,1,0,1,0,1,0',
        Ldepths=>'0,1,2,3,4,5', Rdepths_postorder=>'0,0,0,0,0,0',
        Bdepths_inorder=>'5,4,3,2,1,0', Ldepths_inorder=>'5,4,3,2,1,0',
          Rdepths_inorder=>'0,0,0,0,0,0',
        vpar=>'0,1,2,3,4,5', vpar_postorder=>'2,3,4,5,6,0',
        Lweights=>'1,2,3,4,5,6', Rweights=>'1,1,1,1,1,1',
      },
     ],
     # end generated
    );

  foreach my $N (0 .. $#data) {
    my $i = 0;
    my @arrays = balanced_list($N);

    foreach my $type ('balanced','balanced_postorder',
                      'Ldepths', 'Rdepths_postorder',
                      'Ldepths_inorder','Rdepths_inorder','Bdepths_inorder',
                      'Lweights','Rweights',
                      'vpar','vpar_postorder',
                     ) {
      my $func_name = "_vertex_name_type_$type";
      my $func = Graph::Maker::Catalans->can($func_name)
        or die "oops, no func $func_name";
      foreach my $i (0 .. $#arrays) {
        # print $data[$N]->[$i]->{'balanced'},"\n";
        my $aref = $arrays[$i];
        ok (join(',',$func->($aref)),
            $data[$N]->[$i]->{$type},
            "Catalans-vpar.gp data N=$N i=$i $type");
      }
    }

    # foreach my $i (0 .. $#arrays) {
    #   my $aref = $arrays[$i];
    #   my $binary_tree = balanced_to_binary_tree($aref);
    #   foreach my $LR ('L','R') {
    #     my $type = $LR.'heights';
    #     ok (join(',',binary_tree_to_heights($binary_tree,'pre',$LR)),
    #         $data[$N]->[$i]->{$type},
    #         "Catalans-vpar.gp data N=$N i=$i $type balanced=$data[$N]->[$i]->{balanced}");
    #   }
    # }
  }
}

#------------------------------------------------------------------------------
exit 0;
