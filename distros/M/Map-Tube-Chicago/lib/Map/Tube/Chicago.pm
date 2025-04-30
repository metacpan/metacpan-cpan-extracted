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
package Map::Tube::Chicago;
use 5.14.0;
use version 0.77 ( );
use strict;
use warnings;

our $VERSION = version->declare('v0.2.1');

=encoding utf8

=head1 NAME

Map::Tube::Chicago - Interface to the Chicago L system map

=cut

use File::Share ':all';
use Moo;
use namespace::clean;

has xml => ( is => 'ro', default => sub { return dist_file('Map-Tube-Chicago', 'chicago-map.xml') } );

with 'Map::Tube';

=head1 SYNOPSIS

	use Map::Tube::Chicago;
	my $tube = Map::Tube::Chicago->new();

	my $route = $tube->get_shortest_route( 'Fullerton', 'Library');

    print "Route: $route\n";

=head1 DESCRIPTION

This module allows to find the shortest route between any two given tube or tram
stations in Chicago. All interesting methods are provided by the role L<Map::Tube>.
Since many stations in Chicago having the same name are in fact different stations,
this module disambiguates these names by attaching the parenthesized line name.
This also applies to stations of the same name where an interchange is possible
but requires a walk checking out from one station and checking in at another (of
the same name).

=head1 METHODS

=head2 CONSTRUCTOR

	use Map::Tube::Chicago;
	my $tube = Map::Tube::Chicago->new();

The only argument, C<xml>, is optional; if specified, it should be a code ref
to a function that returns either the path the XML map file, or a string
containing this XML content. The default is the path to F<chicago-map.xml>
that is a part of this distribution. For further information see L<Map::Tube>.

=head2 xml()

This read-only accessor returns whatever was specified as the XML source at
construction.

=head1 ERRORS

If something goes wrong, maybe because the map information file was corrupted,
the constructor will die.

=head1 AUTHOR

Gisbert W. Selke, TapirSoft Selke & Selke GbR.

=head1 COPYRIGHT AND LICENCE

The data for the XML file were taken from https://en.wikipedia.org/wiki/Chicago_%22L%22
and some pages linked from there.
The module itself is free software; you may redistribute and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Map::Tube>, L<Map::Tube::GraphViz>.

=cut

1;
