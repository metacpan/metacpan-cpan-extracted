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

use 5.005;
use strict;
use FindBin;
use List::Util 'min','max','sum';
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # Graph::Writer:::Graph6 not particularly fast, maybe due to has_edge(),
  # maybe just overheads

  my $num_vertices = 700;

  require Graph;
  require Graph::Writer::Graph6;
  require Graph::Writer::Sparse6;
  require Graph::Graph6;
  require Devel::TimeThis;
  require List::Util;

  my $graph = Graph->new(undirected => 1,
                         # multiedged => 1,
                        );
  $graph->add_path(List::Util::shuffle(1 .. $num_vertices));
  print ref $graph->[ Graph::_E() ],"\n";
  # {
  #   my $t = Devel::TimeThis->new("edges()");
  #   my @edges = $graph->edges;
  # }

  {
    open my $fh, '+>', \(my $str) or die;
    {
      my $t = Devel::TimeThis->new("Graph.pm has_edge()");
      my $writer = Graph::Writer::Graph6->new;
      $writer->write_graph($graph, $fh) or die;
    }
    print "length ",length($str),"\n";
  }
  {
    open my $fh, '+>', \(my $str) or die;
    {
      my $t = Devel::TimeThis->new("Graph.pm edges()");
      my $writer = Graph::Writer::Sparse6->new;
      $writer->write_graph($graph, $fh) or die;
    }
    print "length ",length($str),"\n";
  }
  {
    open my $fh, '+>', \(my $str) or die;
    {
      my $t = Devel::TimeThis->new("native Graph6");
      Graph::Graph6::write_graph(fh => $fh,
                                 num_vertices => $num_vertices,
                                 edge_predicate => sub { rand(2) });
    }
    print "length ",length($str),"\n";
  }

  exit 0;
}

{
  # Graph::Writer:::Sparse6

  require Graph;
  my $graph = Graph->new(undirected => 1,
                         multiedged => 1);
  $graph->add_edge(0,1);
  $graph->add_edge(0,1);
  $graph->add_edge(1,2);
  $graph->add_edge(2,3);
  $graph->add_edge(3,0);
  print "$graph\n";

  Graph_view($graph);

  require Graph::Writer::Sparse6;
  open my $fh, '+>', \(my $str) or die;
  my $writer = Graph::Writer::Sparse6->new;
  $writer->write_graph($graph, $fh) or die;
  seek $fh, 0, 0 or die;
  print $str,"\n";

  exit 0;
}

{
  # Graph::Writer cross used on Graph::Easy

  {
    require Graph::Writer::Graph6;
    my $writer = Graph::Writer::Graph6->new;

    require Graph::Easy;
    my $graph = Graph::Easy->new (undirected => 1);
    $graph->add_edge('b','a');
    $graph->add_edge('b','c');
    $writer->write_graph($graph, \*STDOUT);

    Graph::Graph6::read_graph(str => 'B?',
                              edge_aref => \my @edge_aref);
    print scalar(@edge_aref),"\n";
  }
  {
    require Graph::Writer::Sparse6;
    my $writer = Graph::Writer::Sparse6->new;

    require Graph::Easy;
    my $graph = Graph::Easy->new (undirected => 1);
    $graph->add_edge('b','a');
    $graph->add_edge('c','b');
    $writer->write_graph($graph, \*STDOUT);
  }
  exit 0;
}

{
  require Graph::Easy::Parser::Graph6;
  my $parser = Graph::Easy::Parser::Graph6->new;
  my $easy = $parser->from_file('/tmp/0.g6');
  MyGraphs::Graph_Easy_view($easy);
  exit 0;
}

{
  # Graph.pm neighbours() of a directed graph are both ways around,
  # predecessor() and successors() only in direction.  Cf undirected all are
  # both.

  require Graph;
  {
    my $graph = Graph->new;
    $graph->add_edge('from','to');
    print "neighbours ",$graph->neighbours('from'), "\n";
    print "neighbours ",$graph->neighbours('to'), "\n";
    print "predecessors ",$graph->predecessors('from'), "\n";
    print "predecessors ",$graph->predecessors('to'), "\n";
    print "successors ",$graph->successors('from'), "\n";
    print "successors ",$graph->successors('to'), "\n";
    print "\n";
  }
  {
    my $graph = Graph::Undirected->new;
    $graph->add_edge('from','to');
    print "neighbours ",$graph->neighbours('from'), "\n";
    print "neighbours ",$graph->neighbours('to'), "\n";
    print "predecessors ",$graph->predecessors('from'), "\n";
    print "predecessors ",$graph->predecessors('to'), "\n";
    print "successors ",$graph->successors('from'), "\n";
    print "successors ",$graph->successors('to'), "\n";
  }
  exit 0;
}

