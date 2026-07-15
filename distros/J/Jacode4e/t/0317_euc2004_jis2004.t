######################################################################
#
# 0317_euc2004_jis2004.t - EUC-JIS-2004 ('euc2004') and
#                          ISO-2022-JP-2004 ('jis2004')
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

    #-----------------------------------------------------------------
    # euc2004 : plane 1 (JIS X 0208 subset)
    #-----------------------------------------------------------------

    # U+4E9C (亜) is JIS X 0213 plane 1 row 16 cell 1, euc2004 B0A1
    sub { my $line = "\xE4\xBA\x9C";
          my $return = Jacode4e::convert(\$line,'euc2004','utf8');
          ok(($return == 1) and ($line eq "\xB0\xA1"),
             qq{utf8(U+4E9C) => euc2004, return=$return (expect 1),got=(@{[got($line)]}) want=(B0A1)}); },

    sub { my $line = "\xB0\xA1";
          my $return = Jacode4e::convert(\$line,'utf8','euc2004');
          ok(($return == 1) and ($line eq "\xE4\xBA\x9C"),
             qq{euc2004(B0A1) => utf8, return=$return (expect 1),got=(@{[got($line)]}) want=(E4BA9C)}); },

    #-----------------------------------------------------------------
    # euc2004 : plane 2 (JIS X 0213 plane 2, SS3 0x8F + two GR octets)
    #-----------------------------------------------------------------

    # a plane 2 character (utf8jp F3B2ABBC, sjis2004 F8D3)
    sub { my $line = "\xF3\xB2\xAB\xBC";
          my $return = Jacode4e::convert(\$line,'euc2004','utf8jp');
          ok(($return == 1) and ($line =~ /^\x8F/) and (length($line) == 3),
             qq{utf8jp(plane 2) => euc2004 is SS3+GR GR, return=$return (expect 1),got=(@{[got($line)]})}); },

    sub { my $line = "\xF3\xB2\xAB\xBC";
          Jacode4e::convert(\$line,'euc2004','utf8jp');
          my $return = Jacode4e::convert(\$line,'utf8jp','euc2004');
          ok(($return == 1) and ($line eq "\xF3\xB2\xAB\xBC"),
             qq{euc2004(plane 2) => utf8jp round-trip, return=$return (expect 1),got=(@{[got($line)]}) want=(F3B2ABBC)}); },

    #-----------------------------------------------------------------
    # euc2004 : code set 0 (ASCII) and code set 2 (SS2 + Katakana)
    #-----------------------------------------------------------------

    # ASCII is transparent
    sub { my $line = "\x41\x42\x43";
          my $return = Jacode4e::convert(\$line,'utf8','euc2004');
          ok(($return == 3) and ($line eq "\x41\x42\x43"),
             qq{euc2004(ABC) => utf8, return=$return (expect 3),got=(@{[got($line)]}) want=(414243)}); },

    # halfwidth Katakana: U+FF71 (ｱ) = euc2004 SS2 0x8E 0xB1
    sub { my $line = "\xEF\xBD\xB1";
          my $return = Jacode4e::convert(\$line,'euc2004','utf8');
          ok(($return == 1) and ($line eq "\x8E\xB1"),
             qq{utf8(U+FF71) => euc2004 SS2, return=$return (expect 1),got=(@{[got($line)]}) want=(8EB1)}); },

    sub { my $line = "\x8E\xB1";
          my $return = Jacode4e::convert(\$line,'utf8','euc2004');
          ok(($return == 1) and ($line eq "\xEF\xBD\xB1"),
             qq{euc2004(8EB1) => utf8, return=$return (expect 1),got=(@{[got($line)]}) want=(EFBDB1)}); },

    #-----------------------------------------------------------------
    # euc2004 : mixed input
    #-----------------------------------------------------------------

    # ASCII + plane 1 + SS2 kana + plane 2
    sub { my $line = "\x41\xB0\xA1\x8E\xB1\x8F\xF6\xD5";
          my $return = Jacode4e::convert(\$line,'utf8jp','euc2004');
          ok(($return == 4),
             qq{euc2004(mixed 4 chars) => utf8jp, return=$return (expect 4),got=(@{[got($line)]})}); },

    #-----------------------------------------------------------------
    # jis2004 : plane 1 output (default ESC $ ( Q)
    #-----------------------------------------------------------------

    sub { my $line = "\xE4\xBA\x9C";
          my $return = Jacode4e::convert(\$line,'jis2004','utf8',{'OUTPUT_SHIFTING'=>1});
          ok(($return == 1) and ($line eq "\x1B\x24\x28\x51\x30\x21"),
             qq{utf8 => jis2004 plane 1 (ESC\$(Q), return=$return (expect 1),got=(@{[got($line)]}) want=(1B2428513021)}); },

    # plane 1 then ASCII: ESC ( B is restored
    sub { my $line = "\xE4\xBA\x9C\x41";
          my $return = Jacode4e::convert(\$line,'jis2004','utf8',{'OUTPUT_SHIFTING'=>1});
          ok(($return == 2) and ($line eq "\x1B\x24\x28\x51\x30\x21\x1B\x28\x42\x41"),
             qq{jis2004 plane 1 then ASCII, return=$return (expect 2),got=(@{[got($line)]}) want=(1B24285130211B284241)}); },

    #-----------------------------------------------------------------
    # jis2004 : plane 1 output with JIS2004_PLANE1 => 'O' (2000)
    #-----------------------------------------------------------------

    sub { my $line = "\xE4\xBA\x9C";
          my $return = Jacode4e::convert(\$line,'jis2004','utf8',{'OUTPUT_SHIFTING'=>1,'JIS2004_PLANE1'=>'O'});
          ok(($return == 1) and ($line eq "\x1B\x24\x28\x4F\x30\x21"),
             qq{utf8 => jis2004 plane 1 (ESC\$(O, 2000), return=$return (expect 1),got=(@{[got($line)]}) want=(1B24284F3021)}); },

    # explicit 'Q' is the default (2004)
    sub { my $line = "\xE4\xBA\x9C";
          my $return = Jacode4e::convert(\$line,'jis2004','utf8',{'OUTPUT_SHIFTING'=>1,'JIS2004_PLANE1'=>'Q'});
          ok(($return == 1) and ($line eq "\x1B\x24\x28\x51\x30\x21"),
             qq{utf8 => jis2004 plane 1 (ESC\$(Q explicit), return=$return (expect 1),got=(@{[got($line)]}) want=(1B2428513021)}); },

    # invalid JIS2004_PLANE1 croaks
    sub { my $line = "\xE4\xBA\x9C";
          my $return = eval { Jacode4e::convert(\$line,'jis2004','utf8',{'OUTPUT_SHIFTING'=>1,'JIS2004_PLANE1'=>'X'}) };
          ok((not defined($return)) and ($@ ne ''),
             qq{jis2004 JIS2004_PLANE1 => 'X' croaks}); },

    #-----------------------------------------------------------------
    # jis2004 : plane 2 output (ESC $ ( P)
    #-----------------------------------------------------------------

    sub { my $line = "\xF3\xB2\xAB\xBC";
          my $return = Jacode4e::convert(\$line,'jis2004','utf8jp',{'OUTPUT_SHIFTING'=>1});
          ok(($return == 1) and ($line =~ /^\x1B\x24\x28\x50/),
             qq{utf8jp(plane 2) => jis2004 (ESC\$(P), return=$return (expect 1),got=(@{[got($line)]})}); },

    #-----------------------------------------------------------------
    # jis2004 : input escape sequences
    #-----------------------------------------------------------------

    # ESC $ ( Q (JIS X 0213:2004 plane 1)
    sub { my $line = "\x1B\x24\x28\x51\x30\x21\x1B\x28\x42";
          my $return = Jacode4e::convert(\$line,'utf8','jis2004');
          ok(($return == 1) and ($line eq "\xE4\xBA\x9C"),
             qq{jis2004(ESC\$(Q 3021) => utf8, return=$return (expect 1),got=(@{[got($line)]}) want=(E4BA9C)}); },

    # ESC $ ( O (JIS X 0213:2000 plane 1) is also accepted on input
    sub { my $line = "\x1B\x24\x28\x4F\x30\x21\x1B\x28\x42";
          my $return = Jacode4e::convert(\$line,'utf8','jis2004');
          ok(($return == 1) and ($line eq "\xE4\xBA\x9C"),
             qq{jis2004(ESC\$(O 3021) => utf8, return=$return (expect 1),got=(@{[got($line)]}) want=(E4BA9C)}); },

    # ESC $ B (JIS X 0208-1983) is accepted as a plane 1 subset
    sub { my $line = "\x1B\x24\x42\x30\x21\x1B\x28\x42";
          my $return = Jacode4e::convert(\$line,'utf8','jis2004');
          ok(($return == 1) and ($line eq "\xE4\xBA\x9C"),
             qq{jis2004(ESC\$B 3021) => utf8, return=$return (expect 1),got=(@{[got($line)]}) want=(E4BA9C)}); },

    # ESC $ ( P (plane 2)
    sub { my $line = "\xF3\xB2\xAB\xBC";
          Jacode4e::convert(\$line,'jis2004','utf8jp',{'OUTPUT_SHIFTING'=>1});
          my $return = Jacode4e::convert(\$line,'utf8jp','jis2004');
          ok(($return == 1) and ($line eq "\xF3\xB2\xAB\xBC"),
             qq{jis2004 plane 2 round-trip, return=$return (expect 1),got=(@{[got($line)]}) want=(F3B2ABBC)}); },

    # ESC ( I (JIS X 0201 Katakana) input
    sub { my $line = "\x1B\x28\x49\x31\x1B\x28\x42";
          my $return = Jacode4e::convert(\$line,'utf8','jis2004');
          ok(($return == 1) and ($line eq "\xEF\xBD\xB1"),
             qq{jis2004(ESC(I 31) => utf8, return=$return (expect 1),got=(@{[got($line)]}) want=(EFBDB1)}); },

    #-----------------------------------------------------------------
    # jis2004 : round-trip
    #-----------------------------------------------------------------

    sub { my $line = "\x41\xE4\xBA\x9C\xEF\xBD\xB1\x42";
          my $want = $line;
          Jacode4e::convert(\$line,'jis2004','utf8',{'OUTPUT_SHIFTING'=>1});
          my $return = Jacode4e::convert(\$line,'utf8','jis2004');
          ok(($return == 4) and ($line eq $want),
             qq{jis2004 mixed round-trip, return=$return (expect 4),got=(@{[got($line)]})}); },

    #-----------------------------------------------------------------
    # euc2004 <-> sjis2004 direct (same JIS X 0213 repertoire)
    #-----------------------------------------------------------------

    sub { my $line = "\x88\x9F";
          my $return = Jacode4e::convert(\$line,'euc2004','sjis2004');
          ok(($return == 1) and ($line eq "\xB0\xA1"),
             qq{sjis2004(889F) => euc2004, return=$return (expect 1),got=(@{[got($line)]}) want=(B0A1)}); },

    sub { my $line = "\xB0\xA1";
          my $return = Jacode4e::convert(\$line,'sjis2004','euc2004');
          ok(($return == 1) and ($line eq "\x88\x9F"),
             qq{euc2004(B0A1) => sjis2004, return=$return (expect 1),got=(@{[got($line)]}) want=(889F)}); },

    #-----------------------------------------------------------------
    # euc2004 with ROUND_TRIP option (euc2004 has no user-defined area,
    # so it behaves the same as without ROUND_TRIP)
    #-----------------------------------------------------------------

    sub { my $line = "\xE4\xBA\x9C";
          my $return = Jacode4e::convert(\$line,'euc2004','utf8',{'ROUND_TRIP'=>1});
          ok(($return == 1) and ($line eq "\xB0\xA1"),
             qq{euc2004 with ROUND_TRIP, return=$return (expect 1),got=(@{[got($line)]}) want=(B0A1)}); },

);

$|=1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
