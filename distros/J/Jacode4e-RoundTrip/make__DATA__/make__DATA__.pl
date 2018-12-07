######################################################################
#
# make__DATA__.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict; die $_ if ($_=`$^X -cw @{[__FILE__]} 2>&1`) !~ /^.+ syntax OK$/;
use FindBin;
use lib $FindBin::Bin;

# __DATA__
require 'EBCDIC/EBCDIC_IBM_CPGID00290_by_JIS8.pl';
require 'EBCDIC/EBCDIK_HITACHI_by_JIS8.pl';
require 'EBCDIC/EBCDIC_FUJITSU_by_JIS8.pl';
require 'EBCDIC/EBCDIC_NEC_by_JIS8.pl';
require 'Unicode/Unicode_by_CP932.pl';
require 'UTF8/UTF8_by_Unicode.pl';
require 'CP932X/CP932X_by_Unicode.pl';
require 'CP932/CP932_by_Unicode.pl';
require 'ShiftJIS2004/ShiftJIS2004_by_Unicode.pl';
require 'CP00930/make_CP00930.pl';
require 'KEIS/make_KEIS78.pl';
require 'KEIS/make_KEIS83.pl';
require 'KEIS/make_KEIS90.pl';
require 'JEF/make_JEF.pl';
require 'JIPS/make_JIPSJ.pl';
require 'JIPS/make_JIPSE.pl';
require 'LetsJ/LetsJ_by_Unicode.pl';

binmode(STDOUT);

print STDOUT <<'COMMENT';
__DATA__
############################################################################################
# Jacode4e table
############################################################################################
#+++++++------------------------------------------------------------------------------------ CP932X, Extended CP932 to JIS X 0213 using 0x9C5A as single shift
#||||||| ++++------------------------------------------------------------------------------- Microsoft CP932, IANA Windows-31J
#||||||| |||| ++++-------------------------------------------------------------------------- JISC Shift_JIS-2004
#||||||| |||| |||| ++++--------------------------------------------------------------------- IBM CP00930(CP00290+CP00300), CCSID 5026 katakana
#||||||| |||| |||| |||| ++++---------------------------------------------------------------- HITACHI KEIS78
#||||||| |||| |||| |||| |||| ++++----------------------------------------------------------- HITACHI KEIS83
#||||||| |||| |||| |||| |||| |||| ++++------------------------------------------------------ HITACHI KEIS90
#||||||| |||| |||| |||| |||| |||| |||| ++++------------------------------------------------- FUJITSU JEF
#||||||| |||| |||| |||| |||| |||| |||| |||| ++++-------------------------------------------- NEC JIPS(J)
#||||||| |||| |||| |||| |||| |||| |||| |||| |||| ++++--------------------------------------- NEC JIPS(E)
#||||||| |||| |||| |||| |||| |||| |||| |||| |||| |||| ++++---------------------------------- UNISYS LetsJ
#||||||| |||| |||| |||| |||| |||| |||| |||| |||| |||| |||| +++++++++------------------------ Unicode
#||||||| |||| |||| |||| |||| |||| |||| |||| |||| |||| |||| ||||||||| ++++++++++++----------- UTF-8
#||||||| |||| |||| |||| |||| |||| |||| |||| |||| |||| |||| ||||||||| |||||||||||| ++++++++-- UTF-8-SPUA-JP, JIS X 0213 on SPUA ordered by JIS level, plane, row, cell
#2345678 1234 1234 1234 1234 1234 1234 1234 1234 1234 1234 123456789 123456789012 12345678
#VVVVVVV VVVV VVVV VVVV VVVV VVVV VVVV VVVV VVVV VVVV VVVV VVVVVVVVV VVVVVVVVVVVV VVVVVVVV
COMMENT

