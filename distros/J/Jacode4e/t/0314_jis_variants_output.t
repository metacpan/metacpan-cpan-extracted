######################################################################
#
# 0314_jis_variants_output.t - 'jis' output escape sequence variations
#                              (JIS_SBCS, JIS_DBCS, JIS_KANA options)
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

# common input: KATAKANA A (halfwidth), U+4E9C, "A"
my $KANJI_KANA_A = "\xE4\xBA\x9C\xEF\xBD\xB1\x41";

my @tests = (

    # default output: ESC $ B for DBCS, ESC ( B for SBCS, GR octets
    # for JIS X 0201 Katakana (8bit JIS).
    sub { my $line = $KANJI_KANA_A;
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1});
          ok(($return == 3) and ($line eq "\x1B\x24\x42\x30\x21\xB1\x1B\x28\x42\x41"),
             qq{default: ESC\$B 3021 B1 ESC(B 41, return=$return (expect 3),got=(@{[got($line)]})}); },

    # JIS_SBCS => 'J': ESC ( J (JIS X 0201 Roman) instead of ESC ( B.
    sub { my $line = $KANJI_KANA_A;
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_SBCS'=>'J'});
          ok(($return == 3) and ($line eq "\x1B\x24\x42\x30\x21\xB1\x1B\x28\x4A\x41"),
             qq{JIS_SBCS=>'J': ESC(J, return=$return (expect 3),got=(@{[got($line)]})}); },

    # JIS_SBCS => 'H': ESC ( H (old wrong habit) instead of ESC ( B.
    sub { my $line = $KANJI_KANA_A;
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_SBCS'=>'H'});
          ok(($return == 3) and ($line eq "\x1B\x24\x42\x30\x21\xB1\x1B\x28\x48\x41"),
             qq{JIS_SBCS=>'H': ESC(H, return=$return (expect 3),got=(@{[got($line)]})}); },

    # JIS_DBCS => '@': ESC $ @ (JIS C 6226-1978) instead of ESC $ B.
    sub { my $line = $KANJI_KANA_A;
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_DBCS'=>'@'});
          ok(($return == 3) and ($line eq "\x1B\x24\x40\x30\x21\xB1\x1B\x28\x42\x41"),
             qq{JIS_DBCS=>'\@': ESC\$\@, return=$return (expect 3),got=(@{[got($line)]})}); },

    # JIS_DBCS => '&@B': ESC & @ ESC $ B (JIS X 0208-1990).
    sub { my $line = $KANJI_KANA_A;
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_DBCS'=>'&@B'});
          ok(($return == 3) and ($line eq "\x1B\x26\x40\x1B\x24\x42\x30\x21\xB1\x1B\x28\x42\x41"),
             qq{JIS_DBCS=>'&\@B': ESC&\@ESC\$B, return=$return (expect 3),got=(@{[got($line)]})}); },

    # JIS_DBCS => '(B': ESC $ ( B (ISO 2022 general form).
    sub { my $line = $KANJI_KANA_A;
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_DBCS'=>'(B'});
          ok(($return == 3) and ($line eq "\x1B\x24\x28\x42\x30\x21\xB1\x1B\x28\x42\x41"),
             qq{JIS_DBCS=>'(B': ESC\$(B, return=$return (expect 3),got=(@{[got($line)]})}); },

    # JIS_DBCS => '(@': ESC $ ( @ (ISO 2022 general form).
    sub { my $line = $KANJI_KANA_A;
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_DBCS'=>'(@'});
          ok(($return == 3) and ($line eq "\x1B\x24\x28\x40\x30\x21\xB1\x1B\x28\x42\x41"),
             qq{JIS_DBCS=>'(\@': ESC\$(\@, return=$return (expect 3),got=(@{[got($line)]})}); },

    # JIS_KANA => 'I': ESC ( I + GL octets. the ESC $ B before the
    # kana run is absorbed, and the following escape sequence ends it.
    sub { my $line = $KANJI_KANA_A;
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_KANA'=>'I'});
          ok(($return == 3) and ($line eq "\x1B\x24\x42\x30\x21\x1B\x28\x49\x31\x1B\x28\x42\x41"),
             qq{JIS_KANA=>'I': ESC(I 31, return=$return (expect 3),got=(@{[got($line)]})}); },

    # JIS_KANA => 'I': when JIS X 0208 octets follow the kana run
    # directly, the run ends with ESC $ B (re-designation).
    sub { my $line = "\xEF\xBD\xB1\xE4\xBA\x9C\x41";
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_KANA'=>'I'});
          my $want = "\x1B\x28\x49\x31\x1B\x24\x42\x30\x21\x1B\x28\x42\x41";
          my $back = $line;
          Jacode4e::convert(\$back,'utf8','jis');
          ok(($return == 3) and ($line eq $want) and ($back eq "\xEF\xBD\xB1\xE4\xBA\x9C\x41"),
             qq{JIS_KANA=>'I' kana then kanji: ESC(I 31 ESC\$B 3021, return=$return (expect 3),got=(@{[got($line)]})}); },

    # JIS_KANA => 'I': kana at end of output ends with ESC ( B.
    sub { my $line = "\x41\xEF\xBD\xB1";
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_KANA'=>'I'});
          ok(($return == 2) and ($line eq "\x1B\x28\x42\x41\x1B\x28\x49\x31\x1B\x28\x42"),
             qq{JIS_KANA=>'I' kana at end: ESC(I 31 ESC(B, return=$return (expect 2),got=(@{[got($line)]})}); },

    # JIS_KANA => 'I' requires OUTPUT_SHIFTING.
    sub { my $line = "\xEF\xBD\xB1";
          my $return = eval { Jacode4e::convert(\$line,'jis','utf8',{'JIS_KANA'=>'I'}) };
          ok((not defined($return)) and ($@ ne ''),
             qq{JIS_KANA=>'I' without OUTPUT_SHIFTING croaks}); },

    # JIS_KANA => 'SO': SO + GL octets + SI. the surrounding GL
    # designation persists, so the following kanji stays readable.
    sub { my $line = "\xE4\xBA\x9C\xEF\xBD\xB1\xE4\xBA\x9C";
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_KANA'=>'SO'});
          my $want = "\x1B\x24\x42\x30\x21\x0E\x31\x0F\x30\x21";
          my $back = $line;
          Jacode4e::convert(\$back,'utf8','jis',{'JIS_SOSI'=>1});
          ok(($return == 3) and ($line eq $want) and ($back eq "\xE4\xBA\x9C\xEF\xBD\xB1\xE4\xBA\x9C"),
             qq{JIS_KANA=>'SO': ESC\$B 3021 SO 31 SI 3021, return=$return (expect 3),got=(@{[got($line)]})}); },

    # invalid option values croak.
    sub { my $line = "\x41";
          my $return = eval { Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_SBCS'=>'X'}) };
          ok((not defined($return)) and ($@ ne ''),
             qq{JIS_SBCS=>'X' croaks}); },
    sub { my $line = "\x41";
          my $return = eval { Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_DBCS'=>'X'}) };
          ok((not defined($return)) and ($@ ne ''),
             qq{JIS_DBCS=>'X' croaks}); },
    sub { my $line = "\x41";
          my $return = eval { Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_KANA'=>'X'}) };
          ok((not defined($return)) and ($@ ne ''),
             qq{JIS_KANA=>'X' croaks}); },

    # combined: JIS_KANA => 'I', JIS_DBCS => '@', JIS_SBCS => 'J'.
    # JIS_DBCS and JIS_SBCS also rewrite the escape sequences emitted
    # by the JIS_KANA transformation.
    sub { my $line = $KANJI_KANA_A;
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'JIS_KANA'=>'I','JIS_DBCS'=>'@','JIS_SBCS'=>'J'});
          ok(($return == 3) and ($line eq "\x1B\x24\x40\x30\x21\x1B\x28\x49\x31\x1B\x28\x4A\x41"),
             qq{combined I/\@/J, return=$return (expect 3),got=(@{[got($line)]})}); },

    # the options must not affect other OUTPUT encodings.
    sub { my $line = "\xE4\xBA\x9C";
          my $return = Jacode4e::convert(\$line,'sjis','utf8',{'JIS_SBCS'=>'J','JIS_DBCS'=>'@','JIS_KANA'=>'SO'});
          ok(($return == 1) and ($line eq "\x88\x9F"),
             qq{options ignored for sjis output, return=$return (expect 1),got=(@{[got($line)]}) want=(889F)}); },

);

$|=1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
