package GIS::Distance::Fast::Vincenty;
use 5.008001;
use strictures 2;
our $VERSION = '0.16';

use parent 'GIS::Distance::Formula';

use GIS::Distance::Fast;
use namespace::clean;

*_distance = \&GIS::Distance::Fast::vincenty_distance;

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Fast::Vincenty - C implementation of GIS::Distance::Vincenty.

=head1 DESCRIPTION

See L<GIS::Distance::Vincenty> for details about this formula.

The results from L<GIS::Distance::Vincenty> versus this module are slightly
different.  I'm still not sure why this is, as the C code is nearly identical to
the Perl code.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 SUPPORT

See L<GIS::Distance::Fast/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance::Fast/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance::Fast/LICENSE>.

=cut

