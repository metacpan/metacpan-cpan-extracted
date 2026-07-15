######################################################################
#
# 0312_euc_codeset3.t - EUC-JP code set 3 (SS3 0x8F + JIS X 0212)
#
# Since Jacode4e 2.13.6.23, the "euc" and "jis" encodings are derived
# by encoding conversion from the "sjis" columns of each era. Because
# Shift_JIS has no JIS X 0212 (supplementary kanji) repertoire, code
# set 3 is filled separately for 'euc1990'/'jis1990' (and
# so for the year-less 'euc'/'jis') for every character that already
# has a row in the Jacode4e table because some OTHER encoding (CP932X,
# CP932, CP932IBM, CP932NEC, CP00930, KEIS78/83/90, JEF, JIPS(J)/(E),
# or LetsJ) maps it. A character whose ONLY repertoire membership is
# JIS X 0212 (such as U+2122 TRADE MARK SIGN, JIS X 0212 code 0x226F)
# has no row and becomes GETA; see Changes for the coverage
# figure and make__DATA__/JIS/fill_euc_codeset3.pl for how the
# code set 3 mappings are derived.
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

    # code set 3 input (SS3 0x8F + GR A2C2, JIS X 0212 code 0x2242) is
    # U+00A1 INVERTED EXCLAMATION MARK (utf8 C2A1); U+00A1 also has a
    # CP932X mapping, so it has a row and code set 3 now resolves.
    sub { my $line = "\x8F\xA2\xC2";
          my $return = Jacode4e::convert(\$line,'utf8','euc');
          ok(($return == 1) and ($line eq "\xC2\xA1"),
             qq{euc(SS3 A2C2) => utf8, return=$return (expect 1),got=(@{[got($line)]}) want=(C2A1)}); },

    # the reverse direction: utf8(U+00A1) => euc code set 3.
    sub { my $line = "\xC2\xA1";
          my $return = Jacode4e::convert(\$line,'euc','utf8');
          ok(($return == 1) and ($line eq "\x8F\xA2\xC2"),
             qq{utf8(U+00A1) => euc(SS3 A2C2), return=$return (expect 1),got=(@{[got($line)]}) want=(8FA2C2)}); },

    # a character whose ONLY repertoire membership is JIS X 0212
    # (U+2122 TRADE MARK SIGN, JIS X 0212 code 0x226F) still has no
    # row, and is still written as GETA (euc A2AE).
    sub { my $line = "\xE2\x84\xA2";
          my $return = Jacode4e::convert(\$line,'euc','utf8');
          ok(($return == 1) and ($line eq "\xA2\xAE"),
             qq{utf8(U+2122) => euc GETA, return=$return (expect 1),got=(@{[got($line)]}) want=(A2AE)}); },

    # code set 0 (ASCII), code set 1 (JIS X 0208), code set 2 (SS2 +
    # JIS X 0201 Katakana), and now code set 3 (SS3, for characters
    # with a row) are all supported in the same input.
    sub { my $line = "\x41\xA4\xA2\x8E\xB1\x8F\xA2\xC2";
          my $return = Jacode4e::convert(\$line,'utf8','euc');
          ok(($return == 4) and ($line eq "\x41\xE3\x81\x82\xEF\xBD\xB1\xC2\xA1"),
             qq{euc(41 A4A2 SS2 B1 SS3 A2C2) => utf8, return=$return (expect 4),got=(@{[got($line)]})}); },

    # SS3 is recognized as a three-octet unit (DBCS) whether or not it
    # has a mapping, so following octets are not misread. (SS3 A2EF is
    # JIS X 0212 code 0x226F, U+2122, which has no row and is GETA.)
    sub { my $line = "\x8F\xA2\xEF\x41";
          my $return = Jacode4e::convert(\$line,'utf8','euc');
          ok(($return == 2) and ($line eq "\xE3\x80\x93\x41"),
             qq{euc(SS3 A2EF 41) => utf8, return=$return (expect 2),got=(@{[got($line)]}) want=(E3809341)}); },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

__END__
