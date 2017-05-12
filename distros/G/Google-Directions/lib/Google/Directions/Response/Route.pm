package Google::Directions::Response::Route;
use Moose;
use Google::Directions::Types qw/:all/;
use Google::Directions::Response::Leg;
use Google::Directions::Response::Bounds;
use Google::Directions::Response::Polyline;

=head1 NAME

Google::Directions::Response::Route - An individual route suggestion

=head1 SYNOPSIS

    my $first_route = shift( @{ $response->routes } );
    ...

=head1 ATTRIBUTES

See API documentation L<here|http://code.google.com/apis/maps/documentation/directions/#Routes> for details.

=over 4

=item I<copyrights> String defining copyright details

=item I<legs> ArrayRef of L<Google::Directions::Response::Leg>

=item I<bounds> L<Google::Directions::Response::Bounds>

=item I<summary> A String summary of the route

=item I<warnings> An ArrayRef of any warnings which occurred

=item I<waypoint_order> ArrayRef

=item I<overview_polyline> L<Google::Directions::Response::Polyline>

=back

=cut

has 'copyrights'        => ( is => 'ro', isa => 'Str',
    required    => 1,
    );

has 'legs'              => ( is => 'ro', isa => ArrayRefOfLegs,
    required    => 1,
    coerce      => 1,
    );

has 'bounds'            => ( is => 'ro', isa => BoundsClass,
    required    => 1, 
    coerce      => 1,
    );

has 'summary'           => ( is => 'ro', isa => 'Str' );
has 'warnings'          => ( is => 'ro', isa => 'ArrayRef' );
has 'waypoint_order'    => ( is => 'ro', isa => 'ArrayRef' );

has 'overview_polyline' => ( is => 'ro', isa => PolylineClass,
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
