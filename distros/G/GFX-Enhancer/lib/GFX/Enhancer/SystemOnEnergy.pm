package GFX::Enhancer::SystemOnEnergy;

sub new {
	my ($class, $pngfilename) = @_;

        my $self = {
			filename => $pngfilename, 
			### number of rows and columns
			width => 0, height => 0, 
			### main data
			length => 0, index => 0, energystream => undef, bytestream => undef}; 

	### init PNG file bytes
	$reader = GFX::Enhancer::PNGReader->new("");
	$reader->read_in_byte_array($filename);

	$self->{width} = $reader->{width};
	$self->{height} = $reader->{height};

	my $s;
	$self->{bytestream} = \$s;
	$reader->cast_to_imagebytestream($self->{bytestream});

	### init energy floats
	my @fls;
	for (my $i = 0; $i < $reader->{length}; $i++) {
		### read in colours (RGBA values) into floats list
		push (@{fls}, $self->{bytestream}->next);
	}

	my $self->{length} = $reader->{length};
	$self->{energystream} = GFX::Enhancer::EnergyStream($self->{length}, @fls);	

	$class = ref($class) || $class;
	bless $self, $class;
}

### public methods

### NOTE using image representation class !
sub cast_to_imagerepr {
	### reference repr
	my ($self, $inputpngfilename, $repr) = @_;

	${$repr} = GFX::Enhancer::ImageRepresentation->new;	
	${$repr}->scan_in_points_of_png_image_file($inputpngfilename);
}

sub reform_imagerepr_to_this {
	my ($self, $repr) = @_;

	for (my $i = 0; $i < $repr->{width} * $repr->{height}; $i++) {
		$self->{energystream}->edit(${$repr}->{points}[$i]->{rgba}, $i);
	}

	### FIXME read something into the bytestream	
}

sub get_energy_colour_with_index {
	my ($self, $index) = @_;
	
	return $self->{energystream}->{listoffloats}[$index];
}

sub set_energy_colour_with_index {
	my ($self, $value, $index) = @_;

	$self->{energystream}->edit($value, $index);
}


1;
