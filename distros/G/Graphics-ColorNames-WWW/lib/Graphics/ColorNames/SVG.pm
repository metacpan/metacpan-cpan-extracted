package Graphics::ColorNames::SVG;

require 5.006;

use strict;
use warnings;

use Graphics::ColorNames::WWW();

our $VERSION = '1.13';

*NamesRgbTable = \&Graphics::ColorNames::WWW::NamesRgbTable;

1;

=head1 NAME

Graphics::ColorNames::SVG - SVG color names and equivalent RGB values

=head1 SYNOPSIS

  require Graphics::ColorNames::SVG;

  $NameTable = Graphics::ColorNames::SVG->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values
from the SVG 1.2 Specification.

It is currently an alias for L<Graphic::ColorNames::WWW>. This may change in
the future.  It is recommended to use the WWW module, which will always
implement a superset of this module.

See the documentation of L<Graphics::ColorNames> for information how to use
this module.

=head1 SEE ALSO

L<Graphics::ColorNames::WWW>, 
Scalable Vector Graphics (SVG) 1.1 Specification, Section 4.2 (L<http://www.w3.org/TR/SVG/types.html#ColorKeywords>)

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

=head1 LICENSE

Copyright 2008-2009 Claus FE<auml>rber.

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl
itself.

=cut
