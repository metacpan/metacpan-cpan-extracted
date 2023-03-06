package Khonsu::Shape;

use parent 'Khonsu::Ra';

sub add {
	my ($self, $file, %args) = @_;
	my $shape = $file->page->current->gfx;
	$self->shape($file, $shape, %args);
	return $self;
}

1;
