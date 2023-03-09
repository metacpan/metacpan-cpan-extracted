package Khonsu::Text::H4;

use parent 'Khonsu::Text';

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{font}->{size} ||= 25;
	$attributes{font}->{line_height} ||= 17;
	$attributes{h} ||= $attributes{font}->{line_height};
	return $self->SUPER::add($file, %attributes);
}

1;
