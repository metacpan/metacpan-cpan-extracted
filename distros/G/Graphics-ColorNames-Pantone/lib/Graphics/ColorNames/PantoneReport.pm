

package Graphics::ColorNames::PantoneReport;

require 5.008;
use strict;
use warnings;

our $VERSION = '0.54';

sub NamesRgbTable {
    return {
    'marsala'             =>   0x955251,
    'radiandorchid'       =>   0xB565A7,
    'emerald'             =>   0x009B77,
    'tangerinetango'      =>   0xDD4124,
    'honeysucle'          =>   0xD65076,
    'turquoise'           =>   0x45B8AC,
    'mimosa'              =>   0xEFC050,
    'blueizis'            =>   0x5B5EA6,
    'chilipepper'         =>   0x9B2335,
    'sanddollar'          =>   0xDFCFBE,
    'blueturquoise'       =>   0x55B4B0,
    'tigerlily'           =>   0xE15D44,
    'aquasky'             =>   0x7FCDCD,
    'truered'             =>   0xBC243C,
    'fuchsiarose'         =>   0xC3447A,
    'ceruleanblue'        =>   0x98B4D4,
    'rosequartz'          =>   0xF7CAC9,
    'peachecho'           =>   0xF7786B,
    'serenity'            =>   0x91A8D0,
    'snorkelblue'         =>   0x034F84,
    'limpetshell'         =>   0x98DDDE,
    'lilacgrey'           =>   0x9896A4,
    'icedcoffee'          =>   0xB18F6A,
    'fiesta'              =>   0xDD4132,
    'buttercup'           =>   0xFAE03C,
    'greenflash'          =>   0x79C753,
    'riverside'           =>   0x4C6A92,
    'airyblue'            =>   0x92B6D5,
    'sharkskin'           =>   0x838487,
    'aurorared'           =>   0xB93A32,
    'warmtaupe'           =>   0xAF9483,
    'dustycedar'          =>   0xAD5D5D,
    'lushmeadow'          =>   0x006E51,
    'spicymustard'        =>   0xD8AE47,
    'pottersclay'         =>   0x9E4624,
    'bodacious'           =>   0xB76BA3,
    'niagara'             =>   0x578CA9,
    'primroseyellow'      =>   0xF6D155,
    'lapisblue'           =>   0x004B8D,
    'flame'               =>   0xF2552C,
    'islandparadise'      =>   0x95DEE3,
    'paledogwood'         =>   0xEDCDC2,
    'pinkyarrow'          =>   0xCE3175,
    'kale'                =>   0x5A7247,
    'hazelnut'            =>   0xCFB095,
    'grenadine'           =>   0xDC4C46,
    'tawnyport'           =>   0x672E3B,
    'balletslipper'       =>   0xF3D6E4,
    'butterum'            =>   0xC48F65,
    'navypeony'           =>   0x223A5E,
    'neutralgray'         =>   0x898E8C,
    'shadedspruce'        =>   0x005960,
    'goldenlime'          =>   0x9C9A40,
    'marina'              =>   0x4F84C4,
    'autumnmaple'         =>   0xD2691E,
    'meadowlark'          =>   0xECDB54,
    'cherrytomato'        =>   0xE94B3C,
    'littleboyblue'       =>   0x6F9FD8,
    'chilioil'            =>   0x944743,
    'pinklavender'        =>   0xDBB1CD,
    'bloomingdahlia'      =>   0xEC9787,
    'arcadia'             =>   0x00A591,
    'ultraviolet'         =>   0x6B5B95,
    'emperador'           =>   0x6C4F3D,
    'almostmauve'         =>   0xEADEDB,
    'springcrocus'        =>   0xBC70A4,
    'limepunc'            =>   0xBFD641,
    'sailorblue'          =>   0x2E4A62,
    'harbormist'          =>   0xB4B7BA,
    'warmsand'            =>   0xC0AB8E,
    'coconutmilk'         =>   0xF0EDE5,
    'redpear'             =>   0x7F4145,
    'valiantpoppy'        =>   0xBD3D3A,
    'nebulasblue'         =>   0x3F69AA,
    'ceylonyellow'        =>   0xD5AE41,
    'martiniolive'        =>   0x766F57,
    'russetorange'        =>   0xE47A2E,
    'crocuspetal'         =>   0xBE9EC9,
    'limelight'           =>   0xF1EA7F,
    'quetzalgreen'        =>   0x006E6D,
    'sargassosea'         =>   0x485167,
    'tofu'                =>   0xEAE6DA,
    'almondbuff'          =>   0xD1B894,
    'quietgray'           =>   0xBCBCBE,
    'meerkat'             =>   0xA9754F,
    'jesterred'           =>   0x9E1030,
    'turmeric'            =>   0xFE840E,
    'livingcoral'         =>   0xFF6F61,
    'pinkpeacock'         =>   0xC62168,
    'pepperstem'          =>   0x8D9440,
    'aspengold'           =>   0xFFD662,
    'princessblue'        =>   0x00539C,
    'toffee'              =>   0x755139,
    'mangomojito'         =>   0xD69C2F,
    'terrariummoss'       =>   0x616247,
    'sweetlilac'          =>   0xE8B5CE,
    'soybean'             =>   0xD2C29D,
    'eclipse'             =>   0x343148,
    'sweetcorn'           =>   0xF0EAD6,
    'browngranite'        =>   0x615550,
    'bikingred'           =>   0x77212E,
    'cremedepeche'        =>   0xF5D6C6,
    'peachpink'           =>   0xFA9A85,
    'rockyroad'           =>   0x5A3E36,
    'fruitdove'           =>   0xCE5B78,
    'sugaralmond'         =>   0x935529,
    'darkcheddar'         =>   0xE08119,
    'galaxyblue'          =>   0x2A4B7C,
    'bluestone'           =>   0x577284,
    'orangetiger'         =>   0xF96714,
    'eden'                =>   0x264E36,
    'vanillacustard'      =>   0xF3E0BE,
    'eveningblue'         =>   0x2A293E,
    'paloma'              =>   0x9F9C99,
    'guacamole'           =>   0x797B3A,
    'flamescarlet'        =>   0xCD212A,
    'saffron'             =>   0xFFA500,
    'biscaygreen'         =>   0x56C6A9,
    'chive'               =>   0x4B5335,
    'fadeddenim'          =>   0x798EA4,
    'orangepeel'          =>   0xFA7A35,
    'mosaicblue'          =>   0x00758F,
    'sunlight'            =>   0xEDD59E,
    'coralpink'           =>   0xE8A798,
    'cinnamonstic'        =>   0x9C4722,
    'grapecompote'        =>   0x6B5876,
    'lark'                =>   0xB89B72,
    'navyblazer'          =>   0x282D3C,
    'brilliantwhite'      =>   0xEDF1FF,
    'ash'                 =>   0xA09998,
    'amberglow'           =>   0xDC793E,
    'samba'               =>   0xA2242F,
    'sandstone'           =>   0xC48A69,
    'classicblue'         =>   0x34568B,
    'greensheen'          =>   0xD9CE52,
    'rosetan'             =>   0xD19C97,
    'ultramarinegreen'    =>   0x006B54,
    'firedbrick'          =>   0x6A2E2A,
    'peachnougat'         =>   0xE6AF91,
    'magentapurple'       =>   0x6C244C,
    'marigold'            =>   0xFDAC53,
    'cerulean'            =>   0x9BB7D4,
    'rust'                =>   0xB55A30,
    'illuminating'        =>   0xF5DF4D,
    'frenchblue'          =>   0x0072B5,
    'greenash'            =>   0xA0DAA9,
    'burntcoral'          =>   0xE9897E,
    'mint'                =>   0x00A170,
    'amethystorchid'      =>   0x926AA6,
    'raspberrysorbet'     =>   0xD2386C,
    'inkwell'             =>   0x363945,
    'ultimategray'        =>   0x96999b,
    'buttercream'         =>   0xEFE1CE,
    'desertmist'          =>   0xE0B589,
    'willow'              =>   0x9A8B4F,
    'veryperi'            =>   0x696aad,
    'spunsugar'           =>   0xb8deec, 
    'gossamerpink'        =>   0xf9c5c2,
    'innuendo'            =>   0xc43f66,
    'skydiver'            =>   0x1e609e,
    'daffodil'            =>   0xfdc04e,
    'glacierlake'         =>   0x84a2bb,
    'harborblue'          =>   0x16737f,
    'cocamocha'           =>   0x8c725f,
    'dahliamauve'         =>   0xa64f82,
    'poinciana'           =>   0xc94235,
    'snowwhite'           =>   0xf2f0eb,
    'perfectlypale'       =>   0xd5ccc1,
    'basil'               =>   0x829f82,
    'northerndroplet'     =>   0xbdc0bf,
    'poppyseed'           =>   0x66686c,
    'lavafalls'           =>   0x9f383a,
    'samoansun'           =>   0xf5cc72,
#    'orangetiger'         =>   0xfe7133, # selected twice
    'roseviolet'          =>   0xc15391,
    'amazon'              =>   0x1C734B,
    'nosegay'             =>   0xf0c0d8,
    'waterspout'          =>   0x93dbe0,
    'caramelcafe'         =>   0x8b5a3e,
    'midnight'            =>   0x315d78,
#    'martiniolive'        =>   0x776f57, # selected twice
    'arcticwolf'          =>   0xe6decf,
    'autumnblonde'        =>   0xf2d6b3,
    'polarnight'          =>   0x434550,
    'lodenfrost'          =>   0x758e77,
    'chiseledstone'       =>   0x8f8f93,
  };
}

