package Game::TileMap::Role::Checks;
$Game::TileMap::Role::Checks::VERSION = '1.000';
use v5.10;
use strict;
use warnings;

use Moo::Role;

requires qw(
	coordinates
);

sub check_within_map
{
	my ($self, $x, $y) = @_;

	return !!0 if $x < 0 || $y < 0;

	my $obj = $self->coordinates->[$x][$y];
	return $obj && !$obj->is_wall;
}

sub check_can_be_accessed
{
	my ($self, $x, $y) = @_;

	return !!0 if $x < 0 || $y < 0;

	my $obj = $self->coordinates->[$x][$y];
	return $obj && !$obj->is_wall && !$obj->is_void;
}

1;

