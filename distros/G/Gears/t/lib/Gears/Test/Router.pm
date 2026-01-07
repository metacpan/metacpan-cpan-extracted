package Gears::Test::Router;

use v5.40;
use Mooish::Base -standard;

use Gears qw(load_component);

extends 'Gears::Router';

has param 'location_impl' => (
	isa => Str,
);

sub _build_location ($self, %args)
{
	return load_component($self->location_impl)->new(%args);
}

