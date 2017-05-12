#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde
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

use strict;
use Test;

my $have_graph;
my $have_graph_error;
BEGIN {
  # before warnings checking since Graph.pm 0.96 is not safe to non-numeric
  # version number from Storable.pm 
  $have_graph = eval { require Graph; 1 };
  $have_graph_error = $@;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

my $test_count = (tests => 12)[1];
plan tests => $test_count;

if (! $have_graph) {
  MyTestHelpers::diag ('Skip due to no Graph.pm available: ',$have_graph_error);
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

require Graph::Writer::Sparse6;

my $filename = 'Graph-Writer-Sparse6-t.tmp';

#------------------------------------------------------------------------------
{
  my $want_version = 6;
  ok ($Graph::Writer::Sparse6::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Writer::Sparse6->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Writer::Sparse6->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Writer::Sparse6->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# formats.txt sparse6 example

sub try_write {
  my ($graph, @options) = @_;
  {
    my $writer = Graph::Writer::Sparse6->new (@options);
    my $fh;
    (open $fh, '+>', $filename
     and $writer->write_graph($graph, $fh)
     and close $fh
    ) or die "Cannot write $filename; $!";
  }
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

{
  my $graph = Graph::Undirected->new;
  $graph->add_vertices(0,1,2,3,4);
  $graph->add_edge(0,1);
  $graph->add_edge(0,2);
  $graph->add_edge(1,2);
  $graph->add_edge(5,6);

  ok (try_write($graph), ':Fa@x^'."\n");
}
{
  # with header=>1

  my $graph = Graph::Undirected->new;
  $graph->add_vertices(0,1,2,3,4);
  $graph->add_edge(0,1);
  $graph->add_edge(0,2);
  $graph->add_edge(1,2);
  $graph->add_edge(5,6);

  ok (try_write($graph, header=>1), '>>sparse6<<:Fa@x^'."\n");
}

{
  # directed graph either way around
  foreach my $dir (0,1) {
    my $graph = Graph->new;
    $graph->add_vertices(0,1,2);
    if ($dir) {
      $graph->add_edge(1,0);
    } else {
      $graph->add_edge(0,1);
    }

    # 100000 with padding
    ok (try_write($graph), ":Bf\n",
        "dir=$dir");
  }
}

{
  # to a filename
  my $graph = Graph->new;
  $graph->add_edge(0,1);

  my $writer = Graph::Writer::Sparse6->new;
  $writer->write_graph($graph, $filename);

  my $str;
  {
    my $fh;
    (open $fh, '<', $filename
     and read $fh, $str, 1000
     and close $fh
    ) or die "Cannot read $filename: $!";
  }
  unlink $filename;
  ok ($str, ':'.chr(63+2).chr(63+32 +15)."\n");
}

#------------------------------------------------------------------------------
# countedged write

{
  my $graph = Graph::Undirected->new (countedged => 0);
  $graph->add_vertices(0,1);
  $graph->add_edge(0,1);
  $graph->add_edge(0,1);
  ok (try_write($graph), ':A'.chr(0x2F+63)."\n");
  # binary 101111, four pad bits
}
{
  my $graph = Graph::Undirected->new (countedged => 1);
  $graph->add_vertices(0,1);
  $graph->add_edge(0,1);
  $graph->add_edge(0,1);
  ok (try_write($graph), ':A'.chr(0x23+63)."\n");
  # binary 100011, two pad bits
}
{
  my $graph = Graph::Undirected->new (countedged => 1);
  $graph->add_vertices(0,1);
  $graph->add_edge(0,1);
  $graph->add_edge(0,1);
  $graph->add_edge(0,1);
  ok (try_write($graph), ':A'.chr(0x20+63)."\n");
  # binary 100000
}

#------------------------------------------------------------------------------
unlink $filename;
exit 0;
