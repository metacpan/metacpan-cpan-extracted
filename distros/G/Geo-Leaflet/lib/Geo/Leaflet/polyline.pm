package Geo::Leaflet::polyline;
use strict;
use warnings;
use base qw{Geo::Leaflet::polygon};

our $VERSION = '0.03';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::polyline - Leaflet polyline object

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map      = Geo::Leaflet->new;
  my $polyline = $map->polyline(
                              coordinates => [[$lat, $lon], ...]
                              options     => {},
                             );

=head1 DESCRIPTION

This package constructs a Leaflet polyline object for use on a L<Geo::Leaflet> map.

=head1 PROPERTIES

=head2 coordinates

=head2 options

=head2 popup

=head1 METHODS

=head2 stringify

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;