{
  # Graph::Easy has_edge() either way around

  {
    require Graph;
    print "Graph ",Graph->VERSION,"\n";
    my $graph = Graph->new (undirected => 1);
    $graph->add_edge('from','to');
    print $graph->has_edge('from','to') ? "yes\n" : "no\n";
    print $graph->has_edge('to','from') ? "yes\n" : "no\n";
  }
  {
    require Graph::Easy;
    print "Graph::Easy ",Graph::Easy->VERSION,"\n";
    my $graph = Graph::Easy->new (undirected => 1);
    $graph->add_edge('from','to');
    print $graph->has_edge('from','to') ? "yes\n" : "no\n";
    print $graph->has_edge('to','from') ? "yes\n" : "no\n";
  }
  exit 0;
}

{
  # Graph.pm single vertex eccentricity
  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_vertex('one');
  # $graph->add_edge('one','one');
  # $graph->add_edge('one','one');
  # $graph->add_edge('one','two');
  # $graph->add_edge('two','three');

  my $num_vertices = $graph->vertices;
  print "$num_vertices vertices\n";

  my @centre = $graph->centre_vertices;
  my $num_centre = scalar(@centre);
  print "centre $num_centre vertices: @centre\n";

  my $diameter = $graph->diameter;
  print "diameter: ",defined $diameter ? $diameter : 'undef', "\n";

  my $radius = $graph->radius;
  print "radius: ",defined $radius ? $radius : 'undef', "\n";

  my $eccentricity = $graph->vertex_eccentricity('one');
  print "eccentricity:  ",defined $eccentricity ? $eccentricity : 'undef', "\n";

  exit 0;
}

{
  # Graph::Reader bad input
  #   Graph::Reader::XML croaks from XML::Parser
  #   Graph::Reader::HTK returns an empty graph
  #   Graph::Reader::Dot emits some warnings and returns an empty graph
  require Module::Load;
  foreach my $class ('Graph::Reader::Dot',
                     'Graph::Reader::HTK',
                     'Graph::Reader::XML',
                     'Graph::Reader::Graph6') {
    print "--------\n";
    Module::Load::load($class);
    foreach my $filename (
                          # '/dev/null',
                          # "$FindBin::Bin/$FindBin::Script",
                          '/bin/cat',
                         ) {
      print "$class $filename\n";
      open my $fh, '<', $filename or die "Cannot open $filename: $!";
      my $reader = $class->new;
      my $graph;
      eval { $graph = $reader->read_graph($fh); };
      if ($@) {
        my $err = $@;
        print "  error: $err\n";
      } else {
        print "  returned ";
        if (! defined $graph) {
          print "undef\n";
        } elsif (! ref $graph) {
          print "value $graph\n";
        } else {
          print ref $graph,
            "  string=\"$graph\" num vertices=",scalar($graph->vertices),"\n";
        }
      }
      print "\n";
    }
  }
  exit 0;
}
{
  # Path::Class
  require Path::Class;
  my $f = Path::Class::File->new('tmp');
  print $f;
  ### $f

  require Graph::Easy::Parser;
  my $parser = Graph::Easy::Parser->new (fatal_errors => 0);
  my $graph = $parser->from_file($f);
  ### $parser->error

  exit 0;
}

{
  require Graph::Easy::Parser;
  my $parser = Graph::Easy::Parser->new (fatal_errors => 0);
  my $graph = $parser->from_text('bogus');
  print defined $graph ? $graph : undef, "\n";
  exit 0;
}

