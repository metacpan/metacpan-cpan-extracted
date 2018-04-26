package Map::Tube::Frankfurt;

use strict;
use warnings;

our $VERSION = '0.01';

# ABSTRACT: Map::Tube::Frankfurt - interface to the Frankfurt S- and U-Bahn map

use File::Share ':all';

use Moo;
use namespace::clean;

has json => (is => 'ro', default => sub { return dist_file('Map-Tube-Frankfurt', 'frankfurt-map.json') });

with 'Map::Tube';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Tube::Frankfurt - Map::Tube::Frankfurt - interface to the Frankfurt S- and U-Bahn map

=head1 VERSION

version 0.01

=head1 DESCRIPTION

It currently provides functionality to find the shortest route between
the two given stations. The map contains both U-Bahn and S-Bahn stations.

=head1 CONSTRUCTOR

    use Map::Tube::Frankfurt;
    my $tube = Map::Tube::Frankfurt->new;

=head1 METHODS

=head2 get_shortest_route(I<START>, I<END>)

This method expects two parameters I<START> and I<END> station name.
Station names are case insensitive. The station sequence from I<START>
to I<END> is returned.

    use Map::Tube::Frankfurt;
    my $tube = Map::Tube::Frankfurt->new;

    my $route = $tube->get_shortest_route('Riedstadt-Goddelau', 'Hauptbahnhof');

    print "Route: $route\n";

=head1 SEE ALSO

L<Map::Tube>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
