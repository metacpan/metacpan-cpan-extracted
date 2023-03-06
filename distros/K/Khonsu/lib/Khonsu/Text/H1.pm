package Khonsu::Text::H1;

use parent 'Khonsu::Text';

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{font}->{size} ||= 50;
	$attributes{font}->{line_height} ||= 30; 
	$attributes{h} ||= %attributes{font}->{line_height};
	return $self->SUPER::add($file, %attributes);
}

1;
