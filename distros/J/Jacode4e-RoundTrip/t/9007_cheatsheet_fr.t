######################################################################
#
# 9007_cheatsheet_fr.t
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
#
# Aide-mémoire Jacode4e::RoundTrip (Français)
# Ce test sert également de référence rapide pour les utilisateurs francophones.
######################################################################

# Ce fichier est encodé en UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ======================================================================
# Aide-mémoire Jacode4e::RoundTrip (Français)
# ======================================================================
#
# [UTILISATION DE BASE]
#
#   use FindBin;
#   use lib "$FindBin::Bin/lib";
#   use Jacode4e::RoundTrip;
#
#   $char_count = Jacode4e::RoundTrip::convert(\$line, $OUTPUT_encoding, $INPUT_encoding);
#   $char_count = Jacode4e::RoundTrip::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, { %option });
#
#   $line             : chaîne à convertir (passée par référence, écrasée sur place)
#   $OUTPUT_encoding  : nom de l'encodage de sortie
#   $INPUT_encoding   : nom de l'encodage d'entrée
#   $char_count       : nombre de caractères après conversion
#
# [NOMS D'ENCODAGE]
#
#   mnémonique  signification
#   ---------   ---------------------------------------------------
#   cp932x      CP932X (extension vers JIS X 0213, décalage simple 0x9C5A)
#   cp932       Microsoft CP932 (Windows-31J / nom IANA)
#   cp932ibm    IBM CP932
#   cp932nec    NEC CP932
#   sjis2004    JISC Shift_JIS-2004
#   cp00930     IBM CP00930 (CP00290+CP00300, CCSID 5026 katakana)
#   keis78      HITACHI KEIS78
#   keis83      HITACHI KEIS83
#   keis90      HITACHI KEIS90
#   jef         FUJITSU JEF (12pt, codes de décalage avec OUTPUT_SHIFTING)
#   jef9p       FUJITSU JEF ( 9pt, codes de décalage avec OUTPUT_SHIFTING)
#   jipsj       NEC JIPS(J)
#   jipse       NEC JIPS(E)
#   letsj       UNISYS LetsJ
#   utf8        UTF-8.0 (le UTF-8 habituel)
#   utf8.1      UTF-8.1 (conversion basée sur la correspondance Shift_JIS-Unicode, pas CP932)
#   utf8jp      UTF-8-SPUA-JP (JIS X 0213 dans la zone SPUA d'Unicode)
#
# [OPTIONS]
#
#   clé               valeur / description
#   ---------------   ---------------------------------------------------
#   INPUT_LAYOUT      disposition de l'enregistrement ('S'=SBCS, 'D'=DBCS, avec répétition)
#   OUTPUT_SHIFTING   si vrai : insérer les codes de décalage dans la sortie
#   SPACE             code d'espace DBCS/MBCS (chaîne binaire)
#   GETA              caractère de remplacement pour les caractères non mappables
#   OVERRIDE_MAPPING  substitutions par caractère { "\x12\x34"=>"\x56\x78" }
#
# [CODES DE DÉCALAGE]
#
#   encodage   décalage sortant (début DBCS)  décalage entrant (fin DBCS)
#   ---------  ---------------------------    --------------------------
#   cp00930    0x0E                           0x0F
#   keis78     0x0A 0x42                      0x0A 0x41
#   keis83     0x0A 0x42                      0x0A 0x41
#   keis90     0x0A 0x42                      0x0A 0x41
#   jef        0x28                           0x29
#   jef9p      0x38                           0x29
#   jipsj      0x1A 0x70                      0x1A 0x71
#   jipse      0x3F 0x75                      0x3F 0x76
#   letsj      0x93 0x70                      0x93 0xF1
#
# [ATTENTION : CONVERSION ALLER-RETOUR]
#
#   Des conversions avec perte existent (ex. CP932 a 398 caractères sans
# [Jacode4e vs Jacode4e::RoundTrip]
#
#   Jacode4e              : Conversion unidirectionnelle rapide. Avec perte pour
#                           certains caractères (ex. CP932 a 398 correspondances
#                           non réversibles).
#   Jacode4e::RoundTrip   : Garantit la fidélité aller-retour via pivot Unicode.
#                           A->B->A est toujours identique. Plus lent que Jacode4e,
#                           mais à utiliser quand les données doivent faire l'aller-retour.
#
#   mappage aller-retour).
#   Si la conversion aller-retour n'est pas nécessaire, utiliser le module Jacode4e.
#
# ======================================================================

