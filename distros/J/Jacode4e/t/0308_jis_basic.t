######################################################################
#
# 0308_jis_basic.t - basic tests of 'jis' encoding (ISO-2022-JP: JIS X 0201, JIS X 0208)
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Jacode4e;

my $testno = 1;
sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
sub got { uc unpack('H*',$_[0]) }

my @tests = (

    # no escape: US-ASCII
    sub { my $line = "\x41\x42\x43";
          my $return = Jacode4e::convert(\$line,'utf8','jis');
          ok($line eq "\x41\x42\x43", qq{jis(414243) to utf8(414243) => return=$return,got=(@{[got($line)]})}); },

    # ESC $ B (JIS X 0208-1983) ... ESC ( B
    sub { my $line = "\x1B\x24\x42\x24\x22\x1B\x28\x42\x41";
          my $return = Jacode4e::convert(\$line,'sjis','jis');
          ok($line eq "\x82\xA0\x41", qq{jis(ESC\$B 2422 ESC(B 41) to sjis(82A041) => return=$return,got=(@{[got($line)]})}); },

    # ESC $ @ (JIS C 6226-1978)
    sub { my $line = "\x1B\x24\x40\x24\x22";
          my $return = Jacode4e::convert(\$line,'sjis','jis');
          ok($line eq "\x82\xA0", qq{jis(ESC\$\@ 2422) to sjis(82A0) => return=$return,got=(@{[got($line)]})}); },

    # ESC & @ ESC $ B (JIS X 0208-1990)
    sub { my $line = "\x1B\x26\x40\x1B\x24\x42\x24\x22";
          my $return = Jacode4e::convert(\$line,'sjis','jis');
          ok($line eq "\x82\xA0", qq{jis(ESC&\@ESC\$B 2422) to sjis(82A0) => return=$return,got=(@{[got($line)]})}); },

    # ESC ( J (JIS X 0201 Roman)
    sub { my $line = "\x1B\x24\x42\x24\x22\x1B\x28\x4A\x41";
          my $return = Jacode4e::convert(\$line,'sjis','jis');
          ok($line eq "\x82\xA0\x41", qq{jis(ESC\$B 2422 ESC(J 41) to sjis(82A041) => return=$return,got=(@{[got($line)]})}); },

    # ESC ( H (old wrong habit)
    sub { my $line = "\x1B\x24\x42\x24\x22\x1B\x28\x48\x41";
          my $return = Jacode4e::convert(\$line,'sjis','jis');
          ok($line eq "\x82\xA0\x41", qq{jis(ESC\$B 2422 ESC(H 41) to sjis(82A041) => return=$return,got=(@{[got($line)]})}); },

    # ESC ( I (JIS X 0201 Katakana): 0x21..0x5F are read as 0xA1..0xDF
    sub { my $line = "\x1B\x28\x49\x31\x32\x1B\x28\x42\x41";
          my $return = Jacode4e::convert(\$line,'cp932','jis');
          ok($line eq "\xB1\xB2\x41", qq{jis(ESC(I 3132 ESC(B 41) to cp932(B1B241) => return=$return,got=(@{[got($line)]})}); },

    # ESC ( I then ESC $ B (kana mode is left by DBCS escape)
    sub { my $line = "\x1B\x28\x49\x31\x1B\x24\x42\x24\x22";
          my $return = Jacode4e::convert(\$line,'cp932','jis');
          ok($line eq "\xB1\x82\xA0", qq{jis(ESC(I 31 ESC\$B 2422) to cp932(B182A0) => return=$return,got=(@{[got($line)]})}); },

    # 8bit JIS Katakana (GR octets) on input
    sub { my $line = "\xB1\x1B\x24\x42\x24\x22";
          my $return = Jacode4e::convert(\$line,'euc','jis');
          ok($line eq "\x8E\xB1\xA4\xA2", qq{jis(B1 ESC\$B 2422 8bit kana) to euc(8EB1A4A2) => return=$return,got=(@{[got($line)]})}); },

    # consecutive escapes
    sub { my $line = "\x1B\x28\x49\x1B\x28\x42\x41";
          my $return = Jacode4e::convert(\$line,'cp932','jis');
          ok($line eq "\x41", qq{jis(ESC(I ESC(B 41 consecutive escapes) to cp932(41) => return=$return,got=(@{[got($line)]})}); },

    # trailing escape produces no ghost octets
    sub { my $line = "\x41\x1B\x24\x42";
          my $return = Jacode4e::convert(\$line,'cp932','jis');
          ok($line eq "\x41", qq{jis(41 ESC\$B trailing escape) to cp932(41) => return=$return,got=(@{[got($line)]})}); },

    # output without OUTPUT_SHIFTING: naked GL codes and GR kana
    sub { my $line = "\xA4\xA2\x8E\xB1";
          my $return = Jacode4e::convert(\$line,'jis','euc');
          ok($line eq "\x24\x22\xB1", qq{euc(A4A28EB1) to jis(2422B1 no shifting) => return=$return,got=(@{[got($line)]})}); },

    # output with OUTPUT_SHIFTING: ESC ( B and ESC $ B
    sub { my $line = "\x41\xA4\xA2\x42";
          my $return = Jacode4e::convert(\$line,'jis','euc',{'OUTPUT_SHIFTING'=>1});
          ok($line eq "\x1B\x28\x42\x41\x1B\x24\x42\x24\x22\x1B\x28\x42\x42",
             qq{euc(41A4A242) to jis(ESC(B 41 ESC\$B 2422 ESC(B 42), {OUTPUT_SHIFTING=>1} => return=$return,got=(@{[got($line)]})}); },

    # jis to jis roundtrip with OUTPUT_SHIFTING
    sub { my $line = "\x1B\x24\x42\x24\x22\x1B\x28\x42\x41";
          my $return = Jacode4e::convert(\$line,'jis','jis',{'OUTPUT_SHIFTING'=>1});
          ok($line eq "\x1B\x24\x42\x24\x22\x1B\x28\x42\x41", qq{jis to jis roundtrip, {OUTPUT_SHIFTING=>1} => return=$return,got=(@{[got($line)]})}); },

    # kana state does not leak into the next convert() call
    sub { my $line1 = "\x1B\x28\x49\x31";   # ends in kana mode
          Jacode4e::convert(\$line1,'cp932','jis');
          my $line2 = "\x31";
          my $return = Jacode4e::convert(\$line2,'cp932','jis');
          ok($line2 eq "\x31", qq{jis kana state is reset per call => return=$return,got=(@{[got($line2)]})}); },

    # JIS X 0208-1990 additions (row 84)
    sub { my $line = "\x1B\x24\x42\x74\x25\x74\x26";
          my $return = Jacode4e::convert(\$line,'sjis','jis');
          ok($line eq "\xEA\xA3\xEA\xA4", qq{jis(ESC\$B 74257426 row84) to sjis(EAA3EAA4) => return=$return,got=(@{[got($line)]})}); },

    # jis to enterprise encodings
    sub { my $line = "\x1B\x24\x42\x24\x22";
          my $return = Jacode4e::convert(\$line,'jef','jis');
          ok($line eq "\xA4\xA2", qq{jis(ESC\$B 2422) to jef(A4A2) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\x1B\x24\x42\x24\x22";
          my $return = Jacode4e::convert(\$line,'keis83','jis',{'OUTPUT_SHIFTING'=>1});
          ok($line eq "\x0A\x42\xA4\xA2", qq{jis(ESC\$B 2422) to keis83(0A42A4A2), {OUTPUT_SHIFTING=>1} => return=$return,got=(@{[got($line)]})}); },

    # INPUT_LAYOUT: naked GL codes without escapes
    sub { my $line = "\x24\x22\x41";
          my $return = Jacode4e::convert(\$line,'sjis','jis',{'INPUT_LAYOUT'=>'DS'});
          ok($line eq "\x82\xA0\x41", qq{jis(242241 naked GL) to sjis(82A041), {INPUT_LAYOUT=>DS} => return=$return,got=(@{[got($line)]})}); },

    # undefined DBCS code => GETA
    sub { my $line = "\x1B\x24\x42\x22\x2F";
          my $return = Jacode4e::convert(\$line,'utf8','jis',{'GETA'=>'?'});
          ok($line eq "?", qq{jis(ESC\$B 222F undefined) => GETA(?) => return=$return,got=(@{[got($line)]})}); },
);

$| = 1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
