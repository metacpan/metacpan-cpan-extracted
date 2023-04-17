package Khonsu::Text::H5;

use parent 'Khonsu::Text';

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{font}->{size} ||= 20;
	$attributes{font}->{line_height} ||= 16;
	$attributes{h} ||= $attributes{font}->{line_height};
	$file->toc->outline($file, 'h5', %attributes) if $attributes{toc};
	return $self->SUPER::add($file, %attributes);
}

1;
