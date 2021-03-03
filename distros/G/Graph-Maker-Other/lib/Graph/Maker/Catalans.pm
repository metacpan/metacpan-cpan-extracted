# Copyright 2018, 2019, 2020, 2021 Kevin Ryde
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


package Graph::Maker::Catalans;
use 5.004;
use strict;
use constant 1.02;
use Carp 'croak';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 18;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  return Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}

# This finds the last run of 1s and moves the first of them up and the rest
# of them to the end and spread out.  See Math::NumSeq::BalancedBinary for
# more description.
#
# M.C. Er, "Enumerating Ordered Trees Lexicographically", The Computer
# Journal, volume 28, number 5, 1985.  Procedure GenSuc is this algorithm,
# but applying all change once the run of 1s is located.  Here the 1s are
# moved to the end while their extent is still being sought.
#
sub _balanced_next {
  my ($aref) = @_;
  ### _balanced_next(): join('',@$aref)
  foreach my $i (reverse 1 .. $#$aref-1) {
    if ($aref->[$i]) {
      ### low 1 at: $i
      my $o = 0;
      do {
        $aref->[$i--] = 0;
        if ($i<0) {
          ### no more ...
          return 0;
        }
        $aref->[$o-=2] = 1;
      } while ($aref->[$i]);
      $aref->[$i] = 1;
      $aref->[$o] = 0;
      return 1;
    }
  }
  ### no more ...
  return 0;
}

#----------------
# Vertex Names
#
# Other possibilities
#    N+1 elements with parens like 1(2(34))5
#    same as balanced with () for each elem ?
#
# one-sequence  = position in balanced of each 1
# zero-sequence = position in balanced of each 0
# L-sequence    = preorder, at each left child (internal or external),
#                 num externals below
#
# Zerling, rotation coding by rotate root until its subtree sizes are right,
# then recurse to left and then to right.  Code as how many rotates applied.
# Write those from last to first, so first is on a left and so always 0.
# Regenerate by first to last code many right rotates.
#
# Description in Lucas, van Baronaigien, and Ruskey.
# Sequence c1 .. cn where sum(c1..cj) <= j.
# Start left path n vertices.
# For i=2..n, perform ci many right rotations at the root of T[1..i].
# T[1..i] changes due to this.
#
#          *          figure 7
#        /   \        Zerling 00 111 00 103
#      *      *       Weights  1,2,1,2,3,6,1,1,2,1  = Lweights
#     / \      \      Distance 0,0,1,1,1,0,1,2,2,3  = Rdepths_inorder
#    *   *      *
#       /      / \
#      *      *   *
#     /
#    *
#
# Or similar counts rotates but applied to the last edge of the tree.
# Becomes Rdepths, maybe.


my @pm_one = (-1, 1);

sub _vertex_name_type_balanced {
  my ($aref) = @_;
  return @$aref;
}
sub _vertex_name_type_balanced_postorder {
  my ($aref) = @_;
  ### _vertex_name_type_balanced_postorder(): join(',',@$aref)

  # preorder  1 left 0 right           10 10
  # postorder left 1 right 0           1 10 0
  #
  # 0 = end of depth d
  #     emit 1, remember 0 for end of depth d-1
  # 1 = start of new depth
  #
  my @ret;
  my @pending = (0);
  foreach my $bit (@$aref) {
    ### at: "bit $bit pending ".join(',',@pending)." ret=".join('',@ret)
    if ($bit) {
      push @pending, 0;
    } else {
      ### end: "emit pending 0s $pending[-1], and 1"
      push @ret, (0) x pop @pending, 1;
      $pending[-1]++;
    }
  }
  ### final pending: join(',',@pending)
  ### assert: scalar(@pending)==1
  push @ret, (0) x $pending[0];

  ### ret: join('',@ret)
  return @ret;
}

# form used by Sapounakis et al for filling
sub _vertex_name_type_run1s {
  my ($aref) = @_;
  my $r = 0;
  my @ret;
  foreach my $bit (@$aref) {
    if ($bit) {
      $r++;
    } else {
      push @ret, $r;
      $r = 0;
    }
  }
  return @ret;
}

# Knuth volume 4A section 7.2.1.6 after algorithm P at equation (6), which
# is in pre-fascicle 4A
# http://www-cs-faculty.stanford.edu/~knuth/fasc4a.ps.gz draft of section
# 7.2.1.6 page 3, run length encode 0-bits
#
#        d1      d1          dn
#     ( )     ( )    ...  ( )
#
# where )^d[i] means d[i] many closes at that point.  Such a run is after
# each open, and can have d[i]=0 for no closes there.
#
# Per exercise 30 in the same section (draft page 35):
# An ordered forest childful  is where d[i]=0, for a new left descent.
#                   childless is where d[i]!=0, for step up to higher sibling.
#
# Other vertex name forms in Knuth:
# z1,z2,...,zn positions 0 to 2n-1 of the 1s.
# run1s[i] = z[i+1] - z[i] - 1
#
sub _vertex_name_type_run0s {
  my ($aref) = @_;
  my $r = 0;
  my @ret;
  foreach my $bit (reverse @$aref) {
    if ($bit) {
      push @ret, $r;
      $r = 0;
    } else {
      $r++;
    }
  }
  return reverse @ret;
}

sub _vertex_name_type_Ldepths {
  my ($aref) = @_;
  my @ret;
  my $d = 0;
  foreach my $bit (@$aref) {
    if ($bit) { push @ret, $d; }
    $d += $pm_one[$bit];
  }
  return @ret;
}

sub _vertex_name_type_Ldepths_inorder {
  my ($aref) = @_;
  # This code uses the form noted in the POD, at each 0 how many unclosed 1s
  # precede, with the 0 itself counted as a closing, so done after pm_one.
  my @ret;
  my $d = 0;
  foreach my $bit (@$aref) {
    $d += $pm_one[$bit];
    unless ($bit) {
      push @ret, $d;     # at each 0, num unclosed 0s after, not incl self
    }
  }
  return @ret;
}

sub _vertex_name_type_Bdepths_inorder {
  return _vertex_name_type_Rdepths_inorder(@_,1);
}
sub _vertex_name_type_Rdepths_inorder {
  my ($aref, $l) = @_;
  # $l = 1 if count left steps too, giving Bdepths
  #    = 0 if no count left step, giving Rdepths
  $l ||= 0;
  ### _vertex_name_type_Rdepths(): "l=$l  ".join('',@$aref)
  my @pos = (0);
  my @ret;
  my $d = 0;
  foreach my $bit (@$aref) {
    ### at: "bit $bit  d=$d pos ".join(',',@pos)
    if ($bit) {
      push @pos, $pos[-1];   # copy
      $d += $l;
    } else {
      $d -= $l;
      pop @pos;       # backtrack and go right
      push @ret, ($pos[-1]++) + $d;
      ### ret: $ret[-1]
    }
  }
  ### return: join(',',@ret)
  return @ret;
}

sub _vertex_name_type_Rdepths_postorder {
  my ($aref) = @_;
  ### _vertex_name_type_Rdepths_postorder(): join(',',@$aref)

  # $pending[] is how many right descents above the present vertex.
  # Preorder balanced binary is then:
  # 1 = internal vertex, descend to the left, so new 0 many rights.
  # 0 = external vertex
  #     pop @pending for how many rights to go up, each of them is a depth
  #     then next descent is a right so increment now top $pending[-1]
  # $d = right steps depth of current internal vertex
  # Similar to _vertex_name_type_balanced_postorder(), but there just pushing
  # all 1s for the pop @pending rights to go up, not depths.
  #
  my @ret;
  my @pending = (0);
  my $d = 0;
  foreach my $bit (@$aref) {
    ### at: "bit $bit  d=$d pending ".join(',',@pending)
    if ($bit) {
      push @pending, 0;
    } else {
      ### end: "emit $pending[-1] many"
      my $new_d = $d - pop @pending;
      push @ret, reverse $new_d .. $d-1;
      $d = $new_d + 1;
      $pending[-1]++;
    }
  }
  ### end pending: join('',@pending)
  ### end ret: join('',@ret)
  ### $d
  ### assert: @pending==1
  return @ret, reverse 0 .. $pending[0]-1;
}

sub _vertex_name_type_vpar {
  my ($aref) = @_;
  my @vpar;
  my $p = 0;
  foreach my $bit (@$aref) {
    if ($bit) {
      push @vpar, $p;
      $p = scalar @vpar;
    } else {
      $p = $vpar[$p-1];
    }
  }
  return @vpar;
}
sub _vertex_name_type_vpar_postorder {
  my ($aref) = @_;
  ### _vertex_name_type_vpar_postorder(): join('',@$aref)
  my @vpar;
  my $p = 0;
  my $v = scalar(@$aref) >> 1;
  foreach my $bit (reverse @$aref) {
    if ($bit) {
      $p = $vpar[$p-1];
    } else {
      $vpar[$v-1] = $p;
      $p = $v;
      $v--;
    }
  }
  ### @vpar
  return @vpar;
}

