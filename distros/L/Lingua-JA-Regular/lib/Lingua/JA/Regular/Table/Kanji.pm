package Lingua::JA::Regular::Table::Kanji;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use vars qw(@ISA @EXPORT %KANJI_ALT_TABLE);
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(%KANJI_ALT_TABLE);

%KANJI_ALT_TABLE = (
    "\xF9\xAC" => "\xC6\xE5",   # Æå
    "\xF9\xE0" => "\xC4\xCD",   # ÄÍ
    "\xF9\xE1" => "\xC1\xFD",   # Áý
    "\xF9\xEE" => "\xB4\xB2",   # ´²
    "\xF9\xF5" => "\xBA\xEA",   # ºê
    "\xFA\xB3" => "\xB6\xB5",   # ¶µ
    "\xFA\xBE" => "\xC0\xB2",   # À²
    "\xFA\xC6" => "\xCF\xAF",   # Ï¯
    "\xFA\xD4" => "\xB2\xA3",   # ²£
    "\xFA\xE6" => "\xC0\xB6",   # À¶
    "\xFA\xF3" => "\xC0\xA5",   # À¥
    "\xFB\xA3" => "\xC3\xF6",   # Ãö
    "\xFB\xB3" => "\xC9\xD3",   # ÉÓ
    "\xFB\xBA" => "\xB1\xD7",   # ±×
    "\xFB\xC2" => "\xCE\xE9",   # Îé
    "\xFB\xC3" => "\xBF\xC0",   # ¿À
    "\xFB\xC4" => "\xBE\xCD",   # ¾Í
    "\xFB\xC6" => "\xCA\xA1",   # Ê¡
    "\xFB\xCA" => "\xCC\xF7",   # Ì÷
    "\xFB\xCD" => "\xC0\xBA",   # Àº
    "\xFB\xD2" => "\xBD\xEF",   # ½ï
    "\xFB\xD6" => "\xB1\xA9",   # ±©
    "\xFB\xE2" => "\xB7\xB0",   # ·°
    "\xFB\xED" => "\xBD\xF4",   # ½ô
    "\xFB\xF2" => "\xCD\xEA",   # Íê
    "\xFB\xF8" => "\xB0\xEF",   # °ï
    "\xFB\xFA" => "\xCF\xBA",   # Ïº
    "\xFB\xFB" => "\xC5\xD4",   # ÅÔ
    "\xFB\xFC" => "\xB6\xBF",   # ¶¿
    "\xFC\xCE" => "\xB4\xD6",   # ´Ö
    "\xFC\xCF" => "\xCE\xB4",   # Î´
    "\xFC\xD8" => "\xC0\xC4",   # ÀÄ
    "\xFC\xDC" => "\xC8\xD3",   # ÈÓ
    "\xFC\xDD" => "\xBB\xF4",   # »ô
    "\xFC\xDF" => "\xB4\xDB",   # ´Û
    "\xFC\xE2" => "\xB9\xE2",   # ¹â
    "\xFC\xEC" => "\xC4\xE1",   # Äá
    "\xFC\xEE" => "\xB9\xF5",   # ¹õ
);

1;

__END__

=head1 NAME

Lingua::JA::Regular::Table::Kanji - Conversion Table(Kanji) for Lingua::JA::Regular

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 DESCRIPTION

This module defines conversion table used by Lingua::JA::Regular

=head1 BUGS

This table is not filling all.

=head1 AUTHOR

KIMURA, takefumi E<lt>takefumi@takefumi.comE<gt>

=head1 SEE ALSO

L<Lingua::JA::Regular>,
L<http://www.aozora.gr.jp/hosetsu_kijyun/>,

=cut
