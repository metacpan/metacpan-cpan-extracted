package Imgur::API::Endpoint::Account;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub get {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s",['username'],[],\%p),
		'get',
		\%p
	);
}

sub galleryFavorites {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/gallery_favorites",['username'],['page','sort'],\%p),
		'get',
		\%p
	);
}

sub favorites {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/favorites",['username'],['page','sort'],\%p),
		'get',
		\%p
	);
}

sub submissions {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/submissions/%s",['username','page'],[],\%p),
		'get',
		\%p
	);
}

sub settings {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/settings",['username'],[],\%p),
		'get',
		\%p
	);
}

sub updateSettings {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("",[],[],\%p),
		'put | post',
		\%p
	);
}

sub profile {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/gallery_profile",['username'],[],\%p),
		'get',
		\%p
	);
}

sub verifyEmail {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/verifyemail",['username'],[],\%p),
		'get',
		\%p
	);
}

sub sendVerifyEmail {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/verifyemail",['username'],[],\%p),
		'post',
		\%p
	);
}

sub albums {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/albums",['username'],['page'],\%p),
		'get',
		\%p
	);
}

sub album {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/album/%s",['username','account'],[],\%p),
		'get',
		\%p
	);
}

sub albumIds {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/albums/ids",['username'],['page'],\%p),
		'get',
		\%p
	);
}

sub albumCount {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/albums/count",['username'],[],\%p),
		'get',
		\%p
	);
}

sub albumDelete {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/album/%s",['username','account'],[],\%p),
		'delete',
		\%p
	);
}

sub comments {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/comments",['username'],['sort','page'],\%p),
		'get',
		\%p
	);
}

sub comment {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/comment/%s",['username','account'],[],\%p),
		'get',
		\%p
	);
}

sub commentIds {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/comments/ids",['username'],['sort','page'],\%p),
		'get',
		\%p
	);
}

sub commentCount {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/comments/count",['username'],[],\%p),
		'',
		\%p
	);
}

sub commentDelete {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/comment/%s",['username','account'],[],\%p),
		'delete',
		\%p
	);
}

sub images {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/images/%s",['username','page'],[],\%p),
		'get',
		\%p
	);
}

sub image {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/image/%s",['username','account'],[],\%p),
		'get',
		\%p
	);
}

sub imageIds {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/images/ids",['username'],['page'],\%p),
		'get',
		\%p
	);
}

sub imageCount {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/images/count",['username'],[],\%p),
		'get',
		\%p
	);
}

sub imageDelete {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/image/%s",['username','deletehash'],[],\%p),
		'delete',
		\%p
	);
}

sub replies {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/account/%s/notifications/replies",['username'],[],\%p),
		'get',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

