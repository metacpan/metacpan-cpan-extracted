#!/usr/bin/perl -w

# Copyright 2016, 2017 Kevin Ryde
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

use 5.004;
use strict;
use Test;
plan tests => 42;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

require Graph::Maker::BinaryBeanstalk;

# uncomment this to run the ### lines
# use Smart::Comments '###';


# A218616   trunk with reversed subsections
# A213718 n occurs A213712(n) times.

#------------------------------------------------------------------------------
# A213722  num non-trunk,non-leaf v in range 2^n <= v < 2^(n+1)

MyOEIS::compare_values
  (anum => 'A213722',
   max_count => 12,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my $total = 0;
       foreach my $n (2**$k .. 2**($k+1)-1) {
         if (! n_is_leaf($n) && ! n_is_trunk($n)) {
           $total++;
         }
       }
       push @got, $total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A213706   depths of n, cumulative
MyOEIS::compare_values
  (anum => 'A213706',
   func => sub {
     my ($count) = @_;
     my @got;
     my $total = 0;
     for (my $n = 0; @got < $count; $n++) {
       $total += n_to_depth($n);
       push @got, $total;
     }
     return \@got;
   });

# A218254   paths to zero
MyOEIS::compare_values
  (anum => 'A218254',
   func => sub {
     my ($count) = @_;
     my @got;
     my $top_n = 0;
     my $n = 0;
     while (@got < $count) {
       push @got, $n;
       if ($n == 0) {
         $n = ++$top_n;
       } else {
         $n = n_to_parent($n);
       }
     }
     return \@got;
   });

# A213707  positions of zeros in these paths
MyOEIS::compare_values
  (anum => 'A213707',
   func => sub {
     my ($count) = @_;
     my @got;
     my $top_n = 0;
     my $n = 0;
     my $pos = 0;
     while (@got < $count) {
       if ($n == 0) {
         $n = ++$top_n;
         push @got, $pos;
       } else {
         $n = n_to_parent($n);
       }
       $pos++;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A213716  non-trunk positions within non-leafs
MyOEIS::compare_values
  (anum => 'A213716',
   func => sub {
     my ($count) = @_;
     my @got;
     my $num_non_leaf = 0;
     for (my $n = 0; @got < $count; $n++) {
       if (! n_is_leaf($n)) {
         if (! n_is_trunk($n)) {
           push @got, $num_non_leaf;
         }
         $num_non_leaf++;
       }
     }
     return \@got;
   });

# A213715  trunk position within non-leafs
MyOEIS::compare_values
  (anum => 'A213715',
   func => sub {
     my ($count) = @_;
     my @got;
     my $num_non_leaf = 0;
     for (my $n = 0; @got < $count; $n++) {
       if (n_is_trunk($n)) {
         push @got, $num_non_leaf;
       }
       $num_non_leaf += ! n_is_leaf($n);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A213727  num vertices in subtree under n (inc self), or 0=trunk
MyOEIS::compare_values
  (anum => 'A213727',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, n_subtree_num_vertices($n);
     }
     return \@got;
   });
sub n_subtree_num_vertices {
  my ($n) = @_;
  if (n_is_trunk($n)) { return 0; }
  my $vertices = 0;
  my @pending = ($n);
  while (@pending) {
    $vertices += @pending;
    @pending = map { n_to_children($_) } @pending;
  }
  return $vertices;
}

# A213726  num leafs in subtree under n (including self), or 0=trunk
MyOEIS::compare_values
  (anum => 'A213726',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, n_subtree_num_leafs($n);
     }
     return \@got;
   });

sub n_subtree_num_leafs {
  my ($n) = @_;
  if (n_is_trunk($n)) { return 0; }
  my $leafs = 0;
  my @pending = ($n);
  while (@pending) {
    @pending = map {
      my @children = n_to_children($_);
      if (@children == 0) { $leafs++; }
      @children;
    } @pending;
  }
  return $leafs;
}

#------------------------------------------------------------------------------
# A213731 0=leaf, 1=trunk, 2=non-trunk,non-leaf

MyOEIS::compare_values
  (anum => 'A213731',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, (n_is_leaf($n) ? 0
                   : n_is_trunk($n) ? 1
                   : 2);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A218608    depths where trunk is last in row

MyOEIS::compare_values
  (anum => 'A218608',
   max_count => 24,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       if (depth_to_trunk($depth) == depth_to_n_end($depth)) {
         push @got, $depth;
       }
     }
     return \@got;
   });

# A218606    depths where preceding row trunk is last in row
MyOEIS::compare_values
  (anum => 'A218606',
   max_count => 24,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       if (depth_to_trunk($depth-1) == depth_to_n_end($depth-1)) {
         push @got, $depth;
       }
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A218606',
   max_count => 24,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       if (depth_to_trunk($depth) == depth_to_n_end($depth)) {
         push @got, $depth+1;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------

# A213732   depths of even trunk vertices
MyOEIS::compare_values
  (anum => 'A213732',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       my $n = depth_to_trunk($depth);
       if (($n & 1) == 0) {
         push @got, $depth;
       }
     }
     return \@got;
   });

# A213733   depths of odd trunk vertices
MyOEIS::compare_values
  (anum => 'A213733',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       my $n = depth_to_trunk($depth);
       if (($n & 1) == 1) {
         push @got, $depth;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A179016  trunk vertices
MyOEIS::compare_values
  (anum => 'A179016',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (n_is_trunk($n)) {
         push @got, $n;
       }
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A179016',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, depth_to_trunk($depth);
     }
     return \@got;
   });

# A213719   trunk vertex predicate 0,1
MyOEIS::compare_values
  (anum => 'A213719',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, n_is_trunk($n) ? 1 : 0;
     }
     return \@got;
   });

