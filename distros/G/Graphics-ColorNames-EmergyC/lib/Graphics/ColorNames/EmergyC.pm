package Graphics::ColorNames::EmergyC;

=head1 NAME

Graphics::ColorNames::EmergyC - Eco-friendly web-design color-palette.

=head1 SYNOPSIS

  require Graphics::ColorNames::EmergyC;

  $NameTable = Graphics::ColorNames::EmergyC->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

The Emergy-C color palette is based on the
EnergyStar wattage ratings for different colors.  Supposedly, a
display mainly using colors of this palette uses on average only
about 3 or 4 watts more than a completely black screen.  White is
included as an accent color, only for a small proportion
of the screen.

Since it is a minimal palette, you may want to use it in conjunction
with other palettes.

=begin readme

=head1 REVISION HISTORY

Changes since the last release

=for readme include file=Changes start=^1.01 stop=^1.00 type=text

More details can be found in the F<Changes> file.

=end readme

=head1 SEE ALSO

L<Graphics::ColorNames>

This palette comes from
L<http://ecoiron.blogspot.com/2007/01/emergy-c-low-wattage-palette.html>.

EnergyStar wattage ratings for colors,
L<http://www.microtech.doe.gov/EnergyStar/info.htm>.

=head1 AUTHOR

Implemented as a plugin for L<Graphics::ColorNames> by
Robert Rothenberg <rrwo at cpan.org>.

This palette was designed by Jon Doucette, <finaljon at gmail.com>.

=head1 LICENSE

Copyright (c) 2007 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


use strict;

our $VERSION = '1.01';

sub NamesRgbTable() {
  use integer;
  return {
    "white"               => 0xffffff,
    "black"               => 0x000000,
    "rustyred"            => 0x822007,
    "bluegrey"            => 0xb2bbc0,
    "forestgreen"         => 0x19472a,
    "cobalt"              => 0x3d414c,
  };
}

1;

__END__
