######################################################################
#
# 0315_jis_x0212_output.t - JIS X 0212 output for "jis" (ISO-2022-JP-1)
#
# Since 2.13.6.23, "jis" output for a character in JIS X 0212 but not
# JIS X 0208 is written as ESC $ ( D (see the JIS_X0212 option) for
# every character that already has a row in the Jacode4e table (see
# t/0312_euc_codeset3.t and Changes for the coverage figure). A
# character whose ONLY repertoire membership is JIS X 0212 still has
# no row and remains GETA even with the JIS_X0212 option.
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

    # U+00A1 (JIS X 0212 code 0x2242, has a row via CP932X) is written
    # as ESC $ ( D 2242 with the JIS_X0212 option.
    sub { my $line = "\xC2\xA1";
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'JIS_X0212'=>1,'OUTPUT_SHIFTING'=>1});
          ok(($return == 1) and ($line eq "\x1B\x24\x28\x44\x22\x42"),
             qq{JIS_X0212 U+00A1 => ESC\$(D 2242, return=$return (expect 1),got=(@{[got($line)]}) want=(1B2428442242)}); },

    # without the JIS_X0212 option, the same character is GETA (the
    # option gates ESC $ ( D output, not the underlying mapping).
    sub { my $line = "\xC2\xA1";
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'OUTPUT_SHIFTING'=>1,'GETA'=>"\x22\x2E"});
          ok(($return == 1) and ($line eq "\x1B\x24\x42\x22\x2E"),
             qq{without JIS_X0212 U+00A1 => GETA, return=$return (expect 1),got=(@{[got($line)]}) want=(1B2442222E)}); },

    # a character whose ONLY repertoire membership is JIS X 0212
    # (U+2122, JIS X 0212 code 0x226F) has no row and is GETA even
    # with the JIS_X0212 option.
    sub { my $line = "\xE2\x84\xA2";
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'JIS_X0212'=>1,'OUTPUT_SHIFTING'=>1,'GETA'=>"\x22\x2E"});
          ok(($return == 1) and ($line eq "\x1B\x24\x42\x22\x2E"),
             qq{JIS_X0212 U+2122 => GETA, return=$return (expect 1),got=(@{[got($line)]}) want=(1B2442222E)}); },

    # a JIS X 0208 character (U+4E9C, code 0x3021) is still written
    # normally as ESC $ B 3021, unaffected by JIS_X0212.
    sub { my $line = "\xE4\xBA\x9C";
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'JIS_X0212'=>1,'OUTPUT_SHIFTING'=>1});
          ok(($return == 1) and ($line eq "\x1B\x24\x42\x30\x21"),
             qq{U+4E9C => ESC\$B 3021, return=$return (expect 1),got=(@{[got($line)]}) want=(1B24423021)}); },

    # a run of JIS X 0212 characters is wrapped once in ESC $ ( D and
    # closed with ESC $ B when a JIS X 0208 character follows directly
    # (U+00A1 U+00A1 then U+4E9C).
    sub { my $line = "\xC2\xA1\xC2\xA1\xE4\xBA\x9C";
          my $return = Jacode4e::convert(\$line,'jis','utf8',{'JIS_X0212'=>1,'OUTPUT_SHIFTING'=>1});
          ok(($return == 3) and ($line eq "\x1B\x24\x28\x44\x22\x42\x22\x42\x1B\x24\x42\x30\x21"),
             qq{run of JIS_X0212 then JIS X 0208, return=$return (expect 3),got=(@{[got($line)]}) want=(1B242844224222421B24423021)}); },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

__END__