# A213713 non-trunk vertices
MyOEIS::compare_values
  (anum => 'A213713',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (! n_is_trunk($n)) {
         push @got, $n;
       }
     }
     return \@got;
   });

# A213712  1-bits in trunk vertex, so trunk vertex increment
MyOEIS::compare_values
  (anum => 'A213712',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (n_is_trunk($n)) {
         push @got, Graph::Maker::BinaryBeanstalk::_count_1_bits($n);
       }
     }
     return \@got;
   });

# A213717 non-trunk non-leaf vertices
MyOEIS::compare_values
  (anum => 'A213717',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (! n_is_trunk($n) && ! n_is_leaf($n)) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A011371 parent vertex
MyOEIS::compare_values
  (anum => 'A011371',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, n_to_parent($n);
     }
     return \@got;
   });

sub n_to_parent {
  my ($n) = @_;
  return $n - Graph::Maker::BinaryBeanstalk::_count_1_bits($n);
}

#------------------------------------------------------------------------------
# A213710  depth of n=2^k
MyOEIS::compare_values
  (anum => 'A213710',
   # max_values => 31,  # on a 32-bit UV
   max_count => 10,  # iteration a bit slow
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, n_to_depth(1 << $k);
     }
     return \@got;
   });

# A218600  depth of n=2^k-1
MyOEIS::compare_values
  (anum => 'A218600',
   # max_values => 31,  # on a 32-bit UV
   max_count => 10,  # iteration a bit slow
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, n_to_depth((1 << $k) - 1);
     }
     return \@got;
   });


# A071542 depth of vertex
MyOEIS::compare_values
  (anum => 'A071542',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, n_to_depth($n);
     }
     return \@got;
   });

# A213709    depth levels from n=2^k-1 to n=2^(k+1)-1
MyOEIS::compare_values
  (anum => 'A213709',
   # max_values => 30,  # on a 32-bit UV
   max_count => 10,  # iteration a bit slow
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, (n_to_depth((1 << ($k+1)) - 1)
                   - n_to_depth((1 << $k) - 1));
     }
     return \@got;
   });

