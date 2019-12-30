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

plan tests => 13232;

# uncomment this to run the ### lines
# use Smart::Comments;

require Graph::Maker::BulgarianSolitaire;


#------------------------------------------------------------------------------
{
  my $want_version = 14;
  ok ($Graph::Maker::BulgarianSolitaire::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::BulgarianSolitaire->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::BulgarianSolitaire->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::BulgarianSolitaire->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Helpers

sub binomial {
  my ($n, $m) = @_;
  my $ret = 1;
  foreach my $i ($n-$m+1 .. $n) { $ret *= $i; }
  foreach my $i (1 .. $m) { $ret /= $i; }
  return $ret;
}

sub fibonacci {
  my ($n) = @_;
  my $a = 0; 
  my $b = 1; 
  foreach (1..$n) {
    ($a,$b) = ($b, $a+$b);
  }
  return $a;
}
ok (fibonacci(0), 0);
ok (fibonacci(1), 1);
ok (fibonacci(2), 1);
ok (fibonacci(3), 2);
ok (fibonacci(4), 3);
# GP-Test  fibonacci(4) == 3


#------------------------------------------------------------------------------
# _composition_next()

sub i_to_composition {
  my ($n,$i) = @_;
  ### i_to_composition(): "n=$n i=$i"
  my @comp;
  if ($n) {
    $i = ~$i; # ) ^ (1<<$n);
    foreach my $pos (reverse 0 .. $n-1) {
      ### bit: ($i>>$pos) & 1
      if (($i>>$pos) & 1) {
        push @comp, 1;
      } else {
        $comp[-1]++;
      }
    }
  }
  ### comp: join(',',@comp)
  return @comp;
}    

{
  my @want = ([ [] ],
              [ [1] ],
              [ [1,1], [2] ],
              [ [1,1,1], [1,2], [2,1], [3] ],
              [ [1,1,1,1], [1,1,2], [1,2,1], [1,3],
                [2,1,1], [2,2], [3,1], [4]],
             );
  foreach my $n (0 .. $#want) {
    ### $n
    my @comp = (1) x $n;
    my $want_last = $#{$want[$n]};
    foreach my $i (0 .. $want_last) {
      ### at: "n=$n i=$i"
      ok (join(',',@comp), join(',',@{$want[$n]->[$i]}),
          "_composition_next() n=$n i=$i vs want");
      
      my @from = i_to_composition($n,$i);
      ok (join(',',@comp), join(',',@from),
          "_composition_next() n=$n i=$i vs code");

      my $more = Graph::Maker::BulgarianSolitaire::_composition_next(\@comp);
      ### more: "i=$i want_last=$want_last got more=$more  comp=".join(',',@comp)
      ok ($more, $i<$want_last?1:0,
          "_composition_next() n=$n i=$i more");
    }
    # my $more = Graph::Maker::BulgarianSolitaire::_composition_next(\@comp);
    # ok ($more, 0, "_composition_next() no more")
  }
}

{
  foreach my $n (0 .. 8) {
    my $count = 0;
    my %seen;
    my @comp = (1) x $n;
    do {
      $seen{join(',',@comp)}++;
      $count++;
    } while (Graph::Maker::BulgarianSolitaire::_composition_next(\@comp));

    ok ($count, $n==0 ? 1 : 2**($n-1),
        "_composition_next() num compositions");
    ok ($count, scalar(keys %seen),
        "_composition_next() all distinct compositions");
  }
}


#------------------------------------------------------------------------------
# All, both Partitions and Compositions

sub step {
  my ($str, $compositions) = @_;
  ### step(): $str
  ### $compositions
  my @p = split ',', $str;
  my $new_term = scalar(@p);
  @p = map {$_-1} @p;
  if ($compositions eq 'prepend') {
    unshift @p, $new_term;    # prepend
  } else {
    push @p, $new_term;       # append
  }
  @p = grep {$_} @p;          # discard zeros
  if (! $compositions) {
    @p = sort {$a<=>$b} @p;   # sort for partition
  }
  return join(',',@p);
}
ok (step('3',0), '1,2');
ok (step('1,2',0), '1,2');
ok (step('1,2','prepend'), '2,1');

foreach my $compositions (0, 'prepend', 'append') {
  foreach my $N (0 .. 10) {
    foreach my $no_self_loop (0,1) {
      my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                    N => $N,
                                    compositions => $compositions,
                                    no_self_loop => $no_self_loop);

      unless ($no_self_loop) {
        ok (join('', map {$graph->out_degree($_)} $graph->vertices),
            '1' x scalar($graph->vertices),
            "N=$N compositions=$compositions - all vertices out_degree=1");
      }

      foreach my $from ($graph->vertices) {
        my $to = step($from,$compositions);
        if ($to eq $from && $no_self_loop) {
          ok ($graph->out_degree($from), 0);
        } else {
          ok ($graph->out_degree($from), 1,
              "N=$N from=$from to=$to");
          ok (!! $graph->has_edge($from,$to), 1);
        }
      }
    }
  }
}


#------------------------------------------------------------------------------
# Partitions

my @num_partitions   # A000041
  = (1, 1, 2, 3, 5, 7, 11, 15, 22, 30, 42, 56, 77, 101, 135, 176, 231, 297,
     385, 490, 627, 792, 1002, 1255, 1575, 1958, 2436, 3010, 3718, 4565);
# vector(8,n,n--; numbpart(n))

sub partitions_num_GE {
  my ($n) = @_;
  my $ret = 0;
  for (my $j = 1; $n - 3*$j*($j+1)/2 >= 0; $j++) {
    $ret += (-1)**($j+1) * $num_partitions[$n - 3*$j*($j+1)/2];
  }
  return $ret;
}
{
  my @want_connected_components   # A037306
    = (1,  # extra for N=0
       1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 3, 4, 3, 1, 1, 1, 3, 5,
       5, 3, 1, 1, 1, 4, 7, 10, 7, 4, 1, 1, 1, 4, 10, 14, 14, 10, 4, 1, 1, 1,
       5, 12, 22, 26, 22, 12, 5, 1, 1, 1, 5, 15, 30, 42, 42, 30, 15, 5, 1, 1);

  foreach my $N (0 .. 15) {
    {
      my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                    N => $N);
      ok (scalar($graph->vertices),  $num_partitions[$N],
          "N=$N num vertices");
      ok (scalar($graph->edges),  $num_partitions[$N],
          "N=$N num edges");

      my $want_num_GE = partitions_num_GE($N);
      ok (scalar($graph->predecessorless_vertices),
          $want_num_GE,
          "N=$N partitions_num_GE");
    }
    {
      # must be undirected for connected_components()
      # 2-cycle edges come out as one edge in plain non-multiedged
      my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                    N => $N,
                                    undirected => 1);
      ok (scalar($graph->vertices),  $num_partitions[$N],
          "N=$N num vertices");
      ok (scalar($graph->connected_components),  $want_connected_components[$N],
          "N=$N num components");
    }
    {
      my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                    N => $N,
                                    undirected => 1,
                                    multiedged => 1);
      ok (scalar($graph->vertices),  $num_partitions[$N],
          "N=$N num vertices");
      ok (scalar($graph->edges),  $num_partitions[$N],
          "N=$N num edges");
      ok (scalar($graph->connected_components),  $want_connected_components[$N],
          "N=$N num components");
    }
  }
}


