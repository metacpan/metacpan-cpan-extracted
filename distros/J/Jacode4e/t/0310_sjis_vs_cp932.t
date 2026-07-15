######################################################################
#
# 0310_sjis_vs_cp932.t - 'sjis' is the JIS X 0201/0208 subset of 'cp932'
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Jacode4e;

my $testno = 1;
sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }

my $GETA_UTF8 = "\xE3\x80\x93";   # U+3013 GETA MARK

my @tests = (

    # DBCS whole code space: wherever 'sjis' is convertible, its utf8 must
    # equal the utf8 of the same octets read as 'cp932', and the lead octet
    # must be inside the JIS X 0208 area (81..86, 88..9F, E0..EA)
    sub {
        my $checked = 0;
        my $failed  = 0;
        my $sample  = '';
        for (my $octet1=0x81; $octet1<=0xFC; $octet1++) {
            next if (($octet1 > 0x9F) and ($octet1 < 0xE0));
            for (my $octet2=0x40; $octet2<=0xFC; $octet2++) {
                next if ($octet2 == 0x7F);
                my $octets = pack('CC', $octet1, $octet2);

                my $as_sjis = $octets;
                Jacode4e::convert(\$as_sjis, 'utf8', 'sjis', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});
                next if ($as_sjis eq '');   # not convertible as sjis

                my $as_cp932 = $octets;
                Jacode4e::convert(\$as_cp932, 'utf8', 'cp932', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});

                my $in_jisx0208_area =
                    (($octet1 >= 0x81) and ($octet1 <= 0x86)) ||
                    (($octet1 >= 0x88) and ($octet1 <= 0x9F)) ||
                    (($octet1 >= 0xE0) and ($octet1 <= 0xEA));

                $checked++;
                if (($as_sjis ne $as_cp932) or (not $in_jisx0208_area)) {
                    $failed++;
                    if ($sample eq '') {
                        $sample = sprintf('octets=%s sjis=>%s cp932=>%s area=%d',
                            uc(unpack('H*',$octets)),
                            uc(unpack('H*',$as_sjis)), uc(unpack('H*',$as_cp932)),
                            $in_jisx0208_area ? 1 : 0);
                    }
                }
            }
        }
        ok(($failed == 0) and ($checked > 6800),
           qq{sjis is a subset of cp932 with same utf8 mapping: checked=$checked failed=$failed $sample});
    },

    # CP932 extended areas: NEC special (87xx), NEC selected IBM extended
    # (EDxx, EExx), IBM extended (FAxx, FBxx, FCxx) never convert as 'sjis'
    sub {
        my $checked = 0;
        my $failed  = 0;
        my $sample  = '';
        for my $octet1 (0x87, 0xED, 0xEE, 0xFA, 0xFB, 0xFC) {
            for (my $octet2=0x40; $octet2<=0xFC; $octet2++) {
                next if ($octet2 == 0x7F);
                my $octets = pack('CC', $octet1, $octet2);

                # only test cells that cp932 can convert (defined characters)
                my $as_cp932 = $octets;
                Jacode4e::convert(\$as_cp932, 'utf8', 'cp932', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});
                next if ($as_cp932 eq '');

                my $as_sjis = $octets;
                Jacode4e::convert(\$as_sjis, 'utf8', 'sjis', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});

                $checked++;
                if ($as_sjis ne '') {
                    $failed++;
                    if ($sample eq '') {
                        $sample = sprintf('octets=%s unexpectedly convertible as sjis',
                            uc(unpack('H*',$octets)));
                    }
                }
            }
        }
        ok(($failed == 0) and ($checked > 700),
           qq{CP932 extended characters are not 'sjis': checked=$checked failed=$failed $sample});
    },

    # cp932 => sjis conversion keeps the same octets on the JIS X 0208 area
    sub {
        my $checked = 0;
        my $failed  = 0;
        my $sample  = '';
        for (my $octet1=0x81; $octet1<=0xEA; $octet1++) {
            next if ($octet1 == 0x87);
            next if (($octet1 > 0x9F) and ($octet1 < 0xE0));
            for (my $octet2=0x40; $octet2<=0xFC; $octet2++) {
                next if ($octet2 == 0x7F);
                my $octets = pack('CC', $octet1, $octet2);

                my $work = $octets;
                Jacode4e::convert(\$work, 'sjis', 'cp932', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});
                next if ($work eq '');   # unassigned cell

                $checked++;
                if ($work ne $octets) {
                    $failed++;
                    if ($sample eq '') {
                        $sample = sprintf('cp932=%s => sjis=%s',
                            uc(unpack('H*',$octets)), uc(unpack('H*',$work)));
                    }
                }
            }
        }
        ok(($failed == 0) and ($checked > 6800),
           qq{cp932 => sjis keeps octets on JIS X 0208 area: checked=$checked failed=$failed $sample});
    },

    # cp932 extended characters => sjis becomes GETA
    sub {
        my $line = "\x87\x40\xED\x40\xFA\x5C";
        my $return = Jacode4e::convert(\$line, 'sjis', 'cp932');
        ok($line eq "\x81\xAC\x81\xAC\x81\xAC",
           qq{cp932(8740 ED40 FA5C) to sjis => GETA GETA GETA => return=$return,got=(@{[uc unpack('H*',$line)]})});
    },

    # SBCS: kana and ASCII are shared between sjis and cp932
    sub {
        my $failed = 0;
        for (my $octet=0x00; $octet<=0xFF; $octet++) {
            next if (($octet >= 0x80) and ($octet <= 0xA0));
            next if ($octet >= 0xE0);
            my $octets = pack('C', $octet);
            my $as_sjis = $octets;
            Jacode4e::convert(\$as_sjis, 'utf8', 'sjis', {'GETA'=>$GETA_UTF8});
            my $as_cp932 = $octets;
            Jacode4e::convert(\$as_cp932, 'utf8', 'cp932', {'GETA'=>$GETA_UTF8});
            $failed++ if ($as_sjis ne $as_cp932);
        }
        ok($failed == 0, qq{SBCS 00..7F,A1..DF: sjis and cp932 give same utf8: failed=$failed});
    },
);

$| = 1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
