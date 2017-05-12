#!/usr/bin/perl
use strict;
use warnings;
use EntityModel;

sub validate {
	my %args = @_;
	my $user;
	Entity::User->find({
		username => $args{username},
		password => $args{password},
	})->first(sub {
		$user = shift;
	})->done(sub { $args{done}->($user) });
}

