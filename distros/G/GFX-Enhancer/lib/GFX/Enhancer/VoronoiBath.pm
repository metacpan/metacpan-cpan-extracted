package GFX::Enhancer::VoronoiBath;

### filter Voronoi baths

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
