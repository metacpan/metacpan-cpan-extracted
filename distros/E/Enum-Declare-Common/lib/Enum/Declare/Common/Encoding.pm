package Enum::Declare::Common::Encoding;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Type :Str :Type :Export {
	UTF8      = "utf-8",
	UTF16LE   = "utf-16le",
	UTF16BE   = "utf-16be",
	UTF32LE   = "utf-32le",
	UTF32BE   = "utf-32be",
	ASCII     = "ascii",
	Latin1    = "iso-8859-1",
	ISO8859_2 = "iso-8859-2",
	ISO8859_3 = "iso-8859-3",
	ISO8859_4 = "iso-8859-4",
	ISO8859_5 = "iso-8859-5",
	ISO8859_6 = "iso-8859-6",
	ISO8859_7 = "iso-8859-7",
	ISO8859_8 = "iso-8859-8",
	ISO8859_9 = "iso-8859-9",
	ISO8859_10 = "iso-8859-10",
	ISO8859_13 = "iso-8859-13",
	ISO8859_14 = "iso-8859-14",
	ISO8859_15 = "iso-8859-15",
	Windows1250 = "windows-1250",
	Windows1251 = "windows-1251",
	Windows1252 = "windows-1252",
	Windows1253 = "windows-1253",
	Windows1254 = "windows-1254",
	Windows1255 = "windows-1255",
	Windows1256 = "windows-1256",
	ShiftJIS  = "shift_jis",
	EUCJP     = "euc-jp",
	ISO2022JP = "iso-2022-jp",
	GB2312    = "gb2312",
	GBK       = "gbk",
	GB18030   = "gb18030",
	Big5      = "big5",
	EUCKR     = "euc-kr",
	KOI8R     = "koi8-r",
	KOI8U     = "koi8-u"
};

1;

=head1 NAME

Enum::Declare::Common::Encoding - Character encoding name constants

=head1 SYNOPSIS

    use Enum::Declare::Common::Encoding;

    say UTF8;      # "utf-8"
    say ASCII;     # "ascii"
    say ShiftJIS;  # "shift_jis"
    say Latin1;    # "iso-8859-1"

=head1 ENUMS

=head2 Type :Str :Export

36 character encoding constants covering Unicode (UTF-8/16/32), ASCII,
ISO-8859 variants, Windows code pages, CJK encodings (Shift_JIS, EUC-JP,
GB2312, GBK, GB18030, Big5, EUC-KR), and Cyrillic (KOI8-R, KOI8-U).

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
