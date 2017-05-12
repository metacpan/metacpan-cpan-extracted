package GIS::Distance::Formula::Cosine;
$GIS::Distance::Formula::Cosine::VERSION = '0.09';
=head1 NAME

GIS::Distance::Formula::Cosine - Cosine distance calculations.

=head1 DESCRIPTION

Although this formula is mathematically exact, it is unreliable for
small distances because the inverse cosine is ill-conditioned.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

  a = sin(lat1) * sin(lat2)
  b = cos(lat1) * cos(lat2) * cos(lon2 - lon1)
  c = arccos(a + b)
  d = R * c

=cut

use Class::Measure::Length qw( length );
use Math::Trig qw( deg2rad acos );

use Moo;
use strictures 1;
use namespace::clean;

with 'GIS::Distance::Formula';

=head1 METHODS

=head2 distance

This method is called by L<GIS::Distance>'s distance() method.

=cut

sub distance {
    my($self,$lat1,$lon1,$lat2,$lon2) = @_;
    $lon1 = deg2rad($lon1); $lat1 = deg2rad($lat1);
    $lon2 = deg2rad($lon2); $lat2 = deg2rad($lat2);

    my $a = sin($lat1) * sin($lat2);
    my $b = cos($lat1) * cos($lat2) * cos($lon2 - $lon1);
    my $c = acos($a + $b);

    return length( $self->kilometer_rho() * $c, 'km' );
}

1;
__END__

=head1 SEE ALSO

L<GIS::Distanc>

L<GIS::Distance::Formula::Cosine::Fast>

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

