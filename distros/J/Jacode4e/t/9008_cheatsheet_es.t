######################################################################
#
# 9008_cheatsheet_es.t
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
#
# Referencia rápida de Jacode4e (Español)
# Esta prueba también sirve como referencia rápida para hispanohablantes.
######################################################################

# Este archivo está codificado en UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ======================================================================
# Referencia rápida de Jacode4e (Español)
# ======================================================================
#
# [USO BÁSICO]
#
#   use FindBin;
#   use lib "$FindBin::Bin/lib";
#   use Jacode4e;
#
#   $char_count = Jacode4e::convert(\$line, $OUTPUT_encoding, $INPUT_encoding);
#   $char_count = Jacode4e::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, { %option });
#
#   $line             : cadena a convertir (pasada por referencia, sobrescrita in situ)
#   $OUTPUT_encoding  : nombre de la codificación de salida
#   $INPUT_encoding   : nombre de la codificación de entrada
#   $char_count       : número de caracteres tras la conversión
#
# [NOMBRES DE CODIFICACIÓN]
#
#   mnemónico   significado
#   ---------   ---------------------------------------------------
#   cp932x      CP932X (extensión a JIS X 0213, cambio simple 0x9C5A)
#   cp932       Microsoft CP932 (Windows-31J / nombre IANA)
#   cp932ibm    IBM CP932
#   cp932nec    NEC CP932
#   sjis2004    JISC Shift_JIS-2004
#   cp00930     IBM CP00930 (CP00290+CP00300, CCSID 5026 katakana)
#   keis78      HITACHI KEIS78
#   keis83      HITACHI KEIS83
#   keis90      HITACHI KEIS90
#   jef         FUJITSU JEF (12pt, códigos de cambio con OUTPUT_SHIFTING)
#   jef9p       FUJITSU JEF ( 9pt, códigos de cambio con OUTPUT_SHIFTING)
#   jipsj       NEC JIPS(J)
#   jipse       NEC JIPS(E)
#   letsj       UNISYS LetsJ
#   utf8        UTF-8.0 (el UTF-8 habitual)
#   utf8.1      UTF-8.1 (conversión basada en la correspondencia Shift_JIS-Unicode, no CP932)
#   utf8jp      UTF-8-SPUA-JP (JIS X 0213 en la zona SPUA de Unicode)
#
# [OPCIONES]
#
#   clave             valor / descripción
#   ---------------   ---------------------------------------------------
#   INPUT_LAYOUT      disposición del registro ('S'=SBCS, 'D'=DBCS, con repetición)
#   OUTPUT_SHIFTING   si es verdadero: insertar códigos de cambio en la salida
#   SPACE             código de espacio DBCS/MBCS (cadena binaria)
#   GETA              carácter de reemplazo para caracteres no mapeables
#   OVERRIDE_MAPPING  sustituciones por carácter { "\x12\x34"=>"\x56\x78" }
#
# [ADVERTENCIA: CONVERSIÓN DE IDA Y VUELTA]
#
#   Existen conversiones con pérdida (ej. CP932 tiene 398 caracteres sin
#   mapeo de ida y vuelta). Para conversión de ida y vuelta, usar
#   el módulo Jacode4e::RoundTrip.
#
# ======================================================================

