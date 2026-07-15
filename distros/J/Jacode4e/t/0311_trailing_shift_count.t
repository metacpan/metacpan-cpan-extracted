######################################################################
#
# 0311_trailing_shift_count.t - convert() return value must not count a
#                               trailing shifting code as one character
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

    # 'jis' input ending with a trailing shifting code (ESC $ B):
    # only "A" is a character, the trailing escape must not be counted.
    sub { my $line = "\x41\x1B\x24\x42";
          my $return = Jacode4e::convert(\$line,'utf8','jis');
          ok(($return == 1) and ($line eq "\x41"),
             qq{jis(41 + trailing ESC\$B) => return=$return (expect 1),got=(@{[got($line)]})}); },

    # 'jis' input consisting of shifting code(s) only:
    # there is no character, so return must be 0 and output empty.
    sub { my $line = "\x1B\x24\x42";
          my $return = Jacode4e::convert(\$line,'utf8','jis');
          ok(($return == 0) and ($line eq ''),
             qq{jis(only ESC\$B) => return=$return (expect 0),got=(@{[got($line)]})}); },

    # 'jis' input: ESC $ B, one character, then trailing ESC ( B (back to SBCS).
    # one character only.
    sub { my $line = "\x1B\x24\x42\x24\x22\x1B\x28\x42";
          my $return = Jacode4e::convert(\$line,'utf8','jis');
          ok(($return == 1) and ($line eq "\xE3\x81\x82"),
             qq{jis(ESC\$B U+3042 ESC(B) => return=$return (expect 1),got=(@{[got($line)]})}); },

    # 'keis83' input: SO, one character (A4A2 = U+3042), then trailing SI.
    # one character only, the trailing SI must not be counted.
    sub { my $line = "\x0A\x42\xA4\xA2\x0A\x41";
          my $return = Jacode4e::convert(\$line,'utf8','keis83');
          ok(($return == 1) and ($line eq "\xE3\x81\x82"),
             qq{keis83(SO A4A2 SI) => return=$return (expect 1),got=(@{[got($line)]})}); },

    # 'cp00930' input ending with a trailing SI (\x0F):
    # only the DBCS character is counted.
    sub { my $line = "\x0E\x44\x81\x0F";
          my $return = Jacode4e::convert(\$line,'utf8','cp00930');
          ok(($return == 1) and ($line eq "\xE3\x81\x82"),
             qq{cp00930(SO 4481 SI) => return=$return (expect 1),got=(@{[got($line)]})}); },

    # OUTPUT_SHIFTING must be unaffected: the closing shifting code for a
    # trailing input shift is still emitted even though it is not counted.
    # input: ESC $ B, one character (2422), then a trailing ESC ( B that
    # shifts back to SBCS. only one character, and the closing ESC ( B for
    # the output must still be emitted.
    sub { my $line = "\x1B\x24\x42\x24\x22\x1B\x28\x42";
          my $return = Jacode4e::convert(\$line,'jis','jis',{'OUTPUT_SHIFTING'=>1});
          ok(($return == 1) and ($line eq "\x1B\x24\x42\x24\x22\x1B\x28\x42"),
             qq{jis to jis {OUTPUT_SHIFTING=>1}, trailing ESC(B kept => return=$return (expect 1),got=(@{[got($line)]})}); },

    # a normal conversion without any trailing shift is unchanged.
    sub { my $line = "\x82\xA0\xB1\x41";
          my $return = Jacode4e::convert(\$line,'euc','sjis');
          ok($return == 3,
             qq{sjis(82A0B141) to euc => return=$return (expect 3)}); },
);

$| = 1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
