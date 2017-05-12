package Graphics::ColorNames::CSS;

require 5.006;

use strict;
use warnings;

use Graphics::ColorNames::WWW();

our $VERSION = '1.13';

*NamesRgbTable = \&Graphics::ColorNames::WWW::NamesRgbTable;

1;

=head1 NAME

Graphics::ColorNames::CSS - CSS color names and equivalent RGB values

=head1 SYNOPSIS

  require Graphics::ColorNames::CSS;

  $NameTable = Graphics::ColorNames::CSS->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values from the CSS
Color Module Level 3 W3C Working Draft of 2008-07-21.

It is currently an alias for L<Graphic::ColorNames::WWW>. This may change in
the future. It is recommended to use the WWW module, which will always
implement a superset of this module.

See the documentation of L<Graphics::ColorNames> for information how to use
this module.

=head1 SEE ALSO

L<Graphics::ColorNames::WWW>, 
CSS Color Module Level 3 (L<http://w3.org/TR/CSS3-color>)

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

=head1 LICENSE

Copyright 2005-2009 Claus FE<auml>rber.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
