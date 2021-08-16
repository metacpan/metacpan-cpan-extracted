package GFX::Enhancer::FilterMain;

### Main compiler pattern class for all filter methods

sub new {
	my ($class, $pngfilename) = @_;

	my $self = { 
		singlelineenhancer => GFX::Enhancer::SingleLineEnhancer->new, 
		singlelineantialias => GFX::Enhancer::SingleLineAntialias->new, 

	};

	$class = ref($class) || $class;

	bless $self, $class;
}

### make scanned in images with pencil lines, a hard line
sub filter_antialiased_single_line {
	my ($self) = @_;

	my $imgrepr = ImageRepresentation->new;
	$imgrepr->scan_in_points_of_png_image_file($self->{filename});

	$self->{singlelineantialias}->filter($imgrepr, $imgrepr->{points});
}

### FIXME TODO make scanned in images with pencil lines, a hard line
sub filter_single_line {
	my ($self) = @_;

	my $imgrepr = ImageRepresentation->new;
	$imgrepr->scan_in_points_of_png_image_file($self->{filename});

	$self->{singlelineenhancer}->filter($imgrepr);
}

1;
