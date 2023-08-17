package GIS::Distance::Fast;
use 5.008001;
use strictures 2;
our $VERSION = '0.16';

our @ISA;

eval {
    require XSLoader;
    XSLoader::load('GIS::Distance::Fast', $VERSION);
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap GIS::Distance::Fast $VERSION;
};

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Fast - C implementation of GIS::Distance formulas.

=head1 DESCRIPTION

This distribution re-implements some, but not all, of the formulas
that come with L<GIS::Distance> in the C programming language.  C code
is generally much faster than the Perl equivalent.

See L<GIS::Distance/SPEED> for some benchmarking and how to run your
own benchmarks.

This module need not be used directly.  L<GIS::Distance> will automatically
use the C<GIS::Distance::Fast::*> formulas when installed.

=head1 FORMULAS

=over

=item *

L<GIS::Distance::Fast::Cosine>

=item *

L<GIS::Distance::Fast::GreatCircle>

=item *

L<GIS::Distance::Fast::Haversine>

=item *

L<GIS::Distance::Fast::Polar>

=item *

L<GIS::Distance::Fast::Vincenty>

=back

=head1 SUPPORT

Please submit bugs and feature requests to the
GIS-Distance-Fast GitHub issue tracker:

L<https://github.com/bluefeet/GIS-Distance-Fast/issues>

=head1 AUTHOR

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
