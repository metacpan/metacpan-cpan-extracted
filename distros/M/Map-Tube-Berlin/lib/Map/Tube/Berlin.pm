# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2014,2015,2016 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
#

package Map::Tube::Berlin;

$VERSION = '0.14';

=head1 NAME

Map::Tube::Berlin - interface to the Berlin S- and U-Bahn map

=cut

use File::Share ':all';

use Moo;
use namespace::clean;

has xml => (is => 'ro', default => sub { return dist_file('Map-Tube-Berlin', 'berlin-map.xml') });

with 'Map::Tube';

=head1 DESCRIPTION

It currently provides functionality to find the shortest route between
the two given stations. The map contains both U-Bahn and S-Bahn stations.

=head1 CONSTRUCTOR

    use Map::Tube::Berlin;
    my $tube = Map::Tube::Berlin->new;

=head1 METHODS

=head2 get_shortest_route(I<START>, I<END>)

This method expects two parameters I<START> and I<END> station name.
Station names are case insensitive. The station sequence from I<START>
to I<END> is returned.

    use Map::Tube::Berlin;
    my $tube = Map::Tube::Berlin->new;

    my $route = $tube->get_shortest_route('Zoologischer Garten', 'Alexanderplatz');

    print "Route: $route\n";

=head1 NOTES

The XML file was generated using data from the L<BBBike
project|https://github.com/eserte/bbbike>. A Makefile rule
C<build-map> for regenerating the XML file exists (assuming that
BBBike was cloned/extracted into F<$HOME/src/bbbike>.

=head1 AUTHOR

Slaven Rezic

=head1 SEE ALSO

L<Map::Tube>.

=cut

1;
