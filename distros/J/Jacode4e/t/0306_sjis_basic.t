######################################################################
#
# 0306_sjis_basic.t - basic tests of 'sjis' encoding (JIS X 0201, JIS X 0208)
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

    # SBCS: US-ASCII / JIS X 0201 Roman
    sub { my $line = "\x41\x42\x43";
          my $return = Jacode4e::convert(\$line,'utf8','sjis');
          ok($line eq "\x41\x42\x43", qq{sjis(414243) to utf8(414243) => return=$return,got=(@{[got($line)]})}); },

    # DBCS: JIS X 0208
    sub { my $line = "\x82\xA0";
          my $return = Jacode4e::convert(\$line,'utf8','sjis');
          ok($line eq "\xE3\x81\x82", qq{sjis(82A0) to utf8(E38182) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\xE3\x81\x82";
          my $return = Jacode4e::convert(\$line,'sjis','utf8');
          ok($line eq "\x82\xA0", qq{utf8(E38182) to sjis(82A0) => return=$return,got=(@{[got($line)]})}); },

    # JIS X 0201 Katakana
    sub { my $line = "\xB1\xB2\xB3";
          my $return = Jacode4e::convert(\$line,'utf8','sjis');
          ok($line eq "\xEF\xBD\xB1\xEF\xBD\xB2\xEF\xBD\xB3", qq{sjis(B1B2B3) to utf8(halfwidth kana) => return=$return,got=(@{[got($line)]})}); },

    # JIS X 0208-1990 additions (row 84)
    sub { my $line = "\xEA\xA3\xEA\xA4";
          my $return = Jacode4e::convert(\$line,'utf8','sjis');
          my $ok = ($line eq "\xE5\x87\x9C\xE7\x86\x99");
          ok($ok, qq{sjis(EAA3EAA4 row84) to utf8 => return=$return,got=(@{[got($line)]})}); },

    # to cp932: same octets on JIS X 0208 area
    sub { my $line = "\x82\xA0\xB1\x41";
          my $return = Jacode4e::convert(\$line,'cp932','sjis');
          ok($line eq "\x82\xA0\xB1\x41", qq{sjis(82A0B141) to cp932(same octets) => return=$return,got=(@{[got($line)]})}); },

    # from cp932: NEC special character is not JIS X 0208 => GETA
    sub { my $line = "\x87\x40";
          my $return = Jacode4e::convert(\$line,'sjis','cp932');
          ok($line eq "\x81\xAC", qq{cp932(8740 NEC(1)) to sjis => GETA(81AC) => return=$return,got=(@{[got($line)]})}); },

    # from cp932: IBM extended character is not JIS X 0208 => GETA option
    sub { my $line = "\xFA\x5C";
          my $return = Jacode4e::convert(\$line,'sjis','cp932',{'GETA'=>"\x81\xA1"});
          ok($line eq "\x81\xA1", qq{cp932(FA5C IBMext) to sjis, {GETA=>81A1} => return=$return,got=(@{[got($line)]})}); },

    # NEC special character on sjis INPUT is undefined => GETA
    sub { my $line = "\x87\x40";
          my $return = Jacode4e::convert(\$line,'utf8','sjis',{'GETA'=>'?'});
          ok($line eq "?", qq{sjis(8740) is undefined => GETA(?) => return=$return,got=(@{[got($line)]})}); },

    # wave dash: same mapping as this table's cp932 row on utf8 and utf8.1
    sub { my $line = "\x81\x60";
          my $return = Jacode4e::convert(\$line,'utf8','sjis');
          ok($line eq "\xE3\x80\x9C", qq{sjis(8160) to utf8(E3809C U+301C) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\x81\x60";
          my $return = Jacode4e::convert(\$line,'utf8.1','sjis');
          ok($line eq "\xE3\x80\x9C", qq{sjis(8160) to utf8.1(E3809C U+301C) => return=$return,got=(@{[got($line)]})}); },

    # SPACE option
    sub { my $line = "\x81\x40";
          my $return = Jacode4e::convert(\$line,'sjis','cp932',{'SPACE'=>"\x20\x20"});
          ok($line eq "\x20\x20", qq{cp932(8140) to sjis, {SPACE=>2020} => return=$return,got=(@{[got($line)]})}); },

    # sjis to enterprise encodings
    sub { my $line = "\x82\xA0";
          my $return = Jacode4e::convert(\$line,'jef','sjis');
          ok($line eq "\xA4\xA2", qq{sjis(82A0) to jef(A4A2) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\x82\xA0";
          my $return = Jacode4e::convert(\$line,'keis83','sjis');
          ok($line eq "\xA4\xA2", qq{sjis(82A0) to keis83(A4A2) => return=$return,got=(@{[got($line)]})}); },

    sub { my $line = "\x44\x81";
          my $return = Jacode4e::convert(\$line,'sjis','cp00930',{'INPUT_LAYOUT'=>'D'});
          ok($line eq "\x82\xA0", qq{cp00930(4481) to sjis(82A0), {INPUT_LAYOUT=>D} => return=$return,got=(@{[got($line)]})}); },

    # return value is character count
    sub { my $line = "\x82\xA0\xB1\x41";
          my $return = Jacode4e::convert(\$line,'euc','sjis');
          ok($return == 3, qq{sjis(82A0B141) to euc => return=$return (expect 3 characters)}); },
);

$| = 1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
