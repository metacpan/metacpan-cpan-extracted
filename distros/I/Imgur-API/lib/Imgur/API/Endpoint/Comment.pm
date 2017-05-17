package Imgur::API::Endpoint::Comment;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub get {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/comment/%s",['comment'],[],\%p),
		'get',
		\%p
	);
}

sub create {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/comment",[],[],\%p),
		'post',
		\%p
	);
}

sub delete {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/comment/%s",['comment'],[],\%p),
		'delete',
		\%p
	);
}

sub replies {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/comment/%s/replies",['comment'],[],\%p),
		'get',
		\%p
	);
}

sub replyCreate {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/comment/%s",['comment'],[],\%p),
		'post',
		\%p
	);
}

sub vote {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/comment/%s/vote/%s",['comment','vote'],[],\%p),
		'post',
		\%p
	);
}

sub report {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/comment/%s/report",['comment'],[],\%p),
		'post',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

