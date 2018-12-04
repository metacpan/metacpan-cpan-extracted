######################################################################
#
# CP00300_by_Unicode.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# IBM Japanese Graphic Character Set, Kanji DBCS Host and DBCS - PC
# https://www-01.ibm.com/software/globalization/cdra/
# ftp://ftp.software.ibm.com/software/globalization/gcoc/attachments/CP00300.pdf

use strict;
use File::Basename;

my %CP00300_by_Unicode = ();
my %Unicode_by_CP00300 = ();

open(CP00300,"@{[File::Basename::dirname(__FILE__)]}/ftp.__ftp.software.ibm.com_software_globalization_gcoc_attachments_CP00300.pdf.txt") || die;
$_ = join '', <CP00300>;
close(CP00300);
$_ =~ tr/\r\n/ /d;

%_ = ();
while (s{(.*)((TABLE\s*[0123456789]+).*)\z}{$1}is) {
    my($tablename,$content) = ($3,$2);
    $tablename =~ tr/ /_/;
    $_{uc $tablename} .= $content;
}

my $blockno = 1;
for my $tablename (

### 'TABLE_1',  # Table 1. Registration of GCSGID and CPGID for the IBM Japanese Graphic Character Set
###             # CGCSGID GCSGID CPGID | Name | Set Size | Reference in Table | Category of Registration

### 'TABLE_2',  # Table 2. Structure of Japanese DBCS-Host
###             # Area | Wards in Hex | Content

### 'TABLE_3',  # Table 3. Structure of Japanese DBCS-PC
###             # Area | Wards in Hex | Content

### 'TABLE_4',  # Table 4. Format of DBCS-Host Specification Tables
###             # Graphic | Host Code(Hex) | PC Code(Hex) | UCS-2 or UCS-4(Hex)| GCGID or GCUID

    'TABLE_5',  # Table 5. Non-Kanji Set, DBCS-Host
                # Graphic | Host Code | PC Code | UCS-2 | GCGID

    'TABLE_6',  # Table 6. Basic Kanji Set, DBCS-Host
                # Graphic | Host Code | PC Code | UCS-2 | GCGID

    'TABLE_7',  # Table 7. Extended Kanji Set, DBCS-Host
                # Graphic | Host Code | PC Code | UCS-2 | GCGID

    'TABLE_8',  # Table 8. New Extended Non-Kanji Set
                # Graphic | Host Code | PC Code | UCS-2 | GCGID/GCUID*

    'TABLE_9',  # Table 9. New Extended Kanji Set . Part 1
                # Graphic | Host Code | PC Code | UCS-4* | GCGID

    'TABLE_10', # Table 10. New Extended Kanji Set . Part 2
                # Graphic | Host Code | PC Code | UCS-2 | GCGID

    'TABLE_11', # Table 11. Non-Kanji Set, DBCS-PC
                # Graphic | PC Code | Host Code | UCS-2 | GCGID

    'TABLE_12', # Table 12. Level 1 Kanji Set, DBCS-PC
                # Graphic | PC Code | Host Code | UCS-2 | GCGID

    'TABLE_13', # Table 13. Level 2 Kanji Set, DBCS-PC
                # Graphic | PC Code | Host Code | UCS-2 | GCGID

    'TABLE_14', # Table 14. IBM-Selected Non-Kanji Set, DBCS-PC
                # Graphic | PC Code | Host Code | UCS-2 | GCGID

    'TABLE_15', # Table 15. IBM-Selected Kanji Set, DBCS-PC
                # Graphic | PC Code | Host Code | UCS-2 | GCGID

### 'TABLE_16', # Table 16. 2 characters added on 92-11 revision
###             # Graphic | Host Code | PC Code | GCGID

### 'TABLE_17', # Table 17. 2 characters which GCGIDs were corrected
###             # Graphic | Host Code | PC Code | Former GCGID | Correct GCGID

### 'TABLE_18', # Table 18. 14 SEIREI characters
###             # Host Code | PC Code | Former Graphic | New Graphic

    'TABLE_19', # Table 19. 61 NEC Selected Characters
                # Graphic | PC Code(New JIS Sequence) | Host Code | UCS-2 | GCGID

    'TABLE_20', # Table 20. 3 non-Kanji in Halfwidth/Fullwidth Forms
                # Graphic | Host Code | PC Code | UCS-2 | GCGID

### 'TABLE_21', # Table 21. 8 Kanji will be added in JIS X0213 for Hyogai-Kanji
###             # Graphic | Host Code | UCS-2 | JIS X0213(Row-Cell/Hex)

### 'TABLE_22', # Table 22. GCSGIDs and CPGIDs newly added
###             # CGCSGID GCSGID CPGID | Name | Set Size

### 'TABLE_23', # Table 23. Sample Heisei Graphic Images
###             # Host Code | Former Graphic | New Graphic | Host Code | Graphic

### 'TABLE_24', # Table 24. Sample glyph representation change for HYOGAI KANJI JITAIHYO
###             # Former Graphic | New Graphic | Host Code | UCS-2

) {
    @_ = ();
    while (
        $_{$tablename} =~
        s{(.*)((?:
            Graphic [ ]*          Host [ ]* Code [ ]*                                     PC   [ ]* Code [ ]* UCS-2    [ ]* GCGID (?:/GCUID[*])? |
            Graphic [ ]*          Host [ ]* Code [ ]*                                     PC   [ ]* Code [ ]* UCS-4[*] [ ]* GCGID                |
            Graphic [ ]*          PC   [ ]* Code [ ]*                                     Host [ ]* Code [ ]* UCS-2    [ ]* GCGID                |
            Graphic [\x00-\xFF]*? PC   [ ]* Code [ ]* \(New [ ]* JIS [ ]* Sequence\) [ ]* Host [ ]* Code [ ]* UCS-2    [ ]* GCGID
        ).*)\z}{$1}x
    ) {
        unshift @_, $2;
    }

    my %CP00300_by_Unicode_dump = ();
    my %Unicode_by_CP00300_dump = ();
    while ($_ = shift @_) {
        if (0) {
        }
        elsif (s<^Graphic [ ]* Host [ ]* Code [ ]* PC [ ]* Code [ ]* UCS-2 [ ]* GCGID (?:/GCUID[*])?><>x) {
            my $line = 1;
            while (s<^.*?
                ([0123456789ABCDEF]{4})[*]*                   # Host Code
                \s+
                ([0123456789ABCDEF]{4}\s+|-+)[*]*             # PC Code
                ([0123456789ABCDEF]{4})[*]*                   # UCS-2
                \s+
                [0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]{8}[*]* # GCGID
            ><>x) {
                my($HostCode,$PCCode,$UCS) = ($1,$2,$3);
# print STDERR join("\t", 1, $blockno, $line, $HostCode, $UCS, $PCCode), "\n";
                $line++;

                $UCS =~ s/^0([0123456789ABCDEF]{4})/$1/;
                if ($0 eq __FILE__) {
                    if (defined($CP00300_by_Unicode{$UCS}) and ($CP00300_by_Unicode{$UCS} ne $HostCode)) {
                        warn "\$CP00300_by_Unicode{$UCS}(=$HostCode) already defined as CP00300($CP00300_by_Unicode{$UCS}).\n";
                    }
                    if (defined($Unicode_by_CP00300{$HostCode}) and ($Unicode_by_CP00300{$HostCode} ne $UCS)) {
                        warn "\$Unicode_by_CP00300{$HostCode}(=$UCS) already defined as Unicode($Unicode_by_CP00300{$HostCode}).\n";
                    }
                }
                $CP00300_by_Unicode_dump{$UCS} =
                $CP00300_by_Unicode{$UCS}      = $HostCode;
                $Unicode_by_CP00300_dump{$HostCode} =
                $Unicode_by_CP00300{$HostCode} = $UCS;
            }
        }
        elsif (s<^Graphic [ ]* Host [ ]* Code [ ]* PC [ ]* Code [ ]* UCS-4[*] [ ]* GCGID><>x) {
            my $line = 1;
            while (s<^.*?
                ([0123456789ABCDEF]{4})[*]*                   # Host Code
                \s+
                (-+)                                          # PC Code
                \s*
                ([0123456789ABCDEF]{5})[*]*                   # UCS-4
                \s+
                [0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]{8}[*]* # GCGID
            ><>x) {
                my($HostCode,$PCCode,$UCS) = ($1,$2,$3);
# print STDERR join("\t", 2, $blockno, $line, $HostCode, $UCS, $PCCode), "\n";
                $line++;

                $UCS =~ s/^0([0123456789ABCDEF]{4})/$1/;
                if ($0 eq __FILE__) {
                    if (defined($CP00300_by_Unicode{$UCS}) and ($CP00300_by_Unicode{$UCS} ne $HostCode)) {
                        warn "\$CP00300_by_Unicode{$UCS}(=$HostCode) already defined as CP00300($CP00300_by_Unicode{$UCS}).\n";
                    }
                    if (defined($Unicode_by_CP00300{$HostCode}) and ($Unicode_by_CP00300{$HostCode} ne $UCS)) {
                        warn "\$Unicode_by_CP00300{$HostCode}(=$UCS) already defined as Unicode($Unicode_by_CP00300{$HostCode}).\n";
                    }
                }
                $CP00300_by_Unicode_dump{$UCS} =
                $CP00300_by_Unicode{$UCS}      = $HostCode;
                $Unicode_by_CP00300_dump{$HostCode} =
                $Unicode_by_CP00300{$HostCode} = $UCS;
            }
        }
        elsif (s<^Graphic [ ]* PC [ ]* Code [ ]* Host [ ]* Code [ ]* UCS-2 [ ]* GCGID><>x) {
            my $line = 1;
            while (s<^.*?
                ([0123456789ABCDEF]{4})[*]*                   # PC Code
                \s+
                ([0123456789ABCDEF]{4})[*]*                   # Host Code
                \s+
                ([0123456789ABCDEF]{4})[*]*                   # UCS-2
                \s+
                [0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]{8}[*]* # GCGID
            ><>x) {
                my($PCCode,$HostCode,$UCS) = ($1,$2,$3);
# print STDERR join("\t", 3, $blockno, $line, $HostCode, $UCS, $PCCode), "\n";
                $line++;

                $UCS =~ s/^0([0123456789ABCDEF]{4})/$1/;
                if ($0 eq __FILE__) {
                    if (defined($CP00300_by_Unicode{$UCS}) and ($CP00300_by_Unicode{$UCS} ne $HostCode)) {
                        warn "\$CP00300_by_Unicode{$UCS}(=$HostCode) already defined as CP00300($CP00300_by_Unicode{$UCS}).\n";
                    }
                    if (defined($Unicode_by_CP00300{$HostCode}) and ($Unicode_by_CP00300{$HostCode} ne $UCS)) {
                        warn "\$Unicode_by_CP00300{$HostCode}(=$UCS) already defined as Unicode($Unicode_by_CP00300{$HostCode}).\n";
                    }
                }
                $CP00300_by_Unicode_dump{$UCS} =
                $CP00300_by_Unicode{$UCS}      = $HostCode;
                $Unicode_by_CP00300_dump{$HostCode} =
                $Unicode_by_CP00300{$HostCode} = $UCS;
            }
        }
        elsif (s<^Graphic [\x00-\xFF]*? PC [ ]* Code [ ]* \(New [ ]* JIS [ ]* Sequence\) [ ]* Host [ ]* Code [ ]* UCS-2 [ ]* GCGID><>x) {
            my $line = 1;
            while (s<^.*?
                ([0123456789ABCDEF]{4})[*]*                   # PC Code
                \s+
                ([0123456789ABCDEF]{4})[*]*                   # Host Code
                \s+
                ([0123456789ABCDEF]{4})[*]*                   # UCS-2
                \s+
                [0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]{8}[*]* # GCGID
            ><>x) {
                my($PCCode,$HostCode,$UCS) = ($1,$2,$3);
# print STDERR join("\t", 3, $blockno, $line, $HostCode, $UCS, $PCCode), "\n";
                $line++;

                $UCS =~ s/^0([0123456789ABCDEF]{4})/$1/;
                if ($0 eq __FILE__) {
                    if (defined($CP00300_by_Unicode{$UCS}) and ($CP00300_by_Unicode{$UCS} ne $HostCode)) {
                        warn "\$CP00300_by_Unicode{$UCS}(=$HostCode) already defined as CP00300($CP00300_by_Unicode{$UCS}).\n";
                    }
                    if (defined($Unicode_by_CP00300{$HostCode}) and ($Unicode_by_CP00300{$HostCode} ne $UCS)) {
                        warn "\$Unicode_by_CP00300{$HostCode}(=$UCS) already defined as Unicode($Unicode_by_CP00300{$HostCode}).\n";
                    }
                }
                $CP00300_by_Unicode_dump{$UCS} =
                $CP00300_by_Unicode{$UCS}      = $HostCode;
                $Unicode_by_CP00300_dump{$HostCode} =
                $Unicode_by_CP00300{$HostCode} = $UCS;
            }
        }
        else {
            die;
        }

        $blockno++;
    }

    my %want = (
        'TABLE_5'  => 24+25+(25*4*5)+2,
        'TABLE_6'  => 28+30+(30*4*26)+24*2,
        'TABLE_7'  => 28+30+(30*4*28)+(30*2)+6+5,
        'TABLE_8'  => 28+(30*3)+(30*4*17)+21,
        'TABLE_9'  => 28+30+(30*4*7)+6+1,
        'TABLE_10' => 29+30+(30*2*(284-194+1))+2+1,
        'TABLE_11' => 22+30+(30*2*(293-287+1))+(26*2),
        'TABLE_12' => 28+30+(30*2*(343-296+1))+14+13,
        'TABLE_13' => 28+30+(30*2*(400-346+1))+(16*2),
        'TABLE_14' => 26,
        'TABLE_15' => 28+30+(30*2*(408-404+1))+2,
        'TABLE_19' => 31+30,
        'TABLE_20' => 3,
    );

    if ($0 eq __FILE__) {
        open(DUMP,">$0.$tablename.dump") || die;
        binmode(DUMP);
        my $got = 0;
        for my $HostCode (sort { (length($a) <=> length($b) ) || ($a cmp $b) } keys %Unicode_by_CP00300_dump) {
            print DUMP join(' ', $HostCode, $Unicode_by_CP00300_dump{$HostCode}), "\n";
            $got++;
        }
        close(DUMP);
        if ($got == $want{$tablename}) {
            rename("$0.$tablename.dump","$0.$tablename.${got}_of_$want{$tablename}.dump.OK");
        }
        else {
            rename("$0.$tablename.dump","$0.$tablename.${got}_of_$want{$tablename}.dump.ERROR");
        }
    }
}

sub CP00300_by_Unicode {
    my($unicode) = @_;
    return $CP00300_by_Unicode{$unicode};
}

sub keys_of_CP00300_by_Unicode {
    return keys %CP00300_by_Unicode;
}

sub values_of_CP00300_by_Unicode {
    return values %CP00300_by_Unicode;
}

1;

__END__
