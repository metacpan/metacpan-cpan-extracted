package Geo::JSON::LineString;

our $VERSION = '0.007';

use Moo;
extends 'Geo::JSON::Base';
with 'Geo::JSON::Role::Geometry';

use Geo::JSON::Types -types;

has '+coordinates' => ( isa => LineString );

1;

__END__

=encoding utf-8

=head1 NAME

Geo::JSON::LineString - object representing a geojson LineString

=head1 SYNOPSIS

    use Geo::JSON::LineString;
    my $ls = Geo::JSON::LineString->new({
        coordinates => [ [ 51.50101, -0.14159 ], ... ],
    });
    my $json = $ls->to_json;

=head1 DESCRIPTION

A GeoJSON object with a coordinates attribute of an arrayref of
positions.

See L<Geo::JSON> for more details.

=cut

