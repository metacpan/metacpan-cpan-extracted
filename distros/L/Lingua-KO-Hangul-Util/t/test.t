use strict;
use warnings;
BEGIN { $| = 1; print "1..139\n"; }
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

#########################

my($str, @ary, $NG, $aryref);

sub strhex {
    join ':', map sprintf("%04X", $_), unpack 'U*', pack('U*').shift;
}
sub strfy  {
    join ':', map sprintf("%04X", $_), @_;
}

##
## decomposeHangul: 8 tests
##
ok(strfy(decomposeHangul(0xAC00)), "1100:1161");
ok(strfy(decomposeHangul(0xAE00)), "1100:1173:11AF");
ok(strhex(scalar decomposeHangul(0xAC00)), "1100:1161");
ok(strhex(scalar decomposeHangul(0xAE00)), "1100:1173:11AF");
ok(strhex(scalar decomposeHangul(0xAF71)), "1101:116B:11B4");
ok(scalar decomposeHangul(0x0041), undef);
ok(scalar decomposeHangul(0x0000), undef);
@ary = decomposeHangul(0x0000);
ok(scalar @ary, 0);

##
## composeHangul: 8 tests
##
ok(strfy(composeHangul("")), "");
ok(strfy(composeHangul("\0")), "0000");
ok(strfy(composeHangul(" ")),  "0020");
ok(strfy(composeHangul("A\x{1FF}\x{3042}")), "0041:01FF:3042");
ok(strfy(composeHangul("\x{1101}\x{116B}\x{11B4}")), "AF71");
ok(strfy(composeHangul("\x{AC00}\x{11A7}\x{AC00}\x{11A8}")),
	"AC00:11A7:AC01");
ok(strfy(composeHangul("A\x{1100}\x{1161}\x{1100}\x{1173}\x{11AF}a")),
	"0041:AC00:AE00:0061");
ok(strfy(composeHangul("\x{AC00}\x{11A7}\x{1100}\x{0300}\x{1161}")),
	"AC00:11A7:1100:0300:1161");

##
## scalar composeHangul: 8 tests
##
ok(strhex(scalar composeHangul("")), "");
ok(strhex(scalar composeHangul("\0")), "0000");
ok(strhex(scalar composeHangul(" ")),  "0020");
ok(strhex(scalar composeHangul("A\x{1FF}\x{3044}")), "0041:01FF:3044");
ok(strhex(scalar composeHangul("\x{1101}\x{116B}\x{11B4}")), "AF71");
ok(strhex(scalar composeHangul("\x{AC00}\x{11A7}\x{AC00}\x{11A8}")),
	"AC00:11A7:AC01");
ok(strhex(scalar composeHangul("A\x{1100}\x{1161}\x{1100}\x{1173}\x{11AF}a")),
	"0041:AC00:AE00:0061");
ok(strhex(scalar composeHangul("\x{AC00}\x{11A7}\x{1100}\x{0300}\x{1161}")),
	"AC00:11A7:1100:0300:1161");

##
## composeSyllable: 8 tests
##
ok(strhex(composeSyllable("")), "");
ok(strhex(composeSyllable("\0")), "0000");
ok(strhex(composeSyllable(" ")), "0020");
ok(strhex(composeSyllable("A\x{1FF}\x{3044}")), "0041:01FF:3044");
ok(strhex(composeSyllable("\x{1101}\x{116B}\x{11B4}")), "AF71");
ok(strhex(composeSyllable("\x{AC00}\x{11A7}\x{AC00}\x{11A8}")),
	"AC00:11A7:AC01");
ok(strhex(composeSyllable("A\x{1100}\x{1161}\x{1100}\x{1173}\x{11AF}a")),
	"0041:AC00:AE00:0061");
ok(strhex(composeSyllable("\x{AC00}\x{11A7}\x{1100}\x{0300}\x{1161}")),
	"AC00:11A7:1100:0300:1161");