my $spua_jp = 0xF0000;
for my $jis8 (qw(
    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F
    20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F
    30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F
    40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F
    50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F
    60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F
    70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E 7F
    80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F
    90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F
    A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF
    B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF
    C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF
    D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD DE DF
    E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 EA EB EC ED EE EF
    F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC FD FE FF
)) {
    my $data = join("", map { sprintf($_->[1],$_->[0]) }
        [(                                 $jis8   || '  ----  ') => '%-8s ' ], # CP932X, Extended CP932 to JIS X 0213 using 0x9C5A as single shift
        [(                                 $jis8   || ' -- '    ) => '%-4s ' ], # CP932
        [(                                 $jis8   || ' -- '    ) => '%-4s ' ], # Shift_JIS-2004
        [(EBCDIC_IBM_CPGID00290_by_JIS8   ($jis8)  || ' -- '    ) => '%-4s ' ], # IBM CP00930(CP00290+CP00300), CCSID 5026 katakana
        [(EBCDIK_HITACHI_by_JIS8          ($jis8)  || ' -- '    ) => '%-4s ' ], # HITACHI KEIS78
        [(EBCDIK_HITACHI_by_JIS8          ($jis8)  || ' -- '    ) => '%-4s ' ], # HITACHI KEIS83
        [(EBCDIK_HITACHI_by_JIS8          ($jis8)  || ' -- '    ) => '%-4s ' ], # HITACHI KEIS90
        [(EBCDIC_FUJITSU_by_JIS8          ($jis8)  || ' -- '    ) => '%-4s ' ], # FUJITSU JEF
        [(                                 $jis8   || ' -- '    ) => '%-4s ' ], # NEC JIPS(J)
        [(EBCDIC_NEC_by_JIS8              ($jis8)  || ' -- '    ) => '%-4s ' ], # NEC JIPS(E)
        [(                                 $jis8   || ' -- '    ) => '%-4s ' ], # UNISYS LetsJ
        [(Unicode_by_CP932                ($jis8)  || ' --- '   ) => '%-9s ' ], # Unicode
        [(UTF8_by_Unicode(Unicode_by_CP932($jis8)) || '  --  '  ) => '%-12s '], # UTF-8
    );
    print $data;
    print STDOUT UTF8_by_Unicode(sprintf('%05X', $spua_jp));
    if (('00' le $jis8) and ($jis8 le '1F')) {
    }
    elsif ($jis8 eq '7F') {
    }
    elsif ($jis8 eq '80') {
    }
    elsif (('81' le $jis8) and ($jis8 le '9F')) {
    }
    elsif ($jis8 eq 'A0') {
    }
    elsif (('E0' le $jis8) and ($jis8 le 'FC')) {
    }
    elsif (('FD' le $jis8) and ($jis8 le 'FF')) {
    }
    else {
###     print STDOUT ' [', pack('H*', UTF8_by_Unicode(Unicode_by_CP932($jis8))), ']';
    }
    print STDOUT "\n";
    $spua_jp++;
}

my %unicode = map { $_ => 1 } (
    keys_of_CP932X_by_Unicode(),
    keys_of_CP932_by_Unicode(),
    keys_of_ShiftJIS2004_by_Unicode(),
    keys_of_CP00930_by_Unicode(),
    keys_of_KEIS78_by_Unicode(),
    keys_of_KEIS83_by_Unicode(),
    keys_of_KEIS90_by_Unicode(),
    keys_of_JEF_by_Unicode(),
    keys_of_JIPSJ_by_Unicode(),
    keys_of_JIPSE_by_Unicode(),
    keys_of_LetsJ_by_Unicode(),
);

my %data = ();
my %char = ();
for my $unicode (sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %unicode) {
    $data{CP932X_by_Unicode($unicode)} = 
        join("", map { sprintf($_->[1],$_->[0]) }
        [(CP932X_by_Unicode      ($unicode) || '  ----  ') => '%-8s ' ], # CP932X, Extended CP932 to JIS X 0213 using 0x9C5A as single shift
        [(CP932_by_Unicode       ($unicode) || ' -- '    ) => '%-4s ' ], # CP932
        [(ShiftJIS2004_by_Unicode($unicode) || ' -- '    ) => '%-4s ' ], # Shift_JIS-2004
        [(CP00930_by_Unicode     ($unicode) || ' -- '    ) => '%-4s ' ], # IBM CP00930(CP00290+CP00300), CCSID 5026 katakana
        [(KEIS78_by_Unicode      ($unicode) || ' -- '    ) => '%-4s ' ], # HITACHI KEIS78
        [(KEIS83_by_Unicode      ($unicode) || ' -- '    ) => '%-4s ' ], # HITACHI KEIS83
        [(KEIS90_by_Unicode      ($unicode) || ' -- '    ) => '%-4s ' ], # HITACHI KEIS90
        [(JEF_by_Unicode         ($unicode) || ' -- '    ) => '%-4s ' ], # FUJITSU JEF
        [(JIPSJ_by_Unicode       ($unicode) || ' -- '    ) => '%-4s ' ], # NEC JIPS(J)
        [(JIPSE_by_Unicode       ($unicode) || ' -- '    ) => '%-4s ' ], # NEC JIPS(E)
        [(LetsJ_by_Unicode       ($unicode) || ' -- '    ) => '%-4s ' ], # UNISYS LetsJ
        [(                        $unicode  || ' --- '   ) => '%-9s ' ], # Unicode
        [(UTF8_by_Unicode        ($unicode) || '  --  '  ) => '%-12s '], # UTF-8
    );
    $char{CP932X_by_Unicode($unicode)} = pack('H*', UTF8_by_Unicode($unicode));
}

