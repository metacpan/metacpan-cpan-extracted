package Khonsu::Text::H3;

use parent 'Khonsu::Text';

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{font}->{size} ||= 30;
	$attributes{font}->{line_height} ||= 23;
	$attributes{h} ||= $attributes{font}->{line_height};
	$file->toc->outline($file, 'h3', %attributes) if $attributes{toc};
	return $self->SUPER::add($file, %attributes);
}

1;
