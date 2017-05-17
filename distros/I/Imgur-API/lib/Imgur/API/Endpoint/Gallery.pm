package Imgur::API::Endpoint::Gallery;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub get {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery",[],['section','sort','page'],\%p),
		'get',
		\%p
	);
}

sub memeSubgallery {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/g/memes",[],['sort','page'],\%p),
		'get',
		\%p
	);
}

sub memeSubgalleryImage {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/g/memes/%s",['image_id'],[],\%p),
		'get',
		\%p
	);
}

sub subreddit {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/r/%s",['subreddit'],['sort','page'],\%p),
		'get',
		\%p
	);
}

sub subredditImage {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/r/%s/%s",['subreddit','image_id'],[],\%p),
		'get',
		\%p
	);
}

sub tag {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/t/%s",['t_name'],['sort','page'],\%p),
		'get',
		\%p
	);
}

sub tagImage {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/t/%s/%s",['t_name','image_id'],[],\%p),
		'get',
		\%p
	);
}

sub itemTags {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/image/%s/tags",['gallery'],[],\%p),
		'get',
		\%p
	);
}

sub tagVote {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s/vote/tag/%s/%s",['gallery','t_name','vote'],[],\%p),
		'post',
		\%p
	);
}

sub updateGalleryTags {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/tags/%s",['gallery'],[],\%p),
		'post',
		\%p
	);
}

sub search {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/search",[],['sort','window','page'],\%p),
		'get',
		\%p
	);
}

sub random {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/random/random",[],['page'],\%p),
		'get',
		\%p
	);
}

sub toGallery {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s",['gallery'],[],\%p),
		'post | put',
		\%p
	);
}

sub fromGallery {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s",['gallery'],[],\%p),
		'delete',
		\%p
	);
}

sub album {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/album/%s",['gallery'],[],\%p),
		'get',
		\%p
	);
}

sub image {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/image/%s",['gallery'],[],\%p),
		'get',
		\%p
	);
}

sub reporting {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("",[],[],\%p),
		'post',
		\%p
	);
}

sub votes {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s/votes",['gallery'],[],\%p),
		'get',
		\%p
	);
}

sub voting {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s/vote/%s",['gallery','vote'],[],\%p),
		'post',
		\%p
	);
}

sub comments {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s/comments",['gallery'],['sort'],\%p),
		'get',
		\%p
	);
}

sub comment {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s/comment/%s",['gallery','comment'],[],\%p),
		'get',
		\%p
	);
}

sub commentCreation {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s/comment",['gallery'],[],\%p),
		'post',
		\%p
	);
}

sub commentReply {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s/comment/%s",['gallery','commentReply'],[],\%p),
		'post',
		\%p
	);
}

sub commentIds {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s/comments/ids",['gallery'],[],\%p),
		'get',
		\%p
	);
}

sub commentCount {
	my ($this,%p) = @_;

	return $this->dispatcher->request(
		$this->path("3/gallery/%s/comments/count",['gallery'],[],\%p),
		'get',
		\%p
	);
}



1;
__PACKAGE__->meta->make_immutable;

