package GIS::Distance::Null;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

use parent 'GIS::Distance::Formula';

sub _distance { 0 }

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Null - For planets with no surface.

=head1 DESCRIPTION

Always returns C<0>.

A faster (XS) version of this formula is available as
L<GIS::Distance::Fast::Null>.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

    d = 0

=head1 SEE ALSO

=over

=item *

L<https://en.wikipedia.org/wiki/0>

=item *

L<GIS::Distance::Fast::Null>

=back

=head1 SUPPORT

See L<GIS::Distance/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance/LICENSE>.

=cut