##
## decomposeSyllable: 8 tests
##
ok(strhex(decomposeSyllable("")), "");
ok(strhex(decomposeSyllable("\0")), "0000");
ok(strhex(decomposeSyllable(" ")), "0020");
ok(strhex(decomposeSyllable("A\x{1FF}\x{3044}")), "0041:01FF:3044");
ok(strhex(decomposeSyllable("\x{AE00}")), "1100:1173:11AF");
ok(strhex(decomposeSyllable("\x{AF71}")), "1101:116B:11B4");
ok(strhex(decomposeSyllable("\x{AC00}\x{11A7}\x{AC01}")),
	"1100:1161:11A7:1100:1161:11A8");
ok(strhex(decomposeSyllable("A\x{AC00}\x{AE00}a")),
	"0041:1100:1161:1100:1173:11AF:0061");

##
## decomposeJamo: 8 tests
##
ok(strhex(decomposeJamo("")), "");
ok(strhex(decomposeJamo("\0")), "0000");
ok(strhex(decomposeJamo(" ")), "0020");
ok(strhex(decomposeJamo("A\x{1FF}\x{3044}")), "0041:01FF:3044");
ok(strhex(decomposeJamo("\x{AE00}")), "AE00");
ok(strhex(decomposeJamo("\x{AF71}")), "AF71");
ok(strhex(decomposeJamo("\x{1101}\x{116B}\x{11B4}")),
	"1100:1100:1169:1161:1175:11AF:11C0");
ok(strhex(decomposeJamo("\x{1101}\x{116A}\x{1175}\x{11B4}")),
	"1100:1100:1169:1161:1175:11AF:11C0");

##
## composeJamo: 8 tests
##
ok(strhex(composeJamo("")), "");
ok(strhex(composeJamo("\0")), "0000");
ok(strhex(composeJamo(" ")), "0020");
ok(strhex(composeJamo("A\x{1FF}\x{3044}")), "0041:01FF:3044");
ok(strhex(composeJamo("\x{AE00}")), "AE00");
ok(strhex(composeJamo("\x{AF71}")), "AF71");
ok(strhex(composeJamo(
	"\x{1100}\x{1100}\x{1169}\x{1161}\x{1175}\x{11AF}\x{11C0}")),
	"1101:116B:11B4");
ok(strhex(composeJamo(
	"\x{1100}\x{1100}\x{116A}\x{1175}\x{11AF}\x{11C0}")),
	"1101:116A:1175:11B4");

##
## decomposeFull: 8 tests
##
ok(strhex(decomposeFull("")), "");
ok(strhex(decomposeFull("\0")), "0000");
ok(strhex(decomposeFull(" ")), "0020");
ok(strhex(decomposeFull("A\x{1FF}\x{3044}")), "0041:01FF:3044");
ok(strhex(decomposeFull("\x{AE00}")), "1100:1173:11AF");
ok(strhex(decomposeFull("\x{AF71}")),
	"1100:1100:1169:1161:1175:11AF:11C0");
ok(strhex(decomposeFull("\x{AC00}\x{11A7}\x{AC01}")),
	"1100:1161:11A7:1100:1161:11A8");
ok(strhex(decomposeFull("A\x{AC00}\x{AE00}a")),
	"0041:1100:1161:1100:1173:11AF:0061");


##
## getHangulName: 11 tests
##
ok(getHangulName(0xAC00), "HANGUL SYLLABLE GA");
ok(getHangulName(0xAE00), "HANGUL SYLLABLE GEUL");
ok(getHangulName(0xC544), "HANGUL SYLLABLE A");
ok(getHangulName(0xD7A3), "HANGUL SYLLABLE HIH");
ok(getHangulName(0x0000),  undef);
ok(getHangulName(0x00FF),  undef);
ok(getHangulName(0x0100),  undef);
ok(getHangulName(0x11A3),  undef);
ok(getHangulName(0x10000), undef);
ok(getHangulName(0x20000), undef);
ok(getHangulName(0x100000),undef);

