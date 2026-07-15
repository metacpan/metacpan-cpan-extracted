######################################################################
#
# 0318_sjis_euc_jis_era.t - era of "sjis", "euc", and "jis"
#
# The "sjis", "euc", and "jis" encodings support these eras:
#     sjis1978 euc1978 jis1978   JIS C 6226-1978
#     sjis1983 euc1983 jis1983   JIS X 0208-1983
#     sjis1990 euc1990 jis1990   JIS X 0208-1990 (year-less sjis/euc/jis)
#     sjis2000 euc2000 jis2000   JIS X 0213:2000
#     sjis2004 euc2004 jis2004   JIS X 0213:2004
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
sub conv { my($in,$out,$bytes,$opt) = @_; my $s = $bytes; Jacode4e::convert(\$s,$out,$in,($opt||{})); return $s; }

my @tests = (

    #-----------------------------------------------------------------
    # all era names are accepted by convert()
    #-----------------------------------------------------------------
    sub { my $ok = 1;
          for my $e (qw(sjis sjis1978 sjis1983 sjis1990 sjis2000 sjis2004
                        euc  euc1978  euc1983  euc1990  euc2000  euc2004
                        jis  jis1978  jis1983  jis1990  jis2000  jis2004)) {
              my $s = "\x41"; eval { Jacode4e::convert(\$s,$e,'utf8',{'OUTPUT_SHIFTING'=>1}); };
              $ok = 0 if $@;
              my $t = "\x41"; eval { Jacode4e::convert(\$t,'utf8',$e); };
              $ok = 0 if $@;
          }
          ok($ok, "all 18 era encoding names accepted by convert()"); },

    # an unknown era name is rejected
    sub { my $s = "\x41"; my $died = (not eval { Jacode4e::convert(\$s,'sjis1979','utf8'); 1 });
          ok($died, "unknown era name 'sjis1979' is rejected"); },

    #-----------------------------------------------------------------
    # year-less sjis/euc/jis are the 1990 era
    #-----------------------------------------------------------------
    # U+4E9C (Shift_JIS 889F): sjis == sjis1990
    sub { ok(got(conv('sjis','utf8',"\x88\x9F")) eq got(conv('sjis1990','utf8',"\x88\x9F")),
             "year-less sjis == sjis1990"); },
    sub { ok(got(conv('euc','utf8',"\xB0\xA1")) eq got(conv('euc1990','utf8',"\xB0\xA1")),
             "year-less euc == euc1990"); },
    sub { my $a = conv('utf8','jis',"\xE4\xBA\x9C",{'OUTPUT_SHIFTING'=>1});
          my $b = conv('utf8','jis1990',"\xE4\xBA\x9C",{'OUTPUT_SHIFTING'=>1});
          ok(got($a) eq got($b), "year-less jis == jis1990"); },

    #-----------------------------------------------------------------
    # U+4E9C is unchanged across all eras (Shift_JIS 889F, EUC B0A1)
    #-----------------------------------------------------------------
    sub { my $ok = 1;
          for my $e (qw(sjis1978 sjis1983 sjis1990 sjis2000 sjis2004)) {
              $ok = 0 if got(conv('utf8',$e,"\xE4\xBA\x9C")) ne '889F';
          }
          ok($ok, "U+4E9C is Shift_JIS 889F in every era"); },
    sub { my $ok = 1;
          for my $e (qw(euc1978 euc1983 euc1990 euc2000 euc2004)) {
              $ok = 0 if got(conv('utf8',$e,"\xE4\xBA\x9C")) ne 'B0A1';
          }
          ok($ok, "U+4E9C is EUC B0A1 in every era"); },

    #-----------------------------------------------------------------
    # JIS X 0208 "simplified and traditional exchanged" pair
    # (JIS C 6226-1978 versus JIS X 0208-1983): U+9BF5 is at GL 3033
    # in 1983/1990 but at GL 724D in JIS C 6226-1978.
    #-----------------------------------------------------------------
    # sjis1990 88B1 => sjis1978 E9CB
    sub { ok(got(conv('sjis1990','sjis1978',"\x88\xB1")) eq 'E9CB',
             "U+9BF5 sjis1990 88B1 => sjis1978 E9CB (exchanged)"); },
    # sjis1978 E9CB => sjis1990 88B1
    sub { ok(got(conv('sjis1978','sjis1990',"\xE9\xCB")) eq '88B1',
             "U+9BF5 sjis1978 E9CB => sjis1990 88B1 (exchanged back)"); },
    # jis1990 uses ESC $ B and GL 3033; jis1978 uses ESC $ @ and GL 724D
    sub { ok(got(conv('sjis1990','jis1990',"\x88\xB1",{'OUTPUT_SHIFTING'=>1})) eq '1B24423033',
             "U+9BF5 jis1990 = ESC\$B 3033"); },
    sub { ok(got(conv('sjis1978','jis1978',"\xE9\xCB",{'OUTPUT_SHIFTING'=>1})) eq '1B2440724D',
             "U+9BF5 jis1978 = ESC\$@ 724D"); },

    #-----------------------------------------------------------------
    # two kanji were appended by JIS X 0208-1990 (U+51DC at Shift_JIS
    # EAA3, U+7199 at Shift_JIS EAA4): present in 1990 and later, GETA
    # in 1983 and 1978.
    #-----------------------------------------------------------------
    sub { ok(got(conv('sjis1990','sjis1990',"\xEA\xA3")) eq 'EAA3',
             "U+51DC present in 1990 (sjis EAA3)"); },
    sub { ok(got(conv('sjis1990','sjis1983',"\xEA\xA3",{'GETA'=>"\x22\x2E"})) eq '222E',
             "U+51DC GETA in 1983"); },
    sub { ok(got(conv('sjis1990','sjis1978',"\xEA\xA3",{'GETA'=>"\x22\x2E"})) eq '222E',
             "U+51DC GETA in 1978"); },
    sub { ok(got(conv('sjis1990','sjis2004',"\xEA\xA4")) eq 'EAA4',
             "U+7199 present in 2004 (sjis EAA4)"); },

    #-----------------------------------------------------------------
    # ten kanji were appended by JIS X 0213:2004 (for example U+4FF1
    # at Shift_JIS-2004 879F): present in 2004, GETA in 2000.
    #-----------------------------------------------------------------
    sub { ok(got(conv('sjis2004','sjis2004',"\x87\x9F")) eq '879F',
             "U+4FF1 present in 2004 (sjis2004 879F)"); },
    sub { ok(got(conv('sjis2004','sjis2000',"\x87\x9F",{'GETA'=>"\x22\x2E"})) eq '222E',
             "U+4FF1 GETA in 2000"); },

    #-----------------------------------------------------------------
    # jis output designation escape by era
    #     jis1978 = ESC $ @        (JIS C 6226-1978)
    #     jis1983 = ESC $ B        (JIS X 0208-1983)
    #     jis1990 = ESC $ B        (JIS X 0208-1990)
    #     jis2000 = ESC $ ( O      (JIS X 0213:2000 plane 1)
    #     jis2004 = ESC $ ( Q      (JIS X 0213:2004 plane 1)
    # tested with U+4E9C (GL 3021, unchanged in every era).
    #-----------------------------------------------------------------
    sub { ok(got(conv('utf8','jis1978',"\xE4\xBA\x9C",{'OUTPUT_SHIFTING'=>1})) eq '1B2440'.'3021',
             "jis1978 designation = ESC\$@"); },
    sub { ok(got(conv('utf8','jis1983',"\xE4\xBA\x9C",{'OUTPUT_SHIFTING'=>1})) eq '1B2442'.'3021',
             "jis1983 designation = ESC\$B"); },
    sub { ok(got(conv('utf8','jis2000',"\xE4\xBA\x9C",{'OUTPUT_SHIFTING'=>1})) eq '1B242'.'84F'.'3021',
             "jis2000 designation = ESC\$(O"); },
    sub { ok(got(conv('utf8','jis2004',"\xE4\xBA\x9C",{'OUTPUT_SHIFTING'=>1})) eq '1B242'.'851'.'3021',
             "jis2004 designation = ESC\$(Q"); },

    #-----------------------------------------------------------------
    # euc/jis are round-trip safe within an era for a common kanji
    #-----------------------------------------------------------------
    sub { my $ok = 1;
          for my $era (qw(1978 1983 1990 2000 2004)) {
              my $euc = conv('utf8',"euc$era","\xE4\xBA\x9C");
              my $back = conv("euc$era",'utf8',$euc);
              $ok = 0 if $back ne "\xE4\xBA\x9C";
          }
          ok($ok, "U+4E9C utf8 => euc<era> => utf8 round-trip in every era"); },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

__END__
