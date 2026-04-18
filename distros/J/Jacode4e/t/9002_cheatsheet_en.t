######################################################################
#
# 9002_cheatsheet_en.t
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
#
# Jacode4e Cheatsheet (English)
# This test also serves as a quick reference for English speakers.
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ======================================================================
# Jacode4e Cheatsheet (English)
# ======================================================================
#
# [BASIC USAGE]
#
#   use FindBin;
#   use lib "$FindBin::Bin/lib";
#   use Jacode4e;
#
#   $char_count = Jacode4e::convert(\$line, $OUTPUT_encoding, $INPUT_encoding);
#   $char_count = Jacode4e::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, { %option });
#
#   $line             : string to convert (passed by reference, overwritten in place)
#   $OUTPUT_encoding  : output encoding mnemonic
#   $INPUT_encoding   : input encoding mnemonic
#   $char_count       : character count after conversion
#
# [ENCODING MNEMONICS]
#
#   mnemonic    description
#   ---------   ---------------------------------------------------
#   cp932x      CP932X (Extended CP932 to JIS X 0213, single-shift 0x9C5A)
#   cp932       Microsoft CP932 (Windows-31J / IANA registered name)
#   cp932ibm    IBM CP932
#   cp932nec    NEC CP932
#   sjis2004    JISC Shift_JIS-2004
#   cp00930     IBM CP00930 (CP00290+CP00300, CCSID 5026 katakana)
#   keis78      HITACHI KEIS78
#   keis83      HITACHI KEIS83
#   keis90      HITACHI KEIS90
#   jef         FUJITSU JEF (12pt, use OUTPUT_SHIFTING option for shift codes)
#   jef9p       FUJITSU JEF ( 9pt, use OUTPUT_SHIFTING option for shift codes)
#   jipsj       NEC JIPS(J)
#   jipse       NEC JIPS(E)
#   letsj       UNISYS LetsJ
#   utf8        UTF-8.0 (aka UTF-8)
#   utf8.1      UTF-8.1 (conversion based on Shift_JIS-to-Unicode mapping, not CP932)
#   utf8jp      UTF-8-SPUA-JP (JIS X 0213 on SPUA ordered by JIS level/plane/row/cell)
#
# [OPTIONS]
#
#   key               value / description
#   ---------------   ---------------------------------------------------
#   INPUT_LAYOUT      record layout string using 'S' (SBCS) and 'D' (DBCS)
#                     each letter may be followed by a repeat count
#                     e.g. 'SSDDSD' or 'S2D2SD'
#   OUTPUT_SHIFTING   if true, emit shift-out/shift-in codes around DBCS runs
#   SPACE             DBCS/MBCS space code (binary string)
#   GETA              DBCS/MBCS geta (replacement for unmappable characters)
#   OVERRIDE_MAPPING  hashref of per-character overrides { "\x12\x34"=>"\x56\x78" }
#                     (CAUTION: also overrides SPACE option)
#
# [SHIFT CODE REFERENCE]
#
#   encoding  shift-out (DBCS start)  shift-in (DBCS end)
#   --------  ---------------------   -------------------
#   cp00930   0x0E                    0x0F
#   keis78    0x0A 0x42               0x0A 0x41
#   keis83    0x0A 0x42               0x0A 0x41
#   keis90    0x0A 0x42               0x0A 0x41
#   jef       0x28                    0x29
#   jef9p     0x38                    0x29
#   jipsj     0x1A 0x70               0x1A 0x71
#   jipse     0x3F 0x75               0x3F 0x76
#   letsj     0x93 0x70               0x93 0xF1
#
# [ROUND-TRIP CAUTION]
#
#   Lossy conversions exist (e.g. CP932 has 398 non-round-trip mappings).
#   For round-trip conversion, use the Jacode4e::RoundTrip module.
#
# ======================================================================