BEGIN {
    use vars qw(@test);
    @test = (

        # --- Conversion de base : valeur de retour = nombre de caractères ---
        ["\x81\x40", 'jef',    'cp932', {},                    "\xA1\xA1", 'cp932(8140)->jef(A1A1)'],
        ["\x81\x40", 'keis83', 'cp932', {},                    "\xA1\xA1", 'cp932(8140)->keis83(A1A1)'],
        ["\x81\x40", 'jipsj',  'cp932', {},                    "\x21\x21", 'cp932(8140)->jipsj(2121)'],
        ["\x81\x40", 'utf8',   'cp932', {},                    "\xE3\x80\x80", 'cp932(8140)->utf8(E38080)'],

        # --- Option SPACE ---
        ["\x81\x40", 'jef',    'cp932', {'SPACE'=>"\x40\x40"}, "\x40\x40", 'cp932(8140)->jef SPACE=4040'],

        # --- Option GETA : remplacement des caractères non mappables ---
        ["\xFC\xFC", 'jef',    'cp932', {'GETA'=>"\xFE\xFE"},  "\xFE\xFE", 'cp932(FCFC)->jef GETA=FEFE'],

        # --- OUTPUT_SHIFTING : codes de décalage en sortie ---
        ["\x81\x40\x31", 'jef', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x28\xA1\xA1\x29\xF1",
            'cp932(814031)->jef OUTPUT_SHIFTING(28A1A129F1)'],

        # --- INPUT_LAYOUT : décrire l'entrée sans codes de décalage ---
        ["\xA1\xA1\xF1", 'cp932', 'jef', {'INPUT_LAYOUT'=>'DS'}, "\x81\x40\x31",
            'jef(A1A1F1) INPUT_LAYOUT=DS->cp932(814031)'],

        # --- CP00930 (EBCDIC IBM japonais) : sans décalage par défaut ---
        ["\x81\x40", 'cp00930', 'cp932', {}, "\x40\x40", 'cp932(8140)->cp00930 sans décalage(4040)'],
        ["\x81\x40\x31", 'cp00930', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0E\x40\x40\x0F\xF1",
            'cp932(814031)->cp00930 OUTPUT_SHIFTING(0E40400FF1)'],

        # --- KEIS83 (mainframe Hitachi) : sans décalage par défaut ---
        ["\x81\x40\x31", 'keis83', 'cp932', {}, "\xA1\xA1\xF1",
            'cp932(814031)->keis83 sans décalage(A1A1F1)'],
        ["\x81\x40\x31", 'keis83', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0A\x42\xA1\xA1\x0A\x41\xF1",
            'cp932(814031)->keis83 OUTPUT_SHIFTING(0A42A1A10A41F1)'],

        # --- Problème du tiret ondulé : CP932 0x8160 -> U+301C en UTF-8 ---
        ["\x81\x60", 'utf8', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE3\x80\x9C",
            'cp932(8160 tiret ondulé)->utf8(E3809C U+301C)'],

        # --- UTF-8-SPUA-JP : JIS X 0213 dans la zone privée Unicode ---
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

use Jacode4e::RoundTrip;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want,$desc) = @{$test};
    my $got = $give;
    my $return = Jacode4e::RoundTrip::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);
    ok(($return > 0) and ($got eq $want),
        sprintf('%s => return=%d got=(%s) want=(%s)',
            $desc, $return,
            uc unpack('H*',$got),
            uc unpack('H*',$want),
        )
    );
}

__END__
