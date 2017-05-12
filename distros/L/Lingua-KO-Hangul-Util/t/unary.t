use strict;
use warnings;
BEGIN { $| = 1; print "1..11\n"; }
my $count = 0;
sub ok ($;$) {
    my $p = my $r = shift;
    if (@_) {
	my $x = shift;
	$p = !defined $x ? !defined $r : !defined $r ? 0 : $r eq $x;
    }
    print $p ? "ok" : "not ok", ' ', ++$count, "\n";
}

use Lingua::KO::Hangul::Util qw(:all);

ok(1);

ok(decomposeSyllable "\x{AC00}" eq "\x{1100}\x{1161}");

ok(composeSyllable "\x{1100}\x{1161}" eq "\x{AC00}");

ok(decomposeJamo "\x{1101}" eq "\x{1100}\x{1100}");

ok(composeJamo "\x{1100}\x{1100}" eq "\x{1101}");

ok(decomposeFull "\x{AC00}" eq "\x{1100}\x{1161}");

ok(decomposeHangul 0xAC00 eq "\x{1100}\x{1161}");

ok(composeHangul "\x{1100}\x{1161}" eq "\x{AC00}");

ok(getHangulName 0xAC00 eq "HANGUL SYLLABLE GA");

ok(parseHangulName "HANGUL SYLLABLE GA" == 0xAC00);

ok(insertFiller "\x{1100}" eq "\x{1100}\x{1160}");

