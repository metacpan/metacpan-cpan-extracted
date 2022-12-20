package Game::TileMap::Role::Helpers;
$Game::TileMap::Role::Helpers::VERSION = '1.000';
use v5.10;
use strict;
use warnings;

use Moo::Role;

requires qw(
	legend
	_guide
);

sub get_all_of_class
{
	my ($self, $class) = @_;

	return @{$self->_guide->{$class}};
}

sub get_all_of_type
{
	my ($self, $obj) = @_;

	my $class = $self->legend->get_class_of_object($obj);
	my @all_of_class = $self->get_all_of_class($class);

	return grep { $_->type eq $obj } @all_of_class;
}

sub get_class_of_object
{
	my ($self, $obj) = @_;

	return $self->legend->get_class_of_object(ref $obj ? $obj->type : $obj);
}

1;

