package GFX::Enhancer::SystemOnEnergyFunctionsArray;

use parent 'GFX::Enhancer::SystemOnEnergyFunctions';

sub new {
	my ($class, $name) = @_;
        my $self = $class->SUPER::new;

}

### public methods, use Vectors of colours e.g. RedVector, AlphaVector

sub focus_objects {
	my ($self) = @_;


	### FIXME draw a rectangle around each object in the image (png file)
}

sub sharpen_array {
	my ($self, $energysys) = @_;

	my $energystream = $energysys->{energystream};

	### FIXME adapt array to sharpen picture		
}

1;
