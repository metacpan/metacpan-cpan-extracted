package Imgur::API::Endpoint::Topic;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub defaults {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/topics/defaults",[],[],\%p),
		'get',
		\%p
	);
}

sub galleryTopic {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/topics/%s",['topic_id'],['sort','page'],\%p),
		'get',
		\%p
	);
}

sub galleryTopicItem {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/topics/%s/%s",['topic_id','item_id'],[],\%p),
		'get',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

