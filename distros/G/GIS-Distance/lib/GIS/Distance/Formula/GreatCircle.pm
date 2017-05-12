package GIS::Distance::Formula::GreatCircle;
$GIS::Distance::Formula::GreatCircle::VERSION = '0.09';
=head1 NAME

GIS::Distance::Formula::GreatCircle - Great circle distance calculations. (BROKEN)

=head1 DESCRIPTION

A true Great Circle Distance calculation.  This was created
because the L<GIS::Distance::MathTrig> calculation uses
L<Math::Trig>'s great_circle_distance() which doesn't actually
appear to use the actual Great Circle Distance formula.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 BROKEN

As documented in more detail at the BUGS section of L<GIS::Distance>,
the distances returned by this module seem to be invalid.  Don't use
this module unless you want to help fix it.

=head1 FORMULA

  c = 2 * asin( sqrt(
    ( sin(( lat1 - lat2 )/2) )**2 + 
    cos( lat1 ) * cos( lat2 ) * 
    ( sin(( lon1 - lon2 )/2) )**2
  ) )

=cut

use Class::Measure::Length qw( length );
use Math::Trig qw( deg2rad asin );

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

    my $c = 2*asin( sqrt(
        ( sin(($lat1-$lat2)/2) )**2 + 
        cos($lat1) * cos($lat2) * 
        ( sin(($lon1-$lon2)/2) )**2
    ) );

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

