
BEGIN { $| = 1; print "1..56\n"; }
END {print "not ok 1\n" unless $loaded;}

use strict;
use warnings;

use Lingua::AR::MacArabic;
our $loaded = 1;
print "ok 1\n";

### 2..

print "" eq encodeMacArabic("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq decodeMacArabic("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq encodeMacArabic("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq decodeMacArabic("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq Lingua::AR::MacArabic::encode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "" eq Lingua::AR::MacArabic::decode("")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq Lingua::AR::MacArabic::encode("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "Perl" eq Lingua::AR::MacArabic::decode("Perl")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 10..

our $ampLR = "\x{202D}\x2B\x{202C}";
our $ampRL = "\x{202E}\x2B\x{202C}";

print $ampLR eq decodeMacArabic("\x2B")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $ampRL eq decodeMacArabic("\xAB")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x2B" eq encodeMacArabic($ampLR)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xAB" eq encodeMacArabic($ampRL)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{C4}" eq decodeMacArabic("\x80")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x80" eq encodeMacArabic("\x{C4}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{6D2}" eq decodeMacArabic("\xFF")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xFF" eq encodeMacArabic("\x{6D2}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 18..

our $longEnc = "\x24\x20\x28\x29";
our $longUni = "\x{202D}\x{0024}\x{0020}\x{0028}\x{0029}\x{202C}";

print $longUni eq decodeMacArabic($longEnc)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $longEnc eq encodeMacArabic($longUni)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\0" eq encodeMacArabic("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\0" eq decodeMacArabic("\0")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\cA" eq encodeMacArabic("\cA")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\cA" eq decodeMacArabic("\cA")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\t" eq encodeMacArabic("\t")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\t" eq decodeMacArabic("\t")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x7F" eq encodeMacArabic("\x7F")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x7F" eq decodeMacArabic("\x7F")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\n" eq encodeMacArabic("\n")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\n" eq decodeMacArabic("\n")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\r" eq encodeMacArabic("\r")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\r" eq decodeMacArabic("\r")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "0123456789" eq encodeMacArabic("0123456789")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "0123456789" eq decodeMacArabic("0123456789")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 34..

our $macDigitRL = "\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9"; # RL only
our $uniDigit   = pack 'U*', 0x660..0x669;
our $uniDigitRL = "\x{202E}$uniDigit\x{202C}";

print "0123456789" eq encodeMacArabic($uniDigit)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $uniDigitRL eq decodeMacArabic($macDigitRL)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print $macDigitRL eq encodeMacArabic($uniDigitRL)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

# round-trip convetion for single-character strings

our $allchar = map chr, 0..255;
print $allchar eq encodeMacArabic(decodeMacArabic($allchar))
   ? "ok" : "not ok", " ", ++$loaded, "\n";

our $NG = 0;
for (my $char = 0; $char <= 255; $char++) {
    my $bchar = chr $char;
    my $uchar = encodeMacArabic(decodeMacArabic($bchar));
    $NG++ unless $bchar eq $uchar;
}
print $NG == 0
   ? "ok" : "not ok", " ", ++$loaded, "\n";

# to be downgraded on decoding.
print "\x{C4}" eq decodeMacArabic("\x{80}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{C4}" eq decodeMacArabic(pack 'U', 0x80)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 41..

print "\x30" eq encodeMacArabic("\x{0660}") # ARABIC-INDIC DIGIT ZERO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x30" eq encodeMacArabic("\x{202D}\x{0660}") # with LRO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xB0" eq encodeMacArabic("\x{202E}\x{0660}") # with RLO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{202E}\x{669}\x{202C}" eq decodeMacArabic("\x{B9}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x39" eq encodeMacArabic("\x{0669}") # ARABIC-INDIC DIGIT NINE
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x39" eq encodeMacArabic("\x{202D}\x{0669}") # with LRO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xB9" eq encodeMacArabic("\x{202E}\x{0669}") # with RLO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\x{202E}\x{274A}\x{202C}" eq decodeMacArabic("\x{C0}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ""     eq encodeMacArabic("\x{274A}")
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ""     eq encodeMacArabic("\x{202D}\x{274A}") # with LRO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "\xC0" eq encodeMacArabic("\x{202E}\x{274A}") # with RLO
   ? "ok" : "not ok", " ", ++$loaded, "\n";

### 52..

our $hexNCR = sub { sprintf("&#x%x;", shift) };
our $decNCR = sub { sprintf("&#%d;" , shift) };

print "a\xC7" eq
	encodeMacArabic(pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "a\xC7" eq
	encodeMacArabic(\"", pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "?a?\xC7" eq
	encodeMacArabic(\"?", pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "&#x100ff;a&#x3042;\xC7" eq
	encodeMacArabic($hexNCR, pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print "&#65791;a&#12354;\xC7" eq
	encodeMacArabic($decNCR, pack 'U*', 0x100ff, 0x61, 0x3042, 0x0627)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

