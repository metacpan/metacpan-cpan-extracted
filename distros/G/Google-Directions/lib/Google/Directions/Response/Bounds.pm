package Google::Directions::Response::Bounds;
use Moose;
use Google::Directions::Types qw/:all/;

=head1 NAME

Google::Directions::Response::Bounds - The bounds for a route

=head1 SYNOPSIS

    my $first_route = shift( @{ $response->routes } );
    my $bounds = $first_route->bounds;
    ...

=cut

=head1 ATTRIBUTES

Stores the northeast and southwest corners of the bounding box within which the route
happens

=over 4

=item I<northeast> L<Google::Directions::Response::Coordinates>

=item I<southwest> L<Google::Directions::Response::Coordinates>

=back

=cut

has 'northeast'     => ( is => 'ro', isa => CoordinatesClass,
    required => 1, coerce => 1 );
has 'southwest'     => ( is => 'ro', isa => CoordinatesClass,
    required => 1, coerce => 1 );

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

