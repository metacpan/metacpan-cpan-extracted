######################################################################
#
# 0313_jis_variants_input.t - 'jis' input escape sequence variations
#                             (ESC $ ( D, ISO 2022 general forms,
#                              SO/SI with the JIS_SOSI option)
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

    # ESC $ ( D designates JIS X 0212 (supported since 2.13.6.23 for
    # characters that already have a row): 0x3021 is JIS X 0212 code
    # 0x3021, U+4E02 (utf8 E4B882).
    sub { my $line = "\x1B\x24\x28\x44\x30\x21\x1B\x28\x42\x41";
          my $return = Jacode4e::convert(\$line,'utf8','jis');
          ok(($return == 2) and ($line eq "\xE4\xB8\x82\x41"),
             qq{jis(ESC\$(D 3021 ESC(B 41) => utf8, return=$return (expect 2),got=(@{[got($line)]}) want=(E4B88241)}); },

    # ESC $ ( B is the ISO 2022 general form of ESC $ B (JIS X 0208):
    # 0x3021 is U+4E9C (utf8 E4BA9C).
    sub { my $line = "\x1B\x24\x28\x42\x30\x21\x1B\x28\x42\x41";
          my $return = Jacode4e::convert(\$line,'utf8','jis');
          ok(($return == 2) and ($line eq "\xE4\xBA\x9C\x41"),
             qq{jis(ESC\$(B 3021 ESC(B 41) => utf8, return=$return (expect 2),got=(@{[got($line)]}) want=(E4BA9C41)}); },

    # ESC $ ( @ is the ISO 2022 general form of ESC $ @ (JIS C 6226).
    sub { my $line = "\x1B\x24\x28\x40\x30\x21\x1B\x28\x42\x41";
          my $return = Jacode4e::convert(\$line,'utf8','jis');
          ok(($return == 2) and ($line eq "\xE4\xBA\x9C\x41"),
             qq{jis(ESC\$(\@ 3021 ESC(B 41) => utf8, return=$return (expect 2),got=(@{[got($line)]}) want=(E4BA9C41)}); },

    # ESC $ ( D followed by ESC $ B: the JIS X 0212 designation is
    # cleared by the JIS X 0208 designation, so the SAME 0x3021 octets
    # decode differently -- first as JIS X 0212 (U+4E02), then as
    # JIS X 0208 (U+4E9C).
    sub { my $line = "\x1B\x24\x28\x44\x30\x21\x1B\x24\x42\x30\x21";
          my $return = Jacode4e::convert(\$line,'utf8','jis');
          ok(($return == 2) and ($line eq "\xE4\xB8\x82\xE4\xBA\x9C"),
             qq{jis(ESC\$(D 3021 ESC\$B 3021) => utf8, return=$return (expect 2),got=(@{[got($line)]}) want=(E4B882E4BA9C)}); },

    # SO/SI are data octets by default (whole code space transparency):
    # jis => jis must not interpret or remove 0x0E and 0x0F.
    sub { my $line = "\x0E\x31\x0F\x41";
          my $want = $line;
          my $return = Jacode4e::convert(\$line,'jis','jis');
          ok(($return == 4) and ($line eq $want),
             qq{jis(SO 31 SI 41) => jis without JIS_SOSI is transparent, return=$return (expect 4),got=(@{[got($line)]})}); },

    # with JIS_SOSI true, SO (0x0E) shifts to JIS X 0201 Katakana:
    # following 0x21..0x5F are read as 0xA1..0xDF. 0x31 is halfwidth
    # katakana A (U+FF71, utf8 EFBDB1).
    sub { my $line = "\x0E\x31\x0F\x41";
          my $return = Jacode4e::convert(\$line,'utf8','jis',{'JIS_SOSI'=>1});
          ok(($return == 2) and ($line eq "\xEF\xBD\xB1\x41"),
             qq{jis(SO 31 SI 41) JIS_SOSI => utf8, return=$return (expect 2),got=(@{[got($line)]}) want=(EFBDB141)}); },

    # SI must restore the GL designation before SO (designations
    # persist across SO/SI): ESC $ B, kanji, SO kana SI, kanji.
    sub { my $line = "\x1B\x24\x42\x30\x21\x0E\x31\x0F\x30\x21";
          my $return = Jacode4e::convert(\$line,'utf8','jis',{'JIS_SOSI'=>1});
          ok(($return == 3) and ($line eq "\xE4\xBA\x9C\xEF\xBD\xB1\xE4\xBA\x9C"),
             qq{jis(ESC\$B 3021 SO 31 SI 3021) JIS_SOSI => utf8, return=$return (expect 3),got=(@{[got($line)]}) want=(E4BA9CEFBDB1E4BA9C)}); },

    # SI restores the ESC ( I kana designation too.
    sub { my $line = "\x1B\x28\x49\x31\x0E\x32\x0F\x33";
          my $return = Jacode4e::convert(\$line,'utf8','jis',{'JIS_SOSI'=>1});
          ok(($return == 3) and ($line eq "\xEF\xBD\xB1\xEF\xBD\xB2\xEF\xBD\xB3"),
             qq{jis(ESC(I 31 SO 32 SI 33) JIS_SOSI => utf8, return=$return (expect 3),got=(@{[got($line)]}) want=(EFBDB1EFBDB2EFBDB3)}); },

    # GR octets 0xA1..0xDF (8bit JIS katakana) are still accepted with
    # JIS_SOSI true.
    sub { my $line = "\xB1\x0E\x32\x0F";
          my $return = Jacode4e::convert(\$line,'utf8','jis',{'JIS_SOSI'=>1});
          ok(($return == 2) and ($line eq "\xEF\xBD\xB1\xEF\xBD\xB2"),
             qq{jis(GR B1, SO 32 SI) JIS_SOSI => utf8, return=$return (expect 2),got=(@{[got($line)]}) want=(EFBDB1EFBDB2)}); },

    # all input variations combined: ESC $ ( D (JIS X 0212, U+4E02),
    # SO/SI kana, ESC $ ( B, ESC ( J Roman.
    sub { my $line = "\x1B\x24\x28\x44\x30\x21\x0E\x31\x0F\x1B\x24\x28\x42\x30\x21\x1B\x28\x4A\x41";
          my $return = Jacode4e::convert(\$line,'utf8','jis',{'JIS_SOSI'=>1});
          ok(($return == 4) and ($line eq "\xE4\xB8\x82\xEF\xBD\xB1\xE4\xBA\x9C\x41"),
             qq{jis(all input variations) JIS_SOSI => utf8, return=$return (expect 4),got=(@{[got($line)]}) want=(E4B882EFBDB1E4BA9C41)}); },

);

$|=1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
