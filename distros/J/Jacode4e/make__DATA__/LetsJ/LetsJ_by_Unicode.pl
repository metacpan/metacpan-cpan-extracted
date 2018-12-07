######################################################################
#
# LetsJ_by_Unicode.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# ANSI X3.4-1968 (US-ASCII) with 0x60/0x27 as left/right single quotation mark to Unicode
# http://www.unicode.org/Public/MAPPINGS/VENDORS/MISC/US-ASCII-QUOTES.TXT
#
# JIS X 0201 (1976) to Unicode 1.1 Table
# http://www.unicode.org/Public/MAPPINGS/OBSOLETE/EASTASIA/JIS/JIS0201.TXT
#
# JIS X 0208 (1990) to Unicode
# http://www.unicode.org/Public/MAPPINGS/OBSOLETE/EASTASIA/JIS/JIS0208.TXT
#
# JIS X 0212 (1990) to Unicode
# http://www.unicode.org/Public/MAPPINGS/OBSOLETE/EASTASIA/JIS/JIS0212.TXT

use strict; die $_ if ($_=`$^X -cw @{[__FILE__]} 2>&1`) !~ /^.+ syntax OK$/;
use File::Basename;

my %LetsJ_by_Unicode = ();

# The 8-bit Japanese coded character set defined as JISASCII. JISASCII is a
# combination of the ASCII coded character set and the Japanese Industrial
# Standard JISX0201 coded character set, which represents 63 Katakana characters
# placed where no ASCII characters are defined. The 8-bit ASCII characters are
# encoded in the byte range x00-x7F. The 8-bit Katakana characters are encoded
# in the byte range xA1-xDF.

open(FILE,"@{[File::Basename::dirname(__FILE__)]}/http.__www.unicode.org_Public_MAPPINGS_VENDORS_MISC_US-ASCII-QUOTES.TXT") || die;
while (<FILE>) {
    chomp;
    next if /^#/;
    my($ansix34, $Unicode) = split(/\t/, $_);
    if ($ansix34 =~ /^0x([0123456789ABCDEF]{2})$/) {
        my $ansix34_hex = $1;
        if ($Unicode =~ /^0x([0123456789ABCDEF]{4})$/) {
            $LetsJ_by_Unicode{$1} = $ansix34_hex;
        }
        else {
            die;
        }
    }
    else {
        die;
    }
}
close(FILE);

open(FILE,"@{[File::Basename::dirname(__FILE__)]}/http.__www.unicode.org_Public_MAPPINGS_OBSOLETE_EASTASIA_JIS_JIS0201.TXT") || die;
while (<FILE>) {
    chomp;
    next if /^#/;
    my($jisx0201, $Unicode) = split(/\t/, $_);
    if ($jisx0201 =~ /^0x[01234567][0123456789ABCDEF]$/) {
        # ANSI X3.4-1968 (US-ASCII)
    }
    elsif ($jisx0201 =~ /^0x([0123456789ABCDEF]{2})$/) {
        my $jisx0201_hex = $1;
        if ($Unicode =~ /^0x([0123456789ABCDEF]{4})$/) {
            $LetsJ_by_Unicode{$1} = $jisx0201_hex;
        }
        else {
            die;
        }
    }
    else {
        die;
    }
}
close(FILE);

# A 16-bit coded character set based on the Japanese Industrial Standard JISX0208
# coded character set, which represents over 6,000 basic Japanese Kanji and other
# graphic characters. The LetsJ encoding places these characters in the byte pair
# range (xA1-xFE, xA1-xFE).

open(FILE,"@{[File::Basename::dirname(__FILE__)]}/http.__www.unicode.org_Public_MAPPINGS_OBSOLETE_EASTASIA_JIS_JIS0208.TXT") || die;
while (<FILE>) {
    chomp;
    next if /^#/;
    my($sjis, $jisx0208, $Unicode) = split(/\t/, $_);
    if ($jisx0208 =~ /^0x([0123456789ABCDEF]{2})([0123456789ABCDEF]{2})$/) {
        my $jisx0208_hex_1 = $1;
        my $jisx0208_hex_2 = $2;
        if ($Unicode =~ /^0x([0123456789ABCDEF]{4})$/) {
            $LetsJ_by_Unicode{$1} = GL2GR($jisx0208_hex_1) . GL2GR($jisx0208_hex_2);
        }
        else {
            die;
        }
    }
    else {
        die;
    }
}
close(FILE);

