package GIS::Distance::Fast::ALT;
use 5.008001;
use strictures 2;
our $VERSION = '0.16';

use parent 'GIS::Distance::Formula';

use GIS::Distance::Fast;
use namespace::clean;

*_distance = \&GIS::Distance::Fast::alt_distance;

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Fast::ALT - C implementation of GIS::Distance::ALT.

=head1 DESCRIPTION

See L<GIS::Distance::ALT> for details about this formula.

The code for this formula was taken from L<Geo::Distance::XS> and
modified to fit.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 SUPPORT

See L<GIS::Distance::Fast/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance::Fast/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance::Fast/LICENSE>.

=cut

