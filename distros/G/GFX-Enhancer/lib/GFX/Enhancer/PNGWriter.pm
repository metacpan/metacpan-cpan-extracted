package GFX::Enhancer::PNGWriter;

sub new {
	my ($class, $name) = @_;
        my $self = $class->SUPER::new;

        $self->{filename} = "";
        $self->{bytes} = 0; ### number which stores all bytes of the png image
        $self->{length} = 0;
	$self->{width} = 0;
	$self->{height} = 0;
}

### public methods

sub write_byte_array {
	my $self = shift;
	my $self->{filename} = shift;

	### FIXME png writer code
	#$self->{length} = ;
	#$self->{width} = ;
	#$self->{height} = ;
}

1;
