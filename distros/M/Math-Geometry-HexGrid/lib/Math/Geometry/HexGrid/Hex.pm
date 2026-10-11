package Math::Geometry::HexGrid::Hex;

use 5.014;
use strict;
use warnings;

# Ensure parent module and XS binary are loaded
require Math::Geometry::HexGrid;

our $VERSION = '0.01';

use overload
    '""'     => \&to_string,
    '=='     => \&equals,
    '!='     => sub { !equals(@_) },
    fallback => 1;

sub neighbors {
    my ($self) = @_;
    my @raw = Math::Geometry::HexGrid::hex_neighbors($self->col, $self->row);
    return map { Math::Geometry::HexGrid::Hex->new($_->[0], $_->[1]) } @raw;
}

sub ray_to {
    my ($self, $other, $max_len) = @_;
    $max_len //= 100;
    my @raw = Math::Geometry::HexGrid::hex_collinear_ray($self->col, $self->row, $other->col, $other->row, $max_len);
    return map { Math::Geometry::HexGrid::Hex->new($_->[0], $_->[1]) } @raw;
}

1;

