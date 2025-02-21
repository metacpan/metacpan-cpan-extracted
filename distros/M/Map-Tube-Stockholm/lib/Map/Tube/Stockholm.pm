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
package Map::Tube::Stockholm;
use 5.12.0;
use version 0.77 ( );
use strict;
use warnings;

our $VERSION = version->declare('v0.1.1');

=encoding utf8

=head1 NAME

Map::Tube::Stockholm - Interface to the Stockholm tube and tram map

=cut

use File::Share ':all';
use Moo;
use namespace::clean;

has xml => ( is => 'ro', default => sub { return dist_file('Map-Tube-Stockholm', 'stockholm-map.xml') } );

with 'Map::Tube';

=head1 SYNOPSIS

	use Map::Tube::Stockholm;
	my $tube = Map::Tube::Stockholm->new();

	my $route = $tube->get_shortest_route( 'Slussen', 'Solna strand');

    print "Route: $route\n";

=head1 DESCRIPTION

This module allows to find the shortest route between any two given tube or tram
stations in Stockholm. All interesting methods are provided by the role L<Map::Tube>.

=head1 METHODS

=head2 CONSTRUCTOR

	use Map::Tube::Stockholm;
	my $tube = Map::Tube::Stockholm->new();

The only argument, C<xml>, is optional; if specified, it should be a code ref
to a function that returns either the path the XML map file, or a string
containing this XML content. The default is the path to F<stockholm-map.xml>
that is a part of this distribution. For further information see L<Map::Tube>.

=head2 xml()

This read-only accessor returns whatever was specified as the XML source at
construction.

=head1 NOTE CONCERNING DIAGRAM CREATION

This note concerns only those who want to produce network diagrams using
L<Map::Tube::Plugin::Graph> (also pertaining to L<Map::Tube::CLI>) or
L<Map::Tube::GraphViz>.

There is a potential conflict between an advanced feature of the (excellent) L<GraphViz2>
module and the Swedish station names, which may lead to an exception being thrown.

Users of L<Map::Tube::Plugin::Graph> are encouraged to upgrade to at least version 0.48,
which solves the issue cleanly. This also applies to indirect use of this module
through L<Map::Tube::CLI> and the corresponding command line programme.

Users of L<Map::Tube::GraphViz> can prevent any issue cleanly by defining a function
as follows:

	sub mynode_id {
		my ($self, $node) = @_;
		return $node->id;
	};

and supplying this as a callback function when creating the diagram:

	my $g = Map::Tube::GraphViz->new( 'tube' => $tube,
		callback_node_id => \&mynode_id, );


=head1 ERRORS

If something goes wrong, maybe because the map information file was corrupted,
the constructor will die.

=head1 AUTHOR

Gisbert W. Selke, TapirSoft Selke & Selke GbR.

=head1 COPYRIGHT AND LICENCE

The data for the XML file were taken from https://tunnelbanakarta.se/
The module itself is free software; you may redistribute and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Map::Tube>, L<Map::Tube::GraphViz>, L<Map::Tube::Plugin::Graph>.

=cut

1;
