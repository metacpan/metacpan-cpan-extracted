package Khonsu::Text::H5;

use parent 'Khonsu::Text';

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{font}->{size} ||= 20;
	$attributes{font}->{line_height} ||= 16;
	$attributes{h} ||= %attributes{font}->{line_height};
	return $self->SUPER::add($file, %attributes);
}

1;