sub _vertex_name_type_Lweights {
  my ($aref) = @_;
  my @ret;
  my @sizes = (1);
  foreach my $bit (@$aref) {
    ### at: "bit $bit  sizes ".join(',',@sizes)
    if ($bit) {
      push @sizes, 1;
    } else {
      my $size = pop @sizes;
      push @ret, $size;
      $sizes[-1] += $size;
    }
  }
  return @ret;
}
sub _vertex_name_type_Rweights {
  my ($aref) = @_;
  ### _vertex_name_type_Rweights(): join('',@$aref)
  my @ret;
  my @Rweights = (1);
  foreach my $bit (reverse @$aref) {
    ### at: "bit $bit  Rweights ".join(',',@Rweights)
    if ($bit) {
      ### add to above ...
      my $Rweights = pop @Rweights;
      $Rweights[-1] += $Rweights;
    } else {
      ### push ret: $Rweights[-1]
      push @ret, $Rweights[-1];
      push @Rweights, 1;
    }
  }
  ### return: join(',',reverse @ret)
  return reverse @ret;
}

# Adaricheva arxiv 1101.1536v3 "right bracketing" is parens in postorder
# balanced.
#
#      *               ((01)(23))
#     /  \             0(1)(2(3))
#    *    *            preorder  110010
#   / \  / \           postorder 101100
#   0 1  2 3                     ()(())
#
#       *              ((ab)((cd)e))
#      /  \            F = 4,2,4,4
#    *     *           preorder  11001100
#   / \   / \          postorder 10 110100
#   a b  *   e                   () (()())
#       / \                      a(b)(c(d)(e))
#       c d                        1  2 3  4
#                                  2  4 3  4
#
#       *              ((a((bc)d))e)
#      /  \            E = 3,2,3,4
#    *     e           preorder  11011000
#   / \                          (()(()))
#  a   *               postorder 11010010
#     / \                        (()())()
#    *   d                       a(b(c)(d))(e)
#   / \                            1 2  3   4
#   b c                            3 2  3   4

# =head3 Bracketing
#
# Option C<vertex_name_type =E<gt> 'bracketing'> is parenthesized terms like
# "((1,2)3)".  Each external vertex is numbered 1 to N+1 left to right.
# Each internal vertex is parens "(left right)".  A comma (L</Comma> below)
# is between numbers when a vertex has two externals (ie. is a leaf).
#
# There are N pairs of parens.  When N=0 there are no parens and the sole
# vertex name is "1".  N=1 is one pair and sole vertex name "(1,2)".
#
# Option C<vertex_name_type =E<gt> 'bracketing_reduced'> removes paren pairs
# containing the final N+1 external.  For example
#
#     (1((2,3)(4,5)))       bracketing
#       1(2,3)4,5           bracketing_reduced
#
# This reduction is unambiguous.  The reduction leaves consecutive terms "T1
# T2 ... Tk".  Each is either an external, or a parenthesized internal.  The
# full bracketing has parens T1..Tk then T2..Tk then T3..Tk etc.
#
# In terms of the binary tree, each of these T is a left child subtree of
# the rightmost arm descents.
#
# cf
# Tamari and Huang, r.b and g.b.
#
# UNDOCUMENTED
sub _vertex_name_type_bracketing_reduced {
  return _vertex_name_type_bracketing(@_,1);
}
# FIXME: Want outer parens so N=0 is "1" and N=1 is (12) ?
# Omitting outermost would be inconsistent between N=0 and N=1.
# Including means 2N parens.
#
# UNDOCUMENTED
sub _vertex_name_type_bracketing {
  my ($aref,$reduced) = @_;
  ### _vertex_name_type_bracketing(): join('',@$aref)

  my @ret;        # array of strings to return
  my $ret = '';   # current string being built
  my $leaf = 1;   # leaf vertex number 1 .. N+1
  my $d = 0;      # Ldepth = how many left steps down = excess 1s over 0s
  my $sep;        # 1 = prev was number so want separator if next is a number
  my @closes = (0,0);

  foreach my $bit (@$aref, 0) {
    ### at: "bit $bit  ret=$ret"
    if ($bit) {
      if ($d || !$reduced) {
        $ret .= '(';
        $sep = 0;
      }
      push @closes, 0;
      $d++;
    } else {
      if ($sep) {
        push @ret, $ret;
        $ret = '';
      }
      $ret .= $leaf++;
      $sep = 1;

      $d--;
      unless ($reduced && $d < 0) {
        my $closes = pop @closes;
        foreach (1 .. $closes) {
          $ret .= ')';
          $sep = 0;
        }
        $closes[-1]++;
      }
    }
  }
  return @ret, $ret;
}

#---------
# Rotate

sub _rotate_at {
  my ($aref, $i) = @_;
  ### assert: 1 <= $i
  ### assert: $i <= $#$aref-1
  ### assert: $aref->[$i] == 0
  ### assert: $aref->[$i+1] == 1

  my @new_array = @$aref;
  my $d = 0;
  while ($d += $pm_one[ $new_array[$i+1] = $new_array[$i] ]) {
    $i--;
  }
  return \@new_array;
}

use constant _rel_type_name_rotate => 'Rotate';
sub _rel_type_rotate {
  my ($aref, $one) = @_;             # $one meaning rotate_first only
  my @ret;
  foreach my $i (1 .. $#$aref-1) {
    if (!$aref->[$i] && $aref->[$i+1]) {       # want 01
      push @ret, _rotate_at($aref, $i);
      last if $one;
    }
  }
  return @ret;
}

use constant _rel_type_name_rotate_first => 'Rotate First';
sub _rel_type_rotate_first {
  my ($aref) = @_;
  _rel_type_rotate($aref,1);
}

use constant _rel_type_name_rotate_last => 'Rotate Last';
sub _rel_type_rotate_last {
  my ($aref) = @_;
  foreach my $i (reverse 1 .. $#$aref-1) {
    if (!$aref->[$i] && $aref->[$i+1]) {       # last 01
      return _rotate_at($aref, $i);
    }
  }
  return ();
}

use constant _rel_type_name_rotate_rightarm => 'Rotate Right Arm';
sub _rel_type_rotate_rightarm {
  my ($aref) = @_;
  my @ret;
  my $d = 1;
  foreach my $i (1 .. $#$aref-1) {
    $d += $pm_one[$aref->[$i]];
    unless ($aref->[$i] || $d) {    # at bit=0 and d==0
      push @ret, _rotate_at($aref, $i);
    }
  }
  return @ret;
}

# 11 1 A 0 1 B 0 C     1 1 A 0 B 0 C
#    ^^^^^             ^^^^^
#
# 11010010
#   ^^
#      ^^
use constant _rel_type_name_rotate_leftarm => 'Rotate Left Arm';
sub _rel_type_rotate_leftarm {
  my ($aref) = @_;
  my @ret;
  my $i = 0;
  for ( ; $i <= $#$aref; $i++) {
    unless ($aref->[$i]) { last; }
  }
  my $lefts = $i;                       # how many initial 1s
  ### $lefts
  my $d = $i;
  for ( ; $i < $#$aref; $i++) {
    ### at: "i=$i d=$d"
    $d += $pm_one[$aref->[$i]];
    if ($d < $lefts) {
      ### at lefts level: $lefts
      ### assert: ! $aref->[$i]
      if ($aref->[$i+1]) {              # 01 for rotate
        push @ret, _rotate_at($aref, $i);
      }
      $lefts-- or last;                 # stop when back to zero line
    }
  }
  return @ret;
}

# A-empty and 101 is not allowed to be first gives disconnected with N
# predecessorless.
#
use constant _rel_type_name_rotate_Aempty => 'Rotate A-Empty';
sub _rel_type_rotate_Aempty {
  my ($aref) = @_;
  # from 1 A 0 1  B 0 C    from 1 0 1  B 0 C
  #   to 1 1 A 0  B 0 C      to 1 1 0  B 0 C
  #                             ^^^^^
  my @ret;
  foreach my $i (0 .. $#$aref-2) {
    if ($aref->[$i] && !$aref->[$i+1] && $aref->[$i+2]) {
      my @new_array = @$aref;
      $new_array[$i+1] = 1;
      $new_array[$i+2] = 0;
      push @ret, \@new_array;
    }
  }
  return @ret;
}

use constant _rel_type_name_rotate_Bempty => 'Rotate B-Empty';
sub _rel_type_rotate_Bempty {
  my ($aref) = @_;
  # 1 A 0 1 B 0 C     1 A 0 1 0 C
  #                       ^^^^^
  my @ret;
  foreach my $i (1 .. $#$aref-2) {
    if (!$aref->[$i] && $aref->[$i+1] && !$aref->[$i+2]) {  # 010
      push @ret, _rotate_at($aref, $i);
    }
  }
  return @ret;
}

use constant _rel_type_name_rotate_Cempty => 'Rotate C-Empty';
sub _rel_type_rotate_Cempty {
  my ($aref) = @_;
  #          i
  # from 1 A 0 1  B 0 C    1 A 0 1  B 0  (0 or end)
  #   to 1 1 A 0  B 0 C    1 1 A 0  B 0
  my @ret;
  foreach my $i (1 .. $#$aref-1) {
    if (!$aref->[$i] && $aref->[$i+1]) {
      my $d = 1;
      my $j = _balanced_end($aref,$i+1) + 1;
      unless ($aref->[$j]) {   # not a following 1, must either 0 or end
        push @ret, _rotate_at($aref, $i);
      }
    }
  }
  return @ret;
}

