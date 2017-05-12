package Google::Directions::Types;
=head1 NAME

Google::Directions::Types

=head1 DESCRIPTION

Types used in Google::Directions modules

=cut

use MooseX::Types::Moose -all;
use MooseX::Types -declare => [qw(
    ArrayRefOfLegs
    ArrayRefOfPoints
    ArrayRefOfRoutes
    ArrayRefOfSteps
    BoundsClass
    CoordinatesClass
    LegClass
    PolylineClass
    RouteClass
    StatusCode
    StepClass
    TravelMode
    ValueFromHashRef
)]; 


# Bounds
class_type BoundsClass,      { class => 'Google::Directions::Response::Bounds' };

coerce BoundsClass,
    from HashRef,
    via { Google::Directions::Response::Bounds->new( %{ $_ } ) };

# Coordinates
class_type CoordinatesClass, { class => 'Google::Directions::Response::Coordinates' };

coerce CoordinatesClass,
    from HashRef,
    via { Google::Directions::Response::Coordinates->new( %{ $_ } ) };


# Polyline
class_type PolylineClass,    { class => 'Google::Directions::Response::Polyline' };

coerce PolylineClass,
    from HashRef,
    via { Google::Directions::Response::Polyline->new( %{ $_ } ) };

# Route
class_type RouteClass,       { class => 'Google::Directions::Response::Route' };

# Step
class_type StepClass,        { class => 'Google::Directions::Response::Step' };

# Leg
class_type LegClass,         { class => 'Google::Directions::Response::Leg' };

# Valid status codes
enum StatusCode, [ qw/OK NOT_FOUND ZERO_RESULTS MAX_WAYPOINTS_EXCEEDED INVALID_REQUEST
                    OVER_QUERY_LIMIT REQUEST_DENIED UNKNOWN_ERROR/ ];

# Valid travel modes
enum TravelMode, [ qw/DRIVING WALKING BICYCLING/ ];

# A number in the value key of a hashref
subtype ValueFromHashRef,
    as Num;

coerce ValueFromHashRef,
    from HashRef,
    via { $_->{value} };

# Array of legs
# TODO: RCL 2012-02-19 neater/faster/more compact way of doing this?
subtype ArrayRefOfLegs,
    as ArrayRef,
    where { 
        my $arrayref = $_;
        foreach( @{ $arrayref } ){
            if( not ref( $_ ) or ref( $_ ) ne 'Google::Directions::Response::Leg' ){
                return 0;
            }
        }
        return 1;
    },
    message { "Not all elements of the ArrayRef are Google::Direction::Response::Leg objects" };

coerce ArrayRefOfLegs,
    from ArrayRef[HashRef],
    via { [ map{ Google::Directions::Response::Leg->new( %{ $_ } ) } @{ $_ } ] };


# Array of routes
# TODO: RCL 2012-02-19 neater/faster/more compact way of doing this?
subtype ArrayRefOfRoutes,
    as ArrayRef,
    where { 
        my $arrayref = $_;
        foreach( @{ $arrayref } ){
            if( not ref( $_ ) or ref( $_ ) ne 'Google::Directions::Response::Route' ){
                return 0;
            }
        }
        return 1;
    },
    message { "Not all elements of the ArrayRef are Google::Direction::Response::Route objects" };

coerce ArrayRefOfRoutes,
    from ArrayRef[HashRef],
    via { [ map{ Google::Directions::Response::Route->new( %{ $_ } ) } @{ $_ } ] };


# Array of steps
# TODO: RCL 2012-02-19 neater/faster/more compact way of doing this?
subtype ArrayRefOfSteps,
    as ArrayRef,
    where { 
        my $arrayref = $_;
        foreach( @{ $arrayref } ){
            if( not ref( $_ ) or ref( $_ ) ne 'Google::Directions::Response::Step' ){
                return 0;
            }
        }
        return 1;
    },
    message { "Not all elements of the ArrayRef are Google::Direction::Response::Step objects" };

coerce ArrayRefOfSteps,
    from ArrayRef[HashRef],
    via { [ map{ Google::Directions::Response::Step->new( %{ $_ } ) } @{ $_ } ] };


1;

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

