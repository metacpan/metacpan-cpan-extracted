package Geo::Coordinates::VandH::XS;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our @EXPORT_OK = qw( distance toVH toLatLon degrees radians );
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );
our $VERSION = '0.01';

bootstrap Geo::Coordinates::VandH::XS $VERSION;

1;
__END__

=head1 NAME

Geo::Coordinates::VandH::XS

=head1 SYNOPSIS

  use Geo::Coordinates::VandH::XS 'all';
  my( $v, $h ) = toVH( $lat, $lon );
  my( $lat, $long ) = toLatLon( $v, $h );
  my $distance = distance( $v1, $h1, $v2, $h2 );
  my $degrees = degrees($radians);
  my $radians = radians($degrees);

=head1 DESCRIPTION

Convert and Manipulate telco V & H coordinates both to and from Lat/Lon and
calculate the distance between pairs of V&H co-orods.

Latitude and longtitude are in degrees. Utility conversion funtions are
available to convert degrees <-> radians

=head2 EXPORT

None by default.

=head1 AUTHOR

Dr James Freeman, E<lt>james.freeman[AT]id3.org.uk<gt>

=head1 SEE ALSO

L<perl>.

=cut
