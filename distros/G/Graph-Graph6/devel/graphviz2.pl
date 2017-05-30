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
use FindBin;
use List::Util 'min','max','sum';
use MyGraphs;
use GraphViz2;
use GraphViz2::Parse::Graph6;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # digraph6
  require GraphViz2::Parse::Graph6;
  require IPC::Run;
  my $genspecialg_program = 'nauty-genspecialg';

  # open OUT as a pipe filehandle to read the output of "geng"
  IPC::Run::start([$genspecialg_program,
                   '-z',    # directed
                   '-c6',   # cycle-6
                  ],
                  '>pipe', \*OUT);

  my $graphviz2 = GraphViz2->new(global => {directed => 1});
  my $parse = GraphViz2::Parse::Graph6->new(graph=>$graphviz2)
    ->create(fh=>\*OUT);
  $graphviz2->run(format => 'xlib');
  exit 0;
}

{
  # output formats  file:///usr/share/doc/graphviz/html/info/output.html
  require GraphViz2::Parse::Graph6;
  my $parse = GraphViz2::Parse::Graph6->new;
  my $graphviz2 = $parse->graph;
  $graphviz2->default_node(shape=>'triangle');

  $parse->create(file_name => "$ENV{HOME}/HOG/trees10.g6");

  # $graphviz2->run(format => 'dot', output_file => '/tmp/x.dot');
  $graphviz2->run(format => 'xlib');
  # print $graphviz2->dot_input;
  exit 0;
}

{
  my $graphviz2 = GraphViz2->new(edge   => {},
                                 global => {directed => 0},
                                 graph  => {},
                                 node   => {},
                                 verbose => 1,
                                );
  # $graphviz2->default_graph(directed => 'graph');
  # $graphviz2->default_graph(global => { directed => 1 });

  ### global: $graphviz2->global
  # $graphviz2->global->{directed=>'digraph'};
  ### global: $graphviz2->global

  $graphviz2->add_edge(from => 'one', to => 'two');
  $graphviz2->run(format => 'x11', output_file => '/dev/stdout');
  exit 0;
}
{
  require GraphViz2::Parse::Regexp;
  my $parse = GraphViz2::Parse::Regexp->new;
  my $graphviz2 = $parse->graph;
  ### after new: ref $graphviz2

  $parse->create(regexp => '(([abcd0-9])|(foo))');
  ### after create: ref $graphviz2

  my $ps_filename = '/tmp/x.ps';
  $graphviz2->run(format => 'ps', output_file => $ps_filename);
  MyGraphs::postscript_view_file($ps_filename);
  exit 0;
}

{
  require GraphViz2::Parse::Regexp;
  my $graphviz2 = GraphViz2->new(edge   => {},
                                 global => {directed => 1},
                                 graph  => {concentrate => 1, rankdir => 'TB'},
                                 node   => {},
                                 verbose => 1,
                                );
  my $parse = GraphViz2::Parse::Regexp->new;
  $graphviz2 = $parse->graph;
  $parse->create(regexp => '(([abcd0-9])|(foo))');
  my $ps_filename = '/tmp/x.ps';
  $graphviz2->run(format => 'ps', output_file => $ps_filename);
  MyGraphs::postscript_view_file($ps_filename);
  exit 0;
}

{
  # ISA graph
  print GraphViz2->VERSION,"\n";
  require GraphViz2::Parse::ISA;
  my $i = GraphViz2::Parse::ISA->UNIVERSAL::isa('GraphViz2::Parse::ISA');
  # my $i = GraphViz2::Parse::ISA->isa('GraphViz2::Parse::ISA');
  ### $i

  my $parse = GraphViz2::Parse::ISA->new;
  my $graph = $parse->graph;
  ### after create: ref $graph

  $parse->add(class => 'GraphViz2::Parse');
  $graph = $parse->graph;
  ### after add: ref $graph

  exit 0;
}

{
  # ->log(error=>"...") is a die, doesn't go through logger

  use GraphViz2;
  use Log::Handler;
  my $logger = Log::Handler -> new;
  $logger->add (screen => { die_on_errors  => 1,
                            minlevel       => 'error',
                            maxlevel       => 'debug',
                            message_layout => 'message: %m',
                          }
               );
  my $graphviz2 = GraphViz2->new (logger => $logger);
  $logger->error("blah");
  # $graphviz2->log(error => "eek");
  print "end\n";
  exit 0;
}




