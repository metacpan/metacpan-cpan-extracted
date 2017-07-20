package GraphViz::Diagram::ClassDiagram::ClassElement;
#_{ use
use warnings;
use strict;

use Carp;

use GraphViz::Diagram::ClassDiagram;
#_}
our $VERSION = $GraphViz::Diagram::ClassDiagram::VERSION;
sub new { #_{

  my $class_parent   = shift; # Either a GraphViz::Diagram::ClassDiagram::Attribute or a GraphViz::Diagram::ClassDiagram::Method
# my $self           = shift;
  my $class          = shift; # The GraphViz::Diagram::ClassDiagram::Class object in which this ClassElement is being defined
  my $ident          = shift;
  my $opts           = shift // {};

  croak "ClassElement - new: passed \$class_parent (= $class_parent) is neither an *::Attribute nor a *::Method" unless 
         $class_parent eq 'GraphViz::Diagram::ClassDiagram::Attribute' or
         $class_parent eq 'GraphViz::Diagram::ClassDiagram::Method';

  croak "ClassElement -new passed attribute \$class (=$class) is not a GraphViz::Diagram::ClassDiagram::Class" unless ref $class eq 'GraphViz::Diagram::ClassDiagram::Class';

  my $self = {};

  $self->{class}     = $class;
  $self->{ident}     = $ident;

  $self->{comment}   = delete $opts->{comment} if exists $opts->{comment};
  $self->{type}      = delete $opts->{type}    if exists $opts->{type};

  bless $self, $class_parent;

  return $self;

} #_}
sub tr { #_{
  my $self      = shift;
  my $first_row = shift;

  my $draw_border_above = 0;

  if (! $first_row) {
    $draw_border_above = 1;
  }

  my $border_etc='';
  if ($draw_border_above) {
    $border_etc = " sides='t'";
  }
  else {
    $border_etc = " border='0'";
  }

  my $color_ident = $self->ident_color();

  my $td_type = "<td align='left'$border_etc>";
  $td_type .= $self->{type} if (exists $self->{type});
  $td_type .= "</td>";

  my $td_ident = "<td align='left'$border_etc port='$self->{ident}'><font color='$color_ident'>$self->{ident}</font></td>";

  my $tr = "<tr>$td_type$td_ident</tr>";

  my $colspan_max = GraphViz::Diagram::ClassDiagram::Class::colspan_();
  if ($self->{comment}) {
    my $color_comment = GraphViz::Diagram::ClassDiagram::color_comment();
    $tr .= "<tr><td border='0' $colspan_max align='left'><font color='$color_comment'>$self->{comment}</font></td></tr>";
  }

  return $tr;
} #_}
sub connector_for_links {#_{
=head2 connector_for_links

Returns a string that can be used in L<GraphViz::Graph> -> C<edge()>.

Must currently (as of version 0.01) be called after C<connector_for_links> was called!

Should not be called by a user, it is called by L<GraphViz::Diagram::ClassDiagram> C<< -> create() >> instead

=cut

  my $self = shift;

  croak "ClassElement - connector_for_links: self->{class} is not set - is Class->add_class_as_node_to_graph already run?" unless $self->{class};
  croak "ClassElement - connector_for_links: $self->{class} is not a GraphViz::Diagram::ClassDiagram::Class" unless ref $self->{class} eq 'GraphViz::Diagram::ClassDiagram::Class';

# return $self->{class}->{class_node}->port($self->{ident});
  return $self->{class}              ->port($self->{ident});

} #_}

'tq84';
