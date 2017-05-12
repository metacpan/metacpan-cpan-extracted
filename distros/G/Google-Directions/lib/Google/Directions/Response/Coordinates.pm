package Google::Directions::Response::Coordinates;
use Moose;
use MooseX::Aliases;

=head1 NAME

Google::Directions::Response::Coordinates - Individual coordinates

=head1 SYNOPSIS

    my $first_route = shift( @{ $response->routes } );
    my $bounds = $first_route->bounds;
    printf "Northeast corner at Latitude: %3.5f, Longitude: %3.5f\n",
        $bounds->northeast->lat,
        $bounsd->northeast->lng;

=head1 ATTRIBUTES

=over 4

=item I<lat> $number (alias: I<latitude>)

=item I<lng> $number (alias: I<longitude>)

=back

=cut

has 'lat'   => ( is => 'ro', isa => 'Num', required => 1, alias => 'latitude' );
has 'lng'   => ( is => 'ro', isa => 'Num', required => 1, alias => 'longitude' );

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

