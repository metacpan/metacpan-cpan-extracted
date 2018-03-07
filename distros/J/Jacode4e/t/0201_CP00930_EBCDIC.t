######################################################################
#
# 0201_CP00930_EBCDIC.t
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# CPGID 00290
# https://www-01.ibm.com/software/globalization/cdra/
# https://www-01.ibm.com/software/globalization/cp/cp00290.html
# ftp://ftp.software.ibm.com/software/globalization/gcoc/attachments/CP00290.pdf
# ftp://ftp.software.ibm.com/software/globalization/gcoc/attachments/CP00290.txt

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { $|=1; print "1..512\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

my %EBCDIC_IBM_CPGID00290_like_by_JIS8 = map { sprintf('%02X',$_) => (qw(
    00 10 40 F0 7C D7 79 78 20 30 6A 58 91 A5 57 DC
    01 11 5A F1 C1 D8 62 8B 21 31 41 81 92 A6 59 DD
    02 12 7F F2 C2 D9 63 9B 22 1A 42 82 93 A7 5F DE
    03 13 7B F3 C3 E2 64 AB 23 33 43 83 94 A8 9C DF
    37 3C E0 F4 C4 E3 65 B3 24 34 44 84 95 A9 A1 EA
    2D 3D 6C F5 C5 E4 66 B4 25 35 45 85 96 AA B1 EB
    2E 32 50 F6 C6 E5 67 B5 06 36 46 86 97 AC B2 EC
    2F 26 7D F7 C7 E6 68 B6 17 08 47 87 98 AD E1 ED
    16 18 4D F8 C8 E7 69 B7 28 38 48 88 99 AE CA EE
    05 19 5D F9 C9 E8 71 B8 29 39 49 89 9A AF CB EF
    15 3F 5C 7A D1 E9 72 B9 2A 3A 51 8A 9D BA CC FA
    0B 27 4E 5E D2 70 73 C0 2B 3B 52 8C 9E BB CD FB
    0C 1C 6B 4C D3 5B 74 4F 2C 04 53 8D 9F BC CE FC
    0D 1D 60 7E D4 80 75 D0 09 14 54 8E A2 BD CF FD
    0E 1E 4B 6E D5 B0 76 A0 0A 3E 55 8F A3 BE DA FE
    0F 1F 61 6F D6 6D 77 07 1B 4A 56 90 A4 BF DB FF
))[ ($_%16)*16+int($_/16) ]} (0..255);

my %JIS8_by_EBCDIC_IBM_CPGID00290_like = map { sprintf('%02X',$_) => (qw(
    00 10 80 90 20 26 2D 5B 5D BF 7E 5E 7B 7D 24 30
    01 11 81 91 A1 AA 2F 69 B1 C0 E4 E5 41 4A E7 31
    02 12 82 16 A2 AB 61 6A B2 C1 CD E6 42 4B 53 32
    03 13 83 93 A3 AC 62 6B B3 C2 CE 74 43 4C 54 33
    9C 9D 84 94 A4 AD 63 6C B4 C3 CF 75 44 4D 55 34
    09 0A 85 95 A5 AE 64 6D B5 C4 D0 76 45 4E 56 35
    86 08 17 96 A6 AF 65 6E B6 C5 D1 77 46 4F 57 36
    7F 87 1B 04 A7 E0 66 6F B7 C6 D2 78 47 50 58 37
    97 18 88 98 A8 B0 67 70 B8 C7 D3 79 48 51 59 38
    8D 19 89 99 A9 E1 68 60 B9 C8 D4 7A 49 52 5A 39
    8E 92 8A 9A 9F 21 A0 3A BA C9 D5 DA E8 EE F4 FA
    0B 8F 8B 9B 2E 5C 2C 23 71 72 73 DB E9 EF F5 FB
    0C 1C 8C 14 3C 2A 25 40 BB E3 D6 DC EA F0 F6 FC
    0D 1D 05 15 28 29 5F 27 BC CA D7 DD EB F1 F7 FD
    0E 1E 06 9E 2B 3B 3E 3D BD CB D8 DE EC F2 F8 FE
    0F 1F 07 1A 7C E2 3F 22 BE CC D9 DF ED F3 F9 FF
))[ ($_%16)*16+int($_/16) ]} (0..255);

if (scalar(keys %EBCDIC_IBM_CPGID00290_like_by_JIS8) != 256) {
    die;
}

if (scalar(keys %JIS8_by_EBCDIC_IBM_CPGID00290_like) != 256) {
    die;
}

for (0..255) {
    my $hex = sprintf('%02X',$_);
    if (not exists $JIS8_by_EBCDIC_IBM_CPGID00290_like{$hex}) {
        die;
    }
    if (not defined $JIS8_by_EBCDIC_IBM_CPGID00290_like{$hex}) {
        die;
    }
    if ($EBCDIC_IBM_CPGID00290_like_by_JIS8{$JIS8_by_EBCDIC_IBM_CPGID00290_like{$hex}} ne $hex) {
        die "\$hex=($hex) \$JIS8_by_EBCDIC_IBM_CPGID00290_like{$hex}=($JIS8_by_EBCDIC_IBM_CPGID00290_like{$hex}) \$EBCDIC_IBM_CPGID00290_like_by_JIS8{$JIS8_by_EBCDIC_IBM_CPGID00290_like{$hex}}=($EBCDIC_IBM_CPGID00290_like_by_JIS8{$JIS8_by_EBCDIC_IBM_CPGID00290_like{$hex}})";
    }
}

for (0..255) {
    my $hex = sprintf('%02X',$_);
    if (not exists $EBCDIC_IBM_CPGID00290_like_by_JIS8{$hex}) {
        die;
    }
    if (not defined $EBCDIC_IBM_CPGID00290_like_by_JIS8{$hex}) {
        die;
    }
    if ($JIS8_by_EBCDIC_IBM_CPGID00290_like{$EBCDIC_IBM_CPGID00290_like_by_JIS8{$hex}} ne $hex) {
        die "\$hex=($hex) \$EBCDIC_IBM_CPGID00290_like_by_JIS8{$hex}=($EBCDIC_IBM_CPGID00290_like_by_JIS8{$hex}) \$JIS8_by_EBCDIC_IBM_CPGID00290_like{$EBCDIC_IBM_CPGID00290_like_by_JIS8{$hex}}=($JIS8_by_EBCDIC_IBM_CPGID00290_like{$EBCDIC_IBM_CPGID00290_like_by_JIS8{$hex}})";
    }
}

my %jis2ebcdic_IBM_CPGID00290_like = qw(
    9F 4A
    A0 6A
    E0 57
    E1 59
    E2 5F
    E3 9C
    E4 A1
    E5 B1
    E6 B2
    E7 E1

    20 40
    21 5A
    22 7F
    23 7B
    24 E0
    25 6C
    26 50
    27 7D
    28 4D
    29 5D
    2A 5C
    2B 4E
    2C 6B
    2D 60
    2E 4B
    2F 61
    30 F0
    31 F1
    32 F2
    33 F3
    34 F4
    35 F5
    36 F6
    37 F7
    38 F8
    39 F9
    3A 7A
    3B 5E
    3C 4C
    3D 7E
    3E 6E
    3F 6F
    40 7C
    41 C1
    42 C2
    43 C3
    44 C4
    45 C5
    46 C6
    47 C7
    48 C8
    49 C9
    4A D1
    4B D2
    4C D3
    4D D4
    4E D5
    4F D6
    50 D7
    51 D8
    52 D9
    53 E2
    54 E3
    55 E4
    56 E5
    57 E6
    58 E7
    59 E8
    5A E9
    5B 70
    5C 5B
    5D 80
    5E B0
    5F 6D
    60 79
    61 62
    62 63
    63 64
    64 65
    65 66
    66 67
    67 68
    68 69
    69 71
    6A 72
    6B 73
    6C 74
    6D 75
    6E 76
    6F 77
    70 78
    71 8B
    72 9B
    73 AB
    74 B3
    75 B4
    76 B5
    77 B6
    78 B7
    79 B8
    7A B9
    7B C0
    7C 4F
    7D D0
    7E A0
    A1 41
    A2 42
    A3 43
    A4 44
    A5 45
    A6 46
    A7 47
    A8 48
    A9 49
    AA 51
    AB 52
    AC 53
    AD 54
    AE 55
    AF 56
    B0 58
    B1 81
    B2 82
    B3 83
    B4 84
    B5 85
    B6 86
    B7 87
    B8 88
    B9 89
    BA 8A
    BB 8C
    BC 8D
    BD 8E
    BE 8F
    BF 90
    C0 91
    C1 92
    C2 93
    C3 94
    C4 95
    C5 96
    C6 97
    C7 98
    C8 99
    C9 9A
    CA 9D
    CB 9E
    CC 9F
    CD A2
    CE A3
    CF A4
    D0 A5
    D1 A6
    D2 A7
    D3 A8
    D4 A9
    D5 AA
    D6 AC
    D7 AD
    D8 AE
    D9 AF
    DA BA
    DB BB
    DC BC
    DD BD
    DE BE
    DF BF
);

for my $jis (sort keys %jis2ebcdic_IBM_CPGID00290_like) {
    if ($EBCDIC_IBM_CPGID00290_like_by_JIS8{$jis} ne $jis2ebcdic_IBM_CPGID00290_like{$jis}) {
        die "jis($jis): ($EBCDIC_IBM_CPGID00290_like_by_JIS8{$jis}) ne ($jis2ebcdic_IBM_CPGID00290_like{$jis})";
    }
}

use Jacode4e;

for my $byte (0x00 .. 0xFF) {
    my $give = pack('C',$byte);
    my $got  = pack('C',$byte);
    my $want = pack('H*',EBCDIC_IBM_CPGID00290_like_by_JIS8(uc unpack('H*',$give)));
    my $return = Jacode4e::convert(\$got,'cp00930','cp932x',{'INPUT_LAYOUT'=>'S'});
    ok(($return > 0) and ($got eq $want),
        sprintf(qq{cp932x(%s) to cp00930(%s) => return=$return,got=(%s)},
            uc unpack('H*',$give),
            uc unpack('H*',$want),
            uc unpack('H*',$got),
        )
    );
}

for my $byte (0x00 .. 0xFF) {
    my $give = pack('C',$byte);
    my $got  = pack('C',$byte);
    my $want = pack('H*',JIS8_by_EBCDIC_IBM_CPGID00290_like(uc unpack('H*',$give)));
    my $return = Jacode4e::convert(\$got,'cp932x','cp00930',{'INPUT_LAYOUT'=>'S'});
    ok(($return > 0) and ($got eq $want),
        sprintf(qq{cp00930(%s) to cp932x(%s) => return=$return,got=(%s)},
            uc unpack('H*',$give),
            uc unpack('H*',$want),
            uc unpack('H*',$got),
        )
    );
}

sub EBCDIC_IBM_CPGID00290_like_by_JIS8 {
    my($byte) = @_;
    return $EBCDIC_IBM_CPGID00290_like_by_JIS8{$byte};
}

sub JIS8_by_EBCDIC_IBM_CPGID00290_like {
    my($byte) = @_;
    return $JIS8_by_EBCDIC_IBM_CPGID00290_like{$byte};
}

1;

__END__
