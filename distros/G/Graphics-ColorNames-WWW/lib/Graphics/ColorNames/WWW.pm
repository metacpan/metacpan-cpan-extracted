package Graphics::ColorNames::WWW;

require 5.006;

use strict;
use warnings;

our $VERSION = '1.13';

sub NamesRgbTable() {
  sub _mk_rgb { ($_[0] << 16) + ($_[1] << 8) + ($_[2]) }
  use integer;
  return {
    'aliceblue'		=> _mk_rgb(240, 248, 255),
    'antiquewhite'	=> _mk_rgb(250, 235, 215),
    'aqua'		=> _mk_rgb( 0, 255, 255),
    'aquamarine'	=> _mk_rgb(127, 255, 212),
    'azure'		=> _mk_rgb(240, 255, 255),
    'beige'		=> _mk_rgb(245, 245, 220),
    'bisque'		=> _mk_rgb(255, 228, 196),
    'black'		=> _mk_rgb( 0, 0, 0),
    'blanchedalmond'	=> _mk_rgb(255, 235, 205),
    'blue'		=> _mk_rgb( 0, 0, 255),
    'blueviolet'	=> _mk_rgb(138, 43, 226),
    'brown'		=> _mk_rgb(165, 42, 42),
    'burlywood'		=> _mk_rgb(222, 184, 135),
    'cadetblue'		=> _mk_rgb( 95, 158, 160),
    'chartreuse'	=> _mk_rgb(127, 255, 0),
    'chocolate'		=> _mk_rgb(210, 105, 30),
    'coral'		=> _mk_rgb(255, 127, 80),
    'cornflowerblue'	=> _mk_rgb(100, 149, 237),
    'cornsilk'		=> _mk_rgb(255, 248, 220),
    'crimson'		=> _mk_rgb(220, 20, 60),
    'cyan'		=> _mk_rgb( 0, 255, 255),
    'darkblue'		=> _mk_rgb( 0, 0, 139),
    'darkcyan'		=> _mk_rgb( 0, 139, 139),
    'darkgoldenrod'	=> _mk_rgb(184, 134, 11),
    'darkgray'		=> _mk_rgb(169, 169, 169),
    'darkgreen'		=> _mk_rgb( 0, 100, 0),
    'darkgrey'		=> _mk_rgb(169, 169, 169),
    'darkkhaki'		=> _mk_rgb(189, 183, 107),
    'darkmagenta'	=> _mk_rgb(139, 0, 139),
    'darkolivegreen'	=> _mk_rgb( 85, 107, 47),
    'darkorange'	=> _mk_rgb(255, 140, 0),
    'darkorchid'	=> _mk_rgb(153, 50, 204),
    'darkred'		=> _mk_rgb(139, 0, 0),
    'darksalmon'	=> _mk_rgb(233, 150, 122),
    'darkseagreen'	=> _mk_rgb(143, 188, 143),
    'darkslateblue'	=> _mk_rgb( 72, 61, 139),
    'darkslategray'	=> _mk_rgb( 47, 79, 79),
    'darkslategrey'	=> _mk_rgb( 47, 79, 79),
    'darkturquoise'	=> _mk_rgb( 0, 206, 209),
    'darkviolet'	=> _mk_rgb(148, 0, 211),
    'deeppink'		=> _mk_rgb(255, 20, 147),
    'deepskyblue'	=> _mk_rgb( 0, 191, 255),
    'dimgray'		=> _mk_rgb(105, 105, 105),
    'dimgrey'		=> _mk_rgb(105, 105, 105),
    'dodgerblue'	=> _mk_rgb( 30, 144, 255),
    'firebrick'		=> _mk_rgb(178, 34, 34),
    'floralwhite'	=> _mk_rgb(255, 250, 240),
    'forestgreen'	=> _mk_rgb( 34, 139, 34),
    'fuchsia'	        => 0xff00ff, # "fuscia" is incorrect but common
    'fuscia'            => 0xff00ff, # mis-spelling...
    'gainsboro'		=> _mk_rgb(220, 220, 220),
    'ghostwhite'	=> _mk_rgb(248, 248, 255),
    'gold'		=> _mk_rgb(255, 215, 0),
    'goldenrod'		=> _mk_rgb(218, 165, 32),
    'gray'		=> _mk_rgb(128, 128, 128),
    'grey'		=> _mk_rgb(128, 128, 128),
    'green'		=> _mk_rgb( 0, 128, 0),
    'greenyellow'	=> _mk_rgb(173, 255, 47),
    'honeydew'		=> _mk_rgb(240, 255, 240),
    'hotpink'		=> _mk_rgb(255, 105, 180),
    'indianred'		=> _mk_rgb(205, 92, 92),
    'indigo'		=> _mk_rgb( 75, 0, 130),
    'ivory'		=> _mk_rgb(255, 255, 240),
    'khaki'		=> _mk_rgb(240, 230, 140),
    'lavender'		=> _mk_rgb(230, 230, 250),
    'lavenderblush'	=> _mk_rgb(255, 240, 245),
    'lawngreen'		=> _mk_rgb(124, 252, 0),
    'lemonchiffon'	=> _mk_rgb(255, 250, 205),
    'lightblue'		=> _mk_rgb(173, 216, 230),
    'lightcoral'	=> _mk_rgb(240, 128, 128),
    'lightcyan'		=> _mk_rgb(224, 255, 255),
    'lightgoldenrodyellow' => _mk_rgb(250, 250, 210),
    'lightgray'		=> _mk_rgb(211, 211, 211),
    'lightgreen'	=> _mk_rgb(144, 238, 144),
    'lightgrey'		=> _mk_rgb(211, 211, 211),
    'lightpink'		=> _mk_rgb(255, 182, 193),
    'lightsalmon'	=> _mk_rgb(255, 160, 122),
    'lightseagreen'	=> _mk_rgb( 32, 178, 170),
    'lightskyblue'	=> _mk_rgb(135, 206, 250),
    'lightslategray'	=> _mk_rgb(119, 136, 153),
    'lightslategrey'	=> _mk_rgb(119, 136, 153),
    'lightsteelblue'	=> _mk_rgb(176, 196, 222),
    'lightyellow'	=> _mk_rgb(255, 255, 224),
    'lime'		=> _mk_rgb( 0, 255, 0),
    'limegreen'		=> _mk_rgb( 50, 205, 50),
    'linen'		=> _mk_rgb(250, 240, 230),
    'magenta'		=> _mk_rgb(255, 0, 255),
    'maroon'		=> _mk_rgb(128, 0, 0),
    'mediumaquamarine'	=> _mk_rgb(102, 205, 170),
    'mediumblue'	=> _mk_rgb( 0, 0, 205),
    'mediumorchid'	=> _mk_rgb(186, 85, 211),
    'mediumpurple'	=> _mk_rgb(147, 112, 219),
    'mediumseagreen'	=> _mk_rgb( 60, 179, 113),
    'mediumslateblue'	=> _mk_rgb(123, 104, 238),
    'mediumspringgreen'	=> _mk_rgb( 0, 250, 154),
    'mediumturquoise'	=> _mk_rgb( 72, 209, 204),
    'mediumvioletred'	=> _mk_rgb(199, 21, 133),
    'midnightblue'	=> _mk_rgb( 25, 25, 112),
    'mintcream'		=> _mk_rgb(245, 255, 250),
    'mistyrose'		=> _mk_rgb(255, 228, 225),
    'moccasin'		=> _mk_rgb(255, 228, 181),
    'navajowhite'	=> _mk_rgb(255, 222, 173),
    'navy'		=> _mk_rgb( 0, 0, 128),
    'oldlace'		=> _mk_rgb(253, 245, 230),
    'olive'		=> _mk_rgb(128, 128, 0),
    'olivedrab'		=> _mk_rgb(107, 142, 35),
    'orange'		=> _mk_rgb(255, 165, 0),
    'orangered'		=> _mk_rgb(255, 69, 0),
    'orchid'		=> _mk_rgb(218, 112, 214),
    'palegoldenrod'	=> _mk_rgb(238, 232, 170),
    'palegreen'		=> _mk_rgb(152, 251, 152),
    'paleturquoise'	=> _mk_rgb(175, 238, 238),
    'palevioletred'	=> _mk_rgb(219, 112, 147),
    'papayawhip'	=> _mk_rgb(255, 239, 213),
    'peachpuff'		=> _mk_rgb(255, 218, 185),
    'peru'		=> _mk_rgb(205, 133, 63),
    'pink'		=> _mk_rgb(255, 192, 203),
    'plum'		=> _mk_rgb(221, 160, 221),
    'powderblue'	=> _mk_rgb(176, 224, 230),
    'purple'		=> _mk_rgb(128, 0, 128),
    'red'		=> _mk_rgb(255, 0, 0),
    'rosybrown'		=> _mk_rgb(188, 143, 143),
    'royalblue'		=> _mk_rgb( 65, 105, 225),
    'saddlebrown'	=> _mk_rgb(139, 69, 19),
    'salmon'		=> _mk_rgb(250, 128, 114),
    'sandybrown'	=> _mk_rgb(244, 164, 96),
    'seagreen'		=> _mk_rgb( 46, 139, 87),
    'seashell'		=> _mk_rgb(255, 245, 238),
    'sienna'		=> _mk_rgb(160, 82, 45),
    'silver'		=> _mk_rgb(192, 192, 192),
    'skyblue'		=> _mk_rgb(135, 206, 235),
    'slateblue'		=> _mk_rgb(106, 90, 205),
    'slategray'		=> _mk_rgb(112, 128, 144),
    'slategrey'		=> _mk_rgb(112, 128, 144),
    'snow'		=> _mk_rgb(255, 250, 250),
    'springgreen'	=> _mk_rgb( 0, 255, 127),
    'steelblue'		=> _mk_rgb( 70, 130, 180),
    'tan'		=> _mk_rgb(210, 180, 140),
    'teal'		=> _mk_rgb( 0, 128, 128),
    'thistle'		=> _mk_rgb(216, 191, 216),
    'tomato'		=> _mk_rgb(255, 99, 71),
    'turquoise'		=> _mk_rgb( 64, 224, 208),
    'violet'		=> _mk_rgb(238, 130, 238),
    'wheat'		=> _mk_rgb(245, 222, 179),
    'white'		=> _mk_rgb(255, 255, 255),
    'whitesmoke'	=> _mk_rgb(245, 245, 245),
    'yellow'		=> _mk_rgb(255, 255, 0),
    'yellowgreen'	=> _mk_rgb(154, 205, 50),
  };
}

