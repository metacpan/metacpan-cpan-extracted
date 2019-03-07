package GIS::Distance::Fast::Vincenty;
use 5.008001;
use strictures 2;
our $VERSION = '0.09';

use GIS::Distance::Fast;
use GIS::Distance::Constants qw( :all );
use namespace::clean;

sub distance {
    my $c = GIS::Distance::Fast::vincenty_distance( @_ );

    return $c / 1000;
}

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
is used which in turn interfaces with the various formula modules.

=head1 AUTHORS AND LICENSE

See L<GIS::Distance::Fast/AUTHORS> and L<GIS::Distance::Fast/LICENSE>.

=cut

