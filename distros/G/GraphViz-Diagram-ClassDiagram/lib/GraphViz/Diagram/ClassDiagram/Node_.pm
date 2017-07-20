package GraphViz::Diagram::ClassDiagram::Node_;
#_{ use
use warnings;
use strict;

use Carp;
use GraphViz::Diagram::ClassDiagram;
use GraphViz::Graph::Node;

our @ISA=qw(GraphViz::Graph::Node);
our $VERSION=$GraphViz::Diagram::ClassDiagram::VERSION;

#_{ POD
=encoding utf8
=head1 NAME

GraphViz::Diagram::ClassDiagram::Node_ is a base class for all class diagram objects that are rendered in graphviz as a C<GraphViz::Graph::Node>,
such as L<GraphViz::Graph::GlobalVar> or L<GraphViz::Graph::Class>.

=cut
=head1 USAGE

This class should not be used by a user of C<GraphViz::Diagram::ClassDiagram>.

At the time of this writing, there are two classes that derive from GraphViz::Diagram::ClassDiagram::Node_:
L<GraphViz::Diagram::ClassDiagram::Class> and L<GraphViz::Diagram::ClassDiagram::GlobalVar>.

=cut

#_}

sub new {

#_{ POD
=head2 new

Creates a C<GraphViz::Diagram::ClassDiagram::Node_>.

=cut
#_}

  my $class          = shift;
  my $name           = shift;
  my $class_diagram  = shift; # The class diagram on which this class should be drawn

  croak "GraphViz::Diagram::ClassDiagram::Node_ - new: class_diagram $class_diagram is not a GraphViz::Diagram::ClassDiagram" unless $class_diagram->isa('GraphViz::Diagram::ClassDiagram');

  my $self = $class_diagram->node();

  $self->{name}           = $name;
  $self->{class_diagram } = $class_diagram;

  $self->{comments      } = [];

  bless $self, $class;

  return $self;

}

'tq84'
