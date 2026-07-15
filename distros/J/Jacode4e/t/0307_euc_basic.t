######################################################################
#
# 0307_euc_basic.t - basic tests of 'euc' encoding (EUC-JP: JIS X 0201, JIS X 0208)
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

    # code set 0: US-ASCII
    sub { my $line = "\x41\x42\x43";
          my $return = Jacode4e::convert(\$line,'utf8','euc');
          ok($line eq "\x41\x42\x43", qq{euc(414243) to utf8(414243) => return=$return,got=(@{[got($line)]})}); },

    # code set 1: JIS X 0208
    sub { my $line = "\xA4\xA2";
          my $return = Jacode4e::convert(\$line,'utf8','euc');
          ok($line eq "\xE3\x81\x82", qq{euc(A4A2) to utf8(E38182) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\xE3\x81\x82";
          my $return = Jacode4e::convert(\$line,'euc','utf8');
          ok($line eq "\xA4\xA2", qq{utf8(E38182) to euc(A4A2) => return=$return,got=(@{[got($line)]})}); },

    # code set 2: SS2 + JIS X 0201 Katakana
    sub { my $line = "\x8E\xB1\x8E\xB2";
          my $return = Jacode4e::convert(\$line,'cp932','euc');
          ok($line eq "\xB1\xB2", qq{euc(8EB18EB2 SS2 kana) to cp932(B1B2) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\xB1\xB2";
          my $return = Jacode4e::convert(\$line,'euc','cp932');
          ok($line eq "\x8E\xB1\x8E\xB2", qq{cp932(B1B2 kana) to euc(8EB18EB2) => return=$return,got=(@{[got($line)]})}); },

    # SS2 kana is a halfwidth character, so 2 characters here
    sub { my $line = "\x8E\xB1\xA4\xA2";
          my $return = Jacode4e::convert(\$line,'sjis','euc');
          ok(($line eq "\xB1\x82\xA0") and ($return == 2), qq{euc(8EB1A4A2) to sjis(B182A0) => return=$return (expect 2),got=(@{[got($line)]})}); },

    # euc <=> sjis
    sub { my $line = "\x82\xA0\x83\x41";
          my $return = Jacode4e::convert(\$line,'euc','sjis');
          ok($line eq "\xA4\xA2\xA5\xA2", qq{sjis(82A08341) to euc(A4A2A5A2) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\xA4\xA2\xA5\xA2";
          my $return = Jacode4e::convert(\$line,'sjis','euc');
          ok($line eq "\x82\xA0\x83\x41", qq{euc(A4A2A5A2) to sjis(82A08341) => return=$return,got=(@{[got($line)]})}); },

    # JIS X 0208-1990 additions (row 84)
    sub { my $line = "\xF4\xA5\xF4\xA6";
          my $return = Jacode4e::convert(\$line,'sjis','euc');
          ok($line eq "\xEA\xA3\xEA\xA4", qq{euc(F4A5F4A6 row84) to sjis(EAA3EAA4) => return=$return,got=(@{[got($line)]})}); },

    # code set 3 (SS3 0x8F + JIS X 0212) is not supported => GETA
    sub { my $line = "\x8F\xA1\xA1";
          my $return = Jacode4e::convert(\$line,'utf8','euc',{'GETA'=>'?'});
          ok($line =~ /\?/, qq{euc(8FA1A1 SS3) is not supported => GETA => return=$return,got=(@{[got($line)]})}); },

    # from cp932: NEC special character is not JIS X 0208 => GETA
    sub { my $line = "\x87\x40";
          my $return = Jacode4e::convert(\$line,'euc','cp932');
          ok($line eq "\xA2\xAE", qq{cp932(8740 NEC(1)) to euc => GETA(A2AE) => return=$return,got=(@{[got($line)]})}); },

    # euc to enterprise encodings
    sub { my $line = "\xA4\xA2";
          my $return = Jacode4e::convert(\$line,'jef','euc');
          ok($line eq "\xA4\xA2", qq{euc(A4A2) to jef(A4A2) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\xA4\xA2";
          my $return = Jacode4e::convert(\$line,'jipse','euc');
          ok($line eq "\xE0\x7F", qq{euc(A4A2) to jipse(E07F) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\xA4\xA2";
          my $return = Jacode4e::convert(\$line,'cp00930','euc',{'OUTPUT_SHIFTING'=>1});
          ok($line eq "\x0E\x44\x81", qq{euc(A4A2) to cp00930(0E4481), {OUTPUT_SHIFTING=>1} => return=$return,got=(@{[got($line)]})}); },

    # INPUT_LAYOUT: SS2 kana is one 'S' character of 2 octets
    sub { my $line = "\x8E\xB1\xA4\xA2";
          my $return = Jacode4e::convert(\$line,'cp932','euc',{'INPUT_LAYOUT'=>'SD'});
          ok($line eq "\xB1\x82\xA0", qq{euc(8EB1A4A2) to cp932(B182A0), {INPUT_LAYOUT=>SD} => return=$return,got=(@{[got($line)]})}); },
);

$| = 1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
