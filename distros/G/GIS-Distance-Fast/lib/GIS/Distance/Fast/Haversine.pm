package GIS::Distance::Fast::Haversine;
use 5.008001;
use strictures 2;
our $VERSION = '0.16';

use parent 'GIS::Distance::Formula';

use GIS::Distance::Fast;
use namespace::clean;

*_distance = \&GIS::Distance::Fast::haversine_distance;

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Fast::Haversine - C implementation of GIS::Distance::Haversine.

=head1 DESCRIPTION

See L<GIS::Distance::Haversine> for details about this formula.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 SUPPORT

See L<GIS::Distance::Fast/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance::Fast/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance::Fast/LICENSE>.

=cut

