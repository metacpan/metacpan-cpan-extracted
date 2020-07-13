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

my $test_count = (tests => 23)[1];
plan tests => $test_count;

# uncomment this to run the ### lines
# use Smart::Comments;


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
{
  my $have_graph_easy_parser = eval { require Graph::Easy::Parser; 1 };
  my $have_graph_easy_parser_error = $@;
  if (! $have_graph_easy_parser) {
    MyTestHelpers::diag ('Skip due to no Graph::Easy::Parser available: ',
                         $have_graph_easy_parser_error);
    foreach (1 .. $test_count) {
      skip ('no Graph::Easy::Parser', 1, 1);
    }
    exit 0;
  }
}

require Graph::Easy::Parser::Graph6;

my $filename = 'Graph-Easy-Parser-Graph6-t.tmp';

# $easy is a Graph::Easy object
# return a string of its node names
sub easy_vertices_str {
  my ($easy) = @_;
  if (! defined $easy) {
    return 'undef';
  }
  return join(',', sort map{$_->name} $easy->nodes);
}

# $easy is a Graph::Easy object
# return a string of its edges
sub easy_edges_str {
  my ($easy) = @_;
  if (! defined $easy) {
    return 'undef';
  }
  my @edges = $easy->edges;
  my @edge_names = map { join('=',map{$_->name} $_->nodes) } @edges;
  return join(',',sort @edge_names);
}

#------------------------------------------------------------------------------

{
  my $want_version = 8;
  ok ($Graph::Easy::Parser::Graph6::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Easy::Parser::Graph6->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Easy::Parser::Graph6->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Easy::Parser::Graph6->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# vertex_name_func

{
  my $parser = Graph::Easy::Parser::Graph6->new
    (vertex_name_func => sub {
       my ($n) = @_;
       return $n+90;
     });
  my $easy = $parser->from_text(':Fa@x^'."\n");
  ok (defined $easy, 1);
  ok (easy_vertices_str($easy), '90,91,92,93,94,95,96');
  ok (easy_edges_str($easy),    '90=91,90=92,91=92,95=96');
}

#------------------------------------------------------------------------------
# from_text()

{
  ### from_text() formats.txt sparse6 example ...

  my $parser = Graph::Easy::Parser::Graph6->new;
  my $easy = $parser->from_text(':Fa@x^'."\n");
  ok (defined $easy, 1);

  ok (easy_vertices_str($easy),
      '0,1,2,3,4,5,6');  # 7 vertices
  ok (easy_edges_str($easy),
      '0=1,0=2,1=2,5=6');
}

{
  ### from_text() class method ...
  my $easy = Graph::Easy::Parser::Graph6->from_text(':'.chr(63+11));
  ok (defined $easy, 1);

  ok (easy_vertices_str($easy),
      '00,01,02,03,04,05,06,07,08,09,10');  # 11 vertices
  ok (easy_edges_str($easy),
      '');
}

{
  # EOF
  my $parser = Graph::Easy::Parser::Graph6->new;
  my $easy = $parser->from_text('');
  ok ($easy, undef);
  ok ($parser->error, '');
}
{
  # bad input
  my $parser = Graph::Easy::Parser::Graph6->new (fatal_errors => 0);
  my $easy = $parser->from_text('!!invalid');
  ok (defined $easy, 1);  # partially read graph
  ok ($parser->error, 'Unrecognised character: !');
}

#------------------------------------------------------------------------------
# from_file()

{
  ### from_file() formats.txt graph6 example from filename ...

  {
    my $fh;
    (open $fh, '>', $filename
     and print $fh chr(68),chr(81),chr(99),"\n"
     and close $fh
    ) or die "Cannot write $filename: $!";
  }
  my $parser = Graph::Easy::Parser::Graph6->new;
  my $easy = $parser->from_file($filename);
  ok (defined $easy, 1);

  ok (easy_vertices_str($easy), '0,1,2,3,4');  # 5 vertices
  ok (easy_edges_str($easy), '0=2,0=4,1=3,3=4');
}

{
  ### from_file() class method from fh ...

  {
    my $fh;
    (open $fh, '>', $filename
     and print $fh chr(63+2), chr(63+63)    # without newline
     and close $fh
    ) or die "Cannot write $filename: $!";
  }

  open my $fh, '<', $filename or die or die "Cannot open $filename: $!";
  my $parser = Graph::Easy::Parser::Graph6->new;
  my $easy = $parser->from_file($fh);
  ok (defined $easy, 1);

  ok (easy_vertices_str($easy), '0,1');  # 2 vertices
  ok (easy_edges_str($easy), '0=1');

}

#------------------------------------------------------------------------------
unlink $filename;
exit 0;
