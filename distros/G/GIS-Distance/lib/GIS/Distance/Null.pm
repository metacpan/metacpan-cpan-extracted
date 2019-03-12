package GIS::Distance::Null;
use 5.008001;
use strictures 2;
our $VERSION = '0.14';

sub distance { 0 }

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Null - For planets with no surface.

=head1 DESCRIPTION

Always returns C<0>.

=head1 FORMULA

    d = 0

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/0>

L<GIS::Distance::Fast::Null>

=head1 AUTHORS AND LICENSE

See L<GIS::Distance/AUTHORS> and L<GIS::Distance/LICENSE>.

=cut

