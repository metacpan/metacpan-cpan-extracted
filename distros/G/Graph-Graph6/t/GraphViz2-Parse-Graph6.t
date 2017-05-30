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

# uncomment this to run the ### lines
# use Smart::Comments;


# GraphViz2.pm version 2.24 up or some such, runs the "dot" program to find
# the possible graphviz attribute names, so untaint $ENV{PATH} for the
# benefit of testing taint mode.
#
$ENV{PATH} =~ /(.*)/s;
$ENV{PATH} eq $1 or die "oops dodgy untaint";
$ENV{PATH} = $1;

{
  my $have_graphviz2 = eval { require GraphViz2; 1 };
  my $have_graphviz2_error = $@;
  if (! $have_graphviz2) {
    MyTestHelpers::diag ('skip due to no GraphViz2 available: ',
                         $have_graphviz2_error);
    foreach (1 .. $test_count) {
      skip ('no GraphViz2', 1, 1);
    }
    exit 0;
  }
}

require GraphViz2::Parse::Graph6;
my $filename = 'GraphViz2-Parse-Graph6-t.tmp';


#------------------------------------------------------------------------------
# helpers

sub isa_graphviz2_object {
  my ($x) = @_;
  return (defined $x && ref $x && $x->isa('GraphViz2'));
}

sub graphviz2_vertices_str {
  my ($graphviz2) = @_;
  if (! defined $graphviz2) {
    return 'undef';
  }
  if (! ref $graphviz2) {
    return 'notref';
  }
  my $node_hash = $graphviz2->node_hash;
  return join(',', sort keys %$node_hash);
}
sub graphviz2_edges_str {
  my ($graphviz2) = @_;
  if (! defined $graphviz2) {
    return 'undef';
  }
  if (! ref $graphviz2) {
    return 'notref';
  }
  my $edge_hash = $graphviz2->edge_hash;
  my @edge_names = map { my $from = $_;
                         map {"$from=$_"} keys %{$edge_hash->{$from}}
                       } keys %$edge_hash;
  return join(',',sort @edge_names);
}

#------------------------------------------------------------------------------
{
  my $want_version = 7;
  ok ($GraphViz2::Parse::Graph6::VERSION, $want_version, 'VERSION variable');
  ok (GraphViz2::Parse::Graph6->VERSION,  $want_version, 'VERSION class method');
  ok (eval { GraphViz2::Parse::Graph6->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { GraphViz2::Parse::Graph6->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# graph parameter

{
  my $graphviz2 = GraphViz2->new (global => { name => 'Foo' });
  ok ($graphviz2->global->{'name'}, 'Foo');
  my $parse = GraphViz2::Parse::Graph6->new (graph => $graphviz2);
  my $got_graphviz2 = $parse->graph;
  ok (isa_graphviz2_object($got_graphviz2), 1);
  ok ($got_graphviz2 == $graphviz2, 1);
  ok ($got_graphviz2->global->{'name'}, 'Foo');
}

#------------------------------------------------------------------------------
# create(str)

{
  ### create(str) formats.txt sparse6 example ...

  my $parse = GraphViz2::Parse::Graph6->new;
  my $ret = $parse->create(str => ':Fa@x^'."\n");
  ok (defined $ret && $ret == $parse, 1);

  my $graphviz2 = $parse->graph;
  ok (graphviz2_vertices_str($graphviz2),
      '0,1,2,3,4,5,6');  # 7 vertices
  ok (graphviz2_edges_str($graphviz2),
      '0=1,0=2,1=2,5=6');
}

{
  # EOF
  my $parse = GraphViz2::Parse::Graph6->new;
  my $ret = $parse->create(str => '');
  ok ($ret, undef);
}

{
  # bad input, dies
  my $parse = GraphViz2::Parse::Graph6->new;
  my $no_return = 1;
  eval { $parse->create(str => '!!invalid');
         $no_return = 0;
       };
  my $err = $@;
  ok ($no_return, 1);
  ok ($err =~ /Unrecognised character: !/, 1);
}

{
  ### create(str) formats.txt digraph6 example ...

  my $parse = GraphViz2::Parse::Graph6->new;
  my $ret = $parse->create(str => "&DI?AO?\n");
  ok (defined $ret && $ret == $parse, 1);

  my $graphviz2 = $parse->graph;
  ok (graphviz2_vertices_str($graphviz2),
      '0,1,2,3,4');  # 5 vertices
  ok (graphviz2_edges_str($graphviz2),
      '0=2,0=4,3=1,3=4');
}

#------------------------------------------------------------------------------
# create(file_name)

{
  ### create(file_name) formats.txt graph6 example from filename ...

  {
    my $fh;
    (open $fh, '>', $filename
     and print $fh chr(68),chr(81),chr(99),"\n"
     and close $fh
    ) or die "Cannot write $filename: $!";
  }
  my $parse = GraphViz2::Parse::Graph6->new;
  my $ret = $parse->create(file_name => $filename);
  my $graphviz2 = $parse->graph;
  ok (defined $ret && $ret == $parse, 1);

  ok (graphviz2_vertices_str($graphviz2), '0,1,2,3,4');  # 5 vertices
  ok (graphviz2_edges_str($graphviz2), '0=2,0=4,1=3,3=4');
}

#------------------------------------------------------------------------------
# create(fh)

{
  {
    my $fh;
    (open $fh, '>', $filename
     and print $fh chr(63+2), chr(63+63)    # without newline
     and close $fh
    ) or die "Cannot write $filename: $!";
  }

  open my $fh, '<', $filename or die or die "Cannot open $filename: $!";
  my $parse = GraphViz2::Parse::Graph6->new;
  my $ret = $parse->create(fh => $fh);
  my $graphviz2 = $parse->graph;
  ok (defined $ret && $ret == $parse, 1);

  ok (graphviz2_vertices_str($graphviz2), '0,1');  # 2 vertices
  ok (graphviz2_edges_str($graphviz2), '0=1');
}

#------------------------------------------------------------------------------

{
  # chained example in the POD

  my $graphviz2 = GraphViz2::Parse::Graph6->new
    ->create(str => ":Bf\n")
    ->graph;  # GraphViz2 object

  ok (isa_graphviz2_object($graphviz2), 1);
  ok (graphviz2_vertices_str($graphviz2), '0,1,2');  # 2 vertices
  ok (graphviz2_edges_str($graphviz2), '0=1');
}


#------------------------------------------------------------------------------
unlink $filename;
exit 0;
