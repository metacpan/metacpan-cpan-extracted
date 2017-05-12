package Google::Directions::Response::Step;
use Moose;
use Google::Directions::Types qw/:all/;
use Google::Directions::Response::Coordinates;
use Google::Directions::Response::Polyline;

=head1 NAME

Google::Directions::Response::Step - An step of a leg of a journey

=head1 SYNOPSIS

    my $first_route = shift( @{ $response->routes } );
    foreach my $leg( @{ $first_route->legs } ){
        foreach my $step( @{ $leg->steps } ){
            printf "Duration: %s\n", $step->duration;
        }
    }

=cut

=head1 ATTRIBUTES

See API documentation L<here|http://code.google.com/apis/maps/documentation/directions/#Steps> for details.

=over 4

=item I<distance> $integer Distance is always in meters

=item I<duration> $integer Duration is always in seconds

=item I<end_address> $string

=item I<end_location> L<Google::Directions::Response::Coordinates>

=item I<start_address> $string

=item I<start_location> L<Google::Directions::Response::Coordinates>

=item I<steps> ArrayRef of L<Google::Directions::Response::Step>

=item I<html_instructions> $string

=item I<travel_mode> $string

=item I<polyline> L<Google::Directions::Response::Polyline>

=back

=cut

has 'distance'      => ( is => 'ro', isa => ValueFromHashRef,
    coerce      => 1, 
    required    => 1,
    );

has 'duration'      => ( is => 'ro', isa => ValueFromHashRef,
    coerce      => 1, 
    required    => 1,
    );
has 'end_address'   => ( is => 'ro', isa => 'Str' );
has 'end_location'  => ( is => 'ro', isa => CoordinatesClass,
    coerce      => 1,
    required    => 1,
    );

has 'start_address'   => ( is => 'ro', isa => 'Str' );
has 'start_location'  => ( is => 'ro', isa => CoordinatesClass,
    coerce      => 1,
    required    => 1,
    );

has 'html_instructions' => ( is => 'ro', isa => 'Str' );

has 'travel_mode'       => ( is => 'ro', isa => TravelMode );

has 'polyline'          => ( is => 'ro', isa => PolylineClass,
    coerce  => 1,
    );

1;

=head1 AUTHOR

Robin Clarke, C<< <perl at robinclarke.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