BEGIN {
    use vars qw(@test);
    @test = (

        # --- Conversión básica: valor de retorno = número de caracteres ---
        ["\x81\x40", 'jef',    'cp932', {},                    "\xA1\xA1", 'cp932(8140)->jef(A1A1)'],
        ["\x81\x40", 'keis83', 'cp932', {},                    "\xA1\xA1", 'cp932(8140)->keis83(A1A1)'],
        ["\x81\x40", 'jipsj',  'cp932', {},                    "\x21\x21", 'cp932(8140)->jipsj(2121)'],
        ["\x81\x40", 'utf8',   'cp932', {},                    "\xE3\x80\x80", 'cp932(8140)->utf8(E38080)'],

        # --- Opción SPACE ---
        ["\x81\x40", 'jef',    'cp932', {'SPACE'=>"\x40\x40"}, "\x40\x40", 'cp932(8140)->jef SPACE=4040'],

        # --- Opción GETA: reemplazo de caracteres no mapeables ---
        ["\xFC\xFC", 'jef',    'cp932', {'GETA'=>"\xFE\xFE"},  "\xFE\xFE", 'cp932(FCFC)->jef GETA=FEFE'],

        # --- OUTPUT_SHIFTING: códigos de cambio en la salida ---
        ["\x81\x40\x31", 'jef', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x28\xA1\xA1\x29\xF1",
            'cp932(814031)->jef OUTPUT_SHIFTING(28A1A129F1)'],

        # --- INPUT_LAYOUT: describir entrada sin códigos de cambio ---
        ["\xA1\xA1\xF1", 'cp932', 'jef', {'INPUT_LAYOUT'=>'DS'}, "\x81\x40\x31",
            'jef(A1A1F1) INPUT_LAYOUT=DS->cp932(814031)'],

        # --- CP00930 (EBCDIC IBM japonés): sin cambio por defecto ---
        ["\x81\x40", 'cp00930', 'cp932', {}, "\x40\x40", 'cp932(8140)->cp00930 sin cambio(4040)'],
        ["\x81\x40\x31", 'cp00930', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0E\x40\x40\x0F\xF1",
            'cp932(814031)->cp00930 OUTPUT_SHIFTING(0E40400FF1)'],

        # --- KEIS83 (mainframe Hitachi): sin cambio por defecto ---
        ["\x81\x40\x31", 'keis83', 'cp932', {}, "\xA1\xA1\xF1",
            'cp932(814031)->keis83 sin cambio(A1A1F1)'],
        ["\x81\x40\x31", 'keis83', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0A\x42\xA1\xA1\x0A\x41\xF1",
            'cp932(814031)->keis83 OUTPUT_SHIFTING(0A42A1A10A41F1)'],

        # --- Problema del guión de onda: CP932 0x8160 -> U+301C en UTF-8 ---
        ["\x81\x60", 'utf8', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE3\x80\x9C",
            'cp932(8160 guión onda)->utf8(E3809C U+301C)'],

        # --- UTF-8-SPUA-JP: JIS X 0213 en zona de uso privado Unicode ---
        # utf8 vs utf8.1: cp932(815C/8161/817C) differ between MS-CP932 and JIS-Shift_JIS mapping
        # cp932(815C)=― : utf8->U+2015 HORIZONTAL BAR, utf8.1->U+2014 EM DASH
        ["\x81\x5C", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x95", 'cp932(815C)->utf8(E28095 U+2015 HORIZONTAL BAR)'],
        ["\x81\x5C", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x94", 'cp932(815C)->utf8.1(E28094 U+2014 EM DASH)'],
        # cp932(8161)=∥ : utf8->U+2225 PARALLEL TO, utf8.1->U+2016 DOUBLE VERTICAL LINE
        ["\x81\x61", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x88\xA5", 'cp932(8161)->utf8(E288A5 U+2225 PARALLEL TO)'],
        ["\x81\x61", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x96", 'cp932(8161)->utf8.1(E28096 U+2016 DOUBLE VERTICAL LINE)'],
        # cp932(817C)=－ : utf8->U+FF0D FULLWIDTH HYPHEN-MINUS, utf8.1->U+2212 MINUS SIGN
        ["\x81\x7C", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xEF\xBC\x8D", 'cp932(817C)->utf8(EFBC8D U+FF0D FULLWIDTH HYPHEN-MINUS)'],
        ["\x81\x7C", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x88\x92", 'cp932(817C)->utf8.1(E28892 U+2212 MINUS SIGN)'],
        # cp932x(9C5A815C/8161/817C): utf8/utf8.1 mapping is inverted compared to cp932
        ["\x9C\x5A\x81\x5C", 'utf8',   'cp932x', {}, "\xE2\x80\x94", 'cp932x(9C5A815C)->utf8(E28094 U+2014 EM DASH)'],
        ["\x9C\x5A\x81\x5C", 'utf8.1', 'cp932x', {}, "\xE2\x80\x95", 'cp932x(9C5A815C)->utf8.1(E28095 U+2015 HORIZONTAL BAR)'],
        ["\x9C\x5A\x81\x61", 'utf8',   'cp932x', {}, "\xE2\x80\x96", 'cp932x(9C5A8161)->utf8(E28096 U+2016 DOUBLE VERTICAL LINE)'],
        ["\x9C\x5A\x81\x61", 'utf8.1', 'cp932x', {}, "\xE2\x88\xA5", 'cp932x(9C5A8161)->utf8.1(E288A5 U+2225 PARALLEL TO)'],
        ["\x9C\x5A\x81\x7C", 'utf8',   'cp932x', {}, "\xE2\x88\x92", 'cp932x(9C5A817C)->utf8(E28892 U+2212 MINUS SIGN)'],
        ["\x9C\x5A\x81\x7C", 'utf8.1', 'cp932x', {}, "\xEF\xBC\x8D", 'cp932x(9C5A817C)->utf8.1(EFBC8D U+FF0D FULLWIDTH HYPHEN-MINUS)'],
        ["\x81\x40", 'utf8jp', 'cp932', {}, "\xF3\xB0\x84\x80",
            'cp932(8140)->utf8jp(F3B08480 SPUA)'],

    );
    $|=1;
    print "1..",scalar(@test),"\n";
    my $testno=1;
    sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
}

use Jacode4e;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want,$desc) = @{$test};
    my $got = $give;
    my $return = Jacode4e::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);
    ok(($return > 0) and ($got eq $want),
        sprintf('%s => return=%d got=(%s) want=(%s)',
            $desc, $return,
            uc unpack('H*',$got),
            uc unpack('H*',$want),
        )
    );
}

__END__
