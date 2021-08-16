package GFX::Enhancer::ImageRepresentation;

### a repr of an image so that is manipulatable 

sub new {
	my ($class) = @_;

	my $self = { width => 0, height => 0, points => (), }; ### points are PNGRGBAs 
					### they have colour other than white

	$class = ref($class) || $class;

	bless $self, $class;
}

### public methods

sub scan_in_points_of_png_image_file {
### points have a colour
	my ($self, $filename) = @_;

	my $reader = GFX::Enhancer::PNGReader->new;
	$reader->read_in_byte_array($filename);

	$self->{width} = $reader->{width};	
	$self->{height} = $reader->{height};	
	
	for (my $i = 0; $i < $reader->{length}; $i+=4) {
		my $rgba = GFX::Enhancer::PNGRGBA->new($i, $reader->get_byte_interval($i, $i+4)); ### NOTE: ctor takes index here
		if (($rgba->red | $rgba->green | $rgba->blue) > 0) {
			push(@{$self->{points}}, $rgba);
		}
	}  
		 
}	
	
### private methods

sub scan_in_image {
	my ($self) = @_;

}

1;
