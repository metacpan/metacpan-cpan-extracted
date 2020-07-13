#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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

use 5.006;
use strict;
use Test;

my $have_graph;
my $have_graph_error;
BEGIN {  # before warnings checking
  # before warnings checking since Graph.pm 0.96 is not safe to non-numeric
  # version number from Storable.pm 
  $have_graph = eval { require Graph; 1 };
  $have_graph_error = $@;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 17)[1];
plan tests => $test_count;

if (! $have_graph) {
  MyTestHelpers::diag ('Skip due to no Graph.pm available: ',
                       $have_graph_error);
  foreach (1 .. $test_count) {
    skip ('no Graph.pm', 1, 1);
  }
  exit 0;
}

{
  my $have_graph_writer = eval { require Graph::Writer; 1 };
  my $have_graph_writer_error = $@;
  if (! $have_graph_writer) {
    MyTestHelpers::diag ('Skip due to no Graph::Writer available: ',
                         $have_graph_writer_error);
    foreach (1 .. $test_count) {
      skip ('no Graph::Writer', 1, 1);
    }
    exit 0;
  }
}

require Graph::Writer::Graph6;

my $filename = 'Graph-Writer-Graph6-t.tmp';

#------------------------------------------------------------------------------
{
  my $want_version = 8;
  ok ($Graph::Writer::Graph6::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Writer::Graph6->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Writer::Graph6->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Writer::Graph6->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# formats.txt graph6 example

# Return the slurped content of $filename.
sub filename_read_and_remove {
  my $str;
  {
    my $fh;
    (open $fh, '<', $filename
     and read $fh, $str, 1000
     and close $fh
    ) or die "Cannot read $filename: $!";
  }
  unlink $filename;
  return $str;
}

# Write $graph to $filename, with writer "@options".
# Read back the graph6 string from $filename and return that string.
sub try_write {
  my ($graph, @options) = @_;
  my $writer = Graph::Writer::Graph6->new (@options);
  $writer->write_graph($graph, $filename) or die "Cannot write $filename; $!";
  return filename_read_and_remove();
}

{
  my $graph = Graph::Undirected->new;
  $graph->add_vertices(0,1,2,3,4);
  $graph->add_edge(0,2);
  $graph->add_edge(0,4);
  $graph->add_edge(1,3);
  $graph->add_edge(3,4);
  # R(010010 100100) = 81 99.

  ok (try_write($graph), chr(68).chr(81).chr(99)."\n");
}
{
  # with header=>1

  my $graph = Graph::Undirected->new;
  $graph->add_vertices(0,1,2,3,4);
  $graph->add_edge(0,2);
  $graph->add_edge(0,4);
  $graph->add_edge(1,3);
  $graph->add_edge(3,4);
  # R(010010 100100) = 81 99.

  ok (try_write($graph, header=>1),
      '>>graph6<<'.chr(68).chr(81).chr(99)."\n");
}

{
  # directed or undirected  graph edge either way around
  foreach my $undirected (0,1) {
    foreach my $swapped (0,1) {
      my $graph = Graph->new (undirected => $undirected);
      $graph->add_vertices(0,1,2);
      if ($swapped) {
        $graph->add_edge(1,0);
      } else {
        $graph->add_edge(0,1);
      }

      # 100000 with padding
      ok (try_write($graph), 'B'.chr(32+63)."\n",
          "undirected=$undirected swapped=$swapped");
    }
  }
}

{
  # to a filename
  my $graph = Graph->new;
  $graph->add_edge(0,1);

  my $writer = Graph::Writer::Graph6->new;
  $writer->write_graph($graph, $filename);

  my $str;
  {
    my $fh;
    (open $fh, "<$filename"
     and read $fh, $str, 1000
     and close $fh
    ) or die "Cannot read $filename: $!";
  }
  unlink $filename;
  ok ($str, chr(63+2).chr(63+32)."\n");
}

#------------------------------------------------------------------------------
# digraph6

{
  # formats.txt digraph6 example
  my $graph = Graph->new;
  $graph->add_edges(0,2, 0,4, 3,1, 3,4);
  # print "$graph\n";
  ok (try_write($graph, format=>'digraph6'),
      "&DI?AO?\n");
}

{
  # edge back only
  my $graph = Graph->new;
  $graph->add_vertex(1);
  $graph->add_edge(2,0);
  # print "$graph\n";
  ok (try_write($graph, format=>'digraph6'),
      "&B?_\n");
}

{
  # edge both ways from undirected
  my $graph = Graph->new (undirected => 1);
  ok (!! $graph->is_undirected, 1);
  $graph->add_vertex(1);
  $graph->add_edge(2,0);
  # print "$graph\n";
  ok (try_write($graph, format=>'digraph6'),
      "&BG_\n");
}


#------------------------------------------------------------------------------

{
  # two writes to same file, overwrites
  my $graph = Graph->new (undirected => 1);
  my $writer = Graph::Writer::Graph6->new;
  $writer->write_graph($graph, $filename);
  $writer->write_graph($graph, $filename);
  my $str = filename_read_and_remove();
  ok ($str, "?\n");
}
{
  # two writes to same filehandle, appends

  my $graph = Graph->new (undirected => 1);
  my $writer = Graph::Writer::Graph6->new;
  my $fh;
  open $fh, ">$filename" or die "Cannot write $filename; $!";
  $writer->write_graph($graph, $fh) or die "Cannot write $filename; $!";
  $writer->write_graph($graph, $fh) or die "Cannot write $filename; $!";
  close $fh or die;
  my $str = filename_read_and_remove();
  ok ($str, "?\n?\n");
}

#------------------------------------------------------------------------------
unlink $filename;
exit 0;
