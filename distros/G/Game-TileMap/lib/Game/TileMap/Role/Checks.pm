package Game::TileMap::Role::Checks;
$Game::TileMap::Role::Checks::VERSION = '0.001';
use v5.10;
use strict;
use warnings;

use Moo::Role;
use Mooish::AttributeBuilder -standard;

use Game::TileMap::Legend;

requires qw(
	coordinates
);

sub check_within_map
{
	my ($self, $x, $y) = @_;

	return !!0 if $x < 0 || $y < 0;

	my $obj = $self->coordinates->[$x][$y];
	return $obj && $obj->contents ne Game::TileMap::Legend::WALL_OBJECT;
}

sub check_can_be_accessed
{
	my ($self, $x, $y) = @_;

	return !!0 if $x < 0 || $y < 0;

	my $obj = $self->coordinates->[$x][$y];
	return $obj && $obj->contents;
}

1;

