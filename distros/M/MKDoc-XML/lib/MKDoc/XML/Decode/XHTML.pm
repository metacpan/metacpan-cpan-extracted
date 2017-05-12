package MKDoc::XML::Decode::XHTML;
use warnings;
use strict;


# Portions (c) International Organization for Standardization 1986:
# Permission to copy in any form is granted for use with conforming SGML
# systems and applications as defined in ISO 8879, provided this notice is
# included in all copies.
our %ENTITY_2_CHAR = (
    
    # Latin1 characters
    'nbsp'     => chr(160),
    'iexcl'    => chr(161),
    'cent'     => chr(162),
    'pound'    => chr(163),
    'curren'   => chr(164),
    'yen'      => chr(165),
    'brvbar'   => chr(166),
    'sect'     => chr(167),
    'uml'      => chr(168),
    'copy'     => chr(169),
    'ordf'     => chr(170),
    'laquo'    => chr(171),
    'not'      => chr(172),
    'shy'      => chr(173),
    'reg'      => chr(174),
    'macr'     => chr(175),
    'deg'      => chr(176),
    'plusmn'   => chr(177),
    'sup2'     => chr(178),
    'sup3'     => chr(179),
    'acute'    => chr(180),
    'micro'    => chr(181),
    'para'     => chr(182),
    'middot'   => chr(183),
    'cedil'    => chr(184),
    'sup1'     => chr(185),
    'ordm'     => chr(186),
    'raquo'    => chr(187),
    'frac14'   => chr(188),
    'frac12'   => chr(189),
    'frac34'   => chr(190),
    'iquest'   => chr(191),
    'Agrave'   => chr(192),
    'Aacute'   => chr(193),
    'Acirc'    => chr(194),
    'Atilde'   => chr(195),
    'Auml'     => chr(196),
    'Aring'    => chr(197),
    'AElig'    => chr(198),
    'Ccedil'   => chr(199),
    'Egrave'   => chr(200),
    'Eacute'   => chr(201),
    'Ecirc'    => chr(202),
    'Euml'     => chr(203),
    'Igrave'   => chr(204),
    'Iacute'   => chr(205),
    'Icirc'    => chr(206),
    'Iuml'     => chr(207),
    'ETH'      => chr(208),
    'Ntilde'   => chr(209),
    'Ograve'   => chr(210),
    'Oacute'   => chr(211),
    'Ocirc'    => chr(212),
    'Otilde'   => chr(213),
    'Ouml'     => chr(214),
    'times'    => chr(215),
    'Oslash'   => chr(216),
    'Ugrave'   => chr(217),
    'Uacute'   => chr(218),
    'Ucirc'    => chr(219),
    'Uuml'     => chr(220),
    'Yacute'   => chr(221),
    'THORN'    => chr(222),
    'szlig'    => chr(223),
    'agrave'   => chr(224),
    'aacute'   => chr(225),
    'acirc'    => chr(226),
    'atilde'   => chr(227),
    'auml'     => chr(228),
    'aring'    => chr(229),
    'aelig'    => chr(230),
    'ccedil'   => chr(231),
    'egrave'   => chr(232),
    'eacute'   => chr(233),
    'ecirc'    => chr(234),
    'euml'     => chr(235),
    'igrave'   => chr(236),
    'iacute'   => chr(237),
    'icirc'    => chr(238),
    'iuml'     => chr(239),
    'eth'      => chr(240),
    'ntilde'   => chr(241),
    'ograve'   => chr(242),
    'oacute'   => chr(243),
    'ocirc'    => chr(244),
    'otilde'   => chr(245),
    'ouml'     => chr(246),
    'divide'   => chr(247),
    'oslash'   => chr(248),
    'ugrave'   => chr(249),
    'uacute'   => chr(250),
    'ucirc'    => chr(251),
    'uuml'     => chr(252),
    'yacute'   => chr(253),
    'thorn'    => chr(254),
    'yuml'     => chr(255),
    
    # C0 Controls and Basic Latin
    # 'quot' => chr(34),
    # 'amp' => chr(38),
    # 'apos' => chr(39),
    # 'lt' => chr(60),
    # 'gt' => chr(62),
    
    # Latin Extended-A
    'OElig'    => chr(338),
    'oelig'    => chr(339),
    'Scaron'   => chr(352),
    'scaron'   => chr(353),
    'Yuml'     => chr(376),
    
    # Spacin g Modifier Letters
    'circ'     => chr(710),
    'tilde'    => chr(732),
    
    # General Punctuation
    # * lsaquo is proposed but not yet ISO standardized
    # * rsaquo is proposed but not yet ISO standardized 
    'ensp'     => chr(8194),
    'emsp'     => chr(8195),
    'thinsp'   => chr(8201),
    'zwnj'     => chr(8204),
    'zwj'      => chr(8205),
    'lrm'      => chr(8206),
    'rlm'      => chr(8207),
    'ndash'    => chr(8211),
    'mdash'    => chr(8212),
    'lsquo'    => chr(8216),
    'rsquo'    => chr(8217),
    'sbquo'    => chr(8218),
    'ldquo'    => chr(8220),
    'rdquo'    => chr(8221),
    'bdquo'    => chr(8222),
    'dagger'   => chr(8224),
    'Dagger'   => chr(8225),
    'permil'   => chr(8240),
    'lsaquo'   => chr(8249),
    'rsaquo'   => chr(8250),
    'euro'     => chr(8364),
    
    # Mathematical, Greek and Symbolic characters for HTML
    # Latin Extended-B
    'fnof'     => chr(402),
    
    # Greek
    # * there is no Sigmaf, and no U+03A2 character either 
    'Alpha'    => chr(913),
    'Beta'     => chr(914),
    'Gamma'    => chr(915),
    'Delta'    => chr(916),
    'Epsilon'  => chr(917),
    'Zeta'     => chr(918),
    'Eta'      => chr(919),
    'Theta'    => chr(920),
    'Iota'     => chr(921),
    'Kappa'    => chr(922),
    'Lambda'   => chr(923),
    'Mu'       => chr(924),
    'Nu'       => chr(925),
    'Xi'       => chr(926),
    'Omicron'  => chr(927),
    'Pi'       => chr(928),
    'Rho'      => chr(929),
    'Sigma'    => chr(931),
    'Tau'      => chr(932),
    'Upsilon'  => chr(933),
    'Phi'      => chr(934),
    'Chi'      => chr(935),
    'Psi'      => chr(936),
    'Omega'    => chr(937),
    'alpha'    => chr(945),
    'beta'     => chr(946),
    'gamma'    => chr(947),
    'delta'    => chr(948),
    'epsilon'  => chr(949),
    'zeta'     => chr(950),
    'eta'      => chr(951),
    'theta'    => chr(952),
    'iota'     => chr(953),
    'kappa'    => chr(954),
    'lambda'   => chr(955),
    'mu'       => chr(956),
    'nu'       => chr(957),
    'xi'       => chr(958),
    'omicron'  => chr(959),
    'pi'       => chr(960),
    'rho'      => chr(961),
    'sigmaf'   => chr(962),
    'sigma'    => chr(963),
    'tau'      => chr(964),
    'upsilon'  => chr(965),
    'phi'      => chr(966),
    'chi'      => chr(967),
    'psi'      => chr(968),
    'omega'    => chr(969),
    'thetasym' => chr(977),
    'upsih'    => chr(978),
    'piv'      => chr(982),
    
    # General Punctuation
    # * bullet is NOT the same as bullet operator, U+2219
    'bull'     => chr(8226),
    'hellip'   => chr(8230),
    'prime'    => chr(8242),
    'Prime'    => chr(8243),
    'oline'    => chr(8254),
    'frasl'    => chr(8260),
    
    # Letterlike Symbols
    # * alef symbol is NOT the same as hebrew letter alef, U+05D0 although the same glyph could be used to depict both characters
    'weierp'   => chr(8472),
    'image'    => chr(8465),
    'real'     => chr(8476),
    'trade'    => chr(8482),
    'alefsym'  => chr(8501),
    
    # Arrows
    # * Unicode does not say that lArr is the same as the 'is implied by' arrow but also
    # does not have any other character for that function. So ? lArr can be used for 'is implied by' as ISOtech suggests
    # * Unicode does not say rArr is the 'implies' character but does not have another
    # character with this function so ? rArr can be used for 'implies' as ISOtech suggests
    'larr'     => chr(8592),
    'uarr'     => chr(8593),
    'rarr'     => chr(8594),
    'darr'     => chr(8595),
    'harr'     => chr(8596),
    'crarr'    => chr(8629),
    'lArr'     => chr(8656),
    'uArr'     => chr(8657),
    'rArr'     => chr(8658),
    'dArr'     => chr(8659),
    'hArr'     => chr(8660),
    
    # Mathematical Operators
    # * should there be a more memorable name than 'ni'?
    # * prod is NOT the same character as U+03A0 'greek capital letter pi' though the same glyph might be used for both
    # * sum is NOT the same character as U+03A3 'greek capital letter sigma' though the same glyph might be used for both
    # * sim: tilde operator is NOT the same character as the tilde, U+007E, although the same glyph might be used to represent both
    # * note that nsup, 'not a superset of, U+2283' is not covered by the Symbol font encoding and is not included.
    # Should it be, for symmetry? It is in ISOamsn
    # * sdot: dot operator is NOT the same character as U+00B7 middle dot 
    'forall'   => chr(8704),
    'part'     => chr(8706),
    'exist'    => chr(8707),
    'empty'    => chr(8709),
    'nabla'    => chr(8711),
    'isin'     => chr(8712),
    'notin'    => chr(8713),
    'ni'       => chr(8715),
    'prod'     => chr(8719),
    'sum'      => chr(8721),
    'minus'    => chr(8722),
    'lowast'   => chr(8727),
    'radic'    => chr(8730),
    'prop'     => chr(8733),
    'infin'    => chr(8734),
    'ang'      => chr(8736),
    'and'      => chr(8743),
    'or'       => chr(8744),
    'cap'      => chr(8745),
    'cup'      => chr(8746),
    'int'      => chr(8747),
    'there4'   => chr(8756),
    'sim'      => chr(8764),
    'cong'     => chr(8773),
    'asymp'    => chr(8776),
    'ne'       => chr(8800),
    'equiv'    => chr(8801),
    'le'       => chr(8804),
    'ge'       => chr(8805),
    'sub'      => chr(8834),
    'sup'      => chr(8835),
    'nsub'     => chr(8836),
    'sube'     => chr(8838),
    'supe'     => chr(8839),
    'oplus'    => chr(8853),
    'otimes'   => chr(8855),
    'perp'     => chr(8869),
    'sdot'     => chr(8901),
    
    # Miscellaneous Technical
    # * lang is NOT the same character as U+003C 'less than' or U+2039 'single left-pointing angle quotation mark'
    # * rang is NOT the same character as U+003E 'greater than' or U+203A 'single right-pointing angle quotation mark' 
    'lceil'    => chr(8968),
    'rceil'    => chr(8969),
    'lfloor'   => chr(8970),
    'rfloor'   => chr(8971),
    'lang'     => chr(9001),
    'rang'     => chr(9002),
    
    # Geometric Shapes
    'loz'      => chr(9674),
    
    # Miscellaneous Symbols
    # * black here seems to mean filled as opposed to hollow 
    'spades'   => chr(9824),
    'clubs'    => chr(9827),
    'hearts'   => chr(9829),
    'diams'    => chr(9830),
   );


sub process
{
    (@_ == 2) or warn "MKDoc::XML::Encode::process() should be called with two arguments";
    my $class = shift;
    my $stuff = shift;
    return $ENTITY_2_CHAR{$stuff};
}


1;
