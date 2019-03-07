package GIS::Distance::Fast;
use 5.008001;
use strictures 2;
our $VERSION = '0.09';

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
is generally much faster than the perl equivilent.

In most of my testing I've found that the C version of the formulas
outperform the Perl equivelent by at least 2x.

This module need not be used directly.  L<GIS::Distance> will automatically
use the ::Fast formulas when they are available.

=head1 FORMULAS

L<GIS::Distance::Fast::Cosine>

L<GIS::Distance::Fast::Haversine>

L<GIS::Distance::Fast::Vincenty>

=head1 SUPPORT

Please submit bugs and feature requests to the GIS-Distance-Fast GitHub issue tracker:

L<https://github.com/bluefeet/GIS-Distance-Fast/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

