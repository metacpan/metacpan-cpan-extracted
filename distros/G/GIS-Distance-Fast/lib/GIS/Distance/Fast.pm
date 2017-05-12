package GIS::Distance::Fast;
$GIS::Distance::Fast::VERSION = '0.08';
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

=cut

use strictures 1;

our @ISA;
our $VERSION;

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

=head1 FORMULAS

L<GIS::Distance::Formula::Cosine::Fast>

L<GIS::Distance::Formula::Haversine::Fast>

L<GIS::Distance::Formula::Vincenty::Fast>

=head1 BUGS

The L<GIS::Distance::Formula::Vincenty::Fast> produces slightly different results than
L<GIS::Distance::Formula::Vincenty>.  Read the POD for L<GIS::Distance::Formula::Vincenty::Fast>
for details.

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

