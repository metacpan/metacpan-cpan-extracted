package Map::Tube::Nuremberg;
use strict;
use warnings;


our $VERSION = '0.05';

# ABSTRACT: Map::Tube::Nuremberg - interface to the Nuremberg U-Bahn map

use File::Share ':all';

use Moo;
use namespace::clean;

has json => (is => 'ro', default => sub { return dist_file('Map-Tube-Nuremberg', 'nuremberg-map.json') });

with 'Map::Tube';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Tube::Nuremberg - Map::Tube::Nuremberg - interface to the Nuremberg U-Bahn map

=head1 VERSION

version 0.05

=head1 DESCRIPTION

It currently provides functionality to find the shortest route between
the two given stations. The map contains currently only (U-Bahn) subway stations.

=head1 CONSTRUCTOR

    use Map::Tube::Nuremberg;
    my $tube = Map::Tube::Nuremberg->new;

=head1 METHODS

=head2 get_shortest_route(I<START>, I<END>)

This method expects two parameters I<START> and I<END> station name.
Station names are case insensitive. The station sequence from I<START>
to I<END> is returned.

    use Map::Tube::Nuremberg;
    my $tube = Map::Tube::Nuremberg->new;
    my $route = $tube->get_shortest_route('Rathenauplatz', 'Hauptbahnhof');
    print "Route: $route\n";

=head1 SEE ALSO

L<Map::Tube>.

=head1 AUTHOR

Stefan Limbacher <stelim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Stefan Limbacher.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