{
  # Graph::Easy::Parser error handling
  # docs say return undef, but returns graph

  require Graph::Easy::Parser::Graph6;
  {
    ### Graph-Easy-Parser ...
    my $parser = Graph::Easy::Parser->new (fatal_errors => 0);
    my $graph = $parser->from_text('');
    my $error = $parser->error();
    my $graph_error = $graph && $graph->error();
    ### eof ...
    ### $graph
    ### $error
    ### $graph_error
  }

  {
    ### Graph-Easy-Parser ...
    my $parser = Graph::Easy::Parser->new (fatal_errors => 0);
    my $graph = $parser->from_text('invalid');
    my $error = $parser->error();
    my $graph_error = $graph && $graph->error();
    ### invalid ...
    ### $graph
    ### $error
    ### $graph_error
  }

  {
    ### Graph6 parser ...
    my $parser = Graph::Easy::Parser::Graph6->new (fatal_errors => 0);
    my $graph = $parser->from_text('00bad');
    my $error = $parser->error();
    my $graph_error = $graph && $graph->error();
    ### invalid ...
    ### $graph
    ### $error
    ### $graph_error
  }
  # {
  #   my $parser = Graph::Easy::Parser::Graph6->new;
  #   my $graph = $parser->from_text('00bad');
  #   ### $graph
  # }
  exit 0;
}
{
  # graph6 various  # docs say return undef, but returns graph
  require Graph::Graph6;
  Graph::Graph6::write_graph(fh => \*STDOUT,
                             edge_aref => [ [0,1],
                                            [1,2],
                                            [2,0] ]);
  exit 0;
}
{
  # Graph::Easy::As_graph6

  require Graph::Easy;
  require Graph::Easy::As_graph6;
  my $graph = Graph::Easy->new (undirected => 1);
  $graph->add_nodes(0,1,2,3,4);
  $graph->add_edge(0,2);
  $graph->add_edge(0,4);
  $graph->add_edge(1,3);
  $graph->add_edge(3,4);

  # $graph->add_edge('0','1');
  # $graph->add_edge('1','2');
  # $graph->add_edge('2','3');
  # $graph->add_edge('1','3');
  # $graph->add_edge('3','4');

  print chr(68).chr(81).chr(99)."\n";
  print $graph->as_graph6;
  exit 0;
}

{
  # Graph::Easy::As_sparse6

  require Graph::Easy;
  require Graph::Easy::As_sparse6;
  my $graph = Graph::Easy->new (undirected => 1);
  $graph->add_nodes(0,1,2,3,4);
  $graph->add_edge(0,1);
  $graph->add_edge(0,2);
  $graph->add_edge(1,2);
  $graph->add_edge(5,6);
  print $graph->as_sparse6;
  exit 0;
}

{
  # Graph::Writer::Sparse6 formats.txt example
  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_vertices(0,1,2,3,4);
  $graph->add_edge(0,1);
  $graph->add_edge(0,2);
  $graph->add_edge(1,2);
  $graph->add_edge(5,6);
  # 000111 100010 000001 111001 011111
  # 000111 1 000 1 000 0 001 1 110 01 0 111 11
  #  n=7   + 0-1 + 0-2   1-2

  # :Fa@x^
  # 000111 100010 000001 111001 011111

  if (0) {
    require Graph::Maker::Dragon;
    $graph = Graph::Maker->new('dragon', level=>2, undirected=>1);
  }
  if (0) {
    $graph = Graph::Undirected->new;
    $graph->add_vertices(0,1,2,3);
    $graph->add_edge(0,1);
    # $graph->add_edge(0,2);
    # $graph->add_edge(1,1);
  }

  require Graph::Writer::Sparse6;
  my $writer = Graph::Writer::Sparse6->new;
  my $str;
  { open my $fh, '>', \$str or die;
    $writer->write_graph($graph, $fh);
  }

  print "code:\n";
  print $str;
  foreach my $i (1 .. length($str)-2) {
    printf '%06b ', ord(substr($str,$i,1))-63;
  }
  print "\n";
  foreach my $i (-3 .. -2) {
    printf '%d ', ord(substr($str,$i,1));
  }
  print "\n";
  print "\n";

  {
    print "Matrix code:\n";
    require Graph::Writer::Matrix;
    my $writer = Graph::Writer::Matrix->new (nauty_type => 'm');
    $writer->write_graph($graph, '/dev/stdout');
    print "\n";
  }

  print "showg:\n";
  $writer->write_graph($graph, '/tmp/x.g6');
  require IPC::Run;
  my $matrix;
  IPC::Run::run(['nauty-showg',
                 '-q',  # quiet headers
                 '-a',
                 # '-t',
                 '/tmp/x.g6', '/dev/stdout'],
                '>', \$matrix);
  print $matrix;
  $matrix = "n=$matrix";

  print "\n";
  IPC::Run::run(['nauty-amtog',
                 '-s',
                 '/dev/stdin','/tmp/y.g6'],
                '<',\$matrix);
  print "amtog:\n";
  system('cat /tmp/y.g6');

  {
    print "Sparse6 code:\n";
    my $writer = Graph::Writer::Sparse6->new;
    $writer->write_graph($graph, '/dev/stdout');
    print "\n";
  }
  exit 0;
}


