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

use 5.004;
use strict;
use Test;

use lib 't','xt';
use MyOEIS;
use Math::BigInt;
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Graph::Maker::Catalans;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

plan tests => 30;

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


#------------------------------------------------------------------------------
# flip = Stanley

sub flip_num_maximal_chains {
  my ($n) = @_;

  # Richard P. Stanley, "The Fibonacci Lattice", Fibonacci Quarterly, volume
  # 13, number 3, October 1975, pages 215-232.
  # https://fq.math.ca/13-3.html
  # https://fq.math.ca/Scanned/13-3/stanley.pdf
  # Page 222, left as an exercise for the reader.
  #
  # Hook length formula Frame, Robinson, Thrall as given by Luke Nelson.
  # h(n) = binomial(n,2)! / prod(i=1,n-1, (2*i-1)^(n-i));
  # vector(8,n,n--; h(n))
  # A005118
  # h(4)

  # This code began counting powers so as to stay in 32 or 64 bits, but now
  # gone to bignum.

  my @powers;
  foreach my $i (1 .. binomial($n,2)) {
    $powers[$i]++;
  }
  foreach my $i (1 .. $n-1) {
    my $b = 2*$i - 1;   # 1 to 2n-3
    my $p = $n - $i;    # n-1 to 1
    $powers[$b] -= $p;
  }
  for (my $i = 4; $i <= $#powers; $i+=2) {
    my $t = $i;
    until ($t % 2) {
      $t /= 2;
      $powers[2] += $powers[$i];
    }
    $powers[$t] += $powers[$i];
    $powers[$i] = 0;
  }
  ### @powers
  my $ret = Math::BigInt->new(1);
  foreach my $i (0 .. $#powers) {
    $powers[$i] ||= 0;
    if ($powers[$i] > 0) { $ret *= Math::BigInt->new($i)**$powers[$i]; }
  }
  foreach my $i (0 .. $#powers) {
    if ($powers[$i] < 0) { $ret /= Math::BigInt->new($i)**-$powers[$i]; }
  }
  return $ret;
}
MyOEIS::compare_values
  (anum => 'A005118',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N, rel_type => 'flip');
       push @got, MyGraphs::Graph_num_maximal_paths($graph);
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A005118',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       push @got, flip_num_maximal_chains($N);
     }
     return \@got;
   });


# M. De Sainte-Catherine and G. Viennot, "Enumeration of Certain Young
# Tableaux With Bounded Height", Lecture Notes in Mathematics 1234, pages
# 58-67, 1986.  As given in Bernardi and Bonichon.
# A005700
#
sub flip_num_intervals {
  my ($n) = @_;
  return 6 * Math::BigInt->bfac(2*$n) * Math::BigInt->bfac(2*$n+2)
    / Math::BigInt->bfac($n) / Math::BigInt->bfac($n+1)
    / Math::BigInt->bfac($n+2) / Math::BigInt->bfac($n+3);
}
# foreach my $n (2..10) { print flip_num_intervals($n),","; }
# print "\n";
MyOEIS::compare_values
  (anum => 'A005700',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N, rel_type => 'flip');
       push @got, MyGraphs::Graph_num_intervals($graph);
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A005700',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       push @got, flip_num_intervals($N);
     }
     return \@got;
   });



#------------------------------------------------------------------------------
# rotate = Tamari

# A027686 num maximal chains
# 1, 1, 1, 2, 9, 98, 2981
MyOEIS::compare_values
  (anum => 'A027686',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N);
       push @got, MyGraphs::Graph_num_maximal_paths($graph);
     }
     return \@got;
   });

# A002054 (n-1)/2*Catalan = num edges
MyOEIS::compare_values
  (anum => 'A002054',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N);
       push @got, scalar($graph->edges);
     }
     return \@got;
   });

