package GIS::Distance::Constants;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

use Const::Fast;
use namespace::clean;

use Exporter qw( import );
our @EXPORT_OK;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

const our $KILOMETER_RHO => 6371.64;
push @EXPORT_OK, '$KILOMETER_RHO';

const our $DEG_RATIO => 0.0174532925199433;
push @EXPORT_OK, '$DEG_RATIO';

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Constants - Constants used by formula classes.

=head1 CONSTANTS

=head2 $KILOMETER_RHO

Number of kilometers around the equator of the earth.

C<6371.64>

=head2 $DEG_RATIO

Number of units in a single decimal degree (lat or lon) at the equator.

C<0.0174532925199433>

This value is derived from:

    $gis = GIS::Distance->new( 'Haversine' );
    $DEG_RATIO = $gis->distance( 10,0 => 11,0 )->km() / $KILOMETER_RHO;

=head1 SUPPORT

See L<GIS::Distance/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance/LICENSE>.

=cut

