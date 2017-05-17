package Imgur::API::Endpoint::Image;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub get {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/image/%s",['image'],[],\%p),
		'get',
		\%p
	);
}

sub upload {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/image",[],[],\%p),
		'post',
		\%p
	);
}

sub delete {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/image/%s",['image'],[],\%p),
		'delete',
		\%p
	);
}

sub update {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/image/%s",['image'],[],\%p),
		'post',
		\%p
	);
}

sub favorite {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/image/%s/favorite",['image'],[],\%p),
		'post',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

