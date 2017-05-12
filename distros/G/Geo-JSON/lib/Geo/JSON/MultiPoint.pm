package Geo::JSON::MultiPoint;

our $VERSION = '0.007';

# ABSTRACT: object representing a geojson MultiPoint

use Moo;
extends 'Geo::JSON::Base';
with 'Geo::JSON::Role::Geometry';

use Geo::JSON::Types -types;

has '+coordinates' => ( isa => Positions );

1;

__END__

=encoding utf-8

=head1 NAME

Geo::JSON::MultiPoint

=head1 SYNOPSIS

    use Geo::JSON::MultiPoint;
    my $mpt = Geo::JSON::MultiPoint->new({
        coordinates => [ [ 51.50101, -0.14159 ],
                         [ 57.596278, -13.687306 ],
                       ],
    });
    my $json = $mpt->to_json;

=head1 DESCRIPTION

A GeoJSON object with a coordinates attribute consisting of an arrayref of
positions.

See L<Geo::JSON> for more details.

=cut

