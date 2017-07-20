package GraphViz::Diagram::ClassDiagram::Method;
use GraphViz::Diagram::ClassDiagram::ClassElement;

our @ISA = qw(GraphViz::Diagram::ClassDiagram::ClassElement);
our $VERSION = $GraphViz::Diagram::ClassDiagram::VERSION;

sub new { #_{
  my $class_myself = shift;
  my $class        = shift;
  my $ident        = shift;
  my $opts         = shift;

# my $self = {};

  croak unless ref $class eq 'GraphViz::Class';

  $opts->{type} = delete $opts->{returns} if exists $opts->{returns};
# $class_myself->SUPER::new($self, $class, $ident, $opts);

  my $self = $class_myself->SUPER::new($class, $ident, $opts);
  
# bless $self, $class_myself;

  return $self;

} #_}
sub ident_color { #_{
  return '#b08f25';
} #_}

'tq84';