# A000260 num intervals
# compared to Graph in Catalans.t
sub rotate_num_intervals {
  my ($n) = @_;
  return 2 * Math::BigInt->bfac(4*$n+1)
    / Math::BigInt->bfac($n+1) / Math::BigInt->bfac(3*$n+2);
}
MyOEIS::compare_values
  (anum => 'A000260',  # OFFSET=0
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       push @got, rotate_num_intervals($N);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# dexter

sub dexter_num_intervals {
  my ($n) = @_;
  return $n==0 ? 1 :  3 * 2**($n-1) * binomial(2*$n,$n) / ($n+1) / ($n+2);
}
MyOEIS::compare_values
  (anum => 'A000257',  # OFFSET=0
   max_count => 12,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       push @got, dexter_num_intervals($N);
     }
     return \@got;
   });

# Chapoton proposition 1.4, successorless = Motzkin
MyOEIS::compare_values
  (anum => 'A001006',  # Motzkin 1, 1, 2, 4, 9   OFFSET=0
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'dexter');
       push @got, scalar($graph->successorless_vertices);
     }
     return \@got;
   });

# A002054 (n-1)/2*Catalan = num edges
MyOEIS::compare_values
  (anum => 'A002054',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'dexter');
       push @got, scalar($graph->edges);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# rotate_Bempty

MyOEIS::compare_values
  (anum => 'A001006',  # Motzkin
   name => "rotate_Bempty predecessorless",
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_Bempty');
       push @got, scalar($graph->predecessorless_vertices);
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A058987',   # Catalan - Motzkin
   name => "rotate_Bempty predecessorful",
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_Bempty');
       push @got, scalar($graph->predecessorful_vertices);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A001006',  # Motzkin
   name => "rotate_Bempty successorless",
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_Bempty');
       push @got, scalar($graph->successorless_vertices);
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A058987',  # Catalan - Motzkin
   name => "rotate_Bempty successorful",
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_Bempty');
       push @got, scalar($graph->successorful_vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# split = Kreweras

# A000272 n^(n-2) = split, maximal chains
# Kreweras page 348 corollary 5.2 maximal chains m^(m-2).
# And ref to the same from Y. Poupard, "Codage et Denombrement
# Diverse Structures Apparentees a Celle d'Arbre", Cahiers BURO, volume
# 16, 1970, pages 71-80.
#
MyOEIS::compare_values
  (anum => 'A000272',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'split');
       push @got, MyGraphs::Graph_num_maximal_paths($graph);
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A000272',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       push @got, $N<2 ? 1 : $N**($N-2);
     }
     return \@got;
   });

# A002694 binomial(2n,n-2) = split, num edges
# checked against the graph in t/Catalans.t
MyOEIS::compare_values
  (anum => 'A002694',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 2; @got < $count; $N++) {
       push @got, binomial(2*$N,$N-2)
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# rotate_rightarm

# A002057 num edges, 4/(N+2) * binomial(2N-1, N-2)
# cf in t/Catalans.t
MyOEIS::compare_values
  (anum => 'A002057',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_rightarm');
       push @got, scalar($graph->edges);
     }
     return \@got;
   });

# A009766 Catalan triangle = rotate_rightarm row widths
MyOEIS::compare_values
  (anum => 'A009766',
   max_count => 5*6/2,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_rightarm',
                                     undirected => 1);
       my $root = '10'x$N;
       my @widths = row_widths($graph,$root);
       while (@widths && @got < $count) {
         push @got, shift @widths;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# rotate_first

# row widths, including root as a width=1 row, then $widths[$n] is $n away
# from root
sub row_widths {
  my ($graph, $root) = @_;
  my @widths;
  foreach my $v ($graph->vertices) {
    $widths[$graph->path_length($root,$v) || 0]++;
  }
  return @widths;
}

# A009766 Catalan triangle = rotate_first row widths
MyOEIS::compare_values
  (anum => 'A009766',
   max_count => 5*6/2,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_first',
                                     rel_direction => 'down');
       my $root = ('1'x$N).('0'x$N);
       my @widths = row_widths($graph,$root);
       while (@widths && @got < $count) {
         push @got, shift @widths;
       }
     }
     return \@got;
   });

