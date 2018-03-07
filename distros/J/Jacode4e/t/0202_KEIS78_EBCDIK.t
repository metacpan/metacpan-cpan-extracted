######################################################################
#
# 0202_KEIS78_EBCDIK.t
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# HiRDB Datareplicator Version 8 manuals, Hitachi, Ltd.
# http://itdoc.hitachi.co.jp/manuals/3020/3020636050/W3600001.HTM
# http://itdoc.hitachi.co.jp/manuals/3020/3020636050/W3600166.HTM
# http://itdoc.hitachi.co.jp/manuals/3020/30203J3820/ISUS0268.HTM
# http://itdoc.hitachi.co.jp/manuals/3000/30003D5820/CLNT0235.HTM

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { $|=1; print "1..512\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

my %EBCDIK_HITACHI_by_JIS8 = map { sprintf('%02X',$_) => (qw(
    00 10 40 F0 7C D7 79 76 20 30 57 58 91 A5 B2 DC
    01 11 4F F1 C1 D8 59 77 21 31 41 81 92 A6 B3 DD
    02 12 7F F2 C2 D9 62 78 22 1A 42 82 93 A7 B4 DE
    03 13 7B F3 C3 E2 63 80 23 33 43 83 94 A8 B5 DF
    37 3C E0 F4 C4 E3 64 8B 24 34 44 84 95 A9 B6 EA
    2D 3D 6C F5 C5 E4 65 9B 25 35 45 85 96 AA B7 EB
    2E 32 50 F6 C6 E5 66 9C 06 36 46 86 97 AC B8 EC
    2F 26 7D F7 C7 E6 67 A0 17 08 47 87 98 AD B9 ED
    16 18 4D F8 C8 E7 68 AB 28 38 48 88 99 AE CA EE
    05 19 5D F9 C9 E8 69 B0 29 39 49 89 9A AF CB EF
    15 3F 5C 7A D1 E9 70 B1 2A 3A 51 8A 9D BA CC FA
    0B 27 4E 5E D2 4A 71 C0 2B 3B 52 8C 9E BB CD FB
    0C 1C 6B 4C D3 5B 72 6A 2C 04 53 8D 9F BC CE FC
    0D 1D 60 7E D4 5A 73 D0 09 14 54 8E A2 BD CF FD
    0E 1E 4B 6E D5 5F 74 A1 0A 3E 55 8F A3 BE DA FE
    0F 1F 61 6F D6 6D 75 07 1B E1 56 90 A4 BF DB FF
))[ ($_%16)*16+int($_/16) ]} (0..255);

my %JIS8_by_EBCDIK_HITACHI = map { sprintf('%02X',$_) => (qw(
    00 10 80 90 20 26 2D 6A 73 BF 77 79 7B 7D 24 30
    01 11 81 91 A1 AA 2F 6B B1 C0 7E 7A 41 4A 9F 31
    02 12 82 16 A2 AB 62 6C B2 C1 CD E0 42 4B 53 32
    03 13 83 93 A3 AC 63 6D B3 C2 CE E1 43 4C 54 33
    9C 9D 84 94 A4 AD 64 6E B4 C3 CF E2 44 4D 55 34
    09 0A 85 95 A5 AE 65 6F B5 C4 D0 E3 45 4E 56 35
    86 08 17 96 A6 AF 66 70 B6 C5 D1 E4 46 4F 57 36
    7F 87 1B 04 A7 A0 67 71 B7 C6 D2 E5 47 50 58 37
    97 18 88 98 A8 B0 68 72 B8 C7 D3 E6 48 51 59 38
    8D 19 89 99 A9 61 69 60 B9 C8 D4 E7 49 52 5A 39
    8E 92 8A 9A 5B 5D 7C 3A BA C9 D5 DA E8 EE F4 FA
    0B 8F 8B 9B 2E 5C 2C 23 74 75 78 DB E9 EF F5 FB
    0C 1C 8C 14 3C 2A 25 40 BB 76 D6 DC EA F0 F6 FC
    0D 1D 05 15 28 29 5F 27 BC CA D7 DD EB F1 F7 FD
    0E 1E 06 9E 2B 3B 3E 3D BD CB D8 DE EC F2 F8 FE
    0F 1F 07 1A 21 5E 3F 22 BE CC D9 DF ED F3 F9 FF
))[ ($_%16)*16+int($_/16) ]} (0..255);

if (scalar(keys %EBCDIK_HITACHI_by_JIS8) != 256) {
    die;
}

if (scalar(keys %JIS8_by_EBCDIK_HITACHI) != 256) {
    die;
}

for (0..255) {
    my $hex = sprintf('%02X',$_);
    if (not exists $JIS8_by_EBCDIK_HITACHI{$hex}) {
        die;
    }
    if (not defined $JIS8_by_EBCDIK_HITACHI{$hex}) {
        die;
    }
    if ($EBCDIK_HITACHI_by_JIS8{$JIS8_by_EBCDIK_HITACHI{$hex}} ne $hex) {
        die;
    }
}

for (0..255) {
    my $hex = sprintf('%02X',$_);
    if (not exists $EBCDIK_HITACHI_by_JIS8{$hex}) {
        die;
    }
    if (not defined $EBCDIK_HITACHI_by_JIS8{$hex}) {
        die;
    }
    if ($JIS8_by_EBCDIK_HITACHI{$EBCDIK_HITACHI_by_JIS8{$hex}} ne $hex) {
        die;
    }
}

my %jis2ebcdik_hitachi = qw(
    20 40
    21 4F
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
    5B 4A
    5C 5B
    5D 5A
    5E 5F
    5F 6D
    60 79
    61 59
    62 62
    63 63
    64 64
    65 65
    66 66
    67 67
    68 68
    69 69
    6A 70
    6B 71
    6C 72
    6D 73
    6E 74
    6F 75
    70 76
    71 77
    72 78
    73 80
    74 8B
    75 9B
    76 9C
    77 A0
    78 AB
    79 B0
    7A B1
    7B C0
    7C 6A
    7D D0
    7E A1
    A0 57
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

for my $jis (sort keys %jis2ebcdik_hitachi) {
    if ($EBCDIK_HITACHI_by_JIS8{$jis} ne $jis2ebcdik_hitachi{$jis}) {
        die "jis($jis): ($EBCDIK_HITACHI_by_JIS8{$jis}) ne ($jis2ebcdik_hitachi{$jis})";
    }
}

use Jacode4e;

for my $byte (0x00 .. 0xFF) {
    my $give = pack('C',$byte);
    my $got  = pack('C',$byte);
    my $want = pack('H*',EBCDIK_HITACHI_by_JIS8(uc unpack('H*',$give)));
    my $return = Jacode4e::convert(\$got,'keis78','cp932x',{'INPUT_LAYOUT'=>'S'});
    ok(($return > 0) and ($got eq $want),
        sprintf(qq{cp932x(%s) to keis78(%s) => return=$return,got=(%s)},
            uc unpack('H*',$give),
            uc unpack('H*',$want),
            uc unpack('H*',$got),
        )
    );
}

for my $byte (0x00 .. 0xFF) {
    my $give = pack('C',$byte);
    my $got  = pack('C',$byte);
    my $want = pack('H*',JIS8_by_EBCDIK_HITACHI(uc unpack('H*',$give)));
    my $return = Jacode4e::convert(\$got,'cp932x','keis78',{'INPUT_LAYOUT'=>'S'});
    ok(($return > 0) and ($got eq $want),
        sprintf(qq{keis78(%s) to cp932x(%s) => return=$return,got=(%s)},
            uc unpack('H*',$give),
            uc unpack('H*',$want),
            uc unpack('H*',$got),
        )
    );
}

sub EBCDIK_HITACHI_by_JIS8 {
    my($byte) = @_;
    return $EBCDIK_HITACHI_by_JIS8{$byte};
}

sub JIS8_by_EBCDIK_HITACHI {
    my($byte) = @_;
    return $JIS8_by_EBCDIK_HITACHI{$byte};
}

1;

__END__
