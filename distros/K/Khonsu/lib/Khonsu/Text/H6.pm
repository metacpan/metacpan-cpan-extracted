package Khonsu::Text::H6;

use parent 'Khonsu::Text';

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{font}->{size} ||= 15;
	$attributes{font}->{line_height} ||= 13;
	$attributes{h} ||= %attributes{font}->{line_height};	
	return $self->SUPER::add($file, %attributes);
}

1;
