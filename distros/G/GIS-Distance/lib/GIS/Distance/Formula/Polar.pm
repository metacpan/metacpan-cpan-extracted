package GIS::Distance::Formula::Polar;
$GIS::Distance::Formula::Polar::VERSION = '0.09';
=head1 NAME

GIS::Distance::Formula::Polar - Polar coordinate flat-earth distance calculations. (BROKEN)

=head1 DESCRIPTION

Supposedly this is a formula to better calculate distances at the
poles.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 BROKEN

While implimented, this formula has not been tested much.  If you use it
PLEASE share your results with the author.  I've tested the results of this
formula versus Vincenty and it appears that this formula is broken (or
the implementation is) as you can see in 02_polar.t.

=head1 FORMULA

  a = pi/2 - lat1
  b = pi/2 - lat2
  c = sqrt( a^2 + b^2 - 2 * a * b * cos(lon2 - lon1) )
  d = R * c

=cut

use Class::Measure::Length qw( length );
use Math::Trig qw( deg2rad pi );

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
    my $a = pi/2 - $lat1;
    my $b = pi/2 - $lat2;
    my $c = sqrt( $a ** 2 + $b ** 2 - 2 * $a * $b * cos($lon2 - $lon1) );
    return length( $self->kilometer_rho() * $c, 'km' );
}

1;
__END__

=head1 SEE ALSO

L<GIS::Distanc>

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

