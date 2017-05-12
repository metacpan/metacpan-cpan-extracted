package Geo::JSON::Base;

our $VERSION = '0.007';

use Moo;
with 'Geo::JSON::Role::ToJson';

use Carp;

use Geo::JSON;
use Geo::JSON::Types -types;
use Geo::JSON::Utils;

use Types::Standard -types;

has type => (
    is       => 'ro',
    isa      => Str,
    default  => sub { ( ( ref $_[0] ) =~ m/::(\w+)$/ )[0] },
    required => 1,
);

has crs => ( is => 'ro', isa => Maybe [CRS], coerce => CRS->coercion );

has bbox => ( is => 'rw', isa => Maybe [ ArrayRef [Num] ] );

# used by JSON 'convert_blessed'
sub TO_JSON {
    my $self = $_[0];

    my %output = (
        type => $self->type,
        %{$self},
    );

    # prevent empty 'crs' key
    delete $output{crs}
        unless defined $output{crs};

    return \%output;
}

sub compute_bbox {
    return Geo::JSON::Utils::compute_bbox( shift->all_positions );
}

sub all_positions {
    return shift->coordinates;
}

1;

__END__

=encoding utf-8

=head1 NAME

Geo::JSON::Base - Baseclass for Geo::JSON objects

=head1 DESCRIPTION

Base class for Geojson objects.

See L<Geo::JSON> for more details.

=head1 ATTRIBUTES

=head1 type

Required. Scalar defining the class of Geojson object. One of the following:
Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon,
GeometryCollection, Feature, FeatureCollection.

=head2 crs

Optional L<Geo::JSON::CRS> object to define the Co-ordinates Reference System
used by this object.

=head2 bbox

Optional arrayref representing a bounding box that encloses the points defined
by this Geojson object. See L<Geo::JSON> for more details.

=head1 METHODS

=head2 compute_bbox

Returns arrayref representing a Geojson bounding box that encloses the points
in the object's geometry.

=head2 all_positions

Returns arrayref of all positions (each an arrayref of C<n> dimensions) in the
object's geometry.

=cut

