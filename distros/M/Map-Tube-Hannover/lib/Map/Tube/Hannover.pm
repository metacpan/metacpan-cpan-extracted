# -*- perl -*-
#
# Author: Gisbert W. Selke, TapirSoft Selke & Selke GbR.
#
# Copyright (C) 2026 Gisbert W. Selke. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: gws@cpan.org
#
package Map::Tube::Hannover;
use 5.14.0;
use version 0.77 ( );
use strict;
use warnings;

our $VERSION = version->declare('v0.1.0');

=encoding utf8

=head1 NAME

Map::Tube::Hannover - Interface to the German Hannover U- and S-Bahn and tram maps.

=cut

use File::Share ':all';
use Moo;
use namespace::clean;

has xml => ( is => 'ro', default => sub { return dist_file('Map-Tube-Hannover', 'hannover-map.xml') } );

with 'Map::Tube';

=head1 SYNOPSIS

  use Map::Tube::Hannover;
  my $tube = Map::Tube::Hannover->new( );

  my $route = $tube->get_shortest_route( 'xxxxxxxx', 'yyyyyyyy' );

  print "Route: $route\n";

=head1 DESCRIPTION

This module allows to find the shortest route between any two given tube
stations in the Hannover area of Germany. Tube, tram and S-Bahn lines are covered.

All interesting methods are provided by the role L<Map::Tube>.

=head1 METHODS

=head2 CONSTRUCTOR

  use Map::Tube::Hannover;
  my $tube = Map::Tube::Hannover->new( );

The only argument, C<xml>, is optional; if specified, it should be a code ref
to a function that returns either the path the XML map file, or a string
containing this XML content. The default is the path to F<hannover-map.xml>
that is a part of this distribution. For further information see L<Map::Tube>.

=head2 xml( )

This read-only accessor returns whatever was specified as the XML source at
construction.

=head1 ERRORS

If something goes wrong, maybe because the map information file was corrupted,
the constructor will die.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/gwselke/Map-Tube-Hannover/issues>. I will be
notified and then you'll automatically be notified of progress on your
bug when (and if) I make changes.

=head1 CONTRIBUTING

The Perl code as such is fairly trivial (which does not imply free of bugs), so there
is probably little opportunity to contribute interesting things. However, the tube lines
and stations will probably evolve. I would be grateful to be informed about any such changes
(or, indeed, of errors of mine). The best way to contribute is to create an issue and to
list any updated line and station information in plain UTF-8 text, or to attach this
information in a plain text file. Do not change the XML file, since this is mechanically
generated from a different, internal file format.

=head1 AUTHOR

Gisbert W. Selke, TapirSoft Selke & Selke GbR <gws@cpan.org>

=head1 COPYRIGHT AND LICENCE

The data for the map were taken from the various web sites of the companies running the services.
The module itself is free software; you may redistribute and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

L<Map::Tube>, L<Map::Tube::GraphViz>, L<Map::Tube::CLI>.

=cut

1;