{
  # Graph::Easy::Parser::Graph6 parse

  require Graph::Easy::Parser::Graph6;
  my $parser = Graph::Easy::Parser::Graph6->new;
  my $graph = $parser->from_text(':Fa@x^');
  print $graph->as_ascii;
  print "is_directed()   ",$graph->is_directed,"\n";
  print "is_undirected() ",$graph->is_undirected,"\n";
  print "type()          ",$graph->type,"\n";
  print "attribute(type) ",$graph->attribute('type'),"\n";
  # print "fatal_errors ",$graph->attribute('fatal_errors'),"\n";

  {
    my $graph = $parser->from_text(chr(68).chr(81).chr(99)."\n");
    print $graph->as_ascii;
  }
  exit 0;
}

{
  # directed and undirected

  require Graph::Easy;
  print Graph::Easy->VERSION,"\n";
  foreach my $flag (0, 1) {
    print "$flag\n";
    my $graph = Graph::Easy->new(undirected => $flag);
    print "is_directed()   ",$graph->is_directed,"\n";
    print "is_undirected() ",$graph->is_undirected,"\n";
    print "type()          ",$graph->type,"\n";
    print "attribute(type) ",$graph->attribute('type'),"\n";
    ### att: $graph->{att}
    ### att->type: $graph->{att}->{type}
  }
  exit 0;
}
{
  # padding by nauty-amtog, n=2
  require IPC::Run;
  my $str;

  $str = <<'HERE';
n=1
m
1
HERE

  $str = <<'HERE';
n=4
m
0 1 0 0
1 0 0 0
0 0 0 0
0 0 0 0
HERE

  $str = <<'HERE';
n=2
m
1 0
0 0
HERE

  my $out;
  IPC::Run::run(['nauty-amtog','-s'],'<',\$str,'>',\$out);
  print $out;
  foreach my $i (1 .. length($out)-2) {
    printf '%06b ', ord(substr($out,$i,1))-63;
  }
  print "\n";


  print "code:\n";
  require Graph;
  my $graph = Graph::Undirected->new;
  my ($num_vertices) = ($str =~ /(\d+)/);
  foreach my $i (0 .. $num_vertices-1) { $graph->add_vertex($i); }
  $graph->add_edge(0,0);
  print "$graph\n";

  require Graph::Writer::Sparse6;
  my $writer = Graph::Writer::Sparse6->new;
  $writer->write_graph($graph, \*STDOUT);

  exit 0;
}

{
  # Graph::Writer::Matrix samples
  {
    require Graph;
    my $graph = Graph::Undirected->new;
    $graph->add_edge('0','1');
    $graph->add_edge('1','2');
    $graph->add_edge('2','3');
    $graph->add_edge('1','3');
    $graph->add_edge('3','4');

    require Graph::Writer::Matrix;
    my $writer = Graph::Writer::Matrix->new;
    $writer->write_graph($graph, \*STDOUT);
  }

  {
    require Graph;
    my $graph = Graph->new;
    $graph->add_edge('0','1');
    $graph->add_edge('1','2');
    $graph->add_edge('2','3');
    $graph->add_edge('3','1');
    $graph->add_edge('4','3');

    require Graph::Writer::Matrix;
    my $writer = Graph::Writer::Matrix->new;
    $writer->write_graph($graph, \*STDOUT);
  }
  exit 0;
}

