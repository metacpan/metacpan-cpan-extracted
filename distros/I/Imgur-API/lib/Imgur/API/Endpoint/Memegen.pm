package Imgur::API::Endpoint::Memegen;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub defaults {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/memegen/defaults",[],[],\%p),
		'get',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

