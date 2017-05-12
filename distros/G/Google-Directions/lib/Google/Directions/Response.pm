package Google::Directions::Response;
use Moose;
use Google::Directions::Types qw/:all/;
use Google::Directions::Response::Route;

=head1 NAME

Google::Directions::Response - The response to a directions request

=head1 SYNOPSIS

    my $response = $goog->directions(
        origin      => '25 Thompson Street, New York, NY, United States',
        destination => '34 Lafayette Street, New York, NY, United States',
        );
    if( $response->status ne 'OK' ){
        die( "Status: " . $response->status );
    }
    ...

=head1 ATTRIBUTES

=over 4

=item I<status> A text representation of the success of the query.

See API documentation L<here|http://code.google.com/apis/maps/documentation/directions/#StatusCodes> for details.

=item I<routes> An ArrayRef of L<Google::Directions::Response::Route> objects

=back

=cut

has 'cached'	    => ( is => 'rw', isa => 'Bool', writer => 'set_cached' );
has 'status'        => ( is => 'ro', isa => StatusCode, required => 1 );
has 'routes'        => ( is => 'ro', isa => ArrayRefOfRoutes, coerce => 1 );

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
