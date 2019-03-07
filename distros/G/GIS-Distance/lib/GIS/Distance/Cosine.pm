package GIS::Distance::Cosine;
use 5.008001;
use strictures 2;
our $VERSION = '0.10';

use Math::Trig qw( deg2rad acos );
use GIS::Distance::Constants qw( :all );
use namespace::clean;

sub distance {
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

GIS::Distance::Cosine - Cosine distance calculations.

=head1 DESCRIPTION

Although this formula is mathematically exact, it is unreliable for
small distances because the inverse cosine is ill-conditioned.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula modules.

=head1 ARGUMENTS

Takes none.

=head1 FORMULA

    a = sin(lat1) * sin(lat2)
    b = cos(lat1) * cos(lat2) * cos(lon2 - lon1)
    c = arccos(a + b)
    d = R * c

=head1 SEE ALSO

L<GIS::Distanc>

L<GIS::Distance::Fast::Cosine>

=head1 AUTHORS AND LICENSE

See L<GIS::Distance/AUTHORS> and L<GIS::Distance/LICENSE>.

=cut

