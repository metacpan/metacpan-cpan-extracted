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

Version 0.02

=cut

our $VERSION = '0.02';
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

Start a graph. C<'FileNameBase'> is the base name for the produced dot and png/pdf/svg… etc. output file.
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

  $self->{nodes} = [];
  $self->{edges} = [];

  bless $self, $class;
  return $self;

} #_}
sub label { #_{
#_{ POD
=head2 label

    GraphViz::Graph->label({text => 'Graph Title'}');
    GraphViz::Graph->label({html => '<font point-size="20">Say <font face="Courier">Hello World</font></font>'}');

Add a label to a graph. Most probably used as a title.

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

Add a node to a graph

=cut
 #_}
  my $self = shift;
  my $opts = shift;


  my $node = GraphViz::Graph::Node -> new($opts);

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

# Define the graph label end of your dot file,
# otherwise subgraphs will inherit those properties.
# https://stackoverflow.com/a/4716607/180275
  if ($self->{label}) {
     print $out $self->{label}->dot_text;
  }

  print $out "}\n";

} #_}
sub create { #_{

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

  if (ref $node_or_port eq 'GraphViz::Graph::Node') {
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

=cut

#_}
'tq84'
