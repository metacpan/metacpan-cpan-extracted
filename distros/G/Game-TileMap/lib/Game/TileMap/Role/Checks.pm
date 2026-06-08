package Game::TileMap::Role::Checks;
$Game::TileMap::Role::Checks::VERSION = '1.001';
use v5.10;
use strict;
use warnings;

use Mooish::Base -stardard, -role;

requires qw(
	get_tile
);

sub check_within_map
{
	my ($self, $x, $y) = @_;

	my $obj = $self->get_tile($x, $y);
	return $obj && !$obj->is_wall;
}

sub check_can_be_accessed
{
	my ($self, $x, $y) = @_;

	my $obj = $self->get_tile($x, $y);
	return $obj && !$obj->is_wall && !$obj->is_void;
}

1;

