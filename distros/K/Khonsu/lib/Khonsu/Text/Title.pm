package Khonsu::Text::Title;

use parent 'Khonsu::Text';

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{font}->{size} ||= 50;
	return $self->SUPER::add($file, %attributes);
}

1;