sub n_to_depth {
  my ($n) = @_;
  my $depth = 0;
  while ($n > 0) {
    $n = n_to_parent($n);
    $depth++;
  }
  return $depth;
}

#------------------------------------------------------------------------------
# A213728  trunk n mod 2, flip 0<->1
MyOEIS::compare_values
  (anum => 'A213728',
   max_count => 30,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       my $n = depth_to_trunk($depth);
       push @got, 1 - ($n % 2);
     }
     return \@got;
   });

# A213729  trunk n mod 2
MyOEIS::compare_values
  (anum => 'A213729',
   max_count => 30,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       my $n = depth_to_trunk($depth);
       push @got, $n % 2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A213730  n start of finite subtree

MyOEIS::compare_values
  (anum => 'A213730',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = 1; @got < $count; $n++) {
       my $parent = n_to_parent($n);
       if (! n_is_trunk($n) && n_is_trunk($parent)) {
         push @got, $n;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A257130   new high positions of nth leaf - nth non-leaf
MyOEIS::compare_values
  (anum => 'A257130',
   max_count => 15,
   func => sub {
     my ($count) = @_;
     my @got;
     my $n_leaf = 2;
     my $n_non_leaf = 1;
     my $max = 0;
     for (my $i = 1; @got < $count; $i++) {  # start offset=1
       my $diff = $n_leaf - $n_non_leaf;
       if ($diff > $max) {
         $max = $diff;
         push @got, $i;
       }
       ### push: "$n_leaf - $n_non_leaf = ".($n_leaf - $n_non_leaf)
       $n_leaf     = n_next_leaf($n_leaf);
       $n_non_leaf = n_next_non_leaf($n_non_leaf);
     }
     return \@got;
   });

# A257126    n'th leaf - nth' non-leaf, not root 0
#   = A055938(n) - A005187(n)
#     leaf         non-leaf
#     starting 2   starting 0
#     offset=1     offset=0
MyOEIS::compare_values
  (anum => 'A257126',
   func => sub {
     my ($count) = @_;
     my @got;
     my $n_leaf = 2;
     my $n_non_leaf = 1;
     while (@got < $count) {
       push @got, $n_leaf - $n_non_leaf;
       ### push: "$n_leaf - $n_non_leaf = ".($n_leaf - $n_non_leaf)
       $n_leaf     = n_next_leaf($n_leaf);
       $n_non_leaf = n_next_non_leaf($n_non_leaf);
     }
     return \@got;
   });
sub n_next_leaf {
  my ($n) = @_;
  do { $n++; } until (n_is_leaf($n));
  return $n;
}
sub n_next_non_leaf {
  my ($n) = @_;
  do { $n++; } until (! n_is_leaf($n));
  return $n;
}


#------------------------------------------------------------------------------
# A213714 how many non-leaf vertices precede n
MyOEIS::compare_values
  (anum => 'A213714',
   func => sub {
     my ($count) = @_;
     my @got;
     my $preceding_non = 0;
     for (my $n = 0; @got < $count; $n++) {
       if (n_is_leaf($n)) {
         push @got, 0;
       } else {
         push @got, $preceding_non;
         $preceding_non++;
       }
     }
     return \@got;
   });

# A055938 leaf vertices
MyOEIS::compare_values
  (anum => 'A055938',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (n_is_leaf($n)) {
         push @got, $n;
       }
     }
     return \@got;
   });

# A005187 non-leaf vertices
MyOEIS::compare_values
  (anum => 'A005187',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (! n_is_leaf($n)) {
         push @got, $n;
       }
     }
     return \@got;
   });

sub n_is_leaf {
  my ($n) = @_;
  my @children = n_to_children($n);
  return @children == 0;
}

#------------------------------------------------------------------------------
# A213723 child vertex, smallest

