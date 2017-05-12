package Geo::JSON::MultiPolygon;

our $VERSION = '0.007';

# ABSTRACT: object representing a geojson MultiPolygon

use Moo;
extends 'Geo::JSON::Base';
with 'Geo::JSON::Role::Geometry';

use Geo::JSON::Types -types;

has '+coordinates' => ( isa => Polygons );

sub all_positions {
    my $self = shift;

    return [
        map { @{$_} }
        map { @{$_} } @{ $self->coordinates }
    ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Geo::JSON::MultiPolygon

=head1 SYNOPSIS

    use Geo::JSON::MultiPolygon;
    my $mpol = Geo::JSON::MultiPolygon->new({
        coordinates => [
            [   [...],     # outer linear ring
                [...], ... # inner linear ring(s)
            ],
            [...],
            ],
        },
    });
    my $json = $mpol->to_json;

=head1 DESCRIPTION

A GeoJSON object with a coordinates of an arrayref of polygon coordinates.

See L<Geo::JSON> for more details.

=cut

