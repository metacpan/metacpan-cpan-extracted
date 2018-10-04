package Graphics::ColorNames::Netscape;

use v5.6;

# ABSTRACT: Netscape 1.1 Color Names


use strict;
use warnings;

# RECOMMEND PREREQ: Graphics::ColorNames

our $VERSION = 'v3.1.2';

sub NamesRgbTable() {
    use integer;
    return {
        "white"              => 0xffffff,
        "red"                => 0xff0000,
        "green"              => 0x00ff00,
        "blue"               => 0x0000ff,
        "magenta"            => 0xff00ff,
        "cyan"               => 0x00ffff,
        "yellow"             => 0xffff00,
        "black"              => 0x000000,
        "aquamarine"         => 0x70db93,
        "bakerschocolate"    => 0x5c3317,
        "blueviolet"         => 0x9f5f9f,
        "brass"              => 0xb5a642,
        "brightgold"         => 0xd9d919,
        "brown"              => 0xa62a2a,
        "bronze"             => 0x8c7853,
        "bronzeii"           => 0xa67d3d,
        "cadetblue"          => 0x5f9f9f,
        "coolcopper"         => 0xd98719,
        "copper"             => 0xb87333,
        "coral"              => 0xff7f00,
        "cornflowerblue"     => 0x42426f,
        "darkbrown"          => 0x5c4033,
        "darkgreen"          => 0x2f4f2f,
        "darkgreencopper"    => 0x4a766e,
        "darkolivegreen"     => 0x4f4f2f,
        "darkorchid"         => 0x9932cd,
        "darkpurple"         => 0x871f78,
        "darkslateblue"      => 0x241882,
        "darkslategrey"      => 0x2f4f4f,
        "darktan"            => 0x97694f,
        "darkturquoise"      => 0x7093db,
        "darkwood"           => 0x855e42,
        "dimgrey"            => 0x545454,
        "dustyrose"          => 0x856363,
        "feldspar"           => 0xd19275,
        "firebrick"          => 0x8e2323,
        "flesh"              => 0xf5ccb0,
        "forestgreen"        => 0x238e23,
        "gold"               => 0xcd7f32,    #
        "goldenrod"          => 0xdbdb70,
        "grey"               => 0x545454,
        "greencopper"        => 0x856363,
        "greenyellow"        => 0xd19275,
        "huntergreen"        => 0x8e2323,
        "indianred"          => 0xf5ccb0,
        "khaki"              => 0x238e23,
        "lightblue"          => 0xcdd9d9,    #
        "lightgrey"          => 0xdbdb70,
        "lightsteelblue"     => 0x545454,
        "lightwood"          => 0x856363,
        "limegreen"          => 0xd19275,
        "mandarianorange"    => 0x8e2323,
        "maroon"             => 0xf5ccb0,
        "mediumaquamarine"   => 0x238e23,
        "mediumblue"         => 0x3232cd,    #
        "mediumforestgreen"  => 0xdbdb70,
        "mediumgoldenrod"    => 0xeaeaae,
        "mediumorchid"       => 0x9370db,
        "mediumseagreen"     => 0x426f42,
        "mediumslateblue"    => 0x7f00ff,
        "mediumspringgreen"  => 0x7fff00,
        "mediumturquoise"    => 0x70dbdb,
        "mediumvioletred"    => 0xdb7093,
        "mediumwood"         => 0xa68064,
        "midnightblue"       => 0x2f2f4f,
        "navyblue"           => 0x23238e,
        "neonblue"           => 0x4d4dff,
        "neonpink"           => 0xff6ec7,
        "newmidnightblue"    => 0x00009c,
        "newtan"             => 0xebc79e,
        "oldgold"            => 0xcfb53b,
        "orange"             => 0xff7f00,
        "orangered"          => 0xff2400,
        "orchid"             => 0xdb70db,
        "palegreen"          => 0x8fbc8f,
        "pink"               => 0xbc8f8f,
        "plum"               => 0xeaadea,
        "quartz"             => 0xd9d9f3,
        "richblue"           => 0x5959ab,
        "salmon"             => 0x6f4242,
        "scarlet"            => 0x8c1717,
        "seagreen"           => 0x238e68,
        "semisweetchocolate" => 0x6b4226,
        "sienna"             => 0x8e6b23,
        "silver"             => 0xe6e8fa,
        "skyblue"            => 0x3299cc,
        "slateblue"          => 0x007fff,
        "spicypink"          => 0xff1cae,
        "springgreen"        => 0x00ff7f,
        "steelblue"          => 0x236b8e,
        "summersky"          => 0x38b0de,
        "tan"                => 0xdb9370,
        "thistle"            => 0xd8bfd8,
        "turquoise"          => 0xadeaea,
        "verydarkbrown"      => 0x5c4033,
        "verylightgrey"      => 0xcdcdcd,
        "violet"             => 0x4f2f4f,
        "violetred"          => 0xcc3299,
        "wheat"              => 0xd8d8bf,
        "yellowgreen"        => 0x99cc32,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNames::Netscape - Netscape 1.1 Color Names

=head1 VERSION

version v3.1.2

=head1 SYNOPSIS

  require Graphics::ColorNames::Netscape;

  $NameTable = Graphics::ColorNames::Netscape->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values associated
with Netscape 1.1 (I cannot determine whether they were once usable in
Netscape or were arbitrary names for RGB values-- I<many of these names are
not recognized by later versions of Netscape>).

This scheme is deprecated, but is provided as a separate release
from L<Graphics::ColorNames> for backwards compatability.

=head1 SEE ALSO

L<Graphics::ColorNames>

L<Graphics::ColorNames::Mozilla>

L<Graphics::ColorNames::IE>

L<Graphics::ColorNames::SVG>

The color names come from
L<https://web.archive.org/web/20001211143800/http://home1.netscape.com/home/bg/colorindex.html>.

Corrections to errors in the Netscape spec are due to
L<http://www.he.net/info/color/>.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Graphics-ColorNames-Netscape>
and may be cloned from L<git://github.com/robrwo/Graphics-ColorNames-Netscape.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Graphics-ColorNames-Netscape/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Magnus Cedergren Gary Vollink Slaven Rezić

=over 4

=item *

Magnus Cedergren <magnus@mbox604.swipnet.se>

=item *

Gary Vollink <gary@vollink.com>

=item *

Slaven Rezić <slaven@rezic.de>

=back

=head1 COPYRIGHT AND LICENSE


Robert Rothenberg has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