#------------------------------------------------------------------------------
# N=1 singletons

foreach my $compositions (0, 'prepend', 'append') {
  my $N = 1;
  my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                N=>$N,
                                compositions=>$compositions);
  ok (scalar($graph->vertices), 1);
  my $got_num_GE = scalar(grep {$graph->in_degree($_)==0} $graph->vertices);
  ok ($got_num_GE, 0);
  ok ($got_num_GE, compositions_num_GE($N),
      "N=$N compositions=$compositions  compositions_num_GE");
  ok ($got_num_GE, compositions_num_GE_by_sum($N),
      "N=$N compositions=$compositions  compositions_num_GE_by_sum");
}


#------------------------------------------------------------------------------
# Triangulars

foreach my $t (1 .. 4) {
  my $N = $t*($t+1)/2;
  if ($t == 4) {
    ok ($N, 10);  # N=10 shown in POD
  }
  my $root = join(',',1..$t);
  {
    my $graph = Graph::Maker->new('Bulgarian_solitaire', N=>$N);
    ok (scalar($graph->out_degree($root)), 1);
    ok (scalar($graph->self_loop_vertices), 1);
    ok (!! $graph->is_self_loop_vertex($root), 1);
    my @self_loop_vertices = $graph->self_loop_vertices;
    ok (scalar(@self_loop_vertices), 1);
    ok ($self_loop_vertices[0], $root);
  }
  {
    my $graph = Graph::Maker->new('Bulgarian_solitaire', N=>$N,
                                  no_self_loop => 1);
    ok ($graph->out_degree($root), 0);
    ok (scalar($graph->self_loop_vertices), 0);
  }
}


#------------------------------------------------------------------------------
# Compositions

