package GIS::Distance::Cosine;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

use parent 'GIS::Distance::Formula';

use Math::Trig qw( deg2rad acos );
use GIS::Distance::Constants qw( :all );
use namespace::clean;

sub _distance {
    my ($lat1, $lon1, $lat2, $lon2) = @_;

    $lon1 = deg2rad($lon1);
    $lat1 = deg2rad($lat1);
    $lon2 = deg2rad($lon2);
    $lat2 = deg2rad($lat2);

    my $a = sin($lat1) * sin($lat2);
    my $b = cos($lat1) * cos($lat2) * cos($lon2 - $lon1);
    my $c = acos($a + $b);

    return $KILOMETER_RHO * $c;
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Cosine - Spherical law of cosines distance calculations.

=head1 DESCRIPTION

Although this formula is mathematically exact, it is unreliable for
small distances.  See L<GIS::Distance::MathTrig> for related details.

A faster (XS) version of this formula is available as
L<GIS::Distance::Fast::Cosine>.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

    a = sin(lat1) * sin(lat2)
    b = cos(lat1) * cos(lat2) * cos(lon2 - lon1)
    c = arccos(a + b)
    d = R * c

=head1 SEE ALSO

=over

=item *

L<https://en.wikipedia.org/wiki/Spherical_law_of_cosines>

=back

=head1 SUPPORT

See L<GIS::Distance/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance/LICENSE>.

=cut