1;

=head1 NAME

Graphics::ColorNames::WWW - WWW color names and equivalent RGB values

=head1 SYNOPSIS

  require Graphics::ColorNames::WWW;

  $NameTable = Graphics::ColorNames::WWW->NamesRgbTable();
  $RgbBlack  = $NameTable->{black};

=head1 DESCRIPTION

This module defines color names and their associated RGB values from various
WWW specifications, such as SVG or CSS as well as common browser
implementations.

See the documentation of L<Graphics::ColorNames> for information how to use
this module.

Currently, SVG and CSS define the same color keywords and include all color
keywords supported by common web browsers. Therefore, the modules
Graphics::ColorNames::WWW, L<Graphics::ColorNames::SVG> and
L<Graphics::ColorNames::CSS> behave in identical ways. 

This may change if the specs should happen to diverge; then this module will
become a superset of all color keywords defined by W3C's specs.

It is recommended to use this module unless you require exact compatibility
with the CSS and SVG specifications or specific browsers.

=head2 NOTE

Reportedly "fuchsia" was misspelled "fuscia" in an unidentified HTML
specification. It also appears to be a common misspelling, so both names are
recognized.

=head1 LIMITATIONS

The C<transparent> keyword is unsupported. Currently, Graphics::ColorNames does
not allow RGBA values.

Further, the system color keywords are not assigned to a fixed RGB value and
thus unsupported: C<ActiveBorder>, C<ActiveCaption>, C<AppWorkspace>,
C<Background>, C<ButtonFace>, C<ButtonHighlight>, C<ButtonShadow>,
C<ButtonText>, C<CaptionText>, C<GrayText>, C<Highlight>, C<HighlightText>,
C<InactiveBorder>, C<InactiveCaption>, C<InactiveCaptionText>,
C<InfoBackground>, C<InfoText>, C<Menu>, C<MenuText>, C<Scrollbar>,
C<ThreeDDarkShadow>, C<ThreeDFace>, C<ThreeDHighlight>, C<ThreeDLightShadow>,
C<ThreeDShadow>, C<Window>, C<WindowFrame>, C<WindowText> (these are deprecated
in CSS3)

=head1 SEE ALSO

L<Graphics::ColorNames::HTML>, L<Graphics::ColorNames::CSS>,
L<Graphics::ColorNames::SVG>

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

Based on C<Graphics::ColorNames::HTML> by Robert Rothenberg.

=head1 LICENSE

Copyright 2005-2009 Claus FE<auml>rber.

Copyright 2001-2004 Robert Rothenberg.

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl
itself.

=cut
