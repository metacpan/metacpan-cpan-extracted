package Imgur::API::Endpoint::Conversation;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub list {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/conversations",[],[],\%p),
		'get',
		\%p
	);
}

sub get {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/conversations/%s",['conversation'],['page','offset'],\%p),
		'get',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

