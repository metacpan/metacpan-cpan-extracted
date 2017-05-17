package Imgur::API::Endpoint::Custom_gallery;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub customGallery {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/g/custom",[],['sort','page'],\%p),
		'get',
		\%p
	);
}

sub customGalleryImage {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/g/custom/%s",['item_id'],[],\%p),
		'get',
		\%p
	);
}

sub customGalleryAdd {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/g/custom/add_tags",[],[],\%p),
		'put',
		\%p
	);
}

sub customGalleryRemove {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/g/custom/remove_tags",[],[],\%p),
		'delete',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

