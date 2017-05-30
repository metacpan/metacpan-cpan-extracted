#!/usr/bin/perl -w

# Copyright 2015, 2017 Kevin Ryde
#
# This file is part of Graph-Graph6.
#
# Graph-Graph6 is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Graph6 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Graph6.  If not, see <http://www.gnu.org/licenses/>.


# Some random graph reads and writes.

use 5.005;
use strict;
use File::Spec;
use Graph;
use IPC::Run;
use Graph::Writer::Sparse6;
use Graph::Writer::Graph6;
use Graph::Writer::Matrix;


my $t = 0;
my $count = 0;
for (;;) {
  if (int(time()/3) != int($t/3)) {
    $t = time();
    print "$count\n";
  }
  $count++;

  my $graph = Graph::Undirected->new;
  my $num_vertices = int(rand(32)) + 1;
  my @vertices;
  foreach my $i (1 .. $num_vertices) {
    $graph->add_vertex(sprintf '%02d', $i);
  }
  $num_vertices = 2;

  my $num_edges = int(rand(64));
  foreach (1 .. $num_edges) {
    my $v1 = sprintf '%02d', int(rand($num_vertices));
    my $v2 = sprintf '%02d', int(rand($num_vertices));
     next if $v1 eq $v2;
    $graph->add_edge($v1,$v2);
  }
  $num_edges = $graph->edges;

  {
    my $nauty_g6_str;
    {
      my $writer = Graph::Writer::Matrix->new;
      $writer->write_graph($graph, '/tmp/random.matrix');
      IPC::Run::run(['nauty-amtog','-g', '/tmp/random.matrix'],
                    '>', \$nauty_g6_str,
                    '2>', File::Spec->devnull);
    }

    my $code_g6_str;
    {
      open my $fh, '>', \$code_g6_str or die;
      my $writer = Graph::Writer::Graph6->new;
      $writer->write_graph($graph, $fh);
    }

    if ($nauty_g6_str ne $code_g6_str) {
      print "graph6\n";
      print "code:\n$code_g6_str";
      print "amtog:\n$nauty_g6_str";
      exit 1;
    }
  }

  {
    my $nauty_s6_str;
    {
      my $writer = Graph::Writer::Matrix->new;
      $writer->write_graph($graph, '/tmp/random.matrix');
      IPC::Run::run(['nauty-amtog','-s', '/tmp/random.matrix'],
                    '>', \$nauty_s6_str,
                    '2>', File::Spec->devnull);
    }

    my $code_s6_str;
    {
      open my $fh, '>', \$code_s6_str or die;
      my $writer = Graph::Writer::Sparse6->new;
      $writer->write_graph($graph, $fh);
    }

    if ($nauty_s6_str ne $code_s6_str) {
      print "sparse6\n";
      print "num vertices $num_vertices\n";
      print "num edges    $num_edges\n";
      print "code:\n";
      show_str($code_s6_str);
      print "amtog:\n";
      show_str($nauty_s6_str);
      exit 1;
    }
  }
}

sub show_str {
  my ($str) = @_;
  print $str;
  $str =~ s/^://;
  $str =~ s/\n$//;
  foreach my $i (0 .. length($str)-1) {
    my $bits = ord(substr($str,$i,1)) - 63;
    if ($bits >= 0 && $bits <= 63) {
      printf '%06b ', ord(substr($str,$i,1))-63;
    } else {
      print $bits;
    }
  }
  print "\n";
}

exit 0;
