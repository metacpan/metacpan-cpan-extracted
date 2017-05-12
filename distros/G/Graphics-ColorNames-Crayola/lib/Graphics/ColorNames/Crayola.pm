package Graphics::ColorNames::Crayola;

=head1 NAME

Graphics::ColorNames::Crayola - the original 48 crayola crayon colors

=head1 SYNOPSIS

  require Graphics::ColorNames::Crayola;

  $NameTable = Graphics::ColorNames::Crayola->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

A palette based on the original 48 crayola crayon colors.

These colors are based on scanned images of crayon colors, so they
may not correspond with their standard X colors of the same names.

=begin readme

=head1 REVISION HISTORY

Changes since the last release

=for readme include file=Changes start=^1.01 stop=^1.00 type=text

More details can be found in the F<Changes> file.

=end readme

=head1 SEE ALSO

L<Graphics::ColorNames>

=head1 AUTHOR

Implemented as a plugin for L<Graphics::ColorNames> by
Robert Rothenberg <rrwo at cpan.org>.

This palette comes from Bill ?
L<http://www.auterytech.com/enantiodromos/crayola.html>.

=head1 LICENSE

This software is public domain.  No copyright is claimed by the author
for it.

It is possible that Crayola Company (L<http://www.crayola.com>) may
claim ownership of some vague intellectual-property-related 
turf for the crayons, their names, or colors, depending on how
insecure or bored their lawyers are feeling at any moment.

=cut

use strict;

our $VERSION = '1.01';

sub NamesRgbTable() {
  use integer;
  return {
    "black"                => 0x313e38,
    "gray"                 => 0x646f6c,
    "brown"                => 0x73503c,
    "sepia"                => 0x6c4f3c,
    "chestnut"             => 0x954535,
    "mahogany"             => 0xba4f35,
    "burntsienna"          => 0xbd6638,
    "rawsienna"            => 0x9f6a3b,
    "tumbleweed"           => 0xb98a64,
    "tan"                  => 0xda7b3c,
    "timberwolf"           => 0xadb0aa,
    "white"                => 0xfafaf7,
    "lavender"             => 0xee92d0,
    "salmon"               => 0xf6698a,
    "carnationpink"        => 0xfa7fc1,
    "mauvelous"            => 0xd0687e,
    "melon"                => 0xf6857d,
    "peach"                => 0xf5bc89,
    "apricot"              => 0xf7ca83,
    "dandelion"            => 0xedd80b,
    "goldenrod"            => 0xeccc24,
    "olivegreen"           => 0x8aa845,
    "grannysmithapple"     => 0x5cbf64,
    "seagreen"             => 0x50cf9b,
    "skyblue"              => 0x47b0e3,
    "cornflower"           => 0x6590d8,
    "cadetblue"            => 0x7580a0,
    "cerulian"             => 0x0071cd,
    "purplemountainsmajesty"  => 0x8a6dc1,
    "wistera"              => 0xb681cf,
    "violetred"            => 0xe82362,
    "red"                  => 0xe32135,
    "scarlet"              => 0xed3825,
    "redorange"            => 0xf1612a,
    "orange"               => 0xf3770c,
    "yelloworange"         => 0xf59506,
    "macaroniandcheese"    => 0xf6a94b,
    "yellow"               => 0xebdd05,
    "greenyellow"          => 0xe2de2b,
    "springgreen"          => 0xc9d760,
    "yellowgreen"          => 0x84c82e,
    "green"                => 0x008846,
    "bluegreen"            => 0x0083ae,
    "blue"                 => 0x0345be,
    "indigo"               => 0x3c3591,
    "blueviolet"           => 0x5d3694,
    "violet"               => 0x79338d,
    "redviolet"            => 0xb32f79,
  };
}

1;

__END__
