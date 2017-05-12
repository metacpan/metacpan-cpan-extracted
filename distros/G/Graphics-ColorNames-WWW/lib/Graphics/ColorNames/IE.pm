package Graphics::ColorNames::IE;

require 5.006;

use strict;
use warnings;

our $VERSION = '1.13';

sub NamesRgbTable() {
  use integer;
  return {
    (lc 'AliceBlue')		=> 0xF0F8FF,	# 240,248,255	
    (lc 'AntiqueWhite')		=> 0xFAEBD7,	# 250,235,215	
    (lc 'Aqua')			=> 0x00FFFF,	# 0,255,255	
    (lc 'Aquamarine')		=> 0x7FFFD4,	# 127,255,212	
    (lc 'Azure')		=> 0xF0FFFF,	# 240,255,255	
    (lc 'Beige')		=> 0xF5F5DC,	# 245,245,220	
    (lc 'Bisque')		=> 0xFFE4C4,	# 255,228,196	
    (lc 'Black')		=> 0x000000,	# 0,0,0	
    (lc 'BlanchedAlmond')	=> 0xFFEBCD,	# 255,235,205	
    (lc 'Blue')			=> 0x0000FF,	# 0,0,255	
    (lc 'BlueViolet')		=> 0x8A2BE2,	# 138,43,226	
    (lc 'Brown')		=> 0xA52A2A,	# 165,42,42	
    (lc 'BurlyWood')		=> 0xDEB887,	# 222,184,135	
    (lc 'CadetBlue')		=> 0x5F9EA0,	# 95,158,160	
    (lc 'Chartreuse')		=> 0x7FFF00,	# 127,255,0	
    (lc 'Chocolate')		=> 0xD2691E,	# 210,105,30	
    (lc 'Coral')		=> 0xFF7F50,	# 255,127,80	
    (lc 'CornflowerBlue')	=> 0x6495ED,	# 100,149,237	
    (lc 'Cornsilk')		=> 0xFFF8DC,	# 255,248,220	
    (lc 'Crimson')		=> 0xDC143C,	# 220,20,60	
    (lc 'Cyan')			=> 0x00FFFF,	# 0,255,255	
    (lc 'DarkBlue')		=> 0x00008B,	# 0,0,139	
    (lc 'DarkCyan')		=> 0x008B8B,	# 0,139,139	
    (lc 'DarkGoldenrod')	=> 0xB8860B,	# 184,134,11	
    (lc 'DarkGray')		=> 0xA9A9A9,	# 169,169,169	
    (lc 'DarkGreen')		=> 0x006400,	# 0,100,0	
    (lc 'DarkKhaki')		=> 0xBDB76B,	# 189,183,107	
    (lc 'DarkMagenta')		=> 0x8B008B,	# 139,0,139	
    (lc 'DarkOliveGreen')	=> 0x556B2F,	# 85,107,47	
    (lc 'DarkOrange')		=> 0xFF8C00,	# 255,140,0	
    (lc 'DarkOrchid')		=> 0x9932CC,	# 153,50,204	
    (lc 'DarkRed')		=> 0x8B0000,	# 139,0,0	
    (lc 'DarkSalmon')		=> 0xE9967A,	# 233,150,122	
    (lc 'DarkSeaGreen')		=> 0x8FBC8F,	# 143,188,143	
    (lc 'DarkSlateBlue')	=> 0x483D8B,	# 72,61,139	
    (lc 'DarkSlateGray')	=> 0x2F4F4F,	# 47,79,79	
    (lc 'DarkTurquoise')	=> 0x00CED1,	# 0,206,209	
    (lc 'DarkViolet')		=> 0x9400D3,	# 148,0,211	
    (lc 'DeepPink')		=> 0xFF1493,	# 255,20,147	
    (lc 'DeepSkyBlue')		=> 0x00BFFF,	# 0,191,255	
    (lc 'DimGray')		=> 0x696969,	# 105,105,105	
    (lc 'DodgerBlue')		=> 0x1E90FF,	# 30,144,255	
    (lc 'FireBrick')		=> 0xB22222,	# 178,34,34	
    (lc 'FloralWhite')		=> 0xFFFAF0,	# 255,250,240	
    (lc 'ForestGreen')		=> 0x228B22,	# 34,139,34	
    (lc 'Fuchsia')		=> 0xFF00FF,	# 255,0,255	
    (lc 'Gainsboro')		=> 0xDCDCDC,	# 220,220,220	
    (lc 'GhostWhite')		=> 0xF8F8FF,	# 248,248,255	
    (lc 'Gold')			=> 0xFFD700,	# 255,215,0	
    (lc 'Goldenrod')		=> 0xDAA520,	# 218,165,32	
    (lc 'Gray')			=> 0x808080,	# 128,128,128	## NB: Grey is missing!
    (lc 'Green')		=> 0x008000,	# 0,128,0	
    (lc 'GreenYellow')		=> 0xADFF2F,	# 173,255,47	
    (lc 'Honeydew')		=> 0xF0FFF0,	# 240,255,240	
    (lc 'HotPink')		=> 0xFF69B4,	# 255,105,180	
    (lc 'IndianRed')		=> 0xCD5C5C,	# 205,92,92	
    (lc 'Indigo')		=> 0x4B0082,	# 75,0,130	
    (lc 'Ivory')		=> 0xFFFFF0,	# 255,255,240	
    (lc 'Khaki')		=> 0xF0E68C,	# 240,230,140	
    (lc 'Lavender')		=> 0xE6E6FA,	# 230,230,250	
    (lc 'LavenderBlush')	=> 0xFFF0F5,	# 255,240,245	
    (lc 'LawnGreen')		=> 0x7CFC00,	# 124,252,0	
    (lc 'LemonChiffon')		=> 0xFFFACD,	# 255,250,205	
    (lc 'LightBlue')		=> 0xADD8E6,	# 173,216,230	
    (lc 'LightCoral')		=> 0xF08080,	# 240,128,128	
    (lc 'LightCyan')		=> 0xE0FFFF,	# 224,255,255	
    (lc 'LightGoldenrodYellow')	=> 0xFAFAD2,	# 250,250,210	
    (lc 'LightGreen')		=> 0x90EE90,	# 144,238,144	
    (lc 'LightGrey')		=> 0xD3D3D3,	# 211,211,211	
    (lc 'LightPink')		=> 0xFFB6C1,	# 255,182,193	
    (lc 'LightSalmon')		=> 0xFFA07A,	# 255,160,122	
    (lc 'LightSeaGreen')	=> 0x20B2AA,	# 32,178,170	
    (lc 'LightSkyBlue')		=> 0x87CEFA,	# 135,206,250	
    (lc 'LightSlateGray')	=> 0x778899,	# 119,136,153	
    (lc 'LightSteelBlue')	=> 0xB0C4DE,	# 176,196,222	
    (lc 'LightYellow')		=> 0xFFFFE0,	# 255,255,224	
    (lc 'Lime')			=> 0x00FF00,	# 0,255,0	
    (lc 'LimeGreen')		=> 0x32CD32,	# 50,205,50	
    (lc 'Linen')		=> 0xFAF0E6,	# 250,240,230	
    (lc 'Magenta')		=> 0xFF00FF,	# 255,0,255	
    (lc 'Maroon')		=> 0x800000,	# 128,0,0	
    (lc 'MediumAquamarine')	=> 0x66CDAA,	# 102,205,170	
    (lc 'MediumBlue')		=> 0x0000CD,	# 0,0,205	
    (lc 'MediumOrchid')		=> 0xBA55D3,	# 186,85,211	
    (lc 'MediumPurple')		=> 0x9370DB,	# 147,112,219	
    (lc 'MediumSeaGreen')	=> 0x3CB371,	# 60,179,113	
    (lc 'MediumSlateBlue')	=> 0x7B68EE,	# 123,104,238	
    (lc 'MediumSpringGreen')	=> 0x00FA9A,	# 0,250,154	
    (lc 'MediumTurquoise')	=> 0x48D1CC,	# 72,209,204	
    (lc 'MediumVioletRed')	=> 0xC71585,	# 199,21,133	
    (lc 'MidnightBlue')		=> 0x191970,	# 25,25,112	
    (lc 'MintCream')		=> 0xF5FFFA,	# 245,255,250	
    (lc 'MistyRose')		=> 0xFFE4E1,	# 255,228,225	
    (lc 'Moccasin')		=> 0xFFE4B5,	# 255,228,181	
    (lc 'NavajoWhite')		=> 0xFFDEAD,	# 255,222,173	
    (lc 'Navy')			=> 0x000080,	# 0,0,128	
    (lc 'OldLace')		=> 0xFDF5E6,	# 253,245,230	
    (lc 'Olive')		=> 0x808000,	# 128,128,0	
    (lc 'OliveDrab')		=> 0x6B8E23,	# 107,142,35	
    (lc 'Orange')		=> 0xFFA500,	# 255,165,0	
    (lc 'OrangeRed')		=> 0xFF4500,	# 255,69,0	
    (lc 'Orchid')		=> 0xDA70D6,	# 218,112,214	
    (lc 'PaleGoldenrod')	=> 0xEEE8AA,	# 238,232,170	
    (lc 'PaleGreen')		=> 0x98FB98,	# 152,251,152	
    (lc 'PaleTurquoise')	=> 0xAFEEEE,	# 175,238,238	
    (lc 'PaleVioletRed')	=> 0xDB7093,	# 219,112,147	
    (lc 'PapayaWhip')		=> 0xFFEFD5,	# 255,239,213	
    (lc 'PeachPuff')		=> 0xFFDAB9,	# 255,218,185	
    (lc 'Peru')			=> 0xCD853F,	# 205,133,63	
    (lc 'Pink')			=> 0xFFC0CB,	# 255,192,203	
    (lc 'Plum')			=> 0xDDA0DD,	# 221,160,221	
    (lc 'PowderBlue')		=> 0xB0E0E6,	# 176,224,230	
    (lc 'Purple')		=> 0x800080,	# 128,0,128	
    (lc 'Red')			=> 0xFF0000,	# 255,0,0	
    (lc 'RosyBrown')		=> 0xBC8F8F,	# 188,143,143	
    (lc 'RoyalBlue')		=> 0x4169E1,	# 65,105,225	
    (lc 'SaddleBrown')		=> 0x8B4513,	# 139,69,19	
    (lc 'Salmon')		=> 0xFA8072,	# 250,128,114	
    (lc 'SandyBrown')		=> 0xF4A460,	# 244,164,96	
    (lc 'SeaGreen')		=> 0x2E8B57,	# 46,139,87	
    (lc 'Seashell')		=> 0xFFF5EE,	# 255,245,238	
    (lc 'Sienna')		=> 0xA0522D,	# 160,82,45	
    (lc 'Silver')		=> 0xC0C0C0,	# 192,192,192	
    (lc 'SkyBlue')		=> 0x87CEEB,	# 135,206,235	
    (lc 'SlateBlue')		=> 0x6A5ACD,	# 106,90,205	
    (lc 'SlateGray')		=> 0x708090,	# 112,128,144	
    (lc 'Snow')			=> 0xFFFAFA,	# 255,250,250	
    (lc 'SpringGreen')		=> 0x00FF7F,	# 0,255,127	
    (lc 'SteelBlue')		=> 0x4682B4,	# 70,130,180	
    (lc 'Tan')			=> 0xD2B48C,	# 210,180,140	
    (lc 'Teal')			=> 0x008080,	# 0,128,128	
    (lc 'Thistle')		=> 0xD8BFD8,	# 216,191,216	
    (lc 'Tomato')		=> 0xFF6347,	# 255,99,71	
    (lc 'Turquoise')		=> 0x40E0D0,	# 64,224,208	
    (lc 'Violet')		=> 0xEE82EE,	# 238,130,238	
    (lc 'Wheat')		=> 0xF5DEB3,	# 245,222,179	
    (lc 'White')		=> 0xFFFFFF,	# 255,255,255	
    (lc 'WhiteSmoke')		=> 0xF5F5F5,	# 245,245,245	
    (lc 'Yellow')		=> 0xFFFF00,	# 255,255,0	
    (lc 'YellowGreen')		=> 0x9ACD32,	# 154,205,50
  };
}

1;

=head1 NAME

Graphics::ColorNames::IE - MS Internet Explorer color names and equivalent RGB values

=head1 SYNOPSIS

  require Graphics::ColorNames::IE;

  $NameTable = Graphics::ColorNames::IE->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values recognized by
Microsoft Internet Explorer.

This currently is a subset of the colors defined by CSS and SVG specifications.

See the documentation of L<Graphics::ColorNames> for information how to use
this module.

=head2 NOTE

Although Microsoft calls them "X11 color names", some of them are not identical
to the definitions in the X Specification.

=head1 SEE ALSO

C<Graphics::ColorNames::WWW>, MSDN <http://msdn.microsoft.com/library/en-us/dnwebgen/html/X11_names.asp>

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

Based on C<Graphics::ColorNames::HTML> by Robert Rothenberg.

=head1 LICENSE

Copyright 2005-2009 Claus FE<auml>rber.

Copyright 2001-2004 Robert Rothenberg.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
