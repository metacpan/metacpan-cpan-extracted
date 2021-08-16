package GFX::Enhancer::PencilOnlyImageRepresentation;

use parent 'GFX::Enhancer::ImageRepresentation';

### a repr of an image drawn by a pencil only 

sub new {
	my ($class, $name) = @_;
        my $self = $class->SUPER::new;

        $self->{lines} = (); ### FIXME
}

sub process_points {
	my ($self, $filename, $enhancer) = @_;

	$self->scan_in_points_of_png_image_file($filename);
	$enhancer->process($self);
}

1;