# A 16-bit coded character set based on the Japanese Industrial Standard JISX0212
# coded character set, which represents over 6,000 supplementary Japanese Kanji
# and other graphic characters. The LetsJ encoding places these characters in the
# byte pair range (xA1-xFE, x21-x7E).

open(FILE,"@{[File::Basename::dirname(__FILE__)]}/http.__www.unicode.org_Public_MAPPINGS_OBSOLETE_EASTASIA_JIS_JIS0212.TXT") || die;
while (<FILE>) {
    chomp;
    next if /^#/;
    my($jisx0212, $Unicode) = split(/\t/, $_);
    if ($jisx0212 =~ /^0x([0123456789ABCDEF]{2})([0123456789ABCDEF]{2})$/) {
        my $jisx0212_hex_1 = $1;
        my $jisx0212_hex_2 = $2;
        if ($Unicode =~ /^0x([0123456789ABCDEF]{4})$/) {
            $LetsJ_by_Unicode{$1} = GL2GR($jisx0212_hex_1) . $jisx0212_hex_2;
        }
        else {
            die;
        }
    }
    else {
        die;
    }
}
close(FILE);

# IDEOGRAPHIC SPACE
#
# The 8-bit space character in the JISASCII coded character set is located at
# code position x20. The 16-bit ideographic space character in the JISX0208
# coded character set is located at code position x2020.

$LetsJ_by_Unicode{'3000'} = '2020'; # IDEOGRAPHIC SPACE

sub GL2GR {
    my %GL2GR = ();
    @GL2GR{
        qw(
           21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F
        30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F
        40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F
        50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F
        60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F
        70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E
        )
    } = qw(
           A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF
        B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF
        C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF
        D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD DE DF
        E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 EA EB EC ED EE EF
        F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC FD FE
    );

    return $GL2GR{$_[0]};
}

sub LetsJ_by_Unicode {
    my($unicode) = @_;
    return $LetsJ_by_Unicode{$unicode};
}

sub keys_of_LetsJ_by_Unicode {
    return keys %LetsJ_by_Unicode;
}

sub values_of_LetsJ_by_Unicode {
    return values %LetsJ_by_Unicode;
}

1;

__END__

Unisys e-@ction
ClearPath Enterprise
Servers
MultiLingual System (MLS)
Administration, Operations, and
Programming Guide
ClearPath MCP Release 7.0
November 2001
Printed in USA 8600 0288-305

LetsJ Coded Character Set (816CS00.00)

LetsJ is a mixed, multibyte coded character set used on Japanese ClearPath IX
systems to represent 8-bit ASCII and Katakana characters and 16-bit Kanji
characters. This coded character set consists of

The 8-bit Japanese coded character set defined as JISASCII. JISASCII is a
combination of the ASCII coded character set and the Japanese Industrial
Standard JISX0201 coded character set, which represents 63 Katakana characters
placed where no ASCII characters are defined. The 8-bit ASCII characters are
encoded in the byte range x00-x7F. The 8-bit Katakana characters are encoded in
the byte range xA1-xDF. Refer to Section 12, "Eight-Bit Coded Character Sets:
FrenchArabicE to NorwayBTOS," for a complete description of the JISASCII coded
character set.

A 16-bit coded character set based on the Japanese Industrial Standard JISX0208
coded character set, which represents over 6,000 basic Japanese Kanji and other
graphic characters. The LetsJ encoding places these characters in the byte pair
range (xA1-xFE, xA1-xFE).

A 16-bit coded character set based on the Japanese Industrial Standard JISX0212
coded character set, which represents over 6,000 supplementary Japanese Kanji
and other graphic characters. The LetsJ encoding places these characters in the
byte pair range (xA1-xFE, x21-x7E).

Other 16-bit customer-defined custom Japanese characters. The LetsJ encoding
places these characters in the byte pair range (x21-x7E, xA1-xFE).

The 8-bit space character in the JISASCII coded character set is located at code
position x20. The 16-bit ideographic space character in the JISX0208 coded
character set is located at code position x2020.

Within a sequence of characters, all of the 16-bit character data must be
preceded by the two-byte lock shift character x93nn, where "nn" is an
even-valued hex number, to signal the beginning of a 16-bit character string.
Once in the 16-bit mode, the two-byte lock shift character x93nn,where "nn" is
an odd-valued hex number, is required to signal the beginning of 8-bit data.

Unlike the SDO/EDO mechanism of JapanEBCDICJBIS8 and JISASCIIJSBIS7, there is
no need to put a lock shift character at the end of a string. A lock shift
character is only needed when switching from one mode to another. The current
mode of input, 8-bit or 16-bit, continues until the end of the string or until
another lock shift character is encountered.
