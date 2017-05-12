package GIS::Distance::Formula;
$GIS::Distance::Formula::VERSION = '0.09';
=head1 NAME

GIS::Distance::Formula - Role for all the GIS::Distance::Formula:: classes.

=head1 DESCRIPTION

This role enforces an API and provides shared information for the
formula classes that use it.

=cut

use Types::Standard -types;

use Moo::Role;
use strictures 1;
use namespace::clean;

requires 'distance';

=head1 ATTRIBUTES

=head2 kilometer_rho

Number of kilometers around the equator of the earth.
Defaults to 6371.64.

=cut

has kilometer_rho => (
    is      => 'ro',
    isa     => Num,
    default => 6371.64,
);

=head2 deg_ratio

Number of units in a single decimal degree (lat or lon) at the equator.
The default, 0.0174532925199433, is derived from:

  $gis->distance( 10,0 => 11,0 )->km() / $gis->kilometer_rho()

=cut

has deg_ratio => (
    is      => 'ro',
    isa     => Num,
    default => 0.0174532925199433,
);

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

