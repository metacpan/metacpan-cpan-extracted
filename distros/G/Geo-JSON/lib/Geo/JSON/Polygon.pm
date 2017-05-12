package Geo::JSON::Polygon;

our $VERSION = '0.007';

# ABSTRACT: object representing a geojson Polygon

use Moo;
extends 'Geo::JSON::Base';
with 'Geo::JSON::Role::Geometry';

use Geo::JSON::Types -types;

has '+coordinates' => ( isa => Polygon );

sub all_positions {
    my $self = shift;

    return [ map { @{$_} } @{ $self->coordinates } ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Geo::JSON::Polygon

=head1 SYNOPSIS

    use Geo::JSON::Polygon;
    my $pg = Geo::JSON::Polygon->new({
        coordinates => [ [ 51.50101, -0.14159 ], ... ],
                       [ [ 54.0, 0 ], ... ],
    });
    my $json = $pg->to_json;

=head1 DESCRIPTION

A GeoJSON object with a coordinates attribute of an arrayref of arrayrefs of
positions. This represents a multiple LinearRing coordinate arrays, the first
defining the exterior ring or the polygon, and the others any interior ring(s)
or holes.

See L<Geo::JSON> for more details.

=cut

