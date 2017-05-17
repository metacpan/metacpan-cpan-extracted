package Imgur::API::Endpoint::Album;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub get {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album/%s",['album'],[],\%p),
		'get',
		\%p
	);
}

sub images {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album/%s/images",['album'],[],\%p),
		'get',
		\%p
	);
}

sub image {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album/%s/image/%s",['album','image'],[],\%p),
		'get',
		\%p
	);
}

sub upload {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album",[],[],\%p),
		'post',
		\%p
	);
}

sub update {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album/%s",['album'],[],\%p),
		'put',
		\%p
	);
}

sub delete {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album/%s",['album'],[],\%p),
		'delete',
		\%p
	);
}

sub favorite {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album/%s/favorite",['album'],[],\%p),
		'post',
		\%p
	);
}

sub setTo {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album/%s",['album'],[],\%p),
		'post',
		\%p
	);
}

sub addTo {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album/%s/add",['album'],[],\%p),
		'put',
		\%p
	);
}

sub removeFrom {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/album/%s/remove_images",['album'],[],\%p),
		'delete',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

