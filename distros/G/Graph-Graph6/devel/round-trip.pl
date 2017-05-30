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

use 5.005;
use strict;

use Graph;
use Graph::Writer::Graph6;
use Graph::Writer::Sparse6;
# use Graph::Writer::Matrix;

use Graph::Reader::Graph6;
use Graph::Easy;
use Graph::Easy::Parser::Graph6;
use Graph::Easy::As_graph6;
use Graph::Easy::As_sparse6;

# uncomment this to run the ### lines
# use Smart::Comments;


my $t = 0;
my $count = 0;
for (;;) {
  if (int(time()/3) != int($t/3)) {
    $t = time();
    print "$count\n";
  }
  $count++;

  my $graph = Graph->new;        # (undirected => 1);
  my $easy = Graph::Easy->new;   # (undirected => 1);

  my $num_vertices = int(rand(100)) + 1;
  my @vertices;
  foreach my $i (1 .. $num_vertices) {
    my $vertex = sprintf '%02d', $i;
    $graph->add_vertex($vertex);
    $easy->add_vertex($vertex);
  }
  $num_vertices = 2;

  my $num_edges = int(rand(64));
  foreach (1 .. $num_edges) {
    my $v1 = sprintf '%02d', int(rand($num_vertices));
    my $v2 = sprintf '%02d', int(rand($num_vertices));
    $graph->add_edge($v1,$v2);
    $easy->add_edge($v1,$v2);
  }
  $num_edges = $graph->edges;

  my $header = int(rand(2));

  my $g6_str;
  {
    open my $fh, '>', \$g6_str or die;
    my $writer = Graph::Writer::Graph6->new (header => $header);
    $writer->write_graph($graph, $fh);
  }
  my $s6_str;
  {
    open my $fh, '>', \$s6_str or die;
    my $writer = Graph::Writer::Graph6->new (format => 'sparse6',
                                             header => $header);
    $writer->write_graph($graph, $fh);
    if ($count == 1) {
      print "sparse6:\n";
      print $s6_str;
    }
  }
  my $d6_str;
  {
    open my $fh, '>', \$d6_str or die;
    my $writer = Graph::Writer::Graph6->new (format => 'digraph6',
                                             header => $header);
    $writer->write_graph($graph, $fh);
    if ($count == 1) {
      print "digraph6:\n";
      print $d6_str;
    }
  }

  {
    # Graph::Easy::Parser then ->as_graph6 same file content

    my $parser = Graph::Easy::Parser::Graph6->new;
    my $new_easy = $parser->from_text($g6_str);
    my $new_str = $new_easy->as_graph6 (header => $header);
    if ($new_str ne $g6_str) {
      print "Easy graph6\n";
      print "num vertices $num_vertices\n";
      print "num edges    $num_edges\n";
      print "original:\n";
      show_str($g6_str);
      print "round trip:\n";
      show_str($new_str);
      exit 1;
    }
  }

  {
    # Graph::Easy::Parser then ->as_sparse6 same file content

    my $parser = Graph::Easy::Parser::Graph6->new;
    my $new_easy = $parser->from_text($s6_str);
    my $new_str = $new_easy->as_sparse6 (header => $header);
    if ($new_str ne $s6_str) {
      print "Easy sparse6\n";
      print "num vertices $num_vertices\n";
      print "num edges    $num_edges\n";
      print "original:\n";
      show_str($s6_str);
      print "round trip:\n";
      show_str($new_str);
      exit 1;
    }
  }

  {
    # Graph::Easy::Parser then ->as_graph6(format=>'digraph6') same file content

    my $parser = Graph::Easy::Parser::Graph6->new;
    my $new_easy = $parser->from_text($d6_str);
    my $new_str = $new_easy->as_graph6 (format=>'digraph6', header=>$header);
    if ($new_str ne $d6_str) {
      print "Easy digraph6\n";
      print "num vertices $num_vertices\n";
      print "num edges    $num_edges\n";
      print "original:\n";
      show_str($d6_str);
      print "round trip:\n";
      show_str($new_str);
      exit 1;
    }
  }

  #---------

  {
    # Graph::Reader then Writer same file content -- graph6
    open my $fh, '<', \$g6_str or die;
    my $reader = Graph::Reader::Graph6->new;
    my $new_graph = $reader->read_graph($fh);

    my $new_str;
    {
      open my $fh, '>', \$new_str or die;
      my $writer = Graph::Writer::Graph6->new (header => $header);
      $writer->write_graph($graph, $fh);
    }
    if ($new_str ne $g6_str) {
      print "graph6\n";
      print "original:\n$g6_str";
      print "round trip:\n$new_str";
      exit 1;
    }
  }

  {
    # Graph::Reader then Writer same file content -- sparse6

    open my $fh, '<', \$s6_str or die;
    my $reader = Graph::Reader::Graph6->new;
    my $new_graph = $reader->read_graph($fh);

    my $new_str;
    {
      open my $fh, '>', \$new_str or die;
      my $writer = Graph::Writer::Sparse6->new (header => $header);
      $writer->write_graph($graph, $fh);
    }
    if ($new_str ne $s6_str) {
      print "sparse6\n";
      print "num vertices $num_vertices\n";
      print "num edges    $num_edges\n";
      print "original:\n";
      show_str($s6_str);
      print "round trip:\n";
      show_str($new_str);
      exit 1;
    }
  }

  {
    # Graph::Reader then Writer same file content -- digraph6
    open my $fh, '<', \$d6_str or die;
    my $reader = Graph::Reader::Graph6->new;
    my $new_graph = $reader->read_graph($fh);

    my $new_str;
    {
      open my $fh, '>', \$new_str or die;
      my $writer = Graph::Writer::Graph6->new (format => 'digraph6',
                                               header => $header);
      $writer->write_graph($graph, $fh);
    }
    if ($new_str ne $d6_str) {
      print "digraph6\n";
      print "original:\n$g6_str";
      print "round trip:\n$new_str";
      exit 1;
    }
  }
}

sub show_str {
  my ($str) = @_;
  print $str;
  print "[length ",length($str),"]\n";
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