1;

=encoding utf8

=head1 NAME

Graphics::ColorNames::PantoneReport - RGB values of Pantone Report colors

=head1 SYNOPSIS

  require Graphics::ColorNames::PantoneReport;

  $NameTable = Graphics::ColorNames::PantoneReport->NamesRgbTable();
  $RgbBlack  = $NameTable->{'airyblue'};

=head1 DESCRIPTION

See the documentation of L<Graphics::ColorNames> for information how to use
this module.

This module defines 184 names and associated RGB values of colors that were
part of the annual report of the I<Pantone Institute> from 2016 to 2022.
They reflect trends at the I<New York Fashion Week> and should not be
mistaken for the colors of the palette created by Pantone for Designers,
which can be accessed via L<Graphics::ColorNames::Pantone>. I choose 
TPX (TPG) over TCX values since ladder are specific to the textile industry 
and I assume usage of this module is monitor related. However, when no
TPX (TPG) available we took TCX, since I dont have the exact conversion
formula.

All names are lower case and do not contain space or apostrophes or other 
none ASCII characters - the originally named C<"Potter's Clay"> is
here C<"pottersclay"> and C<'Crème de Peche'> => C<'cremedepeche'>.
But you can actually access them as "Potters_Clay" and 'Creme_de_Peche'
because L<Graphics::ColorNames> does normalize names C<lc> and removing I<'_'>.


=head1 SEE ALSO

Pantone Report Colors L<https://www.w3schools.com/colors/colors_trends.asp>

Encycolorpedia L<https://encycolorpedia.com/>

=head1 AUTHOR

Herbert Breunung <lichtkind@cpan.org>

Based on L<Graphics::ColorNames::X> by Robert Rothenberg.

=head1 LICENSE

Copyright 2022 Herbert Breunung

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