##
## parseHangulName: 32 tests
##
ok(parseHangulName('HANGUL SYLLABLE GA'),   0xAC00);
ok(parseHangulName('HANGUL SYLLABLE GEUL'), 0xAE00);
ok(parseHangulName('HANGUL SYLLABLE A'),    0xC544);
ok(parseHangulName('HANGUL SYLLABLE HIH'),  0xD7A3);
ok(parseHangulName('HANGUL SYLLABLE PERL'), undef);
ok(parseHangulName('LATIN LETTER SMALL A'), undef);
ok(parseHangulName('LEFTWARDS TRIPLE ARROW'), undef);
ok(parseHangulName('LATIN LETTER SMALL CAPITAL H'), undef);
ok(parseHangulName('HIRAGANA LETTER BA'), undef);
ok(parseHangulName('HANGUL JONGSEONG PANSIOS'), undef);
ok(parseHangulName('PARENTHESIZED HANGUL KHIEUKH A'), undef);
ok(parseHangulName('CJK COMPATIBILITY IDEOGRAPH-FA24'), undef);
ok(parseHangulName('HANGUL SYLLABLE '), undef);
ok(parseHangulName('HANGUL SYLLABLE'), undef);
ok(parseHangulName('HANGUL SYLLABLE H'), undef);
ok(parseHangulName('HANGUL SYLLABLE HH'), undef);
ok(parseHangulName('HANGUL SYLLABLE AA'), undef);
ok(parseHangulName('HANGUL SYLLABLE AAAA'), undef);
ok(parseHangulName('HANGUL SYLLABLE WYZ'), undef);
ok(parseHangulName('HANGUL SYLLABLE QA'), undef);
ok(parseHangulName('HANGUL SYLLABLE LA'), undef);
ok(parseHangulName('HANGUL SYLLABLE MAR'), undef);
ok(parseHangulName('HANGUL SYLLABLE  GA'), undef);
ok(parseHangulName('HANGUL SYLLABLEGA'), undef);
ok(parseHangulName('HANGUL SYLLABLE GA'."\000"), undef);
ok(parseHangulName('HANGUL SYLLABLE GA '), undef);
ok(parseHangulName('HANGUL SYLLABLE KAA'), undef);
ok(parseHangulName('HANGUL SYLLABLE KKKAK'), undef);
ok(parseHangulName('HANGUL SYLLABLE SAQ'), undef);
ok(parseHangulName('HANGUL SYLLABLE SAU'), undef);
ok(parseHangulName('HANGUL SYLLABLE TEE'), undef);
ok(parseHangulName('HANGUL SYLLABLE SHA'), undef);

##
## round trip : 18 tests
##
for my $r (
    [0xAC00,0xAFFF],   [0xB000,0xB7FF],
    [0xB800,0xBFFF],   [0xC000,0xC7FF],
    [0xC800,0xCFFF],   [0xD000,0xD7A3]) {
    $NG = 0;
    for (my $i = $r->[0]; $i <= $r->[1]; $i++) {
	$NG ++ if $i != parseHangulName(getHangulName($i));
    }
    ok($NG, 0);

    $NG = 0;
    for (my $i = $r->[0]; $i <= $r->[1]; $i++) {
	$NG ++ if $i != (composeHangul scalar decomposeHangul($i))[0];
    }
    ok($NG, 0);

    $NG = 0;
    for (my $i = $r->[0]; $i <= $r->[1]; $i++) {
	$NG ++ if $i != ord composeSyllable decomposeSyllable(chr $i);
    }
    ok($NG, 0);
}

##
## getHangulComposite: 13 tests
##
ok(getHangulComposite( 0,  0), undef);
ok(getHangulComposite( 0, 41), undef);
ok(getHangulComposite(41,  0), undef);
ok(getHangulComposite(41, 41), undef);
ok(getHangulComposite(0x1100, 0x1161), 0xAC00);
ok(getHangulComposite(0x1100, 0x1173), 0xADF8);
ok(getHangulComposite(0xAC00, 0x11A7), undef);
ok(getHangulComposite(0xAC00, 0x11A8), 0xAC01);
ok(getHangulComposite(0xADF8, 0x11AF), 0xAE00);
ok(getHangulComposite(12, 0x0300), undef);
ok(getHangulComposite(0x0055, 0xFF00), undef);
ok(getHangulComposite(0x1100, 0x11AF), undef);
ok(getHangulComposite(0x1173, 0x11AF), undef);

