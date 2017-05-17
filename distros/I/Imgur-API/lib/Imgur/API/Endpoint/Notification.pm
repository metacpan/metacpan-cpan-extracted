package Imgur::API::Endpoint::Notification;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub notifications {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/notification",[],[],\%p),
		'get',
		\%p
	);
}

sub get {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/notification/%s",['notification'],[],\%p),
		'get',
		\%p
	);
}

sub viewed {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/notification/%s",['notification'],[],\%p),
		'put',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