my @cp932x_full = ();
for my $cp932x_ss1 ('', '9C5A') {
    for my $octet1 (qw(
           81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F
        90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F

        E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 EA EB EC ED EE EF
        F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC         
    )) {
        for my $octet2 (qw(
            40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F
            50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F
            60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F
            70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E   
            80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F
            90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F
            A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF
            B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF
            C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF
            D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD DE DF
            E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 EA EB EC ED EE EF
            F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC         
        )) {
            push @cp932x_full, $cp932x_ss1 . $octet1 . $octet2;
        }
    }
}

my %comment = (

    '5C' => <<'COMMENT',
#
# ASCII and JIS X 0201 Roman (2001-04-30)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-yen.html
#
# When converting EUC-JP and Shift_JIS, handling of 0x5c and 0x7e can be a problem.
# Since both encodings have long history and Japanese people have lot of experience
# how to handle them, I now introduce it.
#
# Solution is very simple. Just regard YEN SIGN and REVERSE SOLIDUS as a different
# glyphs of the same character. Then, distinction between ASCII and JIS X 0201
# Roman can be neglected.
#
# Thus, when a Japanese person (almost Japanese people don't know about encoding;
# a certain amount of people [Windows and Macintosh users] know the word "Shift_JIS"
# as the only usable encoding) says "Shift_JIS", almost always it means "CP932".
#
# Please don't blame such Japanese people who don't aware of distinction between
# Shift_JIS and CP932. The difference between Shift_JIS and CP932 was only that
# CP932 has extension characters. It is the introduction of Unicode and conversion
# to/from it that brought a confusing incompatibility of non-letter symbols between
# Shift_JIS and CP932.
#
# The following is the reason why I wrote that when a Japanese person says
# "Shift_JIS", almost always it means "CP932". For example, DOS/Windows programmers
# write YEN SIGN + "n" to mean new line (in Shift_JIS, strictly speaking, CP932).
# DOS/Windows use YEN SIGN (0x5c) for directory name separator. This is why
# Microsoft cannot convert 0x5c in CP932 into characters other than U+005C.
#
# Not only Windows users but also UNIX users regarded 0x5c in Shift_JIS as an
# ambiguous character of YEN SIGN and REVERSE SOLIDUS. For example, popular Japanese
# encode converters such as nkf and qkc don't care about distinction between ASCII
# (0x21-0x7e in EUC-JP) and JIS X 0201 Roman (0x21-0x7e in Shift_JIS). When I often
# use TeraTerm, a telnet/ssh client for Windows, and read YEN SIGN, I read it as a
# REVERSE SOLIDUS according to the context. (When a Japanese person is a writer,
# it means YEN SIGN in most cases. When a non-Japanese person is a writer, it
# always means REVERSE SOLIDUS).
#
# Thus, I don't complain if 0x5c in Shift_JIS is mapped into U+005C. Rather,
# distinction of them (i.e., being strict to official standards) might confuse
# many Japanese people.
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
# Tomohiro KUBOTA <debian at tmail dot plala dot or dot jp>
#
COMMENT

    '7E' => <<'COMMENT',
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
COMMENT

    '8140' => <<'COMMENT',
#
# FACOM JEF Character code index dictionary, 99FR-0012-2 and 99FR-0012-3
# show us that DBCS SPACE code is "\x40\x40", but nobody use so.
#
COMMENT

    '8150' => <<'COMMENT',
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
COMMENT

    '815C' => <<'COMMENT',
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
COMMENT

    '815F' => <<'COMMENT',
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
COMMENT

    '8160' => <<'COMMENT',
#
# Wave dash
# https://en.wikipedia.org/wiki/Wave_dash
#
# Standard     Release  Code-Point        Glyph     Note
# -----------------------------------------------------------------------------
# Unicode 1.0  1991     U+301C WAVE DASH  \/\ (VA)  The glyph was different from the original JIS C 6226 or JIS X 0208.
# Unicode 8.0  2015     U+301C WAVE DASH  /\/ (AV)  The glyph was fixed in Errata fixed in Unicode 8.0.0, The Unicode Consortium, 6 Oct 2014
# JIS C 6226   1978     01-33             /\/ (AV)  The wave was not stressed this much.
# JIS X 0208   1990     01-33             /\/ (AV)  
# JIS X 0213   2000     1-01-33           /\/ (AV)  
# -----------------------------------------------------------------------------
#
# Errata Fixed in Unicode 8.0.0
# http://www.unicode.org/versions/Unicode8.0.0/erratafixed.html
#
# 2014-October-6
# The character U+301C WAVE DASH was encoded to represent JIS C 6226-1978
# 1-33. However, the representative glyph is inverted relative to the
# original source. The glyph will be modified in future editions to match
# the JIS source. The glyph shown below on the left is the incorrect glyph.
# The corrected glyph is shown on the right. (See document L2/14-198 for
# further context for this change.) 
#
# (Japanese) Wave dash
# https://ja.wikipedia.org/wiki/%E6%B3%A2%E3%83%80%E3%83%83%E3%82%B7%E3%83%A5
#
# (Japanese) I'm just a programmer, cannot fix Unicode bug -- Dan Kogai-san 2006.05.10 11:00
# http://blog.livedoor.jp/dankogai/archives/50488765.html
#
# (Japanese) About WAVE DASH problem -- yasuoka-san 2006.05.10 18:29
# https://srad.jp/~yasuoka/journal/357074/
#
# (Japanese) Reason why Unicode's WAVE DASH example glyph was modified for the first time in 25 years
# https://internet.watch.impress.co.jp/docs/special/691658.html
#
COMMENT

    '8161' => <<'COMMENT',
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
COMMENT

    '817C' => <<'COMMENT',
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
COMMENT

    '818F' => <<'COMMENT',
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
COMMENT

    '8191' => <<'COMMENT',
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
COMMENT

    '81B8' => <<'COMMENT',
# Category 1(1 of 2) JIS C 6226-1978 Versus JIS X 0208-1983, CJKV Information Processing by Ken Lunde 1999
COMMENT

    '81CA' => <<'COMMENT',
#
# Conversion tables differ between venders (2002-04-04)
# http://www8.plala.or.jp/tkubota1/unicode-symbols-map2.html
#
# JIS      0208   SJIS   CP932  APPLE  0213   IBMGLY IBMIRV G-EUC  G-SJIS
# -----------------------------------------------------------------------
# 0x005C   ------ U+00A5 U+005C U+00A5 ------ U+00A5 U+005C U+005C U+00A5
# 0x007E   ------ U+203E U+007E U+007E ------ U+203E U+007E U+007E U+203E
# 0x2131   U+FFE3 U+FFE3 U+FFE3 U+FFE3 U+203E U+FFE3 U+FFE3 U+FFE3 U+FFE3
# 0x213D   U+2015 U+2015 U+2015 U+2014 U+2014 U+2014 U+2014 U+2015 U+2015
# 0x2140   U+005C U+005C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C U+FF3C
# 0x2141   U+301C U+301C U+FF5E U+301C U+301C U+301C U+301C U+301C U+301C
# 0x2142   U+2016 U+2016 U+2225 U+2016 U+2016 U+2016 U+2016 U+2016 U+2016
# 0x215D   U+2212 U+2212 U+FF0D U+2212 U+2212 U+2212 U+2212 U+2212 U+2212
# 0x216F   U+FFE5 U+FFE5 U+FFE5 U+FFE5 U+00A5 U+FFE5 U+FFE5 U+FFE5 U+FFE5
# 0x2171   U+00A2 U+00A2 U+FFE0 U+00A2 U+00A2 U+FFE0 U+FFE0 U+00A2 U+00A2
# 0x2172   U+00A3 U+00A3 U+FFE1 U+00A3 U+00A3 U+FFE1 U+FFE1 U+00A3 U+00A3
# 0x224C   U+00AC U+00AC U+FFE2 U+00AC U+00AC U+FFE2 U+FFE2 U+00AC U+00AC
#
COMMENT

    '824F' => <<'COMMENT',
# End of Category 1(1 of 2) JIS C 6226-1978 Versus JIS X 0208-1983, CJKV Information Processing by Ken Lunde 1999
COMMENT

    '849F' => <<'COMMENT',
# Category 1(2 of 2) JIS C 6226-1978 Versus JIS X 0208-1983, CJKV Information Processing by Ken Lunde 1999
COMMENT

    '8740' => <<'COMMENT',
# End of Category 1(2 of 2) JIS C 6226-1978 Versus JIS X 0208-1983, CJKV Information Processing by Ken Lunde 1999
# NEC Kanji Row 13, Appendix C, CJKV Information Processing by Ken Lunde 1999
COMMENT

    '889F' => <<'COMMENT',
# End of NEC Kanji Row 13, Appendix C, CJKV Information Processing by Ken Lunde 1999
COMMENT

    '8D56' => <<'COMMENT',
# IBM Selected Kanji and Non-Kanji, Appendix Q, CJKV Information Processing by Ken Lunde 1999
#
# U+6602
# https://glyphwiki.org/wiki/u6602
#
COMMENT

    '8D57' => <<'COMMENT',
# End of IBM Selected Kanji and Non-Kanji, Appendix Q, CJKV Information Processing by Ken Lunde 1999
COMMENT

    '92CB' => <<'COMMENT',
#
# U+585A
# https://glyphwiki.org/wiki/u585a
#
COMMENT

    '9C5B' => <<'COMMENT',
#
# One 9C5A meaning requires 9C5A9C5A
#
# 9C5A9C5A 9C5A 9C5A 59CD D7BB D7BB D7BB D7BB 573B E65E D7BB 5F41      E5BD81       F3B483BE
#
COMMENT

    'EA9F' => <<'COMMENT',
# Category 2 JIS C 6226-1978 Versus JIS X 0208-1983, CJKV Information Processing by Ken Lunde 1999
COMMENT

    'EAA3' => <<'COMMENT',
# End of Category 2 JIS C 6226-1978 Versus JIS X 0208-1983, CJKV Information Processing by Ken Lunde 1999
# JIS X 0208-1983 Versus JIS X 0208-1990, CJKV Information Processing by Ken Lunde 1999
COMMENT

    'FA40' => <<'COMMENT',
# End of JIS X 0208-1983 Versus JIS X 0208-1990, CJKV Information Processing by Ken Lunde 1999
# IBM Selected Kanji and Non-kanji, Appendix C, CJKV Information Processing by Ken Lunde 1999
COMMENT

    'FA9C' => <<'COMMENT',
#
# U+FA10
# https://glyphwiki.org/wiki/ufa10
#
COMMENT

    'FAD0' => <<'COMMENT',
# IBM Selected Kanji and Non-Kanji, Appendix Q, CJKV Information Processing by Ken Lunde 1999
#
# U+663B
# https://glyphwiki.org/wiki/u663b
#
COMMENT

    'FAD1' => <<'COMMENT',
# End of IBM Selected Kanji and Non-Kanji, Appendix Q, CJKV Information Processing by Ken Lunde 1999
COMMENT

    '--------' => <<'COMMENT',
######################################################################################
# End of Jacode4e compatible table
######################################################################################
######################################################################################
# Jacode4e::RoundTrip supplement table
######################################################################################
#-------------------------------------------------------------------------------------
# CP00930 User-defined Area: ([\x69-\x71][\x41-\xFE]|[\x72][\x41-\xEA])
#
# C-H 3-3220-024 IBM Corp. 2002, Table 2. Structure of Japanese DBCS-Host 6.2 Structure of Japanese DBCS-Host
# CJKV Information Processing by Ken Lunde 1999, Table D-20: IBM Japanese DBCS-Host Encoding Specifications
# The last user-defined character in this region is 0x72EA.
#
#-------------------------------------------------------------------------------------
# KEIS User-defined Area and Unused Area: ([\x7D\x7F\x81-\x9E\xA0][\xA1-\xFE])
#
# 8080-2-100-10 by 1986, 1989, Hitachi, Ltd., Table 4-1 KEIS83 Encoding Specifications
# CJKV Information Processing by Ken Lunde 1999, Table D-23: KEIS Encoding Specifications
# Table D-23 said that user-defined area is (?:[\x81-\xA0][\xA1-\xFE]), but
# ([\x9F][\xA1-\xFE]) is already used by Japan Geographic Data Center.
#
# 8080-2-100-10 tells us unused area, ([\x7D\x7F][\xA1-\xFE]). I decided to use that
# area without permission by Hitachi, Ltd. Yes, this is a hack we love.
#
#-------------------------------------------------------------------------------------
# JEF User-defined Area: ([\x80-\xA0][\xA1-\xFE])
#
# CJKV Information Processing by Ken Lunde 1999, Table D-14: JEF Encoding Specifications
#
#-------------------------------------------------------------------------------------
# JIPS User-defined Area: ([\x74-\x7E][\x21-\x7E]|[\xE0-\xFE][\xA1-\xFE])
#
# ZBB10-3, ZBB11-2 by NEC Corporation 1982, 1993, Figure-1 JIPS code plane
#
#-------------------------------------------------------------------------------------
# LetsJ User-defined Area: ([\x31-\x40\x6D-\x78][\xA1-\xFE])
#
# Heterogeneous database cooperation among heterogeneous OS environments
# http://www.unisys.co.jp/tec_info/tr56/5605.htm
#
#-------------------------------------------------------------------------------------
# UTF-8 User-defined Area: ([\xE0][\xA0-\xBF][\x80-\xBF]|[\xE1-\xEF][\x80-\xBF][\x80-\xBF])
#
# Private-Use Characters
# http://www.unicode.org/faq/private_use.html
#
#-------------------------------------------------------------------------------------
COMMENT

    '9C5A815C' => <<'COMMENT',
# End of IBM Selected Kanji and Non-kanji, Appendix C, CJKV Information Processing by Ken Lunde 1999
#
# (Japanese) ghost characters
# https://ja.wikipedia.org/wiki/%E5%B9%BD%E9%9C%8A%E6%96%87%E5%AD%97
#
# U+5F41
# https://glyphwiki.org/wiki/u5f41
#
COMMENT

    '9C5A879F' => <<'COMMENT',
# JIS X 0213:2000 Versus JIS X 0213:2004 (1 of 5)
COMMENT

    '9C5A87A0' => <<'COMMENT',
# End of JIS X 0213:2000 Versus JIS X 0213:2004 (1 of 5)
COMMENT

    '9C5A889E' => <<'COMMENT',
# JIS X 0213:2000 Versus JIS X 0213:2004 (2 of 5)
COMMENT

    '9C5A9874' => <<'COMMENT',
# End of JIS X 0213:2000 Versus JIS X 0213:2004 (2 of 5)
COMMENT

    '9C5A989E' => <<'COMMENT',
# JIS X 0213:2000 Versus JIS X 0213:2004 (3 of 5)
COMMENT

    '9C5A9C5A' => <<'COMMENT',
# End of JIS X 0213:2000 Versus JIS X 0213:2004 (3 of 5)
#
# (Japanese) ghost characters
# https://ja.wikipedia.org/wiki/%E5%B9%BD%E9%9C%8A%E6%96%87%E5%AD%97
#
# U+5F41
# https://glyphwiki.org/wiki/u5f41
#
COMMENT

    '9C5AEAA5' => <<'COMMENT',
# JIS X 0213:2000 Versus JIS X 0213:2004 (4 of 5)
COMMENT

    '9C5AEAA6' => <<'COMMENT',
# End of JIS X 0213:2000 Versus JIS X 0213:2004 (4 of 5)
COMMENT

    '9C5AEFF8' => <<'COMMENT',
# JIS X 0213:2000 Versus JIS X 0213:2004 (5 of 5)
COMMENT

    '9C5AF040' => <<'COMMENT',
# End of JIS X 0213:2000 Versus JIS X 0213:2004 (5 of 5)
COMMENT
);

for my $cp932x (@cp932x_full) {
    if (defined $data{$cp932x}) {
        if ($comment{$cp932x} ne '') {
            print STDOUT $comment{$cp932x};
            delete $comment{$cp932x};
        }
        print STDOUT $data{$cp932x};
        print STDOUT UTF8_by_Unicode(sprintf('%05X', $spua_jp));
###     print STDOUT ' [', $char{$cp932x}, ']';
        print STDOUT "\n";
    }
    $spua_jp++;
}

print STDOUT <<COMMENT;
############################################################################################
# End of table
############################################################################################
COMMENT

1;

__END__
