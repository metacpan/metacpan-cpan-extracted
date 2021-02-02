package GIS::Distance::GreatCircle;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

use parent 'GIS::Distance::Formula';

use Math::Trig qw( deg2rad asin );
use GIS::Distance::Constants qw( :all );
use namespace::clean;

sub _distance {
    my ($lat1, $lon1, $lat2, $lon2) = @_;

    $lon1 = deg2rad($lon1);
    $lat1 = deg2rad($lat1);
    $lon2 = deg2rad($lon2);
    $lat2 = deg2rad($lat2);

    my $c = 2*asin( sqrt(
        ( sin(($lat1-$lat2)/2) )**2 + 
        cos($lat1) * cos($lat2) * 
        ( sin(($lon1-$lon2)/2) )**2
    ) );

    return $KILOMETER_RHO * $c;
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::GreatCircle - Great circle distance calculations.

=head1 DESCRIPTION

A true Great Circle Distance calculation.  This was created because the
L<GIS::Distance::MathTrig> formula uses L<Math::Trig>'s
C<great_circle_distance()> which doesn't actually appear to use the
actual Great Circle Distance formula (more likely Cosine).

A faster (XS) version of this formula is available as
L<GIS::Distance::Fast::GreatCircle>.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

    c = 2 * asin( sqrt(
        ( sin(( lat1 - lat2 )/2) )**2 + 
        cos( lat1 ) * cos( lat2 ) * 
        ( sin(( lon1 - lon2 )/2) )**2
    ) )

=head1 SUPPORT

See L<GIS::Distance/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance/LICENSE>.

=cut

