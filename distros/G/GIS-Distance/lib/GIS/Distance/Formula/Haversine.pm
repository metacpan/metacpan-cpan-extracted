package GIS::Distance::Formula::Haversine;
$GIS::Distance::Formula::Haversine::VERSION = '0.09';
=head1 NAME

GIS::Distance::Formula::Haversine - Exact spherical distance calculations.

=head1 DESCRIPTION

This is the default distance calculation for L<GIS::Distance> as
it keeps a good balance between speed and accuracy.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

  dlon = lon2 - lon1
  dlat = lat2 - lat1
  a = (sin(dlat/2))^2 + cos(lat1) * cos(lat2) * (sin(dlon/2))^2
  c = 2 * atan2( sqrt(a), sqrt(1-a) )
  d = R * c

=cut

use Math::Trig qw( deg2rad );
use Class::Measure::Length qw( length );

use Moo;
use strictures 1;
use namespace::clean;

with 'GIS::Distance::Formula';

=head1 METHODS

=head2 distance

This method is called by L<GIS::Distance>'s distance() method.

=cut

sub distance {
    my ($self, $lat1, $lon1, $lat2, $lon2) = @_;
    $lon1 = deg2rad($lon1);
    $lat1 = deg2rad($lat1);
    $lon2 = deg2rad($lon2);
    $lat2 = deg2rad($lat2);

    my $dlon = $lon2 - $lon1;
    my $dlat = $lat2 - $lat1;
    my $a = (sin($dlat/2)) ** 2 + cos($lat1) * cos($lat2) * (sin($dlon/2)) ** 2;
    my $c = 2 * atan2(sqrt($a), sqrt(1-$a));

    return length( $self->kilometer_rho() * $c, 'km' );
}

1;
__END__

=head1 SEE ALSO

L<GIS::Distanc>

L<GIS::Distance::Formula::Haversine::Fast>

=head1 RESOURCES

L<http://mathforum.org/library/drmath/view/51879.html>

L<http://www.faqs.org/faqs/geography/infosystems-faq/>

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

