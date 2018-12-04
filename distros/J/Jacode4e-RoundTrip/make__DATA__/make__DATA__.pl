######################################################################
#
# make__DATA__.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
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

binmode(STDOUT);

print STDOUT <<'END';
#+++++++------------------------------------------------------------------------------- CP932X, Extended CP932 to JIS X 0213 using 0x9C5A as single shift
#||||||| ++++-------------------------------------------------------------------------- Microsoft CP932, IANA Windows-31J
#||||||| |||| ++++--------------------------------------------------------------------- JISC Shift_JIS-2004
#||||||| |||| |||| ++++---------------------------------------------------------------- IBM CP00930(CP00290+CP00300), CCSID 5026 katakana
#||||||| |||| |||| |||| ++++----------------------------------------------------------- HITACHI KEIS78
#||||||| |||| |||| |||| |||| ++++------------------------------------------------------ HITACHI KEIS83
#||||||| |||| |||| |||| |||| |||| ++++------------------------------------------------- HITACHI KEIS90
#||||||| |||| |||| |||| |||| |||| |||| ++++-------------------------------------------- FUJITSU JEF
#||||||| |||| |||| |||| |||| |||| |||| |||| ++++--------------------------------------- NEC JIPS(J)
#||||||| |||| |||| |||| |||| |||| |||| |||| |||| ++++---------------------------------- NEC JIPS(E)
#||||||| |||| |||| |||| |||| |||| |||| |||| |||| |||| +++++++++------------------------ Unicode
#||||||| |||| |||| |||| |||| |||| |||| |||| |||| |||| ||||||||| ++++++++++++----------- UTF-8
#||||||| |||| |||| |||| |||| |||| |||| |||| |||| |||| ||||||||| |||||||||||| ++++++++-- UTF-8-SPUA-JP, JIS X 0213 on SPUA ordered by JIS level, plane, row, cell
#2345678 1234 1234 1234 1234 1234 1234 1234 1234 1234 123456789 123456789012 12345678
#VVVVVVV VVVV VVVV VVVV VVVV VVVV VVVV VVVV VVVV VVVV VVVVVVVVV VVVVVVVVVVVV VVVVVVVV
__DATA__
END

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

for my $cp932x (@cp932x_full) {
    if (defined $data{$cp932x}) {
        print STDOUT $data{$cp932x};
        print STDOUT UTF8_by_Unicode(sprintf('%05X', $spua_jp));
###     print STDOUT ' [', $char{$cp932x}, ']';
        print STDOUT "\n";
    }
    $spua_jp++;
}

1;

__END__
