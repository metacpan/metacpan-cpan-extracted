package Geo::JSON::Types;

our $VERSION = '0.007';

use strict;
use warnings;

BEGIN {
    use Type::Library -base, -declare => qw/
        CRS
        Feature
        Features
        Geometry
        LinearRing
        LineString
        LineStrings
        Polygon
        Polygons
        Position
        Positions
        /;
    use Type::Utils;
    use Types::Standard -types;

    use Geo::JSON::Utils qw/ compare_positions /;

    declare Position,    #
        as ArrayRef [Num],    #
        where { @{$_} >= 2 };

    declare Positions,        #
        as ArrayRef [Position],    #
        where { @{$_} > 0 };

    declare LineString,            #
        as Positions,              #
        where { @{$_} >= 2 };

    declare LineStrings,           #
        as ArrayRef [LineString];

    declare LinearRing,            #
        as LineString,             #
        where { @{$_} >= 4 && compare_positions( $_->[0], $_->[-1] ) };

    declare Polygon,               #
        as ArrayRef [LinearRing];

    declare Polygons,              #
        as ArrayRef [Polygon];

    declare Geometry, as Object, where { $_->does("Geo::JSON::Role::Geometry") };

    class_type CRS,      { class => 'Geo::JSON::CRS' };
    class_type Feature,  { class => 'Geo::JSON::Feature' };

    coerce CRS, from HashRef, q{ 'Geo::JSON::CRS'->new($_) };

    coerce Feature, from HashRef, q{ 'Geo::JSON'->load( $_ ) };

    coerce Geometry, from HashRef, q{ 'Geo::JSON'->load( $_ ) };

    declare Features, as ArrayRef [Feature], coercion => 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Geo::JSON::Types - Type::Tiny data types for Geo::JSON classes

=head1 SYNOPSIS

    use Geo::JSON::Types -types;

    has crs          => ( is => 'ro', isa => CRS );
    has feature      => ( is => 'ro', isa => Feature );
    has features     => ( is => 'ro', isa => Features );
    has geometry     => ( is => 'ro', isa => Geometry );
    has linear_ring  => ( is => 'ro', isa => LinearRing );
    has line_string  => ( is => 'ro', isa => LineString );
    has line_strings => ( is => 'ro', isa => LineStrings );
    has polygon      => ( is => 'ro', isa => Polygon );
    has polygons     => ( is => 'ro', isa => Polygons );
    has position     => ( is => 'ro', isa => Position );
    has positions    => ( is => 'ro', isa => Positions );

=head1 DESCRIPTION

L<Type::Tiny> data types to represent the types used by L<Geo::JSON>
objects, the types are listed below.

See L<Geo::JSON> for more details.

=head1 TYPES EXPORTED

=over

=item *

CRS

=item *

Feature

=item *

Features

=item *

Geometry

=item *

Position

=item *

Positions

=item *

LineString

=item *

LineStrings

=item *

LinearRing

=item *

Polygon

=item *

Polygons

=back

=cut

