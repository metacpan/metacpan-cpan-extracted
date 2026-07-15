######################################################################
#
# 0309_sjis_euc_jis_roundtrip.t - roundtrip tests over the whole code space
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Jacode4e;

my $testno = 1;
sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }

my @tests = (

    # DBCS whole code space: sjis => euc => jis => sjis must return the
    # original octets for every convertible JIS X 0208 character
    sub {
        my $checked = 0;
        my $failed  = 0;
        my $sample  = '';
        for (my $octet1=0x81; $octet1<=0xEA; $octet1++) {
            next if ($octet1 == 0x87);
            next if (($octet1 > 0x9F) and ($octet1 < 0xE0));
            for (my $octet2=0x40; $octet2<=0xFC; $octet2++) {
                next if ($octet2 == 0x7F);
                my $sjis = pack('CC', $octet1, $octet2);

                my $euc = $sjis;
                Jacode4e::convert(\$euc, 'euc', 'sjis', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});
                next if ($euc eq '');   # unassigned cell

                my $jis = $euc;
                Jacode4e::convert(\$jis, 'jis', 'euc', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});
                my $back = $jis;
                Jacode4e::convert(\$back, 'sjis', 'jis', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});

                $checked++;
                if ($back ne $sjis) {
                    $failed++;
                    if ($sample eq '') {
                        $sample = sprintf('%s => %s => %s => %s',
                            uc(unpack('H*',$sjis)), uc(unpack('H*',$euc)),
                            uc(unpack('H*',$jis)),  uc(unpack('H*',$back)));
                    }
                }
            }
        }
        ok(($failed == 0) and ($checked > 6800),
           qq{DBCS roundtrip sjis=>euc=>jis=>sjis: checked=$checked failed=$failed $sample});
    },

    # DBCS whole code space: euc octets are sjis GL+0x8080, jis octets are GL
    sub {
        my $checked = 0;
        my $failed  = 0;
        my $sample  = '';
        for (my $octet1=0x81; $octet1<=0xEA; $octet1++) {
            next if ($octet1 == 0x87);
            next if (($octet1 > 0x9F) and ($octet1 < 0xE0));
            for (my $octet2=0x40; $octet2<=0xFC; $octet2++) {
                next if ($octet2 == 0x7F);
                my $sjis = pack('CC', $octet1, $octet2);

                my $euc = $sjis;
                Jacode4e::convert(\$euc, 'euc', 'sjis', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});
                next if ($euc eq '');

                my $jis = $sjis;
                Jacode4e::convert(\$jis, 'jis', 'sjis', {'INPUT_LAYOUT'=>'D', 'GETA'=>''});

                # arithmetic relation: euc = jis GL + 0x8080
                my($j1,$j2) = unpack('CC', $jis);
                my $euc_expected = pack('CC', $j1 + 0x80, $j2 + 0x80);

                # arithmetic relation: jis GL from sjis (Ken Lunde CJKV)
                my($c1,$c2) = unpack('CC', $sjis);
                my($e1,$e2);
                if ($c2 >= 0x9F) {
                    $e1 = ((($c1 < 0xA0) ? ($c1 - 0x81) : ($c1 - 0xC1)) * 2) + 0x22;
                    $e2 = $c2 - 0x7E;
                }
                else {
                    $e1 = ((($c1 < 0xA0) ? ($c1 - 0x81) : ($c1 - 0xC1)) * 2) + 0x21;
                    $e2 = $c2 - (($c2 > 0x7E) ? 0x20 : 0x1F);
                }
                my $jis_expected = pack('CC', $e1, $e2);

                $checked++;
                if (($euc ne $euc_expected) or ($jis ne $jis_expected)) {
                    $failed++;
                    if ($sample eq '') {
                        $sample = sprintf('sjis=%s euc=%s(expect %s) jis=%s(expect %s)',
                            uc(unpack('H*',$sjis)),
                            uc(unpack('H*',$euc)),  uc(unpack('H*',$euc_expected)),
                            uc(unpack('H*',$jis)),  uc(unpack('H*',$jis_expected)));
                    }
                }
            }
        }
        ok(($failed == 0) and ($checked > 6800),
           qq{DBCS arithmetic relation sjis/euc/jis: checked=$checked failed=$failed $sample});
    },

    # SBCS whole code space: US-ASCII 0x00..0x7F
    sub {
        my $failed = 0;
        for (my $octet=0x00; $octet<=0x7F; $octet++) {
            my $sjis = pack('C', $octet);
            my $euc = $sjis;
            Jacode4e::convert(\$euc, 'euc', 'sjis');
            my $jis = $euc;
            Jacode4e::convert(\$jis, 'jis', 'euc');
            my $back = $jis;
            Jacode4e::convert(\$back, 'sjis', 'jis');
            $failed++ if (($euc ne $sjis) or ($jis ne $sjis) or ($back ne $sjis));
        }
        ok($failed == 0, qq{SBCS roundtrip 00..7F: failed=$failed});
    },

    # SBCS whole code space: JIS X 0201 Katakana 0xA1..0xDF
    sub {
        my $failed = 0;
        my $sample = '';
        for (my $octet=0xA1; $octet<=0xDF; $octet++) {
            my $sjis = pack('C', $octet);
            my $euc = $sjis;
            Jacode4e::convert(\$euc, 'euc', 'sjis');
            my $jis = $euc;
            Jacode4e::convert(\$jis, 'jis', 'euc');
            my $back = $jis;
            Jacode4e::convert(\$back, 'sjis', 'jis');
            if (($euc ne ("\x8E" . $sjis)) or ($jis ne $sjis) or ($back ne $sjis)) {
                $failed++;
                if ($sample eq '') {
                    $sample = sprintf('%s => %s => %s => %s',
                        uc(unpack('H*',$sjis)), uc(unpack('H*',$euc)),
                        uc(unpack('H*',$jis)),  uc(unpack('H*',$back)));
                }
            }
        }
        ok($failed == 0, qq{SBCS kana roundtrip A1..DF (euc is SS2 0x8E + kana): failed=$failed $sample});
    },

    # utf8 roundtrip through each new encoding
    # ('jis' needs OUTPUT_SHIFTING to write its escape sequences,
    #  naked GL octets cannot be read back)
    sub {
        my $failed = 0;
        for my $encoding ('sjis', 'euc', 'jis') {
            my $utf8 = "\xE3\x81\x82\xE6\xBC\xA2\x41\xEF\xBD\xB1";   # HIRAGANA A, KAN, A, HALFWIDTH KATAKANA A
            my $work = $utf8;
            Jacode4e::convert(\$work, $encoding, 'utf8', {'OUTPUT_SHIFTING'=>(($encoding eq 'jis') ? 1 : 0)});
            Jacode4e::convert(\$work, 'utf8', $encoding);
            $failed++ if ($work ne $utf8);
        }
        ok($failed == 0, qq{utf8 => sjis/euc/jis => utf8 roundtrip: failed=$failed});
    },
);

$| = 1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