{
  # Graph::Reader::Graph6 multiple graphs
  require Graph::Reader::Graph6;
  open my $fh, '<', '/so/hog/trees08.g6' or die;
  my $reader = Graph::Reader::Graph6->new;
  for (;;) {
    my $graph = $reader->read_graph($fh);
    print "$graph\n";
  }
  exit 0;
}


{
  # Graph::Writer::Matrix
  require Graph;
  my $graph = Graph::Undirected->new;
  ### $graph
  print $graph->get_graph_attribute('omniedged');

  $graph->add_vertex('0');
  $graph->add_edge('0','1');

  require Graph::Maker::Dragon;
  $graph = Graph::Maker->new('dragon', level=>4, undirected=>1);

  require Graph::Writer::Matrix;
  my $writer = Graph::Writer::Matrix->new;
  $writer->write_graph($graph, '/tmp/x.matrix');

  require IPC::Run;
  IPC::Run::run(['nauty-amtog','-g','/tmp/x.matrix','/tmp/x.g6']);
  IPC::Run::run(['nauty-showg',
                 '-a',
                 '-t',
                 '/tmp/x.g6','/tmp/y.matrix']);
  if (-s '/tmp/x.g6' < 2000) {
  }
  system('cat /tmp/x.matrix');
  system('cat /tmp/y.matrix');

  {
    print "graph6:\n";
    require Graph::Writer::Graph6;
    my $writer = Graph::Writer::Graph6->new;
    $writer->write_graph($graph, \*STDOUT);
  }
  system('cat /tmp/x.g6');

  exit 0;
}



{
  # nauty-copyg

  require Graph::Maker::Dragon;
  my $graph = Graph::Maker->new('dragon', level=>4, undirected=>1);

  require Graph::Writer::Graph6;
  my $writer = Graph::Writer::Graph6->new;

  print "copyg:\n";
  $writer->write_graph($graph, '/tmp/x.g6');
  require IPC::Run;
  my $str;
  IPC::Run::run(['nauty-copyg',
                 '-h',
                 '-s',
                 '/tmp/x.g6', '/dev/stdout'],
               '>',\$str);
  print "output:\n";
  print $str;
  exit 0;
}

{
  # Graph::Writer::Graph6 formats.txt example
  require Graph;
  my $graph = Graph::Undirected->new;
  $graph->add_vertices(0,1,2,3,4);
  $graph->add_edge(0,2);
  $graph->add_edge(0,4);
  $graph->add_edge(1,3);
  $graph->add_edge(3,4);
  # R(010010 100100) = 81 99.

  {
    require Graph::Maker::Dragon;
    $graph = Graph::Maker->new('dragon', level=>4, undirected=>1);
  }

  require Graph::Writer::Graph6;
  my $writer = Graph::Writer::Graph6->new;
  my $str;
  open my $fh, '>', \$str or die;
  $writer->write_graph($graph, $fh);

  print $str;
  foreach my $i (-3 .. -2) {
    printf '%06b ', ord(substr($str,$i,1))-63;
  }
  print "\n";
  foreach my $i (-3 .. -2) {
    printf '%d ', ord(substr($str,$i,1));
  }
  print "\n";
  print "\n";

  {
    print "Matrix code:\n";
    require Graph::Writer::Matrix;
    my $writer = Graph::Writer::Matrix->new (nauty_type => 'm');
    $writer->write_graph($graph, '/dev/stdout');
    print "\n";
  }

  print "showg:\n";
  $writer->write_graph($graph, '/tmp/x.g6');
  require IPC::Run;
  my $matrix;
  IPC::Run::run(['nauty-showg',
                 '-q',  # quiet headers
                 '-a',
                 # '-t',
                 '/tmp/x.g6', '/dev/stdout'],
                '>', \$matrix);
  print $matrix;
  $matrix = "n=$matrix";

  print "\n";
  IPC::Run::run(['nauty-amtog',
                 '/dev/stdin','/tmp/y.g6'],
                '<',\$matrix);
  print "amtog:\n";
  system('cat /tmp/y.g6');

  {
    print "Graph6 code:\n";
    require Graph::Writer::Graph6;
    my $writer = Graph::Writer::Graph6->new;
    $writer->write_graph($graph, '/dev/stdout');
    print "\n";
  }
  exit 0;
}
