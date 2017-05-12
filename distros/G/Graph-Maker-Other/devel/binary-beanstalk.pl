#!/usr/bin/perl -w

# Copyright 2016 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use FindBin;
use List::Util 'min','max','sum';
use MyGraphs;

use lib
  'devel/lib';
use Graph::Maker::BinaryBeanstalk;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # height=3 claw
  # height=4 https://hog.grinvin.org/ViewGraphInfo.action?id=334  H shape
  # height=5 https://hog.grinvin.org/ViewGraphInfo.action?id=502
  # height=6 hog not
  # height=7 hog not
  # height=8 hog not

  my @graphs;
  foreach my $height (0 .. 8) {
    print "height=$height\n";
    my $graph = Graph::Maker->new('binary_beanstalk',
                                  height => $height,
                                  # undirected => 1,
                                 );
    Graph_tree_print($graph);
    push @graphs, $graph;
  }
  print "\n";
  hog_searches_html(@graphs);
  exit 0;
}

{
  # text prints

  foreach my $N (50) {
    print "N=$N\n";
    my $graph = Graph::Maker->new('binary_beanstalk',
                                  # N => $N,
                                  height => $N,
                                  undirected => 1,
                                 );
    Graph_tree_print($graph, flow=>'down');
    Graph_tree_print($graph, flow=>'up');
  }
  print "\n";
  exit 0;
}
{
  # non contiguous parents in row

  # 120 121  122 123   124 125
  #  \   /    \   /     \   /
  #   116      117  118  119
  #     \     /      \   /
  #       112         113
  #        \-----v-----/

  my @values;
  my $row_start = 2;
  foreach my $depth (2 .. 500) {
    print "depth=$depth  at $row_start\n";
    # push @values, $row_start;

    my $count = 0;
    my $prev = n_to_parent($row_start);
    for (my $v = $row_start+1; ; $v++) {
      my $p = n_to_parent($v);
      ### at: "v=$v parent=$p"
      if ($p >= $row_start) {
        ### next row ...
        $row_start = $v;
        last;
      }
      if ($p != $prev && $p != $prev+1) {
        print "  depth=$depth  v=$v not contiguous parent prev=$prev parent=$p\n";
        $count++;
      }
      $prev = $p;
    }
    # push @values, $count;
    if ($count) {
      push @values, $depth-1;
    }
  }

  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values,
                           verbose=>1);
  exit 0;

  sub n_to_parent {
    my ($n) = @_;
    return $n - Graph::Maker::BinaryBeanstalk::_count_1_bits($n);
  }
}



{
  # height 3 is 3 rows
  require Graph::Maker::BalancedTree;
  my $graph = Graph::Maker->new('balanced_tree',
                                fan_out => 2, height => 3,
                               );
  Graph_tree_print($graph, flow=>'down');
  exit 0;
}
{
  # last in each row A173601
  my @v = (0,1,3,5,7,9,11,15,17,19,23,27,31,33,35,39,43,47,51,55,59,63,65,67,71,75,79,83,87,91,95,99,103,107,111,115,119,125,127,129,131,135,139,143,147,151,155,159,163,167,171,175,179,183,189,191,195,199,203,207);

  #    # for(i=1,#v,print(binary(v[i])))
  # vector(#v,i,i-=2; if(i==-1,0, 2*i+1)) - v
  # h_to_n(h) = my(i=h-#binary(h));if(i+#binary(i)==h0);while(h>2^p+p+1,p++); 2*(h+p)+1;
  # h_to_n(h) = my(p=0);while(h>2^p+p+1,p++); 2*(h+p)+1;
  # h_to_n(h) = my(p=1);while(1,if(h<2^p+1, return(2^(p+1)+2*h+1)); h-=2^p+1);
  # h_to_n(h) = h-=4;my(i=0);while(i+#binary(i)+1<=h,i++); 4*(h-#binary(i)+1)+3 - 2*(i+#binary(i)==h-1);   i+#binary(i)-h
  # for(h=1,40,printf("%24s %24s\n",binary(h_to_n(h)),binary(v[h])))
  # vector(#v,h,h--;h_to_n(h))

  my @values;
  foreach my $v (@v) {
    printf "%8b %d\n", $v, strip_high_1($v>>2);
    push @values, $v+1;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values,
                           verbose=>1);
  exit 0;

  sub strip_high_1 {
    my ($n) = @_;
    foreach my $i (reverse 0 .. 63) {
      if ($n & (1 << $i)) {
        $n ^= (1 << $i);
        last;
      }
    }
    return $n;
  }
}

{
  # N to depth

  # 3,5,8,13,22,69
  # 4,6,9,14,23,70
  #
  # A213709 depths from 2^n-1 to 2^(n+1)-1
  # 1,1,2,3,5,9,17,30,54,98,179,330,614,1150,2162,4072,7678,14496,27418,51979,98800,188309,359889,689649,1325006,2552031,4926589,9529551,18463098,35815293,69534171,135069124,262448803,510047416,991381433,1927317745,3747885517

  my @values;
  my $prev = 0;
  foreach my $i (0 .. 22) {
    my $n = (1 << $i) - 1;
    my $depth = n_to_depth($n);
    printf "%2d depth=%7d %32b  %+d\n", $i, $depth, $depth, $depth-$prev;
    push @values, $depth;
    $prev = $depth;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values,
                           verbose=>1);
  exit 0;

  sub n_to_depth {
    my ($n) = @_;
    my $depth = 0;
    while ($n > 0) {
      $n -= Graph::Maker::BinaryBeanstalk::_count_1_bits($n);
      $depth++;
    }
    return $depth;
  }
}
{
  # first in each row A213708 minimum i where A071542(i)=n
  my @v = (0,1,2,4,6,8,10,12,16,18,20,24,28,32,34,36,40,44,48,52,56,60,64,66,68,72,76,80,84,88,92,96,100,104,108,112,116,120,126,128,130,132,136,140,144,148,152,156,160,164,168,172,176,180,184,190,192,196,200,204,208,212,216,222,226,232,238,244,250,256,258,260,264,268,272,276);

  # 3,5,8,13,22,69
  # 4,6,9,14,23,70
  foreach my $i (0 .. $#v) {
    my $v = $v[$i];
    printf "%8b i=%d  %d\n", $v, $i, $v>>2;
  }
  exit 0;
}


