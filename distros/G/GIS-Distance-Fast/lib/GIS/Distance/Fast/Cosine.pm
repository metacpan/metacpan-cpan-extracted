package GIS::Distance::Fast::Cosine;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

use GIS::Distance::Fast;
use namespace::clean;

{
    no strict 'refs';
    *distance = \&GIS::Distance::Fast::cosine_distance;
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Fast::Cosine - C implementation of GIS::Distance::Cosine.

=head1 DESCRIPTION

See L<GIS::Distance::Cosine> for details about this formula.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula modules.

=head1 AUTHORS AND LICENSE

See L<GIS::Distance::Fast/AUTHORS> and L<GIS::Distance::Fast/LICENSE>.

=cut

