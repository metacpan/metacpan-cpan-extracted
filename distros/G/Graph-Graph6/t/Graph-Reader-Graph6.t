#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018 Kevin Ryde
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
BEGIN {  # before warnings checking
  # before warnings checking since Graph.pm 0.96 is not safe to non-numeric
  # version number from Storable.pm 
  $have_graph = eval { require Graph; 1 };
  $have_graph_error = $@;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 20)[1];
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
  my $have_graph_reader = eval { require Graph::Reader; 1 };
  my $have_graph_reader_error = $@;
  if (! $have_graph_reader) {
    MyTestHelpers::diag ('Skip due to no Graph::Reader available: ',
                         $have_graph_reader_error);
    foreach (1 .. $test_count) {
      skip ('no Graph::Reader', 1, 1);
    }
    exit 0;
  }
}

require Graph::Reader::Graph6;

my $filename = 'Graph-Reader-Graph6-t.tmp';

sub write_file {
  my $fh;
  (open $fh, '>', $filename
   and print $fh @_
   and close $fh
  ) or die "Cannot write $filename: $!";
}


#------------------------------------------------------------------------------
{
  my $want_version = 9;
  ok ($Graph::Reader::Graph6::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Reader::Graph6->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Reader::Graph6->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Reader::Graph6->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  # formats.txt graph6 example, from filename
  write_file(chr(68),chr(81),chr(99),"\n");
  my $reader = Graph::Reader::Graph6->new;
  my $graph = $reader->read_graph($filename);
  ok (join(',', sort $graph->vertices), '0,1,2,3,4');  # 5 vertices

  my @edges = $graph->edges; # [$name1,$name2]
  my @edge_names = map { join('=', @$_) } @edges;
  ok (join(',',sort @edge_names), '0=2,0=4,1=3,3=4');
}

{
  # formats.txt sparse6 example, from fh

  {
    my $fh;
    (open $fh, '>', $filename
     and print $fh ':Fa@x^', "\n"
     and close $fh)
      or die "Cannot write $filename; $!";
  }

  open my $fh, '<', $filename or die "Cannot open $filename: $!";
  my $reader = Graph::Reader::Graph6->new;
  my $graph = $reader->read_graph($fh);
  ok (join(',', sort $graph->vertices),
      '0,1,2,3,4,5,6');  # 7 vertices

  my @edges = $graph->edges; # [$name1,$name2]
  my @edge_names = map { join('=', @$_) } @edges;
  ok (join(',',sort @edge_names),
      '0=1,0=2,1=2,5=6');
}

#------------------------------------------------------------------------------

{
  # multi-edge sparse6
  my $reader = Graph::Reader::Graph6->new;
  foreach my $elem ([":A\n",0],
                    [":An\n",1],
                    [":Ab\n",2],
                    [":A_\n",3],
                   ) {
    my ($str,$want_num_edges) = @$elem;
    write_file($str);
    my $graph = $reader->read_graph($filename);
    ok (!! $graph->is_undirected, 1);
    ok (!! $graph->is_countedged, $want_num_edges>=2);
    ok (scalar($graph->edges), $want_num_edges);
  }
}


#------------------------------------------------------------------------------
unlink $filename;
exit 0;
