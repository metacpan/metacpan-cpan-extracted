package Khonsu::Image;

use parent 'Khonsu::Ra';

sub attributes {
	my $a = shift;
	return (
		image => {$a->RW},
		mime => {$a->RW, $a->STR}, 
		valid_mime => {$a->RW, $a->HR, default => sub {{
			jpeg => 'image_jpeg',
			tiff => 'image_tiff',
			pnm => 'image_pnm',
			png => 'image_png',
			gif => 'image_gif'
		}}},
		$a->POINTS
	);
}

sub add {
	my ($self, $file, %attributes) = @_;
	$self->set_attributes(%attributes);
	my $type = $self->_identify_type();
	my $image = $file->pdf->$type($self->image);
	my %points = $self->get_points();
	my $photo = $file->page->current->gfx;
	$photo->image(
		$image,
		$points{x}, $points{y}, $points{w}, $points{h}
	);
	return $file;
}

sub _identify_type {
	my ($self) = @_;
	if (!$self->mime && !ref $self->image) {
		my $reg = sprintf '\.(%s)$', join ("|", keys %{$self->valid_mime});
		$self->image =~ m/$reg/;
		my $m = $1;
		$self->mime($m || 'png');
	}
	return $self->valid_mime->{$self->mime};
}

1;
