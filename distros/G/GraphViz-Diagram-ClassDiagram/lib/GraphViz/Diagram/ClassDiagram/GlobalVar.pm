package GraphViz::Diagram::ClassDiagram::GlobalVar;
#_{ use
use warnings;
use strict;
use Carp;
#_}
use GraphViz::Diagram::ClassDiagram::Node_;

our $VERSION = $GraphViz::Diagram::ClassDiagram::VERSION;
our @ISA = qw(GraphViz::Diagram::ClassDiagram::Node_);
#_{ POD: Methods
=head1 METHODS

=cut
#_}
sub new { #_{
#_{ POD
=head2 new

Creates an instance for a C<GlobalVar>. Should (as of now) not be called by the user.
It's called by L<GraphViz::Diagram::ClassDiagram/global_var> instead.

=cut
#_}

  my $class          = shift;
  my $class_name     = shift;
  my $class_diagram  = shift; # The class diagram on which this class should be drawn

# my $opts           = shift // {};

  croak "GlobalVar - new, class=$class instead GraphViz::Diagram::ClassDiagram::GlobalVar"         unless     $class eq 'GraphViz::Diagram::ClassDiagram::GlobalVar';
  croak "GlobalVar - new, class_name=$class_name instead of a string"                     if     ref $class_name;
  croak "GlobalVar - new, class_diagram=$class_diagram instead of GraphViz::Diagram::ClassDiagram" unless ref $class_diagram eq 'GraphViz::Diagram::ClassDiagram';

  my $self = $class->GraphViz::Diagram::ClassDiagram::Node_::new($class_name, $class_diagram);

  return $self;


} #_}
sub class { #{
#_{ POD
=head2 class

    my $class_diagram = GraphViz::Diagram::ClassDiagram->new('foo.png');

    my $CFoo  = $class_diagram->class     ('CFoo' );
    my $g_foo = $class_diagram->global_var('g_foo')

    $g_foo->class($CFoo);

    $class_diagram->create();


Specify the class of the GlobalVar.

=cut
#_}

  my $self  = shift;
  my $class = shift;

  croak "GraphViz::Diagram::ClassDiagram::GlobalVar - class: $class is not a GraphViz::Diagram::ClassDiagram::Class" unless $class->isa('GraphViz::Diagram::ClassDiagram::Class');

  my $edge = $self->{class_diagram}->edge($self, $class);
  $edge->arrow_end('none');

} #}
sub render {
#_{ POD
=head2 render

Renders the html for the GlobalVar. Should not be called by the user, it's called
by L<GraphViz::Diagram::ClassDiagram/create>.

=cut
#_}

  my $self = shift;

  $self->label({html=>
      "<font face='Courier' color='#e73915'>$self->{name}</font>"
    }
  );
}

'tq84';
