#_{ Encoding and name
=encoding utf8

=head1 NAME

GraphViz::Graph - Object Oriented interface to graphviz.

=cut

package GraphViz::Graph;

use strict;
use warnings;
use utf8;
#_}
#_{ Version
=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
#_}
#_{ Synopsis
=head1 SYNOPSIS

    use GraphViz::Graph;

    my $graph = GraphViz::Graph->new('filename-without-suffix');

    # Create nodes:
    my $nd_1 = $graph->node(…);
    my $nd_2 = $graph->node(…);

    # Connect nodes:
    $graph->edge($nd_1, $nd_2);

    # Create .dot file, run graphviz/dot to
    # create filename-without-suffix.png:
    $graph->create('png');

Note: C<GraphViz::Graph> needs C<dot> somewhere in C<$PATH>.

=cut
#_}
#_{ use …

use Carp;
use GraphViz::Graph::Edge;
use GraphViz::Graph::Label;
use GraphViz::Graph::Node;

#_}
#_{ Methods
=head1 METHODS
=cut

sub new { #_{

=head2 new

    my $graph = GraphViz::Graph->new('FileNameBase');

Start a graph. C<'FileNameBase'> is the base name for the produced dot and png/pdf/svg… etc. output file. (See L</create>).

=cut

  my $class          = shift;
  my $file_base_name = shift;
  my $opts           = shift // {};

  my $self           = {};

  croak 'File base name must be passed' unless defined $file_base_name;
  croak 'File base name must be sclar'  unless ref \$file_base_name eq 'SCALAR';

  $self -> {file_base_name} = $file_base_name;

# $opts->{file_base_name} = $file_base_name;

  croak "Unrecognized opts " . join "/", keys %$opts if keys %$opts;

  $self->{nodes     } = [];
  $self->{edges     } = [];
  $self->{same_ranks} = [];

  bless $self, $class;
  return $self;

} #_}
sub label { #_{
#_{ POD
=head2 label

    # Add text label:
    $graph->label({text => 'Graph Title'}');

    # Add html label:
    $graph->label({html => '<font point-size="20">Say <font face="Courier">Hello World</font></font>'}');

    # Position label:
    my $graph_lbl = $graph->label(…);
    $graph_lbl -> loc('t'); # t = top

Add a label to a graph. Note, a graph can only have one label. This label is most probably used as a title.

For positioning the label, see L<GraphViz::Graph::Label/loc>.

=cut
#_}
  my $self = shift;
  my $opts = shift;

  $self -> {label} = GraphViz::Graph::Label->new($opts);

} #_}
sub node { #_{
 #_{
=head2 node

    my $nd_foo = GraphViz::Graph->node();
    # … later:
    $nd_foo -> label({html=>"<b>Bold</b><i>Italic</i>"});

Add a node to a graph. The returned object is a L<GraphViz::Graph::Node>.

=cut
 #_}
  my $self = shift;
# my $opts = shift;

  my $node = GraphViz::Graph::Node -> new();

  push @{$self->{nodes}}, $node;

  return $node;

} #_}
sub edge { #_{
 #_{
=head2 edge

Add an edge to a graph.

    my $nd_one   = $graph->node();
    my $nd_two   = $graph->node();
    my $nd_three = $graph->node();

    $nd_one->label({html=>"…"});

    $nd_two->label({html=>"<table>
      <tr><td port='port_f'>f</td><td>g</td></tr>
    </table>"});

    $graph->edge($nd_one, $nd_two->port('port_f')):
    $graph->edge($nd_two, $nd_three);

=cut
 #_}
  my $self = shift;
  my $from = shift;
  my $to   = shift;

  my $edge = GraphViz::Graph::Edge -> new($from, $to);

  push @{$self->{edges}}, $edge;

  return $edge;

} #_}
sub same_rank { #_{
#_{ POD
=head2 same_rank

    $graph->same_rank($node_one, $node_two);
    $graph->same_rank($node_one, $node_two, $node_three, …);

Put two or more L<nodes|GraphViz::Graph::Node> on the same rank.

=cut

  my $self  = shift;
  my $nodes = [];

  for my $node (@_) { #_{
    croak "Graph - same_rank: Argument $node should be a GraphViz::Graph::Node" unless $node->isa('GraphViz::Graph::Node');
    push @$nodes, $node;
  } #_}

  push @{$self->{same_ranks}}, $nodes;

#_}
} #_}
sub write_dot { #_{

  my $self = shift;
  open my $out, '>', "$self->{file_base_name}.dot";

  print $out "digraph {\n";

  for my $node (@{$self->{nodes}}) {
    print $out $node -> dot_text();
  }
  for my $edge (@{$self->{edges}}) {
    print $out $edge -> dot_text();
  }
  for my $nodes (@{$self->{same_ranks}}) {

    print $out "  {rank=same;";

    for my $node (@$nodes) {
      print $out " $node->{id}";
    }
    print $out "}\n";

  }

# Define the graph label end of your dot file,
# otherwise subgraphs will inherit those properties.
# https://stackoverflow.com/a/4716607/180275
  if ($self->{label}) {
     print $out $self->{label}->dot_text;
  }

  print $out "}\n";

} #_}
sub create { #_{

#_{ POD
=head2 create

    my $graph = GraphViz::Graph->new('my_file');

    # Do stuff...
    $graph->node(…);
  
    # Finally, create the graphviz output:
    # The call to create produces (as per constructor)
    #   - my_file.dot
    #   - my_file.pdf
    $ graph->create('pdf');


=cut
#_}
  my $self     = shift;
  my $filetype = shift;

  croak "unspecified filetype" unless $filetype;

  $self->write_dot();

  my $command = "dot $self->{file_base_name}.dot -T$filetype -o$self->{file_base_name}.$filetype";

  my $rc = system ($command);

  croak "rc = $rc, command=$command" if $rc;

} #_}
sub node_or_port_to_string_ { #_{
#_{ POD
=head2 node_or_port_to_string_

This function is internally used by the constructur (C<new()>) of L<GraphViz::Graph::Edge>.

=cut
#_}

  my $node_or_port = shift;

  if ($node_or_port->isa('GraphViz::Graph::Node')) {
    return $node_or_port->{id};
  }
  unless (ref $node_or_port) {
    # String ???
    return $node_or_port;
  }

  croak "Graph - node_or_port ($node_or_port) neither Node nor string";
} #_}

#_}
#_{ POD: Copyright

=head1 Copyright

Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

#_}
#_{ Testing

=head1 Testing

The tests need L<Test::Files|http://search.cpan.org/search?query=Test%3A%3AFiles&mode=all>.

Since C<GraphViz::Graph> needs C<dot>, the tests are skipped if 

=cut

#_}
#_{ Source Code

=head1 Source Code

The source code is on L<github|https://github.com/ReneNyffenegger/perl-GraphViz-Graph>

=cut

#_}

'tq84'
