package Geo::JSON::Point;

our $VERSION = '0.007';

# ABSTRACT: object representing a geojson Point

use Moo;
extends 'Geo::JSON::Base';
with 'Geo::JSON::Role::Geometry';

use Carp;

use Geo::JSON::Types -types;

has '+coordinates' => ( isa => Position );

before compute_bbox => sub {
    croak "Can't compute_bbox with a single position";
};

sub all_positions { [ shift->coordinates ] }

1;

__END__

=encoding utf-8

=head1 NAME

Geo::JSON::Point

=head1 SYNOPSIS

    use Geo::JSON::Point;
    my $pt = Geo::JSON::Point->new({
        coordinates => [ 51.50101, -0.14159 ],
    });
    my $json = $pt->to_json;

=head1 DESCRIPTION

A GeoJSON object with a coordinates attribute of a single position.

See L<Geo::JSON> for more details.

=cut

