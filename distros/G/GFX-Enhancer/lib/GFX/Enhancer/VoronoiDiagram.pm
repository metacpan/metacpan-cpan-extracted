package GFX::Enhancer::VoronoiDiagram;

### filter Voronoi diagram

sub new {
	my ($class) = @_;

	my $self = {};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub filter {
	my ($self, $imgrepr) = @_; 

}

1;