{
  # ISA graph
  print GraphViz2->VERSION,"\n";
  require GraphViz2::Parse::ISA;
  my $graphviz2 = GraphViz2->new (global => {directed => 1});
  my $parse = GraphViz2::Parse::ISA->new; #  (graph => $graphviz2)
  $graphviz2 = $parse->graph;
  $parse->add(class => 'GraphViz2::Parse::ISA', ignore => []);
  $parse->generate_graph;
  exit 0;

  $graphviz2->run(format => 'xlib');
}

{
  # strace perl devel/graphviz2.pl 2>&1|le

  print "create start\n";
  GraphViz2->new;
  print "create end\n";
  print "second create start\n";
  GraphViz2->new;
  print "second create end\n";
  exit 0;
}




{
  my $graphviz2 = GraphViz2->new(name => '\'',
                                );
  $graphviz2->add_node(name => '\\\\');
  $graphviz2->add_node(name => 'bar');
  $graphviz2->add_edge(from => '\\\\', to => 'bar');
  
  my $ps_filename = '/tmp/x.ps';
  $graphviz2->run(format => 'ps', output_file => $ps_filename);

  my $dot = $graphviz2->dot_input;
  ### $dot
  my $command = $graphviz2->command;
  ### $command

  postscript_view($ps_filename);
  exit 0;
}

{
  require Graph;
  my $graph = Graph::Undirected->new(countedged => 1);
  $graph->add_edge(0,1);
  $graph->add_edge(0,1);
  $graph->add_edge(1,2);
  $graph->add_edge(2,3);

  $graph->add_edge(3,0);
  print "$graph\n";
  Graph_view($graph);

  require Graph::Writer::Sparse6;
  open my $fh, '+>', \my $str or die;
  my $writer = Graph::Writer::Sparse6->new;
  $writer->write_graph($graph, $fh) or die;
  seek $fh, 0, 0 or die;
  print $str;

  require GraphViz2::Parse::Graph6;
  my $graphviz2 = GraphViz2->new(edge   => {},
                                 global => {},
                                 graph  => {},
                                 node   => {},
                                 verbose => 1,
                                );
  my $parse = GraphViz2::Parse::Graph6->new(graph => $graphviz2);
  $parse->create(fh => $fh);
  my $ps_filename = '/tmp/x.ps';
  $graphviz2->run(format => 'ps', output_file => $ps_filename);
  postscript_view($ps_filename);
  exit 0;
}

{
  require GraphViz2::Parse::Graph6;
  my $graphviz2 = GraphViz2->new(edge   => {},
                                 global => {directed => 1},
                                 graph  => {},
                                 node   => {},
                                 verbose => 1,
                                );
  my $parse = GraphViz2::Parse::Graph6->new(graph => $graphviz2);
  $parse->create(str => ':Fa@x^'
                 # chr(68).chr(81).chr(99)."\n"
                );
  my $ps_filename = '/tmp/x.ps';
  $graphviz2->run(format => 'ps', output_file => $ps_filename);
  postscript_view($ps_filename);
  exit 0;
}

{
  # takes the yacc grammar DFA output file

  require GraphViz2::Parse::Yacc;
  require File::Locate::Iterator;
  my $it = File::Locate::Iterator->new (suffixes => ['.y','.yacc']);
  while (defined (my $filename = $it->next)) {
    print $filename,"\n";

    my $graphviz2 = GraphViz2->new(edge   => {},
                                   global => {directed => 1},
                                   graph  => {concentrate => 1, rankdir => 'TB'},
                                   node   => {},
                                   verbose => 1,
                                  );
    my $parse = GraphViz2::Parse::Yacc->new(graph => $graphviz2);
    # .y to .output ...
    $parse->create(file_name => $filename);

    my $ps_filename = '/tmp/x.ps';
    $graphviz2->run(format => 'ps', output_file => $ps_filename);
    postscript_view($ps_filename);
    last;
  }
  exit 0;
}




# ->log(error => ) always dies, can't capture with $logger
#
# my $logger_str;
# {
#   package MyLogger;
#   sub new {
#     my $class = shift;
#     return bless { @_ }, $class;
#   }
#   sub error {
#     my ($self, @args) = @_;
#     $logger_str = join(@args);
#     ### $logger_str
#   }
#   our $AUTOLOAD;
#   sub AUTOLOAD {
#     my ($self, @args) = @_;
#     # ### $AUTOLOAD
#     # ### @args
#   }
# }
# my $logger = MyLogger->new;
# 
# 
#   my $graphviz2 = GraphViz2->new(logger => $logger);
#   ok ($graphviz2->logger == $logger, 1);
#   my $parse = GraphViz2::Parse::Graph6->new (graph => $graphviz2);
#   ok ($parse->graph == $graphviz2, 1);
# 
#   undef $logger_str;