MyOEIS::compare_values
  (anum => 'A213723',
   func => sub {
     my ($count) = @_;
     my @got = (0);  # exception at n=0 ?
     for (my $n = 1; @got < $count; $n++) {
       my @children = n_to_children($n);
       push @got, (@children ? $children[0] : 0);
     }
     return \@got;
   });

# A213714

# A213724 child vertex, biggest
MyOEIS::compare_values
  (anum => 'A213724',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my @children = n_to_children($n);
       push @got, (@children ? $children[-1] : 0);
     }
     return \@got;
   });

sub n_to_children {
  my ($n) = @_;
  if ($n == 0) { return 1; }

  my $limit = 2*($n + 4);
  for (my $c = $n+1; $c < $limit; $c++) {
    if (n_to_parent($c) == $n) {
      return ($c, $c+1);
    }
  }
  return;
}

#------------------------------------------------------------------------------
# A213711 how many n=2^k-1 blocks preceding given depth

MyOEIS::compare_values
  (anum => 'A213711',
   # max_count => 20,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       my $n = depth_to_n($depth);
       push @got, ($n == 0 ? 0 : length(sprintf '%b', $n));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A213725    depth down to a leaf, maximum in subtree

MyOEIS::compare_values
  (anum => 'A213725',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, n_subtree_depth($n);
     }
     return \@got;
   });
sub n_subtree_depth {
  my ($n) = @_;
  if (n_is_trunk($n)) { return 0; }
  my $depth = 0;
  my @pending = ($n);
  while (@pending) {
    @pending = map { n_to_children($_) } @pending;
    $depth++;
  }
  return $depth;
}

#------------------------------------------------------------------------------
# A257265    depth down to a leaf, minimum

MyOEIS::compare_values
  (anum => 'A257265',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, n_depth_to_leaf($n);
     }
     return \@got;
   });
sub n_depth_to_leaf {
  my ($n) = @_;
  my @pending = ($n);
  my $depth = 0;
  for (;;) {
    @pending = map {
      my @children = n_to_children($_);
      if (! @children) { return $depth; }
      @children;
    } @pending;
    $depth++;
  }
}

#------------------------------------------------------------------------------
# A213708 first vertex in row, num vertices of preceding rows

MyOEIS::compare_values
  (anum => 'A213708',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, depth_to_n($depth);
     }
     return \@got;
   });
sub depth_to_n {
  my ($depth) = @_;
  for (my $n = 0; ; $n++) {
    if (n_to_depth($n) == $depth) {
      return $n;
    }
  }
}

# A173601 first vertex in row, num vertices of preceding rows
MyOEIS::compare_values
  (anum => 'A173601',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, depth_to_n_end($depth);
     }
     return \@got;
   });
sub depth_to_n_end {
  my ($depth) = @_;
  for (my $n = 0; ; $n++) {
    if (n_to_depth($n) == $depth+1) {
      return $n-1;
    }
  }
}

# A086876 row width
MyOEIS::compare_values
  (anum => 'A086876',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, depth_to_width($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A218604 num vertices after trunk in row

MyOEIS::compare_values
  (anum => 'A218604',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, depth_to_n_end($depth) - depth_to_trunk($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------

sub round_up_pow2 {
  my ($n) = @_;
  my $p = 1;
  while ($p < $n) { $p <<= 1; }
  return $p;
}
sub n_is_trunk {
  my ($n) = @_;
  return n_is_descendent_of(2*round_up_pow2($n)-1, $n);
}
sub n_is_descendent_of {
  my ($n, $ancestor) = @_;
  for (;;) {
    if ($n == $ancestor) { return 1; }
    if ($n < $ancestor || $n == 0) { return 0; }
    $n = n_to_parent($n);
  }
}
sub depth_to_trunk {
  my ($depth) = @_;
  my $n = depth_to_n($depth);
  while (! n_is_trunk($n)) { $n++; }
  return $n;
}

sub depth_to_width {
  my ($depth) = @_;
  return depth_to_n_end($depth) - depth_to_n($depth) + 1;
}

#------------------------------------------------------------------------------
exit 0;