# $aref is an arrayref to balanced binary 0s and 1s.
# $i is index into $aref of a 1.
# Return the index of the matching closing 0 for that 1.
sub _balanced_end {
  my ($aref, $i) = @_;
  ### assert: $aref->[$i] == 1
  my $d = 1;
  while ($d += $pm_one[$aref->[++$i]]) {}
  return $i;
}

#----------------
# Chapoton dexter
# Movable x is    0, x, (1 or end)
#    /\/\
# /\/    \/\
#   ******
#         **
# NOT: ** followed by 0
#
# from 000 1xx0 (1 or end)
#  to  1xx0 000
#
# forwards form as used here:
#     from  (0 or start) 1xx0 111
#      to                111 1xx0
#
# Decomposition 1 A 0 1 B 0 1 C 0 ... = left child subtrees off the right arm.
# Block indecomposable 1 A 1 B 1 C ... 0 0 0, string ending k+1 many 0s.
# Level decomposition = A, B, C

use constant _rel_type_name_dexter => 'Dexter';
sub _rel_type_dexter {
  my ($aref) = @_;
  ### _rel_type_shift(): join('',@$aref)
  my @ret;
  foreach my $i (1 .. $#$aref-1) {
    if (!$aref->[$i] && $aref->[$i+1]) {          # 01 of rotate
      ### $i
      for (my $e = $i+1; $aref->[$e]; $e++) {     # one or more 1s after
        # $j = start of balanced
        # $i = end of balanced
        # $i+1 = first 1 after
        # $e = end of 1s after, being position of last 1
        my $d = 0;
        foreach my $j (reverse 0 .. $i) {
          unless ($d += $pm_one[$aref->[$j]]) {   # first return to zero
            if ($j == 0 || $aref->[$j-1]==0) {    # only 0 or start preceding
              push @ret, [ @{$aref}[0..$j-1],
                           @{$aref}[$i+1..$e],
                           @{$aref}[$j..$i],
                           @{$aref}[$e+1..$#$aref] ];
            }
            last;
          }
        }
      }
    }
  }
  return @ret;
}

#----------------
# Split = Kreweras

# Refinement of partition is when one or more partition sets split into
# other sets.
# Coarsening is combining one or more sets.
# Order by refinement is Kreweras.

use constant _rel_type_name_split => 'Split';
sub _rel_type_split {
  my ($aref) = @_;
  ### _rel_type_split(): join('',@$aref)
  my @ret;
  foreach my $i (1 .. $#$aref-1) {
    if (!$aref->[$i] && $aref->[$i+1]) {
      ### $i
      my $e = $i+2;
      while ($aref->[$e]) { $e++; }
      $e--;

      # $j = start of balanced
      # $i = end of balanced
      # $i+1 = first 1 after
      # $e = end of 1s after
      my $d = 0;
      foreach my $j (reverse 0 .. $i) {
        unless ($d += $pm_one[$aref->[$j]]) {
          push @ret, [ @{$aref}[0..$j-1],
                       @{$aref}[$i+1..$e],
                       @{$aref}[$j..$i],
                       @{$aref}[$e+1..$#$aref] ];
        }
        last if $d > 0;
      }
    }
  }
  return @ret;
}

#---------
# Flip = Stanley

# Richard P. Stanley, "The Fibonacci Lattice", Fibonacci Quarterly, volume
# 13, number 3, October 1975, pages 215-232.
# https://fq.math.ca/13-3.html
# https://fq.math.ca/Scanned/13-3/stanley.pdf
#
# order ideal of lattice = subset of vertices, and all preceding all of them
# J(lattice) = lattice of order ideals, ordered by set inclusion
# T2 = infinite complete binary tree,  W-ordered covers 1 smaller and 2 bigger
# order ideal of T2 = binary tree
# j[k] = num order ideals of T2 of cardinality k = Catalan(k)
# J(S(k-1)) = Stanley lattice
# S(P) = set of segments (or intervals) of P, ordered by inclusion
#         .
#
#       .   .
#
#     .   *   .      0 segs
#        / \
#   .   *   *   .    1 segs  L or R
#      / \ / \
# .   *   *   *   .  2 segs  LL  L+R  RR
#       S(3)
#
# Order ideal subset of S(3) vertices - start outside, step to first of S(3)
# left arm, follow its vertices stepwise to right arm, exit there.
# Is 4 steps across and 4 steps down per Dyck crossing of 4x4 half grid.
#
# J(S(3)) = Stanley N=4
# 4-elem sets of S(3)


use constant _rel_type_name_flip => 'Flip';
sub _rel_type_flip {
  my ($aref) = @_;
  my @ret;
  foreach my $i (1 .. $#$aref-1) {
    if (!$aref->[$i] && $aref->[$i+1]) {
      my @new_aref = @$aref;
      $new_aref[$i] = 1;
      $new_aref[$i+1] = 0;
      push @ret, \@new_aref;
    }
  }
  return @ret;
}

#---------
# Filling = all flips

use constant _rel_type_name_filling => 'Filling';
sub _rel_type_filling {
  my ($aref) = @_;
  my @new_aref = @$aref;
  my $seen;
  foreach my $i (1 .. $#$aref-1) {
    if (!$aref->[$i] && $aref->[$i+1]) {
      $new_aref[$i] = 1;
      $new_aref[$i+1] = 0;
      $seen = 1;
    }
  }
  return ($seen ? \@new_aref : ());
}

#------------------

sub init {
  my ($self, %params) = @_;
  ### Catalans init ...

  my $N = delete($params{'N'}) || 0;

  my $rel_type = delete($params{'rel_type'}) || 'rotate';
  my $rel_type_func = $self->can("_rel_type_$rel_type")
    || croak "Unrecognised rel_type: ",$rel_type;

  my $rel_direction = delete($params{'rel_direction'}) || 'up';

  my $vertex_name_type = delete($params{'vertex_name_type'}) || 'balanced';
  my $order = delete($params{'order'}) || 'pre';
  my $vertex_name_func = $self->can("_vertex_name_type_$vertex_name_type")
    || croak "Unrecognised vertex_name_type: ",$vertex_name_type;

  my $comma = delete($params{'comma'});
  unless (defined $comma) {
    $comma = ($vertex_name_type eq 'balanced'
              || $vertex_name_type eq 'balanced_postorder'
              ? '' : ',');
  }

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute
    (name => "Catalans N=$N, " . $self->can("_rel_type_name_$rel_type")->());

  unless ($graph->is_directed) {
    $rel_direction = 'up';
  }
  my $up   = ($rel_direction ne 'down');
  my $down = ($rel_direction ne 'up');

  my @array = (1,0) x $N;
  do {
    my $from = join($comma,$vertex_name_func->(\@array));
    $graph->add_vertex($from);

    ### array: join('',@array)
    ### $from
    foreach my $to_aref ($rel_type_func->(\@array)) {
      my $to = join($comma,$vertex_name_func->($to_aref));
      ### to array: join('',@$to_aref)
      ### $to
      if ($up)   { $graph->add_edge($from,$to); }
      if ($down) { $graph->add_edge($to,$from); }
    }
  } while (_balanced_next(\@array));

  ### total vertices: scalar $graph->vertices
  ### total edges   : scalar $graph->edges

  return $graph;
}

Graph::Maker->add_factory_type('Catalans' => __PACKAGE__);
1;

__END__

# Michael Aissen and P. Brian Shay, "Varieties of Binary Systems", Journal
# of Combinatorial Theory, Series A, volume 22, 1977, pages 69-82.
#
#     12345 -> 12(34)5 -> (12)(34)5 -> ((12)(34))5
#     code 1,1,1,3     last to first position of bracketing
#
#     12345 -> (12)345 -> (12)(34)5 -> ((12)(34))5
#     code 1,1,2,1
#
#     take lex minimal code
#
#      *
#     / \
#    *    *
#   / \   / \
#         3 4


# Other Notes:
#
# Olivier Bernardi and Nicolas Bonichon, "Catalan's Intervals and Realizers
# of Triangulations", arxiv:0704.3731
#
# Binary tree as B = (B1,B2) left and right subtrees B1,B2.
# Dyck path sigma(B) = sigma(B1),1,sigma(B2),0.
# This is post-order (skipping first 0).
#
#                  *
#             /        \
#           *            *
#        /     \        / \
#       *       *      e   *
#      / \     / \        / \
#     e   e   *   e      e   e
#            / \
#           e   e
#
# preorder  1110011000 1010 [0]
# postorder [0] 01001011000111
# B+B           10110100111000
#
# Bette Bultena and Frank Ruskey. "Well-Formed Parentheses Strings",
# Information Processing Letters, volume 68, number 5, 1998, pages 255-259.
# https://webhome.cs.uvic.ca/~ruskey/Publications/EMparen/EMparentheses.html
# Stanley lattice 01 flips Gray code


#------------------------------------------------------------------------------

=for stopwords Ryde Catalan Catalans coderef undirected OEIS vpar Dov Tamari Pallo associahedron parens parenthesizations postorder Ldepths Lweights Lweight Rweights Rweight pre unclosed recursing lex lexicographically subtree Bracketings Nieuw Archief voor Wiskunde eg rebalancing substring Unranking Baronaigien Ruskey zig zag Triangulations Acta Cybernetica subgraph subgraphs predecessorless successorless Kreweras Sur d'Un substrings ie preorder Sapounakis Tasoulas Tsikouras Dyck Bernardi Bonichon recurse parenthesized aa aaaa Csar Sengupta Suksompong rightarm poset bracketings Bonnin Motzkin Chapoton dexter les Decomposable decomposable decomposables num Makinen combinatorial Geyer Rik Warut Subposet Ldepth

=head1 NAME

Graph::Maker::Catalans - create Tamari lattice and other Catalan object graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Catalans;
 $graph = Graph::Maker->new ('Catalans', N => 4);

=head1 DESCRIPTION

C<Graph::Maker::Catalans> creates C<Graph.pm> graphs where each vertex
represents a "Catalan object", any one of

    * balanced binary string (Dyck word) of length 2N
    * binary tree of N internal vertices
    * ordered forest of N vertices

    num vertices = Catalan(N) = 1,1,2,5,14,42, ... (A000108)

Binary trees are rooted and each vertex has a left and right child subtree,
each possibly empty.  There are many more combinatorial objects counted by
the Catalan numbers and in one-to-one correspondence.  The present ones are
where the graph relations here have direct interpretation.

The default graph is the Tamari lattice (associahedron, binary tree rotation
graph, see L</Rotate> below), with vertex names as balanced binary strings.
But there are 12 relation types (10 up to isomorphism) and 13 vertex name
types.  The lattices are the algebra type of lattice (partially ordered set
relations).

=head2 Vertex Names

Option C<vertex_name_type> chooses the vertex name style.  The edge relation
rules are sometimes simpler or more complex in one or other type.  In all
cases the underlying object and relation is unchanged, just the vertex names
differ.

=head3 Balanced Binary

Default C<vertex_name_type =E<gt> 'balanced'> is strings of N many 1s and N
many 0s where the 1s and 0s nest like open and close parens.

        /\
     /\/  \  /\       mountain range, 1 up, 0 down
    /      \/  \
    110110001100      balanced binary
    (()(()))(())      parens

The heights in the mountain range are like nesting levels of the parens.
Balanced binary corresponds to a binary tree coded recursively, starting at
the root,

    1, left subtree, 0, right subtree         = balanced

This is pre-order traversal of the binary tree with 1 for a vertex, 0 for an
empty child position (an "external"), and final 0 omitted.

               1                    binary tree, pre-order
           /       \                1 = "internal" vertex
        1             1             0 = "external" empty position
      /   \         /   \           last external omitted
    0      1      1     (0)
          / \    / \                110110001100
         1   0  0   0
        / \
       0   0

Option C<vertex_name_type =E<gt> 'balanced_postorder'> is the tree coded by
postorder traversal.  Each external is a 1, each internal is a 0, except the
very first 1 omitted.  This is a recursive coding

    left subtree, 1, right subtree, 0     = balanced_postorder

There is no in-order bit coding because left,1,right is merely 0101010 for
every tree.

=head3 Depths

Option C<vertex_name_type =E<gt> 'Ldepths'> is left depth of each binary
tree vertex in pre-order.  Left depth is how many left steps down to the
vertex.  The example above is

    0,1,1,2,0,1         Ldepths

Ldepths in terms of balanced binary is at each 1-bit count how many unclosed
1s precede there (excess of 1s over 0s).  This is since each 1 is a vertex
and the next edge is a left descent, and each 0 goes back up that left (and
takes a right descent).

    1 101 1 0001 100    balanced binary
    0,1,1,2,   0,1      Ldepths

Ordered forests are in one-to-one correspondence with binary trees by the
"natural correspondence".  (See for example Knuth volume 1 section 2.3.2 for
pictures and description.)  Ldepths is vertex depth in the ordered forest.

    binary left child  = ordered first child     \    natural
    binary right child = ordered next sibling    / correspondence

         1                1       5
      /     \             | \     |           pre-order
     2       5            2  3    6           labelling
      \     /                |
       3   6                 4
      /
     4

    binary tree         ordered forest

Option C<vertex_name_type =E<gt> 'Ldepths_inorder'> is the same Ldepths but
vertices taken in-order.  In terms of balanced binary, at each 0 count how
many unclosed 0s are after it.  Or equivalently, how many unclosed 1s
precede and the 0 itself included as a closing.

In terms of ordered forest, in-order binary tree traversal is postorder
forest traversal.  So C<Ldepths_inorder> is forest depths postorder.

Option C<vertex_name_type =E<gt> 'Rdepths_inorder'> is right depths of the
binary tree traversed in-order.  Right depth is how many right steps down.
This is Makinen's "distance" representation.  In terms of ordered forest,
right depth is a horizontal position (how many preceding siblings, plus
parent how many preceding siblings, etc).

=cut

# Makinen should be \"a umlaut thingie.  E<228> seems to come out "ae".

=pod

Option C<Bdepths_inorder> is all steps down, so C<Ldepths_inorder> plus
C<Rdepths_inorder>.

Option C<vertex_name_type =E<gt> 'Rdepths_postorder'> is right depths of the
binary tree traversed post-order.

=cut

# Post-order in the ordered forest is a kind of diagonal post recursing into
# first child then next sibling then self.

=pod

The above have only one pre-order and one post-order.  The omitted
combinations are pre R,B and post L,B.  They do not uniquely identify their
tree object, ie. multiple trees have the same resulting vector.

=head3 Runs

Option C<vertex_name_type =E<gt> 'run1s'> is run lengths of 1s.  At each 0
of balanced binary, count how many 1s immediately precede it (possibly
zero).  For example,

    110 1110 0 0 10 0      balanced
      2,   3,0,0, 1,0      run1s

Sapounakis, Tasoulas, and Tsikouras, use this form for L</Filling> below.
They note C<run1s> is a "dominating sequence" in the sense sum(terms 1..k)
E<gt>= k (first term k=1).  sum - k is C<Ldepths_inorder>.

In terms of binary tree, each 0 is an external vertex and the number of 1s
preceding is the number of left edges above it.  So C<run1s> is the length
of the left-edges chain immediately above above each external (and omitting
the right-most external which is always right so always 0).

Option C<vertex_name_type =E<gt> 'run0s'> is run lengths of 0s.  At each 1
of balanced binary, count how many 0s immediately follow it (possibly none).

    1 10 1 1 1000 10 0      balanced
    0,1, 0,0,3,   2         run0s

C<run0s> gives C<Ldepths> differences.  Each 1 is a binary tree vertex in
preorder.  If no 0s then the next vertex is below so depth +1, whereas each
0 is empty positions so next vertex higher.

    run0s[i] = Ldepths[i]+1 - Ldepths[i+1]      depth decrease
                 with an additional Ldepths[N+1] = 0

=cut

# Pallo and Racca call this a P-sequence.  ???
# Pallo and Racca, "A Note on Generating Binary Trees in A-order and
# B-order", Internations Journal of Compuater Mathematics, volume 18,
# number 1, 1985, pages 27-39.

=pod

=head3 Vpar

Option C<vertex_name_type =E<gt> 'vpar'> gives the vertex parent array of
the ordered forest in pre-order.  Vertices are numbered 1 to N and each vpar
entry is the parent vertex number, or 0 if no parent (a root).  The first
vertex is the first root, so vpar always starts with 0.

    1       5
    | \     |           vpar
    2  3    6         0,1,1,3,0,5
       |
       4

Comparing forests lexicographically by C<vpar> is the same as comparing
lexicographically by C<Ldepths>.  So if an edge relation is a lex increase
of C<Ldepths> then it is also a lex increase of C<vpar> (though the values
in the arrays are not the same in general).

Option C<vertex_name_type =E<gt> 'vpar_postorder'> is vertex parent array
with forest vertices labelled in post-order.  The last vertex is the last
root, so C<vpar_postorder> always ends with 0.

    4       6
    | \     |        vpar_postorder
    1  3    5         4,3,4,0,6,0
       |
       2

=head3 Weights

Option C<vertex_name_type =E<gt> 'Lweights'> gives a list of subtree sizes.
This is the binary tree weights vector considered by Pallo ("Enumerating"
below).

Each binary tree external vertex (left to right) is right-most of a sub-tree
(the subtree to its left).  The top of that sub-tree is found by going up
until reaching a vertex (internal or external) which is a left child.  The
weight is the number of externals at and below there.  An external which is
already a left child is weight 1 (itself only).  The first external is
always a left child so Lweights start with 1.  The last external is omitted
(it would be N+1 always).

              1
          /       \              Lweights
       2            5           1,1,2,3, 1,2   (omit e7)
      / \          / \
    e1   3        6   e7         Rweights
        / \      / \            3,1,1, 3,1,1   (omit e1)
       4   e4  e5   e6
      / \
    e2   e3

Option C<vertex_name_type =E<gt> 'Rweights'> is similar.  Each external
vertex is left-most of a subtree (the subtree to its right).  The subtree
top is by going up until a right child vertex.  The last external is always
a right child so Rweights end with 1.  The first external is omitted (it
would always be N+1).

An equivalent definition is to take the internal vertices in-order and
Lweight is the size of that vertex plus its left subtree (if any).  Or
Rweight is itself plus right subtree.

In terms of ordered forests, Lweight is the subtree size at and below each
vertex in post-order (since binary tree in-order is forest post-order).

=head3 Comma

Option C<comma =E<gt> "string"> is the separator between quantities in the
vertex names.  The default is empty "" for balanced binary or "," comma for
the others.

Terms are single digits for weights or vpar of N E<lt> 10, and depths of N
E<lt>= 10.  Omitting the comma by C<comma =E<gt> ''> is then unambiguous and
might be preferred for compact viewing.  Ambiguity at N=10 would be
Catalan(10) = 16796 vertices which is big but possible.

=cut

# GP-DEFINE  Catalan_number(n) = binomial(n<<1,n) / (n+1);
# GP-Test  Catalan_number(10) == 16796

=pod

=head2 Rotate

The default C<rel_type =E<gt> 'rotate'> is the X<Tamari lattice>Tamari
lattice, conceived by Tamari as parenthesizations of N+1 objects and stepped
by one application of the associative law, and hence also called an
X<associahedron>associahedron.

=over

Dov Tamari, "The Algebra of Bracketings and Their Enumeration", Nieuw
Archief voor Wiskunde, Series 3, volume 10, 1962, pages 131-146.

=back

         -------> 110010 -------_
        /                        v              N => 3
    101010                      111000          rel_type => "rotate"
        \                        ^
         --> 101100 --> 110100 -/

In terms of binary trees, this is one "rotation", and hence also called a
binary rotation graph (eg. Pallo).  Rotation is the rearrangement commonly
used for rebalancing a binary tree.  (Or applying an associative law to
operators in an expression parse tree.)

         x    (leftward)    y
        / \      -->       / \            binary tree "rotation",
       A   y              x   C          edge between vertices x,y
          / \            / \           A,B,C subtrees (possibly empty)
         B   C          A   B

    1 A 0 1 B 0 C     1 1 A 0 B 0 C     A,B,C balanced substrings
      ^^^^^             ^^^^^              (possibly empty)

A right edge x-y can rotate to left, or a left edge can come from a right
rotate, so each tree edge gives a graph edge and the graph is regular of
degree N-1.

    num edges = (N-1)/2*Catalan(N) or 0 if N=0
              = binomial(2N-1, N-2)
              = 0,0,1,5,21,84, ...   (A002054)
    degree N-1 regular (in-degree + out-degree)

=cut

# GP-DEFINE  RotateNumEdges_formula(N) = (N-1)/2*Catalan_number(N);
# GP-DEFINE  RotateNumEdges(N) = if(N==0,0, RotateNumEdges_formula(N));
# GP-Test  vector(6,N,N--; RotateNumEdges(N)) == [0,0,1,5,21,84]
# GP-Test  vector(20,N,N--; RotateNumEdges(N)) == \
# GP-Test  vector(20,N,N--; binomial(2*N-1,N-2))
# GP-Test  RotateNumEdges_formula(0) == -1/2

=pod

In terms of balanced binary, rotation moves a 1 to before the shortest
non-empty balanced substring immediately preceding,

    edge from    1aaaa0 1        where 1aaaa0 shortest balanced
          to     1 1aaaa0

Moving the 1 has the effect of shifting the 1A0 part up and right,

   from      /\          to    /\  /\
        /\  /  \   -->        /  \/  \
     /\/  \/    \          /\/        \
     101100111000          101110011000
       ****1                 1****

Each 01 can rotate per the "from" form above, so number of successors is
number of 01 pairs.  Each 11 in the "to" form above can come from a rotate,
so number of predecessors is number of 11 pairs.

In terms of ordered forest, rotation is a vertex move down to deeper level.
A vertex y with preceding sibling x has that x and its subtree drop down to
become the first child of y.  y's other children B remain.

          x ... y ... further-C                   y ... further-C
          |     |                 (leftwards)     | \
    subtree-A  further-B             -->          x .. further-B
                                                  |
                                              subtree-A

In terms of C<Lweights>, Pallo shows a rotate is one entry increasing by its
smallest possible amount, which is adding the size of its immediately
preceding sibling (drops to become first child).  This is y gaining subtree
size x under it.  The post-order vertex sequence is unchanged.  Pallo
reaches the same as Tamari that this operation forms a lattice.

=over

J. M. Pallo, "Enumerating, Ranking and Unranking Binary Trees", The Computer
Journal, volume 29, number 2, 1986, pages 171-175.

=back

Taking C<Lweights> as coordinates allows the graph to be drawn as an N-1
dimensional rectangular figure.  The first Lweights entry is always 1 so can
be ignored as a coordinate.  Each edge is then forward along one axis.  For
N=4 in 3 dimensions the effect is good.  Geyer draws N=4 and N=5 in this
style.  N=5 or more, in 2D projection at least, tends to become too busy to
see much.

=cut

# Winfried Geyer, "On Tamari Lattices", Discrete Mathematics, volume 133,
# 1994, pages 99-122.
# 82586438.pdf
# 

=pod

The undirected graph has a Hamiltonian path per Joan Lucas (simplified by
Lucas, van Baronaigien, and Ruskey).  And it has a Hamiltonian cycle per Wu
and Wang (whose argument can be simplified by expanding as for a path and
doing one zig-zag if Catalan(N-1) is odd).

The various C<rotate_...> relation types below restrict to just some rotates
so are edge subsets of full C<rotate>.

=cut

# Knuth volume 4 section 7.2.1.6 exercise 27
# (L<http://www-cs-faculty.stanford.edu/~knuth/fasc4a.ps.gz>) considers the
# lattice in ordered forests form, by depths or pre-order sizes.
# With rotate as smallest increase in preorder sizes ...
#
# =over
#
# Joan Lucas, "The Rotation Graph of Binary Trees Is Hamiltonian",
# Journal of Algorithms, volume 9, 1988, pages 503-535.
#
# =back
#
# and simplified
#
# =over
#
# Joan Lucas, Dominique Roelants van Baronaigien, Frank Ruskey, "On Rotations
# and the Generation of Binary Trees", Journal of Algorithms, volume 15, 1993,
# pages 343-366.
# L<http://webhome.cs.uvic.ca/~ruskey/Publications/Rotation/Rotation.html>
#
# =back
#
# The latter approach is to take a Hamiltonian path in N-1 and at each element
# run the new term N alternately up and down in the weights vector, which is
# the N-1 roots under or not under the new vertex N.  They use this to iterate
# through weights vectors one rotation at a time.  Knuth volume 4 section
# 7.2.1.6 algorithm L adapts to binary tree form.
#
# The graph has a Hamiltonian cycle per
#
# =over
#
# Ro-Yu Wu, Hung Lung Wang, "A Simple Proof for the Hamiltonian Property on
# Rotation Grpahs of Binary Trees" The 27th Workshop on Combinatorial
# Mathematics and Computation Theory
#
# =back
#
# Their approach starts from the Hamiltonian path, some of which is a base
# cycle, then show the rest are suitably cross linked to the cycle allowing
# them to be included (and a certain special case when N even).
#
# Another way is to extend an N-1 cycle to N cycle by new N up and down the
# same as for the path.  If length Catalan(N-1) is even then it ends back
# where it started.  If Catalan(N-1) is odd, which is N=2^k, then the first
# 11111 up and down to 11121 instead by zig-zag up for a single up (and
# reverse the rest suitably).

=pod

=head2 Rotate Right or Left Arm

Option C<rel_type =E<gt> 'rotate_rightarm'> restricts to rotates of edges on
the right arm of the binary tree, in the manner of

=over

J. M. Pallo, "Right-Arm Rotation Distance Between Binary Trees",
Information Processing Letters, volume 87, number 4, 2003, pages 173-177.

=cut

# doi: 10.1016/S0020-0190(03)00283-7

=pod

=back

         -------> 110010 -------_
        /                        v         N => 3
    101010                      111000     rel_type => "rotate_rightarm"
        \
         --> 101100 --> 110100

The resulting graph is "graded" in that it starts from all edges right arm
(101010), and each step reduces them by 1.  Counts of trees by right arm
length are a row of the Catalan triangle.

     T              rotate_rightarm
    / \
       *            only rotate edges
      / \           on the right-most arm
         *          extending down
        / \

In terms of balanced binary, right arm means rotate at "1aaaa0 1" where the
0 there is a return to the zero line.  The graph endpoints
(C<$graph-E<gt>successorless_vertices>) have no such returns to zero.  They
are "1 balanced(N-1) 0", and hence Catalan(N-1) many.

In terms of C<Ldepths>, right arm vertices have Ldepth=0 and the x,y
vertices of the rotate are consecutive Ldepth=0 (and other non-zeros in
between).  The rotate increases the depth of the second.

Csar, Sengupta, and Suksompong get various rightarm results too, as
X<comb poset>"comb poset" of bracketings.

=over

Sebastian A. Csar, Rik Sengupta, and Warut Suksompong. "On a Subposet of the
Tamari Lattice.", volume 31, number 3, October 2013, pages 337-363.
L<http://dx.doi.org/10.1007/s11083-013-9305-5>

=back

Option C<rel_type =E<gt> 'rotate_leftarm'> restricts to rotates which put a
new edge on the left arm, so rotate a right edge of a left arm vertex.  This
is isomorphic to C<rotate_rightarm> by considering binary trees in mirror
image.  In terms of balanced binary, left arm is a rotate at

    11..11 1aaaa0 1 ...          rotate_leftarm
    ^
    start of string initial run of 1s

The 1 of 1aaaa0 must be in the run of 1s at the start of the string.  It can
be anywhere in the run (including the very start of string), with aaaa
containing the rest of those 1s.

=cut

# In terms of C<bracketing_reduced>, each step adds a pair enclosing
# adjacent elements, either leaf term or parenthesized term.  The start is
# no parens so the first step encloses adjacent leaf terms (N positions).

=pod

=head2 Rotate First or Last

Option C<rel_type =E<gt> 'rotate_first'> restricts to rotate only at the
first possible place.  This result is a tree ("leftmost") per,

=over

J. M. Pallo, "Rotational Tree Structures on Binary Trees and
Triangulations", Acta Cybernetica, volume 17, 2006, pages 799-810.

=back

         -------> 110010 -------_
        /                        v         N => 3
    101010                      111000     rel_type => "rotate_first"
                                 ^
             101100 --> 110100 -/

Per Pallo, the resulting tree is "graded" by how many balanced binary
initial 1s, those being left arm.  Each first rotate moves the first
non-initial-1 to become part of the initial 1s.  The graph start vertices
(predecessorless) have 1 initial 1 and steps take them up to N 1s at the end
(successorless).  That end is unique, being all 1s at the start, 111000.

The number of vertices at each distance from the end a Catalan triangle row.
The predecessorless are Catalan(N-1) which is the end of the triangle row.

=cut

# FIXME: Is this right?
# In terms of binary tree, the rotate is at the first right-descent edge found
# by in-order traversal.

=pod

Option C<rel_type =E<gt> 'rotate_last'> rotates at the last possible place
only.  The result is a tree ("rightmost") again per Pallo (above).

                  110010 -------_
                                 v         N => 3
    101010                      111000     rel_type => "rotate_last"
        \                        ^
         --> 101100 --> 110100 -/

=head2 Rotate Empty

Option C<rel_type =E<gt> 'rotate_Aempty'> or C<'rotate_Bempty'> or
C<'rotate_Cempty'> restrict to rotate where the respective "A", "B" or "C"
part above is an empty subtree.

C<rotate_Aempty> is in the manner of (believe),

=over

A. Bonnin and J.M. Pallo, "A Shortest Path Metric on Unlabelled Binary
Trees", Pattern Recognition Letters, volume 13, 1992, pages 411-415.

=back

In terms of balanced binary, the rotate "aaaa" part is empty so triplet 101
-E<gt> 110.  Flip 01-E<gt>10 is per L</Flip> below, so the result here is
edge intersection of C<rotate> and C<flip>, ie. those edges present in both.

    edge from   101       rotate_Aempty
          to    110

         -------> 110010
        /                                  N => 3
    101010                     111000      rel_type => "rotate_Aempty"
        \                        ^
         --> 101100 --> 110100 -/

Every 110 substring can be reached from a 101, so the only predecessorless
is balanced binary without 110, which is 101010.

Every vertex with a 101 has a successor.  This first 1 is a vertex without
left but with right.  Conversely without 101 is each 10 as 100 or at end of
string.  That means whenever absent left must also have absent right.  This
restriction is Motzkin trees so number of successorless

    successorless = Motzkin(N-1) = 1,1,1,2,4,9,21,51,...  (A001006)

C<rotate_Cempty> is empty C.  This is isomorphic to empty A by considering
binary trees in mirror image and rotate left edge to right.

In balanced binary, C-empty has 1 after the B subtree, so either 0 or end of
string.  Identifying places to rotate normally doesn't look at the length of
B, but for C-empty must check what is after.  For N=3, C-empty is identical
to C<rotate_last> tree, but bigger C-empty and A-empty are not trees.

    edge from 1aaaa0 1bbbb0 [0 or end]     rotate_Cempty
          to  11aaaa0 bbbb0

C<rotate_Bempty> is per Pallo ("Rotational" above) who calls it
X<central rotate>"central rotate" (and takes "y,B" together requiring them a
single vertex).

         -------> 110010 -------_
        /                        v         N => 3
    101010                     111000      rel_type => "rotate_Bempty"
        \                        ^
         --> 101100     110100 -/

In terms of C<Lweights>, Pallo notes that B empty means the y vertex is
weight 1 (nothing under) and the rotate increases it (when possible, and by
smallest amount as usual for a rotate).

In balanced binary, B empty is a 0 after the rotate bit pattern, so rotate
at each 010.

                          v-- must 0 after
    edge from    1aaaa0 1 0                rotate_Bempty
          to     1 1aaaa0 0

The number of edges can be calculated by a recurrence summing over k
vertices in the left subtree, n-k-1 in the right, multiplying rotates within
the left by number of subtrees right, and vice versa, and new rotate at the
root which is right subtree with empty left which is n-k-2.  The result is

    num edges = binomial(2N-2, N-2)
              = 0, 0, 1, 4, 15, 56, 210, 792, ...   (A001791)

Graph vertices without successor have nowhere an empty B.  This means every
tree vertex (y) with a right child also has a left child.  This is the
Motzkin restriction as per A-empty above.  The rotate sends a tree to the
corresponding form in mirror image, so vertices without predecessor are
likewise.  This mirror imaging also means the graph is isomorphic to its own
edge reversal (C<$graph-E<gt>transpose>).

=cut

# GP-DEFINE  T(n) = {
# GP-DEFINE    sum(k=0,n-1,
# GP-DEFINE      T(k)*Catalan_number(n-1-k)
# GP-DEFINE      + Catalan_number(k)*T(n-1-k)
# GP-DEFINE      + if(n-1-k>=1, Catalan_number(k)* Catalan_number(n-2-k)));
# GP-DEFINE  }
# GP-Test  vector(8,n,n--;T(n)) == [0, 0, 1, 4, 15, 56, 210, 792]
# GP-Test  vector(12,n,n--;T(n)) == vector(12,n,n--;binomial(2*n-2,n-2))

=pod

=head2 Dexter

Option C<rel_type =E<gt> 'dexter'>X<dexter> is a multi-step block shift of

=over

F. Chapoton, "Some Properties of a New Partial Order on Dyck Paths",
September 2018.  L<https://hal.archives-ouvertes.fr/hal-01878792>,
L<https://arxiv.org/abs/1809.10981>

=back

         -------> 110010 -------_
        /                        v          N => 3
    101010          --------->  111000      rel_type => "dexter"
        \          /
         --> 101100 --> 110100

Chapoton considers shifts (and rotates) going up and left, but here rotate
is up and right and dexter here is taken the same.  (The difference is
whether to read left to right or right to left.)  In terms of balanced
binary,

    from   (0 or start) 1aaaa0 111     one or more following 1s
     to                 111 1aaaa0

Dexter shift moves one or more of the 1s which are after 1aaaa0.  This is
one or more rotates at the same place.

The 1aaaa0 is restricted to be preceded by 0 or start of string, it cannot
be preceded by 1.  This means 1s are taken in a single bite.  For example,
three 1s are a step but not two 1s then further step remaining 1.  When two
are taken, the result is "11 1aaaa0 1" and 1aaaa0 is now preceded by a 1 so
not eligible for a further shift.

Chapoton notes that all C<rotate_rightarm> (see L</Rotate Right or Left Arm>
above) have the necessary 0 or start, so C<rotate_rightarm> edges are a
subset of C<dexter>.  When all the 1s are taken, the result is per C<split>
(see L</Split> below), but split differs in also shifting across multiple
blocks and it does not take non-maximal 1s.

In terms of binary trees, the restriction is rotate at an x which is a right
child or the root.  Multiple 1s are a chain of left edges down from y.  The
following example is two 1s y,z.  The A subtree rotates to under z.  Further
rotate of 1A0 is disallowed because its 1 is x which is now a left child.

      t                     t
     / \     (leftwards)   / \
    T   x      ------>    T   y              t   x     yz
       / \                   / \       from  1T0 1 A 0 11 B 0 C 0 D
      A   y                 z   D       to       1 11 A 0
         / \               / \
        z   D             x   C        x = right child (or root)
       / \               / \
      B  C              A   B

Successorless graph vertices are no block preceded by 0 and followed by 1.
Per Chapoton, the number of these is the Motzkin numbers.  The condition in
the tree is any right edges must be under left child.

    successorless = Motzkin(N-1) = 1,1,1,2,4,9,21,51,...  (A001006)

Predecessors are from each balanced binary 11.  This is the 11 of "11aaaa0"
in "to" above coming from a shift past the 1aaaa0.  That shift is of the
first 1, plus all preceding 1s.  These 11 locations are the same as for
C<rotate> (each left edge), but coming from a different vertex when
preceding 1s.  The total number of edges is same, though dexter is not
degree regular the way rotate is.

    num edges = same as rotate
              = (N-1)/2*Catalan(N) = 0,0,1,5,21,84, ... (A002054)

=cut

# Same num edges by recurrence counting how right edges and number of lefts
# below.
#
# GP-DEFINE  TotalLeftVertices(n) = binomial(2*n,n+1) *3/(n+2);
# GP-Test  TotalLeftVertices(1) == 1
# vector(10,n,n--; TotalLeftVertices(n))
#
# GP-DEFINE  TotalLeftEdges(n) = binomial(2*n-1,n-2) * 4/(n+2);
# vector(10,n,n--; TotalLeftEdges(n))
# GP-Test  Catalan_number(3) == 5
#
# GP-DEFINE  DexterEdges(n) = {
# GP-DEFINE    sum(k=0,n-1, DexterEdgesNonRoot(k)*Catalan_number(n-1-k)
# GP-DEFINE               + Catalan_number(k)*(  DexterEdges(n-1-k)
# GP-DEFINE                                    + TotalLeftVertices(n-1-k)));
# GP-DEFINE  }
# GP-DEFINE  DexterEdgesNonRoot(n) = {
# GP-DEFINE    sum(k=0,n-1, DexterEdgesNonRoot(k)*Catalan_number(n-1-k)
# GP-DEFINE               + Catalan_number(k)*DexterEdges(n-1-k));
# GP-DEFINE  }
# GP-Test  my(n=2,k=1); DexterEdgesNonRoot(k)*Catalan_number(n-1-k) == 0
# GP-Test  my(n=2,k=1); Catalan_number(k)*  DexterEdges(n-1-k) == 0
# GP-Test  my(n=2,k=1); Catalan_number(k)*  TotalLeftVertices(n-1-k) == 0
# GP-Test  my(n=2,k=1); n-1-k == 0
# GP-Test  vector(10,n,n--; DexterEdges(n)) == \
# GP-Test  vector(10,n,n--; if(n,(n-1)/2*Catalan_number(n)))     \\ A002054
# GP-Test  vector(10,n,n--; DexterEdgesNonRoot(n)) == \
# GP-Test  vector(10,n,n--; binomial(2*n-1,n-3)) /* A003516 */
# vector(10,n,n--; Catalan_number(n))     \\ A002054

=pod

=head2 Split

Option C<rel_type =E<gt> 'split'> is a graph edge where split of a set of
siblings.  This is the X<Kreweras lattice>Kreweras lattice,

=over

G. Kreweras, "Sur les Partitions Non-CroisE<233>es d'Un Cycle", Discrete
Mathematics, volume 1, number 4, 1972, pages 333-350.

=back

          ---> 101100 ---_            N => 3
         /                v           rel_type => "split"
    101010 --> 110010 --> 111000
         \                ^
          ---> 110100 ---/

Kreweras considers the lattice in terms of non-crossing partitions of the
integers 1..N.  A partition is integers 1..N put into one or more sets.
Non-crossing means if sets have overlapping min to max ranges then one must
be entirely within a gap between elements of the other, the way children
fall between two siblings in a pre-order labelled forest.  Non-crossing
partitions are precisely the sets of siblings in ordered forests (with roots
reckoned siblings of each other).

Graph edges are where one set in a partition splits into two sets to reach
another partition.  The set getting the first element remains.  The other
set is new and comprises consecutive elements of the original.  They split
out by dropping to deeper in the forest.

      1         8            1        8
      |\ \ \    |            |  \     |         pre-order forests
      2 3 5 6   9            2    6   9        (post-order similar)
        |   |                |\   |
        4   7                3 5  7
                             |
     siblings sets           4         split 2,3,5,6
    [1,8] [2,3,5,6]                    by dropping 3,5 down
    [4,7] [8] [9]                      [2,6] [3,5]

The graph start vertex is the ordered forest all singletons which is 1 set
of siblings.  A split gives 2 sets, and further split 3 sets, and so on
until N sets which is every vertex alone in its siblings set (path-N down).

In balanced binary, split is a block of 1s moving to before one or more
preceding balanced substrings.

    edge from    1aa0 .. 1aa0 111       across one or more
          to     111 1aa0 .. 1aa0        preceding balanceds

The block of 1s is maximal, ie. all the 1s following a 0.  This is all
children moving down (moving only some would change the siblings below).
Each 1aa0 is a further preceding sibling moving down with it to form the new
sibling set.

The number of edges in the graph can be counted by some recurrences on
forest N vertices, k roots, second root vertex c.  Forest 2..c-1 is a
sub-forest and remaining c..N has 1 fewer roots.  In the balanced binary
this is k many blocks and first size c.  Multiplying count of splits in one
part by number of the other part reaches

    num edges = binomial(2N,N-2) = 0,1,6,28,120,495, ... (A002694)

=cut

# GP-Test  vector(6,n, binomial(2*n,n-2)) == [0,1,6,28,120,495]
# See vpar test.gp counting splits against ordered forests.

=pod

=head2 Flip

Option C<rel_type =E<gt> 'flip'> is graph edge for a balanced binary flip 01
-E<gt> 10.  This is the X<Stanley lattice>Stanley lattice, one of several
given in

=over

Richard P. Stanley, "The Fibonacci Lattice", Fibonacci Quarterly, volume 13,
number 3, October 1975, pages 215-232, see lattice J(S(k)) on page 222.
L<https://fq.math.ca/13-3.html>,
L<https://fq.math.ca/Scanned/13-3/stanley.pdf>

=back

    from 101100           /\  -->  /\/\          valley \/
     to  110100        /\/  \     /    \         flip up to /\ peak
          ^^

          --> 101100 --_                   N => 3
         /              v                  rel_type => "flip"
    101010             110100 --> 111000
         \              ^
          --> 110010 --/

In terms of pre-order C<Ldepths>, the step is where one entry increases
by +1.  Such an increase is possible (ie. goes to valid depths) when E<lt>=
its preceding entry (and first entry depth 0 never increases).

These Ldepth increases mean the lattice is "graded" by total Ldepths (which
is area under the mountain range).  Ldepths run from start 0,0,0,0 to end
0,1,2,3 so path length start to end is sum of those terms which is
triangular number N*(N-1)/2.  Stanley leaves it as an exercise to show the
number of different such paths (maximal chains) is, adapted to N numbering
here,

                                 binomial(N,2) !
    max chains = --------------------------------------------------
               (2N-3) * (2N-5)^2 * (2N-7)^3 * ... * 3^(N-2) * 1^(N-1)

               = 1, 1, 1, 2, 16, 768, 292864, ...    (A005118)

=cut

# GP-Test  my(N=3); N*(N-1)/2 == 3
#
# GP-DEFINE  maximal_chains_k(k) = \
# GP-DEFINE    (binomial(k+1,2))! / prod(i=1,k, (2*k+1-2*i)^i);
# GP-DEFINE  maximal_chains_N(N) = \
# GP-DEFINE    binomial(N,2)! / prod(i=1,N-1, (2*N-1-2*i)^i);
# GP-Test  vector(20,k, maximal_chains_k(k)) == \
# GP-Test  vector(20,k, maximal_chains_N(k+1))    /* N = k+1 */
# GP-Test  maximal_chains_k(2) == 2
# GP-Test  maximal_chains_N(3) == 2
# GP-Test  my(N=2); maximal_chains_N(N) == binomial(N,2)! / (2*N-3)
# GP-Test  my(N=3); maximal_chains_N(N) == binomial(N,2)! / (2*N-3) / (2*N-5)^2
# GP-Test  my(N=4); maximal_chains_N(N) == \
# GP-Test    binomial(N,2)! / (2*N-3) / (2*N-5)^2 / (2*N-7)^3
# GP-Test  vector(7,N,N--; maximal_chains_N(N)) == [1,1,1,2,16,768,292864]

=pod

=head2 Filling

Option C<rel_type =E<gt> 'filling'>X<filling> is graph edges where balanced
binary flips pairs 01 -E<gt> 10 per

=over

A. Sapounakis, I. Tasoulas, P. Tsikouras, "On the Dominance Partial
Ordering of Dyck Paths", Journal of Integer Sequences, volume 9, 2006,
article 06.2.5.
L<https://cs.uwaterloo.ca/journals/JIS/VOL9/Tsikouras/tsikouras67.html>

=back

    101010 ----_                     N => 3
                v                    rel_type => "filling"
    101100 --> 110100 --> 111000
                ^
    110010 ----/

    edge from   ... 01 ... 01 ... 01 ...     all 01 pairs
          to    ... 10 ... 10 ... 10 ...

They show the starts (C<$graph-E<gt>predecessorless_vertices>) are balanced
binary decomposable or containing 0011.  Decomposable means can be broken
into two balanced strings B1,B2, so there is some return to the zero line
before the end.  In N=3 shown above, starts are just the decomposables.  The
0011 rule first applies in N=5 where 1110011000 is not decomposable but is a
start because contains 0011.

Each vertex has just one C<filling> destination so the result is a tree and
ends at 11110000 which is the sole string with no 01s at all.

In terms of C<Ldepths>, filling is +1 of all entries which are able to
increase, meaning E<lt>= preceding entry.  The places able to increase are
determined before any increasing takes place.

=head2 Relation Direction

For a directed graph, edges are in the direction of the rules above.  This
is the default C<rel_direction =E<gt> 'up'>.  Direction "down" is the
opposite, the same as C<$graph-E<gt>transpose>.  Direction "both" is edges
both ways.  An undirected graph has just one edge between vertices in all
cases.

For balanced binary, the various rules are a lexicographic (and numeric)
increase.  The lattices go from global minimum 10101010 up to global maximum
11110000.  Or in some relations other minima or maxima too.

C<balanced_postorder> does some reversing so that the start becomes 11110000
and the end becomes 10101010.  This is because C<vertex_name_type> changes
only the vertex name, not the object represented nor the relation rule.
Direction "down" can be used if desired to put edges the other way.  In the
case of C<rotate>, the rule in C<balanced_postorder> and C<down> becomes

    edge from   0 1aaaa0       vertex_name_type => balanced_postorder
          to    1aaaa0 0       rel_direction => down

The 0 is a descent.  Moving it to after the balanced following has the
effect of shifting 1aaaa0 up and left.  Various authors prefer this form,
for example Bernardi and Bonichon.  Balanced coding and rotate move opposite
ways, so the choice is which one to prefer as the "bit first".

    preorder  coding "1 left 0 right",  rotate "balanced 1"
    postorder coding "left 1 right 0",  rotate "0 balanced"

The default here is to prefer pre-order and rotate in the direction which is
a lex increase of that preorder.

=head2 Lattice Refinement

As noted above, C<split>, C<rotate>, and C<flip>, all form lattices (partial
ordered set algebras).  They are successive refinements, meaning two
elements comparable in one remain comparable in the next, and some new
comparability added.

    split --> rotate --> flip      lattice refinement

In directed graph terms, refinement means at a given vertex the reachable
successors (C<$graph-E<gt>all_successors($v)>) expand so everything which
was reachable remains so, and more becomes reachable too.  The path length
to reach something might increase.  Reachable predecessors expand in the
same way.

In terms of the relation rules on balanced binary, these refinements are
simply that a C<split> step can be built by one or more C<rotate>, and a
C<rotate> can be built by one or more C<flip>.

=cut

# =head2 Dyck Words

# This is a vertex moved down to be the last child of its preceding sibling.
# If the vertex had any children they are adopted by that preceding sibling so
# the same depths.
#
# .  Left edges can rotate to
# right, and right edges can rotate to left.  Hence
#
#   In the
# following example, aaaa is followed by more balanced 1100, but stops at the
# first only.
# Equivalently, each vertex represents a binary tree (left and right children)
# of N vertices, with edges between those differing by "rotation" of one tree
# edge.
#   Vertices are parenthesizations of N+1 objects into
# pairs.  Edges are between those differing by one application of the
# associative law

# vpar_dot(vpar_from_balanced_binary(fromdigits(digits(110011011000,10),2)))
# vpar_dot(vpar_from_balanced_binary(fromdigits(digits(110010110010,10),2)))
#
#   2     6        2  3  5  6
#   |    / \       |     |         first child 4 and its siblings
#   1   3   5      1     4         rise to
#           |
#           4
#
# binary(vpar_to_balanced_binary([2,0, 6,5,6,0]))
# binary(vpar_to_balanced_binary([2,0, 0,5,0,0]))
# vpar_subtree_sizes_vector([2,0, 6,5,6,0])
# vpar_subtree_sizes_vector([2,0, 0,5,0,0])
#
#
# Example Lyon,
#
# vpar_dot(vpar_from_balanced_binary(fromdigits(digits(11011010010010,10),2)))
# vpar_dot(vpar_from_balanced_binary(fromdigits(digits(11110100010010,10),2)))
#
#        1     7              1     7
#      / | \                / |
#     2  3  6              2  6
#       / \                |
#      4   5               3
#                         / \
#                        4   5
#
# vpar_dot(vpar_from_balanced_binary(fromdigits(digits(11110000,10),2)))
# vpar_dot(vpar_from_balanced_binary(fromdigits(digits(10101010,10),2)))

# =head2 Binary Trees
#
# The binary tree form appears in
#
# The vertex names used in the graph are unspecified.  Currently they are
# weights vectors in the manner of Pallo, and per Pallo an edge is between two
# differing in one entry by the smallest amount.

=pod

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Catalans', key =E<gt> value, ...)>

The key/value parameters are

    N            => integer, represented trees size
    graph_maker  => subr(key=>value) constructor,
                     default Graph->new

    rel_type     => string
      "rotate" (default),
      "rotate_first", "rotate_last",
      "rotate_Aempty", "rotate_Bempty", "rotate_Cempty",
      "rotate_rightarm", "rotate_leftarm"
      "dexter"
      "split",
      "flip", "filling"

    rel_direction     => string "up" (default), "down", "both"

    vertex_name_type  => string
      "balanced" (default), "balanced_postorder"
      "Ldepths", "Rdepths_postorder",
      "Ldepths_inorder","Rdepths_inorder","Bdepths_inorder",
      "Lweights", "Rweights",
      "vpar", "vpar_postorder"

    comma          => string, default "," or empty ""

Other parameters are passed to the constructor, either the C<graph_maker>
coderef or C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are only in the
"successor" direction for the given C<rel_type>.

=back

=head1 FORMULAS

The current implementation uses arrays of balanced binary 0,1 internally,
which is the default preorder C<balanced>.  These arrays are generated by
iterating in the same way as L<Math::NumSeq::BalancedBinary> (see docs there
for notes).  Generating by some recursion or even some Gray code stepping is
possible (generating in any order is fine for the purposes here), but the
iteration is simple enough.

A relation type examines and manipulates a balanced binary array to
construct destinations.  Conversions are made from the arrays to the chosen
C<vertex_name_type>.  These conversions are one-pass over an array, possibly
with a stack remembering pending output or depth.  For conversions to
postorder, in some cases it's helpful to go from end to start (of what is
otherwise preorder).

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>  etc

=back

    all rel_type
      1310   N=0 and N=1 singleton
      19655  N=2, path-2

    rotate
      340    N=3, 5-cycle
      33547  N=4
      33549  N=5
      33551  N=6

    rotate_rightarm = rotate_leftarm
      286    N=3, path-5
      33615  N=4
      33617  N=5
      33619  N=6

    rotate_first
      286    N=3, path-5
      33563  N=4
      33565  N=5
      33567  N=6

    rotate_last
      286    N=3, path-5
      33569  N=4
      33571  N=5
      33573  N=6

    rotate_Aempty = rotate_Cempty
      286    N=3, path-5
      33607  N=4
      33609  N=5
      33611  N=6

    rotate_Bempty
      286    N=3, path-5
      33601  N=4
      33603  N=5
      33605  N=6

    dexter
      206    N=3, 4-cycle and leaf
      33621  N=4
      33623  N=5
      33625  N=6

    flip
      206    N=3, 4-cycle and leaf
      33589  N=4
      33591  N=5
      33593  N=6

    filling
      544    N=3, star-5
      33595  N=4
      33597  N=5
      33599  N=6

    split
      264    N=3
      33557  N=4
      33559  N=5
      33561  N=6

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A000108> (etc)

=back

    A000108    num vertices, Catalan numbers

    rotate
      A002054    num edges, (n-1)/2*Catalan
      A000260    num intervals
      A027686    num paths start to end (lattice maximal chains)

    rotate_rightarm = rotate_leftarm
      A002057    num edges, 4/(N+2) * binomial(2N-1, N-2)
      A009766    row widths, Catalan triangle

    rotate_first
      A141364    num edges, Catalan-1
      A009766    row widths, Catalan triangle

    rotate_Bempty
      A001791    num edges, binomial(2N-2,N-2)
      A001006    num predecessorless, Motzkin numbers
      A058987    num predecessorful, Catalan-Motzkin
      A001006    num successorful, Motzkin numbers
      A058987    num successorless, Catalan-Motzkin

    dexter
      A002054    num edges, (n-1)/2*Catalan   (same as rotate)
      A000257    num intervals

    split
      A002694    num edges, binomial(2N,N-2)
      A001764    num intervals
      A000272    num paths start to end (lattice maximal chains)

    flip
      A002054    num edges, count DU, binomial(2N-1,N-2)
      A005700    num intervals
      A005118    num paths start to end (lattice maximal chains)

    filling
      A086581    num predecessorful vertices, N>=2
      A071740    num predecessorless vertices, N>=2

In the above, "num intervals" means the number of pairs of vertices $u to $v
where $v is reachable from $u.  In a lattice, this means $u and $v are
comparable (C<$u E<lt>= $v>).  $u reachable from $u itself is included (an
empty path), so sum C<1 + $graph-E<gt>all_successors($u)> over all $u.

=cut

# Not A182136 = diameter of rotations on unordered binary trees, which is
# (2n-1)!! = 1*3*5*...*(2n-1) many ... not Catalans.

=pod

=head1 SEE ALSO

L<Graph::Maker>

L<Math::NumSeq::BalancedBinary>,
L<Math::NumSeq::Catalan>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2018, 2019, 2020, 2021 Kevin Ryde

This file is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
This file.  If not, see L<http://www.gnu.org/licenses/>.

=cut