# A000108 predecessorless rotate_first
#  = Catalans of N-1
MyOEIS::compare_values
  (anum => 'A000108',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_first');
       push @got, scalar($graph->predecessorless_vertices);
     }
     return \@got;
   });

# A071724 predecessorful rotate_first
#   3/(n+2) * binomial(2n,n-1)
#   Catalan(n+1) - Catalan(n)
MyOEIS::compare_values
  (anum => 'A071724',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_first');
       push @got, scalar($graph->predecessorful_vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A058987 Catalan(n) - Motzkin(n-1)
#   rotate_Aempty successorful
#   rotate_Cempty predecessorful

foreach my $rel_type ('rotate_Cempty') {
  MyOEIS::compare_values
      (anum => 'A058987',   # Catalan - Motzkin
       name => $rel_type,
       max_count => 9,
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $N = 1; @got < $count; $N++) {
           my $graph = Graph::Maker->new('Catalans', N => $N,
                                         rel_type => $rel_type);
           push @got, scalar($graph->predecessorful_vertices);
         }
         return \@got;
       });
}

# No, rotate_Aempty successorful
# got:     1,3,9,29,97,332,1155,4068,14469,51881
# A058987: 1,3,9,29,97,332,1155,4069,14482,51986
#
# MyOEIS::compare_values
#   (anum => 'A058987',
#    max_count => 9,
#    name => "rotate_Aempty successorful",
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 1; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('Catalans', N => $N,
#                                      rel_type => 'rotate_Aempty');
#        push @got, scalar($graph->successorful_vertices);
#      }
#      return \@got;
#    });


# A001006 Motzkin(n-1)
#   rotate_Aempty successorless
#   rotate_Bempty predecessorless
#   rotate_Cempty predecessorless
#
foreach my $rel_type ('rotate_Cempty') {
  MyOEIS::compare_values
      (anum => 'A001006',
       name => $rel_type,
       max_count => 9,
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $N = 1; @got < $count; $N++) {
           my $graph = Graph::Maker->new('Catalans', N => $N,
                                         rel_type => $rel_type);
           push @got, scalar($graph->predecessorless_vertices);
         }
         return \@got;
       });
}
MyOEIS::compare_values
  (anum => 'A001006',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_Aempty');
       push @got, scalar($graph->successorless_vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A086581 predecessorful filling

MyOEIS::compare_values
  (anum => 'A086581',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'filling');
       push @got, scalar($graph->predecessorful_vertices);
     }
     return \@got;
   });

# predecessorless filling
# not in OEIS: 1,3,9,29,97,332,1155,4068,14469,51881
#
# is not A071740 gf (1+x^3*C^4)*C^3 where C = Catalan,
# matches up to 1155, but then differs
#
# MyOEIS::compare_values
#   (anum => 'A071740',
#    max_count => 10,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 2; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('Catalans', N => $N,
#                                      rel_type => 'filling');
#        push @got, scalar($graph->predecessorless_vertices);
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A000958 predecessorful rotate_last
# = num ordered rooted trees with root of odd degree

MyOEIS::compare_values
  (anum => 'A000958',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_last');
       push @got, scalar($graph->predecessorful_vertices);
     }
     return \@got;
   });

# predecessorless rotate_last
# A000957 Fine's sequence
#   = num ordered rooted trees with root of even degree
# A104629 same by gf
MyOEIS::compare_values
  (anum => 'A000957',
   max_count => 10,
   func => sub {
     my ($count) = @_;
     my @got = (0,1,0);
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_last');
       push @got, scalar($graph->predecessorless_vertices);
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A104629',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => 'rotate_last');
       push @got, scalar($graph->predecessorless_vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A000108 Catalan = num vertices

MyOEIS::compare_values
  (anum => 'A000108',
   max_count => 7,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans', N => $N);
       push @got, scalar($graph->vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------

exit 0;
