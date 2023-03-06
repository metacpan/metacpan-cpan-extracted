package Khonsu::Text::Subtitle;

use parent 'Khonsu::Text';

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{font}->{size} ||= 25;
	return $self->SUPER::add($file, %attributes);
}

1;
