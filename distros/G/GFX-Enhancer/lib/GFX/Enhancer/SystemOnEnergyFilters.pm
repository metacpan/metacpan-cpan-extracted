package GFX::Enhancer::SystemOnEnergyFilters;

### main API class

sub new {
	my ($class, $pngfilename) = @_;

	my $self = { energysys => GFX::Enhancer::SystemOnEnergy->new($pngfilename),
			energyfunctions => GFX::Enhancer::SystemOnEnergyFunctionsArray->new(),
			};

	$class = ref($class) || $class;
	bless $self, $class;
}

### public methods, API methods, construct the class with a PNG image filename
### (see new method above), then call a filter and write out another PNG file

sub antialias_filter {
	my ($self, $pngoutputfilename) = @_;
	my $pngwriter = GFX::Enhancer::PNGWriter->new;

	{

	  ### FIXME
	  ### $self->{energyfunctions}->sharpen_array($self->{energysys});	
	  
	  $pngwriter->write_byte_array($pngoutputfilename);
		
	} unless (not $pngoutputfilename);


}

sub from_bits_to_smooth_colours {
	my ($self, $pngoutputfilename) = @_;
	my $pngwriter = GFX::Enhancer::PNGWriter->new;

	{
	  ### FIXME
	  ### $self->{energyfunctions}->from_bits_to_smooth_colours($self->{energysys});	
	  
	  $pngwriter->write_byte_array($pngoutputfilename);
	
	} unless (not $pngoutputfilename);

}

1;