BEGIN {
    use vars qw(@test);
    @test = (

        # --- Basic conversion: return value is character count ---
        # CP932 ideographic space (8140) -> JEF (A1A1): 1 character
        ["\x81\x40", 'jef',    'cp932', {},                    "\xA1\xA1", 'cp932(8140)->jef(A1A1) count=1'],

        # CP932 ideographic space -> KEIS83
        ["\x81\x40", 'keis83', 'cp932', {},                    "\xA1\xA1", 'cp932(8140)->keis83(A1A1)'],

        # CP932 ideographic space -> JIPSJ
        ["\x81\x40", 'jipsj',  'cp932', {},                    "\x21\x21", 'cp932(8140)->jipsj(2121)'],

        # CP932 ideographic space -> UTF-8
        ["\x81\x40", 'utf8',   'cp932', {},                    "\xE3\x80\x80", 'cp932(8140)->utf8(E38080 U+3000)'],

        # --- SPACE option: substitute DBCS space code in output ---
        ["\x81\x40", 'jef',    'cp932', {'SPACE'=>"\x40\x40"}, "\x40\x40", 'cp932(8140)->jef SPACE=4040'],

        # --- GETA option: replace unmappable chars with geta symbol ---
        ["\xFC\xFC", 'jef',    'cp932', {'GETA'=>"\xFE\xFE"},  "\xFE\xFE", 'cp932(FCFC)->jef GETA=FEFE'],

        # --- OUTPUT_SHIFTING: emit shift codes around DBCS in output ---
        ["\x81\x40\x31", 'jef', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x28\xA1\xA1\x29\xF1",
            'cp932(814031)->jef OUTPUT_SHIFTING=1 (28 A1A1 29 F1)'],

        # --- INPUT_LAYOUT: describe input without shift codes ---
        # JEF DS-layout (no shift codes): DBCS A1A1, then SBCS F1
        ["\xA1\xA1\xF1", 'cp932', 'jef', {'INPUT_LAYOUT'=>'DS'}, "\x81\x40\x31",
            'jef(A1A1F1) INPUT_LAYOUT=DS -> cp932(814031)'],

        # --- CP00930 (IBM EBCDIC for Japanese katakana) ---
        # Default (no OUTPUT_SHIFTING): raw DBCS data, no shift codes
        ["\x81\x40", 'cp00930', 'cp932', {}, "\x40\x40", 'cp932(8140)->cp00930 no-shift(4040)'],
        # OUTPUT_SHIFTING=>1: shift-out=0E, shift-in=0F
        ["\x81\x40\x31", 'cp00930', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0E\x40\x40\x0F\xF1",
            'cp932(814031)->cp00930 OUTPUT_SHIFTING(0E 4040 0F F1)'],

        # --- HITACHI KEIS83 (shift: 0A42 / 0A41) ---
        # Default (no OUTPUT_SHIFTING): raw DBCS data
        ["\x81\x40\x31", 'keis83', 'cp932', {}, "\xA1\xA1\xF1",
            'cp932(814031)->keis83 no-shift(A1A1 F1)'],
        # OUTPUT_SHIFTING=>1: shift-out=0A42, shift-in=0A41
        ["\x81\x40\x31", 'keis83', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0A\x42\xA1\xA1\x0A\x41\xF1",
            'cp932(814031)->keis83 OUTPUT_SHIFTING(0A42 A1A1 0A41 F1)'],

        # --- HITACHI KEIS78: same shift codes as KEIS83 ---
        ["\x81\x40", 'keis78', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xA1\xA1",
            'cp932(8140 D-layout)->keis78(A1A1)'],

        # --- Wave dash problem: CP932 0x8160 maps to U+301C (WAVE DASH) in UTF-8 ---
        ["\x81\x60", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE3\x80\x9C",
            'cp932(8160 wave dash)->utf8(E3809C U+301C)'],

        # --- NEC JIPS(J): default no-shift; OUTPUT_SHIFTING adds 1A70/1A71 ---
        ["\x81\x40\x31", 'jipsj', 'cp932', {}, "\x21\x21\x31",
            'cp932(814031)->jipsj no-shift(2121 31)'],
        ["\x81\x40\x31", 'jipsj', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x1A\x70\x21\x21\x1A\x71\x31",
            'cp932(814031)->jipsj OUTPUT_SHIFTING(1A70 2121 1A71 31)'],

        # --- NEC JIPS(E): shift-out=3F75, shift-in=3F76 ---
        ["\x81\x40", 'jipse',  'cp932', {'INPUT_LAYOUT'=>'D'}, "\x4F\x4F",
            'cp932(8140 D-layout)->jipse(4F4F)'],

        # --- UNISYS LetsJ: default no-shift; OUTPUT_SHIFTING adds 9370/93F1 ---
        ["\x81\x40", 'letsj',  'cp932', {}, "\x20\x20",
            'cp932(8140)->letsj no-shift(2020)'],
        ["\x81\x40\x31", 'letsj', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x93\x70\x20\x20\x93\xF1\x31",
            'cp932(814031)->letsj OUTPUT_SHIFTING(9370 2020 93F1 31)'],

        # --- UTF-8.1: conversion based on Shift_JIS-to-Unicode mapping, not CP932 ---
        # utf8 vs utf8.1 differ on cp932(815C/8161/817C): MS mapping vs JIS mapping
        ["\x81\x40", 'utf8.1', 'cp932', {}, "\xE3\x80\x80", 'cp932(8140)->utf8.1(E38080)'],
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

        # --- UTF-8-SPUA-JP: internal pivot encoding for JIS X 0213 ---
        # Uses Unicode SPUA (Supplemental Private Use Area)
        ["\x81\x40", 'utf8jp', 'cp932', {}, "\xF3\xB0\x84\x80",
            'cp932(8140)->utf8jp(F3B08480 SPUA)'],

        # --- OVERRIDE_MAPPING: per-character override (highest priority) ---
        # Override CP932 8160 (wave dash) to map to JEF A1C1 explicitly
        ["\x81\x60", 'jef', 'cp932',
            {'INPUT_LAYOUT'=>'D','OVERRIDE_MAPPING'=>{"\x81\x60"=>"\xA1\xC1"}},
            "\xA1\xC1",
            'cp932(8160)->jef OVERRIDE_MAPPING 8160=>A1C1'],

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
