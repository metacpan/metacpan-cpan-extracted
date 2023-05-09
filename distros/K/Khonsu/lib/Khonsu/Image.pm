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
	if (!$attributes{x}) {
		$attributes{x} = $file->page->x;
		$attributes{y} = $file->page->y;
		$attributes{h} = $attributes{h} || $file->page->remaining_height();
		$attributes{w} = $attributes{w} || $file->page->width();
		if ($attributes{y} + $attributes{h} > $file->page->h) {
			$file->page->next();
			$attributes{x} = $file->page->x;
			$attributes{y} = $file->page->y;
		}
	}
	$self->set_attributes(%attributes);
	my $type = $self->_identify_type();
	my $image = $file->pdf->$type($self->image);
	my %points = $self->get_points();
	my $photo = $file->page->current->gfx;
	if ($attributes{align} && $attributes{align} eq 'center') {
		my $single = ($file->page->w - ($file->page->padding * (2 + ($file->page->columns - 1)))) / $file->page->columns;
		$points{x} = (($file->page->padding + $single) * ($file->page->column - 1)) + $file->page->padding + (($single - $points{w}) / 2);
	}
	$photo->image(
		$image,
		$points{x}, $file->page->h - ($points{y} + $points{h}), $points{w}, $points{h}
	);
	$file->page->y($points{y} + $points{h});	
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