# Return the number of "Garden of Eden" compositions of $n.
# Formulas per
#    Brian Hopkins, Michael A. Jones, "Shift-Induced Dynamical Systems on
#    Partitions and Compositions", The Electronic Journal of Combinatorics
#    13 (2006), #R80.
#
sub compositions_num_GE_by_sum {
  my ($n) = @_;
  my $ret = 0;
  foreach my $j (1 .. ($n>>1)) {
    $ret += 2**($n-$j-1);
    foreach my $k (2 .. $j+1) {
      $ret -= binomial($n-$j-1, $k-2);
    }
  }
  return $ret;
}
sub compositions_num_GE {
  my ($n) = @_;
  return ($n == 0 ? 0
          : 2**($n-1) - fibonacci($n+1));
}
foreach my $N (0 .. 10) {
  ok (compositions_num_GE($N), compositions_num_GE_by_sum($N));
}

foreach my $N (0 .. 10) {
  foreach my $compositions ('prepend', 'append') {
    my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                  N => $N,
                                  compositions => $compositions);
    ok (scalar($graph->vertices), ($N==0 ? 1 : 2**($N-1)),
        "N=$N compositions=$compositions  num vertices");

    my $want_num_GE = compositions_num_GE($N);
    ok (scalar($graph->predecessorless_vertices),
        $want_num_GE,
        "N=$N compositions=$compositions  compositions_num_GE");
    ok (scalar(grep {$graph->is_predecessorless_vertex($_)} $graph->vertices),
        $want_num_GE,
        "N=$N compositions=$compositions  compositions_num_GE");
    ok (scalar(grep {$graph->in_degree($_)==0} $graph->vertices),
        $want_num_GE,
        "N=$N compositions=$compositions  compositions_num_GE");

    foreach my $from ($graph->vertices) {
      my $to = step($from,$compositions);
      ok ($graph->out_degree($from), 1,
          "N=$N from=$from to=$to");
      ok (!! $graph->has_edge($from,$to), 1);
    }
  }
}


#------------------------------------------------------------------------------
# Examples from:
#
# Jerrold R. Griggs and Chih-Chang Ho, "The Cycling of Partitions and
# Compositions under Repeated Shifts", Advances In Applied Mathematics,
# volume 21, 1998, pages 205-227, Am980597.

{
  my $graph = Graph::Maker->new('Bulgarian_solitaire', N=>6);
  ok (!! $graph->has_edge('1,1,1,1,2', '1,5'),  1);
  ok (!! $graph->has_edge('1,5', '2,4'),  1);
  ok (!! $graph->has_edge('2,4', '1,2,3'),  1);
}
{
  my $graph = Graph::Maker->new('Bulgarian_solitaire', N=>7);
  ok (!! $graph->has_edge('1,6', '2,5'),  1);
  ok (!! $graph->has_edge('2,5', '1,2,4'),  1);
  ok (!! $graph->has_edge('1,2,4', '1,3,3'),  1);
  ok (!! $graph->has_edge('1,3,3', '2,2,3'),  1);
  ok (!! $graph->has_edge('2,2,3', '1,1,2,3'),  1);
  ok (!! $graph->has_edge('1,1,2,3', '1,2,4'),  1);
}

{
  my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                N=>6, compositions=>'prepend');
  ok (!! $graph->has_edge('1,1,1,1,2', '5,1'),  1);
  ok (!! $graph->has_edge('5,1', '2,4'),  1);
  ok (!! $graph->has_edge('2,4', '2,1,3'),  1);
  ok (!! $graph->has_edge('2,1,3', '3,1,2'),  1);
  ok (!! $graph->has_edge('3,1,2', '3,2,1'),  1);
}
{
  my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                N=>7, compositions=>'prepend');
  ok (!! $graph->has_edge('6,1', '2,5'),  1);
  ok (!! $graph->has_edge('2,5', '2,1,4'),  1);
  ok (!! $graph->has_edge('2,1,4', '3,1,3'),  1);
  ok (!! $graph->has_edge('3,1,3', '3,2,2'),  1);
  ok (!! $graph->has_edge('3,2,2', '3,2,1,1'),  1);
  ok (!! $graph->has_edge('3,2,1,1', '4,2,1'),  1);
  ok (!! $graph->has_edge('4,2,1', '3,3,1'),  1);
  ok (!! $graph->has_edge('3,3,1', '3,2,2'),  1);
  ok (!! $graph->has_edge('3,2,2', '3,2,1,1'),  1);
  ok (!! $graph->has_edge('3,2,1,1', '4,2,1'),  1);
}


#------------------------------------------------------------------------------
exit 0;
