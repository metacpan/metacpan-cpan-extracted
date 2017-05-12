package GIS::Distance::Formula::MathTrig;
$GIS::Distance::Formula::MathTrig::VERSION = '0.09';
=head1 NAME

GIS::Distance::Formula::MathTrig - Great cirlce distance calculations using Math::Trig.

=head1 DESCRIPTION

This formula uses L<Math::Trig>'s great_circle_distance function which
at this time uses math almost exactly the same as the
L<GIS::Distance::Cosine> formula.  If you want to use the
L<GIS::Distance::Cosine> formula you may find that this module will
calculate faster (untested assumption).  For some reason this and
the Cosine formula return slight differences at very close distances.
This formula has the same drawbacks as the Cosine formula.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

  lat0 = 90 degrees - phi0
  lat1 = 90 degrees - phi1
  d = R * arccos(cos(lat0) * cos(lat1) * cos(lon1 - lon01) + sin(lat0) * sin(lat1))

As stated in the L<Math::Trig> POD.

=cut

use Class::Measure::Length qw( length );
use Math::Trig qw( great_circle_distance deg2rad );

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

    return length(
        great_circle_distance(
            deg2rad($lon1),
            deg2rad(90 - $lat1),
            deg2rad($lon2),
            deg2rad(90 - $lat2),
            $self->kilometer_rho(),
        ),
        'km'
    );
}

1;
__END__

=head1 SEE ALSO

L<GIS::Distanc>

L<Math::Trig>

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

