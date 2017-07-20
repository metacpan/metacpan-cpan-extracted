package GraphViz::Diagram::ClassDiagram::Attribute;
#_{ use
use Carp;
use GraphViz::Diagram::ClassDiagram;
use GraphViz::Diagram::ClassDiagram::ClassElement;
#_}
our @ISA = qw(GraphViz::Diagram::ClassDiagram::ClassElement);

our $VERSION = $GraphViz::Diagram::ClassDiagram::VERSION;
#_{ POD: Methods
=head1 Methods

=cut
#_}
sub new { #_{

#_{ POD
=head2 new

=cut
#_}

  my $class_myself = shift;
  my $class        = shift;
  my $ident        = shift;
  my $opts         = shift;

  croak "Attribute - new: passed \$class_myself (= ref:" . (ref $class_myself) . "  >$class_myself< is neither an *::Attribute nor a *::Method" unless 
         $class_myself eq 'GraphViz::Diagram::ClassDiagram::Attribute' or
         $class_myself eq 'GraphViz::Diagram::ClassDiagram::Method';

  croak "Attribute - new: passed attribute \$class (=$class) is not a GraphViz::Class" unless ref $class eq 'GraphViz::Diagram::ClassDiagram::Class';

  my $self = $class_myself->SUPER::new($class, $ident, $opts);

# bless $self, $class;

# $class_myself->SUPER::new($self, $class, $ident, $opts);
  

  return $self;

} #_}
sub ident_color { #_{
#_{ POD
=head2 ident_color

Static method. Returns the color for an I<identifier>.

Compare with L<GraphViz::Diagram::ClassDiagram/color_comment>

=cut
#_}
  return '#3318cd';
} #_}

'tq84';
