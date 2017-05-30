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

use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 26)[1];
plan tests => $test_count;

{
  my $have_graph_easy = eval { require Graph::Easy; 1 };
  my $have_graph_easy_error = $@;
  if (! $have_graph_easy) {
    MyTestHelpers::diag ('Skip due to no Graph::Easy available: ',
                         $have_graph_easy_error);
    foreach (1 .. $test_count) {
      skip ('no Graph::Easy', 1, 1);
    }
    exit 0;
  }
}

require Graph::Easy::As_graph6;

#------------------------------------------------------------------------------
{
  my $want_version = 7;
  ok ($Graph::Easy::As_graph6::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Easy::As_graph6->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Easy::As_graph6->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Easy::As_graph6->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# format => "graph6"

{
  # no edges
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1,2);

  my $str = $easy->as_graph6;
  ok ($str, 'B?'."\n");
}
{
  # with header=>1 option
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1,2);

  my $str = $easy->as_graph6 (header=>1);
  ok ($str, '>>graph6<<B?'."\n");
}
{
  # self-loop ignored
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1,2);
  $easy->add_edge(0,0);

   my $str = $easy->as_graph6;
  ok ($str, 'B?'."\n");
}
{
  # directed or undirected  graph edge either way around
  foreach my $undirected (0,1) {
    foreach my $swapped (0,1) {
      my $easy = Graph::Easy->new (undirected => $undirected);
      $easy->add_vertices(0,1,2);
      if ($swapped) { 
        $easy->add_edge(1,0);
      } else {
        $easy->add_edge(0,1);
      }

      # 100000 with padding
      my $str = $easy->as_graph6;
      ok ($str, 'B'.chr(32+63)."\n",
          "undirected=$undirected swapped=$swapped");
    }
  }
}

#------------------------------------------------------------------------------
# format => "digraph6"

{
  # formats.txt digraph6 example
  my $easy = Graph::Easy->new;      # directed
  $easy->add_vertices(0,1,2,3,4);
  $easy->add_edge(0,2);
  $easy->add_edge(0,4);
  $easy->add_edge(3,1);
  $easy->add_edge(3,4);
  ok ($easy->as_graph6(format=>'digraph6'),
      "&DI?AO?\n");
  ok ($easy->as_graph6(format=>'digraph6',header=>1),
      ">>digraph6<<&DI?AO?\n");
}
{
  # no edges
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1,2);
  ok ($easy->as_graph6(format=>'digraph6'), "&B??\n");
}
{
  # self-loop
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1,2);
  $easy->add_edge(0,0);

  # 100000
  my $str = $easy->as_graph6(format=>'digraph6');
  ok ($str, '&B'.chr(32+63)."?\n");
}

{
  # undirected graph either way around
  foreach my $dir (0,1) {
    my $easy = Graph::Easy->new (undirected => 1);
    $easy->add_vertices(0,1,2);
    if ($dir) {
      $easy->add_edge(1,0);
    } else {
      $easy->add_edge(0,1);
    }

    my $str = $easy->as_graph6(format=>'digraph6');
    ok ($str, "&BS?\n",
        "dir=$dir");
  }
}

#------------------------------------------------------------------------------
# format => "sparse6"

{
  # formats.txt sparse6 example
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1,2,3,4);
  $easy->add_edge(0,1);
  $easy->add_edge(0,2);
  $easy->add_edge(1,2);
  $easy->add_edge(5,6);

  my $str = $easy->as_graph6 (format=>'sparse6');
  ok ($str, ':Fa@x^'."\n");
}
{
  # with header=>1
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1,2,3,4);
  $easy->add_edge(0,1);
  $easy->add_edge(0,2);
  $easy->add_edge(1,2);
  $easy->add_edge(5,6);

  my $str = $easy->as_graph6 (format=>'sparse6', header=>1);
  ok ($str, '>>sparse6<<:Fa@x^'."\n");
}
{
  # no edges
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1,2);

  my $str = $easy->as_graph6 (format=>'sparse6');
  ok ($str, ':B'."\n");
}
{
  # self-loop
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1,2);
  $easy->add_edge(0,0);

  # 000111 with padding
  my $str = $easy->as_graph6 (format=>'sparse6');
  ok ($str, ':B'.chr(7+63)."\n");
}
{
  # multi-edge
  my $easy = Graph::Easy->new;
  $easy->add_vertices(0,1);
  $easy->add_edge(0,1);
  my $str = $easy->as_graph6 (format=>'sparse6');
  ok ($str, ':A'.chr(0x2F+63)."\n"); # 101111 with padding

  $easy->add_edge(0,1);
  $str = $easy->as_graph6 (format=>'sparse6');
  ok ($str, ':A'.chr(0x23+63)."\n"); # 100011 with padding

  $easy->add_edge(0,1);
  $str = $easy->as_graph6 (format=>'sparse6');
  ok ($str, ':A'.chr(0x20+63)."\n"); # 100000 with padding
}

{
  # directed graph either way around
  foreach my $dir (0,1) {
    my $easy = Graph::Easy->new;
    $easy->add_vertices(0,1,2);
    if ($dir) {
      $easy->add_edge(1,0);
    } else {
      $easy->add_edge(0,1);
    }

    my $str = $easy->as_graph6 (format=>'sparse6');
    ok ($str, ":Bf\n",
        "dir=$dir");
  }
}

#------------------------------------------------------------------------------
exit 0;
