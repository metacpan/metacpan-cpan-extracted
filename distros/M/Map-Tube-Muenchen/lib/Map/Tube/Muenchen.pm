# -*- perl -*-
#
# Author: Gisbert W. Selke, TapirSoft Selke & Selke GbR.
#
# Copyright (C) 2025 Gisbert W. Selke. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: gws@cpan.org
#
package Map::Tube::Muenchen;
use 5.12.0;
use version 0.77 ( );
use strict;
use warnings;
use utf8;

our $VERSION = version->declare('v0.1.0');

=encoding utf8

=head1 NAME

Map::Tube::Muenchen - Interface to the Muenchen (Munich) U- and S-Bahn and tram maps.

=cut

use File::Share ':all';
use Moo;
use namespace::clean;

has xml => ( is => 'ro', default => sub { return dist_file('Map-Tube-Muenchen', 'muenchen-map.xml') } );

with 'Map::Tube';

=head1 SYNOPSIS

	use Map::Tube::Muenchen;
	my $tube = Map::Tube::Muenchen->new( );

	my $route = $tube->get_shortest_route( 'Olympiazentrum', 'Maxmonument' );

    print "Route: $route\n";

=head1 DESCRIPTION

This module allows to find the shortest route between any two given tube stations in Munich.
All interesting methods are provided by the role L<Map::Tube>.

=head1 METHODS

=head2 CONSTRUCTOR

	use Map::Tube::Muenchen;
	my $tube = Map::Tube::Muenchen->new( );

The only argument, C<xml>, is optional; if specified, it should be a code ref
to a function that returns either the path the XML map file, or a string
containing this XML content. The default is the path to F<muenchen-map.xml>
that is a part of this distribution. For further information see L<Map::Tube>.

=head2 xml( )

This read-only accessor returns whatever was specified as the XML source at
construction.

=head1 ERRORS

If something goes wrong, maybe because the map information file was corrupted,
the constructor will die.

=head1 AUTHOR

Gisbert W. Selke, TapirSoft Selke & Selke GbR <gws@cpan.org>

=head1 COPYRIGHT AND LICENCE

The data for the map were taken from the relevant Wikipedia pages.
The module itself is free software; you may redistribute and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

L<Map::Tube>, L<Map::Tube::GraphViz>.

=cut

1;
