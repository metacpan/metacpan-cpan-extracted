package Geo::Coordinates::MGRS::XS;

use 5.022000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	mgrs_to_utm
  mgrs_to_latlon
  latlon_to_mgrs
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Geo::Coordinates::MGRS::XS', $VERSION);

1;
__END__

=head1 NAME

Geo::Coordinates::MGRS::XS - Perl extension for converting MGRS coordinates to UTM or lat/lon.

=head1 SYNOPSIS

  use Geo::Coordinates::MGRS::XS, :all;

  my ($lat, $lon) = mgrs_to_latlon("32VNN100100");
  my ($zone, $hemisphere, $northing, $easting) = mgrs_to_utm("32VNN100100");

=head1 DESCRIPTION

Converts MGRS coordinates to UTM or lat/lon.

=head1 SEE ALSO

This module is written in C/XS for an extra speed boost - if you're not
too worried about execution speed you should probably take a look at the
more mature Geo::Coordinates::UTM, which also handles MGRS coordinates.

=head1 AUTHOR

umeldt E<lt>chris@svindseth.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by umeldt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
