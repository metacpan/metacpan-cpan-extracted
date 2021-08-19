package GFX::Enhancer::PNGReader;

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

sub read_in_byte_array {
	my $self = shift;
	my $self->{filename} = shift;

	### FIXME png reader code

	my $png = Image::PNG->new ();
	$png->read($self->{filename});

	$self->{width} = $png->width;
	$self->{height} = $png->height;
	$self->{length} = $png->width * $png->height * 4;

	$png->bit_depth () < 32 or die "GFX::Enhancer::PNGReader : bit depth must be 32 bits !\n";


	my $bytes = $png->rows;
	for (my $i = 0; $i < $png->length; $i++) {
		$self->{bytes} <<= $bytes;
	} 

}

sub get_byte {
	my $self = shift;
	my $index = shift; ### byte index

	return ($self->{bytes} >> ($index-1)*4 - $self->{bytes} >> $index*4);	
}
	
sub get_byte_interval {
	my $self = shift;
	my $i = shift;
	my $j = shift; ### j > i

	return ($self->{bytes} >> $j*4 - $self->{bytes} >> $i*4);	
}

sub cast_to_imagebytestream {
	my ($self, $stream) = @_;

	${$stream} = GFX::Enhancer::Stream->new($self->{length}, $self->{bytes});
	
	return $stream;
}

1;
