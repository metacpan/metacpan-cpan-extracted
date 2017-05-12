package Geo::JSON::MultiLineString;

our $VERSION = '0.007';

# ABSTRACT: object representing a geojson MultiLineString

use Moo;
extends 'Geo::JSON::Base';
with 'Geo::JSON::Role::Geometry';

use Geo::JSON::Types -types;

has '+coordinates' => ( isa => LineStrings );

sub all_positions {
    my $self = shift;

    return [ map { @{$_} } @{ $self->coordinates } ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Geo::JSON::MultiLineString

=head1 SYNOPSIS

    use Geo::JSON::MultiLineString;
    my $mls = Geo::JSON::MultiLineString->new({
        coordinates => [ [ 51.50101, -0.14159 ], ... ],
                       [ [ 54.0, 0 ], ... ],
    });
    my $json = $mls->to_json;

=head1 DESCRIPTION

A GeoJSON object with a coordinates attribute of an arrayref of
arrayrefs of positions.

See L<Geo::JSON> for more details.

=cut

